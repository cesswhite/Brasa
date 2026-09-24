extends SceneTree
## Native, real-clock visual acceptance stage. It never opens a save or network.
## --write-movie work/...avi --fixed-fps 60 --resolution 1360x880
## --script res://tests/test_visual_consistency_showcase.gd -- --capture-dir=/absolute/work/path
## --body=neris --no-captures runs an unencumbered native 1x playback.
const Fighter = preload("res://scripts/fighter_view.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Story = preload("res://scripts/story_catalog.gd")
const Moves = preload("res://scripts/move_catalog.gd")
const Sets = preload("res://scripts/fighter_animation_set.gd")
const FX = preload("res://scripts/combat_fx.gd")
var actor: Node2D
var reference: Node2D
var effects: Node2D
var caption: Label
var detail: Label
var output := ""
var observations: Array[Dictionary] = []
var observed_frames: Dictionary = {}
var failures := 0
var timeline := 0.0
var segment := ""
var captured: Dictionary = {}
var canvas: SubViewport
var body_id := "ascua"
var body_name := "Ascua"
var damage_health := 1.0
var captures_enabled := true
var segment_reports: Array[Dictionary] = []
var capture_usec := 0
var skipped_transformations: Array[String] = []
var playback_start_usec := 0
var active_source := "presentation_fixture"
var active_move_id := ""
var segment_display_elapsed := 0.0

class LiveTelemetry:
	extends Node
	var harness: SceneTree
	func _process(delta: float) -> void: harness.update_telemetry(delta)

class Stage:
	extends Node2D
	func _draw() -> void:
		draw_rect(Rect2(0,0,1360,880),Color("17221f"))
		draw_rect(Rect2(0,690,1360,190),Color("101916"))
		draw_line(Vector2(120,690),Vector2(1240,690),Color("637a65"),1.0)
		for x: float in [400.0,930.0]:
			draw_line(Vector2(x-12,690),Vector2(x+12,690),Color("b1c0a6"),2.0)
			draw_line(Vector2(x,679),Vector2(x,701),Color("b1c0a6"),2.0)

func _init() -> void: _run.call_deferred()

func label_at(text: String, at: Vector2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text=text
	label.position=at
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	canvas.add_child(label)
	return label

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): output=arg.trim_prefix("--capture-dir=")
		elif arg.begins_with("--body="): body_id=arg.trim_prefix("--body=")
		elif arg=="--no-captures": captures_enabled=false
		elif arg.begins_with("--damage-health="): damage_health=arg.trim_prefix("--damage-health=").to_float()
	var definition: Dictionary=Story.boss_definition(1) if body_id=="ascua" else Story.boss_definition(2) if body_id=="vespera" else preload("res://scripts/cosmetic_catalog.gd").body_definition(body_id)
	if definition.is_empty():
		push_error("Unknown showcase body: "+body_id)
		quit(2)
		return
	body_name=str(definition.name)
	if output.is_empty(): output=ProjectSettings.globalize_path("res://../../work/visual-consistency/pilot" if body_id=="ascua" else "res://../../work/visual-consistency/roster-native/"+body_id)
	DirAccess.make_dir_recursive_absolute(output)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	Engine.max_fps=60
	canvas=SubViewport.new()
	canvas.size=Vector2i(1360,880)
	canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	var display := TextureRect.new()
	display.texture=canvas.get_texture()
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	display.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	root.add_child(display)
	canvas.add_child(Stage.new())
	label_at(body_name.to_upper()+" · CONTINUIDAD DE ANIMACIÓN",Vector2(90,60),25,Color("ede3c6"))
	label_at("Referencia canónica",Vector2(280,730),20,Color("b7c6b5"))
	label_at("Misma escala física · velocidad 1×",Vector2(735,730),20,Color("b7c6b5"))
	caption=label_at("",Vector2(90,112),32,Color("e9bd68"))
	detail=label_at("",Vector2(90,165),16,Color("9eaf9f"))
	reference=Fighter.new()
	reference.setup_character(definition,1)
	reference.position=Vector2(400,690)
	reference.scale=Vector2.ONE*1.50
	canvas.add_child(reference)
	reference.set_process(false)
	actor=Fighter.new()
	actor.setup_character(definition,1)
	actor.position=Vector2(930,690)
	actor.scale=reference.scale
	canvas.add_child(actor)
	actor.prepare_combat_animation()
	actor.set_health_ratio(damage_health)
	effects=FX.new()
	canvas.add_child(effects)
	var telemetry := LiveTelemetry.new()
	telemetry.harness=self
	telemetry.process_priority=1000
	canvas.add_child(telemetry)
	# Exclude resource-import/setup deltas from measured 1x playback.
	for _warmup_frame in range(3):
		await process_frame
		if DisplayServer.get_name()!="headless": await RenderingServer.frame_post_draw
	playback_start_usec=Time.get_ticks_usec()
	await run_segment("Guardia e idle",1.4)
	for kind: String in ["quick","heavy","charge","dash","jump","signature"]:
		var move: Dictionary=showcase_move(kind)
		actor.play_move(move)
		effects.play_move({"move":move,"move_id":move.id,"time":timeline},actor)
		await run_segment("Ataque: "+kind,float(move.duration)+0.50,float(move.impact_delay))
	active_source="reaction_clip_catalogue"
	active_move_id=""
	for reaction: String in ["light","body","heavy","critical","knockback","knockdown","getup"]:
		actor.play_reaction({"result":"critical" if reaction=="critical" else "hit","target_hp":100,"presentation":{"hit_reaction":reaction}})
		await run_segment("Reacción: "+reaction,float(Sets.REACTION_CLIPS[reaction].duration)+0.32)
	var transformations: Dictionary=Sets.TRANSFORMATIONS.get(body_id,{})
	if transformations.is_empty():
		skipped_transformations.append("No supported transformation is registered for "+body_id+"; no unrelated form applied.")
	else:
		for form_id: String in transformations:
			active_source="registered_transformation"
			active_move_id=form_id
			if not actor.play_transformation(form_id): failures+=1
			await run_segment("Transformación · núcleo localizado" if body_id=="ascua" and form_id=="ember_core" else "Transformación: "+form_id,1.5)
			var charge: Dictionary=showcase_move("charge")
			actor.play_move(charge)
			effects.play_move({"move":charge,"move_id":charge.id,"time":timeline},actor)
			await run_segment("Ataque transformado",float(charge.duration)+0.45,float(charge.impact_delay))
			actor.play_transformation(form_id,false)
			active_source="registered_transformation"
			active_move_id=form_id
			await run_segment("Retorno a materiales normales",0.7)
	active_source="battle_resolution_fixture"
	active_move_id=""
	actor.resolve_battle(true)
	await run_segment("Victoria tras resolución",1.2)
	actor.reset_pose()
	actor.set_health_ratio(damage_health)
	actor.resolve_battle(false)
	await run_segment("KO y pose final estable",1.3)
	if actor.get_animation_state().visual_state!="KO": failures+=1
	var wall_seconds: float=float(Time.get_ticks_usec()-playback_start_usec)/1000000.0
	var report: Dictionary={"body_id":body_id,"body_name":body_name,"renderer":DisplayServer.get_name(),"native":DisplayServer.get_name()!="headless","timing":"SceneTree 1x playback with measured wall clock and process deltas; each move segment declares catalogue or labeled fixture timing.","captures_enabled":captures_enabled,"captures":captured.size(),"capture_write_seconds":float(capture_usec)/1000000.0,"wall_duration_seconds":wall_seconds,"duration":timeline,"engine_time_scale":Engine.time_scale,"movie_writer_enabled":OS.get_cmdline_args().has("--write-movie"),"failures":failures,"observed_frames":observed_frames.keys(),"observations":observations,"segments":segment_reports,"skipped_transformations":skipped_transformations,"fixture":"Visual presentation acceptance only; no combat outcomes, accounts, saves or rewards."}
	FileAccess.open(output.path_join("showcase.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("VISUAL SHOWCASE %s: %d frames, %d observations, %d failures, %.3f wall seconds, captures=%s; %s" % [body_id,observed_frames.size(),observations.size(),failures,wall_seconds,str(captures_enabled),output])
	quit(1 if failures else 0)

func showcase_move(kind: String) -> Dictionary:
	for candidate: Dictionary in Moves.moves_for(body_id):
		if str(candidate.animation_type)==kind:
			active_source="character_move_catalogue"
			active_move_id=str(candidate.id)
			return candidate.duplicate(true)
	active_source="visual_fixture_no_catalogue_move_of_type"
	active_move_id="visual_fixture_"+body_id+"_"+kind
	return {"id":active_move_id,"name":"Visual fixture: "+kind,"type":kind,"animation_type":kind,"windup":0.34,"travel":0.18,"recovery":0.32,"impact_delay":0.52,"duration":0.84}

func visual_bounds(state: Dictionary) -> Array[float]:
	var sprite: Sprite2D=actor.get_node("IllustratedFighter")
	var bounds: Rect2=Rect2(state.bounds)
	var points: Array[Vector2]=[bounds.position,bounds.position+Vector2(bounds.size.x,0),bounds.end,bounds.position+Vector2(0,bounds.size.y)]
	var world := Rect2(sprite.to_global(points[0]+sprite.offset),Vector2.ZERO)
	for point: Vector2 in points: world=world.expand(sprite.to_global(point+sprite.offset))
	return [world.position.x,world.position.y,world.size.x,world.size.y]

func update_telemetry(delta: float) -> void:
	if segment.is_empty(): return
	segment_display_elapsed+=delta
	var state: Dictionary=actor.get_animation_state()
	detail.text="%s · %s · %s · %.2f s\n%s: %s" % [str(state.profile_id),str(state.visual_state),str(state.frame),segment_display_elapsed,active_source,active_move_id]

func run_segment(title: String, duration: float, impact: float=-1.0) -> void:
	segment=title
	segment_display_elapsed=0.0
	caption.text=title
	var elapsed := 0.0
	var hit := false
	var last_frame := ""
	var start_usec := Time.get_ticks_usec()
	var samples := 0
	var max_delta := 0.0
	while elapsed<duration:
		await process_frame
		if DisplayServer.get_name()!="headless": await RenderingServer.frame_post_draw
		var delta := actor.get_process_delta_time()
		elapsed+=delta
		timeline+=delta
		samples+=1
		max_delta=maxf(max_delta,delta)
		var state: Dictionary=actor.get_animation_state()
		var frame := str(state.frame)
		observed_frames[frame]=true
		if not bool(state.normalized): failures+=1
		if frame!=last_frame:
			observations.append({"segment":title,"time":timeline,"wall_time":float(Time.get_ticks_usec()-playback_start_usec)/1000000.0,"elapsed":elapsed,"frame":frame,"state":str(state.visual_state),"normalized":bool(state.normalized),"attached_fx":bool(state.attached_fx),"ground_y":actor.to_global(actor.effect_anchor("ground")).y,"density":state.pixels_per_world_unit,"grounded":bool(state.grounded),"visual_bounds_world":visual_bounds(state),"source_path":str(state.source_path),"draw_scale":[state.draw_scale.x,state.draw_scale.y],"move_id":active_move_id,"timing_source":active_source})
			last_frame=frame
			var key := title.validate_filename()+"-"+frame
			if captures_enabled and DisplayServer.get_name()!="headless" and not captured.has(key):
				captured[key]="%03d-%s.png" % [captured.size()+1,key]
				var capture_start := Time.get_ticks_usec()
				canvas.get_texture().get_image().save_png(output.path_join(str(captured[key])))
				capture_usec+=Time.get_ticks_usec()-capture_start
			if captured.has(key): observations[-1]["capture_file"]=captured[key]
		if impact>=0 and elapsed>=impact and not hit:
			hit=true
			actor.move_impact(false)
			effects.play_impact(actor.to_global(actor.effect_anchor("hand")),{"impact_fx":"heavy_hit","reaction":"heavy"},actor.scale.x,1)
	segment_reports.append({"segment":title,"requested_duration":duration,"process_duration":elapsed,"wall_duration":float(Time.get_ticks_usec()-start_usec)/1000000.0,"process_frames":samples,"maximum_process_delta":max_delta,"timing_source":active_source,"move_id":active_move_id})
