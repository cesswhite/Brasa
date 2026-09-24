extends SceneTree
## Real paired sprite geometry, independent of the simulation and player saves.
## Godot --headless --path outputs/Brasa --script res://tests/test_fighter_contact.gd
## Optional -- --report=/absolute/work/path.json. No fixture opens Main or a save.
const Fighter = preload("res://scripts/fighter_view.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Cosmetics = preload("res://scripts/cosmetic_catalog.gd")
const Families = preload("res://scripts/character_families.gd")
const Story = preload("res://scripts/story_catalog.gd")
const Moves = preload("res://scripts/move_catalog.gd")
const Battle = preload("res://scripts/combat_engine.gd")
const Layout = preload("res://scripts/ui/battle_layout.gd")
const FX = preload("res://scripts/combat_fx.gd")
const SIZES: Array[Vector2] = [Vector2(1360,880),Vector2(1224,792),Vector2(1920,1080),Vector2(768,1024),Vector2(390,844),Vector2(430,932),Vector2(844,390)]
var checks := 0
var failures := 0
var cases := 0
var issues: Array[String] = []
var samples: Array[Dictionary] = []
var baseline_observations: Array[Dictionary] = []
var bodies_tested: Dictionary = {}
var types_tested: Dictionary = {}
var sources_before: Dictionary = {}
var special_moves: Dictionary = {}

func _init() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	checks += 1
	if ok: return
	failures += 1
	issues.append(message)
	if issues.size() <= 60: push_error("FIGHTER CONTACT: " + message)

func _run() -> void:
	sources_before = _source_hashes()
	var api = Fighter.new()
	_check(api.has_method("get_contact_state"), "paired-contact diagnostic API is installed")
	api.free()
	if failures > 0:
		_finish()
		return
	special_moves = _recorded_special_moves()
	var definitions: Array[Dictionary] = Catalog.all_definitions()
	definitions.append(Story.boss_definition(1))
	definitions.append(Story.boss_definition(2))
	for body_id: String in Families.individuals():
		var definition: Dictionary = Cosmetics.body_definition(body_id)
		definition["appearance"] = Cosmetics.default_appearance(str(definition.id))
		definition.appearance.body_style_id = body_id
		definitions.append(definition)
	for index in range(definitions.size()):
		var pair := _pair(definitions[index], definitions[(index+5)%definitions.size()])
		for size: Vector2 in SIZES:
			_apply_layout(pair,size)
			for side: String in ["left","right"]:
				var actor = pair[side]
				var defender = pair.right if side == "left" else pair.left
				var rows: Array[Dictionary] = []
				# Boss visuals can retain a gameplay archetype; the definition ID identifies its moves.
				if side == "left": rows = Moves.moves_for(str(definitions[index].id))
				else: rows = Moves.moves_for(str(definitions[(index+5)%definitions.size()].id))
				if not special_moves.get("signature",{}).is_empty(): rows.append(special_moves.signature)
				for move: Dictionary in rows:
					_test_move(pair,actor,defender,move,size)
		pair.parent.free()
	_test_resize_and_pause()
	_test_overlap_and_order()
	_test_double_ko()
	_test_legacy_reduced_and_lifetime()
	_test_terminal_continuity()
	_test_cosmetic_body()
	_finish()

func _pair(left_definition: Dictionary, right_definition: Dictionary) -> Dictionary:
	var parent := Node2D.new()
	root.add_child(parent)
	var left = Fighter.new()
	parent.add_child(left)
	var middle := Node2D.new()
	parent.add_child(middle)
	var right = Fighter.new()
	parent.add_child(right)
	var effects = FX.new()
	parent.add_child(effects)
	var hud := Node2D.new()
	parent.add_child(hud)
	left.set_process(false)
	right.set_process(false)
	effects.set_process(false)
	left.setup_character(left_definition,1)
	right.setup_character(right_definition,-1)
	left.reset_pose()
	right.reset_pose()
	return {"parent":parent,"left":left,"right":right,"middle":middle,"effects":effects,"hud":hud}

func _apply_layout(pair: Dictionary, size: Vector2) -> void:
	var r: Dictionary = Layout.calculate(size,true)
	pair.left.position = r.player_at
	pair.right.position = r.rival_at
	pair.left.scale = Vector2.ONE * float(r.actor_scale)
	pair.right.scale = Vector2.ONE * float(r.actor_scale)
	var limit := (Vector2(r.rival_at).x-Vector2(r.player_at).x)/(2.0*float(r.actor_scale))-6.0
	pair.left.set_combat_lane(limit,pair.right)
	pair.right.set_combat_lane(limit,pair.left)
	pair["layout"] = r
	pair["limit"] = limit

func _painted(actor) -> Rect2:
	# Source alpha bounds and the actual Sprite2D transform; no contact helper formula.
	var sprite: Sprite2D = actor.get_node("IllustratedFighter")
	var frame: Dictionary = actor._current_frame()
	var bounds := Rect2(frame.get("bounds",Rect2i()))
	var transform: Transform2D = sprite.global_transform
	var result := Rect2(transform * (bounds.position+sprite.offset),Vector2.ZERO)
	for point: Vector2 in [Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)]:
		result = result.expand(transform * (point+sprite.offset))
	return result

