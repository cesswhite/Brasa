extends SceneTree
## Full scene selection, illustrated actors, battle results and isolated persistence.
## Optional native renders: -- --capture-dir=/absolute/path
const Base = preload("res://tests/test_story_chapter_integration.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Moves = preload("res://scripts/move_catalog.gd")
const Story = preload("res://scripts/story_progression.gd")
const Fighter = preload("res://scripts/fighter_view.gd")
const IDS: Array[String] = ["balam", "tepa", "xuna", "copal"]
var checks := 0
var failures := 0
var screen
var canvas: SubViewport
var capture_dir := ""

func _init() -> void: _run.call_deferred()
func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("MEXICAN ROSTER UI: " + description)

func _run() -> void:
	create_timer(50,true,false,true).timeout.connect(func(): push_error("Mexican UI timeout"); quit(1))
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): capture_dir = arg.trim_prefix("--capture-dir=")
	var directory := ProjectSettings.globalize_path("res://../../work/mexican_roster/ui-fixtures")
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory.path_join("main_%d.json" % Time.get_ticks_usec())
	canvas = SubViewport.new()
	canvas.size = Vector2i(1360,880)
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	screen = Base.Fixture.new()
	screen.fixture_path = path
	canvas.add_child(screen)
	screen.size = Vector2(1360,880)
	screen._layout_interface(screen.size)
	var league_bytes := FileAccess.get_file_as_string(path)
	screen.story_button.pressed.emit()
	for id: String in IDS:
		screen._show_story_panel("companions")
		var panel = screen.story_layer
		check(panel._character_buttons.size() == Catalog.IDS.size(), "every character appears in Story selection")
		panel._select_character(id)
		check(_text(panel).to_lower().contains(str(Catalog.definition(id).species).to_lower()), id + ": actual species appears in selected detail")
		panel._primary_pressed()
		check(screen.progression.active_id == id and screen.progression.data.level == 1, id + ": selection starts independent level-one campaign")
		check(screen.progression.data.unlocked_moves.size() == 2, id + ": first campaign has two techniques")
		check(screen.player_view.get_sprite_geometry().get("path", "") == "res://assets/sprites/%s-v1.png" % id, id + ": main renders unique atlas")
		screen._start_story_battle()
		check(screen.active_match and screen.combat.running, id + ": real Story button starts combat")
		check(screen.player_name_label.text.contains(str(Catalog.definition(id).name)), id + ": HUD uses selected identity")
		screen.player_view.set_process(false)
		screen.rival_view.set_process(false)
		var opening: Dictionary = Moves.moves_for(id)[0]
		screen.player_view.play_move(opening, float(opening.windup) + float(opening.travel))
		await _capture("arena-" + id)
		var events: Array = screen.combat.advance(60.0)
		for event: Dictionary in events:
			if event.type == "finished": screen._dispatch_events([event])
		await create_timer(0.4).timeout
		check(not screen.active_match and screen.result_panel.visible, id + ": natural result reaches interface")
		check(int(screen.progression.data.matches) == 1 and int(screen.progression.data.total_xp) > 0, id + ": one match rewards and saves")
		var restored = Story.new()
		restored.load_save(path + ".story.json")
		check(not restored.save_blocked and restored.active_id == id and int(restored.data.matches) == 1, id + ": independent result survives reload")
	check(FileAccess.get_file_as_string(path) == league_bytes, "four Story campaigns leave existing league file byte-identical")
	for id: String in IDS:
		check(screen.progression.roster.has(id) and int(screen.progression.roster[id].matches) == 1, id + ": switching retains previous campaign")
	if not capture_dir.is_empty(): await _showcase()
	screen.free()
	print("MEXICAN ROSTER UI: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

func _text(node: Node) -> String:
	var result: String = node.text if node is Label else ""
	for child: Node in node.get_children(): result += "\n" + _text(child)
	return result

func _capture(name: String) -> void:
	if capture_dir.is_empty(): return
	DirAccess.make_dir_recursive_absolute(capture_dir)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	check(canvas.get_texture().get_image().save_png(capture_dir.path_join(name+".png")) == OK, "native capture " + name)

func _showcase() -> void:
	screen.visible = false
	canvas.size = Vector2i(1440,640)
	var sheet := Control.new()
	sheet.size = Vector2(1440,640)
	sheet.theme = screen.theme
	canvas.add_child(sheet)
	var background := ColorRect.new()
	background.color = Color("0c2228")
	background.size = sheet.size
	sheet.add_child(background)
	_label(sheet,"BRASA  /  FAUNA DE MÉXICO",Vector2(48,30),26,Color("efb66f"))
	_label(sheet,"Cuatro compañeros nuevos · cinco técnicas por personaje",Vector2(48,71),18,Color("9ab3ac"))
	for index in range(IDS.size()):
		var definition: Dictionary = Catalog.definition(IDS[index])
		var x: float = 48 + 342 * index
		var panel := Panel.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color("153137")
		style.set_corner_radius_all(18)
		panel.add_theme_stylebox_override("panel",style)
		panel.position = Vector2(x,124)
		panel.size = Vector2(318,460)
		sheet.add_child(panel)
		var actor := Fighter.new()
		panel.add_child(actor)
		actor.setup_character(definition)
		actor.set_process(false)
		if IDS[index] == "tepa": actor._set_pose_frame(3)
		actor.scale = Vector2.ONE * 1.35
		actor.position = Vector2(159,296)
		_label(panel,str(definition.name),Vector2(22,320),29,Color("f5e7cf"))
		_label(panel,str(definition.species),Vector2(22,361),18,Color("7dd7bd"))
		_label(panel,str(definition.role),Vector2(22,400),15,Color("9ab3ac"))
	await _capture("companeros-mexicanos")
	sheet.free()
	canvas.size = Vector2i(640,520)
	var punch := Control.new()
	punch.size = Vector2(640,520)
	punch.theme = screen.theme
	canvas.add_child(punch)
	var backdrop := ColorRect.new()
	backdrop.size = punch.size
	backdrop.color = Color("0c2228")
	punch.add_child(backdrop)
	_label(punch,"TEPA  /  GOLPE CORREGIDO",Vector2(28,22),23,Color("efb66f"))
	var tepa := Fighter.new()
	punch.add_child(tepa)
	tepa.setup_character(Catalog.definition("tepa"))
	tepa.set_process(false)
	tepa._set_pose_frame(3)
	tepa.scale = Vector2.ONE * 2.3
	tepa.position = Vector2(300,480)
	await _capture("tepa-golpe-corregido")
	punch.free()

func _label(parent: Node, value: String, at: Vector2, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = value
	label.position = at
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	parent.add_child(label)
