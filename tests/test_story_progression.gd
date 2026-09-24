extends SceneTree
const Progress = preload("res://scripts/story_progression.gd")
const Story = preload("res://scripts/story_catalog.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Balance = preload("res://scripts/balance.gd")
const EngineModel = preload("res://scripts/combat_engine.gd")
var _checks: int = 0
var _failures: int = 0
var _serial: int = 0
var _directory: String = ""
var _prefix: String = ""

func _init() -> void:
	_directory = ProjectSettings.globalize_path("res://../../work/story/progression_fixtures").simplify_path()
	_prefix = "story_%d_" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(_directory)
	_test_fresh_collection()
	_test_allocations()
	_test_results()
	_test_completion()
	_test_validation()
	_test_persistence()
	_test_history()
	_test_actual_engine()
	_cleanup()
	print("STORY PROGRESSION: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)

func _path(name: String) -> String:
	return _directory.path_join(_prefix + name + ".story.json")

func _write(path: String, value: Variant) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(value if value is String else JSON.stringify(value))
	file.close()

func _fresh(id: String = "luma") -> RefCounted:
	_serial += 1
	var profile = Progress.new()
	profile.load_save(_path("fresh_" + str(_serial)))
	profile.select_character(id)
	return profile

func _summary(profile: RefCounted, winner: String = "player", reason: String = "normal", duration: float = 35.0) -> Dictionary:
	_serial += 1
	return {"battle_id": _prefix + "match_" + str(_serial), "winner": winner, "loser": "rival" if winner == "player" else "player",
		"reason": reason, "duration": duration, "turns": 20, "player": profile.active_combatant(), "rival": profile.make_rival(),
		"metrics": {"player": {"attacks": 10, "misses": 5, "damage_taken": 100}, "rival": {"attacks": 10, "hits": 8}}}

func _snapshot_payload(profile: RefCounted) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(profile._save_path))

func _test_fresh_collection() -> void:
	var profile = _fresh()
	for id: String in Catalog.IDS:
		_check(profile.select_character(id), "Every roster character has a campaign: " + id)
		_check(profile.data.level == 1 and profile.data.xp == 0 and profile.data.points == 3, "Fresh balanced progression: " + id)
		_check(profile.data.stats == Catalog.definition(id).training_base, "No league training inherited: " + id)
		_check(Story.stats_for(profile.data) == Catalog.stats_for({"character_id": id, "level": 1, "stats": Catalog.definition(id).training_base}), "Story starts at archetype's level-one stats")
		_check(profile.current_stage() == 0 and not profile.is_complete() and profile.data.defeated.is_empty(), "Fresh route: " + id)
	_check(profile.roster.size() == Catalog.IDS.size(), "One independent campaign per character")
	profile.select_character("luma", "  Luma\nAzul  ")
	profile.upgrade("defense")
	profile.reward_match(_summary(profile, "rival"))
	var before: Dictionary = profile.data.duplicate(true)
	profile.select_character("mugo")
	_check(profile.data.matches == 0 and profile.data.allocations.defense == 0, "Switch starts other campaign independently")
	profile.select_character("luma")
	_check(profile.data == before and profile.data.name == "Luma Azul", "Switch back never resets progress")
	_check(not profile.select_character("unknown") and profile.active_id == "luma", "Unknown character cannot replace active")
	var descriptor: Dictionary = profile.active_combatant()
	_check(descriptor.mode == "story" and descriptor.story_character_id == "luma" and descriptor.story_stage_index == 0, "Player descriptor carries campaign identity")
	descriptor.allocations.defense = 30
	descriptor.stats.life = 30
	descriptor.combat_stats.attack = 999
	_check(profile.data.allocations.defense == 1 and profile.data.stats.life == 6, "Runtime descriptors cannot mutate permanent stats")

func _test_allocations() -> void:
	for option: Dictionary in Story.allocations():
		var profile = _fresh()
		var before: Dictionary = Story.stats_for(profile.data)
		var legacy: Dictionary = profile.data.stats.duplicate(true)
		_check(profile.upgrade(str(option.key)), "Allocate each of eight choices: " + str(option.key))
		_check(is_equal_approx(float(Story.stats_for(profile.data)[option.key]) - float(before[option.key]), float(option.increment)), "Increment comes from catalog: " + str(option.key))
		_check(profile.data.points == 2 and profile.data.allocations[option.key] == 1, "One allocation consumes one point")
		_check(profile.data.stats == legacy and profile.data.allocation_history.size() == 1, "Allocation history tracks improvement without legacy training inflation")
		_check(not profile.upgrade("strength") and not profile.upgrade("unknown"), "Only story combat-stat keys accepted")
	var critical = _fresh("sira")
	for i in range(3):
		_check(critical.upgrade("crit_chance"), "Reach critical cap with available points")
	critical.reward_match(_summary(critical, "rival"))
	critical.reward_match(_summary(critical, "rival"))
	var points: int = int(critical.data.points)
	_check(points > 0 and not critical.upgrade("crit_chance") and critical.data.points == points, "Global stat cap rejects improvement without consuming points")
	var allocation_count: int = int(critical.data.allocations.crit_chance)
	_check(allocation_count < int(Story.CONFIG.allocation_cap), "Global bounds take precedence over allocation count cap")

func _test_results() -> void:
	var profile = _fresh()
	var encounter: Dictionary = profile.make_rival()
	var first: Dictionary = _summary(profile, "rival")
	var loss: Dictionary = profile.reward_match(first)
	_check(loss.accepted and loss.player.xp_gained == Story.stage(0).xp_loss and loss.player.xp_gained > 0, "Defeat awards declared positive XP")
	_check(not loss.advanced and profile.current_stage() == 0 and profile.make_rival() == encounter, "Defeat retains same opponent")
	_check("precisión" in str(loss.hint), "Defeat hint uses observed misses")
	_check(profile.data.losses == 1 and profile.data.attempts[encounter.story_stage_id] == 1 and profile.data.retries == 0, "First failed attempt recorded")
	var second: Dictionary = _summary(profile, "rival")
	loss = profile.reward_match(second)
	_check(profile.data.level > 1 and loss.player.levels_gained == 1 and loss.player.points_gained == 3, "Repeated defeats can level up and grant three points")
	_check(profile.data.retries == 1 and profile.data.losses == 2, "Retry count distinct from defeats")
	var win: Dictionary = profile.reward_match(_summary(profile))
	_check(win.advanced and profile.current_stage() == 1 and profile.data.defeated == [Story.stage(0).id], "Victory advances one stage")
	_check(win.player.xp_gained == Story.stage(0).xp_win and win.player.xp_gained > loss.player.xp_gained, "Victory significantly exceeds defeat reward")
	_check(win.rival.xp_gained == 0 and win.rival.level_before == win.rival.level_after, "Campaign opponent never levels from player results")
	_check(profile.last_save_ok, "Reward state saved atomically")
	var duplicate: Dictionary = profile.reward_match(first)
	_check(duplicate.duplicate and duplicate.xp_gained == 0, "Old failed attempt cannot reward twice")
	var multi = _fresh()
	multi.data.xp = 50
	multi.data.total_xp = 50
	multi.save()
	var multiple: Dictionary = multi.reward_match(_summary(multi))
	_check(multiple.player.levels_gained == 2 and multiple.player.level_after == 3 and multiple.player.xp_after == 35, "Win carries XP through multiple intermediate levels")
	_check(multiple.player.points_gained == 6 and multiple.player.level_ups.size() == 2 and not multiple.player.stat_gains.is_empty(), "Every intermediate level provides its own gains")
	var surrender = _fresh()
	surrender.data.xp = 54
	surrender.data.total_xp = 54
	surrender.save()
	var resigned: Dictionary = surrender.reward_match(_summary(surrender, "rival", "surrender", 0.01))
	_check(resigned.player.xp_gained == 1 and resigned.player.level_after == 2, "Surrender always grants some XP and can level up")
	_check(surrender.data.surrenders == 1 and surrender.current_stage() == 0 and not resigned.advanced, "Surrender records loss without route advancement")
	_check(surrender.seconds_until_next_match() > 0.0, "Surrender introduces short replay cooldown")
	for i in range(8):
		resigned = surrender.reward_match(_summary(surrender, "rival", "surrender", 30.0))
		_check(resigned.player.xp_gained >= 1 and resigned.player.xp_gained <= 8, "Repeated surrender XP stays in promised bounds")
	_check(resigned.player.xp_gained == 1, "Repeated surrender reduced to minimal reward")
	surrender.select_character("mugo")
	_check(surrender.seconds_until_next_match() > 0.0, "Switching campaigns cannot bypass surrender cooldown")

func _test_completion() -> void:
	var profile = _fresh("mugo")
	profile.upgrade("defense")
	profile.upgrade("accuracy")
	profile.upgrade("max_hp")
	var first: Dictionary = {}
	for index in range(Story.stages().size()):
		var stage: Dictionary = Story.stage(index)
		var summary: Dictionary = _summary(profile)
		if index == 0:
			first = summary.duplicate(true)
		var reward: Dictionary = profile.reward_match(summary)
		_check(reward.accepted and profile.current_stage() == index + 1, "Sequential encounter won: " + str(index))
		_check(profile.data.wins == index + 1 and profile.data.defeated[index] == stage.id, "Defeated route matches declared order")
		_check(reward.player.milestone_points == (2 if stage.kind == "elite" else 0), "Only elite milestones grant two extra points")
		_check(reward.player.points_gained == reward.player.levels_gained * 3 + reward.player.milestone_points, "Displayed point gain includes level and milestone rewards")
		_check(profile.last_save_ok, "Every stage saves valid route")
	_check(profile.is_complete() and profile.current_stage() == 8 and profile.make_rival().is_empty(), "Boss completes route; no extra opponent")
	_check(profile.data.badge == Story.CONFIG.badge and not profile.data.badge.is_empty(), "Completion grants persistent title badge")
	var complete: Dictionary = profile.completion_summary()
	_check(complete.battles == 8 and complete.defeats == 0 and complete.retries == 0 and complete.level > 1, "Completion summary contains meaningful run statistics")
	_check(complete.major_changes.size() == 3 and complete.allocation_history.size() == 3 and complete.clearance == "8 / 8", "Completion remembers build decisions and full clearance")
	_check(not complete.stat_gains.is_empty() and complete.final_stats == Story.stats_for(profile.data), "Completion exposes final stats and growth since start")
	var old_matches: int = profile.data.matches
	_check(profile.reward_match(first).duplicate and profile.data.matches == old_matches, "No completion or stage reward duplication")
	var finished: Dictionary = first.duplicate(true)
	finished.battle_id = "fresh_but_completed"
	_check(not profile.reward_match(finished).accepted, "Completed campaign cannot replay old route for rewards")
	var reloaded = Progress.new()
	reloaded.load_save(profile._save_path)
	_check(reloaded.is_complete() and reloaded.data.badge == Story.CONFIG.badge and reloaded.current_stage() == 8, "Completion persists after reload")
	_check(reloaded.reward_match(first).duplicate, "Boss-run reward ledger persists")
	reloaded.select_character("nima")
	_check(not reloaded.is_complete() and reloaded.current_stage() == 0 and reloaded.data.level == 1, "Another character starts independent replay")
	reloaded.select_character("mugo")
	_check(reloaded.is_complete() and reloaded.data.badge == Story.CONFIG.badge, "Returning to completed character keeps badge")

func _test_validation() -> void:
	var profile = _fresh()
	var before: Dictionary = profile.data.duplicate(true)
	for change: String in ["foreign_player", "player_stage", "rival_stage", "stage_id", "enemy_id", "mode", "metrics", "duration"]:
		var summary: Dictionary = _summary(profile)
		match change:
			"foreign_player": summary.player.character_id = "nima"
			"player_stage": summary.player.story_stage_index = 1
			"rival_stage": summary.rival.story_stage_index = 1
			"stage_id": summary.rival.story_stage_id = "last_lantern"
			"enemy_id": summary.rival.character_id = "mugo"
			"mode": summary.player.mode = "league"
			"metrics": summary.metrics = null
			"duration": summary.duration = -1
		_check(not profile.reward_match(summary).accepted and profile.data == before, "Reject mismatched or invalid result: " + change)
	var won: Dictionary = _summary(profile)
	profile.reward_match(won)
	won.battle_id = "new_id_wrong_old_stage"
	_check(not profile.reward_match(won).accepted and profile.current_stage() == 1, "Different battle ID cannot farm cleared stage")
	var foreign_campaign: Dictionary = _summary(profile)
	profile.select_character("nima")
	_check(not profile.reward_match(foreign_campaign).accepted and profile.data.matches == 0, "Result for another selected campaign rejected")
	var source = _fresh()
	var payload: Dictionary = _snapshot_payload(source)
	for defect: String in ["jump", "wrong_order", "future_attempt", "budget", "training", "retries", "completion", "version"]:
		_serial += 1
		var path: String = _path("invalid_" + defect + str(_serial))
		var bad: Dictionary = payload.duplicate(true)
		var raw: Dictionary = bad.roster.luma
		match defect:
			"jump": raw.current_stage = 2
			"wrong_order":
				raw.current_stage = 1
				raw.defeated = [Story.stage(1).id]
				raw.wins = 1
				raw.matches = 1
				raw.attempts = {Story.stage(1).id: 1}
			"future_attempt": raw.attempts = {Story.stage(7).id: 1}
			"budget": raw.points = 999
			"training": raw.stats.life = 30
			"retries": raw.retries = 8
			"completion": raw.completed = true
			"version": bad.version = 99
		_write(path, bad)
		var text: String = FileAccess.get_file_as_string(path)
		var corrupt = Progress.new()
		corrupt.load_save(path)
		_check(corrupt.save_blocked and not corrupt.select_character("mugo") and not corrupt.save(), "Malformed story protected: " + defect)
		_check(FileAccess.get_file_as_string(path) == text, "Invalid original unchanged: " + defect)
	var overflow: Dictionary = payload.duplicate(true)
	overflow.roster.luma.xp = 250
	overflow.roster.luma.total_xp = 250
	_write(_path("overflow"), overflow)
	var recovered = Progress.new()
	recovered.load_save(_path("overflow"))
	_check(not recovered.save_blocked and recovered.data.level == 4 and recovered.data.xp == 10 and recovered.data.points == 12, "XP overflow recovery calculates every level and three-point grant")
	var cap_payload: Dictionary = payload.duplicate(true)
	cap_payload.roster.luma.level = Balance.MAX_LEVEL
	cap_payload.roster.luma.unlocked_moves = Progress._unlocked_ids("luma", Balance.MAX_LEVEL)
	cap_payload.roster.luma.points = 3 + Progress._stat_points_before_level(Balance.MAX_LEVEL)
	cap_payload.roster.luma.total_xp = Progress._xp_before_level(Balance.MAX_LEVEL)
	_write(_path("cap"), cap_payload)
	recovered.load_save(_path("cap"))
	var points: int = int(recovered.data.points)
	var cap_reward: Dictionary = recovered.reward_match(_summary(recovered, "rival"))
	_check(recovered.data.level == Balance.MAX_LEVEL and recovered.data.points == points and recovered.data.xp == 0, "Maximum level never grows beyond cap")
	_check(cap_reward.player.xp_gained > 0 and recovered.data.cap_xp > 0 and recovered.xp_needed() == 0, "Maximum-level XP still counted and displayed")

func _test_persistence() -> void:
	var profile = _fresh()
	profile.upgrade("resistance")
	var summary: Dictionary = _summary(profile, "rival")
	profile.reward_match(summary)
	profile.save()
	var before: Dictionary = profile.data.duplicate(true)
	var saved_history: Array = profile.history.duplicate(true)
	var reloaded = Progress.new()
	reloaded.load_save(profile._save_path)
	_check(_equivalent(reloaded.data, before) and _equivalent(reloaded.history, saved_history), "Profile, allocations and history round-trip")
	_check(reloaded.reward_match(summary).duplicate and reloaded.data.matches == 1, "Duplicate prevention survives reloading failed attempt")
	_write(profile._save_path, "{broken story fixture")
	reloaded.load_save(profile._save_path)
	_check(not reloaded.save_blocked and reloaded.last_save_ok and _equivalent(reloaded.data, before), "Rolling backup safely restores corrupted campaign")
	_check(FileAccess.get_file_as_string(reloaded.backup_path) == "{broken story fixture" and not reloaded.load_notice.is_empty(), "Corrupt original archived and recovery disclosed")
	var missing: String = _path("missing")
	_write(missing + ".bak", _snapshot_payload(reloaded))
	var restored = Progress.new()
	restored.load_save(missing)
	_check(restored.data.matches == 1 and FileAccess.file_exists(missing), "Missing original recovered from backup")
	var league_path: String = _directory.path_join(_prefix + "league.json")
	var league_text: String = '{"version":2,"active_id":"mugo","marker":"DO NOT CHANGE LEAGUE"}'
	_write(league_path, league_text)
	var isolated = Progress.new()
	isolated.load_save(league_path + ".story.json")
	isolated.select_character("mugo")
	isolated.reward_match(_summary(isolated))
	_check(FileAccess.get_file_as_string(league_path) == league_text, "Separate story save never changes league file")
	isolated.load_save(league_path)
	_check(isolated.save_blocked and not isolated.select_character("luma"), "Accidental league path rejected by mode discriminator")
	_check(FileAccess.get_file_as_string(league_path) == league_text, "League remains untouched even with wrong load path")

func _test_history() -> void:
	var profile = _fresh()
	var first: Dictionary = _summary(profile, "rival")
	profile.reward_match(first)
	for i in range(int(Story.CONFIG.history_limit) + 2):
		profile.reward_match(_summary(profile, "rival"))
	_check(profile.history.size() == Story.CONFIG.history_limit and profile.current_stage() == 0, "Loss retries remain unlimited; history bounded")
	_check(profile.data.retries == profile.data.matches - 1 and profile.data.level > 1, "Failed attempts still support progression")
	_check(profile.reward_match(first).duplicate, "Evicted history event remains in reward ledger")
	var reloaded = Progress.new()
	reloaded.load_save(profile._save_path)
	_check(reloaded.reward_match(first).duplicate and reloaded.data.matches == profile.data.matches, "Old failed-attempt ledger survives reload")

func _test_actual_engine() -> void:
	var profile = _fresh("nima")
	var model = EngineModel.new()
	model.start(profile.active_combatant(), profile.make_rival(), 424242)
	model.advance(60.0)
	var summary: Dictionary = model.summary()
	var reward: Dictionary = profile.reward_match(summary)
	_check(not model.running and reward.accepted and reward.player.xp_gained > 0, "Real authoritative combat summary accepted")
	_check(profile.current_stage() == (1 if summary.winner == "player" else 0) and profile.last_save_ok, "Real battle and campaign stay synchronized")
	_check(profile.reward_match(summary).duplicate, "Actual engine result remains idempotent")

func _equivalent(a: Variant, b: Variant) -> bool:
	if (a is int or a is float) and (b is int or b is float):
		return is_equal_approx(float(a), float(b))
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size():
			return false
		for key: Variant in a:
			if not b.has(key) or not _equivalent(a[key], b[key]):
				return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size():
			return false
		for index in range(a.size()):
			if not _equivalent(a[index], b[index]):
				return false
		return true
	return a == b

func _cleanup() -> void:
	var directory: DirAccess = DirAccess.open(_directory)
	if directory == null:
		return
	for file_name: String in directory.get_files():
		if file_name.begins_with(_prefix):
			DirAccess.remove_absolute(_directory.path_join(file_name))
