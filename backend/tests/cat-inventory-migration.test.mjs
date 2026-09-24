import test from 'node:test';
import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import {fixture,request} from './helpers.mjs';
import {catalogSQL,credentialSQL,newCredential,catalog,grantSQL} from '../scripts/admin.mjs';
import {starterExpansionSQL} from '../scripts/starter-expansions.mjs';
const added=['body_style:onix','body_style:bruma'];
async function legacyAccount(db) {
  const c=newCredential();
  await db.batch(credentialSQL(c).filter(sql=>!added.some(id=>sql.includes("'"+id+"'"))).map(sql=>db.prepare(sql)));
  return c;
}
const owned=async(db,id)=>(await db.prepare('SELECT * FROM owned_cosmetics WHERE account_id=? ORDER BY inventory_id').bind(id).all()).results;
const seed=async db=>db.batch(catalogSQL().map(sql=>db.prepare(sql)));
async function makeFighter(f,owner,id='sira',name='Nombre anterior') {
  const response=await request(f.mf,owner,'/v1/fighters','POST',{archetype_id:id,display_name:name},{'Idempotency-Key':randomUUID()});
  assert.equal(response.status,201,JSON.stringify(response.body));
  return response.body.data;
}
async function beforeExpansion(f) {
  // Latest-schema fixture starts seeded. This simulates the point after migration
  // 0005 and before the first expansion seed, while the fixture has no users.
  await f.db.prepare('DELETE FROM catalog_starter_expansions').run();
}
test('old accounts receive only two new free bodies, retaining identities, progression and rewards',async()=>{
  const f=await fixture();
  try {
    await beforeExpansion(f);
    const owner=await legacyAccount(f.db);
    const original=await makeFighter(f,owner);
    const training=await request(f.mf,owner,`/v1/fighters/${original.fighter_id}/allocate`,'POST',{expected_revision:original.progression_revision,stat:'attack',amount:1},{'Idempotency-Key':randomUUID()});
    assert.equal(training.status,200);
    const prior=(await request(f.mf,owner,`/v1/fighters/${original.fighter_id}`)).body.data;
    const before=await owned(f.db,owner.account_id);
    assert.equal(before.length,22);
    for(const id of ['onix','bruma']) {
      const blocked=await request(f.mf,owner,'/v1/fighters','POST',{archetype_id:id,display_name:id},{'Idempotency-Key':randomUUID()});
      assert.equal(blocked.status,403);
      assert.equal(blocked.body.error.code,'COSMETIC_NOT_OWNED');
    }
    await seed(f.db);
    const after=await owned(f.db,owner.account_id);
    assert.equal(after.length,24);
    assert.deepEqual(after.filter(row=>!added.includes(row.inventory_id)),before);
    assert.deepEqual(after.filter(row=>added.includes(row.inventory_id)).map(row=>row.inventory_id),['body_style:bruma','body_style:onix']);
    assert.ok(after.filter(row=>added.includes(row.inventory_id)).every(row=>row.source==='starter_expansion'));
    assert.ok(!after.some(row=>row.inventory_id==='palette:luna'||row.inventory_id==='aura:corona'));
    assert.deepEqual((await request(f.mf,owner,`/v1/fighters/${original.fighter_id}`)).body.data,prior);
    for(const id of ['onix','bruma']) {
      const cat=await makeFighter(f,owner,id,id==='onix'?'Ónix':'Bruma');
      assert.equal(cat.appearance.body_style_id,id);
      assert.equal(cat.progression.level,1);
      assert.equal(cat.progression.stat_points,3);
    }
    const restored=(await request(f.mf,owner,'/v1/fighters')).body.data.fighters;
    assert.equal(restored.length,3);
    assert.deepEqual(restored.find(row=>row.fighter_id===prior.fighter_id),prior);
    assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM catalog_starter_expansions').first()).n,1);
  } finally {await f.close();}
});
test('reseed preserves missing older defaults and revoked new bodies instead of restoring inventory',async()=>{
  const f=await fixture();
  try {
    await beforeExpansion(f);
    const owner=await legacyAccount(f.db);
    await f.db.prepare("DELETE FROM owned_cosmetics WHERE account_id=? AND inventory_id='palette:jade'").bind(owner.account_id).run();
    await f.db.prepare(grantSQL(owner.account_id,'aura:farol','server_achievement')).run();
    const reward=(await owned(f.db,owner.account_id)).find(row=>row.inventory_id==='aura:farol');
    await seed(f.db);
    assert.ok(!(await owned(f.db,owner.account_id)).some(row=>row.inventory_id==='palette:jade'));
    assert.deepEqual((await owned(f.db,owner.account_id)).find(row=>row.inventory_id==='aura:farol'),reward);
    await f.db.prepare("DELETE FROM owned_cosmetics WHERE account_id=? AND inventory_id IN ('body_style:bruma','aura:farol')").bind(owner.account_id).run();
    const before=await owned(f.db,owner.account_id);
    await seed(f.db);
    await seed(f.db);
    assert.deepEqual(await owned(f.db,owner.account_id),before);
    const result=await request(f.mf,owner,'/v1/fighters','POST',{archetype_id:'bruma',display_name:'Bruma'},{'Idempotency-Key':randomUUID()});
    assert.equal(result.status,403);
    assert.equal(result.body.error.code,'COSMETIC_NOT_OWNED');
  } finally {await f.close();}
});
test('failed expansion rolls back and retries safely; concurrent seeds grant once',async()=>{
  const f=await fixture();
  try {
    await beforeExpansion(f);
    const owners=[await legacyAccount(f.db),await legacyAccount(f.db)];
    const before=await Promise.all(owners.map(owner=>owned(f.db,owner.account_id)));
    await f.db.prepare("CREATE TRIGGER reject_cat_expansion BEFORE INSERT ON owned_cosmetics WHEN NEW.inventory_id='body_style:bruma' BEGIN SELECT RAISE(ABORT,'INJECTED_CAT_FAILURE'); END;").run();
    await assert.rejects(()=>seed(f.db),/INJECTED_CAT_FAILURE/);
    assert.deepEqual(await Promise.all(owners.map(owner=>owned(f.db,owner.account_id))),before);
    assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM catalog_starter_expansions').first()).n,0);
    await f.db.prepare('DROP TRIGGER reject_cat_expansion').run();
    await Promise.all([seed(f.db),seed(f.db)]);
    for(const owner of owners)assert.equal((await owned(f.db,owner.account_id)).length,24);
    assert.equal((await f.db.prepare('SELECT COUNT(*) n FROM catalog_starter_expansions').first()).n,1);
    const exact=await Promise.all(owners.map(owner=>owned(f.db,owner.account_id)));
    await seed(f.db);
    assert.deepEqual(await Promise.all(owners.map(owner=>owned(f.db,owner.account_id))),exact);
  } finally {await f.close();}
});
test('expansion cannot grant an item that is not a current starter default',()=>{
  const bad=structuredClone(catalog);
  bad.items.find(item=>item.inventory_id==='body_style:onix').default=false;
  assert.throws(()=>starterExpansionSQL(bad,x=>x,'test'),/not a catalog default/);
  const missing=structuredClone(catalog);
  missing.starter_owned=missing.starter_owned.filter(id=>id!=='body_style:bruma');
  assert.throws(()=>starterExpansionSQL(missing,x=>x,'test'),/not a catalog default/);
});
