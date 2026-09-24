import {test} from 'node:test';
import assert from 'node:assert/strict';
import {fixture,account,request} from './helpers.mjs';
import {grantSQL,catalog} from '../scripts/admin.mjs';
import {captureFighterSnapshot,readOwnedSnapshot} from '../src/snapshots.js';
import {canonical,sha256} from '../src/crypto.js';
import {validateName,validateAppearance} from '../src/catalog.js';

test('Worker/D1: authenticated ownership, atomic equip and optimistic races, immutable history, durable restart',async(t)=>{
 let f=await fixture();t.after(()=>f.close());
 const a=await account(f.db),b=await account(f.db);
 await t.test('authentication is a hashed expiring credential, never an identity header',async()=>{
  assert.equal((await request(f.mf,null,'/v1/fighters','GET',undefined,{'X-Account-ID':a.account_id})).status,401);
  assert.equal((await request(f.mf,{token:'public-dev-secret'},'/v1/fighters')).status,401);
  const list=await request(f.mf,a,'/v1/fighters');assert.deepEqual(list.body.data.fighters,[]);
  const rows=(await f.db.prepare('SELECT * FROM local_sessions').all()).results;
  assert.equal(rows.length,2);assert.equal(rows[0].token_hash.length,64);assert.ok(!JSON.stringify(rows).includes(a.token));
  const nonlocal=await f.mf.dispatchFetch('https://example.com/v1/fighters',{headers:{Authorization:'Bearer '+a.token}});assert.equal(nonlocal.status,503);
  await f.db.prepare('UPDATE local_sessions SET expires_at=0 WHERE account_id=?').bind(b.account_id).run();
  assert.equal((await request(f.mf,b,'/v1/fighters')).status,401);
  await f.db.prepare('UPDATE local_sessions SET expires_at=? WHERE account_id=?').bind(Date.now()+60000,b.account_id).run();
 });
 let first;
 await t.test('canonical catalog, starter inventory and separate stable IDs',async()=>{
  const cat=(await request(f.mf,a,'/v1/catalog')).body.data;
  assert.deepEqual(cat.items.map(item=>item.inventory_id).sort(),catalog.items.map(item=>item.inventory_id).sort());
  assert.deepEqual(cat.slots.map(slot=>slot.id).sort(),catalog.slots.map(slot=>slot.id).sort());
  assert.equal(cat.version,catalog.version);
  assert.equal(cat.catalog_hash,await sha256(canonical(catalog)));
  const owned=(await request(f.mf,a,'/v1/owned')).body.data;
  assert.deepEqual(owned.owned.map(item=>item.inventory_id).sort(),[...catalog.starter_owned].sort());
  assert.ok(!owned.owned.some(i=>i.inventory_id==='palette:luna'));
  const created=await request(f.mf,a,'/v1/fighters','POST',{archetype_id:'tepa',display_name:'  Tepa  del Sol  '});assert.equal(created.status,201,JSON.stringify(created.body));first=created.body.data;
  assert.equal(first.identity.display_name,'Tepa del Sol');assert.equal(first.account_id,a.account_id);assert.notEqual(first.fighter_id,a.account_id);assert.equal(first.appearance.body_style_id,'tepa');
  assert.deepEqual((await request(f.mf,a,'/v1/fighters/'+first.fighter_id)).body.data,first);
  assert.deepEqual((await request(f.mf,a,'/v1/fighters')).body.data.fighters.find(f=>f.fighter_id===first.fighter_id),first);
  assert.equal((await request(f.mf,a,'/v1/fighters','POST',{archetype_id:'tepa',display_name:'Repetida'})).status,409);
  assert.equal((await request(f.mf,b,'/v1/fighters','POST',{archetype_id:'tepa',display_name:'Tepa del Sol'})).status,201);
  assert.equal((await request(f.mf,b,'/v1/fighters/'+first.fighter_id)).status,404);
  assert.equal((await request(f.mf,b,'/v1/fighters/'+first.fighter_id,'PATCH',{expected_revision:1,display_name:'Intruso'})).status,404);
 });
 await t.test('validation rejects arbitrary paths, slots, ownership grants and gameplay edits with no partial name writes',async()=>{
  for(const patch of [
   {appearance:{shader:'evil'}},{appearance:{palette_id:'res://evil.png'}},{appearance:{palette_id:'luna'}},{appearance:{body_style_id:'ascua'}},{owned:['aura:corona']},{account_id:b.account_id},{progression:{level:50}},{archetype_id:'mugo'}
  ]) {
   const res=await request(f.mf,a,'/v1/fighters/'+first.fighter_id,'PATCH',{expected_revision:1,display_name:'Changed',...patch});assert.ok([403,422].includes(res.status),JSON.stringify(res));
   assert.equal((await request(f.mf,a,'/v1/fighters/'+first.fighter_id)).body.data.identity.display_name,'Tepa del Sol');
  }
  for(const name of ['A','a'.repeat(25),'ADMIN','Sistema','Moderador','Administrador','System','Moderator','---',"''",'A\nB','A\tB','A\u200bB','A\u202eB','E\u0301lite','🔥 Sol','A/B']) assert.throws(()=>validateName(name),undefined,name);
  for(const name of ["O'Neal",'Águila 2','山の火','Sol-Luna','a'.repeat(24)]) assert.equal(validateName(name).display_name,name);
  assert.equal((await request(f.mf,a,'/v1/fighters/'+first.fighter_id,'PATCH',{display_name:'Sol'})).status,422);

 });
 await t.test('simultaneous combined name/equipment updates have exactly one winner',async()=>{
  const before=(await request(f.mf,a,'/v1/fighters/'+first.fighter_id)).body.data;
  const updates=[{display_name:'Jade Uno',appearance:{palette_id:'jade',body_style_id:'xuna'}},{display_name:'Ocaso Dos',appearance:{palette_id:'ocaso',body_style_id:'copal'}}];
  const responses=await Promise.all(updates.map(p=>request(f.mf,a,'/v1/fighters/'+first.fighter_id,'PATCH',{expected_revision:1,...p})));
  assert.deepEqual(responses.map(r=>r.status).sort(),[200,409]);
  const winner=responses.find(r=>r.status===200).body.data;assert.equal(winner.revision,2);assert.equal(winner.archetype_id,'tepa');assert.deepEqual(winner.progression,before.progression);
  const index=winner.identity.display_name==='Jade Uno'?0:1;assert.equal(winner.appearance.palette_id,updates[index].appearance.palette_id);assert.equal(winner.appearance.body_style_id,updates[index].appearance.body_style_id);
  first=winner;
 });
 await t.test('D1 trigger rolls back both identity and revision when inventory changes at the write boundary',async()=>{
  await assert.rejects(()=>f.db.batch([
   f.db.prepare('UPDATE fighters SET revision=revision+1 WHERE id=?').bind(first.fighter_id),
   f.db.prepare('UPDATE fighter_identity SET display_name=? WHERE fighter_id=?').bind('Must Roll Back',first.fighter_id),
   f.db.prepare('UPDATE fighter_appearance SET palette_id=? WHERE fighter_id=?').bind('luna',first.fighter_id)
  ]),/COSMETIC_NOT_OWNED/);
  const unchanged=(await request(f.mf,a,'/v1/fighters/'+first.fighter_id)).body.data;assert.equal(unchanged.revision,first.revision);assert.equal(unchanged.identity.display_name,first.identity.display_name);
  await f.db.prepare(grantSQL(a.account_id,'palette:luna')).run();
  const equipped=await request(f.mf,a,'/v1/fighters/'+first.fighter_id,'PATCH',{expected_revision:first.revision,appearance:{palette_id:'luna'}});assert.equal(equipped.status,200);first=equipped.body.data;
  await assert.rejects(()=>f.db.prepare('DELETE FROM owned_cosmetics WHERE account_id=? AND inventory_id=?').bind(a.account_id,'palette:luna').run(),/COSMETIC_EQUIPPED/);
 });
 let snapshot;
 await t.test('server-only snapshot reads authoritative records, hash and name remain fixed after rename',async()=>{
  snapshot=await captureFighterSnapshot(f.db,{fighter_id:first.fighter_id,kind:'battle_participant',reference_id:'trusted-existing-battle-fixture'});
  assert.equal(snapshot.sha256,await sha256(canonical(snapshot.fighter)));assert.deepEqual(snapshot.fighter.appearance,first.appearance);
  assert.equal((await request(f.mf,a,'/v1/snapshots','POST',{fighter_id:first.fighter_id})).status,404);
  await assert.rejects(()=>captureFighterSnapshot(f.db,{fighter_id:first.fighter_id,kind:'battle_participant',reference_id:'x',appearance:{palette_id:'original'}}));
  const changed=await request(f.mf,a,'/v1/fighters/'+first.fighter_id,'PATCH',{expected_revision:first.revision,display_name:'Nueva Identidad',appearance:{palette_id:'original'}});assert.equal(changed.status,200);first=changed.body.data;
  assert.deepEqual(await captureFighterSnapshot(f.db,{fighter_id:first.fighter_id,kind:'battle_participant',reference_id:'trusted-existing-battle-fixture'}),snapshot);
  assert.equal((await request(f.mf,b,'/v1/snapshots/'+snapshot.snapshot_id)).status,404);
  const historical=(await request(f.mf,a,'/v1/snapshots/'+snapshot.snapshot_id)).body.data;assert.equal(historical.fighter.appearance.palette_id,'luna');assert.notEqual(historical.fighter.identity.display_name,first.identity.display_name);
  const preview=(await request(f.mf,b,'/v1/opponents/'+first.fighter_id)).body.data;assert.equal(preview.identity.display_name,'Nueva Identidad');assert.equal(preview.account_id,undefined);assert.equal(preview.appearance.palette_id,'original');
  await assert.rejects(()=>f.db.prepare('UPDATE fighter_snapshots SET payload=? WHERE id=?').bind('{}',snapshot.snapshot_id).run(),/SNAPSHOT_IMMUTABLE/);
  await assert.rejects(()=>f.db.prepare('DELETE FROM fighter_snapshots WHERE id=?').bind(snapshot.snapshot_id).run(),/SNAPSHOT_IMMUTABLE/);
  await assert.rejects(()=>captureFighterSnapshot(f.db,{fighter_id:crypto.randomUUID(),kind:'opponent_listing',reference_id:'missing'}),/No se encontró/);
 });
 await t.test('durable D1 state survives runtime restart without changing IDs, appearance, inventory or snapshot',async()=>{
  const dir=f.dir;await f.close(false);f=await fixture(dir,false);
  assert.deepEqual((await request(f.mf,a,'/v1/fighters/'+first.fighter_id)).body.data,first);
  assert.deepEqual(await readOwnedSnapshot(f.db,snapshot.snapshot_id,a.account_id),snapshot);
  assert.ok((await request(f.mf,a,'/v1/owned')).body.data.owned.some(i=>i.inventory_id==='palette:luna'));
  await f.db.prepare('UPDATE local_sessions SET revoked_at=? WHERE account_id=?').bind(Date.now(),a.account_id).run();assert.equal((await request(f.mf,a,'/v1/fighters')).status,401);
 });
});

test('production mode fails closed without an identity provider',async(t)=>{
 const f=await fixture(undefined,true,{AUTH_MODE:'production'});t.after(()=>f.close());const a=await account(f.db);
 const res=await request(f.mf,a,'/v1/fighters');assert.equal(res.status,503);assert.equal(res.body.error.code,'AUTH_NOT_CONFIGURED');
});
