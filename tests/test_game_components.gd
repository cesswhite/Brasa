extends SceneTree
## Isolated UI nodes, catalogue data and actual sprite geometry. No save paths.

const Preview = preload("res://scripts/ui/components/game_fighter_preview.gd")
const Badge = preload("res://scripts/ui/components/game_badge.gd")
const Header = preload("res://scripts/ui/components/game_section_header.gd")
const Modal = preload("res://scripts/ui/components/game_modal.gd")
const Visuals = preload("res://scripts/ui/game_visual_system.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Cosmetics = preload("res://scripts/cosmetic_catalog.gd")
const SIZES: Array[Vector2] = [Vector2(1360,880),Vector2(768,1024),Vector2(390,844),Vector2(844,390)]

var checks := 0
var failures := 0
var closes := 0


func _init() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("GAME COMPONENT FAIL: " + message)


func _settle() -> void:
	for frame in range(4): await process_frame


func _inside(outer: Rect2, inner: Rect2) -> bool:
	return outer.grow(1).encloses(inner)


func _run() -> void:
	root.size = Vector2i(1360,880)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var host := Control.new()
	host.size = Vector2(1360,880)
	root.add_child(host)
	await _test_preview(host)
	await _test_labels(host)
	await _test_modal(host)
	host.free()
	print("GAME COMPONENTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _test_preview(host: Control) -> void:
	var preview := Preview.new()
	preview.configure({}, Catalog.definition("nima"))
	host.add_child(preview)
	_check(not preview.actor().motion_paused and preview.actor().is_processing(),"portrait configured before attachment starts normally")
	_check(preview.mouse_filter == Control.MOUSE_FILTER_IGNORE, "portrait never intercepts a card click")
	for id: String in Catalog.IDS:
		var definition := Catalog.definition(id)
		var before := var_to_bytes(definition)
		preview.configure({},definition)
		var sprite := preview.actor().get_node("IllustratedFighter") as Sprite2D
		var expected_atlas: String = definition.visual.get("atlas", Preview.Fighter.ATLAS_PATHS[int(definition.visual.archetype)])
		_check(sprite.texture != null and preview.actor().get_sprite_geometry().path == expected_atlas, id+" uses its genuine atlas")
		for extent: Vector2 in [Vector2(420,470),Vector2(168,180),Vector2(112,96)]:
			preview.size = extent
			preview.set_motion(false,false)
			preview.actor().set_process(false)
			for time in range(4):
				preview.actor()._process(0.29)
				var actual: Rect2 = preview.get_global_transform().affine_inverse()*preview.actor().visible_sprite_bounds()
				_check(_inside(Rect2(Vector2.ZERO,extent),actual),"idle sprite fits %s %s sample%d" % [id,extent,time])
		_check(var_to_bytes(definition) == before,id+" catalogue stays immutable")
	var definition := Catalog.definition("onix")
	var profile := {"character_id":"onix","fighter_id":"fixture-stable","identity":{"display_name":"Mi compañero"},"appearance":Cosmetics.default_appearance("bruma"),"level":37,"stats":{"attack":99}}
	profile.appearance.palette_id = "jade"
	profile.appearance.aura_id = "farol"
	profile.appearance.intro_animation_id = "pulso"
	var original := var_to_bytes(profile)
	preview.configure(profile,definition)
	_check(preview.actor().get_sprite_geometry().path == Catalog.definition("bruma").visual.atlas, "cosmetic body is independent of gameplay archetype")
	_check(preview.actor().identity.display_name == "Mi compañero" and preview.actor().appearance.palette_id == "jade", "identity and full appearance reach real renderer")
	_check(_inside(Rect2(Vector2.ZERO,preview.size),preview.visual_bounds()),"cosmetic envelope also fits smallest card")
	profile.identity.display_name = "Changed outside"
	profile.appearance.palette_id = "ocaso"
	_check(preview.actor().identity.display_name == "Mi compañero" and preview.actor().appearance.palette_id == "jade", "preview keeps no nested input aliases")
	profile.identity.display_name = "Mi compañero"
	profile.appearance.palette_id = "jade"
	_check(var_to_bytes(profile) == original, "configuration never modifies gameplay profile")
	preview.set_motion(true,true)
	_check(preview.actor().motion_paused and preview.actor().reduced_motion,"pause and reduced motion forwarded")
	preview.hide()
	preview.set_motion(false,false)
	_check(not preview.actor().is_processing(),"hidden portrait does not keep processing")
	preview.show()
	_check(preview.actor().is_processing(),"visible portrait resumes its visual clock")
	preview.free()


func _test_labels(host: Control) -> void:
	var header := Header.new()
	host.add_child(header)
	header.configure("BRASA / HISTORIA","El paso de la tormenta","Una descripción extensa que conserva lectura al reducir el ancho del panel.")
	header.size.x = 168
	header.set_compact(true)
	await _settle()
	_check(header.heading_label.get_theme_font("font") == Visuals.font("title"),"heading uses shared Story serif")
	_check(header.heading_label.get_theme_font_size("font_size") == Visuals.font_size("title",true),"compact typography uses shared token")
	_check(header.heading_label.get_line_count() > 1 and header.subtitle_label.get_line_count() > 1,"narrow heading and subtitle wrap instead of truncation")
	_check(not header.eyebrow_label.get_rect().intersects(header.heading_label.get_rect()) and not header.heading_label.get_rect().intersects(header.subtitle_label.get_rect()),"header hierarchy has disjoint text rows")
	header.configure("","Compañeros","")
	_check(not header.eyebrow_label.visible and not header.subtitle_label.visible,"empty optional text takes no row")
	header.free()
	var badge := Badge.new()
	host.add_child(badge)
	for kind: String in ["normal","elite","boss"]:
		badge.configure("Encuentro superado", "completed", kind)
		badge.size = Vector2(160,48)
		await _settle()
		_check(badge.icon.texture is AtlasTexture,"badge uses existing Story atlas: "+kind)
		_check(not badge.icon.get_rect().intersects(badge.label.get_rect()),"badge text remains separate from emblem: "+kind)
		_check(badge.label.get_theme_color("font_color") == Visuals.color("success"),"badge uses shared semantic colour: "+kind)
	badge.configure("Bloqueado","locked","boss")
	_check(badge.mouse_filter == Control.MOUSE_FILTER_IGNORE and badge.icon.mouse_filter == Control.MOUSE_FILTER_IGNORE,"badges remain non-interactive")
	badge.configure("Estado","unknown","unknown")
	_check(badge.state=="neutral" and badge.kind=="normal","unknown display states fall back safely")
	badge.free()


func _test_modal(host: Control) -> void:
	var opener := Button.new()
	opener.text = "Abrir"
	host.add_child(opener)
	var modal := Modal.new()
	host.add_child(modal)
	modal.configure("Apariencia del compañero","Los cambios se revisan antes de guardar.","Esc cierra esta ventana.")
	modal.closed.connect(func(): closes += 1)
	for index in range(30):
		var line := Label.new()
		line.text = "Contenido de prueba %d" % index
		modal.content().add_child(line)
	var action := Button.new()
	action.text = "Acción de prueba"
	modal.content().add_child(action)
	var disabled := Button.new()
	disabled.text = "No disponible"
	disabled.disabled = true
	modal.content().add_child(disabled)
	for extent: Vector2 in SIZES:
		host.size = extent
		opener.grab_focus()
		modal.open(opener)
		await _settle()
		var panel := modal.get_node("Panel") as PanelContainer
		var header := panel.get_node("Stack/HeaderRow") as Control
		var scroll := panel.get_node("Stack/BodyScroll") as ScrollContainer
		var hint := panel.get_node("Stack/Hint") as Control
		var close_button := panel.get_node("Stack/HeaderRow/Close") as Button
		_check(_inside(Rect2(Vector2.ZERO,extent), panel.get_rect()),"modal fits "+str(extent))
		_check(close_button.size.x >= 44 and close_button.size.y >= 44,"modal close is touch accessible "+str(extent))
		_check(not header.get_rect().intersects(scroll.get_rect()) and (not hint.visible or not scroll.get_rect().intersects(hint.get_rect())),"visible modal chrome stays clear of body "+str(extent))
		_check(hint.visible == (extent.x >= 600),"keyboard hint is reserved for wider windows "+str(extent))
		_check(scroll.get_v_scroll_bar().max_value > scroll.size.y,"long content stays reachable by scrolling "+str(extent))
		_check(root.gui_get_focus_owner() == close_button,"opening focuses close "+str(extent))
		for step in range(6):
			var tab := InputEventKey.new()
			tab.keycode = KEY_TAB
			tab.pressed = true
			tab.shift_pressed = step > 2
			modal._input(tab)
			var focused := root.gui_get_focus_owner()
			_check(focused != disabled and modal.is_ancestor_of(focused),"Tab remains inside active content "+str(extent))
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.pressed = true
		modal._input(escape)
		_check(not modal.visible and root.gui_get_focus_owner() == opener,"Escape closes and restores opener "+str(extent))
	modal.close()
	_check(closes == SIZES.size(),"one close signal per opening; repeat close is inert")
	_check(modal.content().get_child_count()==32,"modal layout preserves caller-owned content")
	modal.free()
	opener.free()
