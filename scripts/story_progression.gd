class_name StoryProgression
extends RefCounted
## Campañas independientes de la liga y separadas por cada personaje.
const Catalog = preload("res://scripts/character_catalog.gd")
const Balance = preload("res://scripts/balance.gd")
const Story = preload("res://scripts/story_catalog.gd")
const Campaign = preload("res://scripts/campaign_config.gd")
const Moves = preload("res://scripts/move_catalog.gd")
const BattleIdentity = preload("res://scripts/battle_identity.gd")
const SAVE_VERSION: int = 3
const SAVE_MODE: String = "story"
const LEGACY_KEYS: Array[String] = ["life", "strength", "agility", "speed"]

var data: Dictionary = {}
var roster: Dictionary = {}
var active_id: String = ""
var history: Array[Dictionary] = []
var save_blocked: bool = false
var last_save_ok: bool = true
var load_notice: String = ""
var backup_path: String = ""
var _save_path: String = "user://brasa_save.json.story.json"
var _processed_battles: Dictionary = {}
var _next_match_at: float = 0.0
var _surrender_chain: int = 0
var _recovered_original: bool = false
var _replay_level: int = 0


func load_save(path: String = "user://brasa_save.json.story.json") -> void:
	_save_path = path
	_replay_level = 0
	data = {}
	roster = {}
	active_id = ""
	history = []
	_processed_battles = {}
	_next_match_at = 0.0
	_surrender_chain = 0
	save_blocked = false
	last_save_ok = true
	load_notice = ""
	backup_path = ""
	_recovered_original = false
	var exists: bool = FileAccess.file_exists(path)
	var decoded: Dictionary = _decode(_read_payload(path)) if exists else {}
	if not decoded.is_empty():
		_apply_decoded(decoded)
		if int(_read_payload(path).get("version", SAVE_VERSION)) < SAVE_VERSION:
			load_notice = "Tu historia y tus legados se conservan. Nuevas técnicas y recompensas están disponibles; ningún capítulo se inicia automáticamente."
		return
	var recovered: Dictionary = _decode(_read_payload(path + ".bak"))
	if not recovered.is_empty():
		if exists:
			backup_path = _archive_original(path)
			if backup_path.is_empty():
				_block_save("No pudimos conservar el original de Historia. No se modificó la partida.")
				return
		_apply_decoded(recovered)
		_recovered_original = true
		load_notice = "Historia recuperada desde su copia. El archivo original se conserva."
		save()
		return
	if exists:
		_block_save("El guardado de Historia está dañado o pertenece a otro modo o versión. No se modificó.")


func save() -> bool:
	if save_blocked or active_id.is_empty() or data.is_empty():
		last_save_ok = false
		return false
	roster[active_id] = data
	var absolute: String = ProjectSettings.globalize_path(_save_path)
	if DirAccess.make_dir_recursive_absolute(absolute.get_base_dir()) != OK:
		last_save_ok = false
		return false
	var payload: Dictionary = {"version": SAVE_VERSION, "mode": SAVE_MODE, "active_id": active_id,
		"roster": roster, "history": history, "processed_battles": _processed_battles,
		"next_match_at": _next_match_at, "surrender_chain": _surrender_chain}
	if _decode(payload).is_empty():
		last_save_ok = false
		load_notice = "El progreso de Historia no superó la validación. El archivo anterior se conserva."
		return false
	var temporary: String = absolute + ".tmp"
	if not _write(temporary, JSON.stringify(payload, "\t")):
		last_save_ok = false
		return false
	if FileAccess.file_exists(absolute) and not _recovered_original:
		var original_payload: Dictionary = _read_payload(absolute)
		if _decode(original_payload).is_empty():
			DirAccess.remove_absolute(temporary)
			_block_save("El archivo de Historia cambió o dejó de ser válido. No se sobrescribió.")
			return false
		if int(original_payload.get("version", SAVE_VERSION)) < SAVE_VERSION:
			var original_version: int = int(original_payload.version)
			var permanent_backup: String = absolute + ".v%d.bak" % original_version
			if FileAccess.file_exists(permanent_backup):
				var preserved: Dictionary = _read_payload(permanent_backup)
				if int(preserved.get("version", 0)) != original_version or _decode(preserved).is_empty():
					DirAccess.remove_absolute(temporary)
					last_save_ok = false
					load_notice = "La copia anterior existente necesita revisión. No se reemplazó ningún guardado."
					return false
			elif DirAccess.copy_absolute(absolute, permanent_backup) != OK:
				DirAccess.remove_absolute(temporary)
				last_save_ok = false
				load_notice = "No pudimos preservar la copia anterior. La historia sigue intacta."
				return false
		var backup_temp: String = absolute + ".bak.tmp"
		if DirAccess.copy_absolute(absolute, backup_temp) != OK or DirAccess.rename_absolute(backup_temp, absolute + ".bak") != OK:
			DirAccess.remove_absolute(temporary)
			last_save_ok = false
			return false
	last_save_ok = DirAccess.rename_absolute(temporary, absolute) == OK
	if last_save_ok:
		_recovered_original = false
	return last_save_ok


func select_character(id: String, name_override: String = "") -> bool:
	if save_blocked or Catalog.definition(id).is_empty():
		return false
	if not roster.has(id):
		roster[id] = _new_profile(id, name_override)
	elif not name_override.strip_edges().is_empty():
		roster[id]["name"] = _clean_name(name_override)
	active_id = id
	data = roster[id]
	_replay_level = 0
	save()
	return true


func current_stage() -> int:
	return int(data.get("current_stage", 0))


func current_chapter() -> int:
	return int(data.get("chapter", 1))


func can_start_next_chapter() -> bool:
	return not save_blocked and is_complete() and not Story.chapter(current_chapter() + 1).is_empty()


func start_next_chapter() -> bool:
	if not can_start_next_chapter():
		return false
	var original: Dictionary = data.duplicate(true)
	var old_delay: float = _next_match_at
	var old_chain: int = _surrender_chain
	var archived: Dictionary = data.completion_snapshot.profile.duplicate(true) if data.get("completion_snapshot", {}).has("profile") else original.duplicate(true)
	archived["chapter_records"] = {}
	archived["archive_flat"] = true
	var record: Dictionary = {"profile": archived, "summary": completion_summary()}
	data.chapter_records[str(current_chapter())] = record
	data.chapter = current_chapter() + 1
	_replay_level = 0
	for key: String in ["matches", "wins", "losses", "streak", "best_streak", "surrenders", "current_stage", "retries", "completed_at"]:
		data[key] = 0
	data.defeated = []
	data.attempts = {}
	data.completed = false
	data["completion_snapshot"] = {}
	data.badge = ""
	data.last_hint = ""
	_sync_campaign(data)
	_next_match_at = 0.0
	_surrender_chain = 0
	if save():
		return true
	# The UI must not enter an unsaved chapter after an I/O failure.
	data = original
	roster[active_id] = data
	_next_match_at = old_delay
	_surrender_chain = old_chain
	last_save_ok = false
	return false


