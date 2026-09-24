extends SceneTree
## Continuous Main and historical Replay animation QA. The only mutations are
## unique fixtures beneath work/animation. No poses are set to make screenshots.
## Native: Godot --path outputs/Brasa --script res://tests/test_animation_sequences_visual.gd -- --capture-dir=/absolute/work/path
## Movie: add --resolution 1360x880 --write-movie /absolute/work/demo.avi --fixed-fps 30 before --script; append -- --movie-demo.
const Fixtures = preload("res://tests/test_story_chapter_integration.gd")
const EngineScript = preload("res://scripts/combat_engine.gd")
const Story = preload("res://scripts/story_catalog.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Moves = preload("res://scripts/move_catalog.gd")
const Records = preload("res://scripts/battle_identity.gd")
const Replay = preload("res://scripts/ui/battle_replay_panel.gd")
const AnimationSet = preload("res://scripts/fighter_animation_set.gd")
const SIZES: Array[Vector2i] = [Vector2i(1360,880),Vector2i(390,844)]
const OPTIONS := {"opening_time":0.50,"disable_signatures":true,"battle_id":"animation_sequence_fixture"}

class Fixture:
	extends Fixtures.Fixture
	var fixture_player: Dictionary = {}
	func _ready() -> void:
		super._ready()
		if not fixture_player.is_empty():
			progression.select_character("mugo",str(fixture_player.name))
			_refresh_manager()
			_update_portraits()
	func _player_combatant() -> Dictionary:
		return fixture_player.duplicate(true) if not fixture_player.is_empty() else super._player_combatant()

class Observer:
	extends Node
	signal sampled(delta: float)
	var presentation_time := 0.0
	var count_time := true
	func _process(delta: float) -> void:
		if count_time: presentation_time += delta
		sampled.emit(delta)

var checks := 0
var failures := 0
var capture_dir := ""
var output_dir := ""
var screen: Fixture
var replay
var canvas: SubViewport
var observer: Observer
var player: Dictionary = {}
var rival: Dictionary = {}
var expected: Dictionary = {}
var targets: Array[Dictionary] = []
var seed_value := 1
var measurements: Array[Dictionary] = []
var runtimes: Array[Dictionary] = []
var observed_frames: Dictionary = {}
var seen_fx := false
var plan_only := false
var movie_demo := false
var _observing := false
var _presentation := ""
var _terminal_frame: Dictionary = {}
var _continuous_deltas: Array[float] = []

func _init() -> void: _run.call_deferred()

func _check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ANIMATION SEQUENCES: " + description)

func _run() -> void:
	Engine.time_scale = 1.0
	Engine.max_fps = 60
	create_timer(150,true,false,true).timeout.connect(func(): push_error("ANIMATION SEQUENCES timeout"); quit(1))
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): capture_dir = arg.trim_prefix("--capture-dir=")
		elif arg=="--plan-only": plan_only = true
		elif arg=="--movie-demo": movie_demo = true
	output_dir = ProjectSettings.globalize_path("res://../../work/animation/integration/%d" % Time.get_ticks_usec()).simplify_path()
	DirAccess.make_dir_recursive_absolute(output_dir)
	if not capture_dir.is_empty():
		_check(capture_dir.is_absolute_path() and DisplayServer.get_name() != "headless", "Captures need an absolute path and native renderer")
		if failures: quit(1); return
		DirAccess.make_dir_recursive_absolute(capture_dir)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	# MovieMaker fixes its recording size before this deferred setup. Preserve
	# that native window and fit the full 1360x880 SubViewport into it uniformly.
	if not movie_demo: root.size = Vector2i(360,240)
	_build_battle()
	if expected.is_empty(): quit(1); return
	_build_targets()
	_check(targets.size()==24,"Exactly 24 ordered temporal observations per continuous presentation")
	if plan_only:
		print(JSON.stringify({"seed":seed_value,"duration":expected.duration,"targets":targets}))
		quit(0 if failures==0 else 1)
		return
	var cold_memory := _memory()
	var test_sizes: Array[Vector2i] = []
	if movie_demo: test_sizes.append(SIZES[0])
	else: test_sizes.assign(SIZES)
	for dimensions: Vector2i in test_sizes:
		canvas = SubViewport.new()
		canvas.size = dimensions
		canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(canvas)
		observer = Observer.new()
		observer.process_priority = 1000
		canvas.add_child(observer)
		observer.sampled.connect(_track_frame)
		var movie_surface: TextureRect
		var movie_caption: Label
		if movie_demo:
			movie_surface = TextureRect.new()
			movie_surface.texture = canvas.get_texture()
			movie_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			movie_surface.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			movie_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
			root.add_child(movie_surface)
			movie_caption = Label.new()
			movie_caption.text = "BATALLA DE PRUEBA · TIEMPOS DEL MOTOR"
			movie_caption.position = Vector2((float(root.size.x)-760.0)*0.5,24)
			movie_caption.size = Vector2(760,30)
			movie_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			movie_caption.add_theme_font_size_override("font_size",15)
			movie_caption.add_theme_color_override("font_color",Color("b2c9c2"))
			movie_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
			root.add_child(movie_caption)
		await _live(dimensions)
		if not movie_demo: await _replay(dimensions)
		if is_instance_valid(movie_surface): movie_surface.queue_free()
		if is_instance_valid(movie_caption): movie_caption.queue_free()
		canvas.queue_free()
		await process_frame
	_check(observed_frames.size()>4,"Ascua uses several distinct illustrated sequence frames during continuous playback")
	_check(seen_fx,"At least one separate event-driven FX is visible during actual combat")
	var report := {"checks":checks,"failures":failures,"renderer":DisplayServer.get_name(),"seed":seed_value,"movie_demo":movie_demo,
		"duration":expected.duration,"timing":"Real SceneTree callbacks; targets derive from an independent deterministic engine run. Actual sample time is recorded, never substituted by requested time. PNG readback can add frame latency.",
		"fixture_overrides":{"player":player,"rival":rival,"options":OPTIONS},"memory_cold":cold_memory,"memory_end":_memory(),
		"targets":targets,"observed_frames":observed_frames.keys(),"runtime":runtimes,"observations":measurements}
	report["animation_cache"] = AnimationSet.cache_info()
	var destination := output_dir.path_join("results.json")
	FileAccess.open(destination,FileAccess.WRITE).store_string(JSON.stringify(_json_value(report),"\t"))
	if not capture_dir.is_empty(): FileAccess.open(capture_dir.path_join("results.json"),FileAccess.WRITE).store_string(JSON.stringify(_json_value(report),"\t"))
	print("ANIMATION SEQUENCES: %d checks, %d failures; %d temporal observations; report %s" % [checks,failures,measurements.size(),destination])
	quit(0 if failures==0 else 1)

