extends SceneTree
## Explicit technical demonstrations, with a manual presentation clock.
## No Main boot, progress adapter, user save, reward or catalog mutation.
const Fighter = preload("res://scripts/fighter_view.gd")
const FX = preload("res://scripts/combat_fx.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Story = preload("res://scripts/story_catalog.gd")
const Cosmetics = preload("res://scripts/cosmetic_catalog.gd")
const Moves = preload("res://scripts/move_catalog.gd")
const Combat = preload("res://scripts/combat_engine.gd")
const Records = preload("res://scripts/battle_identity.gd")
const Replay = preload("res://scripts/ui/battle_replay_panel.gd")
const SIZES: Array[Vector2i] = [Vector2i(1360,880),Vector2i(390,844)]
const TITLES := ["Carga y contacto", "Fuego y transformación", "Veneno, escudo y entrada", "Salto y desplazamiento"]
const NOTES := ["Ónix · carga / Farol\nBruma · impacto / Luciérnagas", "Ascua · núcleo encendido\nLuma · estado de quemadura", "Ónix · veneno / Corona\nBruma · escudo / entrada Pulso", "Ónix · salto y polvo\nBruma · estela de desplazamiento"]
var checks := 0
var failures := 0
var capture_dir := ""
var baseline := false
var video_frames := false
var video_only := false
var canvas: SubViewport
var scene: Control
var actors: Array = []
var fx
var fighter_script: Script = Fighter
var fx_script: Script = FX
var observations: Array[Dictionary] = []
var current_case := 0
var dimensions := Vector2i.ZERO
var clock_label: Label

func _init() -> void: _run.call_deferred()

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ORGANIC FX: "+description)

func _run() -> void:
	create_timer(300,true,false,true).timeout.connect(func(): push_error("ORGANIC FX timeout"); quit(1))
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): capture_dir=arg.trim_prefix("--capture-dir=")
		elif arg=="--baseline": baseline=true
		elif arg=="--video-frames": video_frames=true
		elif arg=="--video-only": video_only=true
	if not capture_dir.is_empty():
		if not capture_dir.is_absolute_path() or DisplayServer.get_name()=="headless":
			push_error("Native renderer and absolute capture directory required")
			quit(2)
			return
		DirAccess.make_dir_recursive_absolute(capture_dir)
	if baseline:
		fighter_script=_previous("fighter-before.gd","class_name FighterView")
		fx_script=_previous("combat_fx-before.gd","class_name CombatFX")
		if fighter_script==null or fx_script==null: quit(2); return
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(360,240)
	canvas=SubViewport.new()
	canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	for size_value: Vector2i in SIZES:
		if video_only:
			await _video(size_value)
			continue
		for index in range(4):
			_build(index,size_value)
			_apply_case(index)
			_step(0.085 if index==0 else 0.18 if index==3 else 0.16)
			if not baseline: _bounds("case "+str(index))
			await _capture("%s-%dx%d" % [str(index+1),size_value.x,size_value.y])
			observations.append({"case":TITLES[index],"size":[size_value.x,size_value.y],"manual_presentation_clock":true,"baseline":baseline,"fx":fx.debug_state(),"actors":[actors[0].get_animation_state(),actors[1].get_animation_state()]})
		if not baseline:
			_follow_and_controls()
			_delta_rates()
			await _replay(size_value)
			if video_frames: await _video(size_value)
	if not capture_dir.is_empty() and not video_only:
		var file := FileAccess.open(capture_dir.path_join("observations.json"),FileAccess.WRITE)
		check(file!=null,"Native observation report can be written")
		if file!=null:
			file.store_string(JSON.stringify({"checks":checks,"failures":failures,"baseline":baseline,"source":"Presentation-only technical fixture; replay events from an in-memory combat engine","real_saves_accessed":false,"observations":observations},"\t"))
			file.close()
	if is_instance_valid(scene): scene.free()
	canvas.free()
	await process_frame
	print(("ORGANIC FX VIDEO: %d checks, %d failures" if video_only else "ORGANIC FX: %d checks, %d failures") % [checks,failures])
	quit(0 if failures==0 else 1)

