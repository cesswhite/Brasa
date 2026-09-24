import test from 'node:test';
import assert from 'node:assert/strict';
import {fixture,account,request} from './helpers.mjs';
import {catalog} from '../src/catalog.js';
import {earnedCosmetics} from '../src/game/rewards.js';
import {readOnline} from '../src/game/profiles.js';
import {grantSQL} from '../scripts/admin.mjs';
test('new particle rewards require authoritative ownership and preserve combat power',async()=>{
 const f=await fixture();
 try {
  const owner=await account(f.db);
  let fighter=(await request(f.mf,owner,'/v1/fighters','POST',{archetype_id:'onix',display_name:'Colores'})).body.data;
  const effects=catalog.items.filter(i=>['aura_id','trail_id'].includes(i.slot));
  assert.equal(effects.length,14);
  for(const id of ['petalos','llovizna','cenizas','cristales','cometa','hojas','polvo']) {
   const item=effects.find(i=>i.id===id),row=await readOnline(f.db,fighter.fighter_id);
   const progression=JSON.parse(row.progression_payload);
   const setProgress=value=>{
    if(item.unlock.kind==='level'){progression.level=value;row.progression_payload=JSON.stringify(progression);}
    else if(item.unlock.kind==='league_wins')row.wins=value;
    else row.story_cleared=value;
   };
   setProgress(item.unlock.threshold-1);
   assert(!earnedCosmetics(row).includes(item.inventory_id),id+' is not earned early');
   setProgress(item.unlock.threshold);
   assert(earnedCosmetics(row).includes(item.inventory_id),id+' is earned at exact threshold');
   const denied=await request(f.mf,owner,'/v1/fighters/'+fighter.fighter_id,'PATCH',{expected_revision:fighter.revision,appearance:{[item.slot]:id}});
   assert.equal(denied.status,403,id+' cannot be equipped by a preview');
   await f.db.prepare(grantSQL(owner.account_id,item.inventory_id)).run();
   const equipped=await request(f.mf,owner,'/v1/fighters/'+fighter.fighter_id,'PATCH',{expected_revision:fighter.revision,appearance:{[item.slot]:id}});
   assert.equal(equipped.status,200,JSON.stringify(equipped.body));
   assert.deepEqual(equipped.body.data.progression,fighter.progression);
   assert.deepEqual(equipped.body.data.combatant.stats,fighter.combatant.stats);
   fighter=equipped.body.data;
  }
 } finally {await f.close();}
});
