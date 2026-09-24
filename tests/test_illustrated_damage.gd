extends SceneTree
## Safe asset fallback + complete delivery gate. No generation, profile files or rewards.
## Append -- --require-roster when all23 illustrated40-pose packs are installed.
const DamageArt = preload("res://scripts/damage_art.gd")
const Fighter = preload("res://scripts/fighter_view.gd")
const Sequences = preload("res://scripts/fighter_animation_set.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Cosmetics = preload("res://scripts/cosmetic_catalog.gd")
const Families = preload("res://scripts/character_families.gd")
const Story = preload("res://scripts/story_catalog.gd")
const Moves = preload("res://scripts/move_catalog.gd")
const EngineScript = preload("res://scripts/combat_engine.gd")
const Records = preload("res://scripts/battle_identity.gd")
const Replay = preload("res://scripts/ui/battle_replay_panel.gd")
const Layout = preload("res://scripts/ui/battle_layout.gd")
const SIZES: Array[Vector2] = [Vector2(1360,880),Vector2(1224,792),Vector2(1920,1080),Vector2(768,1024),Vector2(390,844),Vector2(430,932),Vector2(844,390)]

class HealthBoundary:
	extends "res://scripts/main.gd"
	# Exercise production event dispatch with real fighters, omitting unrelated UI/awards.
	func _ready() -> void:
		player_view = Fighter.new();add_child(player_view)
		rival_view = Fighter.new();add_child(rival_view)
		player_view.setup_character(Catalog.definition("neris"))
		rival_view.setup_character(Catalog.definition("taro"),-1)
		player_view.set_process(false);rival_view.set_process(false)
		set_process(false)
	func _log_event(_content: String) -> void: pass
	func _handle_move_started(_event: Dictionary) -> void: pass
	func _handle_attack(_event: Dictionary, _generation: int) -> void: pass
	func _effect_feedback(_event: Dictionary) -> void: pass
	func _finish_fight(_event: Dictionary, _generation: int) -> void: pass
	func _show_signature(_event: Dictionary) -> void: pass

var checks := 0
var failures := 0
var missing: Array[String] = []
var covered: Array[String] = []
var require_roster := false
var report_path := ""
var source_hashes: Dictionary = {}

func _init() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ILLUSTRATED DAMAGE: "+message)

func _run() -> void:
	create_timer(90,true,false,true).timeout.connect(func(): push_error("ILLUSTRATED DAMAGE timeout");quit(1))
	for arg: String in OS.get_cmdline_user_args():
		if arg=="--require-roster": require_roster = true
		if arg.begins_with("--report="): report_path = arg.trim_prefix("--report=")
	for path: String in ["res://scripts/combat_engine.gd","res://scripts/combat_rules.gd","res://scripts/status_effects.gd","res://scripts/character_catalog.gd","res://scripts/move_catalog.gd","res://scripts/progression.gd","res://scripts/story_progression.gd"]:
		source_hashes[path] = FileAccess.get_sha256(path)
	_test_shader()
	_test_schema()
	_test_roster()
	_test_contact_transition()
	_test_health_partition()
	for path: String in source_hashes: check(FileAccess.get_sha256(path)==source_hashes[path],"gameplay file unchanged: "+path)
	if not report_path.is_empty():
		DirAccess.make_dir_recursive_absolute(report_path.get_base_dir())
		var file := FileAccess.open(report_path,FileAccess.WRITE)
		if file!=null: file.store_string(JSON.stringify({"checks":checks,"failures":failures,"require_roster":require_roster,"covered_bodies":covered,"missing_bodies":missing,"frames_per_body":40,"illustrated_family":"shared by tiers2 and3","coverage_complete":covered.size()==23,"cache":DamageArt.cache_info(),"gameplay_hashes":source_hashes,"player_saves_opened":false},"\t")+"\n")
	print("ILLUSTRATED DAMAGE: %d checks, %d failures; %d/23 complete illustrated bodies" % [checks,failures,covered.size()])
	quit(0 if failures==0 else 1)

func _test_shader() -> void:
	for forbidden: String in ["damage_amount","damage_material","damage_scorch","damage_point","scratch(","patch(","dust_ink","abrasion"]:
		check(not Fighter.FLASH_SHADER.contains(forbidden),"wear drawing is absent: "+forbidden)
	check(Fighter.FLASH_SHADER.contains("palette_strength") and Fighter.FLASH_SHADER.contains("flash_amount"),"legitimate palette and contact flash remain")
	DamageArt.clear_cache()
	check(not DamageArt.prepare("../../nima") and not DamageArt.prepare("not_a_body"),"unknown/path traversal body IDs cannot load art")
	check(DamageArt.cache_info().count==0 and not DamageArt.cache_info().negative_cache,"failed discovery retains no negative entries or textures")

func _test_schema() -> void:
	# Existing clean PNG is an in-memory transport fixture, never promoted as damage art.
	var path := "res://assets/sprites/normalized/ascua-movement-v2.png"
	var texture := load(path) as Texture2D
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path.get_basename()+".json"))
	var before := JSON.stringify(metadata)
	var valid := DamageArt._decode_bank("ascua","movement",metadata,texture,path)
	check(not valid.is_empty() and valid.get("frames",{}).size()==16,"schema accepts real normalized sixteen-frame source")
	var variants: Array[Dictionary] = []
	for change: Dictionary in [{"version":99},{"body_id":"mugo"},{"bank":"base"},{"profile_id":"mugo:normal:v1"},{"canvas_px":[256,256]},{"pivot_px":[255,448]},{"pixels_per_world_unit":2.0}]:
		var bad := metadata.duplicate(true);bad.merge(change,true);variants.append(bad)
	var short := metadata.duplicate(true);short.frames.pop_back();variants.append(short)
	var duplicate := metadata.duplicate(true);duplicate.frames[1].region=duplicate.frames[0].region.duplicate();variants.append(duplicate)
	var wrong_name := metadata.duplicate(true);wrong_name.frames[0].name="grounded";variants.append(wrong_name)
	var bad_bounds := metadata.duplicate(true);bad_bounds.frames[0].alpha_bounds_px=[0,0,513,512];variants.append(bad_bounds)
	var bad_socket := metadata.duplicate(true);bad_socket.frames[0].sockets_px={"hand":[NAN,20]};variants.append(bad_socket)
	var bad_ground := metadata.duplicate(true);bad_ground.frames[0].grounded="true";variants.append(bad_ground)
	for index in range(variants.size()): check(DamageArt._decode_bank("ascua","movement",variants[index],texture,path).is_empty(),"malformed metadata fails closed case%d" % index)
	check(JSON.stringify(metadata)==before,"schema validation leaves input metadata immutable")
	if not valid.is_empty():
		var frame: Dictionary = valid.frames.quick_extend
		check(frame.bounds==Rect2i(metadata.frames[5].alpha_bounds_px[0],metadata.frames[5].alpha_bounds_px[1],metadata.frames[5].alpha_bounds_px[2],metadata.frames[5].alpha_bounds_px[3]),"effective frame uses supplied illustrated alpha bounds")
		check(frame.texture.region==Rect2(frame.region) and frame.anchor==Vector2(256,448),"texture and metadata share one region and pivot")
	var qualified := metadata.duplicate(true)
	qualified.frames[0]["socket_annotation_method"]="prior_projection_approximate"
	qualified.frames[0]["socket_verification"]={"hand":"approximate"}
	var qualified_pack := DamageArt._decode_bank("ascua","movement",qualified,texture,path)
	check(not qualified_pack.is_empty() and qualified_pack.frames.guard_shift.socket_annotation_method=="prior_projection_approximate" and qualified_pack.frames.guard_shift.socket_verification=={"hand":"approximate"},"effective descriptor preserves source landmark confidence")