func _root_state(actor) -> Array:
	return [actor.position,actor.scale,actor.rotation,actor.facing,actor.z_index]

func _same_root(actor, expected: Array, label: String) -> void:
	_check(_root_state(actor) == expected,label+": root, facing, scale and z-index remain unchanged")

func _test_move(pair: Dictionary, actor, defender, move: Dictionary, size: Vector2) -> void:
	cases += 1
	actor.reset_pose()
	defender.reset_pose()
	var source := JSON.stringify(move)
	var actor_root := _root_state(actor)
	var defender_root := _root_state(defender)
	var neutral_target := _painted(defender)
	var scale: float = actor.scale.x
	var label := "%s→%s %s %dx%d facing%d" % [actor.get_animation_state().body_id,defender.get_animation_state().body_id,move.id,int(size.x),int(size.y),actor.facing]
	bodies_tested[str(actor.get_animation_state().body_id)] = true
	types_tested[str(move.type)] = true
	var impact := float(move.windup)+float(move.travel)
	var offensive := not str(move.type) in ["guard","counter"]
	actor.play_move(move,float(move.windup)*0.6)
	var preparation: Dictionary = actor.get_contact_state()
	_check(not bool(preparation.active) and Vector2(preparation.offset).length()<0.01,label+": anticipation has no paired advance")
	_same_root(actor,actor_root,label)
	actor.play_move(move,impact)
	var contact: Dictionary = actor.get_contact_state()
	_check(is_equal_approx(actor._action_time,impact),label+": presentation retains authoritative contact time")
	_check(bool(contact.paired),label+": opponent stays paired")
	_same_root(actor,actor_root,label)
	_same_root(defender,defender_root,label+" defender")
	var painted := _painted(actor)
	if offensive:
		_check(bool(contact.active),label+": offensive contact enables paired presentation")
		var gap: float = neutral_target.position.x-painted.end.x if actor.facing > 0 else painted.position.x-neutral_target.end.x
		var penetration: float = maxf(0.0,-gap)/maxf(1.0,neutral_target.size.x)
		_check(gap<=8.0*scale,label+": painted attack reaches the opponent (gap %.2f world px)" % (gap/scale))
		_check(penetration<=0.80,label+": overlap is bounded (%.1f%% of neutral target width)" % (penetration*100.0))
		_check(painted.position.y<neutral_target.end.y and painted.end.y>neutral_target.position.y,label+": visible bodies overlap vertically at contact")
		_check(neutral_target.grow(12.0*scale).has_point(Vector2(contact.target)),label+": target belongs to the neutral opponent silhouette")
		samples.append({"case":label,"gap_world":gap/scale,"penetration_fraction":penetration,"anchor_source":contact.get("anchor_source","")})
	else:
		_check(not bool(contact.active) and Vector2(contact.offset).length()<0.01,label+": guard/counter stance does not lunge")
	var viewport := Rect2(Vector2.ZERO,size)
	_check(viewport.grow(1.0).encloses(painted),label+": painted attack remains inside viewport")
	_check(not painted.intersects(pair.layout.primary),label+": painted attack leaves primary controls clear")
	var hud_clear := not painted.intersects(pair.layout.hud_player) and not painted.intersects(pair.layout.hud_rival)
	if not hud_clear:
		actor.set_combat_lane(float(pair.limit))
		var legacy_painted := _painted(actor)
		actor.set_combat_lane(float(pair.limit),defender)
		var observation := {"case":label,"hud_overlap":true,"paired_bounds":str(painted),"unpaired_bounds":str(legacy_painted),"hud_player":str(pair.layout.hud_player),"hud_rival":str(pair.layout.hud_rival)}
		if painted.is_equal_approx(legacy_painted):
			# Whole-HUD bounding boxes include padding. Record existing guard silhouette
			# intersections separately; this feature must not add or worsen them.
			baseline_observations.append(observation)
			hud_clear = true
		else: samples.append(observation)
	_check(hud_clear,label+": paired translation adds no HUD intersection")
	actor._process(float(move.recovery)+0.10)
	_check(actor._mode == "idle",label+": recovery returns to idle")
	var settled := _painted(actor)
	actor.set_combat_lane(float(pair.limit))
	_check(_painted(actor).is_equal_approx(settled),label+": recovery matches the same idle pose without paired translation")
	actor.set_combat_lane(float(pair.limit),defender)
	_check(not bool(actor.get_contact_state().active),label+": recovery clears contact state")
	_same_root(actor,actor_root,label+" recovered")
	_check(JSON.stringify(move)==source,label+": move dictionary remains immutable")
	_check(pair.effects.get_index()>pair.left.get_index() and pair.effects.get_index()>pair.right.get_index(),label+": combat FX remain above both fighters")
	_check(pair.middle.get_index()==1 and pair.hud.get_index()==4,label+": unrelated siblings retain their indices")

