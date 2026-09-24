extends SceneTree
## Main controls, real adapter and engine. All persistence stays in unique fixtures.
const Base = preload("res://tests/test_story_chapter_integration.gd")
const Story = preload("res://scripts/story_progression.gd")
const Moves = preload("res://scripts/move_catalog.gd")
const EngineScript = preload("res://scripts/combat_engine.gd")
var checks := 0
var failures := 0
var screen
var canvas: SubViewport
var capture_dir := ""
var fixture_path := ""

func _init() -> void: _run.call_deferred()
func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CAMPAIGN100 UI: " + message)

func _run() -> void:
	create_timer(110,true,false,true).timeout.connect(func(): push_error("100 integration timeout"); quit(1))
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): capture_dir = arg.trim_prefix("--capture-dir=")
	var directory := ProjectSettings.globalize_path("res://../../work/campaign100/integration").simplify_path()
	DirAccess.make_dir_recursive_absolute(directory)
	fixture_path = directory.path_join("main_%d.json" % Time.get_ticks_usec())
	canvas = SubViewport.new()
	canvas.size = Vector2i(1360, 880)
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	screen = Base.Fixture.new()
	screen.fixture_path = fixture_path
	canvas.add_child(screen)
	screen.size = Vector2(1360, 880)
	screen._layout_interface(Vector2(1360, 880))
	screen.story_button.pressed.emit()
	screen.story_layer.character_chosen.emit("sira")
	screen._close_story_panel()
	var league_bytes := FileAccess.get_file_as_string(fixture_path)
	var engine = EngineScript.new()
	for story_level in range(1, 100):
		if screen.progression.is_complete(): _check(screen.progression.start_next_chapter(), "explicit chapter transition succeeds")
		_check(screen.progression.global_level() == story_level, "global route advances without skipping %d" % story_level)
		engine.start(screen.progression.active_combatant(), screen.progression.make_rival(), 7300 + story_level, {"initial_hp":{"rival":1.0},"initial_statuses":{"rival":[{"type":"stun","magnitude":1.0,"duration":1}]},"opening_time":0.01,"force_signature":"player","signature_turn":1,"battle_id":"main100_%d_%d" % [Time.get_ticks_usec(), story_level]})
		engine.advance(60.0)
		_check(engine.summary().get("winner", "") == "player", "isolated forced encounter reaches victory")
		var reward: Dictionary = screen.progression.reward_match(engine.summary())
		_check(bool(reward.get("accepted", false)) and screen.progression.last_save_ok, "real summary advances and saves")
		if story_level in [16, 50, 90]:
			var reloaded = Story.new()
			reloaded.load_save(fixture_path + ".story.json")
			_check(not reloaded.save_blocked and reloaded.global_level() == screen.progression.global_level(), "milestone survives actual disk reload")
	_check(screen.progression.global_level() == 100, "final boss is Story100")
	screen._reset_mode_view()
	screen._show_story_panel("moves")
	_check(screen.story_layer.size == screen.size, "Story overlay fills the actual Main canvas")
	var first: Dictionary = Moves.moves_for("sira")[0]
	var tokens_before: int = int(screen.progression.data.move_points)
	screen.story_layer.upgrade_move_requested.emit(str(first.id))
	_check(int(screen.progression.data.move_upgrades.get(str(first.id), 0)) == 1 and int(screen.progression.data.move_points) == tokens_before-1, "move upgrade signal spends exactly one token")
	var perks: Array = screen.progression.available_perks()
	screen.story_layer.perk_chosen.emit(str(perks[0].id))
	_check(screen.progression.data.perks.size() == 1 and int(screen.progression.data.perk_points) == 2, "perk signal chooses one of six")
	screen.story_layer.show_tab("route")
	await _capture("nivel100-ruta")
	screen._start_story_battle()
	_check(screen.active_match and screen.round_label.text.contains("100 / 100"), "main shows global final encounter")
	_check(screen.rival.name.contains("Véspera"), "intentional final boss identity reaches HUD")
	screen.combat.start(screen.progression.active_combatant(), screen.rival, 91815, {"opening_time":0.01,"disable_signatures":true})
	var events: Array = screen.combat.advance(0.2)
	screen._dispatch_events(events)
	screen._refresh_combat_state()
	screen.player_view.set_process(false)
	screen.rival_view.set_process(false)
	_check(screen.player_view._mode == "move" or screen.rival_view._mode == "move", "move_started reaches illustrated movement")
	await _capture("nivel100-batalla")
	screen._show_menu()
	screen._process(0.15)
	_check(screen.player_view.motion_paused and screen.rival_view.motion_paused, "menu pauses both fighters alongside engine")
	screen._close_modal()
	screen._toggle_reduced_motion()
	_check(screen.player_view.reduced_motion and screen.arena.reduced_motion, "reduced motion reaches actors and arena")
	var preferences := ConfigFile.new()
	_check(preferences.load(fixture_path + ".prefs.cfg") == OK and preferences.get_value("display", "reduced_motion", false), "motion preference persists only to fixture path")
	screen._toggle_reduced_motion()
	await _finish()
	_check(bool(screen.progression.data.campaign_completed) and not screen.progression.can_start_next_chapter(), "final boss completes100 without undefined next chapter")
	screen._primary_action()
	await _capture("nivel100-legado")
	var total_xp: int = int(screen.progression.data.total_xp)
	var stat_points: int = int(screen.progression.data.points)
	var move_points: int = int(screen.progression.data.move_points)
	screen.story_layer.replay_requested.emit(7)
	_check(screen.active_match and int(screen.rival.story_level) == 7, "cleared encounter replays from final legacy")
	_check(screen.round_label.text.contains("7 / 100"), "replay HUD labels actual opponent global stage")
	await _finish()
	_check(bool(screen.last_reward.get("replay",false)) and int(screen.last_reward.get("xp_gained",-1)) == 0, "replay is clearly recorded with zeroXP")
	_check(int(screen.progression.data.total_xp) == total_xp and int(screen.progression.data.points) == stat_points and int(screen.progression.data.move_points) == move_points, "replay cannot farm progression or duplicate milestones")
	_check(bool(screen.progression.data.campaign_completed), "replay retains completed campaign")
	var restored = Story.new()
	restored.load_save(fixture_path + ".story.json")
	_check(not restored.save_blocked and bool(restored.data.get("campaign_completed", false)), "100completion and replay counters survive reload")
	_check(restored.data.perks.size() == 1 and int(restored.data.move_upgrades.get(str(first.id),0)) == 1, "selected perk and tier survive reload")
	var victory_legacy: Dictionary = screen.progression.completion_summary().duplicate(true)
	screen._show_story_panel("upgrades")
	screen.story_layer._respec.pressed.emit()
	_check(is_instance_valid(screen.story_layer._confirmation), "redistribution first presents a concrete confirmation")
	screen.story_layer._confirmation_cancel.pressed.emit()
	_check(screen.progression.data.perks.size() == 1, "cancel leaves the actual build intact")
	screen.story_layer._respec.pressed.emit()
	screen.story_layer._confirmation_accept.pressed.emit()
	_check(screen.progression.data.perks.is_empty() and screen.progression.data.move_upgrades.is_empty(), "confirmed redistribution is wired to real progression")
	_check(int(screen.progression.data.total_xp) == total_xp and bool(screen.progression.data.campaign_completed), "redistribution preserves completed Story and XP")
	_check(Story._equivalent(victory_legacy, screen.progression.completion_summary()), "redistribution preserves the final victory build in Legacy")
	var retrained = Story.new()
	retrained.load_save(fixture_path + ".story.json")
	_check(not retrained.save_blocked and retrained.data.perks.is_empty() and retrained.data.chapter_records.size() == 10, "redistributed build reloads with ten archived legacies")
	_check(FileAccess.get_file_as_string(fixture_path) == league_bytes, "Story100 leaves League byte-identical")
	print("CAMPAIGN100 INTEGRATION: %d checks, %d failures; fixture %s" % [checks, failures, fixture_path])
	screen.queue_free()
	canvas.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

func _finish() -> void:
	screen.combat.start(screen.progression.active_combatant(), screen.rival, 7373, {"initial_hp":{"rival":1.0},"initial_statuses":{"rival":[{"type":"stun","magnitude":1.0,"duration":1}]},"opening_time":0.01,"force_signature":"player","signature_turn":1,"battle_id":"main100_finish_%d" % Time.get_ticks_usec()})
	var events: Array = screen.combat.advance(60.0)
	for event: Dictionary in events:
		if event.type == "finished": screen._dispatch_events([event])
	await create_timer(0.36).timeout
	_check(not screen.active_match and screen.result_panel.visible, "main presents terminal reward once")

func _capture(label: String) -> void:
	if capture_dir.is_empty(): return
	DirAccess.make_dir_recursive_absolute(capture_dir)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	_check(canvas.get_texture().get_image().save_png(capture_dir.path_join(label + ".png")) == OK, "capture " + label)
