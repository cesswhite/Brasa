import {B,M,gameCatalog,baseStats,intervalFor,boundMove,improveMove,getUnlockedMoves,AI_STYLES,validateAiConfig,CATALOG_VERSION} from './catalog.js';
import {GodotRng,normalizeSeed,RNG_VERSION} from './rng.js';
import * as Rules from './rules.js';
import * as Effects from './effects.js';
import {clone,clamp,round,empty,approximatelyEqual} from './util.js';
export const ENGINE_VERSION='brasa-authoritative-v1';
const SIDES=['player','rival'];
const other=side=>side==='player'?'rival':'player';
/** Pure trusted-domain engine. HTTP callers must use buildCombatant, not raw overrides. */
export class BattleEngine {
  constructor(){this.running=false;this.elapsed=0;this.fighters={};this.metrics={};this.event_log=[];this.terminal_summary={};}
  start(player,rival,seed,options={}) {
    this.seed=normalizeSeed(seed);this.rng=new GodotRng(this.seed);this.options=options;
    this.running=true;this.elapsed=0;this.winner='';this.turn=0;this.active_side='';this.event_log=[];this.initial_events=[];this.terminal_summary={};this.fighters={};this.metrics={};this.pending_counters=[];
    for(const side of SIDES) {
      const descriptor=this.normalizeCombatant(side==='player'?player:rival,side),stats=clone(descriptor.combat_stats);
      let armed=this.rng.randf()<B.signature.chance;if(options.disable_signatures)armed=false;
      const forced=options.force_signature??[];if(forced===true||forced===side||forced==='both'||(Array.isArray(forced)&&forced.includes(side)))armed=true;
      let signatureTurn=this.rng.randi_range(B.signature.min_turn,B.signature.max_turn);if(Object.hasOwn(options,'signature_turn'))signatureTurn=Math.max(1,Math.trunc(options.signature_turn));
      let opening=this.rng.randf_range(B.combat.opening_min,B.combat.opening_max);opening*=stats.interval/intervalFor(6);
      if(Object.hasOwn(options,'opening_time'))opening=Math.max(.01,options.opening_time);
      this.fighters[side]={descriptor,base_stats:stats,hp:stats.max_hp,max_hp:stats.max_hp,statuses:[],turns_taken:0,next_action:opening,defeated:false,surrendered:false,signature_armed:armed,signature_used:false,signature_turn:signatureTurn,comeback_used:false,announced_phase:-1,move_phase:'idle',pending_move:{},pending_signature:false,impact_at:Infinity,recovery_at:Infinity,move_started_at:0,cooldowns:{},last_move:'',stance:{},counter_pending:false};
      this.metrics[side]={attacks:0,hits:0,criticals:0,misses:0,dodges:0,damage_dealt:0,damage_taken:0,absorbed:0,healing:0,abilities:0,signatures:0,statuses_applied:0,counters:0,turns_survived:0,statuses_prevented:0,status_turns_resisted:0,move_uses:{},critical_damage_taken:0};
      if(Object.hasOwn(options.initial_hp??{},side))this.fighters[side].hp=clamp(options.initial_hp[side],0,stats.max_hp);
      for(const spec of options.initial_statuses?.[side]??[])Effects.apply(this.fighters[side].statuses,spec,spec.source??other(side),0,stats.max_hp);
    }
    this.battle_id=String(options.battle_id??`brasa_${this.seed}`);this.syncHp();
    for(const side of SIDES){const ability=this.fighters[side].descriptor.ability;if(ability.id==='shield')this.grantShield(side,ability,this.initial_events);this.announcePhase(side,this.initial_events);}
  }
  advance(delta) {
    const events=[];if(!this.running||!Number.isFinite(delta)||delta<=0)return events;
    events.push(...this.initial_events);this.initial_events=[];
    if(this.checkTerminal('normal',events))return events;
    const target=Math.min(B.combat.max_duration,this.elapsed+delta);let iterations=0;
    while(this.running) {
      if(++iterations>20000)throw new Error('Battle scheduler exceeded its bounded action budget');
      const next=this.nextEventTime();if(next>target)break;this.elapsed=next;
      for(const side of SIDES){const f=this.fighters[side];if(this.due(f.recovery_at)){this.emit({type:'move_recovered',side,move_id:f.pending_move.id??'',message:''},events);f.recovery_at=Infinity;f.move_phase='idle';f.pending_move={};}}
      const starters=[];
      for(const side of SIDES)if(this.due(this.fighters[side].next_action)) {
        const f=this.fighters[side];starters.push(side);f.turns_taken++;this.metrics[side].turns_survived=f.turns_taken;this.turn++;this.active_side=side;
        if(!empty(f.stance)&&f.turns_taken>=f.stance.until_action){f.stance={};this.emit({type:'stance_expired',side,message:`${this.name(side)} abandona la postura.`},events);}
        this.tickDots(side,events);
      }
      if(this.checkTerminal('dot',events))break;
      if(starters.length===2&&this.rng.randf()<.5)starters.reverse();
      for(const side of starters){this.active_side=side;this.takeAction(side,events);}
      const impacts=SIDES.filter(side=>this.due(this.fighters[side].impact_at));if(impacts.length===2&&this.rng.randf()<.5)impacts.reverse();
      for(const side of impacts){if(!this.running)break;this.resolveMove(side,events);}
      for(let i=this.pending_counters.length-1;i>=0;i--){if(!this.running)break;if(this.due(this.pending_counters[i].at)){const reaction=this.pending_counters.splice(i,1)[0];this.fighters[reaction.side].counter_pending=false;this.resolveCounter(reaction,events);}}
    }
    if(this.running){this.elapsed=target;if(this.elapsed>=B.combat.max_duration)this.finish(this.ratioWinner(),'timeout',events);}
    return events;
  }
  due(time){return Math.abs(time-this.elapsed)<.0000001;}
  nextEventTime(){let result=Infinity;for(const f of Object.values(this.fighters))result=Math.min(result,f.next_action,f.impact_at,f.recovery_at);for(const r of this.pending_counters)result=Math.min(result,r.at);return result;}
  surrender(side='player') {
    const events=[];if(!this.running||!SIDES.includes(side))return events;this.initial_events=[];this.fighters[side].surrendered=true;
    this.emit({type:'surrender',side,message:`${this.name(side)} se rinde. ${this.name(other(side))} gana la ronda.`},events);this.finish(other(side),'surrender',events);return events;
  }
  snapshot() {
    const fighters={};for(const side of SIDES){const f=this.fighters[side];if(!f)continue;fighters[side]={hp:f.hp,max_hp:f.max_hp,shield:Effects.shieldTotal(f.statuses),level:f.descriptor.level,statuses:clone(f.statuses),turns_taken:f.turns_taken,defeated:f.defeated,surrendered:f.surrendered,signature_used:f.signature_used,runtime_stats:this.runtime(side),stance:clone(f.stance),move_phase:f.move_phase,pending_move:clone(f.pending_move),cooldowns:clone(f.cooldowns)};}
    return {turn:this.turn,active_side:this.active_side,fighters,running:this.running,elapsed:this.elapsed,winner:this.winner,battle_id:this.battle_id};
  }
  summary(){return clone(this.terminal_summary);}
  normalizeCombatant(raw,side) {
    const d=clone(raw);if(!d.character_id)d.character_id=gameCatalog.character_ids[clamp(Math.trunc(raw.archetype??1),0,2)];
    let entry=gameCatalog.characters[d.character_id];if(!entry){entry=gameCatalog.characters.nima;d.character_id='nima';}
    d.name=String(raw.name??entry.name??side);d.archetype=Math.trunc(raw.archetype??entry.archetype??1);d.level=clamp(Math.trunc(raw.level??1),1,B.max_level);
    if(!Object.hasOwn(d,'stats'))d.stats=raw.life!==undefined?clone(raw):clone(entry.training_base);
    if(!Object.hasOwn(d,'combat_stats'))d.combat_stats=baseStats(d);
    else {const bounded=baseStats(d);for(const key of Object.keys(bounded)){const v=d.combat_stats[key]??bounded[key];if(Number.isFinite(v)){bounded[key]=Math.max(0,v);if(B.stat_bounds[key])bounded[key]=clamp(bounded[key],...B.stat_bounds[key]);}}bounded.max_hp=Math.max(1,bounded.max_hp);bounded.interval=intervalFor(bounded.speed);d.combat_stats=bounded;}
    d.ability=clone(raw.ability??entry.ability);d.signature=clone(raw.signature??entry.signature);
    let id=raw.story_boss_id??d.character_id;if(!gameCatalog.moves[id]?.length)id=d.character_id;d.move_character_id=id;d.perks=[];d.passive_perks=[];
    for(const perk of gameCatalog.perks[id]??[])if((raw.perks??[]).includes(perk.id)&&d.perks.length<3){d.perks.push(perk.id);if(perk.runtime)d.passive_perks.push(clone(perk));}
    let resolved=[];
    for(const move of Array.isArray(raw.moves)?raw.moves:[])if(move&&['id','name','type','animation_type','movement'].every(k=>Object.hasOwn(move,k))&&Object.hasOwn(gameCatalog.move_types,move.type))resolved.push(boundMove(move));
    if(!resolved.length)for(const move of getUnlockedMoves(id,d.level)){if(raw.unlocked_moves&&!raw.unlocked_moves.includes(move.id))continue;resolved.push(improveMove(id,move,raw.move_upgrades?.[move.id]??0,d.perks));}
    if(!resolved.length)resolved=getUnlockedMoves(id,1);d.moves=resolved;if(d.ai_config)d.ai_config=validateAiConfig(d.ai_config);return d;
  }
  takeAction(side,events) {
    const f=this.fighters[side],a=f.descriptor.ability;
    if(Effects.hasType(f.statuses,'stun')){this.emit({type:'ability',side,ability_id:'stun',message:`${this.name(side)} pierde una acción por aturdimiento.`},events);this.completeAction(side,events);f.next_action=this.elapsed+this.runtime(side).interval;return;}
    if(a.id==='comeback'&&!f.comeback_used&&f.hp/f.max_hp<=a.threshold){f.comeback_used=true;this.abilityEvent(side,a,events);this.heal(side,f.max_hp*a.heal_fraction,events);}
    if(a.id==='shield'&&f.turns_taken>1&&(f.turns_taken-1)%Math.max(1,a.every)===0)this.grantShield(side,a,events);
    const signature=f.signature_armed&&!f.signature_used&&f.turns_taken>=f.signature_turn;
    let move=this.selectMove(side);
    if(signature)move=boundMove({id:'signature',name:f.descriptor.signature.name,type:'signature',animation_type:'signature',damage_multiplier:1,windup:M.signature_windup,travel:M.signature_travel,recovery:M.signature_recovery,priority:0,weight:1,movement:{kind:'charge',retreat:20,distance:100,height:0},status:{},self_status:{},stance:{}});
    f.pending_move=move;f.pending_signature=signature;f.move_phase='windup';f.impact_at=this.elapsed+move.impact_delay;f.recovery_at=this.elapsed+move.duration;f.move_started_at=this.elapsed;f.last_move=move.id;
    if(!signature)f.cooldowns[move.id]=f.turns_taken+move.cooldown+1;
    const variance=B.combat.cadence_variance,cadence=this.runtime(side).interval*(1-move.priority)*this.rng.randf_range(1-variance,1+variance);
    f.next_action=this.elapsed+Math.max(move.duration,Math.max(M.min_cadence,cadence));this.metrics[side].move_uses[move.id]=(this.metrics[side].move_uses[move.id]??0)+1;
    this.emit({type:'move_started',side,target:other(side),move:clone(move),impact_delay:move.impact_delay,duration:move.duration,signature,action:f.turns_taken,message:`${this.name(side)} prepara ${move.name}.`},events);
    if(!empty(move.self_status)&&Effects.isNegative(move.self_status.type))this.applyStatus(side,side,move.self_status,1,true,events);
  }
  selectMove(side) {
    const f=this.fighters[side],target=this.fighters[other(side)],choices=[],weights=[];let total=0;
    const slower=this.runtime(side).speed<this.runtime(other(side)).speed,ai=f.descriptor.ai_config??{style:'balanced',weights:{}};
    for(const move of f.descriptor.moves){if((f.cooldowns[move.id]??0)>f.turns_taken)continue;let weight=move.weight;
      if(f.last_move===move.id)weight*=M.repeat_weight;
      if(target.hp/target.max_hp<M.finisher_ratio)weight*=['quick','dash'].includes(move.type)?M.finisher_weight:M.finisher_other_weight;
      if(['guard','counter'].includes(move.type)){weight*=f.hp/f.max_hp<M.low_hp_ratio?M.defense_weight:M.guard_healthy_weight;if(!empty(f.stance))weight*=M.existing_guard_weight;}
      if(!empty(target.stance)&&move.guard_bonus>0)weight*=M.guard_pressure_weight;
      if(!empty(move.status)&&Effects.hasType(target.statuses,move.status.type))weight*=M.status_refresh_weight;
      if(!empty(move.self_status)&&!Effects.isNegative(move.self_status.type)&&Effects.hasType(f.statuses,move.self_status.type))weight*=M.existing_buff_weight;
      if(slower&&['quick','dash'].includes(move.type))weight*=M.slower_fast_weight;
      weight*=AI_STYLES[ai.style]?.[move.type]??1;weight*=ai.weights?.[move.type]??1;
      choices.push(move);weights.push(Math.max(.001,weight));total+=weights.at(-1);
    }
    if(!choices.length)return clone(gameCatalog.moves[f.descriptor.move_character_id][0]);
    let roll=this.rng.randf()*total;for(let i=0;i<choices.length;i++){roll-=weights[i];if(roll<=0)return clone(choices[i]);}return clone(choices.at(-1));
  }
  resolveMove(side,events) {
    const f=this.fighters[side],move=f.pending_move;f.impact_at=Infinity;f.move_phase='recovery';if(f.hp<=0)return;this.active_side=side;
    if(!empty(move.self_status)&&!Effects.isNegative(move.self_status.type))this.applyStatus(side,side,move.self_status,1,true,events);
    if(['guard','counter'].includes(move.type)){
      const stance=clone(move.stance);Object.assign(stance,{until_action:f.turns_taken+(stance.duration??1),move_id:move.id,name:move.name});f.stance=stance;
      this.emit({type:'defensive_stance',side,target:side,move:clone(move),name:move.name,duration:stance.duration??1,until_action:stance.until_action,reduction:stance.reduction??0,counter_chance:stance.chance??0,message:`${this.name(side)} adopta ${move.name}.`},events);
      if(move.heal_fraction>0)this.heal(side,f.max_hp*move.heal_fraction,events);
    }else this.attack(side,events,move,f.pending_signature);
    if(this.running)this.completeAction(side,events);
  }
  completeAction(side,events) {
    const before=this.runtime(side).interval;for(const expired of Effects.expireAfterAction(this.fighters[side].statuses,this.fighters[side].turns_taken))this.emit({type:'status_expired',side,status:expired,message:`${this.name(side)}: termina ${expired.name}`},events);this.adjustInitiative(side,before,this.runtime(side).interval);
  }
  adjustInitiative(side,before,after) {
    const f=this.fighters[side];if(!approximatelyEqual(before,after)&&f.next_action>this.elapsed)f.next_action=Math.max(this.elapsed+(f.next_action-this.elapsed)*after/before,Number.isFinite(f.recovery_at)?f.recovery_at:0);
  }
  attack(side,events,move,signature=false) {
    if(!this.running)return;
    const target=other(side),f=this.fighters[side],d=this.fighters[target],a=f.descriptor.ability,da=d.descriptor.ability,s=f.descriptor.signature;
    let modifier=signature?1:move.damage_multiplier;if(!signature&&!empty(d.stance))modifier*=1+move.guard_bonus;
    if(a.id==='berserk')modifier*=1+(1-f.hp/f.max_hp)*a.missing_hp_bonus;
    else if(a.id==='combo'&&!signature&&(this.metrics[side].attacks+1)%Math.max(1,a.every)===0){modifier*=a.multiplier;this.abilityEvent(side,a,events);}
    if(signature){f.signature_used=true;this.metrics[side].signatures++;modifier*=clamp(s.modifier??s.damage_multiplier??B.signature.damage_multiplier,B.signature.min_multiplier,B.signature.max_multiplier);
      this.emit({type:'signature',side,name:s.name,effect:s.effect,duration:s.duration,message:`★ ${this.name(side)} desata ${s.name}: impacto certero y ${Effects.NAMES[s.effect]??s.effect}.`},events);}
    const options={signature,modifier,attacker_level:f.descriptor.level,defender_level:d.descriptor.level,move:signature?{}:move};
    if(a.id==='precision')options.critical_armor_ignore=a.armor_ignore;if(da.id==='fortify')options.critical_reduction=da.critical_reduction;
    options.critical_reduction=Math.min(.65,(options.critical_reduction??0)+this.perkBonuses(target).critical_reduction);
    const roll=Rules.rollAttack(this.runtime(side),this.runtime(target),this.rng,options);this.metrics[side].attacks++;
    const result=roll.result,damage=this.damage(target,roll.damage,side);if(roll.critical)this.metrics[target].critical_damage_taken+=Math.ceil(damage.damage);
    let message=`${this.name(side)} golpea: −${Math.ceil(damage.damage)} PV.`;
    if(result==='dodge'){this.metrics[target].dodges++;message=`${this.name(target)} esquiva a ${this.name(side)}.`;}
    else if(result==='miss')message=`${this.name(side)} falla el ataque.`;
    else if(result==='critical'){this.metrics[side].criticals++;message=`¡Crítico de ${this.name(side)}! −${Math.ceil(damage.damage)} PV.`;}
    else if(signature)message=`★ ${this.name(side)}: −${Math.ceil(damage.damage)} PV con ${s.name}.`;
    if(result==='critical'&&a.id==='precision'){this.abilityEvent(side,a,events);message+=` Ignora ${round(a.armor_ignore*100)}% de defensa.`;}
    if(result==='critical'&&da.id==='fortify'){this.abilityEvent(target,da,events);message+=` ${this.name(target)} reduce el extra crítico ${round(da.critical_reduction*100)}%.`;}
    const missed=['miss','dodge'].includes(result);
    if(!missed&&a.id==='berserk')message+=` Furia +${round((1-f.hp/f.max_hp)*a.missing_hp_bonus*100)}%.`;
    if(missed)this.metrics[side].misses++;else this.metrics[side].hits++;
    if(damage.absorbed>0)message+=` Escudo absorbe ${Math.trunc(damage.absorbed)}.`;
    this.emit({type:'attack',side,target,result,damage:Math.ceil(damage.damage),raw_damage:roll.damage,absorbed:damage.absorbed,target_hp:d.hp,signature,hit_chance:roll.hit_chance,move_id:move.id,move_name:move.name,animation_type:move.animation_type,movement:move.movement,message},events);
    this.announcePhase(target,events);
    if(!signature&&!missed&&!empty(move.status)&&d.hp>0)this.applyStatus(target,side,move.status,move.status_chance,false,events);
    if(signature){const spec=clone(s);spec.type=s.effect;this.applyStatus(target,side,spec,1,true,events);}
    else if(missed&&a.id==='adapt'){this.abilityEvent(side,a,events);this.applyStatus(side,side,{type:'accuracy_up',magnitude:a.accuracy_bonus,duration:a.duration},1,true,events);}
    else if(!missed&&a.id==='poison'&&d.hp>0){const spec=clone(a);spec.type='poison';if(this.applyStatus(target,side,spec,a.chance,false,events))this.abilityEvent(side,a,events);}
    if(this.checkTerminal('normal',events))return;
    if(!missed&&!empty(d.stance)&&this.rng.randf()<Rules.counterChance(d.stance.chance??0,this.runtime(target),this.runtime(side)))this.counter(target,side,{id:'stance',name:d.stance.name,multiplier:d.stance.multiplier??0},events);
    else if(!missed&&da.id==='counter'&&this.rng.randf()<da.chance)this.counter(target,side,da,events);
  }
  counter(side,target,ability,events) {
    if(!this.running||this.fighters[side].counter_pending)return;this.abilityEvent(side,ability,events);
    const move=boundMove({id:`reaction_${ability.id}`,name:ability.name??'Réplica',type:'counter',animation_type:'counter',damage_multiplier:ability.multiplier,windup:M.counter_windup,travel:M.counter_travel,recovery:M.counter_recovery,weight:1,movement:{kind:'dash',retreat:6,distance:54,height:0},status:{},self_status:{},stance:{}});
    this.fighters[side].counter_pending=true;this.pending_counters.push({side,target,move,at:this.elapsed+move.impact_delay});
    this.emit({type:'move_started',side,target,move:clone(move),counter:true,impact_delay:move.impact_delay,duration:move.duration,message:`${this.name(side)} prepara una réplica.`},events);
  }
  resolveCounter(reaction,events) {
    const {side,target,move}=reaction;if(!this.running||this.fighters[side].hp<=0)return;this.metrics[side].counters++;
    const roll=Rules.rollAttack(this.runtime(side),this.runtime(target),this.rng,{guaranteed_hit:true,allow_critical:false,modifier:move.damage_multiplier,attacker_level:this.fighters[side].descriptor.level,defender_level:this.fighters[target].descriptor.level});
    const damage=this.damage(target,roll.damage,side);
    this.emit({type:'attack',side,target,result:'hit',counter:true,move_id:move.id,move_name:move.name,animation_type:move.animation_type,movement:move.movement,damage:Math.ceil(damage.damage),raw_damage:roll.damage,absorbed:damage.absorbed,target_hp:this.fighters[target].hp,message:`${this.name(side)} contraataca: −${Math.ceil(damage.damage)} PV.`},events);
    this.announcePhase(target,events);this.checkTerminal('normal',events);
  }
  applyStatus(target,source,spec,chance,guaranteed,events) {
    const negative=Effects.isNegative(spec.type??spec.effect??''),resistance=negative?this.runtime(target).resistance:0;
    if(!guaranteed){const roll=this.rng.randf();if(roll>=Rules.statusChance(chance,resistance)){
      if(negative&&roll<clamp(chance,0,1)){this.metrics[target].statuses_prevented++;this.emit({type:'status_resisted',side:target,source,effect:spec.type??'',message:`${this.name(target)} resiste ${Effects.NAMES[spec.type]??'el efecto'}.`},events);}return false;}}
    const adjusted=clone(spec);if(spec.scaling_stat&&(spec.scaling_base??0)>0)adjusted.magnitude=spec.magnitude*(this.runtime(source)[spec.scaling_stat]??spec.scaling_base)/spec.scaling_base;
    adjusted.duration=Rules.statusDuration(spec.duration,resistance,negative);
    const before=this.runtime(target).interval,application=Effects.apply(this.fighters[target].statuses,adjusted,source,this.fighters[target].turns_taken,this.fighters[target].max_hp);
    if(empty(application)||application.change==='ignored')return false;
    this.adjustInitiative(target,before,this.runtime(target).interval);
    const effect=application.effect,turnsResisted=negative?Math.max(0,clamp(spec.duration,1,B.status.max_duration)-adjusted.duration):0;
    this.metrics[target].status_turns_resisted+=turnsResisted;this.metrics[source].statuses_applied++;
    this.emit({type:'status_applied',side:target,source,status:effect,effect:effect.type,duration:effect.remaining_turns,turns_resisted:turnsResisted,message:`${this.name(target)}: ${Effects.description(effect)} durante ${effect.remaining_turns} acciones propias.${turnsResisted>0?` Resistencia acorta ${turnsResisted}.`:''}`},events);return true;
  }
  grantShield(side,ability,events) {
    this.abilityEvent(side,ability,events);this.applyStatus(side,side,{type:'shield',magnitude:ability.magnitude,duration:ability.duration,stacking:'refresh'},1,true,events);
    const amount=Effects.shieldTotal(this.fighters[side].statuses);this.emit({type:'shield',side,amount,message:`${this.name(side)} levanta un escudo de ${Math.trunc(amount)}.`},events);
  }
  abilityEvent(side,ability,events){this.metrics[side].abilities++;this.emit({type:'ability',side,ability_id:ability.id,name:ability.name??ability.id,message:`${this.name(side)} activa ${ability.name??ability.id}.`},events);}
  heal(side,amount,events) {
    const f=this.fighters[side];let healing=Math.min(f.max_hp-f.hp,Math.max(0,amount)*Effects.healingMultiplier(f.statuses));healing=Math.max(0,round(healing));f.hp=Math.min(f.max_hp,f.hp+healing);this.metrics[side].healing+=healing;this.syncHp();
    this.emit({type:'heal',side,target:side,amount:healing,target_hp:f.hp,message:`${this.name(side)} recupera +${healing} PV.`},events);
  }
  tickDots(side,events) {
    const f=this.fighters[side];for(const tick of Effects.dots(f.statuses,f.turns_taken)) {
      const source=SIDES.includes(tick.effect.source)?tick.effect.source:other(side),damage=this.damage(side,tick.damage,source,true);
      this.emit({type:'status_tick',side,source,target:side,effect:tick.effect.type,damage:Math.ceil(damage.damage),target_hp:f.hp,remaining_turns:tick.effect.remaining_turns,message:`${this.name(side)} sufre ${tick.effect.name}: −${Math.ceil(damage.damage)} PV (${tick.effect.remaining_turns} acciones).`},events);this.announcePhase(side,events);
    }
  }
  damage(target,amount,source,bypassShield=false) {
    const f=this.fighters[target],phase=f.descriptor.ability.id==='phase_shift',before=phase?this.runtime(target).interval:1;
    let safe=Number.isFinite(amount)?Math.max(0,amount):0;if(!bypassShield&&!empty(f.stance))safe*=1-(f.stance.reduction??0);
    const absorption=bypassShield?{remaining:safe,absorbed:0}:Effects.absorb(f.statuses,safe),actual=Math.min(f.hp,Math.max(0,absorption.remaining));f.hp=Math.max(0,f.hp-actual);
    this.adjustInitiative(target,before,phase?this.runtime(target).interval:1);
    this.metrics[target].damage_taken+=round(actual);this.metrics[target].absorbed+=round(absorption.absorbed);this.metrics[source].damage_dealt+=round(actual);this.syncHp();return {damage:actual,absorbed:absorption.absorbed};
  }
  runtime(side) {
    const f=this.fighters[side];let base=f.base_stats;const phase=this.currentPhase(side);
    if(!empty(phase)){base=clone(base);for(const [key,value]of Object.entries(phase.modifiers??{})){if(!B.stat_bounds[key]||key==='max_hp')continue;base[key]=clamp(base[key]*clamp(value,.75,1.25),...B.stat_bounds[key]);}base.interval=intervalFor(base.speed);}
    const runtime=Effects.runtimeStats(base,f.statuses);let evasion=this.perkBonuses(side).evasion;if(f.move_phase==='windup')evasion+=f.pending_move.airborne_evasion??0;runtime.evasion=clamp(runtime.evasion+evasion,...B.stat_bounds.evasion);return runtime;
  }
  perkBonuses(side) {
    const f=this.fighters[side],bonuses={evasion:0,critical_reduction:0};for(const perk of f.descriptor.passive_perks){if(f.hp/f.max_hp>(perk.below_hp??1))continue;for(const [key,value]of Object.entries(perk.runtime))bonuses[key]=(bonuses[key]??0)+value;}return bonuses;
  }
  currentPhase(side) {
    const f=this.fighters[side],a=f.descriptor.ability;if(a.id!=='phase_shift')return {};let current={};
    for(let i=0;i<(a.phases??[]).length;i++)if(f.hp/f.max_hp<=(a.phases[i].below_hp??1)){current=clone(a.phases[i]);current.index=i;}return current;
  }
  announcePhase(side,events) {
    const phase=this.currentPhase(side),f=this.fighters[side];if(empty(phase)||f.hp<=0||f.announced_phase===phase.index)return;
    f.announced_phase=phase.index;this.metrics[side].abilities++;
    this.emit({type:'ability',side,ability_id:'phase_shift',name:phase.name,phase_index:phase.index,modifiers:clone(phase.modifiers??{}),message:`${this.name(side)} entra en ${phase.name}. ${phase.description??''}`},events);
  }
  checkTerminal(reason,events) {
    if(!this.running)return true;if(this.player_hp>0&&this.rival_hp>0)return false;
    let victor=this.rival_hp<=0?'player':'rival';if(this.player_hp<=0&&this.rival_hp<=0){victor=this.rng.randf()<.5?'player':'rival';this.emit({type:'ability',name:'Desempate',message:'Ambos caen a la vez. El sorteo de la liga resuelve la ronda.'},events);}
    this.finish(victor,reason,events);return true;
  }
  ratioWinner(){const p=this.player_hp/this.player_max_hp,r=this.rival_hp/this.rival_max_hp;return approximatelyEqual(p,r)?(this.rng.randf()<.5?'player':'rival'):p>r?'player':'rival';}
  finish(victor,reason,events) {
    if(!this.running)return;this.running=false;this.winner=victor;for(const side of SIDES)this.fighters[side].defeated=this.fighters[side].hp<=0||(reason==='surrender'&&side!==victor);
    this.emit({type:'finished',winner:victor,loser:other(victor),reason,duration:this.elapsed,battle_id:this.battle_id,turns:this.turn,message:`${this.name(victor)} gana${reason==='surrender'?' por rendición':reason==='timeout'?' por porcentaje de vida':''}.`},events);
    this.terminal_summary={battle_id:this.battle_id,winner:victor,loser:other(victor),reason,duration:this.elapsed,turns:this.turn,seed:this.seed,player:clone(this.fighters.player.descriptor),rival:clone(this.fighters.rival.descriptor),metrics:clone(this.metrics),terminal_state:this.snapshot(),events:clone(this.event_log)};
  }
  syncHp(){if(!this.fighters.player||!this.fighters.rival)return;this.player_hp=this.fighters.player.hp;this.rival_hp=this.fighters.rival.hp;this.player_max_hp=this.fighters.player.max_hp;this.rival_max_hp=this.fighters.rival.max_hp;}
  emit(event,events){event.message??='';event.turn=this.turn;event.time=this.elapsed;event.player_hp=this.player_hp;event.rival_hp=this.rival_hp;if(this.options.include_states)event.state=this.snapshot();events.push(event);this.event_log.push(clone(event));}
  name(side){return this.fighters[side].descriptor.name;}
}
export function simulateBattle(player,rival,seed,options={}) {
  const engine=new BattleEngine();engine.start(player,rival,seed,options);
  if(Object.hasOwn(options,'surrender_at')){engine.advance(options.surrender_at);engine.surrender(options.surrender_side??'player');}
  else engine.advance(B.combat.max_duration);
  const result=engine.summary();result.final_state=clone(result.terminal_state);result.engine_version=ENGINE_VERSION;result.catalog_version=CATALOG_VERSION;result.rng_version=RNG_VERSION;return result;
}