func _test_resize_and_pause() -> void:
	var pair := _pair(Catalog.definition("nima"),Story.boss_definition(1))
	var move: Dictionary = Moves.moves_for("nima")[0]
	var impact := float(move.impact_delay)
	_apply_layout(pair,SIZES[0])
	pair.left.play_move(move,float(move.windup)+float(move.travel)*0.5)
	var original_time: float = pair.left._action_time
	for size: Vector2 in SIZES:
		_apply_layout(pair,size)
		var root_state := _root_state(pair.left)
		var once := _painted(pair.left)
		var once_state: Dictionary = pair.left.get_contact_state()
		_apply_layout(pair,size)
		_check(_painted(pair.left).is_equal_approx(once),"resize: repeated pairing is geometrically idempotent at "+str(size))
		_check(is_equal_approx(pair.left._action_time,original_time),"resize: does not restart move time at "+str(size))
		_check(Rect2(Vector2.ZERO,size).grow(1).encloses(once),"resize: travel remains in viewport at "+str(size))
		once = _painted(pair.left)
		once_state = pair.left.get_contact_state()
		pair.left.motion_paused = true
		pair.left._process(0.50)
		_check(_painted(pair.left).is_equal_approx(once) and pair.left.get_contact_state()==once_state,"pause: target and painted position remain frozen")
		_check(is_equal_approx(pair.left._action_time,original_time),"pause: move timeline remains frozen")
		pair.left.motion_paused = false
		_same_root(pair.left,root_state,"resize/pause")
	pair.left.move_impact(false,str(move.id))
	var target: Vector2 = pair.left.get_contact_state().target
	var rival_move: Dictionary = Moves.moves_for("ascua")[0]
	pair.right.play_move(rival_move,float(rival_move.impact_delay))
	pair.left._process(0.0)
	_check(Vector2(pair.left.get_contact_state().target).is_equal_approx(target),"simultaneous: target remains neutral rather than chasing the moving rival")
	_check(_painted(pair.left).position.is_finite() and _painted(pair.left).size.is_finite(),"simultaneous: contact remains finite while the rival also approaches")
	_check(is_equal_approx(pair.left._action_time,impact),"simultaneous: refreshing geometry does not change elapsed time")
	pair.left._process(float(move.recovery)*0.5)
	var recovery_time: float = pair.left._action_time
	_apply_layout(pair,SIZES[0])
	_check(is_equal_approx(pair.left._action_time,recovery_time),"resize during recovery preserves its clock")
	pair.left._process(1.0)
	_check(not bool(pair.left.get_contact_state().active) and pair.left._mode=="idle","resized recovery clears paired advance")
	pair.parent.free()

