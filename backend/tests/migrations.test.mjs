import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile,readdir} from 'node:fs/promises';
import {Miniflare} from 'miniflare';
import {unstable_splitSqlQuery} from 'wrangler';

test('deployment migrations use Wrangler SQL parsing and preserve D1 ownership guards',async(t)=>{
  const mf=new Miniflare({modules:true,script:'export default {fetch(){return new Response("migration fixture")}}',compatibilityDate:'2026-07-08',d1Databases:{DB:'migration-regression'}});
  t.after(()=>mf.dispose());
  const db=await mf.getD1Database('DB');
  const directory=new URL('../migrations/',import.meta.url);
  const files=(await readdir(directory)).filter(name=>name.endsWith('.sql')).sort();
  assert.equal(files.length,5);
  for(const file of files) {
    await t.test('apply '+file+' with the installed Wrangler parser',async()=>{
      // This is Wrangler's actual local deployment path, not the test helper's line parser.
      const statements=unstable_splitSqlQuery(await readFile(new URL(file,directory),'utf8'));
      const results=await db.batch(statements.map(sql=>db.prepare(sql)));
      assert.equal(results.length,statements.length);
      assert.ok(results.every(result=>result.success));
    });
  }
  const triggers=(await db.prepare("SELECT name FROM sqlite_schema WHERE type='trigger' ORDER BY name").all()).results.map(row=>row.name);
  assert.deepEqual(triggers,['appearance_owned_insert','appearance_owned_update','inventory_preserve_equipped','online_battles_immutable_delete','online_battles_immutable_update','snapshots_immutable_delete','snapshots_immutable_update']);
  assert.ok((await db.prepare('PRAGMA table_info(accounts)').all()).results.some(row=>row.name==='is_test'));
  assert.ok(await db.prepare("SELECT name FROM sqlite_schema WHERE name='auth_passkey'").first());
  assert.ok(await db.prepare("SELECT name FROM sqlite_schema WHERE name='offline_activity'").first());

  const slots=['body_style_id','palette_id','aura_id','trail_id','victory_pose_id','intro_animation_id'];
  await db.batch([
    db.prepare("INSERT INTO accounts(id,created_at) VALUES ('owner','fixture'),('other','fixture')"),
    db.prepare("INSERT INTO catalog_versions VALUES ('fixture',1,'{}','fixture')"),
    ...slots.map(slot=>db.prepare("INSERT INTO cosmetic_definitions VALUES (?,?,'base','{}','fixture')").bind(slot+':base',slot)),
    db.prepare("INSERT INTO cosmetic_definitions VALUES ('palette:locked','palette_id','locked','{}','fixture')"),
    ...slots.map(slot=>db.prepare("INSERT INTO owned_cosmetics VALUES ('owner',?,'fixture','fixture')").bind(slot+':base')),
    db.prepare("INSERT INTO owned_cosmetics VALUES ('other','palette:locked','fixture','fixture')"),
    db.prepare("INSERT INTO fighters(id,account_id,archetype_id,last_mutation,created_at,updated_at) VALUES ('first','owner','first','fixture','fixture','fixture'),('second','owner','second','fixture','fixture','fixture')"),
    db.prepare("INSERT INTO fighter_identity VALUES ('first','Original','original')")
  ]);
  const appearance=(id,palette)=>db.prepare("INSERT INTO fighter_appearance VALUES (?,'base',?,'base','base','base','base')").bind(id,palette);

  await t.test('insert rejects another account inventory and accepts owned equipment',async()=>{
    await assert.rejects(()=>appearance('first','locked').run(),/COSMETIC_NOT_OWNED/);
    assert.equal(await db.prepare("SELECT * FROM fighter_appearance WHERE fighter_id='first'").first(),null);
    await appearance('first','base').run();
    await appearance('second','base').run();
    assert.equal((await db.prepare('SELECT COUNT(*) n FROM fighter_appearance').first()).n,2);
  });

  await t.test('invalid equipment rolls back the entire identity mutation; granting ownership permits it',async()=>{
    await assert.rejects(()=>db.batch([
      db.prepare("UPDATE fighters SET revision=revision+1 WHERE id='first'"),
      db.prepare("UPDATE fighter_identity SET display_name='Must roll back' WHERE fighter_id='first'"),
      db.prepare("UPDATE fighter_appearance SET palette_id='locked' WHERE fighter_id='first'")
    ]),/COSMETIC_NOT_OWNED/);
    assert.equal((await db.prepare("SELECT revision FROM fighters WHERE id='first'").first()).revision,1);
    assert.equal((await db.prepare("SELECT display_name FROM fighter_identity WHERE fighter_id='first'").first()).display_name,'Original');
    await assert.rejects(()=>db.prepare("UPDATE fighter_appearance SET palette_id='unknown' WHERE fighter_id='first'").run(),/COSMETIC_NOT_OWNED/);
    await db.prepare("INSERT INTO owned_cosmetics VALUES ('owner','palette:locked','fixture','fixture')").run();
    await db.prepare("UPDATE fighter_appearance SET palette_id='locked' WHERE fighter_id='first'").run();
    assert.equal((await db.prepare("SELECT palette_id FROM fighter_appearance WHERE fighter_id='first'").first()).palette_id,'locked');
  });

  await t.test('equipped inventory cannot be deleted; unequipped inventory can',async()=>{
    const deletion=()=>db.prepare("DELETE FROM owned_cosmetics WHERE account_id='owner' AND inventory_id='palette:locked'").run();
    await assert.rejects(deletion,/COSMETIC_EQUIPPED/);
    assert.ok(await db.prepare("SELECT inventory_id FROM owned_cosmetics WHERE account_id='owner' AND inventory_id='palette:locked'").first());
    await db.prepare("UPDATE fighter_appearance SET palette_id='base' WHERE fighter_id='first'").run();
    await deletion();
    assert.equal(await db.prepare("SELECT inventory_id FROM owned_cosmetics WHERE account_id='owner' AND inventory_id='palette:locked'").first(),null);
    assert.ok(await db.prepare("SELECT inventory_id FROM owned_cosmetics WHERE account_id='other' AND inventory_id='palette:locked'").first());
  });

  await t.test('snapshot immutability remains installed after all migrations',async()=>{
    await db.prepare("INSERT INTO fighter_snapshots VALUES ('snapshot','first','owner','opponent_listing','fixture',1,1,'fixture','{}','fixture','fixture')").run();
    await assert.rejects(()=>db.prepare("UPDATE fighter_snapshots SET payload='[]' WHERE id='snapshot'").run(),/SNAPSHOT_IMMUTABLE/);
    await assert.rejects(()=>db.prepare("DELETE FROM fighter_snapshots WHERE id='snapshot'").run(),/SNAPSHOT_IMMUTABLE/);
    assert.equal((await db.prepare("SELECT payload FROM fighter_snapshots WHERE id='snapshot'").first()).payload,'{}');
  });
});
