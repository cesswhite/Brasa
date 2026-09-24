import test from 'node:test';
import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import {fixture,account,request} from './helpers.mjs';
import {readOnline,grantXp,estimatePower} from '../src/game/profiles.js';
import {xpForLevel,statsForProfile} from '../battle-engine/index.js';
import {ONLINE} from '../src/game/config.js';
const headers=()=>({'Idempotency-Key':randomUUID()});
async function create(f,owner,name='Jade',id='luma') {
 const r=await request(f.mf,owner,'/v1/fighters','POST',{archetype_id:id,display_name:name},headers());
 assert.equal(r.status,201,JSON.stringify(r.body));return r.body.data;
}
async function pair(f) {const a=await account(f.db),b=await account(f.db);return {a,b,p:await create(f,a,'Jade'),r:await create(f,b,'Ceniza')};}
async function challenge(f,owner,p,r,key=headers()) {return request(f.mf,owner,'/v1/battles','POST',{fighter_id:p.fighter_id,opponent_id:r.fighter_id},key);}
async function profileRow(f,id) {return f.db.prepare('SELECT payload,revision FROM fighter_progression WHERE fighter_id=?').bind(id).first();}
async function snapshot(db) {
 const result={};
 for(const table of ['fighters','fighter_identity','fighter_appearance','fighter_progression','fighter_arena','game_operations','online_battles','progression_events','offline_activity','owned_cosmetics']) {
  result[table]=(await db.prepare('SELECT * FROM '+table).all()).results.map(row=>JSON.stringify(row)).sort();
 }
 // Rejected attempts intentionally still count in the separate abuse limiter.
 return result;
}
async function nearLevelTen(f,id) {
 const row=await readOnline(f.db,id);let amount=xpForLevel(9)-1;
 for(let level=1;level<9;level++)amount+=xpForLevel(level);
 grantXp(row,amount);
 await f.db.batch([
  f.db.prepare('UPDATE fighter_progression SET payload=? WHERE fighter_id=?').bind(row.progression_payload,id),
  f.db.prepare('UPDATE fighter_arena SET power=? WHERE fighter_id=?').bind(estimatePower(row),id),
 ]);
}

test('review: legacy power=0 rows become real matchmaking candidates without altering builds',async()=>{
 const f=await fixture();try {
  const {a,b,p,r}=await pair(f),beforePlayer=await profileRow(f,p.fighter_id),beforeRival=await profileRow(f,r.fighter_id);
  await f.db.prepare('UPDATE fighter_arena SET power=0').run();
  const first=await request(f.mf,a,'/v1/arena/opponents?fighter_id='+p.fighter_id);
  assert.equal(first.status,200,JSON.stringify(first.body));assert(first.body.data.opponents.some(v=>v.fighter_id===r.fighter_id));
  const rows=(await f.db.prepare('SELECT fighter_id,power FROM fighter_arena').all()).results;
  assert(rows.every(row=>row.power>0));for(const row of rows)assert.equal(row.power,estimatePower(await readOnline(f.db,row.fighter_id)));
  assert.deepEqual(await profileRow(f,p.fighter_id),beforePlayer);assert.deepEqual(await profileRow(f,r.fighter_id),beforeRival);
  const reverse=await request(f.mf,b,'/v1/arena/opponents?fighter_id='+r.fighter_id);
  assert(reverse.body.data.opponents.some(v=>v.fighter_id===p.fighter_id));
  assert.deepEqual((await f.db.prepare('SELECT fighter_id,power FROM fighter_arena').all()).results,rows);
 } finally {await f.close();}
});

test('review: a batch crossing the stat cap rejects atomically and charges no ineffective points',async()=>{
 const f=await fixture();try {
  const owner=await account(f.db),p=await create(f,owner),row=await readOnline(f.db,p.fighter_id);
  // Trusted fixture funding; no public endpoint accepts a point balance.
  const profile=JSON.parse(row.progression_payload);profile.stat_points=30;
  await f.db.prepare('UPDATE fighter_progression SET payload=? WHERE fighter_id=?').bind(JSON.stringify(profile),p.fighter_id).run();
  const before=await snapshot(f.db),path='/v1/fighters/'+p.fighter_id+'/allocate';
  const rejected=await request(f.mf,owner,path,'POST',{stat:'accuracy',amount:30,expected_revision:1},headers());
  assert.equal(rejected.status,422,JSON.stringify(rejected.body));assert.deepEqual(await snapshot(f.db),before);
  let useful=0,previous=statsForProfile({character_id:'luma',...profile}).accuracy;
  for(let amount=1;amount<=30;amount++) {
   const current=statsForProfile({character_id:'luma',...profile,allocations:{accuracy:amount}}).accuracy;
   if(current<=previous+1e-7)break;useful=amount;previous=current;
  }
  assert(useful>0&&useful<30);
  const accepted=await request(f.mf,owner,path,'POST',{stat:'accuracy',amount:useful,expected_revision:1},headers());
  assert.equal(accepted.status,200,JSON.stringify(accepted.body));assert.equal(accepted.body.data.fighter.progression.stat_points,30-useful);
  const capped=await snapshot(f.db);
  assert.equal((await request(f.mf,owner,path,'POST',{stat:'accuracy',amount:1,expected_revision:2},headers())).status,422);
  assert.deepEqual(await snapshot(f.db),capped);
 } finally {await f.close();}
});

