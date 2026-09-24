extends SceneTree
const PanelScript = preload("res://scripts/ui/story_panel.gd")
const Fixtures = preload("res://tests/test_story_panel.gd")
const Story = preload("res://scripts/story_catalog.gd")
const VisualProfiles = preload("res://scripts/character_visual_profile.gd")
const SIZES: Array[Vector2i] = [Vector2i(1360,880),Vector2i(1224,792),Vector2i(1920,1080),Vector2i(768,1024),Vector2i(390,844),Vector2i(430,932),Vector2i(844,390)]
class VisualStory extends Fixtures.MemoryStory:
	func can_start_next_chapter() -> bool:
		return is_complete() and current_chapter()<Story.chapters().size()
	func completion_summary(chapter: int = 0) -> Dictionary:
		var result: Dictionary = super.completion_summary(chapter)
		result["badge"] = str(Story.chapter(current_chapter() if chapter==0 else chapter).badge)
		return result
var checks: int = 0
var failures: int = 0
var capture_dir: String = ""
var baseline: bool = false
var stage_index: int = 4
var extended: bool = false
func _init() -> void: _run.call_deferred()
func _check(value: bool,message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("STORY WORLD: "+message)
func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): capture_dir = arg.trim_prefix("--capture-dir=")
		if arg == "--baseline": baseline = true
		if arg.begins_with("--stage-index="): stage_index = int(arg.trim_prefix("--stage-index="))
		if arg == "--extended": extended = true
	if not capture_dir.is_empty():
		_check(capture_dir.is_absolute_path() and DisplayServer.get_name() != "headless","native capture destination")
		DirAccess.make_dir_recursive_absolute(capture_dir)
	var model = VisualStory.new()
	model.choose("mugo")
	model.data.chapter = 2
	model.data.current_stage = stage_index
	model.data.level = 13
	model.data.xp = 65
	model.data.points = 6
	model.data.move_points = 2
	model.data.perk_points = 1
	model.data.last_hint = "Tu rival resiste los golpes directos. Prueba a reforzar defensa o precisión antes del reintento."
	var original: Dictionary = model.data.duplicate(true)
	var canvas := SubViewport.new()
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	var panel = PanelScript.new()
	canvas.add_child(panel)
	for view: Vector2i in SIZES:
		canvas.size = view
		panel.configure(model)
		await process_frame
		await process_frame
		for tab: String in (["route"] if baseline else ["route","upgrades","moves","companions","legacy"]):
			panel.show_tab(tab)
			await process_frame
			await process_frame
			_check(panel._body.size.x <= panel._scroll.size.x+1,"body width "+tab+str(view))
			_check(panel._primary.get_global_rect().end.y <= view.y+1,"fixed primary remains visible "+tab+str(view))
			_check(panel._primary.size.y >= 48,"touch target "+tab+str(view))
			if not baseline: _visual_checks(panel,view)
			if not capture_dir.is_empty():
				await RenderingServer.frame_post_draw
				_check(canvas.get_texture().get_image().save_png(capture_dir.path_join("%dx%d-%s.png" % [view.x,view.y,tab])) == OK,"save capture")
	_check(model.data == original,"presentation does not change progression")
	if extended:
		for view: Vector2i in SIZES:
			canvas.size = view
			for state: String in ["boss","legacy-complete","route10-scrolled","journey"]:
				model.data = original.duplicate(true)
				if state == "boss": model.data.current_stage = 7
				elif state == "legacy-complete":
					model.data.current_stage = 8
					model.data.completed = true
					model.data.matches = 22
					model.data.losses = 6
					model.data.retries = 6
					model.data.total_xp = 2800
				elif state == "route10-scrolled":
					model.data.chapter = 4
					model.data.current_stage = 0
				else:
					model.data.chapter = 1
					model.data.current_stage = 2
				var before: Dictionary = model.data.duplicate(true)
				panel.configure(model)
				panel.show_tab("legacy" if state=="legacy-complete" else "route")
				await process_frame
				await process_frame
				if state=="route10-scrolled":
					_check(panel._stage_buttons.size()==10,"later chapter retains all10encounters")
					panel._scroll.ensure_control_visible(panel._stage_buttons.back())
					await process_frame
					await process_frame
					_check(panel._scroll.get_global_rect().encloses(panel._stage_buttons.back().get_global_rect()),"last marker reachable in ten-node chapter")
				_visual_checks(panel,view)
				_check(model.data == before,"state presentation is read only")
				if not capture_dir.is_empty():
					await RenderingServer.frame_post_draw
					_check(canvas.get_texture().get_image().save_png(capture_dir.path_join("%dx%d-%s.png" % [view.x,view.y,state])) == OK,"save extended capture")
	canvas.queue_free()
	await process_frame
	print("STORY WORLD: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

func _visual_checks(panel: Control, view: Vector2i) -> void:
	var viewport := Rect2(Vector2.ZERO,Vector2(view))
	for button: Button in panel._tab_buttons.values():
		_check(viewport.encloses(button.get_global_rect()) and button.size.y>=48,"native physical navigation fits")
	_check(viewport.encloses(panel._primary.get_global_rect()),"fixed footer remains visible")
	if panel._active_tab=="companions":
		for button: Button in panel._character_buttons:
			_check(button.get_theme_stylebox("hover") is StyleBoxFlat and button.get_theme_stylebox("pressed") is StyleBoxFlat,"companion interactions preserve open camp surface")
	if panel._active_tab=="route":
		_check(panel._stage_buttons.size()==Story.stages(panel._route_chapter).size(),"route count matches chapter")
		for button: Button in panel._stage_buttons:
			var path: Control = button.get_parent()
			_check(path.get_global_rect().grow(1).encloses(button.get_global_rect()),"every marker belongs within path bounds")
			_check(not button.tooltip_text.is_empty() and button.badge!=null,"marker preserves information and original illustrated badge")
		if panel._scroll.scroll_vertical==0:
			var actor: Node2D = panel._portraits[0]
			var geometry: Dictionary = actor.get_sprite_geometry()
			var frame: Dictionary = geometry.frames[0]
			var local := Rect2((Vector2(frame.bounds.position)-Vector2(frame.anchor))*float(geometry.scale),Vector2(frame.bounds.size)*float(geometry.scale))
			var painted: Rect2 = actor.get_global_transform()*local
			_check(panel._scroll.get_global_rect().grow(2).encloses(painted),"entire rival visible before scrolling")
			if view.x>=1100 and view.y>=792:
				# Presence follows the authored species height through one shared
				# camera; it must not auto-enlarge each body to a uniform 390 px.
				var holder: Control = actor.get_parent()
				var extent := Vector2(holder.size.x,minf(holder.size.y,holder.custom_minimum_size.y))
				var camera := VisualProfiles.portrait_scale(extent)
				var body := str(actor.get_animation_state().body_id)
				var authored_height := float(VisualProfiles.profile(body).get("world_height",0))
				var expected_height := authored_height*camera
				var visible_pixels: Rect2 = actor.visible_sprite_bounds()
				_check(actor.scale.is_equal_approx(Vector2.ONE*camera),"desktop rival uses the common REST camera without fitting individual bodies")
				_check(authored_height>0 and absf(visible_pixels.size.y-expected_height)<=expected_height*0.03,"desktop presence preserves canonical world height within 3 percent breathing tolerance")
				_check(panel._scroll.get_global_rect().grow(2).encloses(visible_pixels),"actual desktop pose pixels remain fully inside the scene")
