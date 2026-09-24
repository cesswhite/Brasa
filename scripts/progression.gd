class_name Progression
extends RefCounted
## Colección local: progreso permanente separado por personaje y por rival.
const Balance = preload("res://scripts/balance.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const BattleIdentity = preload("res://scripts/battle_identity.gd")
const SAVE_VERSION: int = 2
const STAT_KEYS: Array[String] = ["life", "strength", "agility", "speed"]
const BASE_STATS: Array[Dictionary] = [
	{"life": 6, "strength": 6, "agility": 4, "speed": 8},
	{"life": 6, "strength": 6, "agility": 6, "speed": 6},
	{"life": 8, "strength": 5, "agility": 4, "speed": 5},
]
const RIVAL_NAMES: Array[String] = ["Nara", "Tizón", "Mica", "Nimbo", "Cobre", "Yuca", "Ónix", "Tula", "Azafrán"]
const RIVAL_TITLES: Array[String] = ["del cañón rojo", "del jardín lunar", "del horno antiguo"]

var data: Dictionary = {}
var roster: Dictionary = {}
var opponents: Dictionary = {}
var history: Array[Dictionary] = []
var active_id: String = ""
var last_save_ok: bool = true
var load_notice: String = ""
var save_blocked: bool = false
var backup_path: String = ""
var _processed_battles: Dictionary = {}
var _anti_farm: Dictionary = {}
var _save_path: String = "user://brasa_save.json"
var _recovered_original: bool = false


func load_save(path: String = "user://brasa_save.json") -> void:
	_save_path = path
	data = {}
	roster = {}
	opponents = {}
	history = []
	active_id = ""
	_processed_battles = {}
	_anti_farm = {}
	last_save_ok = true
	save_blocked = false
	load_notice = ""
	backup_path = ""
	_recovered_original = false
	var exists: bool = FileAccess.file_exists(path)
	var payload: Dictionary = _read_payload(path) if exists else {}
	var decoded: Dictionary = _decode_payload(payload)
	if not decoded.is_empty():
		_apply_decoded(decoded)
		if int(payload.version) == 1:
			backup_path = _archive_file(path, "v1")
			if backup_path.is_empty():
				save_blocked = true
				last_save_ok = false
				load_notice = "No se pudo respaldar la partida anterior. Tu progreso sigue intacto; el guardado está protegido."
				return
			load_notice = "Partida anterior migrada. Conservamos una copia V1 de tu progreso."
			save()
		return
	# Una copia válida se recupera únicamente después de conservar el original.
	for candidate: String in [path + ".bak", path + ".v1.bak"]:
		var backup_payload: Dictionary = _read_payload(candidate)
		var recovered: Dictionary = _decode_payload(backup_payload)
		if recovered.is_empty():
			continue
		if exists:
			backup_path = _archive_file(path, "invalid")
			if backup_path.is_empty():
				break
		_apply_decoded(recovered)
		_recovered_original = true
		load_notice = "Recuperamos una copia válida. El archivo original se conserva como respaldo."
		save()
		return
	if exists:
		save_blocked = true
		last_save_ok = false
		load_notice = "La partida está dañada o usa otra versión. Conservamos el archivo sin modificarlo."


func save() -> bool:
	if data.is_empty() or active_id.is_empty() or save_blocked:
		last_save_ok = false
		return false
	roster[active_id] = data
	var absolute: String = ProjectSettings.globalize_path(_save_path)
	if DirAccess.make_dir_recursive_absolute(absolute.get_base_dir()) != OK:
		last_save_ok = false
		return false
	var payload: Dictionary = {
		"version": SAVE_VERSION, "active_id": active_id, "roster": roster,
		"opponents": opponents, "history": history,
		"processed_battles": _processed_battles, "anti_farm": _anti_farm,
	}
	var temporary: String = absolute + ".tmp"
	if not _write_text(temporary, JSON.stringify(payload, "\t")):
		last_save_ok = false
		return false
	if FileAccess.file_exists(absolute) and not _recovered_original:
		# No destruir cambios externos ni convertir un archivo inválido en backup.
		if _decode_payload(_read_payload(absolute)).is_empty():
			save_blocked = true
			last_save_ok = false
			load_notice = "El archivo cambió o dejó de ser válido. No se sobrescribió."
			DirAccess.remove_absolute(temporary)
			return false
		var backup_temp: String = absolute + ".bak.tmp"
		if DirAccess.copy_absolute(absolute, backup_temp) != OK or DirAccess.rename_absolute(backup_temp, absolute + ".bak") != OK:
			last_save_ok = false
			DirAccess.remove_absolute(temporary)
			return false
	last_save_ok = DirAccess.rename_absolute(temporary, absolute) == OK
	if last_save_ok:
		_recovered_original = false
	return last_save_ok


func create_fighter(fighter_name: String, archetype: int) -> void:
	select_character(Catalog.id_for_archetype(archetype), fighter_name)


func select_character(id: String, name_override: String = "") -> bool:
	if save_blocked or Catalog.definition(id).is_empty():
		return false
	if not roster.has(id):
		roster[id] = _new_profile(id, name_override)
	elif not name_override.strip_edges().is_empty():
		roster[id]["name"] = _clean_name(name_override)
	active_id = id
	data = roster[id]
	save()
	return true


func upgrade(stat: String) -> bool:
	if save_blocked or data.is_empty() or not stat in STAT_KEYS or int(data.points) <= 0:
		return false
	var training: Dictionary = data.stats
	if int(training[stat]) >= Balance.TRAINING_CAP:
		return false
	training[stat] = int(training[stat]) + 1
	data["points"] = int(data.points) - 1
	save()
	return true


func xp_needed() -> int:
	if int(data.get("level", 1)) >= Balance.MAX_LEVEL:
		return 0
	return Balance.xp_for_level(int(data.get("level", 1)))


func seconds_until_next_match() -> float:
	return maxf(0.0, float(_anti_farm.get("next_match_at", 0.0)) - Time.get_unix_time_from_system())


func active_combatant() -> Dictionary:
	if data.is_empty():
		return {}
	return _combatant(data)


func make_rival() -> Dictionary:
	if data.is_empty():
		return {}
	var level: int = int(data.level)
	var matches: int = int(data.matches)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 41731 + matches * 7919 + level * 113 + Catalog.IDS.find(active_id) * 101
	var offsets: Array = Balance.MATCHMAKING.normal_offsets
	var wide_every: int = int(Balance.MATCHMAKING.wide_gap_every)
	var wide_gap: int = int(Balance.MATCHMAKING.wide_gap)
	var offset: int = int(offsets[matches % offsets.size()])
	if matches > 0 and matches % wide_every == 0:
		offset = -wide_gap if matches % (wide_every * 2) == 0 else wide_gap
	var target_level: int = clampi(level + offset, 1, Balance.MAX_LEVEL)
	var player_power: float = Catalog.power(Catalog.stats_for(data))
	var candidates: Array[Dictionary] = []
	for id: String in Catalog.IDS:
		var candidate: Dictionary = _opponent_candidate(id, target_level, matches)
		candidate["distance"] = absf(Catalog.power(Catalog.stats_for(candidate.profile)) / maxf(1.0, player_power) - 1.0)
		candidates.append(candidate)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.distance) < float(b.distance))
	# Sorteo ponderado entre los cinco poderes más próximos: conserva variedad.
	var pool_size: int = mini(int(Balance.MATCHMAKING.candidate_pool), candidates.size())
	var weight_sum: float = 0.0
	for index in range(pool_size):
		weight_sum += 1.0 / (float(Balance.MATCHMAKING.distance_smoothing) + float(candidates[index].distance))
	var ticket: float = rng.randf() * weight_sum
	var chosen: Dictionary = candidates[pool_size - 1]
	for index in range(pool_size):
		ticket -= 1.0 / (float(Balance.MATCHMAKING.distance_smoothing) + float(candidates[index].distance))
		if ticket <= 0.0:
			chosen = candidates[index]
			break
	var opponent_id: String = str(chosen.opponent_id)
	if not opponents.has(opponent_id):
		opponents[opponent_id] = chosen.profile
	var result: Dictionary = _combatant(opponents[opponent_id])
	result["opponent_id"] = opponent_id
	result["matchmaking"] = {"player_power": player_power, "rival_power": float(result.power), "power_gap": float(chosen.distance)}
	return result


