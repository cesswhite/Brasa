extends SceneTree
## Production Main documents against isolated fixture profiles. No real settings,
## fullscreen, network, user:// files or gameplay rewards are invoked.
const Base = preload("res://tests/test_identity_integration.gd")
const Progress = preload("res://scripts/progression.gd")
const Story = preload("res://scripts/story_progression.gd")
const Cosmetics = preload("res://scripts/cosmetic_catalog.gd")
const Records = preload("res://scripts/battle_identity.gd")
const Combat = preload("res://scripts/combat_engine.gd")
const Preview = preload("res://scripts/ui/components/game_fighter_preview.gd")
const Views = preload("res://tests/test_battle_layout.gd")

class Fixture:
	extends Base.Fixture
	var surrender_requests := 0
	var surrendered_while_paused := false
	func _accept_surrender() -> void:
		# Verify the destructive action's binding without rewarding or persisting.
		surrender_requests += 1
		surrendered_while_paused = player_view.motion_paused and rival_view.motion_paused and combat_fx.motion_paused

var checks := 0
var failures := 0
var screen: Fixture
var canvas: SubViewport
var capture_dir := ""
var where := ""

func _init() -> void: _run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("DOCUMENT STATES: " + message + " " + where)

func _run() -> void:
	create_timer(120,true,false,true).timeout.connect(func(): push_error("DOCUMENT STATES timeout"); quit(1))
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): capture_dir = argument.trim_prefix("--capture-dir=")
	if not capture_dir.is_empty(): DirAccess.make_dir_recursive_absolute(capture_dir)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(360,240)
	canvas = SubViewport.new()
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	var directory := ProjectSettings.globalize_path("res://../../work/visual-system/documents-qa/fixtures").simplify_path()
	DirAccess.make_dir_recursive_absolute(directory)
	var template := _battle_record()
	check(not Records.snapshot(template).is_empty(), "Natural deterministic battle produces a valid historical snapshot")
	for view: Vector2 in Views.SIZES:
		where = str(view)
		canvas.size = Vector2i(view)
		var path := directory.path_join("document-states-%dx%d-%d.json" % [view.x,view.y,Time.get_ticks_usec()])
		var league := Progress.new()
		league.load_save(path)
		league.select_character("tepa", "Nombre Liga Actual")
		var story := Story.new()
		story.load_save(path+".story.json")
		story.select_character("tepa", "Nombre Historia Actual")
		screen = Fixture.new()
		screen.fixture_path = path
		canvas.add_child(screen)
		screen.size = view
		screen._layout_interface(view)
		await _settle()
		var current := Cosmetics.default_appearance("balam")
		current.palette_id = "ocaso"
		check(screen.fighter_identity.update_fighter("tepa", "IDENTIDAD NUEVA", current).ok, "Set distinct current identity only in disposable sidecar")
		var file_state := _files(path)
		var identity_state: Dictionary = screen.fighter_identity.data.duplicate(true)
		var league_state: Dictionary = screen.progression.data.duplicate(true)
		var story_state: Dictionary = screen.story_progression.data.duplicate(true)
		var setting_state := [screen.sound_enabled,screen.quick_mode,screen.reduced_motion,screen.get_window().mode]
		await _history(template)
		await _settings()
		await _surrender_and_active_history(template)
		check(_files(path)==file_state, "Opening, scrolling, replaying, cancelling and closing never writes either profile, identity or backups")
		check(screen.fighter_identity.data==identity_state, "Browsing preserves stable IDs, current names, inventory and appearance")
		check(screen.progression.data==league_state and screen.story_progression.data==story_state, "Browsing never changes XP, points, stats or either campaign")
		check([screen.sound_enabled,screen.quick_mode,screen.reduced_motion,screen.get_window().mode]==setting_state, "No settings or fullscreen action executed")
		check(screen.session_save_path==path and not path.begins_with("user://"), "Fixture path remains explicit")
		screen.free()
		await process_frame
	canvas.free()
	await process_frame
	print("VISUAL HISTORY SETTINGS: %d checks, %d failures across 7 sizes" % [checks,failures])
	quit(0 if failures==0 else 1)

