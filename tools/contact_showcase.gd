extends SceneTree
## Native BEFORE/AFTER contact evidence. Uses production Main event dispatch,
## FighterView and BattleLayout; no save loader, reward, audio or network setup.
## Godot --path outputs/Brasa --script res://tools/contact_showcase.gd -- --output=/absolute/work/contact/before
const Catalog = preload("res://scripts/character_catalog.gd")
const Story = preload("res://scripts/story_catalog.gd")
const Moves = preload("res://scripts/move_catalog.gd")
const Combat = preload("res://scripts/combat_engine.gd")
const Replay = preload("res://scripts/ui/battle_replay_panel.gd")
const SOURCES := ["res://scripts/main.gd","res://scripts/fighter_view.gd","res://scripts/ui/battle_layout.gd","res://scripts/ui/battle_replay_panel.gd"]
const SIZES: Array[Vector2i] = [Vector2i(1360,880),Vector2i(390,844)]
const CASES := [
	{"id":"nima_mugo_quick","left":"nima","right":"mugo","side":"player","kind":"quick"},
	{"id":"mugo_nima_quick","left":"mugo","right":"nima","side":"rival","kind":"quick"},
	{"id":"mugo_nima_heavy","left":"mugo","right":"nima","side":"player","kind":"heavy"},
	{"id":"nima_mugo_heavy","left":"nima","right":"mugo","side":"rival","kind":"heavy"},
	{"id":"nima_tepa_quick","left":"nima","right":"tepa","side":"player","kind":"quick"},
	{"id":"tepa_nima_quick","left":"tepa","right":"nima","side":"player","kind":"quick"},
	{"id":"nima_mugo_jump","left":"nima","right":"mugo","side":"player","kind":"jump"},
	{"id":"mugo_nima_jump","left":"mugo","right":"nima","side":"rival","kind":"jump"},
	{"id":"ascua_mugo_heavy","left":"ascua","right":"mugo","side":"player","kind":"heavy"},
	{"id":"mugo_ascua_heavy","left":"mugo","right":"ascua","side":"rival","kind":"heavy"},
]
class Fixture:
	extends "res://scripts/main.gd"
	func _ready() -> void:
		sound_enabled = false
		_build_theme()
		_build_interface()
		set_process(false)

var output := ""
var checks := 0
var failures := 0
var shots: Array[Dictionary] = []
var source_hashes: Dictionary = {}

func _init() -> void: _run.call_deferred()
func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CONTACT SHOWCASE: "+message)

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	var allowed := ProjectSettings.globalize_path("res://../../work/contact").simplify_path()
	_check(output.is_absolute_path() and output.simplify_path().begins_with(allowed+"/"),"Output is isolated under work/contact")
	_check(DisplayServer.get_name()!="headless","Native renderer is required")
	if failures: quit(1); return
	DirAccess.make_dir_recursive_absolute(output)
	for path: String in SOURCES: source_hashes[path] = FileAccess.get_sha256(path)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(360,240)
	Engine.time_scale = 1.0
	for dimensions: Vector2i in SIZES:
		for item: Dictionary in CASES:
			await _case(item, dimensions, false)
			if str(item.id) in ["nima_mugo_quick","mugo_nima_heavy"]:
				await _case(item, dimensions, true)
		for index: int in [0,2]: await _replay_case(CASES[index],dimensions)
		for index: int in [0,2]: await _replay_case(CASES[index],dimensions,true)
	for path: String in SOURCES: _check(FileAccess.get_sha256(path)==source_hashes[path],"Runtime source remains frozen: "+path)
	var report := {"checks":checks,"failures":failures,"source_hashes":source_hashes,"renderer":DisplayServer.get_name(),"shots":shots,
		"method":"Deterministic engine events advanced at 120Hz through production Main dispatch and FighterView; samples are continuous within each case. Opponent initiative is delayed only in this isolated engine fixture. No pose assignment, save loading, rewards, audio or network.","tool_sha256":FileAccess.get_sha256("res://tools/contact_showcase.gd")}
	FileAccess.open(output.path_join("observations.json"),FileAccess.WRITE).store_string(JSON.stringify(_json(report),"\t"))
	print("CONTACT SHOWCASE: %d checks, %d failures, %d PNG; %s" % [checks,failures,shots.size(),output])
	quit(0 if failures==0 else 1)

func _definition(id: String) -> Dictionary:
	return Story.opponent(7,1) if id=="ascua" else Catalog.definition(id)

func _profile(id: String) -> Dictionary:
	var definition := _definition(id)
	var profile := definition.duplicate(true)
	profile["character_id"] = "mugo" if id=="ascua" else id
	profile["name"] = "Ascua" if id=="ascua" else str(definition.get("name",id))
	profile["level"] = 20
	profile["stats"] = Catalog.definition(str(profile.character_id)).training_base.duplicate(true)
	profile["combat_stats"] = Catalog.stats_for(profile)
	profile.combat_stats.merge({"max_hp":4000.0,"attack":24.0,"accuracy":1.0,"evasion":0.0,"crit_chance":0.0},true)
	return profile

