extends SceneTree
## Responsive geometry and real UI state transitions. Never loads user:// saves.
## Godot --headless --path . --script tests/test_battle_layout.gd

const SIZES: Array[Vector2] = [
	Vector2(1360, 880), Vector2(1224, 792), Vector2(1920, 1080),
	Vector2(768, 1024), Vector2(390, 844), Vector2(430, 932), Vector2(844, 390),
]
const REQUIRED: Array[String] = ["viewport", "hud_player", "hud_rival", "actor_player", "actor_rival", "controls", "primary", "surrender", "feed", "signature"]
const EPSILON: float = 1.1

class LayoutFixture:
	extends "res://scripts/main.gd"
	var fixture_path: String = ""

	func _ready() -> void:
		# The production _ready loads the real save before considering any UI state.
		# Override only bootstrapping; every layout/action method below is production.
		session_save_path = fixture_path
		sound_enabled = false
		_build_theme()
		_build_interface()
		_make_sounds()
		progression.load_save(fixture_path)
		progression.select_character("mugo", "Guardián de Medianoche")
		progression.data.xp = 50
		_prepare_rival()
		_refresh_manager()
		_update_portraits()
		set_process(false)

var checks: int = 0
var failures: int = 0
var screen: LayoutFixture
var fixture_path: String = ""


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("BATTLE LAYOUT FAIL: " + message)


func _run() -> void:
	get_tree_watchdog()
	screen = LayoutFixture.new()
	if not screen.has_method("_layout_interface"):
		_check(false, "Main exposes responsive _layout_interface API")
		screen.free()
		quit(1)
		return
	var directory: String = ProjectSettings.globalize_path("res://../../work/immersive/layout_tests").simplify_path()
	DirAccess.make_dir_recursive_absolute(directory)
	fixture_path = directory.path_join("battle_%d.json" % Time.get_ticks_usec())
	screen.fixture_path = fixture_path
	screen.name = "BattleLayoutFixture"
	root.add_child(screen)
	await process_frame
	_check(screen.progression.last_save_ok, "Test profile is saved only in work fixture")
	_check(not is_instance_valid(screen.creation_layer), "Fixture does not open onboarding over battlefield")
	_check(screen.arena.position.is_equal_approx(Vector2.ZERO), "Battlefield begins at viewport origin")
	_check(screen.arena.scale.is_equal_approx(Vector2.ONE), "Battlefield is not stretched by Node2D scaling")
	var profile_before: Dictionary = screen.progression.data.duplicate(true)
	for view_size: Vector2 in SIZES:
		_place(view_size)
		_check_layout(view_size, "idle")
	_check(screen.progression.data == profile_before, "Idle resizing preserves progression")
	screen._start_fight()
	_check(screen.active_match and screen.combat.running, "Production primary action starts automatic combat")
	var snapshot_before: Dictionary = screen.combat.snapshot()
	profile_before = screen.progression.data.duplicate(true)
	for view_size: Vector2 in SIZES:
		_place(view_size)
		_check_layout(view_size, "active")
	_check(screen.combat.snapshot() == snapshot_before, "Active resizing never advances or resets combat")
	_check(screen.progression.data == profile_before, "Active resizing never alters stats or awards XP")
	# A start tween must not later restore coordinates from the previous desktop.
	_place(Vector2(390, 844))
	await create_timer(1.05, true, false, true).timeout
	_check_actor_locations(Vector2(390, 844), "after entry tween")
	await _check_paused_modal(Vector2(390, 844))
	await _check_signature_replacement()
	var matches_before: int = int(screen.progression.data.matches)
	var arena_before: int = screen.arena.get_instance_id()
	var player_before: int = screen.player_view.get_instance_id()
	var events: Array = screen.combat.advance(60.0)
	# Keep a fresh banner alive as the normal terminal event reaches production UI.
	screen._show_signature({"side": "player", "name": "Firma decisiva"})
	_check(is_instance_valid(screen.signature_banner), "Normal finish starts with a visible Signature")
	screen._dispatch_events(events)
	var deadline: int = Time.get_ticks_msec() + 3000
	while screen.active_match and Time.get_ticks_msec() < deadline:
		await process_frame
	await process_frame
	_check(not screen.active_match and not screen.combat.running, "Normal result completes without replacing the battle scene")
	_check(screen.result_panel.visible and not is_instance_valid(screen.signature_banner), "Normal result removes the Signature banner immediately")
	_check(not screen.feed_label.visible, "Result keeps recent-event feed hidden after closing its Signature")
	_check(int(screen.progression.data.matches) == matches_before + 1, "Result awards exactly one match")
	_check(screen.arena.get_instance_id() == arena_before and screen.player_view.get_instance_id() == player_before, "Results reuse the arena and fighter nodes")
	var final_snapshot: Dictionary = screen.combat.snapshot()
	profile_before = screen.progression.data.duplicate(true)
	for view_size: Vector2 in SIZES:
		_place(view_size)
		_check_layout(view_size, "result")
	_check(screen.combat.snapshot() == final_snapshot, "Result resizing preserves final health and winner")
	_check(screen.progression.data == profile_before, "Result resizing cannot grant a duplicate reward")
	await _check_surrender_layout()
	_finish()