func _battle_record() -> Dictionary:
	var player := Progress._combatant(Progress._new_profile("tepa"))
	player["fighter_id"] = "fixture:historic-tepa"
	player["identity"] = {"display_name":"LUZ DE AYER"}
	player["name"] = "LUZ DE AYER"
	player["appearance"] = Cosmetics.default_appearance("luma")
	player.appearance.palette_id = "jade"
	player.appearance.victory_pose_id = "saludo"
	var rival := Progress._combatant(Progress._new_profile("copal"))
	rival["name"] = "RIVAL DEL RECUERDO"
	var engine := Combat.new()
	engine.start(player,rival,443211)
	engine.advance(120)
	var summary: Dictionary = engine.summary()
	var record := {"winner":summary.winner,"reason":summary.reason,"duration":summary.duration,"player_xp":19}
	Records.attach(record,summary)
	return record

func _history(template: Dictionary) -> void:
	# Empty history keeps its explanation and exposes no broken replay action.
	screen.progression.history.clear()
	screen._show_history()
	await _settle()
	check(screen.modal_body.visible and screen.modal_body.text.contains("primera pelea"), "Empty history explains how memories begin")
	check(not is_instance_valid(screen.history_scroll) and not is_instance_valid(screen.modal_accept), "Empty history has no replay CTA")
	_check_shell()
	screen._close_modal()
	await _settle()
	for i in range(12):
		var record := template.duplicate(true)
		var old_name := "RECUERDO %02d DE LUZ" % i
		record.player_name = old_name
		record.battle_snapshot.player.name = old_name
		record.battle_snapshot.player.identity.display_name = old_name
		record.battle_snapshot.battle_id = "fixture:memory:%d" % i
		screen.progression.history.append(record)
	var frozen_history: Array = screen.progression.history.duplicate(true)
	screen._show_history()
	await _settle()
	check(screen.modal_kind=="history" and is_instance_valid(screen.history_scroll), "Populated history uses actual memory scroll")
	_check_shell()
	var scroller: ScrollContainer = screen.history_scroll
	var list: VBoxContainer = scroller.get_child(0)
	check(list.get_child_count()==12, "All twelve memories remain available")
	check(scroller.follow_focus and scroller.horizontal_scroll_mode==ScrollContainer.SCROLL_MODE_DISABLED, "History keeps vertical-only accessible scrolling")
	check(list.size.x<=scroller.size.x+1, "Memory rows do not create horizontal overflow")
	check(is_instance_valid(screen.modal_accept) and not screen.modal_accept.disabled, "Replay CTA enabled outside battle")
	check(screen.modal_accept.size.y>=48 and screen.modal_accept.size.x>=48, "Replay CTA touch target")
	check(screen.modal_canvas.get_global_rect().grow(1).encloses(screen.modal_accept.get_global_rect()), "Replay CTA fits canvas")
	check(not scroller.get_global_rect().intersects(screen.modal_accept.get_global_rect()), "Replay action never overlaps history scroll")
	for i in range(list.get_child_count()):
		var card: Control = list.get_child(i)
		var row: HBoxContainer = card.get_child(0)
		var preview: Control = row.get_child(0)
		var text: VBoxContainer = row.get_child(1)
		check(preview is Preview, "Memory uses shared real FighterPreview")
		check(preview.actor().get_sprite_geometry().path=="res://assets/sprites/ajolote-v2.png", "Historical Luma body survives current Balam identity")
		check(preview.actor().appearance.palette_id=="jade", "Historical palette survives current ocaso")
		check(preview.actor().identity.display_name=="RECUERDO %02d DE LUZ" % (11-i), "Historical preview name and reverse chronological order")
		check(preview.actor().motion_paused, "Memory preview never advances a recorded battle")
		check(_text(text).contains("RECUERDO %02d DE LUZ" % (11-i)) and not _text(text).contains("IDENTIDAD NUEVA"), "Memory labels do not resolve current identity or draft")
		check(card.get_global_rect().grow(1).encloses(preview.get_global_rect()), "Portrait fits its memory card")
		check(not preview.get_global_rect().intersects(text.get_global_rect()), "Historical portrait and text do not overlap")
		for label: Label in text.get_children():
			check(card.get_global_rect().grow(1).encloses(label.get_global_rect()), "Complete wrapped historical text fits card")
		check(Rect2(Vector2.ZERO,preview.size).grow(1).encloses(preview.visual_bounds()), "Shared portrait camera stays inside the preview")
	scroller.scroll_vertical = 1000000
	await _settle()
	var last: Control = list.get_child(list.get_child_count()-1)
	check(scroller.scroll_vertical>0, "Long history actually scrolls")
	check(scroller.get_global_rect().grow(1).encloses(last.get_global_rect()), "Last complete historical card is reachable")
	check(_text(last).contains("RECUERDO 00 DE LUZ"), "Oldest memory remains the last reachable row")
	await _capture("history-bottom")
	# A read-only draft change after rendering must not update cards or snapshots.
	var original_name: String = screen.progression.data.name
	screen.progression.data.name = "BORRADOR NO GUARDADO"
	check(not _text(list).contains("BORRADOR NO GUARDADO"), "Changing current profile draft cannot rename historical cards")
	screen.progression.data.name = original_name
	check(screen.progression.history==frozen_history, "Reading cards leaves every immutable event/snapshot untouched")
	screen.modal_accept.pressed.emit()
	await _settle()
	check(is_instance_valid(screen.replay_layer) and not is_instance_valid(screen.modal_layer), "Enabled CTA opens one replay overlay")
	check(screen.replay_layer.snapshots.size()==12, "Replay receives all frozen snapshots")
	check(screen.replay_layer.snapshot.player.name=="RECUERDO 11 DE LUZ", "Replay starts from latest historical name")
	check(screen.replay_layer.actors.player.get_sprite_geometry().path=="res://assets/sprites/ajolote-v2.png", "Replay still uses historical appearance")
	screen._close_replays()
	await _settle()
	check(screen.progression.history==frozen_history, "Opening and closing replay cannot rewrite history or award XP")
	# Legacy records without a snapshot remain readable, with no fabricated image.
	screen.progression.history.clear()
	screen.progression.history.append({"player_name":"LEGADO SIN SNAPSHOT","rival_name":"Rival anterior","winner":"player","duration":30,"player_xp":8})
	screen._show_history()
	await _settle()
	check(_text(screen.history_scroll).contains("LEGADO SIN SNAPSHOT"), "Legacy record keeps original text")
	check(_find_previews(screen.history_scroll).is_empty() and not is_instance_valid(screen.modal_accept), "Legacy history does not invent appearance or replay")
	screen._close_modal()
	await _settle()
	screen.progression.history.clear()
	screen.progression.history.append_array(frozen_history)