func _case(item: Dictionary, dimensions: Vector2i, reduced: bool) -> void:
	var canvas := SubViewport.new()
	canvas.size = dimensions
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	var screen := Fixture.new()
	canvas.add_child(screen)
	screen.size = Vector2(dimensions)
	screen.active_match = true
	screen.reduced_motion = reduced
	screen._layout_interface(screen.size)
	var left := _profile(str(item.left))
	var right := _profile(str(item.right))
	var side := str(item.side)
	var attacking_id := str(item.left if side=="player" else item.right)
	var selected: Dictionary = {}
	for move: Dictionary in Moves.moves_for(attacking_id):
		if str(move.type)==str(item.kind): selected=move.duplicate(true); break
	_check(not selected.is_empty(),str(item.id)+": catalog move exists")
	if selected.is_empty(): canvas.free(); return
	if side=="player": left.moves=[selected]
	else: right.moves=[selected]
	screen.player_view.setup_character(_definition(str(item.left)),1)
	screen.rival_view.setup_character(_definition(str(item.right)),-1)
	for actor: Node2D in [screen.player_view,screen.rival_view]:
		actor.set_process(false)
		actor.reduced_motion = reduced
		actor.prepare_combat_animation()
	screen.arena.set_process(false)
	screen.arena.reduced_motion = reduced
	screen.combat_fx.set_process(false)
	screen.combat_fx.reduced_motion = reduced
	screen.player_name_label.text = str(left.name)
	screen.rival_name_label.text = str(right.name)
	screen.save_notice.text = "MUESTRA AISLADA · SIN GUARDADOS"
	screen.fight_button.text = "PRUEBA DE CONTACTO"
	screen.combat.start(left,right,83041,{"opening_time":0.20,"disable_signatures":true,"battle_id":"contact_showcase"})
	screen.combat._fighters["rival" if side=="player" else "player"].next_action = 99.0
	screen._refresh_combat_state()
	await _capture(screen,canvas,item,reduced,"idle",0.0)
	var start := -1.0
	for step in range(100):
		var events := _step(screen,1.0/120.0)
		for event: Dictionary in events:
			if str(event.type)=="move_started" and str(event.side)==side:
				start=float(event.time)
				selected=event.move
		if start>=0: break
	_check(start>=0,str(item.id)+": actual engine starts requested side")
	var impact := start+float(selected.windup)+float(selected.travel)
	var targets := [{"phase":"travel","time":start+float(selected.windup)+float(selected.travel)*0.5},
		{"phase":"contact","time":impact+0.012}, {"phase":"recovery","time":impact+0.12}]
	for target: Dictionary in targets:
		while screen.combat.elapsed < float(target.time)-0.000001:
			_step(screen,minf(1.0/120.0,float(target.time)-screen.combat.elapsed))
		await _capture(screen,canvas,item,reduced,str(target.phase),float(target.time))
	screen.active_match = false
	canvas.queue_free()
	await process_frame

func _step(screen: Fixture, delta: float) -> Array:
	screen.player_view._process(delta)
	screen.rival_view._process(delta)
	screen.arena._process(delta)
	screen.combat_fx._process(delta)
	var events: Array = screen.combat.advance(delta)
	screen._dispatch_events(events)
	screen._refresh_combat_state()
	return events

