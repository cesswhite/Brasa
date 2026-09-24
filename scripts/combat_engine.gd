class_name CombatEngine
extends RefCounted
## Authoritative scheduler. Rendering delta changes presentation only.
## Progression consumes the immutable terminal summary; combat never grants XP.

const Balance = preload("res://scripts/balance.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Rules = preload("res://scripts/combat_rules.gd")
const Effects = preload("res://scripts/status_effects.gd")
const Moves = preload("res://scripts/move_catalog.gd")
const SIDES: Array[String] = ["player", "rival"]
const STAT_KEYS: Array[String] = ["life", "strength", "agility", "speed"]
var running: bool = false
var elapsed: float = 0.0
var player_hp: float = 0.0
var rival_hp: float = 0.0
var player_max_hp: float = 0.0
var rival_max_hp: float = 0.0
var winner: String = ""
var turn: int = 0
var active_side: String = ""
var battle_id: String = ""
var event_log: Array[Dictionary] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _fighters: Dictionary = {}
var _metrics: Dictionary = {}
var _terminal_summary: Dictionary = {}
var _initial_events: Array[Dictionary] = []
var _seed: int = 0
var _pending_counters: Array[Dictionary] = []


static func describe_stats(stats: Dictionary) -> Dictionary:
	var detail: Dictionary = Catalog.stats_for({"character_id": "luma", "level": 1, "stats": stats})
	detail["damage"] = detail.attack
	detail["dodge_chance"] = detail.evasion
	return detail


func start(player: Dictionary, rival: Dictionary, seed_value: int = 0, options: Dictionary = {}) -> void:
	if seed_value == 0:
		_rng.randomize()
	else:
		_rng.seed = seed_value
	_seed = _rng.seed
	running = true
	elapsed = 0.0
	winner = ""
	turn = 0
	active_side = ""
	event_log.clear()
	_initial_events.clear()
	_terminal_summary.clear()
	_fighters.clear()
	_metrics.clear()
	_pending_counters.clear()
	var originals: Dictionary = {"player": player, "rival": rival}
	for side: String in SIDES:
		var descriptor: Dictionary = _normalize_combatant(originals[side], side)
		var stats: Dictionary = descriptor.combat_stats.duplicate(true)
		var armed: bool = _rng.randf() < float(Balance.SIGNATURE.chance)
		if bool(options.get("disable_signatures", false)):
			armed = false
		var forced: Variant = options.get("force_signature", [])
		if (forced is Array and side in forced) or (forced is String and (forced == side or forced == "both")) or (forced is bool and forced):
			armed = true
		var signature_turn: int = _rng.randi_range(int(Balance.SIGNATURE.min_turn), int(Balance.SIGNATURE.max_turn))
		if options.has("signature_turn"):
			signature_turn = maxi(1, int(options.signature_turn))
		var opening: float = _rng.randf_range(float(Balance.COMBAT.opening_min), float(Balance.COMBAT.opening_max))
		opening *= float(stats.interval) / Balance.interval_for(6.0)
		if options.has("opening_time"):
			opening = maxf(0.01, float(options.opening_time))
		_fighters[side] = {"descriptor": descriptor, "base_stats": stats, "hp": float(stats.max_hp), "max_hp": float(stats.max_hp), "statuses": [], "turns_taken": 0, "next_action": opening, "defeated": false, "surrendered": false, "signature_armed": armed, "signature_used": false, "signature_turn": signature_turn, "comeback_used": false, "announced_phase": -1, "move_phase":"idle", "pending_move":{}, "pending_signature":false, "impact_at":INF, "recovery_at":INF, "move_started_at":0.0, "cooldowns":{}, "last_move":"", "stance":{}, "counter_pending":false}
		_metrics[side] = {"attacks": 0, "hits": 0, "criticals": 0, "misses": 0, "dodges": 0, "damage_dealt": 0, "damage_taken": 0, "absorbed": 0, "healing": 0, "abilities": 0, "signatures": 0, "statuses_applied": 0, "counters": 0, "turns_survived": 0, "statuses_prevented": 0, "status_turns_resisted": 0, "move_uses":{}, "critical_damage_taken":0}
		var initial_hp: Dictionary = options.get("initial_hp", {})
		if initial_hp.has(side):
			_fighters[side].hp = clampf(float(initial_hp[side]), 0.0, float(stats.max_hp))
		var initial_statuses: Dictionary = options.get("initial_statuses", {})
		for spec: Dictionary in initial_statuses.get(side, []):
			Effects.apply(_fighters[side].statuses, spec, str(spec.get("source", _other(side))), 0, float(stats.max_hp))
	battle_id = str(options.get("battle_id", "brasa_%s_%s" % [str(_seed), str(JSON.stringify([_fighters.player.descriptor, _fighters.rival.descriptor]).hash())]))
	_sync_hp()
	for side: String in SIDES:
		var ability: Dictionary = _fighters[side].descriptor.ability
		if str(ability.get("id", "")) == "shield":
			_grant_shield(side, ability, _initial_events)
		_announce_phase(side, _initial_events)


func advance(delta: float) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not running or not is_finite(delta) or delta <= 0.0:
		return events
	if not _initial_events.is_empty():
		events.append_array(_initial_events)
		_initial_events.clear()
	if _check_terminal("normal", events): return events
	var target_time: float = minf(float(Balance.COMBAT.max_duration), elapsed + delta)
	while running:
		var next_time: float = _next_event_time()
		if next_time > target_time: break
		elapsed = next_time
		# Recovery finishes before an action scheduled at the same instant.
		for side: String in SIDES:
			var fighter: Dictionary = _fighters[side]
			if _due(float(fighter.recovery_at)):
				_emit({"type":"move_recovered","side":side,"move_id":fighter.pending_move.get("id",""),"message":""},events)
				fighter.recovery_at = INF
				fighter.move_phase = "idle"
				fighter.pending_move = {}
		var starters: Array[String] = []
		for side: String in SIDES:
			if _due(float(_fighters[side].next_action)):
				starters.append(side)
				_fighters[side].turns_taken = int(_fighters[side].turns_taken)+1
				_metrics[side].turns_survived = int(_fighters[side].turns_taken)
				turn += 1
				active_side = side
				if not _fighters[side].stance.is_empty() and int(_fighters[side].turns_taken)>=int(_fighters[side].stance.until_action):
					_fighters[side].stance = {}
					_emit({"type":"stance_expired","side":side,"message":"%s abandona la postura." % _name(side)},events)
				_tick_dots(side,events)
		# Keep the old simultaneous-DOT rule and exactly one terminal outcome.
		if _check_terminal("dot",events): break
		if starters.size()==2 and _rng.randf()<0.5: starters.reverse()
		for side: String in starters:
			active_side = side
			_take_action(side,events)
		var impacts: Array[String] = []
		for side: String in SIDES:
			if _due(float(_fighters[side].impact_at)): impacts.append(side)
		if impacts.size()==2 and _rng.randf()<0.5: impacts.reverse()
		for side: String in impacts:
			if not running: break
			_resolve_move(side,events)
		for index in range(_pending_counters.size()-1,-1,-1):
			if not running: break
			if _due(float(_pending_counters[index].at)):
				var reaction: Dictionary = _pending_counters[index]
				_pending_counters.remove_at(index)
				_fighters[str(reaction.side)].counter_pending = false
				_resolve_counter(reaction,events)
	if running:
		elapsed = target_time
		if elapsed >= float(Balance.COMBAT.max_duration):
			_finish(_ratio_winner(),"timeout",events)
	return events


func _due(time: float) -> bool:
	return absf(time-elapsed)<0.0000001


func _next_event_time() -> float:
	var result: float = INF
	for side: String in SIDES:
		var fighter: Dictionary = _fighters[side]
		result = minf(result,minf(float(fighter.next_action),minf(float(fighter.impact_at),float(fighter.recovery_at))))
	for reaction: Dictionary in _pending_counters:
		result = minf(result,float(reaction.at))
	return result

func surrender(side: String = "player") -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not running or not side in SIDES:
		return events
	_initial_events.clear()
	_fighters[side].surrendered = true
	_emit({"type": "surrender", "side": side, "message": "%s se rinde. %s gana la ronda." % [_name(side), _name(_other(side))]}, events)
	_finish(_other(side), "surrender", events)
	return events


func snapshot() -> Dictionary:
	var fighters: Dictionary = {}
	for side: String in SIDES:
		if not _fighters.has(side):
			continue
		var fighter: Dictionary = _fighters[side]
		fighters[side] = {"hp": fighter.hp, "max_hp": fighter.max_hp, "shield": Effects.shield_total(fighter.statuses), "level": fighter.descriptor.level, "statuses": fighter.statuses.duplicate(true), "turns_taken": fighter.turns_taken, "defeated": fighter.defeated, "surrendered": fighter.surrendered, "signature_used": fighter.signature_used, "runtime_stats": _runtime(side), "stance":fighter.stance.duplicate(true), "move_phase":fighter.move_phase, "pending_move":fighter.pending_move.duplicate(true), "cooldowns":fighter.cooldowns.duplicate(true)}
	return {"turn": turn, "active_side": active_side, "fighters": fighters, "running": running, "elapsed": elapsed, "winner": winner, "battle_id": battle_id}


func summary() -> Dictionary:
	return _terminal_summary.duplicate(true)


func _normalize_combatant(raw: Dictionary, side: String) -> Dictionary:
	var descriptor: Dictionary = raw.duplicate(true)
	if not descriptor.has("character_id"):
		descriptor["character_id"] = Catalog.id_for_archetype(int(raw.get("archetype", 1)))
	var definition: Dictionary = Catalog.definition(str(descriptor.character_id))
	if definition.is_empty():
		definition = Catalog.definition("nima")
		descriptor["character_id"] = "nima"
	descriptor["name"] = str(raw.get("name", definition.get("name", side)))
	descriptor["archetype"] = int(raw.get("archetype", definition.get("archetype", 1)))
	descriptor["level"] = clampi(int(raw.get("level", 1)), 1, Balance.MAX_LEVEL)
	if not descriptor.has("stats"):
		descriptor["stats"] = raw.duplicate(true) if raw.has("life") else definition.training_base.duplicate(true)
	if not descriptor.has("combat_stats"):
		descriptor["combat_stats"] = Catalog.stats_for(descriptor)
	else:
		var bounded: Dictionary = Catalog.stats_for(descriptor)
		for key: String in bounded:
			var candidate: Variant = descriptor.combat_stats.get(key, bounded[key])
			if (candidate is int or candidate is float) and is_finite(float(candidate)):
				bounded[key] = maxf(0.0, float(candidate))
				if Balance.STAT_BOUNDS.has(key):
					var limits: Array = Balance.STAT_BOUNDS[key]
					bounded[key] = clampf(float(bounded[key]), float(limits[0]), float(limits[1]))
		bounded["max_hp"] = maxf(1.0, float(bounded.max_hp))
		bounded["interval"] = Balance.interval_for(float(bounded.speed))
		descriptor["combat_stats"] = bounded
	descriptor["ability"] = raw.get("ability", definition.ability).duplicate(true)
	descriptor["signature"] = raw.get("signature", definition.signature).duplicate(true)
	var move_id: String = str(raw.get("story_boss_id",descriptor.character_id))
	if Moves.moves_for(move_id).is_empty(): move_id = str(descriptor.character_id)
	descriptor["move_character_id"] = move_id
	descriptor["perks"] = []
	descriptor["passive_perks"] = []
	for perk: Dictionary in Moves.perks_for(move_id):
		if str(perk.id) in raw.get("perks",[]) and descriptor.perks.size()<3:
			descriptor.perks.append(str(perk.id))
			if perk.has("runtime"): descriptor.passive_perks.append(perk.duplicate(true))
	var resolved: Array[Dictionary] = []
	if raw.get("moves",[]) is Array:
		for move: Variant in raw.get("moves",[]):
			if move is Dictionary and move.has_all(["id","name","type","animation_type","movement"]) and str(move.type) in Moves.TYPES:
				resolved.append(Moves.bound_move(move))
	if resolved.is_empty():
		for move: Dictionary in Moves.unlocked_moves(move_id,int(descriptor.level)):
			if raw.has("unlocked_moves") and not str(move.id) in raw.unlocked_moves: continue
			resolved.append(Moves.improve_move(move_id,move,int(raw.get("move_upgrades",{}).get(str(move.id),0)),descriptor.perks))
	if resolved.is_empty(): resolved = Moves.unlocked_moves(move_id,1)
	descriptor["moves"] = resolved
	return descriptor


func _take_action(side: String, events: Array[Dictionary]) -> void:
	var fighter: Dictionary = _fighters[side]
	var ability: Dictionary = fighter.descriptor.ability
	if Effects.has_type(fighter.statuses,"stun"):
		_emit({"type":"ability","side":side,"ability_id":"stun","message":"%s pierde una acción por aturdimiento." % _name(side)},events)
		_complete_action(side,events)
		fighter.next_action = elapsed+float(_runtime(side).interval)
		return
	if str(ability.get("id",""))=="comeback" and not bool(fighter.comeback_used) and float(fighter.hp)/float(fighter.max_hp)<=float(ability.threshold):
		fighter.comeback_used = true
		_ability_event(side,ability,events)
		_heal(side,float(fighter.max_hp)*float(ability.heal_fraction),events)
	if str(ability.get("id",""))=="shield" and int(fighter.turns_taken)>1 and (int(fighter.turns_taken)-1)%maxi(1,int(ability.every))==0:
		_grant_shield(side,ability,events)
	var signature: bool = bool(fighter.signature_armed) and not bool(fighter.signature_used) and int(fighter.turns_taken)>=int(fighter.signature_turn)
	var move: Dictionary = _select_move(side)
	if signature:
		move = Moves.bound_move({"id":"signature","name":str(fighter.descriptor.signature.name),"type":"signature","animation_type":"signature","damage_multiplier":1.0,"windup":Moves.CONFIG.signature_windup,"travel":Moves.CONFIG.signature_travel,"recovery":Moves.CONFIG.signature_recovery,"priority":0.0,"weight":1.0,"movement":{"kind":"charge","retreat":20.0,"distance":100.0,"height":0.0},"status":{},"self_status":{},"stance":{}})
	fighter.pending_move = move
	fighter.pending_signature = signature
	fighter.move_phase = "windup"
	fighter.impact_at = elapsed+float(move.impact_delay)
	fighter.recovery_at = elapsed+float(move.duration)
	fighter.move_started_at = elapsed
	fighter.last_move = str(move.id)
	if not signature:
		fighter.cooldowns[str(move.id)] = int(fighter.turns_taken)+int(move.cooldown)+1
	var variance: float = float(Balance.COMBAT.cadence_variance)
	var cadence: float = float(_runtime(side).interval)*(1.0-float(move.priority))*_rng.randf_range(1.0-variance,1.0+variance)
	fighter.next_action = elapsed+maxf(float(move.duration),maxf(float(Moves.CONFIG.min_cadence),cadence))
	_metrics[side].move_uses[str(move.id)] = int(_metrics[side].move_uses.get(str(move.id),0))+1
	_emit({"type":"move_started","side":side,"target":_other(side),"move":move.duplicate(true),"impact_delay":move.impact_delay,"duration":move.duration,"signature":signature,"action":fighter.turns_taken,"message":"%s prepara %s." % [_name(side),str(move.name)]},events)
	var self_status: Dictionary = move.get("self_status",{})
	if not self_status.is_empty() and Effects.is_negative(str(self_status.type)):
		_apply_status(side,side,self_status,1.0,true,events)


func _select_move(side: String) -> Dictionary:
	var fighter: Dictionary = _fighters[side]
	var target: Dictionary = _fighters[_other(side)]
	var choices: Array[Dictionary] = []
	var weights: Array[float] = []
	var total: float = 0.0
	var slower: bool = float(_runtime(side).speed)<float(_runtime(_other(side)).speed)
	for move: Dictionary in fighter.descriptor.moves:
		if int(fighter.cooldowns.get(str(move.id),0))>int(fighter.turns_taken): continue
		var weight: float = float(move.weight)
		if str(fighter.last_move)==str(move.id): weight *= float(Moves.CONFIG.repeat_weight)
		if float(target.hp)/float(target.max_hp)<float(Moves.CONFIG.finisher_ratio):
			weight *= float(Moves.CONFIG.finisher_weight) if str(move.type) in ["quick","dash"] else float(Moves.CONFIG.finisher_other_weight)
		if str(move.type) in ["guard","counter"]:
			weight *= float(Moves.CONFIG.defense_weight) if float(fighter.hp)/float(fighter.max_hp)<float(Moves.CONFIG.low_hp_ratio) else float(Moves.CONFIG.guard_healthy_weight)
			if not fighter.stance.is_empty(): weight *= float(Moves.CONFIG.existing_guard_weight)
		if not target.stance.is_empty() and float(move.guard_bonus)>0: weight *= float(Moves.CONFIG.guard_pressure_weight)
		if not move.status.is_empty() and Effects.has_type(target.statuses,str(move.status.type)): weight *= float(Moves.CONFIG.status_refresh_weight)
		if not move.self_status.is_empty() and not Effects.is_negative(str(move.self_status.type)) and Effects.has_type(fighter.statuses,str(move.self_status.type)): weight *= float(Moves.CONFIG.existing_buff_weight)
		if slower and str(move.type) in ["quick","dash"]: weight *= float(Moves.CONFIG.slower_fast_weight)
		choices.append(move)
		weights.append(maxf(0.001,weight))
		total += weights[-1]
	if choices.is_empty():
		# Catalog always includes one zero-cooldown quick move; malformed overrides
		# can exhaust themselves, in which case a weak catalog quick is available.
		return Moves.moves_for(str(fighter.descriptor.move_character_id))[0]
	var roll: float = _rng.randf()*total
	for index in range(choices.size()):
		roll -= weights[index]
		if roll<=0.0: return choices[index].duplicate(true)
	return choices[-1].duplicate(true)


func _resolve_move(side: String, events: Array[Dictionary]) -> void:
	var fighter: Dictionary = _fighters[side]
	var move: Dictionary = fighter.pending_move
	fighter.impact_at = INF
	fighter.move_phase = "recovery"
	if float(fighter.hp)<=0.0: return
	active_side = side
	var self_status: Dictionary = move.get("self_status",{})
	if not self_status.is_empty() and not Effects.is_negative(str(self_status.type)):
		_apply_status(side,side,self_status,1.0,true,events)
	if str(move.type) in ["guard","counter"]:
		var stance: Dictionary = move.stance.duplicate(true)
		stance["until_action"] = int(fighter.turns_taken)+int(stance.get("duration",1))
		stance["move_id"] = str(move.id)
		stance["name"] = str(move.name)
		fighter.stance = stance
		_emit({"type":"defensive_stance","side":side,"target":side,"move":move.duplicate(true),"name":move.name,"duration":stance.get("duration",1),"until_action":stance.until_action,"reduction":stance.get("reduction",0.0),"counter_chance":stance.get("chance",0.0),"message":"%s adopta %s." % [_name(side),str(move.name)]},events)
		if float(move.heal_fraction)>0: _heal(side,float(fighter.max_hp)*float(move.heal_fraction),events)
	else:
		_attack(side,events,move,bool(fighter.pending_signature))
	if running: _complete_action(side,events)


func _complete_action(side: String, events: Array[Dictionary]) -> void:
	var interval_before: float = float(_runtime(side).interval)
	for expired: Dictionary in Effects.expire_after_action(_fighters[side].statuses,int(_fighters[side].turns_taken)):
		_emit({"type":"status_expired","side":side,"status":expired,"message":"%s: termina %s." % [_name(side),expired.name]},events)
	var interval_after: float = float(_runtime(side).interval)
	var fighter: Dictionary = _fighters[side]
	if not is_equal_approx(interval_before,interval_after) and float(fighter.next_action)>elapsed:
		fighter.next_action = maxf(elapsed+(float(fighter.next_action)-elapsed)*interval_after/interval_before,float(fighter.recovery_at) if is_finite(float(fighter.recovery_at)) else 0.0)

func _attack(side: String, events: Array[Dictionary], move: Dictionary, signature: bool = false) -> void:
	if not running:
		return
	var target: String = _other(side)
	var fighter: Dictionary = _fighters[side]
	var defender: Dictionary = _fighters[target]
	var ability: Dictionary = fighter.descriptor.ability
	var defense_ability: Dictionary = defender.descriptor.ability
	var signature_data: Dictionary = fighter.descriptor.signature
	var modifier: float = 1.0 if signature else float(move.damage_multiplier)
	if not signature and not defender.stance.is_empty(): modifier *= 1.0+float(move.guard_bonus)
	if str(ability.get("id", "")) == "berserk":
		modifier *= 1.0 + (1.0 - float(fighter.hp) / float(fighter.max_hp)) * float(ability.missing_hp_bonus)
	elif str(ability.get("id", "")) == "combo" and not signature and (int(_metrics[side].attacks) + 1) % maxi(1, int(ability.every)) == 0:
		modifier *= float(ability.multiplier)
		_ability_event(side, ability, events)
	if signature:
		fighter.signature_used = true
		_metrics[side].signatures = int(_metrics[side].signatures) + 1
		modifier *= clampf(float(signature_data.get("modifier", signature_data.get("damage_multiplier", Balance.SIGNATURE.damage_multiplier))), float(Balance.SIGNATURE.min_multiplier), float(Balance.SIGNATURE.max_multiplier))
		_emit({"type": "signature", "side": side, "name": str(signature_data.name), "effect": str(signature_data.effect), "duration": int(signature_data.duration), "message": "★ %s desata %s: impacto certero y %s." % [_name(side), signature_data.name, Effects.NAMES.get(str(signature_data.effect), signature_data.effect)]}, events)
	var options: Dictionary = {"signature": signature, "modifier": modifier, "attacker_level": fighter.descriptor.level, "defender_level": defender.descriptor.level, "move":{} if signature else move}
	if str(ability.get("id", "")) == "precision":
		options["critical_armor_ignore"] = float(ability.armor_ignore)
	if str(defense_ability.get("id", "")) == "fortify":
		options["critical_reduction"] = float(defense_ability.critical_reduction)
	options["critical_reduction"] = minf(0.65,float(options.get("critical_reduction",0.0))+float(_perk_bonuses(target).critical_reduction))
	var roll: Dictionary = Rules.roll_attack(_runtime(side), _runtime(target), _rng, options)
	_metrics[side].attacks = int(_metrics[side].attacks) + 1
	var result: String = str(roll.result)
	var damage: Dictionary = _damage(target, float(roll.damage), side)
	if bool(roll.critical): _metrics[target].critical_damage_taken += ceili(float(damage.damage))
	var message: String = "%s golpea: −%d PV." % [_name(side), ceili(float(damage.damage))]
	if result == "dodge":
		_metrics[target].dodges = int(_metrics[target].dodges) + 1
		message = "%s esquiva a %s." % [_name(target), _name(side)]
	elif result == "miss":
		message = "%s falla el ataque." % _name(side)
	elif result == "critical":
		_metrics[side].criticals = int(_metrics[side].criticals) + 1
		message = "¡Crítico de %s! −%d PV." % [_name(side), ceili(float(damage.damage))]
	elif signature:
		message = "★ %s: −%d PV con %s." % [_name(side), ceili(float(damage.damage)), signature_data.name]
	if result == "critical" and str(ability.get("id", "")) == "precision":
		_ability_event(side, ability, events)
		message += " Ignora %.0f%% de defensa." % (float(ability.armor_ignore) * 100.0)
	if result == "critical" and str(defense_ability.get("id", "")) == "fortify":
		_ability_event(target, defense_ability, events)
		message += " %s reduce el extra crítico %.0f%%." % [_name(target), float(defense_ability.critical_reduction) * 100.0]
	if not result in ["miss", "dodge"] and str(ability.get("id", "")) == "berserk":
		message += " Furia +%.0f%%." % ((1.0 - float(fighter.hp) / float(fighter.max_hp)) * float(ability.missing_hp_bonus) * 100.0)
	if result in ["miss", "dodge"]:
		_metrics[side].misses = int(_metrics[side].misses) + 1
	else:
		_metrics[side].hits = int(_metrics[side].hits) + 1
	if float(damage.absorbed) > 0.0:
		message += " Escudo absorbe %d." % int(damage.absorbed)
	_emit({"type": "attack", "side": side, "target": target, "result": result, "damage": ceili(float(damage.damage)), "raw_damage": int(roll.damage), "absorbed": damage.absorbed, "target_hp": defender.hp, "signature": signature, "hit_chance": roll.hit_chance, "move_id":move.id, "move_name":move.name, "animation_type":move.animation_type, "movement":move.movement, "message":message}, events)
	_announce_phase(target, events)
	if not signature and not result in ["miss","dodge"] and not move.status.is_empty() and float(defender.hp)>0:
		_apply_status(target,side,move.status,float(move.status_chance),false,events)
	if signature:
		var spec: Dictionary = signature_data.duplicate(true)
		spec["type"] = str(signature_data.effect)
		_apply_status(target, side, spec, 1.0, true, events)
	elif result in ["miss", "dodge"] and str(ability.get("id", "")) == "adapt":
		_ability_event(side, ability, events)
		_apply_status(side, side, {"type": "accuracy_up", "magnitude": ability.accuracy_bonus, "duration": ability.duration}, 1.0, true, events)
	elif not result in ["miss", "dodge"] and str(ability.get("id", "")) == "poison" and float(defender.hp) > 0.0:
		var spec: Dictionary = ability.duplicate(true)
		spec["type"] = "poison"
		if _apply_status(target, side, spec, float(ability.chance), false, events):
			_ability_event(side, ability, events)
	if _check_terminal("normal", events):
		return
	if not result in ["miss","dodge"] and not defender.stance.is_empty() and _rng.randf()<Rules.counter_chance(float(defender.stance.get("chance",0.0)),_runtime(target),_runtime(side)):
		_counter(target,side,{"id":"stance","name":str(defender.stance.name),"multiplier":float(defender.stance.get("multiplier",0.0))},events)
	elif not result in ["miss", "dodge"] and str(defense_ability.get("id", "")) == "counter" and _rng.randf() < float(defense_ability.chance):
		_counter(target, side, defense_ability, events)


func _counter(side: String, target: String, ability: Dictionary, events: Array[Dictionary]) -> void:
	if not running or bool(_fighters[side].counter_pending): return
	_ability_event(side,ability,events)
	var move: Dictionary = Moves.bound_move({"id":"reaction_"+str(ability.id),"name":str(ability.get("name","Réplica")),"type":"counter","animation_type":"counter","damage_multiplier":float(ability.multiplier),"windup":Moves.CONFIG.counter_windup,"travel":Moves.CONFIG.counter_travel,"recovery":Moves.CONFIG.counter_recovery,"weight":1.0,"movement":{"kind":"dash","retreat":6.0,"distance":54.0,"height":0.0},"status":{},"self_status":{},"stance":{}})
	_fighters[side].counter_pending = true
	_pending_counters.append({"side":side,"target":target,"move":move,"at":elapsed+float(move.impact_delay)})
	_emit({"type":"move_started","side":side,"target":target,"move":move.duplicate(true),"counter":true,"impact_delay":move.impact_delay,"duration":move.duration,"message":"%s prepara una réplica." % _name(side)},events)


func _resolve_counter(reaction: Dictionary, events: Array[Dictionary]) -> void:
	var side: String = reaction.side
	var target: String = reaction.target
	if not running or float(_fighters[side].hp)<=0.0: return
	var move: Dictionary = reaction.move
	_metrics[side].counters = int(_metrics[side].counters)+1
	var roll: Dictionary = Rules.roll_attack(_runtime(side),_runtime(target),_rng,{"guaranteed_hit":true,"allow_critical":false,"modifier":move.damage_multiplier,"attacker_level":_fighters[side].descriptor.level,"defender_level":_fighters[target].descriptor.level})
	var damage: Dictionary = _damage(target,float(roll.damage),side)
	_emit({"type":"attack","side":side,"target":target,"result":"hit","counter":true,"move_id":move.id,"move_name":move.name,"animation_type":move.animation_type,"movement":move.movement,"damage":ceili(float(damage.damage)),"raw_damage":roll.damage,"absorbed":damage.absorbed,"target_hp":_fighters[target].hp,"message":"%s contraataca: −%d PV." % [_name(side),ceili(float(damage.damage))]},events)
	_announce_phase(target,events)
	_check_terminal("normal",events)

func _apply_status(target: String, source: String, spec: Dictionary, chance: float, guaranteed: bool, events: Array[Dictionary]) -> bool:
	var negative: bool = Effects.is_negative(str(spec.get("type", spec.get("effect", ""))))
	var resistance: float = float(_runtime(target).resistance) if negative else 0.0
	if not guaranteed:
		var status_roll: float = _rng.randf()
		if status_roll >= Rules.status_chance(chance, resistance):
			# Same roll isolates prevention by resistance from an ordinary failed proc.
			if negative and status_roll < clampf(chance, 0.0, 1.0):
				_metrics[target].statuses_prevented = int(_metrics[target].statuses_prevented) + 1
				_emit({"type": "status_resisted", "side": target, "source": source, "effect": str(spec.get("type", "")), "message": "%s resiste %s." % [_name(target), Effects.NAMES.get(str(spec.get("type", "")), "el efecto")]}, events)
			return false
	var adjusted: Dictionary = spec.duplicate(true)
	if spec.has("scaling_stat") and float(spec.get("scaling_base", 0.0)) > 0.0:
		var scaling_value: float = float(_runtime(source).get(str(spec.scaling_stat), spec.scaling_base))
		adjusted["magnitude"] = float(spec.magnitude) * scaling_value / float(spec.scaling_base)
	adjusted["duration"] = Rules.status_duration(int(spec.duration), resistance, negative)
	var interval_before: float = float(_runtime(target).interval)
	var application: Dictionary = Effects.apply(_fighters[target].statuses, adjusted, source, int(_fighters[target].turns_taken), float(_fighters[target].max_hp))
	if application.is_empty() or application.change == "ignored":
		return false
	# Preserve completed initiative progress when a speed effect changes its rate.
	# Thus a one-action slow delays the very next action, before it can expire.
	var interval_after: float = float(_runtime(target).interval)
	if not is_equal_approx(interval_before, interval_after) and float(_fighters[target].next_action) > elapsed:
		_fighters[target].next_action = maxf(elapsed + (float(_fighters[target].next_action) - elapsed) * interval_after / interval_before,float(_fighters[target].recovery_at) if is_finite(float(_fighters[target].recovery_at)) else 0.0)
	var effect: Dictionary = application.effect
	var turns_resisted: int = maxi(0, clampi(int(spec.duration), 1, int(Balance.STATUS.max_duration)) - int(adjusted.duration)) if negative else 0
	_metrics[target].status_turns_resisted = int(_metrics[target].status_turns_resisted) + turns_resisted
	_metrics[source].statuses_applied = int(_metrics[source].statuses_applied) + 1
	_emit({"type": "status_applied", "side": target, "source": source, "status": effect, "effect": effect.type, "duration": effect.remaining_turns, "turns_resisted": turns_resisted, "message": "%s: %s durante %d acciones propias.%s" % [_name(target), Effects.description(effect), int(effect.remaining_turns), " Resistencia acorta %d." % turns_resisted if turns_resisted > 0 else ""]}, events)
	return true


func _grant_shield(side: String, ability: Dictionary, events: Array[Dictionary]) -> void:
	_ability_event(side, ability, events)
	_apply_status(side, side, {"type": "shield", "magnitude": ability.magnitude, "duration": ability.duration, "stacking": "refresh"}, 1.0, true, events)
	_emit({"type": "shield", "side": side, "amount": Effects.shield_total(_fighters[side].statuses), "message": "%s levanta un escudo de %d." % [_name(side), int(Effects.shield_total(_fighters[side].statuses))]}, events)


func _ability_event(side: String, ability: Dictionary, events: Array[Dictionary]) -> void:
	_metrics[side].abilities = int(_metrics[side].abilities) + 1
	_emit({"type": "ability", "side": side, "ability_id": str(ability.id), "name": str(ability.get("name", ability.id)), "message": "%s activa %s." % [_name(side), str(ability.get("name", ability.id))]}, events)


func _heal(side: String, amount: float, events: Array[Dictionary]) -> void:
	var fighter: Dictionary = _fighters[side]
	var healing: float = minf(float(fighter.max_hp) - float(fighter.hp), maxf(0.0, amount) * Effects.healing_multiplier(fighter.statuses))
	healing = maxf(0.0, float(roundi(healing)))
	fighter.hp = minf(float(fighter.max_hp), float(fighter.hp) + healing)
	_metrics[side].healing = int(_metrics[side].healing) + int(healing)
	_sync_hp()
	_emit({"type": "heal", "side": side, "target": side, "amount": healing, "target_hp": fighter.hp, "message": "%s recupera +%d PV." % [_name(side), int(healing)]}, events)


func _tick_dots(side: String, events: Array[Dictionary]) -> void:
	var fighter: Dictionary = _fighters[side]
	for tick: Dictionary in Effects.dots(fighter.statuses, int(fighter.turns_taken)):
		var source: String = str(tick.effect.source)
		if not source in SIDES:
			source = _other(side)
		var damage: Dictionary = _damage(side, float(tick.damage), source, true)
		_emit({"type": "status_tick", "side": side, "source": source, "target": side, "effect": tick.effect.type, "damage": ceili(float(damage.damage)), "target_hp": fighter.hp, "remaining_turns": tick.effect.remaining_turns, "message": "%s sufre %s: −%d PV (%d acciones)." % [_name(side), tick.effect.name, ceili(float(damage.damage)), int(tick.effect.remaining_turns)]}, events)
		_announce_phase(side, events)


func _damage(target: String, amount: float, source: String, bypass_shield: bool = false) -> Dictionary:
	var fighter: Dictionary = _fighters[target]
	var can_change_phase: bool = str(fighter.descriptor.ability.get("id", "")) == "phase_shift"
	var interval_before: float = float(_runtime(target).interval) if can_change_phase else 1.0
	var safe_amount: float = maxf(0.0, amount) if is_finite(amount) else 0.0
	if not bypass_shield and not fighter.stance.is_empty(): safe_amount *= 1.0-float(fighter.stance.get("reduction",0.0))
	var absorption: Dictionary = {"remaining": safe_amount, "absorbed": 0.0}
	if not bypass_shield:
		absorption = Effects.absorb(fighter.statuses, safe_amount)
	var actual: float = minf(float(fighter.hp), maxf(0.0, float(absorption.remaining)))
	fighter.hp = maxf(0.0, float(fighter.hp) - actual)
	var interval_after: float = float(_runtime(target).interval) if can_change_phase else 1.0
	if not is_equal_approx(interval_before, interval_after) and float(fighter.next_action) > elapsed:
		fighter.next_action = maxf(elapsed + (float(fighter.next_action) - elapsed) * interval_after / interval_before,float(fighter.recovery_at) if is_finite(float(fighter.recovery_at)) else 0.0)
	_metrics[target].damage_taken = int(_metrics[target].damage_taken) + roundi(actual)
	_metrics[target].absorbed = int(_metrics[target].absorbed) + roundi(float(absorption.absorbed))
	_metrics[source].damage_dealt = int(_metrics[source].damage_dealt) + roundi(actual)
	_sync_hp()
	return {"damage": actual, "absorbed": float(absorption.absorbed)}


func _runtime(side: String) -> Dictionary:
	var base: Dictionary = _fighters[side].base_stats
	var phase: Dictionary = _current_phase(side)
	if not phase.is_empty():
		base = base.duplicate(true)
		for key: String in phase.get("modifiers", {}):
			if not Balance.STAT_BOUNDS.has(key) or key == "max_hp":
				continue
			var limits: Array = Balance.STAT_BOUNDS[key]
			base[key] = clampf(float(base[key]) * clampf(float(phase.modifiers[key]), 0.75, 1.25), float(limits[0]), float(limits[1]))
		base["interval"] = Balance.interval_for(float(base.speed))
	var runtime: Dictionary = Effects.runtime_stats(base,_fighters[side].statuses)
	var evasive: float = float(_perk_bonuses(side).evasion)
	if str(_fighters[side].move_phase)=="windup": evasive += float(_fighters[side].pending_move.get("airborne_evasion",0.0))
	runtime.evasion = clampf(float(runtime.evasion)+evasive,float(Balance.STAT_BOUNDS.evasion[0]),float(Balance.STAT_BOUNDS.evasion[1]))
	return runtime


func _perk_bonuses(side: String) -> Dictionary:
	var fighter: Dictionary = _fighters[side]
	var bonuses: Dictionary = {"evasion":0.0,"critical_reduction":0.0}
	for perk: Dictionary in fighter.descriptor.passive_perks:
		if float(fighter.hp)/float(fighter.max_hp)>float(perk.get("below_hp",1.0)): continue
		for key: String in perk.runtime: bonuses[key] = float(bonuses.get(key,0.0))+float(perk.runtime[key])
	return bonuses


func _current_phase(side: String) -> Dictionary:
	var fighter: Dictionary = _fighters[side]
	var ability: Dictionary = fighter.descriptor.ability
	if str(ability.get("id", "")) != "phase_shift":
		return {}
	var ratio: float = float(fighter.hp) / float(fighter.max_hp)
	var current: Dictionary = {}
	var phases: Array = ability.get("phases", [])
	for index: int in range(phases.size()):
		var phase: Dictionary = phases[index]
		if ratio <= float(phase.get("below_hp", 1.0)):
			current = phase.duplicate(true)
			current["index"] = index
	return current


func _announce_phase(side: String, events: Array[Dictionary]) -> void:
	var phase: Dictionary = _current_phase(side)
	if phase.is_empty() or float(_fighters[side].hp) <= 0.0 or int(_fighters[side].announced_phase) == int(phase.index):
		return
	_fighters[side].announced_phase = int(phase.index)
	_metrics[side].abilities = int(_metrics[side].abilities) + 1
	_emit({"type": "ability", "side": side, "ability_id": "phase_shift", "name": phase.name, "phase_index": phase.index, "modifiers": phase.get("modifiers", {}).duplicate(true), "message": "%s entra en %s. %s" % [_name(side), phase.name, phase.get("description", "")]}, events)


func _check_terminal(reason: String, events: Array[Dictionary]) -> bool:
	if not running:
		return true
	if player_hp > 0.0 and rival_hp > 0.0:
		return false
	var victor: String = "player" if rival_hp <= 0.0 else "rival"
	if player_hp <= 0.0 and rival_hp <= 0.0:
		victor = "player" if _rng.randf() < 0.5 else "rival"
		_emit({"type": "ability", "name": "Desempate", "message": "Ambos caen a la vez. El sorteo de la liga resuelve la ronda."}, events)
	_finish(victor, reason, events)
	return true


func _ratio_winner() -> String:
	var player_ratio: float = player_hp / player_max_hp
	var rival_ratio: float = rival_hp / rival_max_hp
	if is_equal_approx(player_ratio, rival_ratio):
		return "player" if _rng.randf() < 0.5 else "rival"
	return "player" if player_ratio > rival_ratio else "rival"


func _finish(victor: String, reason: String, events: Array[Dictionary]) -> void:
	if not running:
		return
	running = false
	winner = victor
	for side: String in SIDES:
		_fighters[side].defeated = float(_fighters[side].hp) <= 0.0 or (reason == "surrender" and side != winner)
	_emit({"type": "finished", "winner": winner, "loser": _other(winner), "reason": reason, "duration": elapsed, "battle_id": battle_id, "turns": turn, "message": "%s gana%s." % [_name(winner), " por rendición" if reason == "surrender" else (" por porcentaje de vida" if reason == "timeout" else "")]}, events)
	_terminal_summary = {"battle_id": battle_id, "winner": winner, "loser": _other(winner), "reason": reason, "duration": elapsed, "turns": turn, "seed": _seed, "player": _fighters.player.descriptor.duplicate(true), "rival": _fighters.rival.descriptor.duplicate(true), "metrics": _metrics.duplicate(true), "terminal_state": snapshot(), "events": event_log.duplicate(true)}


func _sync_hp() -> void:
	if _fighters.size() < 2:
		return
	player_hp = float(_fighters.player.hp)
	rival_hp = float(_fighters.rival.hp)
	player_max_hp = float(_fighters.player.max_hp)
	rival_max_hp = float(_fighters.rival.max_hp)


func _emit(event: Dictionary, events: Array[Dictionary]) -> void:
	if not event.has("message"):
		event["message"] = ""
	event["turn"] = turn
	event["time"] = elapsed
	event["player_hp"] = player_hp
	event["rival_hp"] = rival_hp
	events.append(event)
	event_log.append(event.duplicate(true))


func _name(side: String) -> String:
	return str(_fighters[side].descriptor.name)


static func _other(side: String) -> String:
	return "rival" if side == "player" else "player"