func get_tree_watchdog() -> void:
	create_timer(25.0, true, false, true).timeout.connect(func() -> void:
		push_error("BATTLE LAYOUT FAIL: asynchronous test timeout")
		quit(1)
	)


func _place(view_size: Vector2) -> void:
	root.size = Vector2i(view_size)
	screen.size = view_size
	screen.call("_layout_interface", view_size)


func _within(inner: Rect2, outer: Rect2) -> bool:
	return outer.grow(EPSILON).encloses(inner)


func _rect_matches(a: Rect2, b: Rect2) -> bool:
	return a.position.distance_to(b.position) < EPSILON and a.size.distance_to(b.size) < EPSILON


func _check_layout(view_size: Vector2, phase: String) -> void:
	var prefix: String = "%dx%d %s: " % [int(view_size.x), int(view_size.y), phase]
	var layout: Dictionary = screen.get("layout_rects")
	var viewport: Rect2 = Rect2(Vector2.ZERO, view_size)
	_check(layout.has_all(REQUIRED), prefix + "all layout diagnostic regions are present")
	if not layout.has_all(REQUIRED):
		return
	_check(_rect_matches(layout.viewport, viewport), prefix + "layout uses requested native viewport size")
	if screen.arena.has_method("get_backdrop_rect"):
		var backdrop: Rect2 = screen.arena.call("get_backdrop_rect")
		_check(_within(viewport, backdrop), prefix + "illustrated battlefield covers the entire viewport")
	for key: String in REQUIRED:
		var region: Rect2 = layout[key]
		_check(region.size.x > 0 and region.size.y > 0, prefix + key + " has a usable region")
		_check(_within(region, viewport), prefix + key + " remains inside viewport")
	_check(not Rect2(layout.hud_player).intersects(layout.hud_rival), prefix + "fighter HUDs stay separate")
	_check(not Rect2(layout.primary).intersects(layout.surrender), prefix + "surrender never overlaps primary")
	_check(_within(screen.fight_button.get_global_rect(), viewport), prefix + "actual primary respects bounds after font minimum sizes")
	_check(_rect_matches(layout.primary, screen.fight_button.get_global_rect()), prefix + "primary diagnostic matches actual Control geometry")
	_check(screen.fight_button.size.y >= 48.0 and screen.fight_button.size.x >= 120.0, prefix + "primary is a comfortable tap target")
	_check(screen.fight_button.focus_mode != Control.FOCUS_NONE, prefix + "primary remains keyboard accessible")
	if phase != "result": _check(_within(layout.primary, layout.controls), prefix + "primary belongs to bottom interaction region")
	if phase != "result": _check(Rect2(layout.primary).position.y > view_size.y * 0.60, prefix + "primary stays near bottom reach")
	_check(not Rect2(layout.feed).intersects(layout.primary), prefix + "compact log does not cover primary")
	if phase != "result": _check(not Rect2(layout.signature).intersects(layout.primary), prefix + "Signature feedback does not cover primary")
	for side: String in ["player", "rival"]:
		var actor_rect: Rect2 = layout["actor_" + side]
		var hud_rect: Rect2 = layout["hud_" + side]
		_check(not actor_rect.intersects(hud_rect), prefix + side + " sprite does not cover health HUD")
		if phase != "result": _check(not actor_rect.intersects(layout.primary), prefix + side + " sprite remains above controls")
		_check(not actor_rect.intersects(layout.feed), prefix + side + " sprite remains clear of recent-event feed")
		_check(not actor_rect.intersects(layout.signature), prefix + side + " Signature row stays clear of the fighter")
		var hp: ProgressBar = screen.player_bar if side == "player" else screen.rival_bar
		var hp_text: Label = screen.player_hp_label if side == "player" else screen.rival_hp_label
		var name_label: Label = screen.player_name_label if side == "player" else screen.rival_name_label
		var level: Label = screen.player_level_label if side == "player" else screen.rival_level_label
		var status: Label = screen.player_status_label if side == "player" else screen.rival_status_label
		_check(hp.is_visible_in_tree() and hp_text.is_visible_in_tree(), prefix + side + " HP stays visible")
		_check(level.is_visible_in_tree() and not level.text.is_empty(), prefix + side + " level stays visible")
		for node: Control in [hp, hp_text, name_label, level]:
			_check(_within(node.get_global_rect(), hud_rect), prefix + side + " HUD child %s fits %s (actual %s)" % [node.get_class(), str(hud_rect), str(node.get_global_rect())])
		if status.is_visible_in_tree():
			_check(_within(status.get_global_rect(), viewport), prefix + side + " local statuses fit viewport")
			_check(not status.get_global_rect().intersects(layout.primary), prefix + side + " statuses stay away from primary")
			_check(not status.get_global_rect().intersects(hud_rect), prefix + side + " statuses do not cover name, level or HP")
		if view_size.y <= 480:
			_check(actor_rect.size.y >= 90, prefix + side + " landscape fighter remains legible")
		elif view_size.x <= 480:
			# The old 166-unit diagnostic rectangle predates normalized painted
			# sprites. Check their canonical standing art at the shared camera scale;
			# a KO must not count as a legibility failure because it lies horizontally.
			var actor: Node2D = screen.player_view if side=="player" else screen.rival_view
			var geometry: Dictionary = actor.get_sprite_geometry()
			var standing_height: float = float(geometry.frames[0].bounds.size.y)*float(geometry.scale)*actor.scale.y
			_check(standing_height >= 100, prefix + side + " painted phone fighter remains legible with separate lanes")
		else:
			_check(actor_rect.size.y >= 180, prefix + side + " large-screen fighter uses the expanded arena")
	_check(is_equal_approx(screen.player_bar.size.x, screen.rival_bar.size.x), prefix + "health bars are directly comparable")
	_check_actor_locations(view_size, phase)
	_check_visible_controls(view_size, phase)
	if phase == "active":
		_check(screen.fight_button.disabled and "autom" in screen.fight_button.text.to_lower(), prefix + "automatic combat has explicit disabled primary label")
		_check(screen.surrender_button.is_visible_in_tree() and not screen.surrender_button.disabled, prefix + "surrender stays accessible during combat")
		_check(_within(screen.surrender_button.get_global_rect(), viewport), prefix + "actual surrender control fits viewport")
		_check(screen.surrender_button.size.y >= (44 if view_size.y <= 480 else 48), prefix + "surrender has a usable touch target")
	elif phase == "idle":
		_check(not screen.fight_button.disabled, prefix + "idle primary is ready to start")
		_check(not screen.surrender_button.is_visible_in_tree(), prefix + "surrender is absent before combat")
	else:
		if view_size.x<640:
			_check(screen.fight_button.get_rect().end.y<=screen.player_view.position.y-166*screen.player_view.scale.y-8,prefix+"result action clears phone fighter footprint")
		else:
			_check(is_equal_approx((screen.result_panel.position.y+screen.fight_button.get_rect().end.y)*0.5,view_size.y*0.5),prefix+"result and action share viewport center")
		_check(screen.result_panel.is_visible_in_tree(), prefix + "result overlays the same battlefield")
		_check(_within(screen.result_panel.get_global_rect(), viewport), prefix + "result panel fits viewport")
		_check(not screen.result_panel.get_global_rect().intersects(layout.primary), prefix + "result does not hide replay")
		_check("volver" in screen.fight_button.text.to_lower(), prefix + "result presents replay as primary")
		_check(not screen.surrender_button.is_visible_in_tree(), prefix + "surrender disappears after result")
		for action: Button in [screen.summary_button, screen.roster_button]:
			_check(action.is_visible_in_tree() and not action.disabled, prefix + action.text + " remains available after the result")
			_check(action.mouse_filter != Control.MOUSE_FILTER_IGNORE and action.focus_mode != Control.FOCUS_NONE, prefix + action.text + " remains usable by pointer and keyboard")
			_check(action.size.y >= (44 if view_size.y <= 480 else 48), prefix + action.text + " remains a comfortable touch target")


