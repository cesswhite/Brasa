import test from 'node:test';
import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import {fixture,account,request} from './helpers.mjs';
import {grantXp,estimatePower} from '../src/game/profiles.js';
import {arenaRewards,storyReward,earnedCosmetics} from '../src/game/rewards.js';
import {gameCatalog,getStoryStage} from '../battle-engine/index.js';

const key=()=>({'Idempotency-Key':randomUUID()});
async function fighter(f,owner,archetype='mugo',name='Jade') {
  const response=await request(f.mf,owner,'/v1/fighters','POST',{archetype_id:archetype,display_name:name},key());
  assert.equal(response.status,201,JSON.stringify(response.body));return response.body.data;
}
async function pair(f) {const a=await account(f.db),b=await account(f.db);return {a,b,p:await fighter(f,a,'mugo','Jade'),r:await fighter(f,b,'mugo','Ceniza')};}
async function challenge(f,a,p,r,headers=key()) {return request(f.mf,a,'/v1/battles','POST',{fighter_id:p.fighter_id,opponent_id:r.fighter_id},headers);}

test('game catalog, empty real matchmaking and idempotent fighter creation',async()=>{
 const f=await fixture();try {
  const a=await account(f.db),headers=key(),body={archetype_id:'tepa',display_name:'Cometa'};
  const responses=await Promise.all([request(f.mf,a,'/v1/fighters','POST',body,headers),request(f.mf,a,'/v1/fighters','POST',body,headers)]);
  assert(responses.every(x=>x.status===201||x.status===200),JSON.stringify(responses));
  assert.equal(responses[0].body.data.fighter_id,responses[1].body.data.fighter_id);
  assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM fighters').first()).n,1);
  assert.equal(responses[0].body.data.progression.stat_points,3);
  const id=responses[0].body.data.fighter_id;
  assert.deepEqual((await request(f.mf,a,'/v1/arena/opponents?fighter_id='+id)).body.data.opponents,[]);
  const data=(await request(f.mf,a,'/v1/game/catalog')).body.data;
  assert.equal(data.characters.length,15);assert.equal(data.story_stages.length,100);assert.equal(data.story_stages[1].global_level,2);
  const conflict=await request(f.mf,a,'/v1/fighters','POST',{...body,display_name:'Otro'},headers);assert.equal(conflict.status,409);
 }finally{await f.close();}
});
test('allocation, strategy and upgrade intentions are bounded and exactly once',async()=>{
 const f=await fixture();try {
  const {a,b,p}=await pair(f),path='/v1/fighters/'+p.fighter_id,headers=key();
  const body={stat:'attack',amount:2,expected_revision:1};
  const [one,two]=await Promise.all([request(f.mf,a,path+'/allocate','POST',body,headers),request(f.mf,a,path+'/allocate','POST',body,headers)]);
  assert.equal(one.status,200,JSON.stringify(one.body));assert.equal(two.status,200);
  assert.equal(one.body.data.fighter.progression.stat_points,1);
  assert.equal(one.body.data.fighter.progression.allocations.attack,2);
  assert.equal((await request(f.mf,a,path+'/allocate','POST',body,key())).status,409);
  assert.equal((await request(f.mf,a,path+'/allocate','POST',{...body,expected_revision:2,amount:500},key())).status,422);
  assert.equal((await request(f.mf,b,path+'/allocate','POST',{...body,expected_revision:2},key())).status,404);
  assert.equal((await request(f.mf,a,path+'/ai','POST',{style:'aggressive',expected_revision:2,xp:999},key())).status,422);
  assert.equal((await request(f.mf,a,path+'/ai','POST',{style:'aggressive',expected_revision:2},key())).status,200);
  assert.equal((await request(f.mf,a,path+'/upgrade-move','POST',{move_id:'mugo_nudillo',expected_revision:3},key())).status,422);
  assert.equal((await request(f.mf,a,path+'/perk','POST',{perk_id:'mugo_focus',expected_revision:3},key())).status,422);
  const reset=await request(f.mf,a,path+'/respec','POST',{expected_revision:3},key());assert.equal(reset.body.data.fighter.progression.stat_points,3);
 }finally{await f.close();}
});
test('one authoritative battle pays both fighters once, survives retry and isolates history',async()=>{
 const f=await fixture();try {
  const {a,b,p,r}=await pair(f),headers=key();
  const replies=await Promise.all([challenge(f,a,p,r,headers),challenge(f,a,p,r,headers)]);
  assert(replies.every(v=>v.status===201||v.status===200),JSON.stringify(replies));
  const battle=replies[0].body.data.battle;assert.equal(battle.id,replies[1].body.data.battle.id);
  assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM online_battles').first()).n,1);
  assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM progression_events').first()).n,2);
  assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM offline_activity').first()).n,1);
  assert.equal(battle.record.battle_snapshot.player.name,'Jade');assert.equal(battle.record.battle_snapshot.rival.name,'Ceniza');
  assert(battle.record.battle_snapshot.events.length>5);
  assert.equal(typeof battle.record.battle_snapshot.seed,'string');
  const again=await challenge(f,a,p,r,headers);assert.equal(again.status,200);assert.equal(again.body.data.battle.id,battle.id);
  assert.equal((await challenge(f,a,p,r)).status,429);
  const foreign=await account(f.db);assert.equal((await request(f.mf,foreign,'/v1/battles/'+battle.id)).status,404);
  const defense=await request(f.mf,b,'/v1/battles/'+battle.id);assert.equal(defense.status,200);assert.equal(defense.body.data.battle.viewing_side,'rival');
  const feed=await request(f.mf,b,'/v1/arena/offline-results');assert.equal(feed.body.data.totals.battles,1);
  const ackBody={ids:feed.body.data.results.map(x=>x.id)},ackKey=key();
  assert.equal((await request(f.mf,b,'/v1/arena/offline-results/ack','POST',ackBody,ackKey)).status,200);
  assert.equal((await request(f.mf,b,'/v1/arena/offline-results/ack','POST',ackBody,ackKey)).status,200);
  assert.equal((await request(f.mf,b,'/v1/arena/offline-results')).body.data.totals.battles,0);
  assert.equal((await request(f.mf,a,'/v1/arena/offline-results/ack','POST',ackBody,key())).status,404);
  const saved=JSON.stringify(battle.record.battle_snapshot);
  await request(f.mf,b,'/v1/fighters/'+r.fighter_id,'PATCH',{expected_revision:1,display_name:'Cambiado',appearance:{body_style_id:'copal',palette_id:'jade'}});
  assert.equal(JSON.stringify((await request(f.mf,a,'/v1/battles/'+battle.id)).body.data.battle.record.battle_snapshot),saved);
  await assert.rejects(f.db.prepare('UPDATE online_battles SET seed=\'99\' WHERE id=?').bind(battle.id).run(),/IMMUTABLE/);
  assert.equal((await request(f.mf,a,'/v1/history?fighter_id='+p.fighter_id)).body.data.battles.length,1);
 }finally{await f.close();}
});
test('hostile challenge fields, self matches and unavailable Story stages are rejected',async()=>{
 const f=await fixture();try {
  const {a,p,r}=await pair(f);
  for(const field of ['xp','winner','seed','combat_stats','force_signature']) {
   const res=await request(f.mf,a,'/v1/battles','POST',{fighter_id:p.fighter_id,opponent_id:r.fighter_id,[field]:999},key());assert.equal(res.status,422,field);
  }
  assert.equal((await challenge(f,a,p,p)).status,422);
  assert.equal((await request(f.mf,a,'/v1/story/battles','POST',{fighter_id:p.fighter_id,story_level:2},key())).status,422);
  assert.equal((await request(f.mf,a,'/v1/battles','POST',{fighter_id:p.fighter_id,opponent_id:r.fighter_id})).status,422);
  assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM online_battles').first()).n,0);
 }finally{await f.close();}
});
test('Story uses server stage and engine; winning, replay and tokens commit once',async()=>{
 const f=await fixture();try {
  const a=await account(f.db),p=await fighter(f,a,'luma','Luna');
  // Trusted test fixture: not an HTTP endpoint or imported client progress.
  const profile={...p.progression,level:50,allocations:{max_hp:30,attack:30,defense:30,speed:30,accuracy:30,evasion:30,crit_chance:30,resistance:30}};
  delete profile.unlocked_moves;delete profile.xp_required;
  await f.db.prepare('UPDATE fighter_progression SET payload=? WHERE fighter_id=?').bind(JSON.stringify(profile),p.fighter_id).run();
  const headers=key(),body={fighter_id:p.fighter_id};
  const one=await request(f.mf,a,'/v1/story/battles','POST',body,headers);assert.equal(one.status,201,JSON.stringify(one.body));
  assert.equal(one.body.data.battle.record.winner,'player');assert.equal(one.body.data.fighter.online.story_cleared,1);
  assert.equal((await request(f.mf,a,'/v1/story/battles','POST',body,headers)).body.data.battle.id,one.body.data.battle.id);
  assert.equal((await request(f.mf,a,'/v1/story?fighter_id='+p.fighter_id)).body.data.next_stage.global_level,2);
  await f.db.prepare('UPDATE fighter_arena SET next_challenge_at=0 WHERE fighter_id=?').bind(p.fighter_id).run();
  const practice=await request(f.mf,a,'/v1/story/battles','POST',{fighter_id:p.fighter_id,story_level:1},key());assert.equal(practice.status,201);
  assert.equal(practice.body.data.battle.rewards.player.xp_gained,0);assert.equal(practice.body.data.fighter.online.story_cleared,1);
 }finally{await f.close();}
});
test('XP overflow, defensive diminishing returns, rating and cosmetic milestones are distinct',()=>{
 const row=()=>({id:'x',archetype_id:'luma',display_name:'Luna',rating:1000,wins:0,losses:0,draws:0,story_cleared:0,story_attempts:0,progression_payload:JSON.stringify({level:1,xp:0,stat_points:3,move_points:0,perk_points:0,total_xp:0,cap_xp:0,allocations:{},move_upgrades:{},perks:[]})});
 const leveled=row(),xp=grantXp(leveled,200);assert.equal(xp.level_after,3);assert.equal(JSON.parse(leveled.progression_payload).xp,65);
 const p=row(),r=row(),result={winner:'player',duration:30};
 const zero=arenaRewards(p,r,result,{pair:10,defenses:25,activeXp:0,defensiveXp:0});assert.equal(zero.player.xp_gained,0);assert.equal(zero.rival.xp_gained,0);assert.equal(p.wins,1);assert.equal(r.losses,1);assert.equal(p.rating,1000);
 const normal=arenaRewards(row(),row(),result,{pair:0,defenses:0,activeXp:0,defensiveXp:0});assert.equal(normal.player.xp_gained,40);assert.equal(normal.rival.xp_gained,25);assert.equal(normal.player.rating_delta,12);
 const reduced=arenaRewards(row(),row(),result,{pair:0,defenses:5,activeXp:0,defensiveXp:1198});assert.equal(reduced.rival.xp_gained,2);
 const story=row();storyReward(story,getStoryStage(10),result);assert.equal(story.story_cleared,10);assert.equal(JSON.parse(story.progression_payload).perk_points,1);
 assert(earnedCosmetics(story).includes('aura:farol'));
 assert.equal(gameCatalog.campaign.stages.length,100);
});