func _opponent_candidate(id: String, target_level: int, matches: int) -> Dictionary:
	var opponent_id: String = "npc_%s_%d" % [id, target_level]
	if opponents.has(opponent_id) and absi(int(opponents[opponent_id].level) - int(data.level)) > int(Balance.MATCHMAKING.wide_gap):
		opponent_id += "_%d" % (matches / 9)
	if opponents.has(opponent_id):
		return {"opponent_id": opponent_id, "profile": opponents[opponent_id]}
	var profile: Dictionary = _new_profile(id, RIVAL_NAMES[(matches + Catalog.IDS.find(id)) % RIVAL_NAMES.size()])
	profile["level"] = target_level
	profile["total_xp"] = _xp_before_level(target_level)
	profile["points"] = 0
	profile["opponent_id"] = opponent_id
	var training: Dictionary = profile.stats
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7171 + target_level * 1193 + Catalog.IDS.find(id) * 101
	for i in range(floori(float(target_level - 1) * float(Balance.MATCHMAKING.npc_training_per_level))):
		var stat: String = STAT_KEYS[rng.randi_range(0, STAT_KEYS.size() - 1)]
		training[stat] = mini(Balance.TRAINING_CAP, int(training[stat]) + 1)
	return {"opponent_id": opponent_id, "profile": profile}