func _check_visible_controls(view_size: Vector2, phase: String) -> void:
	var prefix: String = "%dx%d %s: " % [int(view_size.x), int(view_size.y), phase]
	var viewport: Rect2 = Rect2(Vector2.ZERO, view_size)
	var controls: Array[Dictionary] = [
		{"id": "primary", "button": screen.fight_button},
		{"id": "training", "button": screen.training_button},
		{"id": "roster", "button": screen.roster_button},
		{"id": "speed", "button": screen.speed_button},
		{"id": "log", "button": screen.log_button},
		{"id": "surrender", "button": screen.surrender_button},
		{"id": "summary", "button": screen.summary_button},
		{"id": "menu", "button": screen.menu_button},
	]
	for left: int in range(controls.size()):
		var first: Button = controls[left].button
		if not first.is_visible_in_tree():
			continue
		var first_rect: Rect2 = first.get_global_rect()
		_check(_within(first_rect, viewport), prefix + controls[left].id + " actual visible button fits viewport")
		for right: int in range(left + 1, controls.size()):
			var second: Button = controls[right].button
			if not second.is_visible_in_tree():
				continue
			var second_rect: Rect2 = second.get_global_rect()
			_check(not first_rect.intersects(second_rect), prefix + "%s %s is separate from %s %s" % [controls[left].id, str(first_rect), controls[right].id, str(second_rect)])