func _previous(filename: String, declaration: String) -> Script:
	var directory := ProjectSettings.globalize_path("res://../../work/organic-fx").simplify_path()
	var source := FileAccess.get_file_as_string(directory.path_join(filename)).replace(declaration,"")
	if filename=="combat_fx-before.gd": source=source.replace("res://data/combat_fx.json",directory.path_join("combat_fx-before.json"))
	var script := GDScript.new()
	script.source_code=source
	if script.reload()!=OK:
		push_error("Cannot compile read-only baseline "+filename)
		return null
	return script

func _descriptor(id: String, aura: String="none", intro: String="classic") -> Dictionary:
	var definition := Story.boss_definition(1) if id=="ascua" else Catalog.definition(id)
	definition=definition.duplicate(true)
	definition["character_id"]=str(definition.get("character_id",id))
	definition["level"]=20
	definition["fighter_id"]="fixture:organic:"+id
	if not definition.has("combat_stats"): definition["combat_stats"]=Catalog.stats_for({"character_id":id,"level":20})
	if id!="ascua":
		definition["appearance"]=Cosmetics.default_appearance(id)
		definition.appearance.aura_id=aura
		definition.appearance.intro_animation_id=intro
	return definition

func _build(index: int, size_value: Vector2i) -> void:
	if is_instance_valid(scene): scene.free()
	actors.clear()
	dimensions=size_value
	current_case=index
	canvas.size=size_value
	scene=Control.new()
	scene.size=Vector2(size_value)
	canvas.add_child(scene)
	var background := TextureRect.new()
	background.texture=load("res://assets/arena-faroles-v2.png")
	background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.size=Vector2(size_value)
	scene.add_child(background)
	var shade := ColorRect.new()
	shade.color=Color(0.02,0.055,0.065,0.32)
	shade.size=Vector2(size_value)
	scene.add_child(shade)
	var margin := 20.0 if size_value.x<640 else 44.0
	_label("BRASA · Muestra técnica",Vector2(margin,20),Vector2(size_value.x-margin*2,30),18,Color("cda977"))
	_label(TITLES[index],Vector2(margin,55),Vector2(size_value.x-margin*2,76),25 if size_value.x<640 else 36,Color("f5e4c8"))
	clock_label=_label("ANTES · reloj manual" if baseline else "PARTÍCULAS · reloj manual",Vector2(margin,116),Vector2(size_value.x-margin*2,26),13,Color("a8c4bf"))
	var pair := ["ascua","luma"] if index==1 else ["onix","bruma"]
	var appearance_ids := ["farol","luciernagas"] if index==0 else ["corona","none"] if index==2 else ["none","none"]
	var scale_value := 0.94 if size_value.x<640 else 1.75
	var floor_y := size_value.y*0.67
	for side in range(2):
		var actor = fighter_script.new()
		scene.add_child(actor)
		actor.setup_character(_descriptor(pair[side],appearance_ids[side],"pulso" if index==2 and side==1 else "classic"),1 if side==0 else -1)
		actor.prepare_combat_animation()
		actor.set_process(false)
		actor._intro_elapsed=10.0
		actor.position=Vector2(size_value.x*(0.29 if side==0 else 0.71),floor_y)
		# The current Ascua transformation extends 3px beyond this technical
		# fixture's mobile safe margin. This adjusts only the sample staging.
		if size_value.x < 640 and index == 1 and side == 0: actor.position.x += 8
		actor.scale=Vector2.ONE*scale_value
		actor._process(0)
		actors.append(actor)
		var width := (size_value.x-margin*2-16)/2.0
		_label(str(_descriptor(pair[side]).name),Vector2(margin+side*(width+16),155),Vector2(width,28),18,Color("f5e4c8"))
		var bar := ColorRect.new()
		bar.position=Vector2(margin+side*(width+16),188)
		bar.size=Vector2(width,6)
		bar.color=Color("63b0a0")
		scene.add_child(bar)
	fx=fx_script.new()
	scene.add_child(fx)
	fx.set_process(false)
	_label(NOTES[index],Vector2(margin,floor_y+36),Vector2(size_value.x-margin*2,72),17 if size_value.x<640 else 21,Color("f5e4c8"))
	_label("Efectos activados para inspección.\nSin combate, recompensas ni guardados.",Vector2(margin,size_value.y-99),Vector2(size_value.x-margin*2,70),13,Color("a8c4bf"))

