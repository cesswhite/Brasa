extends SceneTree
const Combat = preload("res://scripts/combat_engine.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Story = preload("res://scripts/story_catalog.gd")
const Moves = preload("res://scripts/move_catalog.gd")
var cases: Array[Dictionary] = []
func fighter(id: String, level: int = 20) -> Dictionary:
	var profile: Dictionary = {"character_id":id,"level":level,"allocations":{"max_hp":3,"attack":4,"defense":2,"speed":3,"accuracy":1,"evasion":2,"crit_chance":1,"resistance":2},"move_upgrades":{},"perks":[]}
	if level >= 12:
		profile.perks = [Moves.perks_for(id)[0].id, Moves.perks_for(id)[4].id]
		for move: Dictionary in Moves.unlocked_moves(id,level): profile.move_upgrades[move.id] = 1
	profile["combat_stats"] = Story.stats_for(profile)
	return profile
func add_case(label: String, a: Dictionary, b: Dictionary, seed_value: int, options: Dictionary = {}) -> void:
	options = options.duplicate(true)
	options.battle_id = label
	var engine := Combat.new()
	engine.start(a,b,seed_value,options)
	if options.has("surrender_at"):
		engine.advance(float(options.surrender_at))
		engine.surrender(str(options.get("surrender_side","player")))
	else:
		while engine.running: engine.advance(60.0)
	var summary: Dictionary = engine.summary()
	summary.seed = str(seed_value)
	cases.append({"id":label,"player":a,"rival":b,"seed":str(seed_value),"options":options,"expected":summary})
func _init() -> void:
	var vectors: Array[Dictionary] = []
	for seed_value: int in [0,1,2,77,7651,4294967295,9007199254740993,9223372036854775807,-1]:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var values: Array[Dictionary] = []
		for index in range(40):
			values.append({"randi":rng.randi(),"randf":rng.randf(),"range":rng.randf_range(1.8,2.3),"bounded":rng.randi_range(2,5),"variance":rng.randf_range(.92,1.08),"wide":rng.randi_range(-1000000000,1147483648)})
		vectors.append({"seed":"18446744073709551615" if seed_value==-1 else str(seed_value),"values":values})
	var stat_cases: Array[Dictionary] = []
	for id: String in Catalog.IDS:
		for level: int in [1,10,25,50]:
			var profile: Dictionary = fighter(id,level)
			stat_cases.append({"profile":profile,"expected":profile.combat_stats})
			for enemy: String in ["luma","taro","iria"]:
				add_case(id+"_"+str(level)+"_"+enemy,profile,fighter(enemy,level),771+level+Catalog.IDS.find(id)*100)
	for global_level: int in range(1,101):
		var stage: Dictionary = Story.global_stage(global_level)
		var chapter: int = Story.chapter_for_level(global_level)
		var opponent: Dictionary = Story.opponent(global_level-int(Story.chapter(chapter).start_level),chapter)
		add_case("story_"+str(global_level),fighter(Catalog.IDS[global_level%Catalog.IDS.size()],int(stage.level)),opponent,9911+global_level)
	for id: String in Catalog.IDS:
		add_case("signature_"+id,fighter(id),fighter("mugo"),551,{"force_signature":"both","signature_turn":2})
	add_case("simultaneous_dot",fighter("luma"),fighter("luma"),178,{"initial_hp":{"player":1,"rival":1},"opening_time":1,"initial_statuses":{"player":[{"type":"poison","magnitude":3,"duration":2}],"rival":[{"type":"burn","magnitude":3,"duration":2}]}})
	add_case("surrender_effects",fighter("iria"),fighter("taro"),981,{"surrender_at":10.0})
	add_case("signature_lethal",fighter("nima"),fighter("mugo"),711,{"initial_hp":{"rival":1},"force_signature":"player","signature_turn":1,"opening_time":2})
	add_case("signature_deadline",fighter("luma"),fighter("luma"),183,{"force_signature":"both","signature_turn":1,"opening_time":59.5})
	add_case("status_stun_slow",fighter("tepa"),fighter("xuna"),531,{"opening_time":1,"initial_statuses":{"player":[{"type":"slow","magnitude":.25,"duration":1},{"type":"stun","magnitude":1,"duration":1}],"rival":[{"type":"healing_down","magnitude":.4,"duration":5}]}})
	var move_cases: Array[Dictionary] = []
	for id: String in Catalog.IDS + ["ascua", "vespera"]:
		var all_perks: Array = Moves.perks_for(id).map(func(perk: Dictionary) -> String: return str(perk.id))
		for move: Dictionary in Moves.moves_for(id):
			for tier: int in [0,1,2]:
				for selection: Array in [[], all_perks.slice(0,3), all_perks.slice(3,6), [all_perks[0],all_perks[2],all_perks[5]]]:
					move_cases.append({"character_id":id,"move_id":move.id,"tier":tier,"perks":selection,"expected":Moves.resolve_move(id,move.id,tier,selection)})
	var data: Dictionary = {"godot_version":Engine.get_version_info().string,"catalog_sha256":FileAccess.get_sha256("res://backend/data/game-catalog.json"),"rng_vectors":vectors,"stats":stat_cases,"moves":move_cases,"battles":cases}
	var file := FileAccess.open("res://backend/tests/fixtures/engine-godot.json.gz",FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_buffer((JSON.stringify(data,"",true,true)+"\n").to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP))
	file.close()
	print("ENGINE_CORPUS_EXPORTED ",cases.size()," battles; ",vectors.size()," RNG sequences")
	quit(0)