func reward(won: bool) -> Dictionary:
	# Compatibilidad con callers V1: mismas recompensas 40/25, nuevos registros.
	if data.is_empty():
		return _empty_reward()
	var summary: Dictionary = {
		"battle_id": "legacy_%s_%d_%d" % [active_id, int(data.matches), Time.get_ticks_usec()],
		"winner": "player" if won else "rival", "reason": "normal", "duration": 30.0,
		"player": active_combatant(), "rival": make_rival(), "metrics": {},
	}
	return _reward_match(summary, true)


func reward_match(summary: Dictionary) -> Dictionary:
	return _reward_match(summary, false)


func _reward_match(summary: Dictionary, legacy: bool) -> Dictionary:
	var empty: Dictionary = _empty_reward()
	var battle_id: String = str(summary.get("battle_id", ""))
	if _processed_battles.has(battle_id):
		empty["duplicate"] = true
		return empty
	if save_blocked or data.is_empty() or battle_id.is_empty() or battle_id.length() > 200:
		return empty
	var winner: String = str(summary.get("winner", ""))
	var reason: String = str(summary.get("reason", "normal"))
	if not winner in ["player", "rival"] or not reason in ["normal", "timeout", "dot", "surrender"]:
		return empty
	if not summary.get("player") is Dictionary or not summary.get("rival") is Dictionary or not _is_number(summary.get("duration")):
		return empty
	if not summary.get("metrics", {}) is Dictionary:
		return empty
	var player_desc: Dictionary = summary.player
	var rival_desc: Dictionary = summary.rival
	var player_id: String = str(player_desc.get("character_id", ""))
	var rival_id: String = str(rival_desc.get("character_id", ""))
	if not roster.has(player_id) or Catalog.definition(rival_id).is_empty():
		return empty
	var opponent_id: String = str(rival_desc.get("opponent_id", "npc_" + rival_id + "_" + str(rival_desc.get("level", 1))))
	if not opponents.has(opponent_id):
		var rival_profile: Dictionary = _profile_from_combatant(rival_desc)
		if rival_profile.is_empty():
			return empty
		rival_profile["opponent_id"] = opponent_id
		opponents[opponent_id] = rival_profile
	var player_profile: Dictionary = roster[player_id]
	var rival_profile: Dictionary = opponents[opponent_id]
	var duration: float = clampf(float(summary.duration), 0.0, float(Balance.COMBAT.max_duration))
	var player_won: bool = winner == "player"
	var surrendered: bool = reason == "surrender" and not player_won
	var repeated: int = int(_anti_farm.get("repeat_count", 0)) + 1 if str(_anti_farm.get("last_opponent", "")) == opponent_id else 1
	var surrender_streak: int = int(_anti_farm.get("surrender_streak", 0)) + 1 if surrendered else 0
	var player_result: String = "win" if player_won else ("surrender" if surrendered else "loss")
	var rival_result: String = "loss" if player_won else "win"
	if reason == "surrender" and player_won:
		rival_result = "surrender"
	var player_xp: int = Balance.reward_base(int(player_profile.level), player_result)
	var rival_xp: int = Balance.reward_base(int(rival_profile.level), rival_result)
	var multiplier: float = 1.0
	if legacy:
		player_xp = int(Balance.XP.win if player_won else Balance.XP.loss)
		rival_xp = int(Balance.XP.loss if player_won else Balance.XP.win)
	else:
		# La victoria por rendición mantiene la recompensa normal del ganador.
		if not (player_won and reason == "surrender"):
			if duration < float(Balance.XP.short_match_seconds):
				multiplier *= maxf(float(Balance.XP.short_match_floor), duration / float(Balance.XP.short_match_seconds))
			if repeated > int(Balance.XP.repeat_opponent_threshold):
				multiplier *= maxf(float(Balance.XP.repeat_opponent_floor), 1.0 - float(repeated - int(Balance.XP.repeat_opponent_threshold)) * float(Balance.XP.repeat_opponent_decay))
		if surrendered:
			multiplier *= maxf(float(Balance.XP.repeat_surrender_floor), pow(float(Balance.XP.repeat_surrender_decay), float(surrender_streak - 1)))
		player_xp = maxi(1, floori(float(player_xp) * multiplier))
		if rival_result == "surrender" and duration < float(Balance.XP.short_match_seconds):
			rival_xp = maxi(1, floori(float(rival_xp) * maxf(float(Balance.XP.short_match_floor), duration / float(Balance.XP.short_match_seconds))))
	var player_reward: Dictionary = _grant_xp(player_profile, player_xp)
	var rival_reward: Dictionary = _grant_xp(rival_profile, rival_xp)
	_record_result(player_profile, player_won, surrendered)
	_record_result(rival_profile, not player_won, rival_result == "surrender")
	_processed_battles[battle_id] = true
	_anti_farm = {
		"last_opponent": opponent_id, "repeat_count": repeated, "surrender_streak": surrender_streak,
		"next_match_at": Time.get_unix_time_from_system() + float(Balance.XP.surrender_cooldown) if surrendered else 0.0,
	}
	var entry: Dictionary = {
		"battle_id": battle_id, "timestamp": int(Time.get_unix_time_from_system()),
		"winner": winner, "loser": "rival" if player_won else "player", "reason": reason,
		"duration": duration, "turns": int(summary.get("turns", 0)),
		"player_name": str(player_profile.name), "rival_name": str(rival_profile.name),
		"winner_name": str(player_profile.name) if player_won else str(rival_profile.name),
		"loser_name": str(rival_profile.name) if player_won else str(player_profile.name),
		"player_character_id": player_id, "rival_character_id": rival_id, "opponent_id": opponent_id,
		"player_xp": player_xp, "rival_xp": rival_xp,
		"player": player_reward.duplicate(true), "rival": rival_reward.duplicate(true),
		"metrics": summary.get("metrics", {}).duplicate(true),
	}
	BattleIdentity.attach(entry, summary)
	history.append(entry)
	while history.size() > Balance.HISTORY_LIMIT:
		history.pop_front()
	save()
	var result: Dictionary = player_reward.duplicate(true)
	result["player"] = player_reward
	result["rival"] = rival_reward
	result["duplicate"] = false
	result["history_entry"] = entry.duplicate(true)
	result["reward_multiplier"] = multiplier
	result["next_match_delay"] = seconds_until_next_match()
	return result