func _definition(body: String) -> Dictionary:
	if body=="ascua": return Story.boss_definition(1)
	if body=="vespera": return Story.boss_definition(2)
	return Cosmetics.body_definition(body)

func _test_roster() -> void:
	var bodies: Array = Sequences.BASE_TO_BODY.values()
	check(bodies.size()==23,"all23 bodies participate, including families and bosses")
	for body: String in bodies:
		var available := DamageArt.prepare(body)
		if available: covered.append(body)
		else: missing.append(body)
		if require_roster: check(available,"complete40-pose illustrated family required: "+body)
		var count := 0
		for bank_name: String in DamageArt.BANKS:
			var clean: Dictionary = Sequences.normalized_pack(body,bank_name)
			check(not clean.is_empty(),body+": original normalized pack remains usable "+bank_name)
			if clean.is_empty(): continue
			for name: String in DamageArt.expected_names(bank_name):
				count += 1
				var original: Dictionary = clean.frames[name]
				var source_path: String = original.source_path
				var fresh := DamageArt.resolve_frame(body,0,original)
				var worn := DamageArt.resolve_frame(body,1,original)
				var damaged := DamageArt.resolve_frame(body,2,original)
				var critical := DamageArt.resolve_frame(body,3,original)
				check(fresh.source_path==source_path and worn.source_path==source_path and not worn.damage_art,body+"/"+name+": clean/fatigue use original illustration without shader marks")
				check(original.source_path==source_path and not original.has("damage_art"),body+"/"+name+": resolver leaves canonical descriptor immutable")
				if available:
					check(damaged.damage_art and critical.damage_art and damaged.source_path==critical.source_path,body+"/"+name+": tiers2/3 share the declared illustrated family")
					check(damaged.name==name and damaged.bank==bank_name and damaged.body_id==body,body+"/"+name+": semantic frame and identity preserved")
					check(damaged.scale==original.scale and damaged.anchor==original.anchor,body+"/"+name+": physical scale and ground origin retained")
					check(damaged.texture.atlas.resource_path==damaged.source_path and damaged.texture.region==Rect2(damaged.region),body+"/"+name+": rendered resource matches effective metadata")
				else:
					check(not damaged.damage_art and damaged.source_path==source_path and not damaged.damage_fallback.is_empty(),body+"/"+name+": absent pack has explicit safe fallback")
		check(count==40,body+": all40 semantic poses resolved")
		_test_actor(body,available)
		if available: _test_illustrated_contact(body)
		check(int(DamageArt.cache_info().count)<=6,body+": LRU never exceeds six banks")
	check(not DamageArt.cache_info().negative_cache,"missing generation outputs never become permanent negative cache")