func _replay_case(item: Dictionary, dimensions: Vector2i, lethal: bool = false) -> void:
	var canvas := SubViewport.new()
	canvas.size = dimensions
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	var panel := Replay.new()
	canvas.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(dimensions)
	panel.set_process(false)
	var left := _profile(str(item.left))
	var right := _profile(str(item.right))
	var move: Dictionary = {}
	for candidate: Dictionary in Moves.moves_for(str(item.left)):
		if str(candidate.type)==str(item.kind): move=candidate.duplicate(true); break
	left.moves = [move]
	var engine := Combat.new()
	engine.start(left,right,83041,{"opening_time":0.20,"disable_signatures":true,"battle_id":"contact_showcase_replay","initial_hp":{"rival":1.0} if lethal else {}})
	engine._fighters.rival.next_action = 99.0
	var recorded: Array = []
	var move_at := -1.0
	while engine.elapsed < 1.8 and engine.running:
		var events: Array = engine.advance(1.0/120.0)
		for event: Dictionary in events:
			recorded.append(event.duplicate(true))
			if move_at<0 and str(event.type)=="move_started" and str(event.side)=="player": move_at=float(event.time)
	panel.snapshot = {"player":left,"rival":right,"duration":1.8,"events":recorded}
	panel.restart()
	panel.playing = true
	panel._fx.set_process(false)
	panel._fx.motion_paused = false
	for actor: Node2D in panel.actors.values():
		actor.set_process(false)
		actor.motion_paused = false
	var impact := move_at+float(move.windup)+float(move.travel)
	_check(move_at>=0 and impact+0.12<1.8,"Replay contact targets fit recorded sequence")
	var checkpoints := [{"phase":"idle","time":0.0},{"phase":"contact","time":impact+0.012},{"phase":"recovery","time":impact+0.12}]
	if lethal:
		_check(not engine.running and engine.winner=="player","KO fixture reaches a real terminal engine event")
		checkpoints.append({"phase":"terminal","time":impact+0.70})
		checkpoints.append({"phase":"settled","time":1.75})
	for target: Dictionary in checkpoints:
		while panel.elapsed < float(target.time)-0.000001:
			var delta := minf(1.0/120.0,float(target.time)-panel.elapsed)
			for actor: Node2D in panel.actors.values(): actor._process(delta)
			panel._fx._process(delta)
			panel._process(delta)
		await process_frame
		await RenderingServer.frame_post_draw
		var filename := "%s-%s-%dx%d-%s.png" % ["ko" if lethal else "replay",str(item.id),dimensions.x,dimensions.y,str(target.phase)]
		_check(canvas.get_texture().get_image().save_png(output.path_join(filename))==OK,"PNG: "+filename)
		var a: Node2D = panel.actors.player
		var b: Node2D = panel.actors.rival
		shots.append({"file":filename,"case":item,"presentation":"ko" if lethal else "replay","layers":_layers(a,b,panel._fx),"phase":target.phase,"engine_time":panel.elapsed,
			"viewport":dimensions,"player_origin":a.global_position,"rival_origin":b.global_position,"scale":a.scale,
			"player_bounds":a.visible_sprite_bounds(),"rival_bounds":b.visible_sprite_bounds(),
			"player_z":a.z_index,"rival_z":b.z_index,"player_state":a.get_animation_state(),"rival_state":b.get_animation_state(),"player_contact":a.get_contact_state(),"rival_contact":b.get_contact_state()})
	canvas.queue_free()
	await process_frame

func _capture(screen: Fixture, canvas: SubViewport, item: Dictionary, reduced: bool, phase: String, requested: float) -> void:
	screen.feed_label.text = "%s · %s · %s" % [str(item.kind).to_upper(),phase,"REDUCIDO" if reduced else "NORMAL"]
	await process_frame
	await RenderingServer.frame_post_draw
	var filename := "%s-%dx%d-%s-%s.png" % [str(item.id),canvas.size.x,canvas.size.y,"reduced" if reduced else "normal",phase]
	var image := canvas.get_texture().get_image()
	_check(not image.is_empty() and image.save_png(output.path_join(filename))==OK,"PNG: "+filename)
	var a: Node2D = screen.player_view
	var b: Node2D = screen.rival_view
	var bounds_a: Rect2 = a.visible_sprite_bounds()
	var bounds_b: Rect2 = b.visible_sprite_bounds()
	shots.append({"file":filename,"case":item,"phase":phase,"requested_time":requested,"engine_time":screen.combat.elapsed,"reduced_motion":reduced,
		"viewport":canvas.size,"player_origin":a.position,"rival_origin":b.position,"scale":a.scale,"player_bounds":bounds_a,"rival_bounds":bounds_b,
		"layers":_layers(a,b,screen.combat_fx),"painted_gap_pixels":bounds_b.position.x-bounds_a.end.x,"player_z":a.z_index,"rival_z":b.z_index,
		"player_state":a.get_animation_state(),"rival_state":b.get_animation_state(),"player_contact":a.get_contact_state(),"rival_contact":b.get_contact_state()})

func _layers(a: Node2D,b: Node2D,fx: Node2D) -> Dictionary:
	var same_parent := a.get_parent()==b.get_parent() and a.get_parent()==fx.get_parent()
	_check(a.z_index==0 and b.z_index==0,"Actor z remains zero")
	_check(same_parent and fx.get_index()>maxi(a.get_index(),b.get_index()),"FX remains above both actor siblings")
	var contact_a: Dictionary = a.get_contact_state()
	var contact_b: Dictionary = b.get_contact_state()
	if float(contact_a.weight)>0.01 and float(contact_b.weight)<=0.01:
		_check(a.get_index()>b.get_index(),"Player attacker is drawn in front")
	elif float(contact_b.weight)>0.01 and float(contact_a.weight)<=0.01:
		_check(b.get_index()>a.get_index(),"Rival attacker is drawn in front")
	return {"same_parent":same_parent,"player_index":a.get_index(),"rival_index":b.get_index(),"fx_index":fx.get_index(),"fx_z":fx.z_index}

func _json(value: Variant) -> Variant:
	if value is Vector2 or value is Vector2i: return [value.x,value.y]
	if value is Rect2 or value is Rect2i: return {"position":_json(value.position),"size":_json(value.size)}
	if value is Dictionary:
		var out := {}
		for key: Variant in value: out[str(key)]=_json(value[key])
		return out
	if value is Array:
		var out: Array = []
		for item: Variant in value: out.append(_json(item))
		return out
	return value
