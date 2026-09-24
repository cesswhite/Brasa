extends SceneTree
const Story = preload("res://scripts/story_catalog.gd")
const Progress = preload("res://scripts/story_progression.gd")
const Battle = preload("res://scripts/combat_engine.gd")
const Balance = preload("res://scripts/balance.gd")
class MemoryCampaign extends "res://scripts/story_progression.gd":
	var fail_save: bool = false
	func save() -> bool:
		last_save_ok = not fail_save
		return last_save_ok
var checks: int = 0
var failures: int = 0
var serial: int = 0
var fixture_root: String = ""

func _init() -> void:
	fixture_root = ProjectSettings.globalize_path("res://../../work/story/chapter_fixtures/run_%d" % Time.get_ticks_usec()).simplify_path()
	DirAccess.make_dir_recursive_absolute(fixture_root)
	_test_catalog()
	_test_transition()
	_test_v1_migration()
	_test_boss()
	print("STORY CHAPTERS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("CHAPTER FAIL: " + message)

func _fresh() -> RefCounted:
	var result = MemoryCampaign.new()
	result.select_character("sira")
	return result

func _summary(profile: RefCounted, winner: String = "player") -> Dictionary:
	serial += 1
	return {"battle_id": "chapters_%d" % serial, "winner": winner, "reason": "normal", "duration": 35.0, "turns": 20, "player": profile.active_combatant(), "rival": profile.make_rival(), "metrics": {"player": {}, "rival": {}}}

func _complete(profile: RefCounted) -> void:
	while not profile.is_complete():
		var reward: Dictionary = profile.reward_match(_summary(profile))
		check(bool(reward.accepted), "Fixture progresses only through accepted chapter rewards")
		if not bool(reward.accepted): break

func _test_catalog() -> void:
	check(Story.stages().size() == 8 and Story.stage(1).id == "wind_bridge" and Story.stage(1).level == 2, "Original second opponent now has level 2 without changing its identity")
	check(Story.chapters().size() == 11 and Story.chapter().number == 1, "Default API remains chapter one")
	var ids: Array[String] = []
	for chapter: int in [1, 2]:
		check(Story.stages(chapter).size() == 8, "Each chapter has its own eight encounters")
		check(ResourceLoader.exists(str(Story.chapter(chapter).background)), "Chapter points at a real background")
		for index: int in range(8):
			var stage: Dictionary = Story.stage(index, chapter)
			var opponent: Dictionary = Story.opponent(index, chapter)
			check(not str(stage.id) in ids, "Stage IDs remain globally unique")
			ids.append(str(stage.id))
			check(int(opponent.story_chapter_id) == chapter and int(opponent.story_stage_index) == index and opponent.story_stage_id == stage.id, "Descriptor carries chapter and local stage identity")
			check(int(stage.xp_loss) > 0 and int(stage.xp_win) >= int(stage.xp_loss) * 3, "Chapter rewards remain positive and favor victory")
			for key: String in Balance.STAT_BOUNDS:
				check(float(opponent.combat_stats[key]) >= float(Balance.STAT_BOUNDS[key][0]) and float(opponent.combat_stats[key]) <= float(Balance.STAT_BOUNDS[key][1]), "Chapter stats obey global caps")
	check(Story.stage(8).is_empty() and Story.stage(8, 2).is_empty() and Story.chapter(12).is_empty(), "Chapter boundaries do not silently invent another fight")
	check(Story.boss_definition().id == "ascua" and Story.boss_definition(2).id == "vespera", "Both bosses retain distinct definitions")
	check(Story.opponent(7, 2).name == "Véspera" and Story.opponent(7, 2).ability.id == "phase_shift", "Véspera uses existing phase rules")

func _test_transition() -> void:
	var profile = _fresh()
	check(not profile.can_start_next_chapter() and not profile.start_next_chapter(), "Chapter two cannot be skipped to")
	profile.upgrade("attack")
	var stale: Dictionary = _summary(profile)
	profile.reward_match(stale)
	_complete(profile)
	check(profile.is_complete() and profile.current_chapter() == 1 and profile.make_rival().is_empty() and profile.can_start_next_chapter(), "Ascua still completes chapter one without auto-starting chapter two")
	var before: Dictionary = profile.data.duplicate(true)
	var legacy: Dictionary = profile.completion_summary()
	var logs: Array = profile.history.duplicate(true)
	profile.fail_save = true
	check(not profile.start_next_chapter() and profile.data == before and profile.current_chapter() == 1, "Failed transition save rolls back every chapter field")
	check(profile.completion_summary() == legacy and profile.history == logs, "Failed save cannot alter legacy or history")
	profile.fail_save = false
	check(profile.start_next_chapter() and profile.current_chapter() == 2 and profile.current_stage() == 0, "Explicit successful transition begins local stage zero")
	for key: String in ["name", "character_id", "level", "xp", "points", "total_xp", "cap_xp", "stats", "allocations", "allocation_history"]:
		check(profile.data[key] == before[key], "Shared growth preserved exactly: " + key)
	check(profile.data.matches == 0 and profile.data.wins == 0 and profile.data.losses == 0 and not profile.is_complete(), "Only new chapter route counters reset")
	check(profile.completion_summary(1) == legacy and profile.chapter_summaries().size() == 1, "Prior legacy snapshot archived intact")
	var copy: Dictionary = profile.completion_summary(1)
	copy.final_stats.attack = 999.0
	check(profile.completion_summary(1) == legacy, "Returned legacy cannot mutate immutable snapshot")
	check(profile.reward_match(stale).duplicate, "Chapter-one processed rewards remain idempotent")
	var forged: Dictionary = _summary(profile)
	forged.player.story_chapter_id = 1
	check(not profile.reward_match(forged).accepted, "Stale player chapter rejected even when local stage and IDs match")
	forged = _summary(profile)
	forged.rival.story_chapter_id = 1
	check(not profile.reward_match(forged).accepted, "Stale rival chapter rejected")
	forged = _summary(profile)
	forged.player.erase("story_chapter_id")
	check(not profile.reward_match(forged).accepted, "Missing chapter metadata cannot bypass chapter validation")
	profile.upgrade("max_hp")
	profile.reward_match(_summary(profile, "rival"))
	check(profile.completion_summary(1) == legacy and profile.current_stage() == 0, "Later growth and losses cannot rewrite old legacy")
	_complete(profile)
	check(profile.is_complete() and profile.can_start_next_chapter(), "Véspera closes chapter two and leaves chapter three for explicit entry")
	check(profile.chapter_summaries().size() == 2 and profile.completion_summary(2).badge != legacy.badge, "Both chapter legacies and distinct badges remain available")
	check(profile.completion_summary(1) == legacy, "Completed second chapter still preserves first snapshot")
	profile.select_character("mugo")
	check(profile.current_chapter() == 1 and profile.data.level == 1, "Another hero has an independent fresh chapter one")
	profile.select_character("sira")
	check(profile.current_chapter() == 2 and profile.is_complete(), "Returning to Sira restores the second completed chapter")
	var payload: Dictionary = _payload(profile)
	check(not Progress._decode(payload).is_empty(), "Full two-chapter profile validates for persistence")
	for defect: String in ["missing_archive", "forged_legacy", "future_chapter", "point_budget", "erased_growth"]:
		var corrupted: Dictionary = payload.duplicate(true)
		match defect:
			"missing_archive": corrupted.roster.sira.chapter_records.clear()
			"forged_legacy": corrupted.roster.sira.chapter_records["1"].summary.final_stats.attack = 999.0
			"future_chapter": corrupted.roster.sira.chapter = 3
			"point_budget": corrupted.roster.sira.points = int(corrupted.roster.sira.points) + 4
			"erased_growth":
				var raw: Dictionary = corrupted.roster.sira
				raw.level = 1
				raw.xp = 0
				raw.total_xp = 0
				var spent: int = 0
				for key: String in raw.allocations: spent += int(raw.allocations[key])
				raw.points = 11 - spent
		check(Progress._decode(corrupted).is_empty(), "Corrupt archive rejected: " + defect)

func _payload(profile: RefCounted) -> Dictionary:
	profile.roster[profile.active_id] = profile.data
	return {"version": Progress.SAVE_VERSION, "mode": "story", "active_id": profile.active_id, "roster": profile.roster.duplicate(true), "history": profile.history.duplicate(true), "processed_battles": profile._processed_battles.duplicate(true), "next_match_at": 0.0, "surrender_chain": 0}

func _write(path: String, content: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)
	file.close()

func _test_v1_migration() -> void:
	var source = _fresh()
	source.upgrade("defense")
	source.reward_match(_summary(source, "rival"))
	_complete(source)
	var old: Dictionary = _payload(source)
	old.version = 1
	old.roster.sira.erase("chapter")
	old.roster.sira.erase("chapter_records")
	for key: String in ["unlocked_moves", "move_upgrades", "perks", "move_points", "perk_points", "run_seed", "bosses_defeated", "campaign_completed", "global_story_level", "replay_matches", "replay_wins", "replay_losses", "build_revision", "build_history", "stat_policy_version", "legacy_stat_credit", "move_token_floor", "completion_snapshot"]:
		old.roster.sira.erase(key)
	for log: Dictionary in old.history: log.erase("story_chapter_id")
	for action: Dictionary in old.roster.sira.allocation_history: action.erase("chapter")
	var bytes: String = JSON.stringify(old, "\t")
	var path: String = fixture_root.path_join("sira_v1.json")
	_write(path, bytes)
	var profile = Progress.new()
	profile.load_save(path)
	check(not profile.save_blocked and profile.current_chapter() == 1 and profile.is_complete(), "Sira V1 completion migrates to chapter one in memory")
	check(FileAccess.get_file_as_string(path) == bytes and not FileAccess.file_exists(path + ".v1.bak"), "Loading V1 performs no write or automatic chapter transition")
	for key: String in old.roster.sira:
		check(Progress._equivalent(profile.data[key], old.roster.sira[key]), "Migration retains existing field: " + key)
	var legacy: Dictionary = profile.completion_summary()
	check(profile.start_next_chapter(), "Migrated Sira can explicitly enter second chapter")
	check(FileAccess.get_file_as_string(path + ".v1.bak") == bytes and FileAccess.get_file_as_string(path + ".bak") == bytes, "First V2 write preserves permanent and rotating V1 copies")
	check(int(Progress._read_payload(path).version) == 3, "New save is version three")
	profile.upgrade("attack")
	check(FileAccess.get_file_as_string(path + ".v1.bak") == bytes, "Later saves never replace the permanent V1 copy")
	var restored = Progress.new()
	restored.load_save(path)
	check(restored.current_chapter() == 2 and Progress._equivalent(restored.completion_summary(1), legacy), "Disk reload retains second chapter and immutable first legacy")
	var valid_copy: String = FileAccess.get_file_as_string(path + ".v1.bak")
	_write(path, bytes)
	restored.load_save(path)
	check(restored.save() and FileAccess.get_file_as_string(path + ".v1.bak") == valid_copy, "Existing valid permanent backup is preserved")
	var invalid_backup: String = fixture_root.path_join("invalid_backup.json")
	_write(invalid_backup, bytes)
	_write(invalid_backup + ".v1.bak", "invalid preserved bytes")
	restored.load_save(invalid_backup)
	var before: Dictionary = restored.data.duplicate(true)
	check(not restored.start_next_chapter() and restored.data == before, "Invalid preexisting V1 backup prevents transition with rollback")
	check(FileAccess.get_file_as_string(invalid_backup) == bytes and FileAccess.get_file_as_string(invalid_backup + ".v1.bak") == "invalid preserved bytes", "Backup failure preserves both originals byte-for-byte")
	var new_state: Dictionary = _payload(source)
	new_state.version = 4
	check(Progress._decode(new_state).is_empty(), "Unknown future save version remains protected")
	old.roster.sira.chapter = 2
	check(Progress._decode(old).is_empty(), "A V1 label cannot silently downgrade chapter-two data")

func _test_boss() -> void:
	var player: Dictionary = Story.opponent(7)
	var boss: Dictionary = Story.opponent(7, 2)
	var fast = Battle.new()
	var stepped = Battle.new()
	fast.start(player, boss, 5591, {"force_signature": ["rival"], "signature_turn": 1})
	stepped.start(player, boss, 5591, {"force_signature": ["rival"], "signature_turn": 1})
	fast.advance(60.0)
	while stepped.running: stepped.advance(0.017)
	check(fast.summary() == stepped.summary(), "New boss reuses seeded delta-independent combat")
	check(int(fast.summary().metrics.rival.signatures) == 1 and float(Balance.SIGNATURE.chance) == 0.01, "Véspera signature is single-use and normal chance remains one percent")
	fast.start(player, boss, 55, {"disable_signatures": true, "initial_hp": {"rival": float(boss.combat_stats.max_hp) * 0.29}})
	var runtime: Dictionary = fast.snapshot().fighters.rival.runtime_stats
	check(is_equal_approx(float(runtime.speed), float(boss.combat_stats.speed) * 1.10) and is_equal_approx(float(runtime.attack), float(boss.combat_stats.attack) * 1.08), "Véspera final phase contains only its declared subtle changes")
	fast.surrender()
	check(not fast.running and fast.advance(60.0).is_empty(), "Chapter-two boss cannot act after surrender")
