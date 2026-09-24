class_name CombatRules
extends RefCounted
## All probability and damage calculations live here. No random global state.

const Balance = preload("res://scripts/balance.gd")
const Moves = preload("res://scripts/move_catalog.gd")


static func hit_chance(attacker: Dictionary, defender: Dictionary) -> float:
	return clampf(float(attacker.get("accuracy", 0.96)) - float(defender.get("evasion", 0.10)), float(Balance.COMBAT.hit_min), float(Balance.COMBAT.hit_max))


static func critical_chance(attacker: Dictionary) -> float:
	return clampf(float(attacker.get("crit_chance", 0.12)), float(Balance.COMBAT.crit_min), float(Balance.COMBAT.crit_max))


static func damage_preview(attacker: Dictionary, defender: Dictionary, attacker_level: int = 1, defender_level: int = 1, modifier: float = 1.0, armor_ignore: float = 0.0) -> float:
	var attack: float = maxf(0.0, float(attacker.get("attack", 0.0)))
	var defense: float = maxf(0.0, float(defender.get("defense", 0.0))) * (1.0 - clampf(armor_ignore, 0.0, 1.0))
	var defense_scale: float = maxf(1.0, float(Balance.COMBAT.defense_scale))
	var level_factor: float = clampf(1.0 + float(attacker_level - defender_level) * float(Balance.COMBAT.level_damage_per_level), float(Balance.COMBAT.level_damage_min), float(Balance.COMBAT.level_damage_max))
	return maxf(float(Balance.COMBAT.min_damage), attack * defense_scale / (defense_scale + defense) * maxf(0.0, modifier) * level_factor)


static func roll_attack(attacker: Dictionary, defender: Dictionary, rng: RandomNumberGenerator, options: Dictionary = {}) -> Dictionary:
	attacker = move_stats(attacker,options.get("move",{}))
	var signature: bool = bool(options.get("signature", false))
	var hit: float = hit_chance(attacker, defender)
	if not signature and not bool(options.get("guaranteed_hit",false)) and rng.randf() >= hit:
		# A failed accuracy check is described as dodge when evasion caused it.
		var miss_weight: float = maxf(0.01, 1.0 - float(attacker.get("accuracy", 0.96)))
		var evasion_weight: float = maxf(0.0, float(defender.get("evasion", 0.1)))
		var result: String = "dodge" if rng.randf() < evasion_weight / (evasion_weight + miss_weight) else "miss"
		return {"result": result, "damage": 0, "hit_chance": hit, "critical": false, "signature": false}
	var critical: bool = not signature and bool(options.get("allow_critical",true)) and rng.randf() < critical_chance(attacker)
	var multiplier: float = maxf(0.0, float(options.get("modifier", 1.0)))
	var armor_ignore: float = float(options.get("move",{}).get("armor_ignore",0.0))
	if critical: armor_ignore += float(options.get("critical_armor_ignore",0.0))
	armor_ignore = clampf(armor_ignore,0.0,0.65)
	var damage: float = damage_preview(attacker, defender, int(options.get("attacker_level", 1)), int(options.get("defender_level", 1)), multiplier, armor_ignore)
	if critical:
		var crit_multiplier: float = maxf(1.0, float(attacker.get("crit_damage", 1.55)))
		var crit_reduction: float = clampf(float(options.get("critical_reduction", 0.0)), 0.0, 1.0)
		damage *= 1.0 + (crit_multiplier - 1.0) * (1.0 - crit_reduction)
	var variance: float = clampf(float(Balance.COMBAT.variance), 0.0, 0.10)
	damage *= rng.randf_range(1.0 - variance, 1.0 + variance)
	return {
		"result": "signature" if signature else ("critical" if critical else "hit"),
		"damage": maxi(int(Balance.COMBAT.min_damage), roundi(damage)),
		"hit_chance": hit, "critical": critical, "signature": signature,
	}


static func move_stats(base: Dictionary, move: Dictionary) -> Dictionary:
	var result: Dictionary = base.duplicate(true)
	for item: Array in [["attack","base_damage"],["accuracy","accuracy_modifier"],["crit_chance","critical_chance_modifier"],["crit_damage","critical_damage_modifier"]]:
		var key: String = item[0]
		var limits: Array = Balance.STAT_BOUNDS[key]
		result[key] = clampf(float(result.get(key,limits[0]))+float(move.get(item[1],0.0)),float(limits[0]),float(limits[1]))
	return result


static func counter_chance(base: float, defender: Dictionary, attacker: Dictionary) -> float:
	if base<=0.0: return 0.0
	var accuracy_factor: float = hit_chance(defender,attacker)
	var speed_bonus: float = (float(defender.speed)-float(attacker.speed))*float(Moves.CONFIG.counter_speed_factor)
	return clampf(base*accuracy_factor+speed_bonus,0.03,float(Moves.CONFIG.max_counter_chance))


static func status_chance(chance: float, resistance: float) -> float:
	return clampf(chance * (1.0 - clampf(resistance, 0.0, 1.0) * float(Balance.STATUS.resistance_chance_factor)), 0.0, 1.0)


static func status_duration(turns: int, resistance: float, negative: bool = true) -> int:
	var duration: int = clampi(turns, 1, int(Balance.STATUS.max_duration))
	if not negative:
		return duration
	return maxi(1, ceili(float(duration) * (1.0 - clampf(resistance, 0.0, 1.0) * float(Balance.STATUS.resistance_duration_factor))))