func _label(value: String, at: Vector2, extent: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text=value
	label.position=at
	label.size=extent
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	scene.add_child(label)
	return label

func _move(kind: String) -> Dictionary:
	for id: String in ["onix","bruma","mugo","luma","nima"]:
		for move: Dictionary in Moves.moves_for(id):
			if str(move.type)==kind: return move.duplicate(true)
	return {}

func _start_move(actor, kind: String, age: float=0) -> void:
	var move := _move(kind)
	check(not move.is_empty(),"Technical gesture comes from a real catalog move: "+kind)
	var event := {"type":"move_started","side":"player","time":0,"move":move}
	var before := JSON.stringify(event)
	actor.play_move(move,age)
	fx.play_move(event,actor,age)
	check(JSON.stringify(event)==before,"Presenting "+kind+" preserves its input event")

func _at(actor, kind: String) -> Vector2:
	return fx.to_local(actor.to_global(actor.effect_anchor(kind))) if actor.has_method("effect_anchor") else actor.position+Vector2(0,-78)*actor.scale

func _apply_case(index: int) -> void:
	match index:
		0:
			_start_move(actors[0],"charge",0.16)
			actors[1].play_reaction({"result":"critical","damage":30,"target_hp":80,"presentation":{"hit_reaction":"heavy"}})
			fx.play_impact(_at(actors[1],"chest"),{"impact_fx":"critical_hit","animation_type":"heavy","reaction":"critical","camera_feedback":"none"},actors[1].scale.x,1)
		1:
			actors[0].play_transformation("ember_core")
			fx.play_status({"type":"ability","ability_id":"phase_shift","phase_index":1},actors[0])
			fx.play_status({"type":"status_applied","effect":"burn"},actors[1])
		2:
			actors[1].play_intro()
			fx.play_status({"type":"status_applied","effect":"poison"},actors[0])
			fx.play_status({"type":"shield"},actors[1])
		3:
			_start_move(actors[0],"jump",0.16)
			_start_move(actors[1],"dash",0.07)

func _step(delta: float) -> void:
	for actor in actors: actor._process(delta)
	fx._process(delta)

func _bounds(label: String) -> void:
	var state: Dictionary = fx.debug_state()
	var safe := Rect2(8,204,dimensions.x-16,dimensions.y-324)
	var within := true
	var modest := true
	var visible := 0
	for effect: Dictionary in state.active:
		for particle: Dictionary in effect.get("particles",[]):
			if float(particle.color.a)<0.01: continue
			visible+=1
			var extent: float = maxf(particle.radius.x,particle.radius.y)+float(particle.get("length",0))
			within = within and safe.encloses(Rect2(particle.at-Vector2.ONE*extent,Vector2.ONE*extent*2))
			modest = modest and maxf(particle.radius.x,particle.radius.y)<=6*float(actors[0].scale.x)
	check(within,label+": particles remain inside the arena and below the sample HUD")
	check(modest,label+": individual grains stay small rather than becoming screen-sized circles")
	check(int(state.particles)<=320,label+": global particle budget remains bounded")
	check(visible>0,label+": sample contains visible live particles")
	for actor in actors:
		var actor_bounds: Rect2 = actor.visible_sprite_bounds()
		check(safe.encloses(actor_bounds),label+": whole illustrated pose stays below the sample HUD")

func _follow_and_controls() -> void:
	# Compare anchors under a translated/scaled parent and both facing directions.
	fx.clear()
	for actor in actors:
		actor.reset_pose()
		actor._intro_elapsed=10.0
	var actor = actors[0]
	actor.play_move(_move("jump"),0.18)
	fx.play_status({"type":"status_applied","effect":"poison"},actor)
	var first: Dictionary = fx.debug_state().active[0]
	var first_origin: Vector2 = first.at
	actor._process(0.045)
	fx._process(0.045)
	var later: Dictionary = fx.debug_state().active[0]
	check(Vector2(later.at).is_equal_approx(_at(actor,"chest")),"Status emitter follows the current jumping sprite anchor")
	check(first_origin.distance_to(later.at)>0.1,"Jump actually moved the tested emission point")
	var particle_at: Vector2 = later.particles[0].at
	actor.position.x+=35
	fx._process(0.001)
	var detached: Dictionary = fx.debug_state().active[0]
	check(Vector2(detached.at).is_equal_approx(_at(actor,"chest")) and Vector2(detached.particles[0].at).distance_to(particle_at)<1.0,"Released particles drift independently while the emitter follows the actor")
	actor.position.x-=35
	for kind: String in ["charge","jump","dash"]:
		var left: Dictionary = {}
		for facing in [-1,1]:
			actor.facing=facing
			actor.reset_pose()
			actor.play_move(_move(kind),0.20)
			for anchor: String in ["chest","hand","back","feet"]:
				check(actor.effect_anchor(anchor).is_finite(),kind+" has a finite "+anchor+" anchor while facing "+str(facing))
				if facing<0: left[anchor]=actor.effect_anchor(anchor)
				else:
					var right: Vector2 = actor.effect_anchor(anchor)
					check(right.is_equal_approx(Vector2(-left[anchor].x,left[anchor].y)),kind+" mirrors the "+anchor+" anchor with the actual sprite")
	fx.clear()
	fx.play_status({"type":"heal"},actor)
	check(str(fx.debug_state().active[0].style)=="heal","Healing has a distinct cool pigment treatment")
	actor.motion_paused=true
	fx.motion_paused=true
	var frozen := JSON.stringify(fx.debug_state())
	var frozen_actor := JSON.stringify(actor.get_animation_state())
	actor._process(0.5)
	fx._process(0.5)
	check(JSON.stringify(fx.debug_state())==frozen and JSON.stringify(actor.get_animation_state())==frozen_actor,"Paused presentation freezes actor and particles at the same instant")
	actor.motion_paused=false
	fx.motion_paused=false
	actor._process(0.02)
	fx._process(0.02)
	check(JSON.stringify(fx.debug_state())!=frozen,"Resume advances the same particles")
	set_meta("brasa_reduced_motion",true)
	actor._process(0.02)
	fx._process(0.02)
	check(fx.debug_state().active.is_empty() and fx.debug_state().pending==0 and fx.camera_offset()==Vector2.ZERO,"Reduced motion clears bursts, pending emissions and shake")
	remove_meta("brasa_reduced_motion")
	actor.reduced_motion=false
	fx.reduced_motion=false

func _delta_rates() -> void:
	for fps in [20,60,120]:
		fx.clear()
		var actor = actors[0]
		actor.facing=1
		actor.reset_pose()
		actor.play_move(_move("jump"))
		fx.play_move({"move":_move("jump")},actor)
		fx.play_status({"type":"status_applied","effect":"burn"},actor)
		var finite := true
		var bounded := true
		for frame in range(fps):
			actor._process(1.0/fps)
			fx._process(1.0/fps)
			var state: Dictionary = fx.debug_state()
			bounded = bounded and int(state.particles)<=320
			for effect: Dictionary in state.active:
				finite = finite and Vector2(effect.at).is_finite()
		check(finite and bounded,"Particles remain finite and bounded at %d FPS" % fps)
		fx._process(1)
		check(fx.debug_state().active.is_empty() and fx.debug_state().pending==0,"Effects fully settle at %d FPS" % fps)

func _replay(size_value: Vector2i) -> void:
	# Engine produces the record; test only controls its historical playback clock.
	var engine := Combat.new()
	var player := _descriptor("onix","farol")
	var rival := _descriptor("bruma","luciernagas")
	player["moves"]=[_move("charge")]
	engine.start(player,rival,49271,{"opening_time":0.2,"disable_signatures":true,"battle_id":"fixture:organic-replay"})
	engine.advance(120)
	var summary: Dictionary = engine.summary()
	var original := JSON.stringify(summary)
	var record := {}
	Records.attach(record,summary)
	var replay = Replay.new()
	canvas.add_child(replay)
	replay.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	replay.size=Vector2(size_value)
	replay.configure([record])
	replay.set_process(false)
	replay._fx.set_process(false)
	for body in replay.actors.values(): body.set_process(false)
	check(not replay.snapshot.is_empty(),"Replay loads an actual engine record using only in-memory descriptors")
	var sample_time := 0.0
	for event: Dictionary in summary.events:
		if str(event.type)=="move_started" and str(event.get("side",""))=="player" and str(event.get("move",{}).get("type",""))=="charge":
			sample_time=float(event.time)+0.10
			break
	check(sample_time>0,"Actual replay contains a charge with an observable emitter")
	replay._toggle()
	replay._process(sample_time)
	for body in replay.actors.values(): body._process(0.025)
	replay._fx._process(0.025)
	check(not replay._fx.debug_state().active.is_empty(),"Pause regression starts with live FX rather than an empty scene")
	replay._toggle()
	var before := JSON.stringify(replay._fx.debug_state())
	var elapsed_before: float = replay.elapsed
	var indices_before: int = replay.event_index
	var actor_before := JSON.stringify(replay.actors.player.get_animation_state())
	replay._process(0.5)
	for body in replay.actors.values(): body._process(0.5)
	replay._fx._process(0.5)
	check(replay.elapsed==elapsed_before and replay.event_index==indices_before,"Real replay pause freezes timeline and event cursor")
	check(JSON.stringify(replay._fx.debug_state())==before and JSON.stringify(replay.actors.player.get_animation_state())==actor_before,"Replay pause freezes particles and the current illustrated pose")
	replay._note.text="Muestra técnica · repetición de un combate en memoria"
	await _capture("replay-paused-%dx%d" % [size_value.x,size_value.y])
	set_meta("brasa_reduced_motion",true)
	for body in replay.actors.values(): body._process(0.016)
	replay._fx._process(0.016)
	check(replay._fx.debug_state().active.is_empty() and replay._fx.camera_offset()==Vector2.ZERO,"Reduced motion works even while historical playback is paused")
	replay._note.text="Muestra técnica · pausa y movimiento reducido"
	await _capture("replay-reduced-%dx%d" % [size_value.x,size_value.y])
	remove_meta("brasa_reduced_motion")
	check(JSON.stringify(summary)==original and record.battle_snapshot.events==summary.events,"FX and replay leave the authoritative record immutable")
	replay.free()

func _video(size_value: Vector2i) -> void:
	if capture_dir.is_empty(): return
	var directory := capture_dir.path_join("frames-%dx%d" % [size_value.x,size_value.y])
	DirAccess.make_dir_recursive_absolute(directory)
	# Four brief gesture loops, each explicitly labelled as a manual-clock sample.
	for index in range(4):
		_build(index,size_value)
		_apply_case(index)
		for frame in range(24):
			if frame==12 and index==0:
				fx.play_impact(_at(actors[1],"chest"),{"impact_fx":"small_hit","camera_feedback":"none"},actors[1].scale.x,1)
			elif frame==12 and index==2:
				fx.play_status({"type":"heal"},actors[0])
			_step(1.0/30.0)
			clock_label.text=("CURA · reloj manual %.2f s" if index==2 and frame>=12 else "MUESTRA · reloj manual %.2f s") % ((frame+1)/30.0)
			await process_frame
			await RenderingServer.frame_post_draw
			canvas.get_texture().get_image().save_png(directory.path_join("frame-%04d.png" % (index*24+frame)))

func _capture(name: String) -> void:
	if capture_dir.is_empty(): return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	check(canvas.get_texture().get_image().save_png(capture_dir.path_join(name+".png"))==OK,"Saved native "+name)