func _settings() -> void:
	var original := [screen.sound_enabled,screen.quick_mode,screen.reduced_motion]
	for selected: bool in [false,true]:
		screen.sound_enabled = selected
		screen.quick_mode = selected
		screen.reduced_motion = selected
		screen._show_settings()
		await _settle()
		_check_shell()
		check(screen.menu_actions.size()==4, "Settings retains exactly four existing actions")
		check(screen.modal_canvas.custom_minimum_size.y>=228, "Settings canvas reserves enough space to scroll all four controls")
		var outer: ScrollContainer = screen.modal_layer.parts().scroll
		check(outer.follow_focus, "Settings scroll follows keyboard focus")
		var states: Array[bool] = [selected,selected,selected,screen.get_window().mode in [Window.MODE_FULLSCREEN,Window.MODE_EXCLUSIVE_FULLSCREEN]]
		for i in range(4):
			var button: Button = screen.menu_actions[i]
			check(not button.disabled and button.size.x>=48 and button.size.y>=48, "Enabled 48px setting "+str(i))
			check(button.icon!=null and button.get_meta("game_visual_role","")==("navigation_active" if states[i] else "navigation"), "Setting icon/material represents current state "+str(i))
			check(screen.modal_canvas.get_global_rect().grow(1).encloses(button.get_global_rect()), "Setting belongs to scrollable canvas "+str(i))
			for j in range(i):
				check(not button.get_global_rect().intersects(screen.menu_actions[j].get_global_rect()), "Settings controls do not overlap")
		var visited := {}
		screen.modal_close_button.grab_focus()
		for i in range(24):
			_send_key(KEY_TAB,i>=12)
			await _settle()
			var focus: Control = canvas.gui_get_focus_owner()
			check(focus!=null and screen.modal_layer.is_ancestor_of(focus), "Tab/Shift-Tab stay inside settings")
			if focus is Button and focus in screen.menu_actions:
				visited[screen.menu_actions.find(focus)] = true
				check(outer.get_global_rect().grow(1).encloses(focus.get_global_rect()), "Keyboard fully reveals focused setting, including landscape")
		check(visited.size()==4, "Keyboard reaches all four settings")
		outer.ensure_control_visible(screen.menu_actions.back())
		await _settle()
		check(outer.get_global_rect().grow(1).encloses(screen.menu_actions.back().get_global_rect()), "Fourth action remains reachable at scroll end")
		if selected: await _capture("settings-bottom")
		_send_key(KEY_ESCAPE)
		await _settle()
		check(not is_instance_valid(screen.modal_layer), "Escape closes settings exactly once")
		check(canvas.gui_get_focus_owner()==screen.menu_button, "Settings returns focus to opener")
	screen.sound_enabled = original[0]
	screen.quick_mode = original[1]
	screen.reduced_motion = original[2]