func _build_battle() -> void:
	var definition: Dictionary = Catalog.definition("mugo")
	player = {"character_id":"mugo","fighter_id":"fixture:animation:mugo","name":"Mugo","level":12,"stats":definition.training_base.duplicate(true),"visual":definition.visual.duplicate(true),"ability":definition.ability.duplicate(true),"signature":definition.signature.duplicate(true)}
	player.combat_stats = Catalog.stats_for(player)
	player.combat_stats.merge({"max_hp":1200.0,"attack":72.0,"defense":35.0,"speed":18.0,"accuracy":1.0,"evasion":0.0,"crit_chance":0.04},true)
	player.moves = []
	for move: Dictionary in Moves.moves_for("mugo"):
		if str(move.type)=="heavy":
			move.cooldown = 0
			player.moves.append(move)
			break
	rival = Story.opponent(7,1)
	rival.combat_stats.merge({"max_hp":440.0,"attack":26.0,"defense":35.0,"speed":18.0,"accuracy":1.0,"evasion":0.0,"crit_chance":0.04},true)
	rival.moves = []
	for move: Dictionary in Moves.moves_for("ascua"):
		if str(move.type) in ["heavy","charge"]:
			move.cooldown = 0
			rival.moves.append(move)
	for candidate in range(100,130):
		var simulation = EngineScript.new()
		simulation.start(player,rival,candidate,OPTIONS)
		while simulation.running: simulation.advance(0.20)
		var summary: Dictionary = simulation.summary()
		var actions := 0
		for event: Dictionary in summary.events:
			if str(event.type)=="move_started" and str(event.get("side",""))=="rival" and float(event.time)<float(summary.duration)-1.8: actions += 1
		if summary.winner=="player" and actions>=2 and float(summary.duration)<18.0:
			seed_value = candidate
			expected = summary
			break
	_check(not expected.is_empty(),"Bounded fixture produces Ascua anticipation, impacts and a real KO without forced poses")

