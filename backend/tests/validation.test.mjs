import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile,stat} from 'node:fs/promises';
import {fixture,account,request} from './helpers.mjs';
import {catalog,validateAppearance,defaultAppearance,validateName} from '../src/catalog.js';
import {catalogSQL,credentialSQL,newCredential,grantSQL} from '../scripts/admin.mjs';
import {captureFighterSnapshot} from '../src/snapshots.js';
import {canonical,sha256} from '../src/crypto.js';

test('HTTP boundaries: body limits, malformed JSON, Unicode policy and ignored-field attacks',async(t)=>{
 const f=await fixture();t.after(()=>f.close());const a=await account(f.db);
 const raw=async(body,headers={})=>f.mf.dispatchFetch('http://127.0.0.1/v1/fighters',{method:'POST',headers:{Authorization:'Bearer '+a.token,'Content-Type':'application/json',...headers},body});
 assert.equal((await raw('{')).status,400);
 assert.equal((await raw('{}',{'Content-Type':'text/plain'})).status,415);
 assert.equal((await raw(' '.repeat(8193))).status,413);
 for(const body of [null,[],{archetype_id:'nima',display_name:'Admin'},{archetype_id:'nima',display_name:'\u00a0Sol\u00a0'},{archetype_id:'nima',display_name:'A\u0000B'},{archetype_id:'nima',display_name:'E\u0301lite'},{archetype_id:'nima',display_name:'OK',account_id:'stolen'},{archetype_id:'nima',display_name:'OK',appearance:{aura_id:'corona'}}])
  assert.equal((await request(f.mf,a,'/v1/fighters','POST',body)).status,422,JSON.stringify(body));
 const p=JSON.parse('{"archetype_id":"nima","display_name":"OK","__proto__":{"owned":true}}');assert.equal((await request(f.mf,a,'/v1/fighters','POST',p)).status,422);
 assert.deepEqual((await request(f.mf,a,'/v1/fighters')).body.data.fighters,[]);
 for(const [archetype_id,display_name] of [['nima',"Águila O'Neal 2"],['luma','山の火'],['mugo','  Sol   Luna  ']]) {
  const res=await request(f.mf,a,'/v1/fighters','POST',{archetype_id,display_name});assert.equal(res.status,201);assert.equal(res.body.data.identity.display_name,validateName(display_name).display_name);assert.equal(res.headers.get('Cache-Control'),'no-store');
 }
});

test('compatibility is validated from the canonical definition, independent of inventory',async(t)=>{
 const f=await fixture();t.after(()=>f.close());const a=await account(f.db);
 const item=catalog.items.find(i=>i.inventory_id==='palette:jade');const bodies=item.compatible_body_styles,archetypes=item.compatible_archetypes;
 try {
  item.compatible_body_styles=['xuna'];
  await assert.rejects(()=>validateAppearance(f.db,a.account_id,'nima',{...defaultAppearance('nima'),palette_id:'jade'}),e=>e.code==='INCOMPATIBLE_COSMETIC');
  await validateAppearance(f.db,a.account_id,'nima',{...defaultAppearance('xuna'),palette_id:'jade'});
  item.compatible_archetypes=['mugo'];
  await assert.rejects(()=>validateAppearance(f.db,a.account_id,'nima',{...defaultAppearance('xuna'),palette_id:'jade'}),e=>e.code==='INCOMPATIBLE_COSMETIC');
 } finally {item.compatible_body_styles=bodies;item.compatible_archetypes=archetypes;}
});

test('snapshot concurrency uses one immutable ID and nonexistent fighters cannot be captured',async(t)=>{
 const f=await fixture();t.after(()=>f.close());const a=await account(f.db);
 const player=(await request(f.mf,a,'/v1/fighters','POST',{archetype_id:'xuna',display_name:'Guardiana'})).body.data;
 const snapshots=await Promise.all(Array.from({length:5},()=>captureFighterSnapshot(f.db,{fighter_id:player.fighter_id,kind:'opponent_listing',reference_id:'listing-fixture'})));
 assert.equal(new Set(snapshots.map(s=>s.snapshot_id)).size,1);assert.equal(new Set(snapshots.map(s=>s.sha256)).size,1);
 assert.equal((await f.db.prepare('SELECT COUNT(*) AS n FROM fighter_snapshots').first()).n,1);
 await assert.rejects(()=>captureFighterSnapshot(f.db,{fighter_id:'bad',kind:'opponent_listing',reference_id:'invalid'}),e=>e.code==='FIGHTER_NOT_FOUND');
});

test('seed is idempotent, catalog parity is enforced, and grants need a real account and item',async(t)=>{
 const f=await fixture();t.after(()=>f.close());const a=await account(f.db);
 await f.db.batch(catalogSQL().map(s=>f.db.prepare(s)));
 assert.equal((await f.db.prepare('SELECT COUNT(*) AS n FROM cosmetic_definitions').first()).n,catalog.items.length);
 assert.throws(()=>grantSQL(a.account_id,'palette:invented'));
 await assert.rejects(()=>f.db.prepare(grantSQL('missing-account','palette:luna')).run(),/FOREIGN KEY/);
 const invalidCredential=newCredential('missing-account');
 await assert.rejects(()=>f.db.batch(credentialSQL(invalidCredential,false).map(s=>f.db.prepare(s))),/FOREIGN KEY/);
 assert.equal((await f.db.prepare('SELECT COUNT(*) AS n FROM local_sessions').first()).n,1);
 // All catalog tables are administrative: no HTTP writer exists. A missing
 // migration/seed is reported explicitly rather than serving mismatched IDs.
 await f.db.prepare('DELETE FROM cosmetic_definitions WHERE inventory_id=?').bind('palette:luna').run();
 const unavailable=await request(f.mf,a,'/v1/catalog');assert.equal(unavailable.status,503);assert.equal(unavailable.body.error.code,'CATALOG_NOT_SEEDED');
});

test('generated canonical export matches source exactly; production config has no deploy target or secrets',async()=>{
 const original=JSON.parse(await readFile('../data/cosmetic_catalog.json','utf8'));
 const generated=JSON.parse(await readFile('generated/cosmetic_catalog.json','utf8'));assert.deepEqual(generated,original);
 const config=JSON.parse(await readFile('wrangler.jsonc','utf8'));assert.equal(config.workers_dev,false);assert.equal(config.preview_urls,false);assert.equal(config.account_id,undefined);assert.equal(config.vars.AUTH_MODE,'local_dev');
 const pkg=JSON.parse(await readFile('package.json','utf8'));assert.equal(pkg.scripts.deploy,undefined);
});

test('historical appearance resolves its pinned catalog version, not newly changed presentation values',async(t)=>{
 const f=await fixture();t.after(()=>f.close());const a=await account(f.db);
 const old=structuredClone(catalog);old.version=0;old.items.find(i=>i.inventory_id==='palette:jade').color='102030';
 const hash=await sha256(canonical(old));
 await f.db.prepare('INSERT INTO catalog_versions(hash,version,payload,created_at) VALUES (?,?,?,?)').bind(hash,0,canonical(old),new Date().toISOString()).run();
 const result=await request(f.mf,a,'/v1/catalog?hash='+hash);assert.equal(result.status,200);assert.equal(result.body.data.items.find(i=>i.inventory_id==='palette:jade').color,'102030');assert.equal(result.body.data.catalog_hash,hash);
 assert.equal((await request(f.mf,a,'/v1/catalog?hash='+('0'.repeat(64)))).status,404);
 assert.equal((await request(f.mf,a,'/v1/catalog?hash=invalid')).status,422);
});
