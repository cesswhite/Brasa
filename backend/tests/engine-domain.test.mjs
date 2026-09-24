import test from 'node:test';
import assert from 'node:assert/strict';
import {BattleEngine,simulateBattle,buildCombatant,gameCatalog,getStoryOpponent,getUnlockedMoves,getPerks,getStatOptions,validateAiConfig,AI_STYLES,normalizeSeed,CombatRules,StatusEffects} from '../battle-engine/index.js';
const fighter=(id='luma',level=20,extra={})=>buildCombatant({character_id:id,level,...extra});
test('Catalog complete: 15 identities,75 ordinary moves,90 perks,100 stable Story opponents',()=>{
  assert.equal(gameCatalog.character_ids.length,15);let moves=0,perks=0;
  for(const id of gameCatalog.character_ids){moves+=getUnlockedMoves(id,50).length;perks+=getPerks(id).length;assert.deepEqual(getUnlockedMoves(id,1).map(m=>m.unlock_level),[1,1]);}
  assert.equal(moves,75);assert.equal(perks,90);assert.equal(gameCatalog.campaign.stages.length,100);
  assert.equal(getStoryOpponent(1).story_stage_id,'river_gate');assert.equal(getStoryOpponent(2).level,2);assert.equal(getStoryOpponent(8).story_boss_id,'ascua');assert.equal(getStoryOpponent(16).story_boss_id,'vespera');assert.equal(getStoryOpponent(100).story_level,100);
  assert.equal(getStatOptions().length,8);assert.equal(getStoryOpponent(101),null);
});
test('Trusted DTO builder ignores forged derived stats/abilities/moves but validates legal build shapes',()=>{
  const plain=fighter('tepa');const forged=fighter('tepa',20,{combat_stats:{attack:999},ability:{id:'berserk'},moves:[{damage_multiplier:999}]});assert.deepEqual(forged,plain);
  for(const dto of [null,[],{character_id:'unknown'},{character_id:'tepa',level:51},{character_id:'tepa',level:NaN},{character_id:'tepa',allocations:{attack:31}},{character_id:'tepa',allocations:{attack:-1}},{character_id:'tepa',allocations:{attack:1.5}},{character_id:'tepa',allocations:{fake:1}},{character_id:'tepa',allocations:[]},{character_id:'tepa',perks:['tepa_focus','tepa_focus']},{character_id:'tepa',perks:['luma_focus']},{character_id:'tepa',move_upgrades:{tepa_fake:1}},{character_id:'tepa',level:1,move_upgrades:{[getUnlockedMoves('tepa',50)[4].id]:1}}])assert.throws(()=>buildCombatant(dto));
  const full=fighter('balam',50,{allocations:{max_hp:30,attack:30,defense:30,speed:30,accuracy:30,evasion:30,crit_chance:30,resistance:30}});
  for(const [key,limits]of Object.entries(gameCatalog.balance.stat_bounds))assert.ok(full.combat_stats[key]>=limits[0]&&full.combat_stats[key]<=limits[1]);
});
test('Input data and the shared catalog remain immutable across simulation and returned-data edits',()=>{
  const a=fighter('sira'),b=fighter('mugo');const before=JSON.stringify([a,b]);const result=simulateBattle(a,b,'91');assert.equal(JSON.stringify([a,b]),before);
  result.player.moves[0].damage_multiplier=999;assert.notEqual(fighter('sira').moves[0].damage_multiplier,999);assert.ok(Object.isFrozen(gameCatalog.characters.sira));
});
test('uint64 seed strings are exact and reject accidental float conversion or overflow',()=>{
  for(const value of ['0','1','9007199254740993','18446744073709551615'])assert.equal(normalizeSeed(value),value);
  for(const value of [1,1n,'01','-1','1.0','1e3','18446744073709551616','',null])assert.throws(()=>normalizeSeed(value));
  const a=fighter(),b=fighter('taro');assert.deepEqual(simulateBattle(a,b,'18446744073709551615'),simulateBattle(a,b,'18446744073709551615'));
});
test('Whole simulation and presentation-step simulation have identical summaries',()=>{
  for(const id of gameCatalog.character_ids){const a=fighter(id),b=fighter('taro');const whole=new BattleEngine(),step=new BattleEngine();whole.start(a,b,'894');step.start(a,b,'894');whole.advance(60);while(step.running)step.advance(.016);assert.deepEqual(step.summary(),whole.summary());}
});
test('Surrender is immediate, terminal, and prevents all queued attacks/status ticks/rewards',()=>{
  const engine=new BattleEngine();engine.start(fighter('iria'),fighter('taro'),'82',{initial_statuses:{player:[{type:'poison',magnitude:10,duration:5}]}});engine.advance(.01);
  const before=engine.snapshot();const events=engine.surrender();assert.equal(events.at(-1).type,'finished');assert.equal(engine.summary().reason,'surrender');assert.equal(engine.snapshot().fighters.player.hp,before.fighters.player.hp);
  const summary=engine.summary();for(const delta of [0,-1,NaN,Infinity,60])assert.deepEqual(engine.advance(delta),[]);assert.deepEqual(engine.surrender(),[]);assert.deepEqual(engine.summary(),summary);assert.equal(summary.xp,undefined);
});
test('Guard/negative/zero damage, shield bypass, states and duration do not create HP or invalid numbers',()=>{
  const engine=new BattleEngine();engine.start(fighter('luma'),fighter('luma'),'9');const hp=engine.player_hp;
  for(const damage of [-3,NaN,Infinity,0]){assert.equal(engine.damage('player',damage,'rival').damage,0);assert.equal(engine.player_hp,hp);}
  const effects=[];StatusEffects.apply(effects,{type:'shield',magnitude:1000,duration:99},'player',0,100);assert.equal(StatusEffects.shieldTotal(effects),25);assert.equal(effects[0].remaining_turns,5);assert.equal(StatusEffects.absorb(effects,50).remaining,25);
  StatusEffects.apply(effects,{type:'poison',magnitude:99,duration:3,stacking:'intensity',max_stacks:3},'rival',0,100);
  StatusEffects.apply(effects,{type:'poison',magnitude:99,duration:3,stacking:'intensity',max_stacks:3},'rival',0,100);assert.equal(effects[0].magnitude,4);assert.equal(effects[0].stacks,2);
  assert.equal(CombatRules.statusDuration(5,.5),4);assert.equal(CombatRules.statusChance(1,.5),.625);
});
test('Optional authoritative visual snapshots preserve identical combat and are independent deep copies',()=>{
  const a=fighter('iria'),b=fighter('duna'),plain=simulateBattle(a,b,'557'),visual=simulateBattle(a,b,'557',{include_states:true});
  assert.equal(visual.winner,plain.winner);assert.equal(visual.duration,plain.duration);assert.deepEqual(visual.metrics,plain.metrics);
  assert.ok(visual.events.every(e=>e.state&&e.state.elapsed===e.time));
  const first=visual.events[0];first.state.fighters.player.hp=-1;assert.ok(visual.final_state.fighters.player.hp>=0);
});
test('AI configuration is bounded, deterministic and cannot disable all techniques',()=>{
  assert.deepEqual(validateAiConfig(),{style:'balanced',weights:{}});
  for(const value of [null,[],{style:'unknown'},{style:'balanced',weights:{fake:1}},{weights:{quick:0}},{weights:{quick:4.1}},{weights:{quick:NaN}},{weights:[]},{weights:{quick:'2'}},{extra:1}])assert.throws(()=>validateAiConfig(value));
  const a=fighter('mugo'),b=fighter('luma');assert.deepEqual(simulateBattle(a,b,'64').events,simulateBattle({...a,ai_config:{style:'balanced',weights:{}}},b,'64').events);
  for(const style of Object.keys(AI_STYLES)){const player=fighter('taro',30,{ai_config:{style}});const x=simulateBattle(player,b,'912');assert.deepEqual(x,simulateBattle(player,b,'912'));assert.ok(Object.keys(x.metrics.player.move_uses).length>=2);}
});
test('Defensive AI changes move selection frequencies, without hidden stat or damage multipliers',()=>{
  const usage={balanced:0,defensive:0};
  for(const style of Object.keys(usage))for(let seed=1;seed<=80;seed++){
    const a=fighter('taro',30,{ai_config:{style}});assert.deepEqual(a.combat_stats,fighter('taro',30).combat_stats);
    const result=simulateBattle(a,fighter('luma',30),String(seed));for(const event of result.events)if(event.type==='move_started'&&event.side==='player'&&event.move.type==='counter'&&!event.counter)usage[style]++;
  }
  assert.ok(usage.defensive>usage.balanced*1.1,JSON.stringify(usage));
});
