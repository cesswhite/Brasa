import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {gunzipSync} from 'node:zlib';
import {createHash} from 'node:crypto';
import {simulateBattle,GodotRng,statsForProfile,resolveMove} from '../battle-engine/index.js';
const corpus=JSON.parse(gunzipSync(readFileSync(new URL('./fixtures/engine-godot.json.gz',import.meta.url))));
function compare(a,b,path='root') {
  if(typeof a==='number'&&typeof b==='number'){assert.equal(a,b,path);return;}
  if(Array.isArray(b)){assert.equal(a.length,b.length,path+'.length');for(let i=0;i<b.length;i++)compare(a[i],b[i],path+'['+i+']');return;}
  if(b&&typeof b==='object'){for(const key of Object.keys(b)){if(key==='message')continue;assert.ok(Object.hasOwn(a,key),path+'.'+key+' missing');compare(a[key],b[key],path+'.'+key);}return;}
  assert.equal(a,b,path);
}
test('Godot PCG exact 2160 mixed uint32/float/range/rejection outputs including uint64 seeds',()=>{
  for(const v of corpus.rng_vectors){const rng=new GodotRng(v.seed);for(const e of v.values)assert.deepEqual({randi:rng.randi(),randf:rng.randf(),range:rng.randf_range(1.8,2.3),bounded:rng.randi_range(2,5),variance:rng.randf_range(.92,1.08),wide:rng.randi_range(-1000000000,1147483648)},e);}
});
test('All 15 Story stat formulas, including both cats, match levels1/10/25/50 with independent allocations',()=>{
  assert.equal(corpus.stats.length,60);
  for(const id of ['onix','bruma'])assert.equal(corpus.stats.filter(row=>row.profile.character_id===id).length,4);
  for(const row of corpus.stats)compare(statsForProfile(row.profile),row.expected,row.profile.character_id+row.profile.level);
});
test('Golden corpus is bound to the exact exported catalog',()=>assert.equal(createHash('sha256').update(readFileSync(new URL('../data/game-catalog.json',import.meta.url))).digest('hex'),corpus.catalog_sha256));
test('All1020 resolved techniques,tiers and perk combinations match Godot exactly',()=>{
  assert.equal(corpus.moves.length,1020);
  for(const row of corpus.moves)compare(resolveMove(row.character_id,row.move_id,row.tier,row.perks),row.expected,row.move_id+'/'+row.tier);
});
for(const row of corpus.battles)test('Godot parity: '+row.id,()=>compare(simulateBattle(row.player,row.rival,row.seed,row.options),row.expected,row.id));