func _test_overlap_and_order() -> void:
	var pair := _pair(Catalog.definition("taro"),Catalog.definition("bruma"))
	_apply_layout(pair,Vector2(390,844))
	var own: Dictionary = Moves.moves_for("taro")[2]
	var other: Dictionary = Moves.moves_for("bruma")[0]
	var reaction: Dictionary = special_moves.get("counter",{})
	_check(not reaction.is_empty(),"counter fixture comes from an actual motor event")
	if reaction.is_empty():
		pair.parent.free()
		return
	var before := JSON.stringify([own,other,reaction])
	pair.left.play_move(own,float(own.windup)*0.3)
	var own_time: float = pair.left._action_time
	pair.right.play_move(other,float(other.impact_delay))
	_check(pair.right.get_index()>pair.left.get_index(),"last presented opponent attack is in front")
	pair.left.play_move(reaction,float(reaction.impact_delay))
	_check(is_equal_approx(pair.left._action_time,own_time),"counter overlay cannot fast-forward its scheduled attack")
	_check(str(pair.left._counter_move.get("id",""))==str(reaction.id),"counter has an independent overlapping timeline")
	_check(bool(pair.left.get_contact_state().active),"counter reaction reaches with its own contact presentation")
	_check(pair.left.get_index()>pair.right.get_index(),"latest counter presentation takes foreground")
	pair.right._process(0.0)
	pair.left._process(0.0)
	_check(pair.left.get_index()>pair.right.get_index(),"ordinary pose updates cannot steal event-based foreground priority")
	pair.right.move_impact(false,str(other.id))
	_check(pair.right.get_index()>pair.left.get_index(),"latest impact wins simultaneous event priority")
	pair.left.move_impact(false,str(reaction.id))
	_check(pair.left.get_index()>pair.right.get_index(),"counter impact can regain foreground without changing scheduled time")
	_check(is_equal_approx(pair.left._action_time,own_time),"counter contact leaves normal windup time intact")
	_check(pair.effects.get_index()==3 and pair.middle.get_index()==1 and pair.hud.get_index()==4,"depth swaps only the two fighter slots, never FX or UI")
	_check(JSON.stringify([own,other,reaction])==before,"overlapping move source events remain immutable")
	pair.left._process(2.0)
	pair.right._process(2.0)
	_check(not bool(pair.left.get_contact_state().active) and not bool(pair.right.get_contact_state().active),"both overlapping movements settle without sticky offset")
	pair.parent.free()