func chapter_summaries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if data.is_empty(): return result
	for number: int in range(1, current_chapter()):
		result.append(completion_summary(number))
	if is_complete(): result.append(completion_summary())
	return result


func is_complete() -> bool:
	return not data.is_empty() and bool(data.get("completed", false))


func xp_needed() -> int:
	var level: int = int(data.get("level", 1))
	return 0 if level >= Balance.MAX_LEVEL else Balance.xp_for_level(level)


func seconds_until_next_match() -> float:
	return maxf(0.0, _next_match_at - Time.get_unix_time_from_system())


func global_level() -> int:
	return clampi(int(Story.chapter(current_chapter()).start_level) + current_stage(), 1, Story.total_encounters())


func campaign_completion() -> Dictionary:
	if data.is_empty(): return {"completed": false, "defeated": 0, "total": Story.total_encounters(), "current_level": 1, "bosses_defeated": [], "next_boss": 8, "next_milestone": 5}
	var cleared: int = _cleared(data)
	var next_boss: int = 0
	for chapter: Dictionary in Story.chapters():
		if int(chapter.end_level) > cleared:
			next_boss = int(chapter.end_level)
			break
	var next_milestone: int = 0
	for level: int in range(cleared + 1, Story.total_encounters() + 1):
		if level in Campaign.MOVE_TOKEN_LEVELS or level in Campaign.PERK_LEVELS or level == next_boss:
			next_milestone = level
			break
	return {"completed": cleared == Story.total_encounters(), "defeated": cleared, "total": Story.total_encounters(),
		"current_level": global_level(), "bosses_defeated": data.bosses_defeated.duplicate(),
		"next_boss": next_boss, "next_milestone": next_milestone}


func can_replay(story_level: int) -> bool:
	return not save_blocked and not data.is_empty() and story_level >= 1 and story_level <= _cleared(data)


func select_replay(story_level: int) -> bool:
	if not can_replay(story_level): return false
	_replay_level = story_level
	return true


func clear_replay() -> void:
	_replay_level = 0


func is_replay() -> bool:
	return _replay_level > 0


func preview_opponent(story_level: int) -> Dictionary:
	if data.is_empty(): return {}
	var chapter_number: int = Story.chapter_for_level(story_level)
	if chapter_number == 0: return {}
	var index: int = story_level - int(Story.chapter(chapter_number).start_level)
	var result: Dictionary = Story.opponent(index, chapter_number, int(data.run_seed), active_id)
	result["story_replay"] = is_replay() and story_level == _replay_level
	result["story_run_seed"] = int(data.run_seed)
	return result


func active_combatant() -> Dictionary:
	if data.is_empty(): return {}
	var entry: Dictionary = Catalog.definition(active_id)
	var result: Dictionary = {}
	for key: String in ["character_id", "name", "archetype", "level", "xp", "stats", "allocations", "unlocked_moves", "move_upgrades", "perks"]:
		result[key] = data[key].duplicate(true) if data[key] is Dictionary or data[key] is Array else data[key]
	result["combat_stats"] = Story.stats_for(data)
	result["ability"] = entry.ability.duplicate(true)
	result["signature"] = entry.signature.duplicate(true)
	result["visual"] = entry.visual.duplicate(true)
	result["title"] = str(entry.role)
	result["power"] = Catalog.power(result.combat_stats)
	result["mode"] = SAVE_MODE
	result["story_character_id"] = active_id
	var selected_level: int = _replay_level if is_replay() else global_level()
	var chapter_number: int = Story.chapter_for_level(selected_level) if is_replay() else current_chapter()
	result["story_chapter_id"] = chapter_number
	result["story_stage_index"] = selected_level - int(Story.chapter(chapter_number).start_level) if is_replay() else current_stage()
	result["story_stage_id"] = "" if is_complete() and not is_replay() else str(Story.global_stage(selected_level).id)
	result["story_level"] = selected_level
	result["story_replay"] = is_replay()
	result["story_run_seed"] = int(data.run_seed)
	result["moves"] = []
	for move_id: String in data.unlocked_moves:
		result.moves.append(Moves.resolve_move(active_id, move_id, int(data.move_upgrades.get(move_id, 0)), data.perks))
	return result


func make_rival() -> Dictionary:
	if data.is_empty() or (is_complete() and not is_replay()): return {}
	return preview_opponent(_replay_level if is_replay() else global_level())


func available_perks() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if data.is_empty() or int(data.perk_points) < 1 or data.perks.size() >= Campaign.MAX_PERKS: return result
	for perk: Dictionary in Moves.perks_for(active_id):
		if not str(perk.id) in data.perks: result.append(perk)
	return result


func choose_perk(perk_id: String) -> bool:
	if save_blocked: return false
	var valid: bool = false
	for perk: Dictionary in available_perks():
		if str(perk.id) == perk_id: valid = true
	if not valid: return false
	var original: Dictionary = data.duplicate(true)
	data.perks.append(perk_id)
	data.perk_points = int(data.perk_points) - 1
	if save(): return true
	data = original
	roster[active_id] = data
	return false


func can_upgrade_move(move_id: String) -> bool:
	return not save_blocked and not data.is_empty() and move_id in data.unlocked_moves and int(data.move_points) > 0 and int(data.move_upgrades.get(move_id, 0)) < Campaign.MAX_MOVE_TIER


func upgrade_move(move_id: String) -> bool:
	if not can_upgrade_move(move_id): return false
	var original: Dictionary = data.duplicate(true)
	data.move_upgrades[move_id] = int(data.move_upgrades.get(move_id, 0)) + 1
	data.move_points = int(data.move_points) - 1
	if save(): return true
	data = original
	roster[active_id] = data
	return false


func respec_build() -> bool:
	if save_blocked or data.is_empty(): return false
	var original: Dictionary = data.duplicate(true)
	var archive: Dictionary = {"revision": int(data.get("build_revision", 0)), "chapter": current_chapter(), "story_level": global_level(),
		"allocations": data.allocations.duplicate(true), "allocation_history": data.allocation_history.duplicate(true),
		"move_upgrades": data.move_upgrades.duplicate(true), "perks": data.perks.duplicate(true)}
	var refunded: int = 0
	for key: String in data.allocations:
		refunded += int(data.allocations[key])
		data.allocations[key] = 0
	data.points = int(data.points) + refunded
	data.allocation_history = []
	for move_id: String in data.move_upgrades: data.move_points = int(data.move_points) + int(data.move_upgrades[move_id])
	data.move_upgrades = {}
	data.perk_points = int(data.perk_points) + data.perks.size()
	data.perks = []
	data["build_revision"] = int(data.get("build_revision", 0)) + 1
	if not data.has("build_history"): data["build_history"] = []
	data.build_history.append(archive)
	while data.build_history.size() > 20: data.build_history.pop_front()
	if save(): return true
	data = original
	roster[active_id] = data
	return false