func _test_actor(body: String, available: bool) -> void:
	var actor := Fighter.new();root.add_child(actor);actor.setup_character(_definition(body));actor.set_process(false)
	var rival := Fighter.new();root.add_child(rival);rival.setup_character(Catalog.definition("nima"),-1);rival.set_process(false)
	actor.position=Vector2(250,600);rival.position=Vector2(430,600)
	actor.set_combat_lane(84,rival);rival.set_combat_lane(84,actor)
	var home := actor.transform
	for pose in range(8):
		actor._set_pose_frame(pose)
		check(actor._current_frame().texture==actor._sprite.texture,body+": base eight-pose API never reports a stale effective frame")
	actor.reset_pose()
	actor.set_health_ratio(0.39);actor._process(1.0)
	check(actor.damage_state.tier==2 and bool(actor.get_animation_state().damage_art)==available,body+": actual actor selects illustrated damage or declared fallback")
	actor.set_health_ratio(0.9);actor._process(0.2)
	check(actor.damage_state.tier==2,body+": healing does not repair the drawing")
	var id := Families.base_body(body)
	var move: Dictionary = Moves.moves_for(id)[0]
	actor.play_move(move,float(move.impact_delay))
	check(actor.transform==home and is_equal_approx(actor._action_time,float(move.impact_delay)),body+": damage preserves root and contact clock")
	check(bool(actor.get_animation_state().damage_art)==available,body+": damage persists through the outgoing punch")
	var current: Dictionary = actor._current_frame()
	check(actor._sprite.texture==current.texture and actor.get_animation_state().source_path==current.source_path,body+": sprite/public geometry/FX see the same effective frame")
	if current.sockets_px.has("core"):
		var expected: Vector2 = actor._sprite.transform*(Vector2(current.sockets_px.core)-Vector2(current.anchor))
		check(actor.effect_anchor("chest").is_equal_approx(expected),body+": chest follows the current illustrated socket")
	actor.motion_paused=true;var frozen: Dictionary=actor.damage_state.snapshot();actor._process(2.0)
	check(actor.damage_state.snapshot()==frozen,body+": pause preserves damage and contact")
	actor.motion_paused=false
	actor.set_health_ratio(0.1);actor._process(0.02)
	actor.resolve_battle(false);actor._process(1.0)
	check(actor._mode=="fall" and actor.damage_state.tier==3,body+": KO commits critical state without reviving")
	check(bool(actor.get_animation_state().damage_art)==available,body+": grounded KO retains illustrated appearance")
	actor.reset_pose();check(actor.damage_state.tier==0 and not actor.get_animation_state().damage_art,body+": new round restores clean appearance")
	actor.reduced_motion=true;actor.set_health_ratio(0.1);actor._process(1.0)
	check(bool(actor.get_animation_state().damage_art)==available,body+": reduced motion retains authored damage")
	actor.free();rival.free()