func _test_legacy_reduced_and_lifetime() -> void:
	var pair := _pair(Catalog.definition("tepa"),Catalog.definition("nima"))
	_apply_layout(pair,Vector2(390,844))
	var move: Dictionary = Moves.moves_for("tepa")[0]
	for phase: float in [0.0,float(move.windup)*0.6,float(move.impact_delay),float(move.impact_delay)+float(move.recovery)*0.5]:
		pair.left.reduced_motion = true
		pair.left.play_move(move,phase)
		var paired := _painted(pair.left)
		var state: Dictionary = pair.left.get_contact_state()
		pair.left.set_combat_lane(float(pair.limit))
		_check(_painted(pair.left).is_equal_approx(paired),"reduced motion: pairing adds no translation in any phase")
		_check(Vector2(state.offset).length()<0.01,"reduced motion: no hidden paired displacement")
		pair.left.set_combat_lane(float(pair.limit),pair.right)
	pair.left.reduced_motion = false
	pair.left.set_combat_lane(float(pair.limit))
	pair.left.play_move(move,float(move.impact_delay))
	var unpaired := _painted(pair.left)
	var local: Rect2 = pair.left.painted_bounds_local()
	_check(local.end.x<=float(pair.limit)+0.01,"unpaired legacy mode retains the lane bound")
	_check(not bool(pair.left.get_contact_state().paired),"omitting opponent clears the optional pair")
	pair.left.set_combat_lane(float(pair.limit),pair.right)
	_check(_painted(pair.left).end.x>unpaired.end.x+1.0,"paired contact visibly reaches farther than separated legacy lanes")
	pair.right.free()
	pair.left._process(0.0)
	_check(not bool(pair.left.get_contact_state().paired),"freed opponent is handled without a dangling reference")
	_check(_painted(pair.left).is_equal_approx(unpaired),"freed opponent safely falls back to the legacy lane")
	pair.parent.free()

func _test_cosmetic_body() -> void:
	var definition: Dictionary = Catalog.definition("mugo")
	definition["appearance"] = {"body_style_id":"tepa","palette_id":"original","aura_id":"none","trail_id":"none","victory_pose_id":"classic","intro_animation_id":"classic"}
	var source := JSON.stringify(definition)
	var pair := _pair(definition,Catalog.definition("onix"))
	_apply_layout(pair,Vector2(390,844))
	_check(str(pair.left.get_animation_state().body_id)=="tepa","cosmetic body is independent of gameplay archetype")
	_test_move(pair,pair.left,pair.right,Moves.moves_for("mugo")[0],Vector2(390,844))
	_check(JSON.stringify(definition)==source,"pairing never mutates cosmetic or character definitions")
	pair.parent.free()

func _test_terminal_continuity() -> void:
	for id: String in ["mugo","nima","tepa","ascua"]:
		var definition: Dictionary = Story.boss_definition(1) if id=="ascua" else Catalog.definition(id)
		var pair := _pair(definition,Catalog.definition("bruma"))
		for size: Vector2 in SIZES:
			_apply_layout(pair,size)
			for side: String in ["left","right"]:
				var actor = pair[side]
				var other = pair.right if side=="left" else pair.left
				var move: Dictionary = Moves.moves_for(id if side=="left" else "bruma")[0]
				for terminal: String in ["fall","victory"]:
					actor.reset_pose()
					other.reset_pose()
					actor.play_move(move,float(move.impact_delay))
					var root_state := _root_state(actor)
					var contact_x: float = actor.get_node("IllustratedFighter").position.x
					var label := "%s %s %s %s" % [id,side,terminal,str(size)]
					actor.resolve_battle(terminal=="victory")
					_check(actor._mode==("victory" if terminal=="victory" else "fall"),label+": actual result selects the terminal mode")
					_check(absf(float(actor.get_node("IllustratedFighter").position.x)-contact_x)<0.01,label+": terminal event does not teleport the drawn origin home")
					for step in range(12):
						actor._process(0.10)
						_check(absf(float(actor.get_node("IllustratedFighter").position.x)-contact_x)<0.01,label+": terminal pose keeps its horizontal location at %.1fs" % ((step+1)*0.1))
					_same_root(actor,root_state,label)
					actor.reset_pose()
					var reset_bounds := _painted(actor)
					actor.set_combat_lane(float(pair.limit))
					_check(_painted(actor).is_equal_approx(reset_bounds),label+": a new round matches unpaired rest, clearing terminal displacement")
					actor.set_combat_lane(float(pair.limit),other)
		pair.parent.free()