func _surrender_and_active_history(template: Dictionary) -> void:
	# Start only the real engine and active view state. Avoid _start_fight's
	# intentional identity write; this test concerns browsing during a battle.
	screen.combat.start(screen._player_combatant(),screen.rival,777123)
	screen.active_match = true
	screen.finishing = false
	var elapsed: float = screen.combat.elapsed
	screen._show_history()
	await _settle()
	check(screen.modal_accept.disabled and screen.modal_accept.tooltip_text.contains("terminar"), "Replay disabled with explicit explanation during battle")
	screen.modal_accept.pressed.emit()
	check(not is_instance_valid(screen.replay_layer), "Replay handler also rejects a forged disabled click")
	screen._process(1.0)
	check(screen.combat.elapsed==elapsed and screen.combat_fx.motion_paused, "History pauses engine and FX")
	screen._close_modal()
	await _settle()
	for story_mode: bool in [false,true]:
		screen.story_mode = story_mode
		screen._confirm_surrender()
		await _settle()
		_check_shell()
		check(screen.modal_kind=="surrender" and screen.modal_layer.preferred_height==460, "Surrender keeps compact shared modal")
		check(screen.modal_body.text.contains("XP") and screen.modal_body.text.to_lower().contains("rend"), "Surrender explains reward and consequence")
		check(screen.modal_body.text.contains("Conservas tu nivel") if story_mode else screen.modal_body.text.contains(str(screen.rival.name)), "Correct Story/League consequences remain present")
		check(screen.modal_subtitle.text.contains("En pausa"), "Pause is explicit in surrender dialog")
		check(screen.modal_cancel.text=="Seguir peleando" and screen.modal_accept.text=="Rendirme", "Both surrender actions retain unambiguous labels")
		for button: Button in [screen.modal_cancel,screen.modal_accept]:
			check(button.size.y>=48 and button.size.x>=48, "Surrender actions retain touch size")
			check(screen.modal_canvas.get_global_rect().grow(1).encloses(button.get_global_rect()), "Surrender action fits canvas")
			check(not screen.modal_body.get_global_rect().intersects(button.get_global_rect()), "Surrender text never overlaps actions")
		check(not screen.modal_cancel.get_global_rect().intersects(screen.modal_accept.get_global_rect()), "Surrender actions are disjoint")
		var inner: VScrollBar = screen.modal_body.get_v_scroll_bar()
		inner.value = inner.max_value
		await _settle()
		check(inner.max_value<=inner.page or inner.value>0, "Long surrender explanation remains scrollable")
		screen._process(2.0)
		check(screen.combat.elapsed==elapsed and screen.combat.running, "Confirmation leaves authoritative battle unchanged")
		check(screen.player_view.motion_paused and screen.rival_view.motion_paused and screen.combat_fx.motion_paused, "Both actors and FX pause while deciding")
		var visited := {}
		for i in range(12):
			_send_key(KEY_TAB,i>=6)
			await _settle()
			var focus: Control = canvas.gui_get_focus_owner()
			check(focus!=null and screen.modal_layer.is_ancestor_of(focus), "Surrender focus cannot escape to battle HUD")
			if focus==screen.modal_cancel: visited["cancel"] = true
			if focus==screen.modal_accept: visited["accept"] = true
		check(visited.size()==2, "Keyboard reaches both confirmation actions")
		if not story_mode: await _capture("surrender")
		screen.modal_accept.pressed.emit()
		check(screen.surrender_requests==(2 if story_mode else 1) and screen.surrendered_while_paused, "Accept dispatches once from paused state (safe callback spy)")
		screen.modal_cancel.pressed.emit()
		await _settle()
		check(not is_instance_valid(screen.modal_layer) and screen.active_match and screen.combat.running, "Cancel resumes same unfinished battle")
		check(not screen.player_view.motion_paused and not screen.rival_view.motion_paused and not screen.combat_fx.motion_paused, "Cancel resumes all presentation clocks")
	screen.story_mode = false
	screen.active_match = false
	check(Records.snapshot(template).player.name=="LUZ DE AYER", "Shared golden history source remains immutable")

