extends SceneTree
## Bounded presentation fixture. No Main, engine, network or player save access.
const ResultPanel = preload("res://scripts/ui/components/game_battle_result_panel.gd")
const Layout = preload("res://scripts/ui/battle_layout.gd")
const Visuals = preload("res://scripts/ui/game_visual_system.gd")
const SIZES: Array[Vector2i] = [Vector2i(1360,880),Vector2i(1224,792),Vector2i(1920,1080),Vector2i(768,1024),Vector2i(390,844),Vector2i(430,932),Vector2i(844,390)]
var checks := 0
var failures := 0
var capture_dir := ""
var observations: Array[Dictionary] = []

func _init() -> void: _run.call_deferred()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("BATTLE RESULT: " + message)

func _settle() -> void:
	await process_frame
	await process_frame

func _within(parent: Control, child: Control) -> bool:
	return Rect2(Vector2.ZERO,parent.size).grow(0.1).encloses(child.get_rect())

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): capture_dir = arg.trim_prefix("--capture-dir=")
	if not capture_dir.is_empty():
		if not capture_dir.is_absolute_path() or DisplayServer.get_name() == "headless": quit(2); return
		DirAccess.make_dir_recursive_absolute(capture_dir)
	for extent: Vector2i in SIZES: await _size(extent)
	if not capture_dir.is_empty():
		var file := FileAccess.open(capture_dir.path_join("observations.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"screens":observations},"\t"))
	print("BATTLE RESULT PANEL: %d checks, %d failures across %d viewports" % [checks,failures,SIZES.size()])
	quit(1 if failures else 0)

func _size(extent: Vector2i) -> void:
	var view := SubViewport.new()
	view.size = extent
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var ground := ColorRect.new()
	ground.color = Visuals.DARK
	ground.size = extent
	view.add_child(ground)
	var panel := ResultPanel.new()
	_check(panel.title_label != null and panel.copy_label != null and panel.xp_bar != null,"public fields exist before attachment")
	view.add_child(panel)
	var layout := Layout.calculate(Vector2(extent),false,true)
	var expected: Rect2 = layout.result
	panel.position = expected.position
	panel.size = expected.size
	panel.layout_compact(bool(layout.short),bool(layout.phone))
	panel.configure_progress(65,105)
	panel.title_label.text = "¡VICTORIA!"
	panel.copy_label.text = "Tú +40 XP · Rival +25 XP" if layout.short else "Tu compañero +40 XP · Rival +25 XP\nEntrena, cambia de compañero o vuelve a la arena."
	await _settle()
	_check(panel.get_rect().is_equal_approx(expected),"caller footprint is unchanged at "+str(extent))
	_check(Rect2(Vector2.ZERO,Vector2(extent)).encloses(panel.get_rect()),"result is inside viewport "+str(extent))
	_check(_within(panel,panel.title_label) and _within(panel,panel.copy_label),"both text rectangles stay inside result "+str(extent))
	_check(not panel.title_label.get_rect().intersects(panel.copy_label.get_rect()),"title and copy do not overlap "+str(extent))
	_check(panel.title_label.get_theme_font("font") == Visuals.font("hero"),"shared Story serif")
	_check(panel.copy_label.get_theme_font("font") == Visuals.font("secondary"),"shared readable body font")
	_check(panel.mouse_filter == Control.MOUSE_FILTER_IGNORE,"no new mouse barrier above combat")
	_check(is_equal_approx(panel.xp_bar.value,65) and is_equal_approx(panel.xp_bar.max_value,105),"XP value remains caller supplied")
	_check(panel.copy_label.get_line_count() <= panel.copy_label.max_lines_visible,"real league copy fits without truncation "+str(extent))
	if layout.short:
		_check(not panel.xp_bar.visible,"landscape 48 px hides XP")
		_check(panel.get_theme_stylebox("panel") is StyleBoxFlat,"compact surface stays open to arena")
		_check(panel.title_label.get_theme_font_size("font_size") == 20 and panel.copy_label.get_theme_font_size("font_size") == 12,"compact typography is 20/12")
	else:
		_check(panel.xp_bar.visible and _within(panel,panel.xp_bar),"XP visible and bounded "+str(extent))
		_check(not panel.copy_label.get_rect().intersects(panel.xp_bar.get_rect()),"XP never intersects rewards "+str(extent))
		_check(panel.get_theme_stylebox("panel") is StyleBoxTexture,"shared reward material "+str(extent))
		_check(panel.title_label.get_line_count()==1,"headline stays a single row")
	var league_lines := panel.copy_label.get_line_count()
	panel.title_label.text = "CAPÍTULO 2 COMPLETADO" + (" · +300 XP" if layout.short else "")
	panel.copy_label.text = "Tu insignia y tu recorrido te esperan en Legado." if layout.short else "+300 XP · ¡Nivel 20! · +3 puntos\nTu insignia y tu recorrido te esperan en Legado."
	var title_before := panel.title_label.text
	var copy_before := panel.copy_label.text
	panel.configure_progress(105,105)
	await _settle()
	_check(panel.title_label.text == title_before and panel.copy_label.text == copy_before,"progress configuration never rewrites result text")
	_check(panel.copy_label.get_line_count() <= panel.copy_label.max_lines_visible,"real Story copy fits without truncation "+str(extent))
	_check(_within(panel,panel.copy_label),"Story copy has bounded geometry")
	panel.title_label.add_theme_color_override("font_color",Visuals.CORAL)
	panel.copy_label.tooltip_text = "Caller owns the complete reward detail"
	panel.copy_label.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.layout_compact(layout.short,layout.phone)
	_check(panel.title_label.get_theme_color("font_color") == Visuals.CORAL and panel.copy_label.tooltip_text == "Caller owns the complete reward detail" and panel.copy_label.mouse_filter == Control.MOUSE_FILTER_PASS,"layout preserves caller colour, tooltip and interaction")
	panel.title_label.add_theme_color_override("font_color",Visuals.GOLD)
	observations.append({"viewport":[extent.x,extent.y],"result":str(expected),"title":str(panel.title_label.get_rect()),"copy":str(panel.copy_label.get_rect()),"title_size":panel.title_label.get_theme_font_size("font_size"),"copy_size":panel.copy_label.get_theme_font_size("font_size"),"league_lines":league_lines,"story_lines":panel.copy_label.get_line_count(),"visible_lines":panel.copy_label.max_lines_visible,"xp_visible":panel.xp_bar.visible})
	if not capture_dir.is_empty():
		await RenderingServer.frame_post_draw
		var image := view.get_texture().get_image().get_region(Rect2i(expected.grow(12)))
		_check(image.save_png(capture_dir.path_join("%dx%d-result.png" % [extent.x,extent.y])) == OK,"native result capture")
	panel.configure_progress(999,105)
	_check(is_equal_approx(panel.xp_bar.value,105),"XP beyond maximum is bounded")
	panel.configure_progress(-50,105)
	_check(is_zero_approx(panel.xp_bar.value),"negative XP is bounded")
	panel.configure_progress(65,0)
	_check(not panel.xp_bar.visible and panel.xp_bar.max_value>0,"missing XP maximum hides progress without invalid Range")
	panel.configure_progress(NAN,INF)
	_check(not panel.xp_bar.visible and is_zero_approx(panel.xp_bar.value),"nonfinite progress has safe presentation")
	panel.size = Vector2(480,48)
	panel.layout_compact(false,false)
	panel.configure_progress(10,100)
	_check(not panel.xp_bar.visible and _within(panel,panel.title_label) and _within(panel,panel.copy_label),"48 px auto adapts even without compact flag")
	view.free()