test('review: large Story XP in the same UTC day does not exhaust Arena XP or its CAS guard',async()=>{
 const f=await fixture();try {
  const {a,p,r}=await pair(f);
  // Use a real immutable Story battle, then supply historical ledger totals only
  // in the fixture instead of running the entire campaign in this regression.
  const story=await request(f.mf,a,'/v1/story/battles','POST',{fighter_id:p.fighter_id},headers());
  assert.equal(story.status,201,JSON.stringify(story.body));
  await f.db.prepare("UPDATE progression_events SET xp=? WHERE battle_id=? AND side='player'").bind(ONLINE.activeDailyXpCap+5000,story.body.data.battle.id).run();
  await f.db.prepare('UPDATE fighter_arena SET next_challenge_at=0 WHERE fighter_id=?').bind(p.fighter_id).run();
  const result=await challenge(f,a,p,r);
  assert.equal(result.status,201,JSON.stringify(result.body));assert(result.body.data.battle.rewards.player.xp_gained>0);
  const events=(await f.db.prepare("SELECT b.mode,e.xp FROM progression_events e JOIN online_battles b ON b.id=e.battle_id WHERE e.account_id=? AND e.side='player'").bind(a.account_id).all()).results;
  assert(events.find(e=>e.mode==='story').xp>ONLINE.activeDailyXpCap);assert(events.find(e=>e.mode==='arena').xp>0);
  // Actual Arena XP must still consume the Arena cap.
  await f.db.prepare("UPDATE progression_events SET xp=? WHERE battle_id=? AND side='player'").bind(ONLINE.activeDailyXpCap,result.body.data.battle.id).run();
  await f.db.prepare('UPDATE fighter_arena SET next_challenge_at=0 WHERE fighter_id=?').bind(p.fighter_id).run();
  const capped=await challenge(f,a,p,r);assert.equal(capped.status,201,JSON.stringify(capped.body));assert.equal(capped.body.data.battle.rewards.player.xp_gained,0);
 } finally {await f.close();}
});

test('review: final offline-notice failure rolls back battle, XP, rating, cosmetics and receipt',async()=>{
 const f=await fixture();try {
  const {a,b,p,r}=await pair(f);await nearLevelTen(f,p.fighter_id);await nearLevelTen(f,r.fighter_id);
  const before=await snapshot(f.db),key=headers();
  await f.db.prepare("CREATE TRIGGER review_fail_last_write BEFORE INSERT ON offline_activity BEGIN SELECT RAISE(ABORT,'TEST_ATOMIC_FAILURE'); END;").run();
  const failed=await challenge(f,a,p,r,key);assert.equal(failed.status,500,JSON.stringify(failed.body));assert.deepEqual(await snapshot(f.db),before);
  assert.equal((await f.db.prepare("SELECT COUNT(*) n FROM owned_cosmetics WHERE inventory_id='palette:luna'").first()).n,0);
  await f.db.prepare('DROP TRIGGER review_fail_last_write').run();
  const success=await challenge(f,a,p,r,key);assert.equal(success.status,201,JSON.stringify(success.body));
  assert.equal(success.body.data.battle.rewards.player.level_after,10);assert.equal(success.body.data.battle.rewards.rival.level_after,10);
  assert.equal((await f.db.prepare("SELECT COUNT(*) n FROM owned_cosmetics WHERE inventory_id='palette:luna'").first()).n,2);
  const after=await snapshot(f.db),retry=await challenge(f,a,p,r,key);assert.equal(retry.status,200);assert.equal(retry.body.data.battle.id,success.body.data.battle.id);assert.deepEqual(await snapshot(f.db),after);
  assert.equal((await request(f.mf,b,'/v1/arena/offline-results')).body.data.totals.battles,1);
 } finally {await f.close();}
});