func _check_shell() -> void:
	check(Rect2(Vector2.ZERO,screen.size).grow(1).encloses(screen.modal_panel.get_global_rect()), "Modal shell fits viewport")
	check(screen.modal_close_button.size.x>=48 and screen.modal_close_button.size.y>=48, "Close target remains 48px")
	check(screen.modal_panel.get_global_rect().grow(1).encloses(screen.modal_close_button.get_global_rect()), "Close fits panel")
	check(screen.modal_canvas.size.x>=140 and screen.modal_canvas.size.y>=48, "Document has usable text width/height")

func _files(path: String) -> Dictionary:
	var result := {}
	for extension: String in ["",".bak",".story.json",".story.json.bak",".identity.json",".identity.json.bak"]:
		var source := path+extension
		result[extension] = FileAccess.get_file_as_bytes(source) if FileAccess.file_exists(source) else null
	return result

func _send_key(code: Key, shift: bool=false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	event.shift_pressed = shift
	canvas.push_input(event)

func _settle() -> void:
	for i in range(3): await process_frame

func _text(node: Node) -> String:
	var result := str(node.text)+"\n" if node is Label or node is RichTextLabel else ""
	for child: Node in node.get_children(): result += _text(child)
	return result

func _find_previews(node: Node) -> Array:
	var result: Array = [node] if node is Preview else []
	for child: Node in node.get_children(): result.append_array(_find_previews(child))
	return result

func _capture(label: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name()=="headless": return
	if canvas.size not in [Vector2i(1360,880),Vector2i(390,844),Vector2i(844,390)]: return
	await create_timer(0.32,true,false,true).timeout
	await RenderingServer.frame_post_draw
	var destination := capture_dir.path_join("%s-%dx%d.png" % [label,canvas.size.x,canvas.size.y])
	check(canvas.get_texture().get_image().save_png(destination)==OK, "Captured native document state "+label)
