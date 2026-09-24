extends SceneTree
## Real roster controls with in-memory profiles; no Main boot or persistence.
const Roster = preload("res://scripts/ui/roster_panel.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Cosmetics = preload("res://scripts/cosmetic_catalog.gd")
const Visuals = preload("res://scripts/ui/game_visual_system.gd")
const Preview = preload("res://scripts/ui/components/game_fighter_preview.gd")
const SIZES: Array[Vector2] = [Vector2(1360,880),Vector2(1224,792),Vector2(1920,1080),Vector2(768,1024),Vector2(390,844),Vector2(430,932),Vector2(844,390)]
var checks := 0
var failures := 0
var closes := 0
var choices := 0

func _init() -> void: _run.call_deferred()

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ROSTER VISUAL SYSTEM: "+message)

func _settle() -> void:
	for frame in range(5): await process_frame

func _key(code: Key, shift: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.shift_pressed = shift
	event.pressed = true
	return event

func _run() -> void:
	root.size = Vector2i(390,844)
	var canvas := SubViewport.new()
	canvas.size = Vector2i(SIZES[0])
	root.add_child(canvas)
	var hud := Button.new()
	hud.text = "HUD subyacente"
	canvas.add_child(hud)
	var panel := Roster.new()
	canvas.add_child(panel)
	panel.closed.connect(func(): closes += 1)
	panel.character_chosen.connect(func(_id: String,_name: String): choices += 1)
	var definitions := Catalog.all_definitions()
	var index := Catalog.IDS.find("mugo")
	definitions[index].appearance = Cosmetics.default_appearance("tepa")
	definitions[index].appearance.palette_id = "jade"
	definitions[index].identity = {"display_name":"Luz del refugio"}
	var profiles := {"mugo":{"character_id":"mugo","name":"Luz del refugio","level":12,"xp":27,"stats":Catalog.definition("mugo").training_base.duplicate(true),"wins":3}}
	var definitions_before := var_to_bytes(definitions)
	var profiles_before := var_to_bytes(profiles)
	panel.configure(definitions,profiles,"mugo",false)
	for size_value: Vector2 in SIZES:
		canvas.size = Vector2i(size_value)
		panel._select(index,false)
		panel._set_mobile_page(0)
		await _settle()
		_check(panel.theme==Visuals.theme(),"roster inherits shared theme "+str(size_value))
		_check(panel._shell.get_theme_stylebox("panel") is StyleBoxEmpty and panel._detail_panel.get_theme_stylebox("panel") is StyleBoxEmpty,"shell and detail leave camp open")
		var paths: Array[String] = panel._backdrop.loaded_background_paths()
		_check(paths.size()==1 and paths[0].ends_with("camp-v1.png"),"only current Camp background is loaded")
		_check(panel._close_button.get_meta("game_visual_role")=="icon" and panel._close_button.size==Vector2(48,48),"shared close icon remains48px")
		for card: Button in panel._cards:
			_check(card.get_meta("game_component")=="character_card" and card.get_theme_stylebox("hover") is StyleBoxFlat and card.get_theme_stylebox("pressed") is StyleBoxFlat,"all companion states use open shared cards")
		_check(panel._cards[index].get_meta("actor")==panel._portraits[index],"legacy portrait metadata preserves card indexing")
		if panel._compact:
			_check(panel._roster_tab.get_meta("game_visual_role")=="navigation_active" and panel._detail_tab.get_meta("game_visual_role")=="navigation","mobile pages share selected and idle navigation")
		panel._set_mobile_page(1)
		await _settle()
		var preview := panel._detail.get_child(0)
		_check(preview.get_script()==Preview,"selected real preview leads complete detail")
		_check(preview.actor().get_sprite_geometry().path.ends_with("tepa-v1.png") and preview.actor().appearance.palette_id=="jade","selected preview preserves body and palette independent of Mugo combat")
		_check(preview.actor().identity.display_name=="Luz del refugio","selected preview preserves identity")
		_check(Rect2(Vector2.ZERO,preview.size).grow(1).encloses(preview.visual_bounds()),"shared preview framing remains inside its allocated area")
		var bars := panel._detail.find_children("*","ProgressBar",true,false)
		_check(bars.size()==1 and bars[0].get_meta("game_component")=="progress" and bars[0].value==27,"XP rail shares style and keeps exact profile value")
		if not panel._show_about: panel._toggle_about()
		await _settle()
		var signature: Control = panel._detail.find_child("Signature",true,false)
		panel._detail_scroll.ensure_control_visible(signature)
		await _settle()
		_check(signature.get_global_rect().intersects(panel._detail_scroll.get_global_rect()),"signature remains reachable below the new portrait")
		panel._set_mobile_page(0)
		panel._cards[0].grab_focus()
		canvas.push_input(_key(KEY_RIGHT),true)
		_check(panel._selected_index==1,"arrow browsing reaches its original card handler")
		for step in range(24):
			canvas.push_input(_key(KEY_TAB,step>=12),true)
			var focused := canvas.gui_get_focus_owner()
			_check(is_instance_valid(focused) and panel.is_ancestor_of(focused) and focused!=hud,"Tab/Shift-Tab cannot escape to underlying HUD")
	_check(var_to_bytes(definitions)==definitions_before and var_to_bytes(profiles)==profiles_before,"browse, resize and appearance preview leave input data immutable")
	_check(choices==0,"focus and arrows never commit a selection")
	canvas.push_input(_key(KEY_ESCAPE),true)
	_check(closes==1,"returning roster Escape emits exactly once")
	panel.configure(definitions,profiles,"mugo",true)
	await _settle()
	canvas.push_input(_key(KEY_ESCAPE),true)
	_check(closes==1 and not panel._close_button.visible,"first companion cannot be dismissed via shared focus helper")
	panel.free()
	canvas.free()
	print("ROSTER VISUAL SYSTEM: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
