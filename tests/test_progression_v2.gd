extends SceneTree

const Profile = preload("res://scripts/progression.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Balance = preload("res://scripts/balance.gd")
const MUGO_V1: Dictionary = {"version": 1, "fighter": {"name": "Mugo", "archetype": 2, "level": 3, "xp": 65, "points": 2, "wins": 5, "losses": 0, "matches": 5, "stats": {"life": 8, "strength": 7, "agility": 4, "speed": 8}}}
var _failures: int = 0
var _checks: int = 0
var _directory: String = ""
var _prefix: String = ""
var _serial: int = 0

func _init() -> void:
	_directory = ProjectSettings.globalize_path("res://../../work/expansion/progression_tests").simplify_path()
	_prefix = "run_%d_" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(_directory)
	_catalog()
	_migration()
	_corrupt_backups()
	_collection()
	_rewards()
	_farming()
	_matchmaking()
	_history()
	_cleanup()
	print("PROGRESSION V2: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)

func _path(name: String) -> String:
	return _directory.path_join(_prefix + name + ".json")

func _write(path: String, value: Variant) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(value if value is String else JSON.stringify(value))
	file.close()

func _fresh(name: String = "fresh") -> RefCounted:
	_serial += 1
	var profile = Profile.new()
	profile.load_save(_path(name + str(_serial)))
	profile.select_character("luma")
	return profile

func _summary(profile: RefCounted, winner: String = "player", reason: String = "normal", duration: float = 35.0, rival: Dictionary = {}) -> Dictionary:
	_serial += 1
	return {"battle_id": _prefix + "battle_" + str(_serial), "winner": winner, "reason": reason, "duration": duration, "turns": 20, "player": profile.active_combatant(), "rival": profile.make_rival() if rival.is_empty() else rival.duplicate(true), "metrics": {"player": {"damage": 100}, "rival": {"damage": 80}}}

func _catalog() -> void:
	var definitions: Array = Catalog.all_definitions()
	_check(definitions.size() == Catalog.IDS.size(), "All playable definitions")
	var abilities: Dictionary = {}
	var ability_behaviors: Dictionary = {}
	for entry: Dictionary in definitions:
		_check(entry.has_all(["id", "name", "role", "personality", "strengths", "weaknesses", "base_stats", "growth", "training_base", "ability", "signature", "visual"]), "Definition complete: " + str(entry.id))
		# The dispatch ID names a reusable mechanic; identity and tuning are distinct.
		_check(not abilities.has(entry.ability.name), "Unique named ability: " + str(entry.id))
		abilities[entry.ability.name] = true
		var behavior: Dictionary = entry.ability.duplicate(true)
		behavior.erase("name")
		behavior.erase("description")
		var fingerprint: String = JSON.stringify(behavior)
		_check(not ability_behaviors.has(fingerprint), "Distinct ability behavior: " + str(entry.id))
		ability_behaviors[fingerprint] = true
		var profile: Dictionary = {"character_id": entry.id, "level": 1, "stats": entry.training_base.duplicate(true)}
		var copy: Dictionary = profile.duplicate(true)
		var stats: Dictionary = Catalog.stats_for(profile)
		for key: String in Balance.STAT_KEYS:
			_check(is_equal_approx(float(stats[key]), float(entry.base_stats[key])), "Lv1 values match base: " + str(entry.id) + "/" + key)
			_check(Catalog.STAT_HELP.has(key), "Stat help: " + key)
		_check(stats.has("interval") and Catalog.power(stats) > 0.0, "Derived interval and power")
		profile.level = Balance.MAX_LEVEL
		for key: String in Profile.STAT_KEYS:
			profile.stats[key] = 30
		var maximum: Dictionary = Catalog.stats_for(profile)
		for key: String in Balance.STAT_KEYS:
			_check(float(maximum[key]) >= float(Balance.STAT_BOUNDS[key][0]) and float(maximum[key]) <= float(Balance.STAT_BOUNDS[key][1]), "Final stat bounded: " + key)
		stats.attack = -1000
		_check(Catalog.stats_for(copy).attack > 0, "Runtime dictionary cannot mutate definition")
		_check(float(entry.signature.damage_multiplier) >= 1.4 and float(entry.signature.damage_multiplier) <= 1.8 and int(entry.signature.duration) > 0, "Signature bounded with duration")
	var original: Dictionary = Catalog.definition("luma")
	original.base_stats.attack = 9999
	_check(Catalog.definition("luma").base_stats.attack != 9999, "Definition API returns isolated data")
	_check(Balance.growth_steps(50) < 49.0 and Balance.growth_steps(2) == 1.0, "Growth diminishes after soft cap")

func _migration() -> void:
	var path: String = _path("mugo")
	_write(path, MUGO_V1)
	var original: String = FileAccess.get_file_as_string(path)
	var profile = Profile.new()
	profile.load_save(path)
	_check(not profile.save_blocked and profile.last_save_ok, "Migration succeeds")
	_check(profile.active_id == "mugo" and profile.roster.size() == 1, "Mugo becomes selected collection profile")
	for key: String in ["name", "archetype", "level", "xp", "points", "wins", "losses", "matches", "stats"]:
		_check(profile.data[key] == MUGO_V1.fighter[key], "Preserve real V1 field: " + key)
	_check(FileAccess.get_file_as_string(path + ".v1.bak") == original, "Exact V1 backup before migration")
	_check(int(JSON.parse_string(FileAccess.get_file_as_string(path)).version) == 2, "Main save migrated to V2")
	profile.upgrade("life")
	_check(FileAccess.get_file_as_string(path + ".v1.bak") == original, "V1 backup remains immutable after training")
	var reloaded = Profile.new()
	reloaded.load_save(path)
	_check(reloaded.data == profile.data, "Migrated profile round-trips")
	var overflow: Dictionary = MUGO_V1.duplicate(true)
	overflow.fighter.level = 1
	overflow.fighter.xp = 250
	overflow.fighter.points = 3
	_write(_path("overflow"), overflow)
	profile.load_save(_path("overflow"))
	_check(profile.data.level == 4 and profile.data.xp == 10 and profile.data.points == 9, "V1 XP overflow carries across every level")
	var ancient: Dictionary = MUGO_V1.duplicate(true)
	ancient.fighter.level = 80
	ancient.fighter.xp = 170
	_write(_path("ancient"), ancient)
	profile.load_save(_path("ancient"))
	_check(profile.data.level == 50 and profile.data.legacy_level == 80 and profile.data.xp == 0, "V1 above cap preserves legacy level metadata")
	_check(profile.data.cap_xp > 0 and profile.data.total_xp > 0, "XP above cap retained as lifetime progress")
	var collision: String = _path("collision")
	_write(collision, MUGO_V1)
	_write(collision + ".v1.bak", overflow)
	var collision_backup: String = FileAccess.get_file_as_string(collision + ".v1.bak")
	profile.load_save(collision)
	_check(FileAccess.get_file_as_string(collision + ".v1.bak") == collision_backup, "Existing V1 backup never overwritten")
	_check(profile.backup_path != collision + ".v1.bak" and FileAccess.file_exists(profile.backup_path), "Different V1 source gets another backup")

func _corrupt_backups() -> void:
	for invalid: Variant in ["{broken json", {"version": 99, "future": true}, {"version": 2, "active_id": "missing", "roster": {}}, {"version": 1, "fighter": {"name": "broken"}}]:
		_serial += 1
		var path: String = _path("invalid" + str(_serial))
		_write(path, invalid)
		var original: String = FileAccess.get_file_as_string(path)
		var profile = Profile.new()
		profile.load_save(path)
		_check(profile.save_blocked and not profile.last_save_ok, "Unknown or corrupt save protected")
		profile.create_fighter("Replacement", 0)
		_check(not profile.save(), "Protected save rejects writes")
		_check(FileAccess.get_file_as_string(path) == original, "Invalid original unchanged")
	var profile = _fresh("backup")
	profile.upgrade("life")
	var before: Dictionary = profile.data.duplicate(true)
	profile.save()
	var path: String = profile._save_path
	_write(path, "{corrupt live fixture")
	var recovered = Profile.new()
	recovered.load_save(path)
	_check(not recovered.save_blocked and recovered.last_save_ok, "Valid rolling backup recovered")
	_check(recovered.data == before and not recovered.load_notice.is_empty(), "Recovery exposes notice and exact backup data")
	_check(FileAccess.get_file_as_string(recovered.backup_path) == "{corrupt live fixture", "Corrupt original archived before recovery")
	var missing: String = _path("missing_main")
	_write(missing + ".v1.bak", MUGO_V1)
	recovered.load_save(missing)
	_check(recovered.data.name == "Mugo" and FileAccess.file_exists(missing), "Missing main recovered from existing backup")
	var invalid_stat: Dictionary = MUGO_V1.duplicate(true)
	invalid_stat.fighter.stats.agility = "many"
	_write(_path("invalid_stat"), invalid_stat)
	recovered.load_save(_path("invalid_stat"))
	_check(recovered.save_blocked and recovered.data.is_empty(), "Nonnumeric profile stats rejected")

func _collection() -> void:
	var profile = _fresh("collection")
	profile.upgrade("strength")
	profile.reward(true)
	var luma: Dictionary = profile.data.duplicate(true)
	_check(profile.select_character("sira", "  Sira\nEstelar  "), "Select new fighter")
	_check(profile.data.name == "Sira Estelar" and profile.data.level == 1 and profile.data.xp == 0, "New character starts independently with normalized name")
	_check(profile.data.points == 3 and profile.roster.size() == 2, "Initial points per character")
	profile.upgrade("agility")
	profile.select_character("luma")
	_check(profile.data == luma, "Switching preserves original fighter progress")
	_check(not profile.select_character("unknown") and profile.active_id == "luma", "Unknown selection harmless")
	var reloaded = Profile.new()
	reloaded.load_save(profile._save_path)
	_check(reloaded.roster == profile.roster and reloaded.active_id == "luma", "Entire collection persists")
	var combatant: Dictionary = profile.active_combatant()
	combatant.stats.life = 0
	combatant.combat_stats.max_hp = 0
	combatant.ability.id = "bad"
	_check(profile.data.stats.life > 0 and profile.active_combatant().ability.id == "adapt", "Combatant snapshot isolated from profile")
	var selected_before: String = profile.active_id
	profile.create_fighter("Luma renamed", 1)
	_check(profile.active_id == selected_before and profile.data.xp == luma.xp, "Legacy create cannot erase existing progress")

func _rewards() -> void:
	var profile = _fresh("rewards")
	var summary: Dictionary = _summary(profile)
	var rival_id: String = summary.rival.opponent_id
	var reward: Dictionary = profile.reward_match(summary)
	_check(reward.player.xp_gained == 40 and reward.rival.xp_gained == 25, "Both participants receive independent XP")
	_check(profile.opponents[rival_id].xp == 25 and profile.opponents[rival_id].losses == 1, "NPC progression persists in opponents")
	var state: Dictionary = profile.data.duplicate(true)
	_check(profile.reward_match(summary).duplicate, "Duplicate battle recognized")
	_check(profile.data == state and profile.history.size() == 1, "Duplicate grants nothing and adds no history")
	var reloaded = Profile.new()
	reloaded.load_save(profile._save_path)
	_check(reloaded.reward_match(summary).duplicate and reloaded.data == state, "Duplicate prevention survives reload")
	profile.data.xp = 50
	var lost: Dictionary = profile.reward_match(_summary(profile, "rival"))
	_check(lost.player.level_after == 2 and lost.player.xp_after == 20 and lost.player.points_gained == 2, "Normal defeat can level up")
	_check(lost.player.level_ups.size() == 1 and not lost.player.stat_gains.is_empty(), "Level gains described explicitly")
	_check(profile.data.streak == 0 and profile.data.best_streak == 1, "Loss resets streak and preserves best")
	var multi = _fresh("multi")
	multi.data.xp = 250
	var gained: Dictionary = multi.reward_match(_summary(multi))
	_check(gained.player.levels_gained == 3 and gained.player.level_after == 4 and gained.player.xp_after == 50, "Multiple intermediate levels and overflow")
	_check(gained.player.level_ups.size() == 3 and gained.player.points_gained == 6, "Every intermediate level grants two points")
	for key: String in gained.player.stat_gains:
		var summed: float = 0.0
		for up: Dictionary in gained.player.level_ups:
			summed += float(up.stat_gains.get(key, 0.0))
		_check(is_equal_approx(summed, float(gained.player.stat_gains[key])), "Intermediate stat gains sum exactly: " + key)
	var capped = _fresh("cap")
	capped.data.level = 49
	capped.data.xp = Balance.xp_for_level(49) - 1
	var cap_reward: Dictionary = capped.reward_match(_summary(capped))
	_check(capped.data.level == 50 and capped.data.xp == 0 and capped.data.cap_xp > 0, "Entering level cap preserves excess in cap XP")
	_check(cap_reward.player.levels_gained == 1 and cap_reward.player.at_max_level and capped.xp_needed() == 0, "Cap accurately reported")
	var at_cap_stats: Dictionary = Catalog.stats_for(capped.data)
	var total_before: int = capped.data.total_xp
	var points_before: int = capped.data.points
	cap_reward = capped.reward_match(_summary(capped, "rival"))
	_check(capped.data.level == 50 and capped.data.points == points_before and Catalog.stats_for(capped.data) == at_cap_stats, "At cap no new levels or permanent stat changes")
	_check(capped.data.total_xp == total_before + cap_reward.player.xp_gained and cap_reward.player.xp_gained > 0, "At cap earned XP remains visible in lifetime XP")
	var empty: Dictionary = profile.reward_match({"battle_id": "bad", "winner": "nobody"})
	_check(empty.xp_gained == 0, "Invalid terminal summary rejected")

func _farming() -> void:
	var profile = _fresh("surrender")
	profile.data.xp = 54
	var rival: Dictionary = profile.make_rival()
	var reward: Dictionary = profile.reward_match(_summary(profile, "rival", "surrender", 0.1, rival))
	_check(reward.player.xp_gained == 1 and reward.player.level_after == 2, "Instant surrender gives nonzero XP and can level up")
	_check(reward.rival.xp_gained == 40, "Winner of surrender receives normal victory XP")
	_check(profile.data.surrenders == 1 and profile.data.losses == 1 and profile.data.matches == 1, "Surrender recorded as distinct loss")
	_check(profile.history[0].reason == "surrender" and profile.seconds_until_next_match() > 0.0, "Surrender reason and replay cooldown visible")
	var previous_xp: int = Balance.reward_base(2, "surrender")
	for i in range(10):
		reward = profile.reward_match(_summary(profile, "rival", "surrender", 8.0, rival))
		_check(reward.player.xp_gained >= 1 and reward.player.xp_gained <= previous_xp, "Repeated surrender XP decreases but never zero")
		previous_xp = reward.player.xp_gained
	_check(previous_xp == 1, "Repeated surrender floor is minimal XP")
	_check(profile.seconds_until_next_match() <= float(Balance.XP.surrender_cooldown) + 0.01, "Surrender cooldown bounded")
	var farm = _fresh("opponent_farm")
	var fixed: Dictionary = farm.make_rival()
	var fourth_multiplier: float = 1.0
	for i in range(7):
		reward = farm.reward_match(_summary(farm, "player", "normal", 35.0, fixed))
		if i == 3:
			fourth_multiplier = reward.reward_multiplier
	_check(fourth_multiplier < 1.0 and reward.reward_multiplier >= float(Balance.XP.repeat_opponent_floor), "Repeated opponent penalty bounded")
	var short = _fresh("short")
	reward = short.reward_match(_summary(short, "player", "normal", 1.0))
	_check(reward.player.xp_gained < Balance.reward_base(1, "win") and reward.player.xp_gained > 0, "Extremely short normal match penalized")
	var opponent_surrenders = _fresh("npc_surrenders")
	reward = opponent_surrenders.reward_match(_summary(opponent_surrenders, "player", "surrender", 0.1))
	_check(reward.player.xp_gained == 40 and reward.rival.xp_gained == 1, "Opposing surrender preserves player win and nonzero rival XP")

func _matchmaking() -> void:
	var profile = _fresh("matchmaking")
	var first: Dictionary = profile.make_rival()
	_check(first == profile.make_rival(), "Opponent stable without progression changes")
	_check(first.has_all(["character_id", "name", "level", "stats", "combat_stats", "ability", "signature", "opponent_id", "power", "matchmaking"]), "Complete opponent combat descriptor")
	var ids: Dictionary = {}
	for level in [1, 5, 20, 50]:
		profile.data.level = level
		for match_count in range(22):
			profile.data.matches = match_count
			var opponent: Dictionary = profile.make_rival()
			_check(absi(int(opponent.level) - level) <= 2, "Matchmaking level gap bounded")
			_check(float(opponent.matchmaking.power_gap) >= 0.0 and float(opponent.power) > 0.0, "Power consulted for opponent selection")
			ids[opponent.character_id] = true
	_check(ids.size() >= 5, "Power matching preserves roster variety")

func _history() -> void:
	var profile = _fresh("history")
	var first: Dictionary = _summary(profile)
	profile.reward_match(first)
	for i in range(Balance.HISTORY_LIMIT + 2):
		profile.reward_match(_summary(profile, "player" if i % 2 == 0 else "rival"))
	_check(profile.history.size() == Balance.HISTORY_LIMIT, "History bounded without losing reward ledger")
	_check(profile.reward_match(first).duplicate, "Old battle remains idempotent after history eviction")
	var reloaded = Profile.new()
	reloaded.load_save(profile._save_path)
	_check(_equivalent(reloaded.history, profile.history), "History round-trips at stored JSON precision")
	_check(reloaded.opponents == profile.opponents, "NPC progress round-trip")
	_check(reloaded.reward_match(first).duplicate, "Evicted battle ledger still persists")

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