func _build_targets() -> void:
	var action_number := 0
	for event: Dictionary in expected.events:
		if str(event.type)!="move_started" or str(event.get("side",""))!="rival": continue
		var move: Dictionary = event.move
		var start := float(event.time)
		var windup := float(move.windup)
		var impact := float(move.impact_delay)
		var recovery := float(move.recovery)
		var offsets := [0.015,windup*0.50,windup-0.015,windup+float(move.travel)*0.50,impact+0.025,impact+0.095,impact+recovery*0.70,impact+recovery+0.06]
		for index in range(offsets.size()):
			targets.append({"time":start+float(offsets[index]),"label":"ascua_action_%d_%d" % [action_number+1,index+1],"event_time":start,"impact_time":start+impact,"move_id":move.id})
		action_number += 1
		if action_number==2: break
	for offset: float in [-0.03,0.08,0.20,0.34,0.50,0.70,1.0,1.40]:
		targets.append({"time":float(expected.duration)+offset,"label":"ko_%+.2f" % offset,"event_time":float(expected.duration)})
	targets.sort_custom(func(a: Dictionary,b: Dictionary): return float(a.time)<float(b.time))

func _live(dimensions: Vector2i) -> void:
	screen = Fixture.new()
	screen.fixture_path = output_dir.path_join("live_%dx%d.json" % [dimensions.x,dimensions.y])
	screen.fixture_player = player.duplicate(true)
	canvas.add_child(screen)
	screen.size = Vector2(dimensions)
	screen._layout_interface(screen.size)
	screen.rival = rival.duplicate(true)
	screen._start_fight()
	screen.combat.start(player,rival,seed_value,OPTIONS)
	screen.set_process(true)
	_check(screen.rival_view.has_method("get_animation_state"),"FighterView exposes read-only sequence metrics")
	_check(screen.player_view.process_priority<screen.process_priority,"Live aligns renderer clocks before event dispatch")
	await _observe("live",dimensions)
	_check(JSON.stringify(screen.last_battle_summary.events)==JSON.stringify(expected.events),"Live presentation preserves every authoritative event and timing")
	_check(screen.rival_view._mode=="fall","Real terminal event reaches Ascua KO")
	_check(not screen.active_match,"Native fixture completes and commits only its isolated reward")
	screen.set_process(false)
	screen.queue_free()
	await process_frame
	screen = null

func _replay(dimensions: Vector2i) -> void:
	var record := {}
	Records.attach(record,expected)
	_check(not Records.snapshot(record).is_empty(),"Replay consumes valid immutable battle identity and recorded events")
	var stored_path := output_dir.path_join("live_%dx%d.json" % [dimensions.x,dimensions.y])
	var stored_bytes := FileAccess.get_file_as_string(stored_path)
	replay = Replay.new()
	canvas.add_child(replay)
	replay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	replay._layout()
	replay.configure([record])
	replay._toggle()
	await _observe("replay",dimensions)
	_check(replay.event_index==expected.events.size(),"Replay consumes the entire authoritative event sequence")
	_check(replay.actors.rival._mode=="fall","Replay terminal event reaches the same Ascua KO")
	_check(FileAccess.get_file_as_string(stored_path)==stored_bytes,"Replay grants no rewards and never writes the isolated progression")
	replay.queue_free()
	await process_frame
	replay = null

