import test from 'node:test';
import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import {fixture,account,request} from './helpers.mjs';
import {catalog,archetypes} from '../src/catalog.js';
import {earnedCosmetics} from '../src/game/rewards.js';
import {readOnline} from '../src/game/profiles.js';
import {grantSQL} from '../scripts/admin.mjs';
import {getStoryStage} from '../battle-engine/index.js';

test('six family appearances keep authoritative unlocks, combat power and historical Arena identity',async()=>{
 const f=await fixture();
 try {
  const owner=await account(f.db),other=await account(f.db);
  const create=async(who,id,name)=>{
   const r=await request(f.mf,who,'/v1/fighters','POST',{archetype_id:id,display_name:name},{'Idempotency-Key':randomUUID()});
   assert.equal(r.status,201,JSON.stringify(r.body));return r.body.data;
  };
  let fighter=await create(owner,'taro','Familia');
  const rival=await create(other,'bruma','Rival');
  const individuals=catalog.items.filter(i=>i.species_id);
  assert.equal(individuals.length,6);assert.equal(archetypes.length,15);
  for(const item of individuals) {
   assert(!archetypes.includes(item.id));
   const stage=getStoryStage(item.unlock.threshold);
   assert.equal(stage.opponent.appearance.body_style_id,item.id);
   const row=await readOnline(f.db,fighter.fighter_id);
   row.story_cleared=item.unlock.threshold-1;
   assert(!earnedCosmetics(row).includes(item.inventory_id));
   row.story_cleared++;
   assert(earnedCosmetics(row).includes(item.inventory_id));
   const denied=await request(f.mf,owner,'/v1/fighters/'+fighter.fighter_id,'PATCH',{expected_revision:fighter.revision,appearance:{body_style_id:item.id}});
   assert.equal(denied.status,403);
   // Trusted disposable fixture grant; public clients have no grant route.
   await f.db.prepare(grantSQL(owner.account_id,item.inventory_id)).run();
   const equipped=await request(f.mf,owner,'/v1/fighters/'+fighter.fighter_id,'PATCH',{expected_revision:fighter.revision,appearance:{body_style_id:item.id}});
   assert.equal(equipped.status,200,JSON.stringify(equipped.body));
   assert.deepEqual(equipped.body.data.progression,fighter.progression);
   assert.deepEqual(equipped.body.data.combatant.stats,fighter.combatant.stats);
   assert.equal(equipped.body.data.archetype_id,'taro');
   fighter=equipped.body.data;
  }
  const battle=await request(f.mf,owner,'/v1/battles','POST',{fighter_id:fighter.fighter_id,opponent_id:rival.fighter_id},{'Idempotency-Key':randomUUID()});
  assert.equal(battle.status,201,JSON.stringify(battle.body));
  const record=battle.body.data.battle;
  assert.equal(record.record.battle_snapshot.player.appearance.body_style_id,fighter.appearance.body_style_id);
  const current=(await request(f.mf,owner,'/v1/fighters/'+fighter.fighter_id)).body.data;
  assert.equal((await request(f.mf,owner,'/v1/fighters/'+fighter.fighter_id,'PATCH',{expected_revision:current.revision,appearance:{body_style_id:'taro'}})).status,200);
  const historical=(await request(f.mf,owner,'/v1/battles/'+record.id)).body.data.battle;
  assert.deepEqual(historical.record.battle_snapshot,record.record.battle_snapshot);
 } finally {await f.close();}
});
