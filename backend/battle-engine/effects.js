import {B,gameCatalog,intervalFor} from './catalog.js';
import {clone,clamp,round} from './util.js';
export const NAMES=gameCatalog.effects.names;
export const DOT_TYPES=gameCatalog.effects.dot_types;
export const POSITIVE_TYPES=gameCatalog.effects.positive_types;
export const isNegative=type=>!POSITIVE_TYPES.includes(type);
export function description(effect) {
  const type=effect.type??effect.effect??'',m=effect.magnitude??0;let amount;
  if(DOT_TYPES.includes(type))amount=`−${round(m)} PV por acción`;
  else if(type==='shield')amount=`${round(m)} PV de protección`;
  else if(type==='stun')amount='no puede atacar';
  else amount=`${POSITIVE_TYPES.includes(type)?'+':'−'}${round(m*100)}${['accuracy_down','accuracy_up'].includes(type)?' puntos de precisión':'%'}`;
  return `${NAMES[type]??type} (${amount})`;
}
export function apply(effects,spec,source,action,maxHp) {
  const type=spec.type??spec.effect??'';if(!Object.hasOwn(NAMES,type))return {};
  let limit=B.status.max_magnitude;
  if(DOT_TYPES.includes(type))limit=maxHp*B.status.max_dot_fraction;else if(type==='shield')limit=maxHp*B.status.max_shield_fraction;else if(type==='stun')limit=1;
  const magnitude=clamp(spec.magnitude??0,0,limit),duration=clamp(Math.trunc(spec.duration??1),1,B.status.max_duration);
  let stacking=spec.stacking??'refresh';if(!['refresh','intensity','replace','ignore'].includes(stacking))stacking='refresh';
  const maximum=clamp(Math.trunc(spec.max_stacks??B.status.max_stacks),1,B.status.max_stacks);
  for(const effect of effects)if(effect.type===type) {
    if(stacking==='ignore')return {effect:clone(effect),change:'ignored'};
    if(stacking==='intensity'){effect.stacks=Math.min(maximum,(effect.stacks??1)+1);effect.magnitude=Math.min(limit,magnitude*effect.stacks);}
    else if(stacking==='replace'){effect.magnitude=magnitude;effect.stacks=1;}
    else {effect.magnitude=Math.max(effect.magnitude,magnitude);effect.stacks=1;}
    Object.assign(effect,{duration,remaining_turns:duration,source,stacking,applied_at_action:action});return {effect:clone(effect),change:'refreshed'};
  }
  const added={id:type,type,name:NAMES[type],magnitude,duration,remaining_turns:duration,source,stacking,stacks:1,applied_at_action:action};effects.push(added);return {effect:clone(added),change:'applied'};
}
export function runtimeStats(base,effects) {
  const stats=clone(base);
  for(const effect of effects) {
    const m=effect.magnitude;
    switch(effect.type) {
      case 'attack_down':stats.attack*=1-m;break;case 'attack_up':stats.attack*=1+m;break;
      case 'defense_down':stats.defense*=1-m;break;case 'defense_up':stats.defense*=1+m;break;
      case 'slow':stats.speed*=1-m;break;case 'accuracy_down':stats.accuracy-=m;break;case 'accuracy_up':stats.accuracy+=m;break;
    }
  }
  for(const [key,limits]of Object.entries(B.stat_bounds))if(Object.hasOwn(stats,key))stats[key]=clamp(stats[key],...limits);
  stats.interval=intervalFor(Math.max(0,stats.speed));return stats;
}
export const dots=(effects,action)=>effects.filter(e=>DOT_TYPES.includes(e.type)&&e.applied_at_action<action).map(effect=>({effect:clone(effect),damage:Math.max(0,round(effect.magnitude))}));
export function expireAfterAction(effects,action) {
  const expired=[];for(let i=effects.length-1;i>=0;i--){const e=effects[i];if(e.applied_at_action>=action)continue;if(--e.remaining_turns<=0){expired.push(clone(e));effects.splice(i,1);}}return expired;
}
export const shieldTotal=effects=>effects.reduce((sum,e)=>sum+(e.type==='shield'?e.magnitude:0),0);
export function absorb(effects,damage) {
  let remaining=Math.max(0,damage),absorbed=0;
  for(let i=effects.length-1;i>=0;i--){const effect=effects[i];if(effect.type!=='shield')continue;const amount=Math.min(remaining,effect.magnitude);effect.magnitude-=amount;remaining-=amount;absorbed+=amount;if(effect.magnitude<=0)effects.splice(i,1);}
  return {remaining,absorbed};
}
export const hasType=(effects,type)=>effects.some(e=>e.type===type);
export const healingMultiplier=effects=>Math.max(0,effects.reduce((result,e)=>result*(e.type==='healing_down'?1-e.magnitude:1),1));
