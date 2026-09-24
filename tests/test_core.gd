extends SceneTree
## Fast integration regressions. Large balance simulations and detailed migration
## scenarios belong to the dedicated combat/progression suites.

const BattleModel = preload("res://scripts/combat_engine.gd")
const Profile = preload("res://scripts/progression.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Balance = preload("res://scripts/balance.gd")
const TEST_DIR: String = "user://tests/core_regression"
const TEST_SAVE: String = TEST_DIR + "/profile.json"
const BASE: Dictionary = {"life": 6, "strength": 6, "agility": 6, "speed": 6}

var _failures: int = 0
var _checks: int = 0


func _init() -> void:
	_cleanup()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEST_DIR))
	_test_stats()
	_test_combat()
	_test_progression()
	_test_protected_save()
	_cleanup()
	print("CORE TESTS: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("CORE FAIL: " + message)


func _test_stats() -> void:
	var described: Dictionary = BattleModel.describe_stats(BASE)
	var catalog_stats: Dictionary = Catalog.stats_for({"character_id": "luma", "level": 1, "stats": BASE})
	for key: String in Balance.STAT_KEYS:
		_check(is_equal_approx(float(described[key]), float(catalog_stats[key])), "legacy stat adapter uses catalog: " + key)
	_check(described.damage == described.attack and described.dodge_chance == described.evasion, "legacy damage and dodge aliases retained")
	for key: String in Profile.STAT_KEYS:
		var improved: Dictionary = BASE.duplicate()
		improved[key] = int(improved[key]) + 1
		var next: Dictionary = BattleModel.describe_stats(improved)
		match key:
			"life": _check(next.max_hp > described.max_hp, "Vida increases survivability")
			"strength": _check(next.damage > described.damage, "Fuerza increases attack")
			"agility":
				_check(next.crit_chance > described.crit_chance, "Agilidad increases critical chance")
				_check(next.dodge_chance > described.dodge_chance, "Agilidad increases evasion")
			"speed": _check(next.interval < described.interval, "Velocidad reduces time between actions")
	var capped: Dictionary = BattleModel.describe_stats({"life": 999, "strength": 999, "agility": 999, "speed": 999})
	for key: String in Balance.STAT_KEYS:
		var bounds: Array = Balance.STAT_BOUNDS[key]
		_check(float(capped[key]) >= float(bounds[0]) and float(capped[key]) <= float(bounds[1]), "legacy out-of-range stats obey centralized bounds: " + key)
	_check(BASE == {"life": 6, "strength": 6, "agility": 6, "speed": 6}, "stat previews do not mutate caller data")


func _combatant(id: String, level: int = 1) -> Dictionary:
	var definition: Dictionary = Catalog.definition(id)
	var result: Dictionary = {"character_id": id, "name": definition.name, "archetype": definition.archetype, "level": level, "stats": definition.training_base.duplicate(true)}
	result["combat_stats"] = Catalog.stats_for(result)
	result["ability"] = definition.ability.duplicate(true)
	result["signature"] = definition.signature.duplicate(true)
	return result


func _simulate(player: Dictionary, rival: Dictionary, seed_value: int, step: float = 0.1, options: Dictionary = {}) -> Dictionary:
	var battle = BattleModel.new()
	battle.start(player, rival, seed_value, options)
	var events: Array[Dictionary] = []
	var updates: int = 0
	while battle.running and updates < 10000:
		events.append_array(battle.advance(step))
		updates += 1
	_check(not battle.running, "simulation reaches terminal state")
	return {"events": events, "summary": battle.summary(), "winner": battle.winner, "elapsed": battle.elapsed, "player_hp": battle.player_hp, "rival_hp": battle.rival_hp}


func _test_combat() -> void:
	var first: Dictionary = _simulate(BASE, BASE, 12345, 0.016)
	_check(first == _simulate(BASE, BASE, 12345, 0.016), "legacy inputs reproduce complete seeded battle")
	_check(first == _simulate(BASE, BASE, 12345, 10.0), "legacy events are independent of render delta")
	_check(first != _simulate(BASE, BASE, 54321), "different seed changes the battle")
	var player: Dictionary = _combatant("nima", 4)
	var rival: Dictionary = _combatant("iria", 4)
	var untouched: Array = [player.duplicate(true), rival.duplicate(true)]
	var full: Dictionary = _simulate(player, rival, 7788, 0.016)
	_check(full == _simulate(player, rival, 7788, 10.0), "catalog combatants reproduce events and summary across delta")
	_check([player, rival] == untouched, "combat does not mutate persisted base descriptors")
	var finish_count: int = 0
	for event: Dictionary in full.events:
		_check(event.has("message") and event.message is String, "events carry readable log messages")
		if event.type == "finished":
			finish_count += 1
		if event.type == "attack":
			_check(int(event.damage) >= 0 and float(event.target_hp) >= 0.0, "attack damage and resulting HP are nonnegative")
	_check(finish_count == 1, "exactly one finished event")
	_check(full.summary.has_all(["battle_id", "player", "rival", "metrics", "terminal_state", "reason"]), "terminal summary supports rewards and result UI")
	var battle = BattleModel.new()
	battle.start(BASE, BASE, 55)
	_check(battle.advance(0.0).is_empty() and battle.elapsed == 0.0, "zero delta does nothing")
	_check(battle.advance(-1.0).is_empty() and battle.elapsed == 0.0, "negative delta does nothing")
	_check(battle.advance(1.0).is_empty(), "opening provides time before first attack")
	battle.advance(100.0)
	var terminal: Dictionary = battle.summary()
	_check(not battle.running and battle.advance(100.0).is_empty(), "no actions after normal completion")
	_check(battle.surrender("player").is_empty() and battle.summary() == terminal, "late surrender does not replace terminal result")
	var tank: Dictionary = _combatant("mugo")
	tank.combat_stats.max_hp = float(Balance.STAT_BOUNDS.max_hp[1])
	tank.combat_stats.attack = float(Balance.STAT_BOUNDS.attack[0])
	tank.combat_stats.defense = float(Balance.STAT_BOUNDS.defense[1])
	tank.combat_stats.speed = float(Balance.STAT_BOUNDS.speed[0])
	tank.combat_stats.interval = Balance.interval_for(tank.combat_stats.speed)
	var timeout: Dictionary = _simulate(tank, tank, 9876, 1.0, {"disable_signatures": true})
	_check(is_equal_approx(float(timeout.elapsed), float(Balance.COMBAT.max_duration)), "defensive battle stops at configured time limit")
	_check(timeout.summary.reason == "timeout" and timeout.winner in ["player", "rival"], "timeout resolves one winner")
	if not is_equal_approx(float(timeout.player_hp), float(timeout.rival_hp)):
		_check(timeout.winner == ("player" if timeout.player_hp > timeout.rival_hp else "rival"), "equal-max-HP timeout selects higher remaining life")


func _test_progression() -> void:
	var profile = Profile.new()
	profile.load_save(TEST_SAVE)
	_check(profile.data.is_empty(), "missing save starts onboarding")
	profile.create_fighter("  Lumbre\nAzul  ", 0)
	_check(profile.data.name == "Lumbre Azul", "legacy creation normalizes name")
	_check(profile.data.character_id == Catalog.id_for_archetype(0), "legacy archetype maps to stable character ID")
	_check(profile.data.points == Balance.INITIAL_POINTS and profile.data.level == 1, "new character receives initial progression")
	_check(profile.last_save_ok and FileAccess.file_exists(TEST_SAVE), "initial save succeeds")
	_check(not profile.upgrade("invalid"), "invalid training stat is rejected")
	var initial_life: int = int(profile.data.stats.life)
	_check(profile.upgrade("life") and profile.data.stats.life == initial_life + 1, "legacy training increases stat")
	_check(profile.data.points == Balance.INITIAL_POINTS - 1, "training consumes one point")
	profile.upgrade("speed")
	profile.upgrade("strength")
	_check(not profile.upgrade("agility"), "training requires an available point")
	var won: Dictionary = profile.reward(true)
	var lost: Dictionary = profile.reward(false)
	_check(won.xp_gained == 40 and lost.xp_gained == 25, "legacy reward adapter preserves 40/25 XP")
	_check(lost.levels_gained == 1 and lost.points_gained == Balance.POINTS_PER_LEVEL, "level-up grants configured training points")
	_check(profile.data.level == 2 and profile.data.xp == 65 - Balance.xp_for_level(1), "XP overflow survives level-up")
	_check(profile.data.matches == 2 and profile.data.wins == 1 and profile.data.losses == 1, "legacy reward updates counters exactly once per call")
	_check(profile.xp_needed() == Balance.xp_for_level(2), "XP requirement uses centralized level curve")
	var saved_nima: Dictionary = profile.data.duplicate(true)
	var reloaded = Profile.new()
	reloaded.load_save(TEST_SAVE)
	_check(profile.data == reloaded.data and profile.roster == reloaded.roster, "active profile and roster round-trip")
	_check(profile.make_rival() == profile.make_rival(), "rival stable before next match")
	var opponent: Dictionary = profile.make_rival()
	_check(opponent.has_all(["name", "archetype", "stats", "level", "title", "character_id", "combat_stats", "ability", "signature"]), "rival supports old and new UI contracts")
	var descriptor: Dictionary = profile.active_combatant()
	_check(descriptor.combat_stats == Catalog.stats_for(profile.data), "active battle stats derive from actual saved training")
	_check(profile.select_character("luma"), "switch to another roster member")
	_check(profile.data.level == 1 and profile.data.xp == 0 and profile.data.points == Balance.INITIAL_POINTS, "new roster member owns fresh progression")
	profile.create_fighter("Lumbre Azul", 0)
	_check(profile.data == saved_nima, "legacy create selects existing character without erasing progress")
	profile.data.stats.life = Balance.TRAINING_CAP
	var points_before: int = int(profile.data.points)
	_check(not profile.upgrade("life") and profile.data.points == points_before, "training cap consumes no point")
	for archetype in range(3):
		var separate = Profile.new()
		separate.load_save(TEST_DIR + "/archetype_%d.json" % archetype)
		separate.create_fighter("Test", archetype)
		_check(separate.data.stats == Profile.BASE_STATS[archetype], "original archetype training bases preserved")
		separate.data.stats.life = 15
		_check(Profile.BASE_STATS[archetype] == Catalog.definition(Catalog.id_for_archetype(archetype)).training_base, "mutable profile does not alter catalog constants")


func _test_protected_save() -> void:
	# Each malformed payload has no backup: recovery and v1 migration are tested
	# separately by the progression suite, while this checks caller protection.
	var payloads: Array[String] = ["{bad json", "[]", '{"version":999,"fighter":{}}', '{"version":1,"fighter":{"name":"Test","stats":{}}}']
	for index in range(payloads.size()):
		var path: String = TEST_DIR + "/invalid_%d.json" % index
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		file.store_string(payloads[index])
		file.close()
		var profile = Profile.new()
		profile.load_save(path)
		_check(profile.data.is_empty() and not profile.last_save_ok, "invalid save is reported instead of treated as a fresh success")
		_check(not profile.select_character("nima") and not profile.save(), "invalid save blocks accidental overwrite")
		_check(FileAccess.get_file_as_string(path) == payloads[index], "original invalid payload remains recoverable")


func _cleanup() -> void:
	var directory: DirAccess = DirAccess.open(TEST_DIR)
	if directory == null:
		return
	for file_name: String in directory.get_files():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_DIR.path_join(file_name)))