func _observe(presentation: String, dimensions: Vector2i) -> void:
	var time := 0.0
	var index := 0
	var frame_count := 0
	var pause_checked := movie_demo
	var deltas: Array[float] = []
	var memory_begin := _memory()
	_terminal_frame = {}
	_continuous_deltas = []
	_presentation = presentation
	_observing = true
	observer.presentation_time = 0.0
	observer.count_time = true
	while index<targets.size():
		var delta: float = await observer.sampled
		time = observer.presentation_time
		frame_count += 1
		deltas.append(delta)
		if not pause_checked and time>=0.50:
			await _exercise_pause(presentation)
			pause_checked = true
		# Only one capture per real rendered frame. Close targets may be late;
		# measuring that delay is preferable to inventing an intermediate pose.
		if time<float(targets[index].time): continue
		var actor = screen.rival_view if presentation=="live" else replay.actors.rival
		var state: Dictionary = actor.get_animation_state() if actor.has_method("get_animation_state") else {}
		var fx = screen.get("combat_fx") if presentation=="live" else replay.get("_fx")
		var effects: Dictionary = fx.debug_state() if is_instance_valid(fx) and fx.has_method("debug_state") else {}
		if not effects.get("active",[]).is_empty(): seen_fx = true
		var frame_key := str(state.get("clip",""))+":"+str(state.get("frame",""))
		observed_frames[frame_key] = true
		var boundary := _sprite_boundary(actor)
		var player_actor = screen.player_view if presentation=="live" else replay.actors.player
		var player_boundary := _sprite_boundary(player_actor)
		var player_state: Dictionary = player_actor.get_animation_state()
		var visible_rect := Rect2(Vector2.ZERO,Vector2(dimensions))
		if presentation=="replay": visible_rect=visible_rect.intersection(replay._stage.get_global_rect())
		_check(not state.is_empty() and state.get("body_id","")=="ascua","%s: canonical Ascua animation body is resolved" % presentation)
		_check(bool(state.get("enabled",false)),"%s: installed Ascua sequence banks are active" % presentation)
		_check(str(player_state.get("body_id",""))=="mugo" and bool(player_state.get("enabled",false)),"%s: Mugo also uses its installed sequence banks" % presentation)
		if str(state.get("mode",""))=="move":
			var latest: Dictionary = {}
			var engine_time: float = screen.combat.elapsed if presentation=="live" else replay.elapsed
			for event: Dictionary in expected.events:
				if float(event.time)>engine_time: break
				if str(event.type)=="move_started" and str(event.get("side",""))=="rival" and not bool(event.get("counter",false)): latest=event
			if not latest.is_empty(): _check(absf(float(state.elapsed)-(engine_time-float(latest.time)))<0.0001,"%s: sequence clock follows its actual move event through hit stop" % presentation)
			if float(state.get("hit_stop_remaining",0))<=0.0:
				_check(not bool(state.get("fallback",true)),"%s: moving attacks use new physical frames, not the eight-pose fallback" % presentation)
		if time>float(expected.duration)+0.07:
			_check(str(state.get("mode",""))=="fall","%s: Ascua enters KO at terminal contact without waiting for the result card" % presentation)
			# Engine elapsed clamps to the terminal event. A long render frame can
			# dispatch that event after its mathematical time; this is measured,
			# not mistaken for a subsequent KO reset by the result-card callback.
			_check(not _terminal_frame.is_empty(),"%s: the exact terminal process frame was observed independently of screenshots" % presentation)
			if not _terminal_frame.is_empty():
				var ko_origin: float = float(_terminal_frame.time)-float(_terminal_frame.pose_elapsed)
				_check(absf(float(state.elapsed)-(time-ko_origin))<0.001,"%s: result card does not reset or skip the continuous KO clock" % presentation)
		_check(not boundary.is_empty(),"%s: the actual rendered sprite has measurable geometry" % presentation)
		if not boundary.is_empty():
			_check(visible_rect.grow(1.0).encloses(boundary.rect),"%s %s: complete sprite stays inside viewport at %s" % [presentation,dimensions,targets[index].label])
		_check(not player_boundary.is_empty(),"%s: Mugo also has measurable rendered geometry" % presentation)
		if not player_boundary.is_empty():
			_check(visible_rect.grow(1.0).encloses(player_boundary.rect),"%s %s: complete Mugo sprite stays inside viewport at %s" % [presentation,dimensions,targets[index].label])
		var checkpoint: Dictionary = {"presentation":presentation,"viewport":[dimensions.x,dimensions.y],"index":index,
			"target":targets[index],"actual_time":time,"late_by":time-float(targets[index].time),"frame_delta":delta,
			"engine_time":float(screen.combat.elapsed) if presentation=="live" else float(replay.elapsed),
			"state":state,"geometry":boundary,"player_state":player_state,"player_geometry":player_boundary,"fx":effects,"memory":_memory()}
		if not _terminal_frame.is_empty(): checkpoint["terminal_dispatch"]=_terminal_frame.duplicate(true)
		if not capture_dir.is_empty():
			await RenderingServer.frame_post_draw
			var path := capture_dir.path_join("%dx%d-%s-%02d-%s.png" % [dimensions.x,dimensions.y,presentation,index,targets[index].label])
			var image: Image = canvas.get_texture().get_image()
			_check(image.get_size()==dimensions,"Native capture keeps exact viewport size")
			_check(image.save_png(path)==OK,"Native chronological frame is saved")
			checkpoint["capture"] = path
		measurements.append(checkpoint)
		index += 1
	_observing = false
	deltas = _continuous_deltas.duplicate()
	deltas.sort()
	runtimes.append({"presentation":presentation,"viewport":[dimensions.x,dimensions.y],"frames":deltas.size(),"elapsed":time,"delta_median":deltas[deltas.size()/2],"delta_p95":deltas[mini(deltas.size()-1,int(deltas.size()*0.95))],"memory_start":memory_begin,"memory_end":_memory(),"terminal_dispatch":_terminal_frame.duplicate(true)})

