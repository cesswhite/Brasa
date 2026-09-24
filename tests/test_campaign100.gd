extends SceneTree
const Story = preload("res://scripts/story_catalog.gd")
const Progress = preload("res://scripts/story_progression.gd")
const Config = preload("res://scripts/campaign_config.gd")
const Moves = preload("res://scripts/move_catalog.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Balance = preload("res://scripts/balance.gd")
class MemoryCampaign extends "res://scripts/story_progression.gd":
	var fail_save: bool = false
	func save() -> bool:
		last_save_ok = not fail_save
		return last_save_ok
var checks: int = 0
var failures: int = 0
var serial: int = 0
var directory: String
const CAMPAIGN_KEYS: Array[String] = ["unlocked_moves", "move_upgrades", "perks", "move_points", "perk_points", "run_seed", "bosses_defeated", "campaign_completed", "global_story_level", "replay_matches", "replay_wins", "replay_losses", "archive_flat", "build_revision", "build_history", "stat_policy_version", "legacy_stat_credit", "move_token_floor", "completion_snapshot"]

func _init() -> void:
	directory = ProjectSettings.globalize_path("res://../../work/campaign100/fixtures_%d" % Time.get_ticks_usec()).simplify_path()
	DirAccess.make_dir_recursive_absolute(directory)
	_catalog()
	_malformed_shapes()
	_campaign()
	_migration()
	_moves_and_replays()
	_respec()
	print("CAMPAIGN100: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CAMPAIGN100: " + label)

func fresh(id: String = "sira") -> RefCounted:
	var p = MemoryCampaign.new()
	p.select_character(id)
	return p

func summary(p: RefCounted, won: bool = true, reason: String = "normal") -> Dictionary:
	serial += 1
	return {"battle_id": "campaign100_%d" % serial, "winner": "player" if won else "rival", "reason": reason, "duration": 30.0, "turns": 20, "player": p.active_combatant(), "rival": p.make_rival(), "metrics": {"player": {}, "rival": {}}}

func payload(p: RefCounted) -> Dictionary:
	p.roster[p.active_id] = p.data
	return {"version": 3, "mode": "story", "active_id": p.active_id, "roster": p.roster.duplicate(true), "history": p.history.duplicate(true), "processed_battles": p._processed_battles.duplicate(true), "next_match_at": 0.0, "surrender_chain": 0}

func _catalog() -> void:
	check(Story.total_encounters() == 100 and Story.chapters().size() == 11, "Exactly 100 battles in eleven explicit chapters")
	check(Story.stages().size() == 8 and Story.stages(2).size() == 8 and Story.stages(3).size() == 4, "First sixteen and chapter APIs keep their boundaries")
	check(Story.stage(1).id == "wind_bridge" and Story.stage(1).level == 2, "Previously corrected Nima2 preserved")
	var ids: Array[String] = []
	var bosses: Array[int] = []
	for level: int in range(1, 101):
		var stage: Dictionary = Story.global_stage(level)
		var chapter: int = Story.chapter_for_level(level)
		check(not stage.is_empty() and int(stage.global_level) == level, "Every global position exists")
		check(not str(stage.id) in ids, "Unique stable global encounter ID")
		ids.append(str(stage.id))
		check(ResourceLoader.exists(str(Story.chapter(chapter).background)), "Every chapter has an existing background")
		var rival: Dictionary = Story.opponent(level - int(Story.chapter(chapter).start_level), chapter, 778, "sira")
		check(rival.story_level == level and rival.story_stage_id == stage.id, "Opponent describes the exact global encounter")
		check(rival.moves.size() >= 2 and rival.moves.size() <= 5, "Known usable moves visible before combat")
		for key: String in Balance.STAT_BOUNDS:
			check(float(rival.combat_stats[key]) >= float(Balance.STAT_BOUNDS[key][0]) and float(rival.combat_stats[key]) <= float(Balance.STAT_BOUNDS[key][1]), "Campaign stats use normal bounds")
		check(stage.xp_win >= stage.xp_loss * 3, "Winning beats losing for progression")
		if stage.kind == "boss":
			bosses.append(level)
			check(rival.moves.size() == 5, "Boss full known moveset")
			check(rival == Story.opponent(level - int(Story.chapter(chapter).start_level), chapter, 998, "taro"), "Bosses never randomized")
	check(bosses == [8,16,20,30,40,50,60,70,80,90,100], "Intentional bosses and special 50/100")
	check(Story.global_stage(0).is_empty() and Story.global_stage(101).is_empty(), "Out-of-range encounters rejected")
	check(Story.global_stage(50).major and Story.global_stage(100).major, "Two major bosses declared")
	var seen: Array[String] = []
	for seed_value: int in range(1, 41):
		var opponent: Dictionary = Story.opponent(0, 4, seed_value, "nima")
		if not str(opponent.character_id) in seen: seen.append(str(opponent.character_id))
		check(opponent == Story.opponent(0, 4, seed_value, "nima"), "Pool choice reproducible without consuming combat RNG")
	check(seen.size() >= 2, "Normal encounters vary between runs")
	check(Story.global_stage(61).stat_allocations != Story.global_stage(62).stat_allocations, "Variants change distributions rather than uniform multipliers")

func _campaign() -> void:
	var p = fresh()
	var legacy: Dictionary = {}
	for level: int in range(1, 101):
		check(p.global_level() == level, "Global progression advances once per victory")
		var reward: Dictionary = p.reward_match(summary(p))
		check(bool(reward.accepted) and bool(reward.advanced), "Valid new win accepted")
		check(int(reward.move_points_gained) == (1 if level in Config.MOVE_TOKEN_LEVELS else 0), "Move milestone once")
		check(int(reward.perk_points_gained) == (1 if level in Config.PERK_LEVELS else 0), "Perk milestone once")
		if p.is_complete() and level != 100:
			if level == 8: legacy = p.completion_summary()
			check(p.can_start_next_chapter(), "Chapter needs explicit entry")
			check(p.start_next_chapter(), "Next chapter starts explicitly")
			check(p.completion_summary(1) == legacy, "Original legacy immutable through the whole campaign")
			check(not Progress._decode(payload(p)).is_empty(), "Flat checkpoints validate without recursive duplication")
	check(p.campaign_completion().completed and p.campaign_completion().defeated == 100, "Final victory completes campaign")
	check(p.data.bosses_defeated.size() == 11 and p.chapter_summaries().size() == 11, "All bosses and chapter legacies retained")
	check(not p.can_start_next_chapter() and not p.start_next_chapter(), "No imaginary chapter twelve")
	var final_legacy: Dictionary = p.completion_summary()
	check(p.respec_build() and p.completion_summary() == final_legacy, "Final winning build remains frozen after completed-campaign respec")
	p.upgrade("attack")
	check(p.completion_summary() == final_legacy, "Post-victory training cannot alter final legacy")
	check(p.data.move_points == 10 and p.data.perk_points == 3, "Bounded lifetime milestone currencies")
	check(not Progress._decode(payload(p)).is_empty(), "Complete one-hundred-battle save validates")
	var serialized: String = JSON.stringify(payload(p))
	check(serialized.length() < 1000000, "Legacy archives grow linearly, under one MB for this full run")
	check(not p.reward_match(summary(p)).accepted, "No progression results accepted after final completion")
	check(p.select_replay(100), "Final boss becomes replayable")
	var old: Dictionary = p.data.duplicate(true)
	var repeated: Dictionary = p.reward_match(summary(p))
	check(repeated.accepted and repeated.replay and not repeated.advanced and repeated.xp_gained == 0, "Final boss replay cannot duplicate rewards")
	check(p.data.total_xp == old.total_xp and p.data.move_points == old.move_points and p.data.perk_points == old.perk_points and p.data.bosses_defeated == old.bosses_defeated, "Replay cannot farm progression")
	check(not Progress._decode(payload(p)).is_empty(), "Replay save and global history validate")

func _legacy_profile(profile: Dictionary) -> void:
	for record: Dictionary in profile.get("chapter_records", {}).values(): _legacy_profile(record.profile)
	for key: String in CAMPAIGN_KEYS: profile.erase(key)

func _write(path: String, content: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)
	file.close()

func _migration() -> void:
	for version: int in [1, 2]:
		var p = fresh()
		for battle: int in range(8): p.reward_match(summary(p))
		var legacy: Dictionary = p.completion_summary()
		if version == 2:
			p.start_next_chapter()
			p.reward_match(summary(p, false))
		var old: Dictionary = payload(p)
		old.version = version
		_legacy_profile(old.roster.sira)
		if version == 1:
			old.roster.sira.erase("chapter")
			old.roster.sira.erase("chapter_records")
		var bytes: String = JSON.stringify(old, "\t")
		var path: String = directory.path_join("v%d.json" % version)
		_write(path, bytes)
		var loaded = Progress.new()
		loaded.load_save(path)
		check(not loaded.save_blocked and not loaded.data.is_empty(), "Legacy version loads")
		check(FileAccess.get_file_as_string(path) == bytes, "Legacy load does not rewrite original")
		check(loaded.current_chapter() == version and Progress._equivalent(loaded.completion_summary(1), legacy), "Legacy remains in original chapter with exact first summary")
		for key: String in ["name","character_id","level","xp","points","allocations","allocation_history","total_xp","stats"]:
			check(loaded.data[key] == p.data[key], "Legacy growth unchanged: " + key)
		check(loaded.data.unlocked_moves.size() >= 3 and loaded.data.move_points == 1, "Migration derives moves and already earned milestone")
		check(loaded.save(), "Explicit first write creates v3")
		check(FileAccess.get_file_as_string(path + ".v%d.bak" % version) == bytes, "Permanent previous-version backup byte-identical")
		var again = Progress.new()
		again.load_save(path)
		check(Progress._equivalent(again.data, loaded.data) and Progress._equivalent(again.completion_summary(1), legacy), "V3 reload retains migration data")
		check(again.save() and FileAccess.get_file_as_string(path + ".v%d.bak" % version) == bytes, "Permanent backup never rotates")
		var blocked_path: String = directory.path_join("blocked%d.json" % version)
		_write(blocked_path, bytes)
		_write(blocked_path + ".v%d.bak" % version, "bad backup")
		var blocked = Progress.new()
		blocked.load_save(blocked_path)
		check(not blocked.save() and FileAccess.get_file_as_string(blocked_path) == bytes, "Invalid permanent backup prevents replacement")

func _moves_and_replays() -> void:
	var p = fresh("nima")
	check(p.data.unlocked_moves.size() == 2 and p.available_perks().is_empty(), "Fresh hero has two moves and no free perks")
	check(not p.upgrade_move("nima_cometa") and not p.choose_perk("foreign"), "Locked moves and foreign perks rejected")
	var losses: Array[int] = []
	for attempt: int in range(6): losses.append(int(p.reward_match(summary(p, false)).xp_gained))
	check(losses[0] > losses[1] and losses[1] >= losses[5] and losses[5] > 0, "Repeated loss XP diminishes but never blocks growth")
	for level: int in range(1, 11):
		if p.is_complete(): p.start_next_chapter()
		p.reward_match(summary(p))
	var move_id: String = str(p.data.unlocked_moves[0])
	var old: Dictionary = p.data.duplicate(true)
	p.fail_save = true
	check(not p.upgrade_move(move_id) and p.data == old, "Failed move save rolls back currency and tier")
	p.fail_save = false
	check(p.upgrade_move(move_id) and p.upgrade_move(move_id), "Two bounded move tiers consume tokens")
	check(not p.upgrade_move(move_id) and p.data.move_points == 0, "Tier three rejected")
	var options: Array[Dictionary] = p.available_perks()
	check(options.size() == 6, "Six character-specific perks preserve choices")
	old = p.data.duplicate(true)
	p.fail_save = true
	check(not p.choose_perk(str(options[0].id)) and p.data == old, "Failed perk save rolls back choice")
	p.fail_save = false
	check(p.choose_perk(str(options[0].id)) and not p.choose_perk(str(options[0].id)), "Perk choice unique and consumes token")
	check(not p.select_replay(11) and p.select_replay(5), "Only cleared battles replayable")
	var descriptor: Dictionary = p.make_rival()
	check(descriptor.story_level == 5 and descriptor.story_replay and p.active_combatant().story_level == 5, "Both combatants carry replay identity")
	var stale: Dictionary = summary(p)
	var repeated: Dictionary = p.reward_match(stale)
	check(repeated.replay and repeated.accepted and repeated.move_points_gained == 0 and repeated.perk_points_gained == 0, "Milestone replays give no tokens")
	check(p.reward_match(stale).duplicate, "Replay result idempotent")
	p.clear_replay()
	stale.battle_id = "stale_unprocessed"
	check(not p.reward_match(stale).accepted, "Replay result cannot become progression result")
	check(not Progress._decode(payload(p)).is_empty(), "Upgrades perks replay validate together")
	for defect: String in ["unlocked", "tier", "token", "perk", "seed", "boss", "complete"]:
		var bad: Dictionary = payload(p)
		match defect:
			"unlocked": bad.roster.nima.unlocked_moves.append("nima_impossible")
			"tier": bad.roster.nima.move_upgrades[move_id] = 3
			"token": bad.roster.nima.move_points = 20
			"perk": bad.roster.nima.perks.append("sira_foreign")
			"seed": bad.roster.nima.run_seed = 0
			"boss": bad.roster.nima.bosses_defeated.append("journey_100")
			"complete": bad.roster.nima.campaign_completed = true
		check(Progress._decode(bad).is_empty(), "Corrupt new field rejected: " + defect)

func _respec() -> void:
	var p = fresh("sira")
	for index: int in range(10):
		if p.is_complete(): p.start_next_chapter()
		p.upgrade("attack")
		p.reward_match(summary(p))
	p.upgrade_move(str(p.data.unlocked_moves[0]))
	p.choose_perk(str(p.available_perks()[0].id))
	var before: Dictionary = p.data.duplicate(true)
	var legacy: Dictionary = p.completion_summary(1)
	var xp: int = int(p.data.total_xp)
	var points: int = int(p.data.points)
	for value: Variant in p.data.allocations.values(): points += int(value)
	p.fail_save = true
	check(not p.respec_build() and p.data == before, "Respec rolls back entirely on write failure")
	p.fail_save = false
	check(p.respec_build(), "Explicit respec succeeds")
	check(p.data.points == points and p.data.move_points == 2 and p.data.perk_points == 1, "Respec refunds only earned and spent currencies")
	check(p.data.allocation_history.is_empty() and p.data.move_upgrades.is_empty() and p.data.perks.is_empty(), "Respec clears current build choices")
	check(p.data.build_revision == 1 and p.data.build_history.size() == 1 and p.data.build_history[0].allocations == before.allocations, "Previous choices retained in build history")
	check(p.data.total_xp == xp and p.data.level == before.level and p.data.current_stage == before.current_stage and p.data.attempts == before.attempts, "Respec keeps XP level route and all attempts")
	check(p.completion_summary(1) == legacy, "Respec never changes previous legacy")
	check(not Progress._decode(payload(p)).is_empty(), "Revision explicitly permits redistribution after frozen chapter")
	p.upgrade("defense")
	p.upgrade_move(str(p.data.unlocked_moves[1]))
	p.choose_perk(str(p.available_perks()[1].id))
	var path: String = directory.path_join("respec.json")
	_write(path, JSON.stringify(payload(p)))
	var loaded = Progress.new()
	loaded.load_save(path)
	check(not loaded.save_blocked and Progress._equivalent(loaded.data,p.data), "Redistributed build persists exactly through reload")
	check(Progress._equivalent(loaded.completion_summary(1),legacy), "Disk reload retains immutable legacy after redistribution")
	var bad: Dictionary = payload(p)
	bad.roster.sira.build_revision = 0
	check(Progress._decode(bad).is_empty(), "Forged missing revision rejected")
	var old = fresh("luma")
	# Simulate an old valid level-50 V2 with its full originally earned credit.
	old.data.level = 50
	old.data.xp = 0
	old.data.total_xp = Progress._xp_before_level(50)
	old.data.points = 3 + 49 * 3
	var legacy_payload: Dictionary = payload(old)
	legacy_payload.version = 2
	_legacy_profile(legacy_payload.roster.luma)
	var migrated: Dictionary = Progress._decode(legacy_payload)
	check(not migrated.is_empty() and migrated.roster.luma.points == 150 and migrated.roster.luma.legacy_stat_credit == 30, "Old level-50 earned stat credit survives new growth curve")
	var forged = fresh("nima")
	var fake: Dictionary = payload(forged)
	fake.roster.nima.legacy_stat_credit = 200
	fake.roster.nima.points = 203
	check(Progress._decode(fake).is_empty(), "Legacy credit bounded by actually reached hero and story levels")
	fake = payload(forged)
	fake.roster.nima.move_token_floor = 10
	fake.roster.nima.move_points = 10
	check(Progress._decode(fake).is_empty(), "Old move entitlement cannot exist before its original milestone")
	check(Story.points_for_level(20) == 3 and Story.points_for_level(21) == 2 and Story.points_for_level(51) == 0, "Declared per-level grants stay bounded")

func _malformed_shapes() -> void:
	var p = fresh()
	var original: Dictionary = payload(p)
	for key: String in p.data:
		var corrupt: Dictionary = original.duplicate(true)
		corrupt.roster.sira.erase(key)
		# Optional migration metadata is intentionally backfilled; core fields must reject safely.
		var decoded: Dictionary = Progress._decode(corrupt)
		if key in ["level","current_stage","total_xp","character_id","completed","name","stats","xp","points","allocations","allocation_history","defeated","attempts","matches","wins","losses","badge"]:
			check(decoded.is_empty(), "Missing core field rejects without a script exception: " + key)
	for key: String in ["chapter","current_stage","level","total_xp"]:
		var corrupt: Dictionary = original.duplicate(true)
		corrupt.version = 2
		corrupt.roster.sira[key] = 3000000000
		check(Progress._decode(corrupt).is_empty(), "Malformed legacy numbers cannot enter migration loops: " + key)
