extends SceneTree
## Reproducible read-only export of the existing GDScript domain.
const Characters = preload("res://scripts/character_catalog.gd")
const Moves = preload("res://scripts/move_catalog.gd")
const Balance = preload("res://scripts/balance.gd")
const Story = preload("res://scripts/story_catalog.gd")
const Campaign = preload("res://scripts/campaign_config.gd")
const Effects = preload("res://scripts/status_effects.gd")

func _init() -> void:
	var characters: Dictionary = {}
	var moves: Dictionary = {}
	var perks: Dictionary = {}
	for id: String in Characters.IDS:
		characters[id] = Characters.definition(id)
	for id: String in Characters.IDS + ["ascua", "vespera"]:
		moves[id] = Moves.moves_for(id)
		perks[id] = Moves.perks_for(id)
	var stages: Array[Dictionary] = []
	for global_level: int in range(1, 101):
		var stage: Dictionary = Story.global_stage(global_level)
		var chapter_number: int = Story.chapter_for_level(global_level)
		var chapter: Dictionary = Story.chapter(chapter_number)
		stage["opponent"] = Story.opponent(global_level - int(chapter.start_level), chapter_number)
		stages.append(stage)
	var sources: Dictionary = {}
	for filename: String in ["balance", "character_catalog", "move_catalog", "combat_engine", "combat_rules", "status_effects", "story_catalog", "campaign_config", "character_families"]:
		sources[filename + ".gd"] = FileAccess.get_sha256("res://scripts/" + filename + ".gd")
	sources["character_families.json"] = FileAccess.get_sha256("res://data/character_families.json")
	var result: Dictionary = {
		"schema_version":1, "catalog_version":"brasa-game-v1", "godot_version":Engine.get_version_info().string,
		"source_hashes":sources, "character_ids":Characters.IDS, "characters":characters,
		"moves":moves, "perks":perks, "move_config":Moves.CONFIG, "move_types":Moves.TYPES, "movement":Moves.MOVEMENT,
		"unlock_levels":Moves.UNLOCK_LEVELS, "max_move_tier":Moves.MAX_TIER, "move_upgrade_cost":Moves.UPGRADE_COST,
		"balance":{"max_level":Balance.MAX_LEVEL,"soft_level":Balance.LEVEL_SOFT_CAP,"growth_after_soft":Balance.GROWTH_AFTER_SOFT_CAP,"training_cap":Balance.TRAINING_CAP,"initial_points":Balance.INITIAL_POINTS,"points_per_level":Balance.POINTS_PER_LEVEL,"combat":Balance.COMBAT,"signature":Balance.SIGNATURE,"status":Balance.STATUS,"xp":Balance.XP,"matchmaking":Balance.MATCHMAKING,"stat_bounds":Balance.STAT_BOUNDS,"training":Balance.TRAINING_EFFECTS},
		"effects":{"dot_types":Effects.DOT_TYPES,"positive_types":Effects.POSITIVE_TYPES,"names":Effects.NAMES},
		"campaign":{"chapters":Campaign.CHAPTERS,"stages":stages,"variants":Campaign.VARIANTS,"bosses":Campaign.BOSSES,"allocations":Story.ALLOCATIONS,"config":Story.CONFIG,"move_token_levels":Campaign.MOVE_TOKEN_LEVELS,"perk_levels":Campaign.PERK_LEVELS,"max_perks":Campaign.MAX_PERKS,"replay_xp":Campaign.REPLAY_XP,"loss_xp_floor":Campaign.LOSS_XP_FLOOR,"loss_xp_decay":Campaign.LOSS_XP_DECAY,"opponent_policy":"Fixed exported run_seed=0 variants; legacy local run-seeded selection is not reimplemented."}}
	var path: String = "res://backend/data/game-catalog.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write game catalog")
		quit(1)
		return
	file.store_string(JSON.stringify(result, "\t", true, true) + "\n")
	file.close()
	print("GAME_CATALOG_EXPORTED ", FileAccess.get_sha256(path))
	quit(0)