func _track_frame(delta: float) -> void:
	if not _observing or not observer.count_time: return
	_continuous_deltas.append(delta)
	if not _terminal_frame.is_empty(): return
	var engine_time: float = screen.combat.elapsed if _presentation=="live" else replay.elapsed
	if engine_time<float(expected.duration): return
	var actor = screen.rival_view if _presentation=="live" else replay.actors.rival
	var time := observer.presentation_time
	var lag := time-float(expected.duration)-float(actor._action_time)
	_terminal_frame = {"time":time,"delta":delta,"engine_time":engine_time,"pose_elapsed":float(actor._action_time),"mode":str(actor._mode),"lag":lag}
	_check(str(actor._mode)=="fall","%s: terminal process frame immediately binds Ascua KO" % _presentation)
	_check(lag>=-0.001 and lag<=delta+0.001,"%s: terminal dispatch lag is bounded by that exact process frame" % _presentation)

func _exercise_pause(presentation: String) -> void:
	# Exercise the public pause path in the same continuous battle, after the
	# first real anticipation emitted its FX. Paused deltas do not enter time.
	var actor = screen.rival_view if presentation=="live" else replay.actors.rival
	var fx = screen.get("combat_fx") if presentation=="live" else replay.get("_fx")
	var effects: Dictionary = fx.debug_state() if is_instance_valid(fx) else {}
	var engine_time: float = screen.combat.elapsed if presentation=="live" else replay.elapsed
	var action_time: float = actor._action_time
	observer.count_time = false
	if presentation=="live": screen._open_document("Prueba de pausa","Fixture aislada","La preparación y sus efectos deben conservar el mismo reloj.")
	else: replay._toggle()
	_check(is_instance_valid(fx) and fx.motion_paused,"%s: pause callback stops FX immediately, before the next process frame" % presentation)
	for index in range(3):
		await observer.sampled
		var current: float = screen.combat.elapsed if presentation=="live" else replay.elapsed
		_check(is_equal_approx(current,engine_time) and is_equal_approx(actor._action_time,action_time),"%s: real pause freezes both authoritative and presentation clocks" % presentation)
		if is_instance_valid(fx): _check(fx.debug_state().get("active",[])==effects.get("active",[]) and fx.debug_state().get("pending",0)==effects.get("pending",0),"%s: pause neither ages nor emits queued FX" % presentation)
	if presentation=="live": screen._close_modal()
	else: replay._toggle()
	observer.count_time = true
	_check(is_instance_valid(fx) and not fx.motion_paused,"%s: resume releases FX immediately without a frame of lag" % presentation)

func _sprite_boundary(actor) -> Dictionary:
	var sprite: Sprite2D = actor.get("_sprite")
	if not is_instance_valid(sprite) or sprite.texture==null: return {}
	var current: Dictionary = actor._current_frame()
	var local := Rect2(Vector2(current.bounds.position)-Vector2(current.anchor),Vector2(current.bounds.size))
	var xform: Transform2D = sprite.get_global_transform()
	var corners: Array[Vector2] = [xform*local.position,xform*Vector2(local.end.x,local.position.y),xform*local.end,xform*Vector2(local.position.x,local.end.y)]
	var rectangle := Rect2(corners[0],Vector2.ZERO)
	for point: Vector2 in corners: rectangle=rectangle.expand(point)
	return {"rect":rectangle,"local_rect":local,"sprite_scale":sprite.scale,"sprite_rotation":sprite.rotation,"actor_position":actor.position,"texture_size":Vector2(sprite.texture.get_size())}

func _memory() -> Dictionary:
	return {"static_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC)),"texture_bytes":int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)),"objects":int(Performance.get_monitor(Performance.OBJECT_COUNT))}

func _json_value(value: Variant) -> Variant:
	if value is Vector2 or value is Vector2i: return [value.x,value.y]
	if value is Rect2 or value is Rect2i: return [value.position.x,value.position.y,value.size.x,value.size.y]
	if value is Color: return value.to_html()
	if value is Dictionary:
		var output := {}
		for key: Variant in value: output[str(key)]=_json_value(value[key])
		return output
	if value is Array:
		var output := []
		for item: Variant in value: output.append(_json_value(item))
		return output
	return value