func _grant_xp(profile: Dictionary, amount: int) -> Dictionary:
	var before: Dictionary = Catalog.stats_for(profile)
	var level_before: int = int(profile.level)
	var xp_before: int = int(profile.xp)
	var level_ups: Array[Dictionary] = []
	profile["total_xp"] = int(profile.get("total_xp", 0)) + amount
	profile["xp"] = int(profile.xp) + amount
	while int(profile.level) < Balance.MAX_LEVEL and int(profile.xp) >= Balance.xp_for_level(int(profile.level)):
		var previous: Dictionary = Catalog.stats_for(profile)
		profile["xp"] = int(profile.xp) - Balance.xp_for_level(int(profile.level))
		profile["level"] = int(profile.level) + 1
		profile["points"] = int(profile.points) + Balance.POINTS_PER_LEVEL
		var gains: Dictionary = _stat_difference(previous, Catalog.stats_for(profile))
		level_ups.append({"level": int(profile.level), "stat_gains": gains, "stats": gains.duplicate(true)})
	if int(profile.level) >= Balance.MAX_LEVEL:
		profile["cap_xp"] = int(profile.get("cap_xp", 0)) + int(profile.xp)
		profile["xp"] = 0
	return {
		"xp_gained": amount, "levels_gained": int(profile.level) - level_before,
		"points_gained": (int(profile.level) - level_before) * Balance.POINTS_PER_LEVEL,
		"level_before": level_before, "level_after": int(profile.level),
		"xp_before": xp_before, "xp_after": int(profile.xp),
		"xp_required": 0 if int(profile.level) >= Balance.MAX_LEVEL else Balance.xp_for_level(int(profile.level)),
		"stat_gains": _stat_difference(before, Catalog.stats_for(profile)), "level_ups": level_ups,
		"at_max_level": int(profile.level) >= Balance.MAX_LEVEL, "total_xp": int(profile.total_xp),
	}


