extends SceneTree
## Read-only native visual sampler. Saves rendered UI only, never edited source images.
## Godot --path outputs/Brasa --script res://tests/test_world_surfaces.gd -- --capture-dir=/absolute/path
const Visuals = preload("res://scripts/ui/world_visuals.gd")
const Backdrop = preload("res://scripts/ui/world_backdrop.gd")
const STATES: Array[String] = ["normal","hover","pressed","disabled","focus"]
const PROP_IDS: Array[String] = ["tepa_cloth","balam_bandages","ascua_brazier","storm_relic","travel_pack","arena_medallion"]
var checks := 0
var failures := 0
var capture_dir := ""
var buttons: Array[Button] = []

class FocusSample extends Control:
	var style: StyleBox
	func _draw() -> void:
		if style != null: draw_style_box(style,Rect2(Vector2.ZERO,size))

func _init() -> void: _run.call_deferred()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("WORLD SURFACES: "+message)

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): capture_dir = arg.trim_prefix("--capture-dir=")
	if not capture_dir.is_empty():
		_check(capture_dir.is_absolute_path() and DisplayServer.get_name() != "headless","captures use explicit path and native renderer")
		if DisplayServer.get_name() == "headless": capture_dir = ""
		else: DirAccess.make_dir_recursive_absolute(capture_dir)
	var manifest_before: Dictionary = Visuals.manifest()
	var source_hashes: Dictionary = {}
	for asset: String in ["surfaces","props"]:
		source_hashes[asset] = FileAccess.get_sha256(Visuals.asset_path(asset))
		_check(Visuals.texture(asset) != null,"actual imported texture "+asset)
		_check(Visuals.texture(asset) == Visuals.texture(asset),"shared texture reused "+asset)
	await _sample(Vector2i(1360,880))
	await _sample(Vector2i(390,844))
	await _navigation()
	await _footprints()
	_check(Visuals.manifest() == manifest_before,"visual reads leave registry unchanged")
	for asset: String in source_hashes:
		_check(FileAccess.get_sha256(Visuals.asset_path(asset)) == source_hashes[asset],"native sampling preserves source PNG "+asset)
	print("WORLD SURFACES: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

func _canvas(view: Vector2i, transparent: bool = false) -> SubViewport:
	var canvas := SubViewport.new()
	canvas.size = view
	canvas.transparent_bg = transparent
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	return canvas

func _label(parent: Node, caption: String, at: Vector2, extent: Vector2, font_size: int = 16) -> Label:
	var text := Label.new()
	text.text = caption
	text.position = at
	text.size = extent
	text.add_theme_font_size_override("font_size",font_size)
	text.add_theme_color_override("font_color",Color("f6e6c9"))
	text.add_theme_color_override("font_shadow_color",Color(0,0,0,0.8))
	text.add_theme_constant_override("shadow_offset_y",1)
	text.clip_text = true
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(text)
	return text

func _button(parent: Node, role: String, state: String, rect: Rect2, caption: String = "Ir") -> Button:
	var button := Button.new()
	button.text = caption
	button.position = rect.position
	button.size = rect.size
	button.custom_minimum_size = rect.size
	button.clip_text = true
	button.add_theme_font_size_override("font_size",16)
	Visuals.apply_button(button,role)
	# Freeze each native state for a simultaneous swatch, without synthetic input.
	if state != "focus": button.add_theme_stylebox_override("normal",Visuals.surface(role,state))
	button.disabled = state == "disabled"
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(button)
	if state == "focus":
		var ring := FocusSample.new()
		ring.style = button.get_theme_stylebox("focus")
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(ring)
		ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	buttons.append(button)
	return button

func _picture(parent: Node, texture: Texture2D, rect: Rect2) -> TextureRect:
	var picture := TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture = texture
	picture.position = rect.position
	picture.size = rect.size
	picture.set_meta("expected_rect",rect)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(picture)
	return picture

func _prop(id: String) -> Dictionary:
	for definition: Dictionary in Visuals.manifest().props:
		if str(definition.id) == id: return definition
	return {}

func _sample(view: Vector2i) -> void:
	buttons.clear()
	var canvas := _canvas(view)
	var background := Backdrop.new()
	canvas.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.set_context("workshop")
	var phone := view.x < 500
	var margin := 16.0 if phone else 48.0
	_label(canvas,"BRASA · Superficies nativas",Vector2(margin,14),Vector2(view.x-2*margin,36),20 if phone else 28)
	_label(canvas,"Estados fijos · 48 / 56 px",Vector2(margin,50),Vector2(view.x-2*margin,26),14 if phone else 18)
	var width := 64.0 if phone else 192.0
	var gap := 8.0 if phone else 48.0
	for row in range(2):
		var role := "primary" if row == 0 else "secondary"
		var top := 90.0 + row*100.0
		for i in range(STATES.size()):
			var x := margin+i*(width+gap)
			_label(canvas,STATES[i],Vector2(x,top),Vector2(width,22),11 if phone else 16)
			_button(canvas,role,STATES[i],Rect2(x,top+26,width,48+row*8),"Ruta" if phone else "Continuar")
	_label(canvas,"90 px · estados nativos compactos",Vector2(margin,296),Vector2(view.x-2*margin,24),13 if phone else 18)
	for i in range(3):
		_button(canvas,"primary" if i != 1 else "secondary",["normal","focus","disabled"][i],Rect2(margin+i*114,328,90,48 if i == 0 else 56),["Ruta","Volver","Fijado"][i])
	var frame_width := 166.0 if phone else 360.0
	for i in range(2):
		var panel := PanelContainer.new()
		panel.position = Vector2(margin+i*(frame_width+(26 if phone else 40)),410)
		panel.size = Vector2(frame_width,118 if phone else 132)
		Visuals.apply_card(panel,"panel" if i == 0 else "boss_panel")
		canvas.add_child(panel)
		var title := Label.new()
		title.text = "Encuentro" if i == 0 else "Guardián"
		title.add_theme_font_size_override("font_size",16)
		title.add_theme_color_override("font_color",Color("fff0d7"))
		panel.add_child(title)
	_label(canvas,"Insignias · 48 / 56 px",Vector2(margin,550),Vector2(view.x-2*margin,24),14 if phone else 18)
	for i in range(3):
		var badge := Visuals.illustration(["encounter_badge","boss_badge","elite_badge"][i])
		_check(badge != null,"badge region loads")
		_picture(canvas,badge,Rect2(margin+i*116,580,48,48))
		_picture(canvas,badge,Rect2(margin+i*116+50,576,56,56))
	_label(canvas,"Objetos · alpha original · 48 / 56 px",Vector2(margin,642),Vector2(view.x-2*margin,24),13 if phone else 18)
	for i in range(PROP_IDS.size()):
		var definition := _prop(PROP_IDS[i])
		var texture := Visuals.region_texture(str(definition.get("asset","")),definition.get("region",[]))
		_check(texture != null,"isolated prop region "+PROP_IDS[i])
		var x := margin+(i%3)*116 if phone else margin+i*200
		var y := 678+(i/3)*80 if phone else 694
		_picture(canvas,texture,Rect2(x,y,48,48))
		_picture(canvas,texture,Rect2(x+50,y-4,56,56))
		_label(canvas,PROP_IDS[i],Vector2(x,y+50),Vector2(110,20),10 if phone else 13)
	await process_frame
	await process_frame
	var all_fit := true
	var all_touch := true
	for button: Button in buttons:
		all_fit = all_fit and Rect2(Vector2.ZERO,Vector2(view)).encloses(button.get_global_rect())
		all_touch = all_touch and button.size.x >= 40 and button.size.y >= 40
	_check(all_fit,"all button footprints fit "+str(view))
	_check(all_touch,"all samples retain40px minimum hit target "+str(view))
	var pictures_fit := true
	for child: Node in canvas.get_children():
		if child is TextureRect and child.has_meta("expected_rect"):
			pictures_fit = pictures_fit and child.get_global_rect().is_equal_approx(child.get_meta("expected_rect"))
	_check(pictures_fit,"badges and props retain requested48/56px extent "+str(view))
	if not capture_dir.is_empty(): await _capture(canvas,"surfaces-%dx%d.png" % [view.x,view.y])
	canvas.queue_free()
	await process_frame

func _navigation() -> void:
	buttons.clear()
	var canvas := _canvas(Vector2i(390,180))
	var backdrop := Backdrop.new()
	canvas.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.set_context("workshop")
	_label(canvas,"Tabs móviles · 64 × 48 · fuente13",Vector2(16,20),Vector2(358,28),16)
	for i in range(5):
		var button := _button(canvas,"navigation_active" if i == 0 else "navigation","normal",Rect2(16+i*72,72,64,48),["Ruta","Mejora","Golpes","Equipo","Legado"][i])
		button.add_theme_font_size_override("font_size",13)
	await process_frame
	await process_frame
	var exact := true
	var labels_fit := true
	for button: Button in buttons:
		exact = exact and button.size.is_equal_approx(Vector2(64,48))
		var text_width := button.get_theme_font("font").get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
		labels_fit = labels_fit and text_width <= button.size.x-button.get_theme_stylebox("normal").get_minimum_size().x
	_check(exact,"five actual navigation labels retain64x48 hit targets")
	_check(labels_fit,"mobile navigation labels fit native text insets")
	if not capture_dir.is_empty(): await _capture(canvas,"surfaces-mobile-navigation.png")
	canvas.queue_free()
	await process_frame

func _footprints() -> void:
	buttons.clear()
	var canvas := _canvas(Vector2i(420,136),true)
	var expected: Array[Rect2] = []
	for i in range(4):
		var extent := Vector2(64,48) if i%2 == 0 else Vector2(90,56)
		var rect := Rect2(Vector2(16+i*100,40),extent)
		expected.append(rect)
		_button(canvas,"primary" if i < 2 else "secondary","normal",rect)
	await process_frame
	await process_frame
	for i in range(buttons.size()):
		_check(buttons[i].get_global_rect().is_equal_approx(expected[i]),"narrow native button does not force a larger hit area")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var image := canvas.get_texture().get_image()
		var outside := 0
		var painted := 0
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				if image.get_pixel(x,y).a < 0.05: continue
				painted += 1
				var allowed := false
				for rect: Rect2 in expected:
					if rect.grow(2).has_point(Vector2(x,y)): allowed = true
				if not allowed: outside += 1
		_check(painted > 3000,"9slice surfaces remain visibly painted at compact sizes")
		_check(outside == 0,"transparent source cannot create a large painted footprint outside controls")
		if not capture_dir.is_empty():
			_check(image.save_png(capture_dir.path_join("surfaces-transparent-footprints.png")) == OK,"native alpha footprint capture saved")
	canvas.queue_free()
	await process_frame

func _capture(canvas: SubViewport, filename: String) -> void:
	await RenderingServer.frame_post_draw
	_check(canvas.get_texture().get_image().save_png(capture_dir.path_join(filename)) == OK,"native swatch capture saved")
