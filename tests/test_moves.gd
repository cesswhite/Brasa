extends SceneTree
## Move catalog, authoritative anticipation/impact/recovery, AI, caps and Signature regressions.
## All combatants are in memory; this suite never opens a player save.
const Battle = preload("res://scripts/combat_engine.gd")
const Moves = preload("res://scripts/move_catalog.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Balance = preload("res://scripts/balance.gd")
const Rules = preload("res://scripts/combat_rules.gd")
const Effects = preload("res://scripts/status_effects.gd")
var checks := 0
var failures := 0

func _init() -> void:
	_catalog()
	_timing()
	_cooldowns()
	_perks_and_bounds()
	_counters_and_stance()
	_signature_arming()
	_combo_counts_attacks()
	_ai_variety()
	print("MOVES: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("MOVE FAIL: "+message)

func fighter(id: String = "luma", level: int = 25) -> Dictionary:
	var base_id: String = "mugo" if id=="ascua" else ("sira" if id=="vespera" else id)
	var definition: Dictionary = Catalog.definition(base_id)
	var result: Dictionary = {"character_id":base_id,"name":id,"level":level,"stats":definition.training_base.duplicate(true),"ability":definition.ability.duplicate(true),"signature":definition.signature.duplicate(true)}
	result["combat_stats"] = Catalog.stats_for(result)
	if id in ["ascua","vespera"]: result["story_boss_id"] = id
	return result

func simulate(a: Dictionary,b: Dictionary,seed_value: int,delta: float = 60.0,options: Dictionary = {}) -> Dictionary:
	var engine = Battle.new()
	engine.start(a,b,seed_value,options)
	while engine.running: engine.advance(delta)
	return engine.summary()

func _catalog() -> void:
	var ids: Array[String] = []
	ids.assign(Catalog.IDS)
	ids.append_array(["ascua","vespera"])
	var unique: Dictionary = {}
	for id: String in ids:
		var rows: Array = Moves.moves_for(id)
		check(rows.size()==5,id+": five usable moves")
		check(Moves.unlocked_moves(id,1).size()==2,id+": two functional starting moves")
		check(Moves.unlocked_moves(id,5).size()==3 and Moves.unlocked_moves(id,12).size()==4 and Moves.unlocked_moves(id,20).size()==5,id+": staggered move unlocks")
		check(Moves.perks_for(id).size()==6,id+": six perk alternatives for three slots")
		var purposes: Dictionary = {}
		for move: Dictionary in rows:
			check(move.has_all(["id","name","type","description","purpose","risk","unlock_level","max_tier","upgrade_description","cost","windup","travel","recovery","movement","animation_type","weight","cooldown"]),id+": complete data and presentation contract")
			check(not unique.has(move.id),"Move IDs remain unique")
			unique[move.id] = true
			purposes[move.type] = true
			check(move.type!="signature" and move.id!="signature","Signature is never part of normal weighted moves")
			check(float(move.windup)>0 and float(move.recovery)>0 and is_equal_approx(move.impact_delay,move.windup+move.travel),"Every move has real anticipation and recovery")
			check(int(move.max_tier)==2 and int(move.cost)==1,"Move progression has bounded tiers and explicit cost")
			var upgraded: Dictionary = Moves.resolve_move(id,move.id,99,[])
			check(int(upgraded.tier)==2 and upgraded.recovery<move.recovery,"Excess upgrade tiers are capped")
			if move.type in ["guard","counter"]:
				check(upgraded.stance.reduction>move.stance.reduction,"Defensive upgrade has a real defensive benefit")
			else:
				check(upgraded.damage_multiplier>move.damage_multiplier,"Attack upgrade has a modest real benefit")
		check(purposes.size()>=4,id+": moves have distinct mechanical purposes")
	var copy: Array = Moves.moves_for("nima")
	copy[0].damage_multiplier = 100
	check(Moves.moves_for("nima")[0].damage_multiplier<2,"Returned move definitions cannot mutate the catalog cache")
	check(Moves.moves_for("unknown").is_empty() and Moves.resolve_move("nima","unknown").is_empty(),"Unknown identities and move IDs have no invented definitions")

func _timing() -> void:
	var a: Dictionary = fighter("kiro")
	a.ability = {"id":"none"}
	var charge: Dictionary = Moves.moves_for("kiro")[2]
	charge.cooldown = 0
	a["moves"] = [charge]
	var b: Dictionary = fighter("mugo")
	b.ability = {"id":"none"}
	var engine = Battle.new()
	engine.start(a,b,455,{"opening_time":0.2,"disable_signatures":true})
	engine._fighters.rival.next_action = 20.0
	var untouched: Array = [a.duplicate(true),b.duplicate(true)]
	var hp_before: float = engine.rival_hp
	var events: Array = engine.advance(0.2)
	check(events.any(func(event: Dictionary): return event.type=="move_started"),"At action time the engine begins anticipation")
	check(engine.rival_hp==hp_before and engine._metrics.player.attacks==0,"Anticipation never applies damage early")
	check(engine.snapshot().fighters.player.move_phase=="windup","Snapshot exposes preparation phase")
	var impact_at: float = float(engine._fighters.player.impact_at)
	engine.advance(impact_at-engine.elapsed-0.0001)
	check(engine.rival_hp==hp_before and engine._metrics.player.attacks==0,"Travel remains harmless until actual contact")
	events = engine.advance(0.0002)
	check(engine._metrics.player.attacks==1 and events.any(func(event: Dictionary): return event.type=="attack"),"Exactly one attack resolves at contact")
	check(engine.snapshot().fighters.player.move_phase=="recovery","Impact begins recovery")
	var recovery_at: float = float(engine._fighters.player.recovery_at)
	check(float(engine._fighters.player.next_action)>=recovery_at,"Next action cannot begin before recovery")
	events = engine.advance(recovery_at-engine.elapsed+0.0001)
	check(events.any(func(event: Dictionary): return event.type=="move_recovered"),"Recovery has a scheduled completion event")
	check(a==untouched[0] and b==untouched[1],"Runtime move actions do not mutate source profiles")
	var canceled = Battle.new()
	canceled.start(a,b,455,{"opening_time":0.2,"disable_signatures":true})
	canceled.advance(0.21)
	var before_surrender: float = canceled.rival_hp
	canceled.surrender("player")
	check(canceled.advance(60).is_empty() and canceled.rival_hp==before_surrender,"Surrender cancels pending impacts")
	for id: String in Catalog.IDS:
		var full: Dictionary = simulate(fighter(id),fighter("taro"),894,60,{"disable_signatures":true})
		var stepped: Dictionary = simulate(fighter(id),fighter("taro"),894,0.016,{"disable_signatures":true})
		check(full==stepped,id+": move selection, effects and terminal result are independent of rendering delta")
		var started: Dictionary = {}
		for event: Dictionary in full.events:
			if event.type=="move_started": started[str(event.side)+":"+str(event.move.id)] = event
			elif event.type=="attack":
				var key: String = str(event.side)+":"+str(event.move_id)
				check(started.has(key),"Every normal or counter impact has its own prior anticipation")
				if started.has(key):
					var previous: Dictionary = started[key]
					check(float(event.time)+0.000001>=float(previous.time)+float(previous.impact_delay),"Impact timestamp respects move's anticipation plus travel")

func _cooldowns() -> void:
	var a: Dictionary = fighter("kiro",25)
	a.ability = {"id":"none"}
	a.combat_stats.max_hp = 2000.0
	a.combat_stats.attack = 5.0
	var heavy: Dictionary = Moves.moves_for("kiro")[1]
	heavy.cooldown = 3
	heavy.weight = 8.0
	var quick: Dictionary = Moves.moves_for("kiro")[0]
	quick.weight = 0.01
	a["moves"] = [heavy,quick]
	var b: Dictionary = a.duplicate(true)
	var summary: Dictionary = simulate(a,b,18,60,{"disable_signatures":true})
	var last_action: Dictionary = {}
	var heavy_count := 0
	for event: Dictionary in summary.events:
		if event.type!="move_started" or event.get("counter",false): continue
		if str(event.move.id)!=str(heavy.id): continue
		heavy_count += 1
		if last_action.has(event.side):
			check(int(event.action)-int(last_action[event.side])>=4,"Three-action cooldown requires three other own actions")
		last_action[event.side] = int(event.action)
	check(heavy_count>=4,"Weighted heavy move is used repeatedly after its cooldown")
	var beginner: Dictionary = simulate(fighter("sira",1),fighter("luma",1),899,60,{"disable_signatures":true})
	var allowed: Array[String] = []
	for move: Dictionary in Moves.unlocked_moves("sira",1): allowed.append(move.id)
	for event: Dictionary in beginner.events:
		if event.type=="move_started" and event.side=="player" and not event.get("counter",false):
			check(event.move.id in allowed,"Level-one AI cannot choose a locked move")

func _perks_and_bounds() -> void:
	var a: Dictionary = fighter("nima")
	a["perks"] = ["nima_focus","nima_tempo","nima_instinct"]
	var first: Dictionary = Moves.moves_for("nima")[0]
	var resolved: Dictionary = Moves.resolve_move("nima",first.id,2,a.perks)
	a["moves"] = [resolved]
	a["move_upgrades"] = {first.id:2}
	var engine = Battle.new()
	engine.start(a,fighter(),811,{"disable_signatures":true})
	check(engine._fighters.player.descriptor.moves[0]==resolved,"Pre-resolved descriptor moves never receive upgrades or perks twice")
	var plain: Dictionary = fighter("nima")
	plain["move_upgrades"] = {first.id:2}
	plain["perks"] = a.perks.duplicate()
	engine.start(plain,fighter(),811,{"disable_signatures":true})
	check(engine._fighters.player.descriptor.moves[0]==resolved,"League defaults resolve the same tiers and perks as explicit Story moves")
	var evasion_before: float = engine._runtime("player").evasion
	engine._fighters.player.hp = engine._fighters.player.max_hp*0.30
	check(engine._runtime("player").evasion>evasion_before,"Survival perk activates only below its declared HP threshold")
	var counter: Dictionary = Moves.moves_for("taro")[1]
	var momentum: Dictionary = Moves.resolve_move("taro",counter.id,0,["taro_momentum"])
	check(momentum.stance.multiplier>counter.stance.multiplier,"Counter-specialist momentum improves actual retaliation")
	var malformed: Dictionary = Moves.bound_move({"damage_multiplier":999,"accuracy_modifier":999,"priority":999,"windup":-10,"recovery":-1,"status":"invalid","stance":"invalid","self_status":17,"movement":"invalid"})
	check(malformed.status.is_empty() and malformed.stance.is_empty(),"Malformed nested move data cannot break engine normalization")
	check(malformed.damage_multiplier<=Moves.CONFIG.max_damage_multiplier and malformed.priority<=Moves.CONFIG.max_priority,"Move modifiers respect centralized caps")
	var base: Dictionary = Catalog.stats_for(fighter("sira",50))
	var boosted: Dictionary = Rules.move_stats(base,{"accuracy_modifier":99.0,"critical_chance_modifier":99.0,"critical_damage_modifier":99.0,"base_damage":999.0})
	for key: String in ["attack","accuracy","crit_chance","crit_damage"]:
		check(float(boosted[key])<=float(Balance.STAT_BOUNDS[key][1]),"Move interaction respects existing "+key+" bound")
	var effects: Array = []
	Effects.apply(effects,{"type":"accuracy_up","magnitude":999,"duration":99},"player",0,2000)
	var runtime: Dictionary = Effects.runtime_stats(base,effects)
	check(runtime.accuracy<=Balance.STAT_BOUNDS.accuracy[1],"Status bonuses retain the same stat caps")
	check(Rules.hit_chance(boosted,base)<=Balance.COMBAT.hit_max and Rules.critical_chance(boosted)<=Balance.COMBAT.crit_max,"Final probability caps remain unchanged")

func _counters_and_stance() -> void:
	var engine = Battle.new()
	engine.start(fighter("taro"),fighter("mugo"),981,{"opening_time":20.0,"disable_signatures":true})
	var events: Array[Dictionary] = []
	var hp_before: float = engine.rival_hp
	engine._counter("player","rival",{"id":"counter","name":"Réplica","multiplier":0.5},events)
	check(engine.rival_hp==hp_before and events[1].type=="move_started","Retaliation announces movement before applying damage")
	var delay: float = Moves.CONFIG.counter_windup+Moves.CONFIG.counter_travel
	engine.advance(delay-0.0001)
	check(engine.rival_hp==hp_before,"Counter travel never damages early")
	events = engine.advance(0.0002)
	check(engine.rival_hp<hp_before and engine._metrics.player.counters==1,"Counter lands once after its short anticipation")
	check(engine._metrics.rival.counters==0,"Counters never recursively trigger other counters")
	var seen_stance := false
	var seen_expiration := false
	var reduced_hits := 0
	var counters := 0
	var hits := 0
	for seed_value in range(30,50):
		var guarded: Dictionary = simulate(fighter("taro"),fighter("mugo"),seed_value,60,{"disable_signatures":true})
		counters += int(guarded.metrics.player.counters)
		hits += int(guarded.metrics.rival.hits)
		for event: Dictionary in guarded.events:
			if event.type=="defensive_stance": seen_stance = true
			if event.type=="stance_expired": seen_expiration = true
			if event.type=="attack" and event.get("raw_damage",0)>event.damage and float(event.get("absorbed",0))==0 and event.damage>0: reduced_hits += 1
	check(seen_stance and seen_expiration,"Defensive stances enter and expire on own actions")
	check(reduced_hits>0,"Stances actually reduce incoming damage")
	check(counters>0 and counters<hits,"Counter responses are useful but not guaranteed")
	var fast: Dictionary = Catalog.stats_for(fighter("nima",25))
	var slow: Dictionary = Catalog.stats_for(fighter("mugo",25))
	check(Rules.counter_chance(0.4,fast,slow)>Rules.counter_chance(0.4,slow,fast),"Counter probability responds to the same speed and accuracy stats")
	check(Rules.counter_chance(99,fast,slow)<=Moves.CONFIG.max_counter_chance,"Counter chance stays capped")

func _signature_arming() -> void:
	var engine = Battle.new()
	var reference := RandomNumberGenerator.new()
	var a: Dictionary = fighter("luma",25)
	var b: Dictionary = fighter("nima",25)
	for seed_value in range(1,301):
		reference.seed = seed_value
		engine.start(a,b,seed_value)
		for side: String in ["player","rival"]:
			# EXACT original sequence: one match-start roll, trigger turn and opening roll.
			var armed: bool = reference.randf()<float(Balance.SIGNATURE.chance)
			var signature_turn: int = reference.randi_range(Balance.SIGNATURE.min_turn,Balance.SIGNATURE.max_turn)
			reference.randf_range(Balance.COMBAT.opening_min,Balance.COMBAT.opening_max)
			check(bool(engine._fighters[side].signature_armed)==armed,"Existing match-level Signature arming remains exactly seed-compatible")
			check(int(engine._fighters[side].signature_turn)==signature_turn,"Existing Signature trigger-turn draw remains unchanged")
	var result: Dictionary = simulate(a,b,32,60,{"disable_signatures":true})
	check(result.metrics.player.signatures==0 and result.metrics.rival.signatures==0,"Many moves cannot create new Signature chances during a match")
	result = simulate(a,b,32,60,{"force_signature":["player","rival"],"signature_turn":2})
	check(result.metrics.player.signatures==1 and result.metrics.rival.signatures==1,"A full moveset still executes at most one armed Signature per fighter")
	for event: Dictionary in result.events:
		if event.type=="attack" and event.get("signature",false):
			check(event.result=="signature" and event.move_id=="signature","Signature remains its own guaranteed strike, separate from upgraded moves")

func _combo_counts_attacks() -> void:
	var guards := 0
	var misses := 0
	for seed_value in range(1,31):
		for force_signature: bool in [false,true]:
			var result: Dictionary = simulate(fighter("nima",20),fighter("mugo",20),seed_value,60,{"disable_signatures":not force_signature,"force_signature":"player" if force_signature else [],"signature_turn":2})
			var attack_count := 0
			var combo_pending := false
			for event: Dictionary in result.events:
				if event.get("side","") != "player": continue
				if event.type=="defensive_stance": guards += 1
				if event.type=="ability" and event.get("ability_id","")=="combo": combo_pending = true
				if event.type=="attack" and not event.get("counter",false):
					attack_count += 1
					if event.result in ["miss","dodge"]: misses += 1
					var expected: bool = attack_count%3==0 and not bool(event.get("signature",false))
					check(combo_pending==expected,"Nima combo counts attack attempts; guards and reactions do not consume the third attack")
					combo_pending = false
			check(attack_count==int(result.metrics.player.attacks),"Combo attack count includes Signature but excludes passive counter reactions")
	check(guards>0 and misses>0,"Combo regression exercises defensive actions and missed attacks")

func _ai_variety() -> void:
	var total_used: Dictionary = {}
	for id: String in Catalog.IDS:
		var used: Dictionary = {}
		for seed_value in range(200,210):
			var result: Dictionary = simulate(fighter(id,30),fighter("luma",30),seed_value,60,{"disable_signatures":true})
			for key: String in result.metrics.player.move_uses: used[key] = true
		for move: Dictionary in Moves.moves_for(id):
			check(used.has(move.id),id+": contextual AI uses "+str(move.name)+" across seeded matches")
		total_used[id] = used.size()
	var engine = Battle.new()
	engine.start(fighter("mugo"),fighter(),615,{"disable_signatures":true})
	var normal := 0
	var desperate := 0
	for index in range(600):
		if str(engine._select_move("player").type) in ["guard","counter"]: normal += 1
	engine._fighters.player.hp = engine.player_max_hp*0.20
	engine._rng.seed = 616
	for index in range(600):
		if str(engine._select_move("player").type) in ["guard","counter"]: desperate += 1
	check(desperate>normal,"AI increases defensive choices at low HP without becoming deterministic")
	print("Move usage across nine identities: ",total_used)
