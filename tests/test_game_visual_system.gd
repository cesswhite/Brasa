extends SceneTree
const Visuals = preload("res://scripts/ui/game_visual_system.gd")
var checks := 0
var failures := 0
var capture_dir := ""

func _init() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("GAME VISUAL SYSTEM: "+message)

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): capture_dir = arg.trim_prefix("--capture-dir=")
	if not capture_dir.is_empty(): DirAccess.make_dir_recursive_absolute(capture_dir)
	for view: Vector2i in [Vector2i(1360,880),Vector2i(390,844)]:
		var canvas := SubViewport.new()
		canvas.size = view
		canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(canvas)
		var screen := Control.new()
		screen.size = view
		screen.theme = Visuals.theme()
		canvas.add_child(screen)
		Visuals.mount_background(screen,"story")
		var column := VBoxContainer.new()
		column.position = Vector2(24,24)
		column.size = Vector2(view.x-48,view.y-48)
		column.add_theme_constant_override("separation",12)
		screen.add_child(column)
		var title := Label.new()
		title.text = "Materiales de Brasa"
		Visuals.apply_label(title,"title")
		column.add_child(title)
		for role: String in ["primary","secondary","danger","navigation_active"]:
			var button := Button.new()
			button.text = {"primary":"Entrar al combate","secondary":"Volver al refugio","danger":"Rendirse","navigation_active":"Ruta · seleccionada"}[role]
			Visuals.apply_button(button,role)
			column.add_child(button)
			for state: String in ["normal","hover","pressed","disabled"]:
				check(button.get_theme_stylebox(state) is StyleBoxTexture,"painted material for "+role+" "+state)
			check(button.get_theme_stylebox("focus") != null,"keyboard focus available")
		var locked := Button.new()
		locked.text = "Próximamente · bloqueado"
		Visuals.apply_button(locked)
		locked.disabled = true
		column.add_child(locked)
		var field := LineEdit.new()
		field.placeholder_text = "Nombre del compañero"
		column.add_child(field)
		var option := OptionButton.new()
		option.add_item("El patio de los faroles")
		Visuals.apply_option(option)
		column.add_child(option)
		var toggle := CheckBox.new()
		toggle.text = "Movimiento reducido"
		toggle.button_pressed = true
		column.add_child(toggle)
		var slider := HSlider.new()
		slider.value = 65
		slider.custom_minimum_size.y = 32
		column.add_child(slider)
		var progress := ProgressBar.new()
		Visuals.apply_progress(progress)
		progress.custom_minimum_size.y = 10
		progress.value = 64
		column.add_child(progress)
		await process_frame
		await process_frame
		check(field.get_theme_stylebox("normal") is StyleBoxTexture,"text input shares frame")
		check(option.get_popup().get_theme_stylebox("panel") is StyleBoxTexture,"dropdown popup shares frame")
		check(toggle.get_theme_icon("checked") == Visuals.icon("checked"),"themed engraved toggle")
		for child: Control in column.get_children():
			check(child.get_global_rect().end.x <= view.x and child.get_global_rect().end.y <= view.y,"control fits "+child.get_class()+" "+str(view))
		if not capture_dir.is_empty() and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			check(canvas.get_texture().get_image().save_png(capture_dir.path_join("components-%dx%d.png" % [view.x,view.y])) == OK,"native component capture")
		canvas.queue_free()
		await process_frame
	print("GAME VISUAL SYSTEM: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