test('review: concurrent challengers preserve both defender rewards, levels, rating and notices',async()=>{
 const f=await fixture();try {
  const a=await account(f.db),b=await account(f.db),defender=await account(f.db);
  const p=await create(f,a,'Jade'),q=await create(f,b,'Llama'),r=await create(f,defender,'Ceniza'),keys=[headers(),headers()];
  const replies=await Promise.all([challenge(f,a,p,r,keys[0]),challenge(f,b,q,r,keys[1])]);
  for(const result of replies)assert.equal(result.status,201,JSON.stringify(result.body));
  assert.notEqual(replies[0].body.data.battle.id,replies[1].body.data.battle.id);
  const rewards=replies.map(v=>v.body.data.battle.rewards.rival),row=await readOnline(f.db,r.fighter_id),profile=JSON.parse(row.progression_payload);
  assert.equal(row.progression_revision,3);assert.equal(profile.total_xp,rewards.reduce((sum,reward)=>sum+reward.xp_gained,0));
  const previousXp=Array.from({length:profile.level-1},(_,index)=>xpForLevel(index+1)).reduce((sum,xp)=>sum+xp,0);
  assert.equal(profile.total_xp,previousXp+profile.xp+profile.cap_xp);
  assert.equal(row.rating,ONLINE.initialRating+rewards.reduce((sum,reward)=>sum+reward.rating_delta,0));assert.equal(row.wins+row.losses,2);
  assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM online_battles').first()).n,2);
  assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM progression_events').first()).n,4);
  assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM offline_activity').first()).n,2);
  assert.equal((await f.db.prepare('SELECT SUM(rating) total FROM fighter_arena').first()).total,3*ONLINE.initialRating);
  const notices=await request(f.mf,defender,'/v1/arena/offline-results');assert.equal(notices.body.data.totals.battles,2);assert.equal(notices.body.data.totals.xp,profile.total_xp);
  const before=await snapshot(f.db),retried=await Promise.all([challenge(f,a,p,r,keys[0]),challenge(f,b,q,r,keys[1])]);
  assert(retried.every(v=>v.status===200));assert.deepEqual(await snapshot(f.db),before);
 } finally {await f.close();}
});

test('review: test and real cohorts cannot list or challenge each other, and clients cannot assign the flag',async()=>{
 const f=await fixture();try {
  const real=await account(f.db),testA=await account(f.db),testB=await account(f.db);
  await f.db.prepare('UPDATE accounts SET is_test=1 WHERE id IN (?,?)').bind(testA.account_id,testB.account_id).run();
  const p=await create(f,real,'Real'),a=await create(f,testA,'Prueba Uno'),b=await create(f,testB,'Prueba Dos');
  const realList=await request(f.mf,real,'/v1/arena/opponents?fighter_id='+p.fighter_id);
  assert.equal(realList.status,200);assert.deepEqual(realList.body.data.opponents,[]);
  const testList=await request(f.mf,testA,'/v1/arena/opponents?fighter_id='+a.fighter_id);
  assert.equal(testList.status,200);assert(testList.body.data.opponents.some(v=>v.fighter_id===b.fighter_id));
  assert(!testList.body.data.opponents.some(v=>v.fighter_id===p.fighter_id));
  assert.equal((await challenge(f,real,p,a)).status,404);
  assert.equal((await challenge(f,testA,a,p)).status,404);
  assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM online_battles').first()).n,0);
  const fakeCreate=await request(f.mf,real,'/v1/fighters','POST',{archetype_id:'tepa',display_name:'Cometa',is_test:1},headers());
  assert.equal(fakeCreate.status,422,JSON.stringify(fakeCreate.body));
  const fakePatch=await request(f.mf,real,'/v1/fighters/'+p.fighter_id,'PATCH',{expected_revision:1,display_name:'Real',is_test:1},headers());
  assert.equal(fakePatch.status,422,JSON.stringify(fakePatch.body));
  assert.equal((await f.db.prepare('SELECT is_test FROM accounts WHERE id=?').bind(real.account_id).first()).is_test,0);
  const valid=await challenge(f,testA,a,b);assert.equal(valid.status,201,JSON.stringify(valid.body));
  assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM online_battles').first()).n,1);
  assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM progression_events').first()).n,2);
 } finally {await f.close();}
});