func upgrade(key: String) -> bool:
	if save_blocked or data.is_empty() or int(data.points) < 1:
		return false
	var option: Dictionary = _allocation_definition(key)
	if option.is_empty() or int(data.allocations.get(key, 0)) >= int(Story.CONFIG.allocation_cap):
		return false
	var before: Dictionary = Story.stats_for(data)
	var candidate: Dictionary = data.duplicate(true)
	candidate.allocations[key] = int(candidate.allocations.get(key, 0)) + 1
	var after: Dictionary = Story.stats_for(candidate)
	if not after.has(key) or float(after[key]) <= float(before[key]) + 0.0000001:
		return false
	data.allocations[key] = int(data.allocations.get(key, 0)) + 1
	data.points = int(data.points) - 1
	data.allocation_history.append({"key": key, "name": str(option.name), "stage": current_stage(), "chapter": current_chapter(),
		"level": int(data.level), "increment": float(after[key]) - float(before[key]),
		"value_after": float(after[key]), "allocation_count": int(data.allocations[key])})
	save()
	return true


func reward_match(summary: Dictionary) -> Dictionary:
	var result: Dictionary = _empty_reward()
	var battle_id: String = str(summary.get("battle_id", ""))
	if _processed_battles.has(battle_id):
		result["duplicate"] = true
		return result
	if not _valid_result(summary):
		result["error"] = "El resultado no corresponde al personaje y encuentro actuales de Historia."
		return result
	if is_replay(): return _reward_replay(summary)
	var index: int = current_stage()
	var story_level: int = global_level()
	var previous_moves: Array = data.unlocked_moves.duplicate()
	var previous_move_budget: int = _move_budget(data)
	var stage: Dictionary = Story.stage(index, current_chapter())
	var stage_id: String = str(stage.id)
	var won: bool = str(summary.winner) == "player"
	var reason: String = str(summary.reason)
	var surrendered: bool = not won and reason == "surrender"
	var duration: float = clampf(float(summary.duration), 0.0, float(Balance.COMBAT.max_duration))
	var xp: int = int(stage.xp_win) if won else int(stage.xp_loss)
	if not won and not surrendered:
		var repeat_count: int = int(data.attempts.get(stage_id, 0))
		xp = maxi(1, floori(float(xp) * maxf(Campaign.LOSS_XP_FLOOR, 1.0 - float(repeat_count) * Campaign.LOSS_XP_DECAY) * minf(1.0, maxf(0.15, duration / 8.0))))
	_surrender_chain = _surrender_chain + 1 if surrendered else 0
	if surrendered:
		var duration_factor: float = maxf(float(Balance.XP.short_match_floor), minf(1.0, duration / float(Balance.XP.short_match_seconds)))
		var repetition_factor: float = maxf(float(Balance.XP.repeat_surrender_floor), pow(float(Balance.XP.repeat_surrender_decay), float(_surrender_chain - 1)))
		xp = clampi(floori(float(Story.CONFIG.surrender_xp) * duration_factor * repetition_factor), 1, int(Story.CONFIG.surrender_xp))
	_next_match_at = Time.get_unix_time_from_system() + float(Story.CONFIG.surrender_cooldown) if surrendered else 0.0
	var player_reward: Dictionary = _grant_xp(xp)
	var previous_attempts: int = int(data.attempts.get(stage_id, 0))
	data.attempts[stage_id] = previous_attempts + 1
	data.retries = int(data.retries) + (1 if previous_attempts > 0 else 0)
	data.matches = int(data.matches) + 1
	data.streak = int(data.streak) + 1 if won else 0
	data.best_streak = maxi(int(data.best_streak), int(data.streak))
	var milestone: int = 0
	if won:
		data.wins = int(data.wins) + 1
		data.defeated.append(stage_id)
		data.current_stage = index + 1
		data.last_hint = ""
		if str(stage.kind) == "elite":
			milestone = Campaign.elite_points(story_level)
			data.points = int(data.points) + milestone
		if current_stage() == Story.stages(current_chapter()).size():
			data.completed = true
			data.badge = str(Story.chapter(current_chapter()).badge)
			data.completed_at = int(Time.get_unix_time_from_system())
	else:
		data.losses = int(data.losses) + 1
		if surrendered:
			data.surrenders = int(data.surrenders) + 1
		data.last_hint = "Puedes volver a prepararte y retomar este encuentro." if surrendered else Story.defeat_hint(summary)
	var move_points_gained: int = _move_budget(data) - previous_move_budget if won else 0
	var perk_points_gained: int = 1 if won and story_level in Campaign.PERK_LEVELS else 0
	data.move_points = int(data.move_points) + move_points_gained
	data.perk_points = int(data.perk_points) + perk_points_gained
	_sync_campaign(data)
	if bool(data.completed): _capture_completion(data, active_id)
	var unlocked: Array[Dictionary] = []
	for move: Dictionary in Moves.unlocked_moves(active_id, int(data.level)):
		if not str(move.id) in previous_moves: unlocked.append(move)
	player_reward["moves_unlocked"] = unlocked
	player_reward["move_points_gained"] = move_points_gained
	player_reward["perk_points_gained"] = perk_points_gained
	player_reward["replay"] = false
	player_reward["points_gained"] = int(player_reward.points_gained) + milestone
	player_reward["milestone_points"] = milestone
	var rival_reward: Dictionary = _static_opponent_reward(summary.rival)
	_processed_battles[battle_id] = true
	var history_entry: Dictionary = {
		"battle_id": battle_id, "timestamp": int(Time.get_unix_time_from_system()), "mode": SAVE_MODE,
		"story_character_id": active_id, "story_chapter_id": current_chapter(), "story_stage_id": stage_id, "story_stage_index": index, "story_level": story_level, "replay": false,
		"stage_title": str(stage.title), "winner": str(summary.winner), "loser": "rival" if won else "player",
		"reason": reason, "duration": duration, "turns": int(summary.get("turns", 0)),
		"player_name": str(data.name), "rival_name": str(summary.rival.name),
		"winner_name": str(data.name) if won else str(summary.rival.name),
		"loser_name": str(summary.rival.name) if won else str(data.name),
		"player_xp": xp, "rival_xp": 0, "player": player_reward.duplicate(true), "rival": rival_reward.duplicate(true),
		"advanced": won, "completed": is_complete(), "hint": str(data.last_hint),
		"metrics": summary.get("metrics", {}).duplicate(true),
	}
	BattleIdentity.attach(history_entry, summary)
	history.append(history_entry)
	while history.size() > int(Story.CONFIG.history_limit):
		history.pop_front()
	save()
	result = player_reward.duplicate(true)
	result["player"] = player_reward
	result["rival"] = rival_reward
	result["duplicate"] = false
	result["accepted"] = true
	result["history_entry"] = history_entry
	result["story_stage"] = stage.duplicate(true)
	result["story_chapter"] = current_chapter()
	result["advanced"] = won
	result["completed"] = is_complete()
	result["hint"] = str(data.last_hint)
	result["badge"] = str(data.badge)
	result["next_match_delay"] = seconds_until_next_match()
	result["campaign_completed"] = bool(data.campaign_completed)
	return result


