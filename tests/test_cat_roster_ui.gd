extends SceneTree
## Real Main/identity/Story controls using only explicit disposable fixture paths.
const Base = preload("res://tests/test_identity_integration.gd")
const Progress = preload("res://scripts/progression.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Story = preload("res://scripts/story_progression.gd")
const Identity = preload("res://scripts/fighter_identity.gd")
const Cosmetics = preload("res://scripts/cosmetic_catalog.gd")
const Sets = preload("res://scripts/fighter_animation_set.gd")
const Fighter = preload("res://scripts/fighter_view.gd")
const IDS: Array[String] = ["onix", "bruma"]
const SIZES: Array[Vector2i] = [Vector2i(1360,880), Vector2i(390,844)]
var checks := 0
var failures := 0
var screen
var canvas: SubViewport
var capture_dir := ""
var save_path := ""
var observations: Array[Dictionary] = []

func _init() -> void: _run.call_deferred()

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CAT ROSTER UI: " + description)

func _run() -> void:
	Engine.time_scale = 1.0
	create_timer(120,true,false,true).timeout.connect(func(): push_error("CAT ROSTER UI timeout"); quit(1))
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): capture_dir = arg.trim_prefix("--capture-dir=")
	if not capture_dir.is_empty():
		if not capture_dir.is_absolute_path() or DisplayServer.get_name()=="headless":
			push_error("Captures require a native renderer and absolute output directory")
			quit(2)
			return
		DirAccess.make_dir_recursive_absolute(capture_dir)
	var directory := ProjectSettings.globalize_path("res://../../work/cats/ui-fixtures").simplify_path()
	DirAccess.make_dir_recursive_absolute(directory)
	save_path = directory.path_join("cats_%d.json" % Time.get_ticks_usec())
	check(not FileAccess.file_exists(save_path),"Fixture starts at a fresh disposable path")
	# Base.Fixture renders its current profile on boot. Seed only this new test file;
	# leaving it empty would exercise an invalid fixture rather than cat selection.
	var initial := Progress.new()
	initial.load_save(save_path)
	check(initial.select_character("nima") and initial.last_save_ok,"Explicit fixture profile exists before Main renders its initial portraits")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(360,240)
	canvas = SubViewport.new()
	canvas.size = SIZES[0]
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	screen = Base.Fixture.new()
	screen.fixture_path = save_path
	canvas.add_child(screen)
	check(screen.identity_loaded and screen.session_save_path==save_path,"Main initializes identity only at the explicit fixture path")
	for dimensions: Vector2i in SIZES:
		canvas.size = dimensions
		screen.size = Vector2(dimensions)
		screen._layout_interface(Vector2(dimensions))
		for id: String in IDS:
			await _select_and_fight(id, dimensions)
	await _showcase()
	if not capture_dir.is_empty():
		var report := FileAccess.open(capture_dir.path_join("observations.json"),FileAccess.WRITE)
		check(report != null,"Can write the native fixture observation report")
		if report != null:
			report.store_string(JSON.stringify({"fixture_path":save_path,"checks":checks,"failures":failures,"battle_captures":observations,"forced_battle_poses":false},"\t"))
			report.close()
	screen.free()
	print("CAT ROSTER UI: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)

func _select_and_fight(id: String, dimensions: Vector2i) -> void:
	var suffix := "%dx%d" % [dimensions.x,dimensions.y]
	screen._show_roster()
	var roster = screen.creation_layer
	check(is_instance_valid(roster) and roster._cards.size()==Catalog.IDS.size(),"League exposes all fifteen companions")
	await process_frame
	roster._roster_scroll.ensure_control_visible(roster._cards[Catalog.IDS.find(id)])
	roster._cards[Catalog.IDS.find(id)].pressed.emit()
	await _capture("league-"+id+"-"+suffix)
	check(not roster._choose_button.disabled and roster._choose_button.text.contains(str(Catalog.definition(id).name)),"Cat is selectable with its correct name")
	roster._choose_button.pressed.emit()
	await process_frame
	check(screen.progression.active_id==id,"Real League choose control selects "+id)
	check(screen.player_view.get_sprite_geometry().get("path","")=="res://assets/sprites/%s-v1.png" % id,"League uses the cat's own canonical atlas")
	check(screen.fighter_identity.entry(id).appearance==Cosmetics.default_appearance(id),"Default appearance preserves cat body and original eye/fur palette")
	# Exercise the real editor save path, then verify the durable identity later.
	screen._open_customization(id)
	check(is_instance_valid(screen.customization_layer),"Cat identity can be edited")
	screen.customization_layer.confirmed.emit(id,str(Catalog.definition(id).name),Cosmetics.default_appearance(id))
	await process_frame
	check(FileAccess.file_exists(save_path+".identity.json"),"Cat identity is persisted before reload")
	var stable_id: String = screen.fighter_identity.entry(id).fighter_id
	var before_league_matches := int(screen.progression.data.matches)
	screen._start_fight()
	check(screen.active_match and screen.combat.running,"Selected cat starts a real League fight")
	await _observe_running_battle("league-battle-"+id+"-"+suffix,id)
	await _finish_naturally()
	check(int(screen.progression.data.matches)==before_league_matches+1,"League battle rewards the cat exactly once")
	var restored_league := Progress.new()
	restored_league.load_save(save_path)
	check(not restored_league.save_blocked and restored_league.active_id==id and int(restored_league.data.matches)==before_league_matches+1,"Cat League profile survives a save and reload")
	screen._enter_story()
	screen._show_story_panel("companions")
	var panel = screen.story_layer
	check(panel._character_buttons.size()==Catalog.IDS.size(),"Story exposes all fifteen companions")
	panel._character_buttons[Catalog.IDS.find(id)].pressed.emit()
	await process_frame
	await process_frame
	panel._scroll.ensure_control_visible(panel._character_buttons[Catalog.IDS.find(id)])
	await _capture("story-"+id+"-"+suffix)
	panel._primary_pressed()
	check(screen.progression.active_id==id and screen.player_name_label.text.contains(str(Catalog.definition(id).name)),"Story selection and HUD use the same cat identity")
	var before_matches := int(screen.progression.data.matches)
	screen._start_story_battle()
	check(screen.active_match and screen.combat.running,"Selected cat starts a real Story fight")
	check(screen.player_view.get_sprite_geometry().get("path","")=="res://assets/sprites/%s-v1.png" % id,"Battle retains the correct cat art")
	check(Sets.available(id),"Expanded animation banks are installed for "+id)
	await _observe_running_battle("battle-"+id+"-"+suffix,id)
	await _finish_naturally()
	check(int(screen.progression.data.matches)==before_matches+1 and int(screen.progression.data.total_xp)>0,"Battle rewards the cat exactly once")
	var restored := Story.new()
	restored.load_save(save_path+".story.json")
	check(not restored.save_blocked and restored.active_id==id and int(restored.data.matches)==before_matches+1,"Cat campaign survives a save and reload")
	var identity := Identity.new()
	identity.load_save(save_path+".identity.json")
	check(not identity.save_blocked and identity.entry(id).appearance.body_style_id==id and identity.entry(id).fighter_id==stable_id,"Cat identity survives a save and reload with its stable fighter ID")
	screen._leave_story()
	await process_frame
	check(not screen.story_mode and screen.progression.active_id==id,"Returning to League preserves independent cat selection")

func _observe_running_battle(name: String, id: String) -> void:
	# Observe a scheduled contact while Main advances naturally. A fixed wall time
	# could show only the random opening pause; never set an actor pose or its clock.
	check(screen.active_match and screen.combat.running,"Capture begins during an active "+id+" battle")
	if not screen.active_match or not screen.combat.running: return
	screen.player_view.set_process(true)
	screen.rival_view.set_process(true)
	screen.set_process(true)
	var deadline := Time.get_ticks_msec()+12000
	var contact: Dictionary = {}
	var cursor := 0
	while screen.active_match and Time.get_ticks_msec()<deadline and contact.is_empty():
		await process_frame
		while cursor<screen.combat.event_log.size():
			var event: Dictionary = screen.combat.event_log[cursor]
			cursor += 1
			if str(event.get("type",""))=="attack" and str(event.get("side",""))=="player":
				contact=event.duplicate(true)
				break
	check(not contact.is_empty(),"Observed a real engine contact for "+name)
	check(screen.active_match and screen.combat.running,"Battle capture is still running rather than a staged result")
	if not contact.is_empty():
		check(screen.player_view.get_animation_state().body_id==id,"Live action keeps the selected cat body")
		check(not screen.player_view.get_animation_state().fallback,"Live contact uses the cat's expanded animation bank")
		await _capture(name,false)
		observations.append({"capture":name+".png","mode":"Story" if screen.story_mode else "League","character_id":id,"elapsed":screen.combat.elapsed,"contact":contact,"player_animation":screen.player_view.get_animation_state(),"rival_animation":screen.rival_view.get_animation_state(),"running":screen.combat.running,"viewport":[canvas.size.x,canvas.size.y]})
	screen.set_process(false)
	screen.player_view.set_process(false)
	screen.rival_view.set_process(false)

func _finish_naturally() -> void:
	if screen.combat.running: screen._dispatch_events(screen.combat.advance(120.0))
	var deadline := Time.get_ticks_msec()+3000
	while screen.active_match and Time.get_ticks_msec()<deadline: await process_frame
	check(not screen.active_match and screen.result_panel.visible,"Natural combat completion presents a result")
	check(not screen.last_battle_summary.is_empty() and str(screen.last_battle_summary.get("reason",""))!="surrender","Completed match uses the engine's terminal outcome")

func _capture(name: String, settle: bool = true) -> void:
	if capture_dir.is_empty(): return
	if settle:
		await process_frame
		await process_frame
	await RenderingServer.frame_post_draw
	check(canvas.get_texture().get_image().save_png(capture_dir.path_join(name+".png"))==OK,"Saved native capture "+name)

func _showcase() -> void:
	if capture_dir.is_empty(): return
	screen.hide()
	canvas.size = Vector2i(1200,720)
	var scene := Control.new()
	canvas.add_child(scene)
	var background := ColorRect.new()
	background.color = Color("12292f")
	background.size = Vector2(1200,720)
	scene.add_child(background)
	_label(scene,"BRASA · Nuevos compañeros",Vector2(42,28),30,Color("f4dfb9"))
	_label(scene,"Dos gatos · 40 poses ilustradas cada uno",Vector2(42,74),18,Color("9ab3ac"))
	for index: int in range(IDS.size()):
		var definition := Catalog.definition(IDS[index])
		var x := 300.0+index*600.0
		var actor := Fighter.new()
		scene.add_child(actor)
		actor.setup_character(definition)
		actor.set_process(false)
		actor._intro_elapsed = 10.0
		actor.position = Vector2(x,520)
		actor.scale = Vector2.ONE*2.05
		_label(scene,str(definition.name),Vector2(x-235,548),32,Color("f4dfb9"))
		_label(scene,"Gato negro · ojos amarillos" if index==0 else "Gato gris · ojos verdosos",Vector2(x-235,592),20,Color("efc65c") if index==0 else Color("9fcda8"))
		_label(scene,str(definition.role),Vector2(x-235,635),17,Color("9ab3ac"))
	await _capture("cats-showcase")
	scene.free()

func _label(parent: Node, value: String, at: Vector2, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text=value
	label.position=at
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	parent.add_child(label)