func _check_actor_locations(view_size: Vector2, phase: String) -> void:
	var layout: Dictionary = screen.get("layout_rects")
	var viewport: Rect2 = Rect2(Vector2.ZERO, view_size)
	_check(screen.player_view.global_position.x < screen.rival_view.global_position.x, phase + ": fighters retain their sides")
	for side: String in ["player", "rival"]:
		var actor: Node2D = screen.player_view if side == "player" else screen.rival_view
		var region: Rect2 = layout["actor_" + side]
		_check(is_equal_approx(actor.scale.x, actor.scale.y), phase + ": " + side + " art keeps its proportions")
		_check(viewport.has_point(actor.global_position), phase + ": " + side + " ground anchor remains in viewport")
		_check(actor.global_position.x >= region.position.x - EPSILON and actor.global_position.x <= region.end.x + EPSILON, phase + ": " + side + " actual anchor agrees with layout after resize")
		_check(absf(actor.global_position.y - region.end.y) < EPSILON, phase + ": " + side + " feet match the layout ground line")


func _check_paused_modal(view_size: Vector2) -> void:
	_place(view_size)
	screen._show_log()
	_check(is_instance_valid(screen.modal_layer), "Recent-event feed opens a secondary log on demand")
	if not is_instance_valid(screen.modal_layer):
		return
	var previous: Dictionary = screen.combat.snapshot()
	screen._process(1.0)
	_check(screen.combat.snapshot() == previous, "Secondary log pauses authoritative combat")
	_check(_within(screen.modal_body.get_global_rect(), Rect2(Vector2.ZERO, view_size)), "Phone log body fits the viewport")
	screen._close_modal()
	await process_frame
	_check(screen.active_match and screen.combat.running, "Closing secondary log preserves the ongoing battle")