func _reward_replay(summary: Dictionary) -> Dictionary:
	var before: Dictionary = _grant_xp(0)
	before["replay"] = true
	before["moves_unlocked"] = []
	before["move_points_gained"] = 0
	before["perk_points_gained"] = 0
	var rival_reward: Dictionary = _static_opponent_reward(summary.rival)
	var won: bool = str(summary.winner) == "player"
	data.replay_matches = int(data.replay_matches) + 1
	data.replay_wins = int(data.replay_wins) + (1 if won else 0)
	data.replay_losses = int(data.replay_losses) + (0 if won else 1)
	_processed_battles[str(summary.battle_id)] = true
	var encounter: Dictionary = Story.global_stage(_replay_level)
	var record: Dictionary = {"battle_id": str(summary.battle_id), "timestamp": int(Time.get_unix_time_from_system()), "mode": SAVE_MODE,
		"story_character_id": active_id, "story_chapter_id": int(encounter.chapter), "story_stage_index": _replay_level - int(Story.chapter(int(encounter.chapter)).start_level),
		"story_stage_id": str(encounter.id), "story_level": _replay_level, "stage_title": str(encounter.title), "winner": str(summary.winner),
		"loser": "rival" if won else "player", "reason": str(summary.reason), "duration": float(summary.duration), "turns": int(summary.get("turns", 0)),
		"player_name": str(data.name), "rival_name": str(summary.rival.name), "winner_name": str(data.name) if won else str(summary.rival.name),
		"loser_name": str(summary.rival.name) if won else str(data.name), "player_xp": 0, "rival_xp": 0, "player": before.duplicate(true), "rival": rival_reward,
		"advanced": false, "completed": is_complete(), "replay": true, "hint": "Práctica: sin XP ni recompensas adicionales.", "metrics": summary.get("metrics", {}).duplicate(true)}
	BattleIdentity.attach(record, summary)
	history.append(record)
	while history.size() > int(Story.CONFIG.history_limit): history.pop_front()
	if str(summary.reason) == "surrender": _next_match_at = Time.get_unix_time_from_system() + float(Story.CONFIG.surrender_cooldown)
	save()
	var result: Dictionary = before.duplicate(true)
	result.merge({"player": before, "rival": rival_reward, "accepted": true, "duplicate": false, "advanced": false, "completed": is_complete(), "campaign_completed": bool(data.campaign_completed), "hint": record.hint,
		"history_entry": record, "story_stage": encounter, "story_chapter": int(encounter.chapter), "badge": str(data.badge), "next_match_delay": seconds_until_next_match()}, true)
	return result


func completion_summary(chapter_number: int = 0) -> Dictionary:
	if data.is_empty(): return {}
	var number: int = current_chapter() if chapter_number == 0 else chapter_number
	if number == current_chapter():
		if is_complete() and data.get("completion_snapshot", {}).has("summary"): return data.completion_snapshot.summary.duplicate(true)
		return _summary_for(data, active_id)
	var records: Dictionary = data.get("chapter_records", {})
	return records[str(number)].summary.duplicate(true) if records.has(str(number)) else {}


static func _summary_for(data: Dictionary, active_id: String) -> Dictionary:
	if data.is_empty():
		return {}
	var base_profile: Dictionary = _new_profile(active_id)
	var base: Dictionary = Story.stats_for(base_profile)
	var final_stats: Dictionary = Story.stats_for(data)
	var major: Array[Dictionary] = []
	for option: Dictionary in Story.allocations():
		var count: int = int(data.allocations.get(option.key, 0))
		if count > 0:
			major.append({"key": str(option.key), "name": str(option.name), "points": count,
				"before": float(base[option.key]), "after": float(final_stats[option.key]),
				"gain": float(final_stats[option.key]) - float(base[option.key])})
	major.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.points) > int(b.points))
	return {"completed": bool(data.completed), "name": str(data.name), "character_id": active_id,
		"level": int(data.level), "final_level": int(data.level), "stats": final_stats,
		"final_stats": final_stats.duplicate(true), "base_stats": base,
		"stat_gains": _stat_difference(base, final_stats), "major_changes": major,
		"battles": int(data.matches), "defeats": int(data.losses), "retries": int(data.retries),
		"wins": int(data.wins), "defeated": data.defeated.duplicate(true), "badge": str(data.badge),
		"allocations": data.allocations.duplicate(true), "allocation_history": data.allocation_history.duplicate(true),
		"unspent_points": int(data.points), "total_xp": int(data.total_xp),
		"chapter": int(data.get("chapter", 1)), "chapter_title": Story.chapter(int(data.get("chapter", 1))).title,
		"completed_at": int(data.completed_at), "total_stages": Story.stages(int(data.get("chapter", 1))).size(), "clearance": "%d / %d" % [data.defeated.size(), Story.stages(int(data.get("chapter", 1))).size()]}


func _valid_result(summary: Dictionary) -> bool:
	if save_blocked or data.is_empty() or (is_complete() and not is_replay()) or not summary.get("battle_id") is String: return false
	if str(summary.battle_id).is_empty() or str(summary.battle_id).length() > 200: return false
	if not str(summary.get("winner", "")) in ["player", "rival"] or not str(summary.get("reason", "")) in ["normal", "timeout", "dot", "surrender"]: return false
	if not _number(summary.get("duration")) or float(summary.duration) < 0.0: return false
	if not summary.get("player") is Dictionary or not summary.get("rival") is Dictionary or not summary.get("metrics", {}) is Dictionary: return false
	var selected_level: int = _replay_level if is_replay() else global_level()
	var encounter: Dictionary = Story.global_stage(selected_level)
	var number: int = int(encounter.chapter)
	var index: int = selected_level - int(Story.chapter(number).start_level)
	for side: String in ["player", "rival"]:
		var descriptor: Dictionary = summary[side]
		if str(descriptor.get("mode", "")) != SAVE_MODE or not _whole(descriptor.get("story_stage_index"), index, index): return false
		if not _whole(descriptor.get("story_chapter_id"), number, number): return false
		if str(descriptor.get("story_stage_id", "")) != str(encounter.id): return false
		if bool(descriptor.get("story_replay", false)) != is_replay(): return false
		if not _whole(descriptor.get("story_level", selected_level), selected_level, selected_level): return false
		if not _whole(descriptor.get("story_run_seed", data.run_seed), int(data.run_seed), int(data.run_seed)): return false
	if str(summary.player.get("character_id", "")) != active_id or str(summary.player.get("story_character_id", "")) != active_id: return false
	var expected: Dictionary = preview_opponent(selected_level)
	return str(summary.rival.get("character_id", "")) == str(expected.character_id) and summary.rival.get("name") is String