func _record_result(profile: Dictionary, won: bool, surrendered: bool) -> void:
	profile["matches"] = int(profile.matches) + 1
	var key: String = "wins" if won else "losses"
	profile[key] = int(profile[key]) + 1
	profile["streak"] = int(profile.get("streak", 0)) + 1 if won else 0
	profile["best_streak"] = maxi(int(profile.get("best_streak", 0)), int(profile.streak))
	if surrendered:
		profile["surrenders"] = int(profile.get("surrenders", 0)) + 1


static func _combatant(profile: Dictionary) -> Dictionary:
	var entry: Dictionary = Catalog.definition(str(profile.character_id))
	var result: Dictionary = profile.duplicate(true)
	result["combat_stats"] = Catalog.stats_for(profile)
	result["ability"] = entry.ability.duplicate(true)
	result["signature"] = entry.signature.duplicate(true)
	result["visual"] = entry.visual.duplicate(true)
	result["title"] = str(entry.role)
	result["power"] = Catalog.power(result.combat_stats)
	return result


static func _new_profile(id: String, given_name: String = "") -> Dictionary:
	var entry: Dictionary = Catalog.definition(id)
	return {
		"character_id": id, "name": _clean_name(given_name) if not given_name.strip_edges().is_empty() else str(entry.name),
		"archetype": int(entry.archetype), "level": 1, "xp": 0, "points": Balance.INITIAL_POINTS,
		"wins": 0, "losses": 0, "matches": 0, "streak": 0, "best_streak": 0,
		"surrenders": 0, "total_xp": 0, "cap_xp": 0, "stats": entry.training_base.duplicate(true),
	}


static func _profile_from_combatant(descriptor: Dictionary) -> Dictionary:
	var id: String = str(descriptor.get("character_id", ""))
	if Catalog.definition(id).is_empty():
		return {}
	var profile: Dictionary = _new_profile(id, str(descriptor.get("name", "")))
	profile["level"] = clampi(int(descriptor.get("level", 1)), 1, Balance.MAX_LEVEL)
	profile["total_xp"] = _xp_before_level(int(profile.level))
	if descriptor.get("stats") is Dictionary:
		for key: String in STAT_KEYS:
			if _is_number(descriptor.stats.get(key)):
				profile.stats[key] = clampi(int(descriptor.stats[key]), 1, Balance.TRAINING_CAP)
	return profile


static func _empty_reward() -> Dictionary:
	return {"xp_gained": 0, "levels_gained": 0, "points_gained": 0, "player": {}, "rival": {}, "duplicate": false}