func _painted(actor) -> Rect2:
	var frame: Dictionary = actor._current_frame()
	var rect := Rect2(frame.bounds)
	var transform: Transform2D = actor._sprite.global_transform
	var result := Rect2(transform*(rect.position+actor._sprite.offset),Vector2.ZERO)
	for point: Vector2 in [Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]:
		result=result.expand(transform*(point+actor._sprite.offset))
	return result

func _test_illustrated_contact(body: String) -> void:
	var parent := Node2D.new();root.add_child(parent)
	var actor := Fighter.new();parent.add_child(actor);actor.set_process(false)
	var rival := Fighter.new();parent.add_child(rival);rival.set_process(false)
	for facing: int in [1,-1]:
		actor.setup_character(_definition(body),facing)
		rival.setup_character(Catalog.definition("nima"),-facing)
		for size: Vector2 in SIZES:
			var layout: Dictionary=Layout.calculate(size,true)
			actor.scale=Vector2.ONE*float(layout.actor_scale);rival.scale=actor.scale
			actor.position=layout.player_at if facing>0 else layout.rival_at
			rival.position=layout.rival_at if facing>0 else layout.player_at
			actor.set_combat_lane(84,rival);rival.set_combat_lane(84,actor)
			for move: Dictionary in Moves.moves_for(Families.base_body(body)):
				actor.reset_pose();rival.reset_pose()
				actor.set_health_ratio(0.39);actor._process(1.0)
				var home:=actor.transform
				var target:=_painted(rival)
				actor.play_move(move,float(move.impact_delay))
				var actual:=_painted(actor)
				var label:="%s/%s/%s/facing%d" % [body,move.id,str(size),facing]
				check(actor.get_animation_state().damage_art,label+": every attack/guard uses the illustrated bank")
				check(actor.transform==home and is_equal_approx(actor._action_time,float(move.impact_delay)),label+": root and clock are unchanged")
				check(Rect2(Vector2.ZERO,size).grow(1).encloses(actual) and not actual.intersects(layout.primary),label+": actual illustrated silhouette stays in view and clear of CTA")
				if not str(move.type) in ["guard","counter"]:
					var gap:float=target.position.x-actual.end.x if facing>0 else actual.position.x-target.end.x
					check(gap<=8.0*actor.scale.x and -gap<=target.size.x*0.8,label+": drawn impact reaches with bounded overlap")
					var at_contact:float=actor._sprite.position.x
					actor.resolve_battle(false)
					check(absf(actor._sprite.position.x-at_contact)<0.01,label+": KO retains contact origin")
				actor._process(1.2)
				check(actor.transform==home and actor.get_animation_state().damage_art,label+": recovery/result keeps identity and scale")
	parent.free()

