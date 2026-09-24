import {B,M} from './catalog.js';
import {clamp,clone,round} from './util.js';
export const hitChance=(a,d)=>clamp((a.accuracy??.96)-(d.evasion??.10),B.combat.hit_min,B.combat.hit_max);
export const criticalChance=a=>clamp(a.crit_chance??.12,B.combat.crit_min,B.combat.crit_max);
export function damagePreview(a,d,aLevel=1,dLevel=1,modifier=1,armorIgnore=0) {
  const attack=Math.max(0,a.attack??0),defense=Math.max(0,d.defense??0)*(1-clamp(armorIgnore,0,1)),scale=Math.max(1,B.combat.defense_scale);
  const level=clamp(1+(aLevel-dLevel)*B.combat.level_damage_per_level,B.combat.level_damage_min,B.combat.level_damage_max);
  return Math.max(B.combat.min_damage,attack*scale/(scale+defense)*Math.max(0,modifier)*level);
}
export function moveStats(base,move) {
  const result=clone(base);
  for(const [key,field]of [['attack','base_damage'],['accuracy','accuracy_modifier'],['crit_chance','critical_chance_modifier'],['crit_damage','critical_damage_modifier']])result[key]=clamp((result[key]??B.stat_bounds[key][0])+(move[field]??0),...B.stat_bounds[key]);
  return result;
}
export function rollAttack(attacker,defender,rng,options={}) {
  attacker=moveStats(attacker,options.move??{});
  const signature=!!options.signature,hit=hitChance(attacker,defender);
  if(!signature&&!options.guaranteed_hit&&rng.randf()>=hit) {
    const miss=Math.max(.01,1-(attacker.accuracy??.96)),evasion=Math.max(0,defender.evasion??.1);
    return {result:rng.randf()<evasion/(evasion+miss)?'dodge':'miss',damage:0,hit_chance:hit,critical:false,signature:false};
  }
  const critical=!signature&&(options.allow_critical??true)&&rng.randf()<criticalChance(attacker);
  let ignore=options.move?.armor_ignore??0;if(critical)ignore+=options.critical_armor_ignore??0;ignore=clamp(ignore,0,.65);
  let damage=damagePreview(attacker,defender,options.attacker_level??1,options.defender_level??1,Math.max(0,options.modifier??1),ignore);
  if(critical)damage*=1+(Math.max(1,attacker.crit_damage??1.55)-1)*(1-clamp(options.critical_reduction??0,0,1));
  const variance=clamp(B.combat.variance,0,.10);damage*=rng.randf_range(1-variance,1+variance);
  return {result:signature?'signature':critical?'critical':'hit',damage:Math.max(B.combat.min_damage,round(damage)),hit_chance:hit,critical,signature};
}
export const counterChance=(base,defender,attacker)=>base<=0?0:clamp(base*hitChance(defender,attacker)+(defender.speed-attacker.speed)*M.counter_speed_factor,.03,M.max_counter_chance);
export const statusChance=(chance,resistance)=>clamp(chance*(1-clamp(resistance,0,1)*B.status.resistance_chance_factor),0,1);
export function statusDuration(turns,resistance,negative=true) {const duration=clamp(Math.trunc(turns),1,B.status.max_duration);return negative?Math.max(1,Math.ceil(duration*(1-clamp(resistance,0,1)*B.status.resistance_duration_factor))):duration;}