func _grant_xp(amount: int) -> Dictionary:
	var before: Dictionary = Story.stats_for(data)
	var old_level: int = int(data.level)
	var old_xp: int = int(data.xp)
	var level_ups: Array[Dictionary] = []
	var earned_points: int = 0
	data.total_xp = int(data.total_xp) + amount
	data.xp = int(data.xp) + amount
	while int(data.level) < Balance.MAX_LEVEL and int(data.xp) >= Balance.xp_for_level(int(data.level)):
		var old_stats: Dictionary = Story.stats_for(data)
		data.xp = int(data.xp) - Balance.xp_for_level(int(data.level))
		data.level = int(data.level) + 1
		var grant: int = Story.points_for_level(int(data.level))
		data.points = int(data.points) + grant
		earned_points += grant
		level_ups.append({"level": int(data.level), "stat_gains": _stat_difference(old_stats, Story.stats_for(data))})
	if int(data.level) >= Balance.MAX_LEVEL:
		data.cap_xp = int(data.cap_xp) + int(data.xp)
		data.xp = 0
	data["unlocked_moves"] = _unlocked_ids(active_id, int(data.level))
	return {"xp_gained": amount, "levels_gained": int(data.level) - old_level,
		"points_gained": earned_points,
		"level_before": old_level, "level_after": int(data.level), "xp_before": old_xp,
		"xp_after": int(data.xp), "xp_required": xp_needed(), "stat_gains": _stat_difference(before, Story.stats_for(data)),
		"level_ups": level_ups, "at_max_level": int(data.level) >= Balance.MAX_LEVEL, "total_xp": int(data.total_xp)}


static func _static_opponent_reward(opponent: Dictionary) -> Dictionary:
	return {"xp_gained": 0, "levels_gained": 0, "points_gained": 0, "level_before": int(opponent.level),
		"level_after": int(opponent.level), "xp_before": 0, "xp_after": 0, "xp_required": 0,
		"stat_gains": {}, "level_ups": [], "at_max_level": false, "total_xp": 0, "static_opponent": true}


static func _empty_reward() -> Dictionary:
	return {"xp_gained": 0, "levels_gained": 0, "points_gained": 0, "player": {}, "rival": {},
		"duplicate": false, "accepted": false, "advanced": false, "completed": false, "hint": ""}


static func _new_profile(id: String, name_override: String = "") -> Dictionary:
	var entry: Dictionary = Catalog.definition(id)
	var allocations: Dictionary = {}
	for option: Dictionary in Story.allocations():
		allocations[str(option.key)] = 0
	var profile: Dictionary = {"character_id": id, "name": str(entry.name) if name_override.strip_edges().is_empty() else _clean_name(name_override),
		"archetype": int(entry.archetype), "level": 1, "xp": 0, "points": int(Story.CONFIG.initial_points),
		"stats": entry.training_base.duplicate(true), "allocations": allocations, "allocation_history": [],
		"matches": 0, "wins": 0, "losses": 0, "streak": 0, "best_streak": 0, "surrenders": 0,
		"total_xp": 0, "cap_xp": 0, "chapter": 1, "chapter_records": {}, "defeated": [], "current_stage": 0, "attempts": {},
		"retries": 0, "completed": false, "badge": "", "completed_at": 0, "last_hint": ""}
	_migrate_campaign(profile, id)
	profile.run_seed = int((str(Time.get_ticks_usec()) + id).hash() % 2147483646) + 1
	return profile


static func _allocation_definition(key: String) -> Dictionary:
	for option: Dictionary in Story.allocations():
		if str(option.key) == key:
			return option
	return {}