func _test_double_ko() -> void:
	var pair := _pair(Catalog.definition("nima"),Catalog.definition("mugo"))
	_apply_layout(pair,Vector2(390,844))
	for initiated: bool in [false,true]:
		pair.left.reset_pose()
		pair.right.reset_pose()
		if initiated:
			for side: String in ["left","right"]:
				var move: Dictionary = Moves.moves_for("nima" if side=="left" else "mugo")[0]
				pair[side].play_move(move,float(move.impact_delay))
		pair.left.resolve_battle(false)
		pair.right.resolve_battle(false)
		var order: Array[int] = [pair.left.get_index(),pair.right.get_index()]
		for step in range(20):
			if step%2==0:
				pair.left._process(0.04)
				pair.right._process(0.04)
			else:
				pair.right._process(0.04)
				pair.left._process(0.04)
			_check(order==[pair.left.get_index(),pair.right.get_index()],"double KO: alternating process order cannot flip depth (attacks=%s)" % initiated)
		_check(pair.effects.get_index()==3 and pair.middle.get_index()==1 and pair.hud.get_index()==4,"double KO: unrelated nodes and FX retain depth")
	pair.parent.free()

func _recorded_special_moves() -> Dictionary:
	var result: Dictionary = {}
	for seed_value in range(1701,1713):
		var engine = Battle.new()
		engine.start({"character_id":"taro","level":25},{"character_id":"mugo","level":25},seed_value,{"force_signature":"player","signature_turn":1,"opening_time":0.1,"battle_id":"contact-presentation-fixture"})
		var events: Array[Dictionary] = engine.advance(60.0)
		for event: Dictionary in events:
			if str(event.get("type",""))!="move_started": continue
			var move: Dictionary = event.get("move",{})
			if str(move.get("type",""))=="signature": result["signature"] = move.duplicate(true)
			if bool(event.get("counter",false)):
				# Main/Replay annotate this copy at the presentation boundary.
				result["counter"] = move.duplicate(true)
				result.counter["is_counter_reaction"] = true
				result.counter["animation_type"] = "dash"
		if result.size()==2: break
	_check(result.has("signature") and result.has("counter"),"motor fixtures provide real Signature and counter events")
	return result

func _finish() -> void:
	var sources_after := _source_hashes()
	_check(sources_before==sources_after,"source code and profile inputs remain unchanged throughout the run")
	_check(bodies_tested.size()==23,"all 15 companions, 2 bosses and 6 family bodies participate")
	var path := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--report="): path = arg.trim_prefix("--report=")
	if not path.is_empty():
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var report := {"suite":"fighter_contact","checks":checks,"failures":failures,"move_cases":cases,"bodies":bodies_tested.keys(),"move_types":types_tested.keys(),"sizes":SIZES.map(func(value: Vector2) -> Array: return [int(value.x),int(value.y)]),"issues":issues,"measurements":samples,"unchanged_baseline_hud_intersections":baseline_observations,"sources_before":sources_before,"sources_after":sources_after,"player_saves_opened":false,"renderer":"headless geometry"}
		var file := FileAccess.open(path,FileAccess.WRITE)
		if file != null: file.store_string(JSON.stringify(report,"\t")+"\n")
	print("FIGHTER CONTACT: %d checks, %d failures; %d paired move cases" % [checks,failures,cases])
	quit(0 if failures==0 else 1)

func _source_hashes() -> Dictionary:
	var result: Dictionary = {}
	for path: String in ["res://scripts/fighter_view.gd","res://scripts/fighter_animation_set.gd","res://scripts/character_visual_profile.gd","res://data/character_visual_profiles.json","res://scripts/ui/battle_layout.gd","res://scripts/character_catalog.gd","res://scripts/move_catalog.gd","res://scripts/combat_engine.gd","res://scripts/cosmetic_catalog.gd","res://scripts/character_families.gd","res://data/character_families.json","res://tests/test_fighter_contact.gd"]:
		result[path] = FileAccess.get_sha256(path)
	return result
