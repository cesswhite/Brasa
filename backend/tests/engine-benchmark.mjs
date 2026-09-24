// Development-only simulator. No DB, HTTP, Godot UI or user save access.
import {performance} from 'node:perf_hooks';
import {writeFileSync,readFileSync,mkdirSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {BattleEngine,buildCombatant,gameCatalog,ENGINE_VERSION,CATALOG_VERSION,RNG_VERSION,getStoryOpponent} from '../battle-engine/index.js';
const count=Number(process.argv[2]??10000);if(!Number.isInteger(count)||count<1000||count>100000)throw Error('Expected1000..100000 battles');
const out=process.argv[3]??new URL('../../../../work/arena-engine/benchmark.json',import.meta.url).pathname;
const ids=gameCatalog.character_ids,levels=[1,10,25,50];
const profiles=Object.fromEntries(ids.map(id=>[id,Object.fromEntries(levels.map(level=>[level,buildCombatant({character_id:id,level,allocations:{max_hp:4,attack:4,defense:3,speed:4,accuracy:2,evasion:2,crit_chance:2,resistance:2}})]))]));
const stats={battles:count,signatures_armed:0,signatures_executed:0,attack_attempts:0,hits:0,criticals:0,dodges:0,statuses_applied:0,counters:0,total_damage:0,total_turns:0,total_duration:0,timeouts:0,move_usage:{},wins:{player:0,rival:0},by_character:{}};
const ms=[],bytes=[],events=[];const cpuStart=process.cpuUsage(),start=performance.now();
for(let i=0;i<count;i++){
  const a=profiles[ids[i%ids.length]][levels[Math.floor(i/ids.length)%4]],b=profiles[ids[(i*7+3)%ids.length]][levels[Math.floor(i/ids.length)%4]];
  const t=performance.now(),engine=new BattleEngine();engine.start(a,b,String(100001+i));
  for(const side of ['player','rival'])stats.signatures_armed+=engine.fighters[side].signature_armed?1:0;
  engine.advance(60);const result=engine.terminal_summary;ms.push(performance.now()-t);bytes.push(Buffer.byteLength(JSON.stringify(result)));events.push(result.events.length);
  if(!result.winner||!Number.isFinite(result.duration)||result.duration>60)throw Error('Invalid terminal battle');
  stats.wins[result.winner]++;stats.total_duration+=result.duration;stats.total_turns+=result.turns;if(result.reason==='timeout')stats.timeouts++;
  for(const side of ['player','rival']){
    const m=result.metrics[side],id=result[side].character_id;stats.by_character[id]??={battles:0,wins:0};stats.by_character[id].battles++;stats.by_character[id].wins+=result.winner===side?1:0;
    stats.signatures_executed+=m.signatures;stats.attack_attempts+=m.attacks;stats.hits+=m.hits;stats.criticals+=m.criticals;stats.dodges+=m.dodges;stats.statuses_applied+=m.statuses_applied;stats.counters+=m.counters;stats.total_damage+=m.damage_dealt;
    for(const [id,n]of Object.entries(m.move_uses))stats.move_usage[id]=(stats.move_usage[id]??0)+n;
  }
  if((i+1)%1000===0)console.log('BENCHMARK_PROGRESS',i+1,count);
}
const elapsed=performance.now()-start,cpu=process.cpuUsage(cpuStart);
const percentile=(values,p)=>[...values].sort((a,b)=>a-b)[Math.min(values.length-1,Math.floor(values.length*p))];
const aggregate=values=>({mean:values.reduce((a,b)=>a+b,0)/values.length,p50:percentile(values,.5),p95:percentile(values,.95),p99:percentile(values,.99),max:Math.max(...values)});
const visualMs=[],visualBytes=[];
for(let i=0;i<200;i++){
  const a=profiles[ids[i%13]][50],b=i%2?getStoryOpponent(100):profiles[ids[(i+3)%13]][50];
  const t=performance.now(),e=new BattleEngine();e.start(a,b,String(800001+i),{include_states:true});e.advance(60);visualMs.push(performance.now()-t);visualBytes.push(Buffer.byteLength(JSON.stringify(e.terminal_summary)));
}
const sourceHashes={};for(const f of ['engine.js','catalog.js','rng.js','rules.js','effects.js','util.js'])sourceHashes[f]=createHash('sha256').update(readFileSync(new URL('../battle-engine/'+f,import.meta.url))).digest('hex');
const result={engine_version:ENGINE_VERSION,catalog_version:CATALOG_VERSION,rng_version:RNG_VERSION,node:process.version,platform:process.platform,architecture:process.arch,method:'10,000 seeded balanced AI autobattles,13 characters,levels1/10/25/50 with common allocations. Separate200 visual-state cases include finalboss. Timings are this Node process, not measured Cloudflare production CPU.',seed_start:'100001',stats,signature_arm_rate:stats.signatures_armed/(count*2),signature_execution_rate:stats.signatures_executed/(count*2),duration_seconds:stats.total_duration/count,turns:stats.total_turns/count,critical_per_hit:stats.criticals/Math.max(1,stats.hits),dodges_per_attempt:stats.dodges/Math.max(1,stats.attack_attempts),total_wall_ms:elapsed,total_cpu_ms:(cpu.user+cpu.system)/1000,core_simulation_ms:aggregate(ms),events:aggregate(events),payload_bytes:aggregate(bytes),with_visual_states:{battles:200,simulation_ms:aggregate(visualMs),payload_bytes:aggregate(visualBytes)},source_hashes:sourceHashes,catalog_sha256:createHash('sha256').update(readFileSync(new URL('../data/game-catalog.json',import.meta.url))).digest('hex')};
if(result.signature_arm_rate<.006||result.signature_arm_rate>.014)throw Error('Unexpected signature arming frequency');
mkdirSync(new URL('.', 'file://'+out).pathname,{recursive:true});writeFileSync(out,JSON.stringify(result,null,2)+'\n');console.log('BENCHMARK_COMPLETE',JSON.stringify({battles:count,signatures:result.signature_arm_rate,mean_ms:result.core_simulation_ms.mean,p95_ms:result.core_simulation_ms.p95,p95_bytes:result.payload_bytes.p95,visual_p95_bytes:result.with_visual_states.payload_bytes.p95,output:out}));
