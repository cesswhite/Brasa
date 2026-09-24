import catalog from '../data/game-catalog.json' with {type:'json'};
import {clamp,clone,deepFreeze} from './util.js';
export const gameCatalog=deepFreeze(catalog);
export const CATALOG_VERSION=gameCatalog.catalog_version;
export const B=gameCatalog.balance;
export const M=gameCatalog.move_config;
export const intervalFor=speed=>B.combat.interval_base/(1+clamp(speed,...B.stat_bounds.speed)*B.combat.interval_speed_scale);
export const xpForLevel=level=>B.xp.first_level+(clamp(Math.trunc(level),1,B.max_level)-1)*B.xp.per_level;
export const pointsForLevel=level=>level<=1||level>50?0:level<=20?3:2;
export const getStatOptions=()=>clone(gameCatalog.campaign.allocations);
export const getUnlockedMoves=(id,level)=>clone((gameCatalog.moves[id]??[]).filter(move=>move.unlock_level<=level));
export const getPerks=id=>clone(gameCatalog.perks[id]??[]);
export const getStoryStage=level=>clone(gameCatalog.campaign.stages.find(stage=>stage.global_level===level)??null);
export const getStoryOpponent=level=>getStoryStage(level)?.opponent??null;
export function baseStats(profile) {
  const entry=gameCatalog.characters[profile.character_id]??gameCatalog.characters.nima;
  const level=clamp(Math.trunc(profile.level??1),1,B.max_level);
  const steps=Math.min(level,B.soft_level)-1+Math.max(0,level-B.soft_level)*B.growth_after_soft;
  const training=profile.stats??entry.training_base; const result={};
  for(const stat of ['max_hp','attack','defense','speed','accuracy','evasion','crit_chance','crit_damage','resistance']) {
    let value=entry.base_stats[stat]+entry.growth[stat]*steps;
    for(const key of ['life','strength','agility','speed']) if(B.training[key]?.[stat]!==undefined) value+=(clamp(Math.trunc(training[key]??entry.training_base[key]),1,B.training_cap)-entry.training_base[key])*B.training[key][stat];
    result[stat]=clamp(value,...B.stat_bounds[stat]);
  }
  result.interval=intervalFor(result.speed); return result;
}
export function statsForProfile(profile) {
  const entry=gameCatalog.characters[profile.character_id]; if(!entry)throw new RangeError('Unknown character');
  const result=baseStats({character_id:profile.character_id,level:profile.level??1,stats:entry.training_base});
  for(const option of gameCatalog.campaign.allocations) result[option.key]=clamp(result[option.key]+clamp(Math.trunc(profile.allocations?.[option.key]??0),0,gameCatalog.campaign.config.allocation_cap)*option.increment,...B.stat_bounds[option.key]);
  result.interval=intervalFor(result.speed);return result;
}
export function boundMove(raw) {
  const result=clone(raw);
  for(const key of ['damage_multiplier','base_damage','accuracy_modifier','priority','critical_chance_modifier','critical_damage_modifier','armor_ignore','guard_bonus','airborne_evasion','heal_fraction','status_chance','windup','travel','recovery','weight']) result[key]=Number.isFinite(result[key])?result[key]:0;
  const bounds={damage_multiplier:[0,M.max_damage_multiplier],base_damage:[0,8],accuracy_modifier:[-.15,M.max_accuracy_modifier],priority:[-M.max_priority,M.max_priority],critical_chance_modifier:[-.10,.12],critical_damage_modifier:[-.10,.20],armor_ignore:[0,M.max_armor_ignore],guard_bonus:[0,.20],airborne_evasion:[0,.07],heal_fraction:[0,M.max_heal_fraction],status_chance:[0,1],windup:[.035,.65],travel:[0,.40],recovery:[.06,.45],weight:[.01,8]};
  for(const [key,limits] of Object.entries(bounds)) result[key]=clamp(result[key],...limits);
  result.cooldown=clamp(Math.trunc(result.cooldown??0),0,6);
  result.impact_delay=result.windup+result.travel;result.duration=result.impact_delay+result.recovery;
  for(const key of ['stance','status','self_status']) if(!result[key]||typeof result[key]!=='object'||Array.isArray(result[key]))result[key]={};
  result.movement=result.movement??clone(gameCatalog.movement.quick);
  result.status_duration=Math.trunc(result.status.duration??0);
  if(Object.keys(result.stance).length) {
    result.stance.reduction=clamp(result.stance.reduction??0,0,M.max_guard_reduction);
    result.stance.chance=clamp(result.stance.chance??0,0,M.max_counter_chance);
    result.stance.multiplier=clamp(result.stance.multiplier??0,0,.80);
    result.stance.duration=clamp(Math.trunc(result.stance.duration??1),1,2);
  }
  return result;
}
export function improveMove(id,definition,tier=0,perks=[]) {
  const result=clone(definition);tier=clamp(Math.trunc(tier),0,gameCatalog.max_move_tier);result.tier=tier;
  if((result.damage_multiplier??0)>0)result.damage_multiplier+=M.damage_per_tier*tier;
  if(Object.keys(result.stance??{}).length) { result.stance.reduction=(result.stance.reduction??0)+.01*tier;if((result.stance.multiplier??0)>0)result.stance.multiplier+=.02*tier; }
  result.accuracy_modifier=(result.accuracy_modifier??0)+M.accuracy_per_tier*tier;
  result.recovery=(result.recovery??.2)-M.recovery_per_tier*tier;
  let count=0;
  for(const perk of gameCatalog.perks[id]??[]) {
    if(!perks.includes(perk.id))continue;if(++count>3)continue;
    if(perk.types.length&&!perk.types.includes(result.type))continue;
    for(const [key,amount] of Object.entries(perk.modifiers)) {
      if(key==='status_duration') {for(const type of ['status','self_status'])if(Object.keys(result[type]??{}).length)result[type].duration=(result[type].duration??1)+Math.trunc(amount);}
      else if(key==='counter_chance') {if(Object.keys(result.stance??{}).length)result.stance.chance=(result.stance.chance??0)+amount;}
      else if(key==='damage_multiplier'&&result.type==='counter')result.stance.multiplier=(result.stance.multiplier??0)+amount;
      else if(key!=='damage_multiplier'||(result.damage_multiplier??0)>0)result[key]=(result[key]??0)+amount;
    }
  }
  return boundMove(result);
}
export function resolveMove(id,moveId,tier=0,perks=[]) { const move=gameCatalog.moves[id]?.find(m=>m.id===moveId);return move?improveMove(id,move,tier,perks):null; }
export const AI_STYLES=deepFreeze({
  balanced:{},aggressive:{quick:1.1,heavy:1.4,charge:1.5,guard:.55,counter:.75},
  defensive:{guard:1.8,counter:1.35,heavy:.75,charge:.7},fast:{quick:1.5,dash:1.6,jump:1.15,heavy:.7,charge:.6},
  counter:{counter:2,guard:1.4,quick:.85,charge:.7},risky:{heavy:1.8,charge:2,jump:1.2,guard:.35,counter:.5},
  unpredictable:{quick:.55,dash:1.05,heavy:1.05,charge:1.25,jump:1.25,technique:1.45,guard:1.5,counter:1.5}
});
export function validateAiConfig(raw={}) {
  if(!raw||typeof raw!=='object'||Array.isArray(raw)||Object.keys(raw).some(k=>!['style','weights'].includes(k)))throw new TypeError('Invalid AI config');
  const style=raw.style??'balanced';if(!Object.hasOwn(AI_STYLES,style))throw new RangeError('Unknown AI style');
  const weights=raw.weights??{};if(!weights||typeof weights!=='object'||Array.isArray(weights))throw new TypeError('Invalid AI weights');
  for(const [key,value] of Object.entries(weights))if(!Object.hasOwn(gameCatalog.move_types,key)||typeof value!=='number'||!Number.isFinite(value)||value<.25||value>4)throw new RangeError('AI weights must be known move types in [0.25,4]');
  return {style,weights:clone(weights)};
}
export function buildCombatant(dto) {
  if(!dto||typeof dto!=='object'||Array.isArray(dto))throw new TypeError('Invalid fighter');
  const entry=gameCatalog.characters[dto.character_id];if(!entry)throw new RangeError('Unknown character');
  const level=dto.level??1;if(!Number.isInteger(level)||level<1||level>B.max_level)throw new RangeError('Invalid level');
  const allocations=dto.allocations??{};if(!allocations||typeof allocations!=='object'||Array.isArray(allocations))throw new TypeError('Invalid allocations');
  const keys=gameCatalog.campaign.allocations.map(x=>x.key);
  for(const [key,value]of Object.entries(allocations))if(!keys.includes(key)||!Number.isInteger(value)||value<0||value>30)throw new RangeError('Invalid allocation');
  const available=getUnlockedMoves(entry.id,level),ids=available.map(x=>x.id),tiers=dto.move_upgrades??{},perks=dto.perks??[];
  if(!tiers||typeof tiers!=='object'||Array.isArray(tiers))throw new TypeError('Invalid move upgrades');
  for(const [id,value]of Object.entries(tiers))if(!ids.includes(id)||!Number.isInteger(value)||value<0||value>2)throw new RangeError('Invalid move upgrade');
  if(!Array.isArray(perks)||perks.length>3||new Set(perks).size!==perks.length||perks.some(p=>!gameCatalog.perks[entry.id].some(x=>x.id===p)))throw new RangeError('Invalid perks');
  const result={character_id:entry.id,name:dto.identity?.display_name??dto.name??entry.name,archetype:entry.archetype,level,stats:clone(entry.training_base),allocations:clone(allocations),combat_stats:statsForProfile(dto),ability:clone(entry.ability),signature:clone(entry.signature),visual:clone(entry.visual),unlocked_moves:ids,move_upgrades:clone(tiers),perks:clone(perks),ai_config:validateAiConfig(dto.ai_config)};
  for(const key of ['fighter_id','owner_id','identity','appearance'])if(dto[key]!==undefined)result[key]=clone(dto[key]);
  result.moves=available.map(move=>improveMove(entry.id,move,tiers[move.id]??0,perks));return result;
}