static func _stat_difference(before: Dictionary, after: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: String in Balance.STAT_KEYS:
		var change: float = float(after[key]) - float(before[key])
		if absf(change) > 0.0000001:
			result[key] = change
	return result


func _apply_decoded(payload: Dictionary) -> void:
	roster = payload.roster
	active_id = str(payload.active_id)
	data = roster[active_id]
	history.assign(payload.history)
	_processed_battles = payload.processed_battles
	_next_match_at = float(payload.next_match_at)
	_surrender_chain = int(payload.surrender_chain)


static func _decode(payload: Dictionary) -> Dictionary:
	if not _whole(payload.get("version"), 1, SAVE_VERSION) or str(payload.get("mode", "")) != SAVE_MODE:
		return {}
	if not payload.get("active_id") is String or not payload.get("roster") is Dictionary or not payload.get("history", []) is Array:
		return {}
	var profiles: Dictionary = {}
	for id: Variant in payload.roster:
		if not id is String or not payload.roster[id] is Dictionary or Catalog.definition(str(id)).is_empty():
			return {}
		var raw: Dictionary = payload.roster[id].duplicate(true)
		if int(payload.version) == 1:
			# V1 always meant the original eight encounters, even after content expands.
			if raw.has("chapter") and not _whole(raw.chapter, 1, 1): return {}
			if raw.has("chapter_records") and (not raw.chapter_records is Dictionary or not raw.chapter_records.is_empty()): return {}
			raw["chapter"] = 1
			raw["chapter_records"] = {}
		if int(payload.version) == 2 and not _whole(raw.get("chapter"), 1, 2): return {}
		if not _whole(raw.get("chapter"), 1, Story.chapters().size()): return {}
		if not _whole(raw.get("current_stage"), 0, Story.stages(int(raw.chapter)).size()): return {}
		if not _whole(raw.get("level"), 1, Balance.MAX_LEVEL) or not _whole(raw.get("total_xp"), 0, 2000000000): return {}
		if str(raw.get("character_id", "")) != str(id) or not raw.get("completed") is bool: return {}
		if int(payload.version) < 3: _migrate_campaign(raw, str(id))
		if not raw.has("build_revision"): raw["build_revision"] = 0
		if not raw.has("build_history"): raw["build_history"] = []
		if not raw.has("stat_policy_version"): _migrate_stat_policy(raw)
		if not raw.has("move_token_floor"):
			var spent_moves: int = int(raw.get("move_points", 0))
			for tier: Variant in raw.get("move_upgrades", {}).values(): spent_moves += int(tier)
			raw["move_token_floor"] = clampi(spent_moves, 0, 10)
		if not raw.has("completion_snapshot"):
			raw["completion_snapshot"] = {}
		var profile: Dictionary = _validate_profile(raw, str(id), 1 if int(payload.version) == 1 else 2 if int(payload.version) == 2 else Story.chapters().size())
		if profile.is_empty():
			return {}
		profiles[id] = profile
	if not profiles.has(str(payload.active_id)):
		return {}
	if not payload.get("processed_battles", {}) is Dictionary or not _number(payload.get("next_match_at", 0.0)) or not _whole(payload.get("surrender_chain", 0), 0, 10000000):
		return {}
	var processed: Dictionary = payload.get("processed_battles", {}).duplicate(true)
	for id: Variant in processed:
		if not id is String or str(id).is_empty():
			return {}
	var logs: Array[Dictionary] = []
	for entry: Variant in payload.get("history", []):
		if not entry is Dictionary or not entry.get("battle_id") is String or not str(entry.get("winner", "")) in ["player", "rival"]:
			return {}
		var hero: String = str(entry.get("story_character_id", ""))
		if not profiles.has(hero): return {}
		var number: Variant = 1 if int(payload.version) == 1 else entry.get("story_chapter_id")
		if not _whole(number, 1, int(profiles[hero].chapter)): return {}
		if not _whole(entry.get("story_stage_index"), 0, Story.stages(int(number)).size() - 1):
			return {}
		if str(entry.get("story_stage_id", "")) != str(Story.stage(int(entry.story_stage_index), int(number)).id):
			return {}
		var normalized: Dictionary = entry.duplicate(true)
		normalized["story_chapter_id"] = int(number)
		logs.append(normalized)
		processed[str(entry.battle_id)] = true
	while logs.size() > int(Story.CONFIG.history_limit):
		logs.pop_front()
	return {"active_id": str(payload.active_id), "roster": profiles, "history": logs,
		"processed_battles": processed, "surrender_chain": int(payload.get("surrender_chain", 0)),
		"next_match_at": clampf(float(payload.get("next_match_at", 0.0)), 0.0, Time.get_unix_time_from_system() + float(Story.CONFIG.surrender_cooldown))}


static func _validate_profile(raw: Dictionary, id: String, highest_chapter: int = 11) -> Dictionary:
	if not _whole(raw.get("chapter"), 1, highest_chapter) or not raw.get("chapter_records") is Dictionary: return {}
	var number: int = int(raw.chapter)
	if raw.chapter_records.size() != number - 1: return {}
	var records: Dictionary = {}
	for previous: int in range(1, number):
		var key: String = str(previous)
		if not raw.chapter_records.get(key) is Dictionary: return {}
		var record: Dictionary = raw.chapter_records[key]
		if not record.get("profile") is Dictionary or not record.get("summary") is Dictionary: return {}
		if not _whole(record.profile.get("chapter"), previous, previous): return {}
		if not record.profile.get("chapter_records") is Dictionary: return {}
		if bool(record.profile.get("archive_flat", false)):
			if not record.profile.chapter_records.is_empty(): return {}
		else:
			if record.profile.chapter_records.size() != previous - 1: return {}
			for older: String in records:
				if not record.profile.chapter_records.has(older) or not _equivalent(record.profile.chapter_records[older], records[older]): return {}
		var archived: Dictionary = _validate_core(record.profile, id, records, true)
		if archived.is_empty() or not bool(archived.completed): return {}
		var expected_summary: Dictionary = _summary_for(archived, id)
		if not _equivalent(record.summary, expected_summary): return {}
		records[key] = {"profile": archived, "summary": record.summary.duplicate(true)}
	return _validate_core(raw, id, records, false)


static func _validate_core(raw: Dictionary, id: String, records: Dictionary, archive: bool) -> Dictionary:
	var entry: Dictionary = Catalog.definition(id)
	var number: int = int(raw.chapter)
	var route: Array[Dictionary] = Story.stages(number)
	if route.is_empty(): return {}
	var modern_policy: bool = int(raw.get("stat_policy_version", 1)) == 2
	var archived_elite_points: int = 0
	for previous: int in range(1, number):
		for encounter: Dictionary in Story.stages(previous):
			if encounter.kind == "elite": archived_elite_points += Campaign.elite_points(int(encounter.global_level)) if modern_policy else int(Story.CONFIG.elite_points)
	if str(raw.get("character_id", "")) != id or not raw.get("name") is String or not raw.get("stats") is Dictionary:
		return {}
	for key: String in LEGACY_KEYS:
		if not _whole(raw.stats.get(key), int(entry.training_base[key]), int(entry.training_base[key])):
			return {}
	for key: String in ["level", "xp", "points", "matches", "wins", "losses", "streak", "best_streak", "surrenders", "total_xp", "cap_xp", "current_stage", "retries", "completed_at"]:
		if not _whole(raw.get(key), 0, 2000000000):
			return {}
	if int(raw.level) < 1 or int(raw.level) > Balance.MAX_LEVEL or int(raw.current_stage) > route.size():
		return {}
	if not raw.get("defeated") is Array or not raw.get("attempts") is Dictionary or not raw.get("allocations") is Dictionary or not raw.get("allocation_history") is Array:
		return {}
	if not raw.get("completed") is bool or not raw.get("badge") is String or not raw.get("last_hint") is String:
		return {}
	var stage_index: int = int(raw.current_stage)
	var completed: bool = stage_index == route.size()
	if raw.defeated.size() != stage_index or int(raw.wins) != stage_index or bool(raw.completed) != completed:
		return {}
	if str(raw.badge) != (str(Story.chapter(number).badge) if completed else ""):
		return {}
	var elite_points: int = archived_elite_points
	for index in range(stage_index):
		var stage: Dictionary = Story.stage(index, number)
		if str(raw.defeated[index]) != str(stage.id):
			return {}
		if str(stage.kind) == "elite":
			elite_points += Campaign.elite_points(int(stage.global_level)) if modern_policy else int(Story.CONFIG.elite_points)
	var attempts: Dictionary = {}
	var total_attempts: int = 0
	var eligible_ids: Array[String] = []
	for index in range(mini(stage_index + 1, route.size())):
		eligible_ids.append(str(Story.stage(index, number).id))
	for stage_id: Variant in raw.attempts:
		if not stage_id is String or not str(stage_id) in eligible_ids or not _whole(raw.attempts[stage_id], 1, 10000000):
			return {}
		attempts[stage_id] = int(raw.attempts[stage_id])
		total_attempts += int(raw.attempts[stage_id])
	for stage_id: Variant in raw.defeated:
		if not attempts.has(str(stage_id)):
			return {}
	if total_attempts != int(raw.matches) or int(raw.wins) + int(raw.losses) != int(raw.matches) or int(raw.retries) != total_attempts - attempts.size():
		return {}
	if int(raw.streak) > int(raw.wins) or int(raw.best_streak) < int(raw.streak) or int(raw.best_streak) > int(raw.wins) or int(raw.surrenders) > int(raw.losses):
		return {}
	var allocations: Dictionary = {}
	var spent: int = 0
	for option: Dictionary in Story.allocations():
		var key: String = str(option.key)
		if not _whole(raw.allocations.get(key), 0, int(Story.CONFIG.allocation_cap)):
			return {}
		allocations[key] = int(raw.allocations[key])
		spent += int(raw.allocations[key])
	if raw.allocations.size() != allocations.size():
		return {}
	var level: int = int(raw.level)
	var xp: int = int(raw.xp)
	var points: int = int(raw.points)
	while level < Balance.MAX_LEVEL and xp >= Balance.xp_for_level(level):
		xp -= Balance.xp_for_level(level)
		level += 1
		points += Story.points_for_level(level) if modern_policy else int(Story.CONFIG.points_per_level)
	var budget: int = int(Story.CONFIG.initial_points) + (_stat_points_before_level(level) + int(raw.get("legacy_stat_credit", 0)) if modern_policy else (level - 1) * int(Story.CONFIG.points_per_level)) + elite_points
	if spent + points != budget:
		return {}
	var allocation_history: Array[Dictionary] = []
	var history_counts: Dictionary = {}
	for action: Variant in raw.allocation_history:
		if not action is Dictionary or not allocations.has(str(action.get("key", ""))):
			return {}
		var key: String = str(action.key)
		history_counts[key] = int(history_counts.get(key, 0)) + 1
		allocation_history.append(action.duplicate(true))
	for key: String in allocations:
		if int(history_counts.get(key, 0)) != int(allocations[key]):
			return {}
	var profile: Dictionary = raw.duplicate(true)
	profile["chapter"] = number
	profile["chapter_records"] = raw.chapter_records.duplicate(true) if archive else records
	for key: String in ["matches", "wins", "losses", "streak", "best_streak", "surrenders", "retries", "completed_at"]:
		profile[key] = int(raw[key])
	profile["name"] = _clean_name(str(raw.name))
	profile["archetype"] = int(entry.archetype)
	profile["stats"] = entry.training_base.duplicate(true)
	profile["level"] = level
	profile["xp"] = 0 if level >= Balance.MAX_LEVEL else xp
	profile["points"] = points
	profile["allocations"] = allocations
	profile["allocation_history"] = allocation_history
	profile["current_stage"] = stage_index
	profile["attempts"] = attempts
	profile["total_xp"] = maxi(int(raw.total_xp), _xp_before_level(int(raw.level)) + int(raw.xp))
	profile["cap_xp"] = maxi(int(raw.cap_xp), maxi(0, int(profile.total_xp) - _xp_before_level(Balance.MAX_LEVEL))) if level >= Balance.MAX_LEVEL else 0
	if number > 1:
		var prior: Dictionary = records[str(number - 1)].profile
		if int(profile.level) < int(prior.level) or int(profile.total_xp) < int(prior.total_xp): return {}
		var revision: int = int(profile.get("build_revision", 0))
		var prior_revision: int = int(prior.get("build_revision", 0))
		if revision < prior_revision: return {}
		if prior.has("run_seed") and int(profile.get("run_seed", 0)) != int(prior.run_seed): return {}
		if revision == prior_revision:
			for key: String in allocations:
				if int(allocations[key]) < int(prior.allocations[key]): return {}
			if allocation_history.size() < prior.allocation_history.size(): return {}
			for index: int in range(prior.allocation_history.size()):
				if not _equivalent(allocation_history[index], prior.allocation_history[index]): return {}
			for move_id: String in prior.get("move_upgrades", {}):
				if int(profile.get("move_upgrades", {}).get(move_id, 0)) < int(prior.move_upgrades[move_id]): return {}
			for perk_id: String in prior.get("perks", []):
				if not perk_id in profile.get("perks", []): return {}
	if not archive or raw.has("unlocked_moves"):
		if not _valid_campaign(profile, id): return {}
	if not archive:
		if not raw.get("completion_snapshot") is Dictionary: return {}
		if completed:
			var frozen: Dictionary = raw.completion_snapshot
			if frozen.is_empty():
				_capture_completion(profile, id)
				frozen = profile.completion_snapshot
			if not frozen.get("profile") is Dictionary or not frozen.get("summary") is Dictionary: return {}
			if not _whole(frozen.profile.get("chapter"), number, number) or not bool(frozen.profile.get("completed", false)): return {}
			if not frozen.profile.get("chapter_records") is Dictionary or not frozen.profile.chapter_records.is_empty(): return {}
			if frozen.profile.has("completion_snapshot"): return {}
			var winning: Dictionary = _validate_core(frozen.profile, id, records, true)
			if winning.is_empty() or not _equivalent(frozen.summary, _summary_for(winning, id)): return {}
			for key: String in ["level", "xp", "total_xp", "matches", "wins", "losses", "completed_at", "current_stage"]:
				if int(winning[key]) != int(profile[key]): return {}
			if int(profile.get("build_revision", 0)) < int(winning.get("build_revision", 0)): return {}
		elif not raw.completion_snapshot.is_empty(): return {}
	return profile


static func _cleared(profile: Dictionary) -> int:
	return int(Story.chapter(int(profile.get("chapter", 1))).start_level) - 1 + int(profile.get("current_stage", 0))


static func _unlocked_ids(id: String, level: int) -> Array[String]:
	var result: Array[String] = []
	for move: Dictionary in Moves.unlocked_moves(id, level): result.append(str(move.id))
	return result


static func _bosses_for(cleared: int) -> Array[String]:
	var result: Array[String] = []
	for chapter: Dictionary in Story.chapters():
		if int(chapter.end_level) <= cleared: result.append(str(Story.global_stage(int(chapter.end_level)).id))
	return result


static func _sync_campaign(profile: Dictionary) -> void:
	var cleared: int = _cleared(profile)
	profile["global_story_level"] = mini(Story.total_encounters(), cleared + 1)
	profile["campaign_completed"] = cleared == Story.total_encounters()
	profile["bosses_defeated"] = _bosses_for(cleared)
	profile["unlocked_moves"] = _unlocked_ids(str(profile.character_id), int(profile.level))


static func _migrate_campaign(profile: Dictionary, id: String) -> void:
	var cleared: int = _cleared(profile)
	profile["run_seed"] = int((id + ":" + str(profile.get("total_xp", 0)) + ":" + str(profile.get("completed_at", 0))).hash() % 2147483646) + 1
	profile["move_upgrades"] = {}
	profile["perks"] = []
	profile["move_points"] = Campaign.earned_tokens(cleared, Campaign.MOVE_TOKEN_LEVELS)
	profile["perk_points"] = Campaign.earned_tokens(cleared, Campaign.PERK_LEVELS)
	profile["replay_matches"] = 0
	profile["replay_wins"] = 0
	profile["replay_losses"] = 0
	profile["build_revision"] = 0
	profile["build_history"] = []
	profile["completion_snapshot"] = {}
	profile["move_token_floor"] = 0
	_migrate_stat_policy(profile)
	_sync_campaign(profile)


static func _capture_completion(profile: Dictionary, id: String) -> void:
	if not profile.get("completion_snapshot", {}).is_empty(): return
	var winning: Dictionary = profile.duplicate(true)
	winning.erase("completion_snapshot")
	winning["chapter_records"] = {}
	winning["archive_flat"] = true
	profile["completion_snapshot"] = {"profile": winning, "summary": _summary_for(winning, id)}


static func _stat_points_before_level(hero_level: int) -> int:
	var result: int = 0
	for level: int in range(2, hero_level + 1): result += Story.points_for_level(level)
	return result


static func _maximum_legacy_credit(profile: Dictionary) -> int:
	var credit: int = (int(profile.level) - 1) * int(Story.CONFIG.points_per_level) - _stat_points_before_level(int(profile.level))
	for level: int in range(17, _cleared(profile) + 1):
		if Story.global_stage(level).kind == "elite": credit += int(Story.CONFIG.elite_points)
	return maxi(0, credit)


static func _migrate_stat_policy(profile: Dictionary) -> void:
	profile["legacy_stat_credit"] = _maximum_legacy_credit(profile)
	profile["stat_policy_version"] = 2


static func _move_budget(profile: Dictionary) -> int:
	if not profile.has("move_token_floor"): return mini(10, floori(float(_cleared(profile)) / 5.0))
	return maxi(Campaign.earned_tokens(_cleared(profile), Campaign.MOVE_TOKEN_LEVELS), int(profile.get("move_token_floor", 0)))


static func _valid_campaign(profile: Dictionary, id: String) -> bool:
	var cleared: int = _cleared(profile)
	if profile.has("stat_policy_version") and not _whole(profile.stat_policy_version, 2, 2): return false
	if not _whole(profile.get("legacy_stat_credit", 0), 0, _maximum_legacy_credit(profile)): return false
	if not _whole(profile.get("build_revision", 0), 0, 2000000000) or not profile.get("build_history", []) is Array: return false
	var revision: int = int(profile.get("build_revision", 0))
	var ledger: Array = profile.get("build_history", [])
	if ledger.size() != mini(20, revision): return false
	for index: int in range(ledger.size()):
		var action: Variant = ledger[index]
		if not action is Dictionary or not _whole(action.get("revision"), revision - ledger.size() + index, revision - ledger.size() + index): return false
		if not action.get("allocations") is Dictionary or not action.get("allocation_history") is Array or not action.get("move_upgrades") is Dictionary or not action.get("perks") is Array: return false
	if not _whole(profile.get("run_seed"), 1, 2147483647): return false
	if not _equivalent(profile.get("unlocked_moves"), _unlocked_ids(id, int(profile.level))): return false
	if not profile.get("move_upgrades") is Dictionary or not profile.get("perks") is Array: return false
	if not _whole(profile.get("move_points"), 0, Campaign.MOVE_TOKEN_LEVELS.size()) or not _whole(profile.get("perk_points"), 0, Campaign.MAX_PERKS): return false
	var spent: int = 0
	for move_id: Variant in profile.move_upgrades:
		if not move_id is String or not move_id in profile.unlocked_moves or not _whole(profile.move_upgrades[move_id], 0, Campaign.MAX_MOVE_TIER): return false
		spent += int(profile.move_upgrades[move_id])
	if not _whole(profile.get("move_token_floor", 0), 0, mini(10, floori(float(cleared) / 5.0))): return false
	if spent + int(profile.move_points) != _move_budget(profile): return false
	var allowed: Array[String] = []
	for perk: Dictionary in Moves.perks_for(id): allowed.append(str(perk.id))
	var chosen: Array[String] = []
	for perk_id: Variant in profile.perks:
		if not perk_id is String or not perk_id in allowed or perk_id in chosen: return false
		chosen.append(str(perk_id))
	if chosen.size() > Campaign.MAX_PERKS or chosen.size() + int(profile.perk_points) != Campaign.earned_tokens(cleared, Campaign.PERK_LEVELS): return false
	if not _whole(profile.get("global_story_level"), mini(100, cleared + 1), mini(100, cleared + 1)): return false
	if not profile.get("campaign_completed") is bool or bool(profile.campaign_completed) != (cleared == Story.total_encounters()): return false
	if not _equivalent(profile.get("bosses_defeated"), _bosses_for(cleared)): return false
	for key: String in ["replay_matches", "replay_wins", "replay_losses"]:
		if not _whole(profile.get(key), 0, 2000000000): return false
	return int(profile.replay_matches) == int(profile.replay_wins) + int(profile.replay_losses)


static func _equivalent(left: Variant, right: Variant) -> bool:
	if _number(left) and _number(right): return is_equal_approx(float(left), float(right))
	if left is Dictionary and right is Dictionary:
		if left.size() != right.size(): return false
		for key: Variant in left:
			if not right.has(key) or not _equivalent(left[key], right[key]): return false
		return true
	if left is Array and right is Array:
		if left.size() != right.size(): return false
		for index: int in range(left.size()):
			if not _equivalent(left[index], right[index]): return false
		return true
	return typeof(left) == typeof(right) and left == right


func _block_save(message: String) -> void:
	save_blocked = true
	last_save_ok = false
	load_notice = message


static func _xp_before_level(level: int) -> int:
	var count: int = maxi(0, level - 1)
	return count * int(Balance.XP.first_level) + (count * (count - 1) / 2) * int(Balance.XP.per_level)


static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))


static func _whole(value: Variant, low: int, high: int) -> bool:
	return _number(value) and float(value) >= float(low) and float(value) <= float(high) and floor(float(value)) == float(value)


static func _clean_name(value: String) -> String:
	var cleaned: String = value.replace("\n", " ").replace("\r", " ").replace("\t", " ").strip_edges().left(24)
	return "Brasa" if cleaned.is_empty() else cleaned


static func _read_payload(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser: JSON = JSON.new()
	var parse_error: Error = parser.parse(file.get_as_text())
	file.close()
	return parser.data if parse_error == OK and parser.data is Dictionary else {}


static func _write(path: String, value: String) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(value)
	file.flush()
	var error: Error = file.get_error()
	file.close()
	return error == OK


static func _archive_original(path: String) -> String:
	var absolute: String = ProjectSettings.globalize_path(path)
	var target: String = absolute + ".invalid.bak"
	if FileAccess.file_exists(target):
		if FileAccess.get_file_as_string(absolute) == FileAccess.get_file_as_string(target):
			return target
		target = absolute + ".invalid-" + str(Time.get_ticks_usec()) + ".bak"
	return target if DirAccess.copy_absolute(absolute, target) == OK else ""
