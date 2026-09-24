extends SceneTree
## No save files: checks card selection, naming and first-time modal behavior.
## Add -- --preview to keep the roster window open for visual inspection.
const Roster = preload("res://scripts/ui/roster_panel.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const BalanceConfig = preload("res://scripts/balance.gd")

var _checks: int = 0
var _failures: int = 0
var _selection: Array = []
var _closes: int = 0
var _test_viewport: SubViewport
const VIEW_SIZES: Array[Vector2i] = [Vector2i(1360, 880), Vector2i(1224, 792), Vector2i(1920, 1080), Vector2i(768, 1024), Vector2i(390, 844), Vector2i(430, 932), Vector2i(844, 390)]


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("ROSTER FAIL: " + description)


func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	root.min_size = Vector2i.ZERO
	root.size = Vector2i(1360, 880)
	# Native-size render surface avoids the host window manager clipping taller
	# tablet/desktop fixtures to the physical monitor's available work area.
	var host := SubViewportContainer.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	_test_viewport = SubViewport.new()
	_test_viewport.size = Vector2i(1360, 880)
	_test_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	host.add_child(_test_viewport)
	var panel := Roster.new()
	_test_viewport.add_child(panel)
	var definitions: Array = Catalog.all_definitions()
	var first_id: String = str(definitions[0]["id"])
	var profiles: Dictionary = {}
	profiles[first_id] = {"character_id": first_id, "name": "Luz de prueba", "archetype": definitions[0]["archetype"], "level": 4, "xp": 27, "stats": definitions[0]["training_base"].duplicate()}
	panel.character_chosen.connect(func(id: String, alias: String): _selection = [id, alias])
	panel.closed.connect(func(): _closes += 1)
	panel.configure(definitions, profiles, first_id, true)
	await process_frame
	await process_frame
	_check(panel._cards.size() == definitions.size(), "one card per definition")
	_check(panel._cards.size() == Catalog.IDS.size(), "all characters available")
	_check(not panel._close_button.visible, "first choice has no dismiss button")
	panel._request_close()
	_check(_closes == 0, "first choice cannot be dismissed")
	_check(panel._name_input.text == "Luz de prueba", "existing nickname appears")
	panel._name_input.text = "  Cometa  "
	panel._select(1)
	panel._select(0)
	_check(panel._name_input.text == "  Cometa  ", "per-character name draft survives browsing")
	panel._emit_choice()
	_check(_selection == [first_id, "Cometa"], "choice emits clean name and stable character ID")
	_check(profiles[first_id]["name"] == "Luz de prueba", "browsing and choosing never mutate input profile")
	for index in range(definitions.size()):
		panel._select(index)
		var profile: Dictionary = panel._preview_profile(definitions[index])
		var stats: Dictionary = Catalog.stats_for(profile)
		_check(stats.size() >= 9, "every character has combat stat preview")
		_check(panel._portraits[index].get_sprite_geometry().size() > 0, "every portrait uses illustrated art")
		_check(panel._portraits[index].visual_tint == Color(str(definitions[index]["visual"]["tint"])), "portrait tint follows catalog data")
		_check(panel._name_input.text.length() > 0, "every choice has a sensible default name")
	panel._select(0)
	var right := InputEventKey.new()
	right.keycode = KEY_RIGHT
	right.pressed = true
	panel._card_input(right, 0)
	_check(panel._selected_index == 1, "arrow keys browse cards")
	panel._name_input.text = " "
	panel._emit_choice()
	_check(_selection[1] == str(definitions[1]["name"]), "blank name falls back to character name")
	panel.configure(definitions, profiles, first_id, false)
	await process_frame
	await process_frame
	_check(panel._close_button.visible, "returning player can close")
	panel._request_close()
	_check(_closes == 1, "close emits once")
	_check(panel.get_global_rect().encloses(panel._choose_button.get_global_rect()), "primary action remains visible")
	_check(panel._detail_scroll.size.y > 300, "details have a usable scrolling viewport")
	var tiny_percent: String = panel._format_gain(0.0008, {"format": "percent"})
	_check(tiny_percent.contains("0.08"), "small percentage growth is not rounded away")
	var capture_dir: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			capture_dir = argument.trim_prefix("--capture-dir=")
			DirAccess.make_dir_recursive_absolute(capture_dir)
	for view_size: Vector2i in VIEW_SIZES:
		await _test_layout(panel, view_size, capture_dir)
	print("ROSTER TESTS: %d checks, %d failures" % [_checks, _failures])
	root.size = Vector2i(1360, 880)
	_test_viewport.size = Vector2i(1360, 880)
	panel._set_mobile_page(0)
	await _settle()
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			await RenderingServer.frame_post_draw
			_test_viewport.get_texture().get_image().save_png(argument.trim_prefix("--capture="))
	if OS.get_cmdline_user_args().has("--preview"):
		root.title = "Brasa · Vista de compañeros"
		return
	quit(0 if _failures == 0 else 1)


func _settle() -> void:
	for _frame in range(5):
		await process_frame


func _inside(rect: Rect2, boundary: Rect2) -> bool:
	return boundary.grow(1.0).encloses(rect)


func _test_layout(panel: RosterPanel, view_size: Vector2i, capture_dir: String) -> void:
	var selected_before: int = panel._selected_index
	var name_before: String = panel._name_input.text
	root.size = view_size
	_test_viewport.size = view_size
	panel._set_mobile_page(0)
	await _settle()
	var label: String = "%dx%d" % [view_size.x, view_size.y]
	var boundary := Rect2(Vector2.ZERO, Vector2(view_size))
	_check(panel._selected_index == selected_before, label + ": resize preserves selected identity")
	_check(panel._name_input.text == name_before, label + ": resize preserves nickname draft")
	_check(panel.size.is_equal_approx(Vector2(view_size)), label + ": uses native viewport without legacy scaling")
	_check(_inside(panel._shell.get_global_rect(), boundary), label + ": shell stays within viewport")
	_check(_inside(panel._header.get_global_rect(), boundary), label + ": heading stays within viewport")
	_check(_inside(panel._choose_button.get_global_rect(), boundary), label + ": choose always visible")
	_check(_inside(panel._name_input.get_global_rect(), boundary), label + ": name always visible")
	_check(not panel._choose_button.get_global_rect().intersects(panel._name_input.get_global_rect()), label + ": name and choose never overlap")
	var touch_height: float = 44.0 if view_size.y < 520 else 48.0
	_check(panel._choose_button.size.y >= touch_height and panel._name_input.size.y >= touch_height, label + ": footer has accessible touch targets")
	_check(panel._close_button.size.y >= touch_height, label + ": close has accessible touch target")
	_check(panel._roster_scroll.size.y >= 110.0, label + ": roster has usable scroll area")
	_check(panel._grid.size.x <= panel._roster_scroll.size.x + 1.0, label + ": cards never overflow horizontally")
	for index in range(panel._cards.size()):
		var card: Button = panel._cards[index]
		_check(card.size.x >= 120 and card.size.y >= 48, label + ": card remains tappable")
		if index > 0 and index % panel._grid.columns != 0:
			_check(not card.get_global_rect().intersects(panel._cards[index - 1].get_global_rect()), label + ": neighboring cards do not overlap")
	panel._roster_scroll.ensure_control_visible(panel._cards[-1])
	await _settle()
	var last_card: Rect2 = panel._cards[-1].get_global_rect()
	var scroll_rect: Rect2 = panel._roster_scroll.get_global_rect()
	_check(last_card.intersects(scroll_rect), label + ": last character reachable by scrolling")
	panel._roster_scroll.scroll_vertical = 0
	panel._select(0)
	await _settle()
	if not capture_dir.is_empty():
		await RenderingServer.frame_post_draw
		_test_viewport.get_texture().get_image().save_png(capture_dir.path_join("roster-" + label + ".png"))
	if panel._compact:
		_check(panel._tabs.visible, label + ": compact view has roster/detail tabs")
		panel._card_pressed(Catalog.IDS.size() - 1)
		await _settle()
		_check(panel._mobile_page == 1 and panel._detail_panel.visible, label + ": tapping a card opens its complete details")
		_check(panel._detail_tab.text.contains(str(Catalog.definition(Catalog.IDS[-1]).name)), label + ": details correspond to selected last character")
	_check(panel._detail.size.x <= panel._detail_scroll.size.x + 1.0, label + ": details do not overflow horizontally")
	_check(_inside(panel._detail_panel.get_global_rect(), boundary), label + ": details panel stays within viewport")
	_check(panel._detail_scroll.size.y >= 100.0, label + ": details keep a usable scrolling viewport")
	if not panel._show_about: panel._toggle_about()
	await _settle()
	var signature_box: Control = panel._detail.find_child("Signature",true,false)
	panel._detail_scroll.ensure_control_visible(signature_box)
	await _settle()
	_check(signature_box.get_global_rect().intersects(panel._detail_scroll.get_global_rect()), label + ": signature information is reachable")
	panel._detail_scroll.scroll_vertical = 0
	if not capture_dir.is_empty() and panel._compact:
		await RenderingServer.frame_post_draw
		_test_viewport.get_texture().get_image().save_png(capture_dir.path_join("detail-" + label + ".png"))
