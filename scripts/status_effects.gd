class_name StatusEffects
extends RefCounted
## Durations count the affected fighter's own actions, including stunned actions.
## Effects applied during an action do not lose a turn on that same action.

const Balance = preload("res://scripts/balance.gd")
const DOT_TYPES: Array[String] = ["poison", "burn", "bleed"]
const POSITIVE_TYPES: Array[String] = ["attack_up", "defense_up", "accuracy_up", "shield"]
const NAMES: Dictionary = {
	"attack_down": "Debilidad", "defense_down": "Fractura", "slow": "Lentitud",
	"accuracy_down": "Niebla", "poison": "Veneno", "burn": "Quemadura",
	"bleed": "Sangrado", "healing_down": "Herida", "stun": "Aturdimiento",
	"attack_up": "Impulso", "defense_up": "Guardia", "accuracy_up": "Enfoque", "shield": "Escudo",
}


static func is_negative(type: String) -> bool:
	return not type in POSITIVE_TYPES


static func description(effect: Dictionary) -> String:
	var type: String = str(effect.get("type", effect.get("effect", "")))
	var magnitude: float = float(effect.get("magnitude", 0.0))
	var amount: String = ""
	if type in DOT_TYPES:
		amount = "−%d PV por acción" % roundi(magnitude)
	elif type == "shield":
		amount = "%d PV de protección" % roundi(magnitude)
	elif type == "stun":
		amount = "no puede atacar"
	else:
		var sign: String = "+" if type in POSITIVE_TYPES else "−"
		var unit: String = "puntos de precisión" if type in ["accuracy_down", "accuracy_up"] else "%"
		amount = "%s%.0f%s" % [sign, magnitude * 100.0, (" " + unit) if unit != "%" else unit]
	return "%s (%s)" % [str(NAMES.get(type, type)), amount]


static func apply(effects: Array, spec: Dictionary, source: String, owner_action: int, max_hp: float) -> Dictionary:
	var type: String = str(spec.get("type", spec.get("effect", "")))
	if not NAMES.has(type):
		return {}
	var limit: float = float(Balance.STATUS.max_magnitude)
	if type in DOT_TYPES:
		limit = max_hp * float(Balance.STATUS.max_dot_fraction)
	elif type == "shield":
		limit = max_hp * float(Balance.STATUS.max_shield_fraction)
	elif type == "stun":
		limit = 1.0
	var magnitude: float = clampf(float(spec.get("magnitude", 0.0)), 0.0, limit)
	var duration: int = clampi(int(spec.get("duration", 1)), 1, int(Balance.STATUS.max_duration))
	var stacking: String = str(spec.get("stacking", "refresh"))
	if not stacking in ["refresh", "intensity", "replace", "ignore"]:
		stacking = "refresh"
	var maximum_stacks: int = clampi(int(spec.get("max_stacks", Balance.STATUS.max_stacks)), 1, int(Balance.STATUS.max_stacks))
	for effect: Dictionary in effects:
		if effect.type != type:
			continue
		if stacking == "ignore":
			return {"effect": effect.duplicate(true), "change": "ignored"}
		if stacking == "intensity":
			var stacks: int = mini(maximum_stacks, int(effect.get("stacks", 1)) + 1)
			effect["stacks"] = stacks
			effect["magnitude"] = minf(limit, magnitude * float(stacks))
		elif stacking == "replace":
			effect["magnitude"] = magnitude
			effect["stacks"] = 1
		else:
			effect["magnitude"] = maxf(float(effect.magnitude), magnitude)
			effect["stacks"] = 1
		effect["duration"] = duration
		effect["remaining_turns"] = duration
		effect["source"] = source
		effect["stacking"] = stacking
		effect["applied_at_action"] = owner_action
		return {"effect": effect.duplicate(true), "change": "refreshed"}
	var added: Dictionary = {
		"id": type, "type": type, "name": str(NAMES[type]), "magnitude": magnitude,
		"duration": duration, "remaining_turns": duration, "source": source,
		"stacking": stacking, "stacks": 1, "applied_at_action": owner_action,
	}
	effects.append(added)
	return {"effect": added.duplicate(true), "change": "applied"}


static func runtime_stats(base: Dictionary, effects: Array) -> Dictionary:
	var stats: Dictionary = base.duplicate(true)
	for effect: Dictionary in effects:
		var magnitude: float = float(effect.magnitude)
		match str(effect.type):
			"attack_down": stats["attack"] = float(stats.attack) * (1.0 - magnitude)
			"attack_up": stats["attack"] = float(stats.attack) * (1.0 + magnitude)
			"defense_down": stats["defense"] = float(stats.defense) * (1.0 - magnitude)
			"defense_up": stats["defense"] = float(stats.defense) * (1.0 + magnitude)
			"slow": stats["speed"] = float(stats.speed) * (1.0 - magnitude)
			"accuracy_down": stats["accuracy"] = float(stats.accuracy) - magnitude
			"accuracy_up": stats["accuracy"] = float(stats.accuracy) + magnitude
	for key: String in Balance.STAT_BOUNDS:
		if not stats.has(key): continue
		var limits: Array = Balance.STAT_BOUNDS[key]
		stats[key] = clampf(float(stats[key]),float(limits[0]),float(limits[1]))
	stats["interval"] = Balance.interval_for(maxf(0.0, float(stats.speed)))
	return stats


static func dots(effects: Array, owner_action: int) -> Array[Dictionary]:
	var ticks: Array[Dictionary] = []
	for effect: Dictionary in effects:
		if str(effect.type) in DOT_TYPES and int(effect.applied_at_action) < owner_action:
			ticks.append({"effect": effect.duplicate(true), "damage": maxi(0, roundi(float(effect.magnitude)))})
	return ticks


static func expire_after_action(effects: Array, owner_action: int) -> Array[Dictionary]:
	var expired: Array[Dictionary] = []
	for index in range(effects.size() - 1, -1, -1):
		var effect: Dictionary = effects[index]
		if int(effect.applied_at_action) >= owner_action:
			continue
		effect["remaining_turns"] = int(effect.remaining_turns) - 1
		if int(effect.remaining_turns) <= 0:
			expired.append(effect.duplicate(true))
			effects.remove_at(index)
	return expired


static func shield_total(effects: Array) -> float:
	var total: float = 0.0
	for effect: Dictionary in effects:
		if effect.type == "shield":
			total += float(effect.magnitude)
	return total


static func absorb(effects: Array, damage: float) -> Dictionary:
	var remaining: float = maxf(0.0, damage)
	var absorbed: float = 0.0
	for index in range(effects.size() - 1, -1, -1):
		var effect: Dictionary = effects[index]
		if effect.type != "shield":
			continue
		var amount: float = minf(remaining, float(effect.magnitude))
		effect["magnitude"] = float(effect.magnitude) - amount
		remaining -= amount
		absorbed += amount
		if float(effect.magnitude) <= 0.0:
			effects.remove_at(index)
	return {"remaining": remaining, "absorbed": absorbed}


static func has_type(effects: Array, type: String) -> bool:
	for effect: Dictionary in effects:
		if effect.type == type:
			return true
	return false


static func healing_multiplier(effects: Array) -> float:
	var multiplier: float = 1.0
	for effect: Dictionary in effects:
		if effect.type == "healing_down":
			multiplier *= 1.0 - float(effect.magnitude)
	return maxf(0.0, multiplier)
