class_name BattleIdentity
extends RefCounted
## Historical presentation is copied from the combat snapshot, never a live profile.
const VERSION := 1

static func attach(record: Dictionary, summary: Dictionary) -> void:
	var player: Dictionary = summary.get("player", {})
	var rival: Dictionary = summary.get("rival", {})
	if not player.has("fighter_id"): return # Legacy callers remain compatible.
	var player_name := str(player.get("name", record.get("player_name", "Compañero")))
	var rival_name := str(rival.get("name", record.get("rival_name", "Rival")))
	record["player_name"] = player_name
	record["rival_name"] = rival_name
	record["winner_name"] = player_name if str(summary.get("winner", "")) == "player" else rival_name
	record["loser_name"] = rival_name if str(summary.get("winner", "")) == "player" else player_name
	record["player_fighter_id"] = str(player.fighter_id)
	record["rival_fighter_id"] = str(rival.get("fighter_id", rival.get("opponent_id", "story:" + str(rival.get("story_stage_id", rival.get("character_id", "rival"))))))
	record["battle_snapshot"] = {"version": VERSION, "battle_id": str(summary.get("battle_id", "")),
		"seed": summary.get("seed", 0), "player": player.duplicate(true), "rival": rival.duplicate(true),
		"events": summary.get("events", []).duplicate(true), "duration": float(summary.get("duration", 0.0)),
		"winner": str(summary.get("winner", "")), "reason": str(summary.get("reason", ""))}

static func snapshot(record: Dictionary) -> Dictionary:
	var value: Variant = record.get("battle_snapshot", {})
	if not value is Dictionary or not _number(value.get("version")) or float(value.version) != VERSION: return {}
	if not _descriptor(value.get("player")) or not _descriptor(value.get("rival")) or not value.get("events") is Array: return {}
	if not value.get("winner") is String or not value.winner in ["player", "rival"]: return {}
	if not _number(value.get("duration")) or float(value.duration) < 0 or float(value.duration) > 120: return {}
	if value.events.size() > 10000: return {}
	var previous := 0.0
	for event: Variant in value.events:
		if not event is Dictionary or not event.get("type") is String or not _number(event.get("time")): return {}
		if float(event.time) < previous or float(event.time) > float(value.duration)+0.001: return {}
		previous = float(event.time)
		for key: String in ["side", "target", "winner"]:
			if event.has(key) and not event[key] in ["player", "rival"]: return {}
		for key: String in ["player_hp", "rival_hp"]:
			if event.has(key) and not _number(event[key]): return {}
		if str(event.type) == "finished" and not event.has("winner"): return {}
		if str(event.type) == "move_started":
			if not event.get("move") is Dictionary: return {}
			var move: Dictionary = event.move
			for key: String in ["windup", "travel", "recovery", "duration", "impact_delay"]:
				if move.has(key) and (not _number(move[key]) or float(move[key]) < 0 or float(move[key]) > 120): return {}
			if move.has("movement"):
				if not move.movement is Dictionary: return {}
				for key: String in ["height", "distance", "retreat"]:
					if move.movement.has(key) and not _number(move.movement[key]): return {}
	return value.duplicate(true)

static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func _descriptor(value: Variant) -> bool:
	if not value is Dictionary or not value.get("name") is String or not value.get("character_id") is String: return false
	if not _number(value.get("level")) or not value.get("combat_stats") is Dictionary: return false
	if not _number(value.combat_stats.get("max_hp")) or float(value.combat_stats.max_hp) <= 0: return false
	for key: String in ["appearance", "identity", "visual"]:
		if value.has(key) and not value[key] is Dictionary: return false
	for key: String in ["archetype", "story_chapter_id"]:
		if value.has(key) and not _number(value[key]): return false
	var visual: Dictionary = value.get("visual", {})
	if visual.has("archetype") and not _number(visual.archetype): return false
	if visual.has("tint") and (not visual.tint is String or not Color.html_is_valid(visual.tint)): return false
	return true