static func _stat_difference(before: Dictionary, after: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: String in Balance.STAT_KEYS:
		var delta: float = float(after[key]) - float(before[key])
		if absf(delta) > 0.0000001:
			result[key] = delta
	return result


static func _decode_payload(payload: Dictionary) -> Dictionary:
	if not _is_number(payload.get("version")) or float(payload.version) != floor(float(payload.version)):
		return {}
	if float(payload.version) < 1.0 or float(payload.version) > float(SAVE_VERSION):
		return {}
	var version: int = int(payload.version)
	if version == 1:
		if not payload.get("fighter") is Dictionary:
			return {}
		var raw: Dictionary = payload.fighter
		if not _is_number(raw.get("archetype")):
			return {}
		var id: String = Catalog.id_for_archetype(int(raw.archetype))
		var profile: Dictionary = _validate_profile(raw, id)
		if profile.is_empty():
			return {}
		return {"roster": {id: profile}, "active_id": id, "opponents": {}, "history": [], "processed_battles": {}, "anti_farm": {}}
	if version != SAVE_VERSION or not payload.get("roster") is Dictionary or not payload.get("active_id") is String:
		return {}
	var decoded_roster: Dictionary = {}
	for id: Variant in payload.roster:
		if not id is String or Catalog.definition(str(id)).is_empty() or not payload.roster[id] is Dictionary:
			return {}
		var profile: Dictionary = _validate_profile(payload.roster[id], str(id))
		if profile.is_empty():
			return {}
		decoded_roster[id] = profile
	var chosen: String = str(payload.active_id)
	if not decoded_roster.has(chosen):
		return {}
	var decoded_opponents: Dictionary = {}
	if not payload.get("opponents", {}) is Dictionary or not payload.get("history", []) is Array:
		return {}
	for key: Variant in payload.get("opponents", {}):
		var raw: Variant = payload.opponents[key]
		if not key is String or not raw is Dictionary:
			return {}
		var id: String = str(raw.get("character_id", ""))
		var profile: Dictionary = _validate_profile(raw, id)
		if profile.is_empty():
			return {}
		profile["opponent_id"] = str(key)
		decoded_opponents[key] = profile
	var decoded_history: Array[Dictionary] = []
	for item: Variant in payload.get("history", []):
		if not item is Dictionary or not item.get("battle_id") is String or not str(item.get("winner", "")) in ["player", "rival"]:
			return {}
		decoded_history.append(item.duplicate(true))
	while decoded_history.size() > Balance.HISTORY_LIMIT:
		decoded_history.pop_front()
	if not payload.get("processed_battles", {}) is Dictionary or not payload.get("anti_farm", {}) is Dictionary:
		return {}
	var anti: Dictionary = payload.get("anti_farm", {})
	for key: String in ["repeat_count", "surrender_streak", "next_match_at"]:
		if anti.has(key) and not _is_number(anti[key]):
			return {}
	anti = {
		"last_opponent": str(anti.get("last_opponent", "")),
		"repeat_count": _bounded_int(anti.get("repeat_count", 0), 0, 1000000),
		"surrender_streak": _bounded_int(anti.get("surrender_streak", 0), 0, 1000000),
		"next_match_at": clampf(float(anti.get("next_match_at", 0.0)), 0.0, Time.get_unix_time_from_system() + float(Balance.XP.surrender_cooldown)),
	}
	var processed: Dictionary = payload.get("processed_battles", {}).duplicate(true)
	for battle_id: Variant in processed:
		if not battle_id is String or str(battle_id).is_empty():
			return {}
	for item: Dictionary in decoded_history:
		processed[str(item.battle_id)] = true
	return {"roster": decoded_roster, "active_id": chosen, "opponents": decoded_opponents,
		"history": decoded_history, "processed_battles": processed, "anti_farm": anti}


func _apply_decoded(decoded: Dictionary) -> void:
	roster = decoded.roster
	active_id = str(decoded.active_id)
	data = roster[active_id]
	opponents = decoded.opponents
	history.assign(decoded.history)
	_processed_battles = decoded.processed_battles
	_anti_farm = decoded.anti_farm


static func _validate_profile(raw: Dictionary, id: String) -> Dictionary:
	var entry: Dictionary = Catalog.definition(id)
	if entry.is_empty() or not raw.get("name") is String or not raw.get("stats") is Dictionary:
		return {}
	for key: String in ["level", "xp", "points", "wins", "losses", "matches"]:
		if not _is_number(raw.get(key)):
			return {}
	var training: Dictionary = {}
	for key: String in STAT_KEYS:
		if not _is_number(raw.stats.get(key)):
			return {}
		training[key] = _bounded_int(raw.stats[key], 1, Balance.TRAINING_CAP)
	var original_level: int = _bounded_int(raw.level, 1, 10000)
	var original_xp: int = _bounded_int(raw.xp, 0, 2000000000)
	var level: int = mini(original_level, Balance.MAX_LEVEL)
	var xp: int = original_xp
	var points: int = _bounded_int(raw.points, 0, 20000)
	while level < Balance.MAX_LEVEL and xp >= Balance.xp_for_level(level):
		xp -= Balance.xp_for_level(level)
		level += 1
		points += Balance.POINTS_PER_LEVEL
	var wins: int = _bounded_int(raw.wins, 0, 10000000)
	var losses: int = _bounded_int(raw.losses, 0, 10000000)
	var lifetime: int = _xp_before_level(original_level) + original_xp
	for key: String in ["streak", "best_streak", "surrenders", "total_xp", "cap_xp"]:
		if raw.has(key) and not _is_number(raw[key]):
			return {}
	var total_xp: int = maxi(lifetime, _bounded_int(raw.get("total_xp", lifetime), 0, 2000000000))
	var streak: int = _bounded_int(raw.get("streak", 0), 0, wins)
	var result: Dictionary = {
		"character_id": id, "name": _clean_name(str(raw.name)), "archetype": int(entry.archetype),
		"level": level, "xp": 0 if level >= Balance.MAX_LEVEL else xp, "points": points,
		"wins": wins, "losses": losses, "matches": maxi(wins + losses, _bounded_int(raw.matches, 0, 20000000)),
		"stats": training, "streak": streak, "best_streak": maxi(streak, _bounded_int(raw.get("best_streak", 0), 0, wins)),
		"surrenders": _bounded_int(raw.get("surrenders", 0), 0, losses), "total_xp": total_xp,
		"cap_xp": maxi(_bounded_int(raw.get("cap_xp", 0), 0, 2000000000), maxi(0, total_xp - _xp_before_level(Balance.MAX_LEVEL))) if level >= Balance.MAX_LEVEL else 0,
	}
	if original_level > Balance.MAX_LEVEL:
		result["legacy_level"] = original_level
	elif raw.has("legacy_level") and _is_number(raw.legacy_level):
		result["legacy_level"] = _bounded_int(raw.legacy_level, Balance.MAX_LEVEL, 10000)
	return result


static func _validate_fighter(raw: Dictionary) -> Dictionary:
	return _validate_profile(raw, Catalog.id_for_archetype(int(raw.get("archetype", 0))))


static func _xp_before_level(level: int) -> int:
	var count: int = maxi(0, level - 1)
	return count * int(Balance.XP.first_level) + (count * (count - 1) / 2) * int(Balance.XP.per_level)


static func _bounded_int(value: Variant, low: int, high: int) -> int:
	return int(clampf(float(value), float(low), float(high)))


static func _is_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))


static func _clean_name(value: String) -> String:
	var cleaned: String = value.replace("\n", " ").replace("\r", " ").replace("\t", " ").strip_edges().left(24)
	return "Brasa" if cleaned.is_empty() else cleaned


static func _read_payload(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parser: JSON = JSON.new()
	if parser.parse(text) != OK or not parser.data is Dictionary:
		return {}
	return parser.data


static func _write_text(path: String, contents: String) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(contents)
	file.flush()
	var error: Error = file.get_error()
	file.close()
	return error == OK


static func _archive_file(path: String, tag: String) -> String:
	var absolute: String = ProjectSettings.globalize_path(path)
	var destination: String = absolute + "." + tag + ".bak"
	if FileAccess.file_exists(destination):
		if FileAccess.get_file_as_string(absolute) == FileAccess.get_file_as_string(destination):
			return destination
		destination = absolute + "." + tag + "-" + str(Time.get_ticks_usec()) + ".bak"
	return destination if DirAccess.copy_absolute(absolute, destination) == OK else ""