func _check_surrender_layout() -> void:
	_place(Vector2(390, 844))
	screen._start_fight()
	screen._show_signature({"side": "rival", "name": "Firma antes de rendirse"})
	screen._confirm_surrender()
	_check(is_instance_valid(screen.modal_layer), "Phone surrender requires confirmation")
	if not is_instance_valid(screen.modal_layer):
		return
	var snapshot_before: Dictionary = screen.combat.snapshot()
	screen._process(2.0)
	_check(screen.combat.snapshot() == snapshot_before, "Surrender confirmation pauses combat")
	for button: Button in _buttons_under(screen.modal_layer):
		if button.is_visible_in_tree():
			_check(_within(button.get_global_rect(), Rect2(Vector2.ZERO, Vector2(390, 844))), "Surrender confirmation button stays onscreen: %s %s" % [button.text, str(button.get_global_rect())])
			_check(button.size.y >= 48, "Surrender confirmation is touch accessible: " + button.text)
	screen._close_modal()
	await process_frame
	_check(screen.active_match and screen.combat.running, "Cancelling surrender retains combat state")
	screen._confirm_surrender()
	screen._accept_surrender()
	_check(not screen.active_match and not screen.combat.running, "Confirmed surrender immediately reaches result state")
	_check(not is_instance_valid(screen.signature_banner), "Surrender result also removes an active Signature")
	_place(Vector2(390, 844))
	_check_layout(Vector2(390, 844), "result")
	_check("REND" in screen.result_title.text.to_upper(), "Surrender result is distinguished from defeat")


func _check_signature_replacement() -> void:
	var snapshot_before: Dictionary = screen.combat.snapshot()
	var profile_before: Dictionary = screen.progression.data.duplicate(true)
	screen._show_signature({"side": "player", "name": "Firma A"})
	var first: Label = screen.signature_banner
	_check(is_instance_valid(first) and not screen.feed_label.visible, "Signature A hides the recent-event feed")
	await create_timer(0.8, true, false, true).timeout
	screen._show_signature({"side": "rival", "name": "Firma B"})
	var second: Label = screen.signature_banner
	_check(second != first and not screen.feed_label.visible, "Signature B replaces A without exposing the feed")
	await process_frame
	_check(not is_instance_valid(first), "Replaced Signature A is removed from the scene")
	# Cross A's original timeout while B still has over a second remaining.
	await create_timer(1.5, true, false, true).timeout
	_check(is_instance_valid(second) and screen.signature_banner == second, "Signature B remains active after A's original timeout")
	_check(not screen.feed_label.visible, "Cancelled Signature A cannot show the feed over Signature B")
	await create_timer(1.2, true, false, true).timeout
	await process_frame
	_check(not is_instance_valid(screen.signature_banner) and screen.feed_label.visible, "Feed returns only after the current Signature finishes")
	_check(screen.combat.snapshot() == snapshot_before, "Signature replacement does not advance authoritative combat")
	_check(screen.progression.data == profile_before, "Signature replacement does not mutate progression")


func _buttons_under(node: Node) -> Array[Button]:
	var buttons: Array[Button] = []
	for child: Node in node.get_children():
		if child is Button:
			buttons.append(child)
		buttons.append_array(_buttons_under(child))
	return buttons


func _finish() -> void:
	Engine.time_scale = 1.0
	screen.free()
	for suffix: String in ["", ".bak", ".tmp", ".bak.tmp"]:
		var path: String = fixture_path + suffix
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	print("BATTLE LAYOUT: %d checks, %d failures across %d sizes and idle/active/result states" % [checks, failures, SIZES.size()])
	quit(0 if failures == 0 else 1)