func _test_contact_transition() -> void:
	if not DamageArt.prepare("ascua"): return
	var actor := Fighter.new();root.add_child(actor);actor.setup_character(_definition("ascua"));actor.set_process(false)
	var rival := Fighter.new();root.add_child(rival);rival.setup_character(Catalog.definition("nima"),-1);rival.set_process(false)
	actor.position=Vector2(250,600);rival.position=Vector2(430,600)
	actor.set_combat_lane(84,rival);rival.set_combat_lane(84,actor)
	var heavy: Dictionary = {}
	for move: Dictionary in Moves.moves_for("ascua"):
		if move.type=="heavy": heavy=move;break
	check(not heavy.is_empty(),"transition fixture uses a real heavy movement")
	if heavy.is_empty(): actor.free();rival.free();return
	var home := actor.transform
	actor.play_move(heavy,float(heavy.windup)+0.001)
	actor.set_health_ratio(0.1);actor._process(0.16)
	check(actor.damage_state.tier==3 and actor.get_contact_state().active,"health threshold commits while an actual heavy contact is still active")
	check(not actor.get_animation_state().damage_art,"illustrated geometry waits until the current outgoing contact has recovered")
	check(actor.transform==home and is_equal_approx(actor._action_time,float(heavy.windup)+0.161),"deferred art does not alter root or action time")
	var held_x: float=actor._sprite.position.x
	actor.resolve_battle(false)
	check(actor.get_animation_state().damage_art and absf(actor._sprite.position.x-held_x)<0.01,"KO can reveal damage while retaining the outgoing contact origin")
	actor.reset_pose();actor.set_health_ratio(0.39);actor._process(1.0)
	actor.play_move(heavy,float(heavy.impact_delay))
	# Local injury detail now shares the clean pose's exact geometry. Its existing
	# authored hand annotation is retained, rather than projected to a redraw.
	var clean_strike: Dictionary=Sequences.frame("ascua","quick_extend")
	var injured_strike: Dictionary=DamageArt.resolve_frame("ascua",2,clean_strike)
	check(injured_strike.sockets_px.get("hand")==clean_strike.sockets_px.get("hand"),"localized injury retains the existing clean hand annotation")
	check(injured_strike.bounds==clean_strike.bounds,"localized injury retains the exact clean strike silhouette")
	check(actor.get_contact_state().anchor_source=="authored_hand","contact uses the authored hand on the shared clean geometry")
	var frame := actor._current_frame().duplicate(true)
	var transform := actor._sprite.transform
	actor.set_health_ratio(0.1);actor.damage_state.advance(0.2,false);actor._update_pose()
	check(actor.damage_state.tier==3 and actor._current_frame().source_path==frame.source_path,"critical health reuses the same illustrated family during an attack")
	check(actor._sprite.transform.is_equal_approx(transform),"tier2-to3 does not shift the illustrated strike")
	actor._process(1.0)
	check(actor._mode=="idle" and actor.get_animation_state().damage_art,"ordinary recovery retains illustrated idle")
	actor.free();rival.free()

func _test_health_partition() -> void:
	var engine = EngineScript.new()
	var trace: Array[Dictionary] = []
	var summary: Dictionary = {}
	for seed_value in range(511,551):
		engine.start({"character_id":"neris","level":25,"fighter_id":"fixture:neris"},{"character_id":"taro","level":25},seed_value,{"disable_signatures":true,"opening_time":0.1,"battle_id":"illustrated-damage-health-fixture"})
		engine.advance(60.0)
		summary=engine.summary()
		trace.clear()
		for event: Dictionary in summary.events:
			trace.append(event)
			if event.type=="heal" and event.get("side","")=="player": break
		if not trace.is_empty() and trace.back().type=="heal": break
	check(not trace.is_empty() and trace.back().type=="heal","real seeded trace contains a comeback heal after damage")
	if trace.is_empty(): return
	var before := JSON.stringify(trace)
	var lowest := 1.0
	for event: Dictionary in trace: lowest=minf(lowest,float(event.player_hp)/engine.player_max_hp)
	check(lowest<float(trace.back().player_hp)/engine.player_max_hp,"batch fixture has an intermediate HP minimum lower than its final snapshot")
	var batched := HealthBoundary.new();root.add_child(batched);batched.combat=engine
	var split := HealthBoundary.new();root.add_child(split);split.combat=engine
	batched._dispatch_events(trace)
	for event: Dictionary in trace: split._dispatch_events([event])
	batched.player_view._process(1.0);split.player_view._process(1.0)
	check(is_equal_approx(batched.player_view.damage_state.minimum_health,lowest),"Main retains intermediate HP minimum within one dispatch batch")
	check(batched.player_view.damage_state.snapshot()==split.player_view.damage_state.snapshot(),"Main split and batched dispatch produce the same visual damage")
	var record: Dictionary={};Records.attach(record,summary)
	var replay := Replay.new();root.add_child(replay);replay.set_process(false);replay.configure([record])
	check(not replay.snapshot.is_empty(),"replay accepts the actual immutable battle record")
	for event: Dictionary in trace:
		replay.elapsed=float(event.time);replay._apply_event(event)
	replay.actors.player.motion_paused=false;replay.actors.player._process(1.0)
	check(is_equal_approx(replay.actors.player.damage_state.minimum_health,lowest),"Replay and live Main preserve the same intermediate minimum")
	check(replay.actors.player.damage_state.tier==batched.player_view.damage_state.tier,"Replay and live Main select the same damage family after healing")
	check(JSON.stringify(trace)==before,"health observation leaves the authoritative event trace immutable")
	check(batched.progression.data.is_empty() and split.progression.data.is_empty(),"boundary fixtures never initialize or reward a player profile")
	replay.free();batched.free();split.free()
