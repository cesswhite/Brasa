extends SceneTree
const Home = preload("res://scripts/ui/home_panel.gd")
const Refuges = preload("res://scripts/ui/character_refuges.gd")
const World = preload("res://scripts/ui/world_visuals.gd")
var failures := 0
var checks := 0
var captured := ""
var emitted := ""
var only: Array[String] = []

func _init() -> void: _run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): captured = arg.trim_prefix("--capture-dir=")
		elif arg.begins_with("--only="):
			for id: String in arg.trim_prefix("--only=").split(",",false): only.append(id)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(360,240)
	set_meta("brasa_reduced_motion",true)
	if not captured.is_empty(): DirAccess.make_dir_recursive_absolute(captured)
	var viewport := SubViewport.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var actions: Array = []
	for row: Array in [["story","Historia"],["arena","Arena"],["online","Arena online"],["training","Entrenar"],["companions","Compañeros"],["customize","Personalizar"],["profile","Ficha"],["legacy","Legado"],["history","Historial"],["settings","Ajustes"],["help","Cómo jugar"],["log","Registro"]]:
		actions.append({"id":row[0],"label":row[1]})
	check(Refuges.scenes().size()==21,"Every playable body and family individual has its own refuge")
	for body: String in Refuges.scenes():
		if not only.is_empty() and not body in only: continue
		var scene := Refuges.scene(body)
		check(ResourceLoader.exists(World.asset_path(str(scene.asset))),"Imported background exists: "+body)
		var profile := {"character_id":"nima","identity":{"display_name":"Mi compañero"},"appearance":{"body_style_id":body},"level":6}
		var before := profile.duplicate(true)
		check(Refuges.resolve_body(profile,{"id":"nima"})==body,"Actual appearance overrides archetype: "+body)
		for dimensions: Vector2i in [Vector2i(1360,880),Vector2i(390,844),Vector2i(844,390),Vector2i(1920,1080)]:
			viewport.size = dimensions
			var home := Home.new()
			viewport.add_child(home)
			home.configure(profile,{"id":"nima","name":"Nima"},{},actions)
			home.action_requested.connect(func(id: String): emitted=id)
			await process_frame
			await process_frame
			check(home.selected_refuge==body,"Correct selected background")
			check(home.buttons.size()==actions.size(),"Every original destination remains reachable")
			check(home._backdrop.visible_prop_ids().is_empty(),"No unrelated props pasted over the illustration")
			check(home._backdrop.loaded_background_paths()==[World.asset_path(str(scene.asset))],"Only the active scene is loaded")
			check(home._scroll.get_rect().end.x<=dimensions.x and home._scroll.get_rect().end.y<=dimensions.y,"Navigation fits the viewport")
			for button: Button in home.buttons:
				check(button.size.y>=48,"Accessible button height")
				check(button.size.x>=70,"Readable button width")
				button.grab_focus()
				await process_frame
				await process_frame
				check(home._scroll.get_global_rect().encloses(button.get_global_rect()),"Keyboard scroll reveals each complete action")
				button.pressed.emit()
				check(emitted==str(button.get_meta("action_id")),"Correct action is emitted")
			check(profile==before,"Menu does not mutate player data")
			if not captured.is_empty() and (not only.is_empty() or body in ["nima","luma","mugo","neris","bruma","bruma_nieve"]) and dimensions.x in [1360,390]:
				home.buttons[0].grab_focus()
				home._scroll.scroll_vertical=0
				await process_frame
				await RenderingServer.frame_post_draw
				viewport.get_texture().get_image().save_png(captured.path_join("%s-%dx%d.png" % [body,dimensions.x,dimensions.y]))
			home.free()
	check(Refuges.resolve_body({"appearance":{"body_style_id":"unknown"},"character_id":"luma"},{})=="luma","Unknown body falls back to actual archetype")
	check(Refuges.resolve_body({}, {})=="nima","Safe fallback for absent identity")
	viewport.free()
	print("CHARACTER REFUGES: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
