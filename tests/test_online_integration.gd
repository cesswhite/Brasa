extends SceneTree
## Main's real --online startup, with explicit disposable paths and an in-memory API.
const MainScript = preload("res://scripts/main.gd")
const UiFixtures = preload("res://tests/test_online_ui.gd")
const Progress = preload("res://scripts/progression.gd")
const Story = preload("res://scripts/story_progression.gd")
const PLAYER_ID := "10000000-0000-4000-8000-000000000001"
const RIVAL_ID := "20000000-0000-4000-8000-000000000002"

class StartupFixture:
	extends "res://scripts/main.gd"
	func _ready() -> void:
		online_api = UiFixtures.FixtureApi.new()
		online_api.signed_in = false
		add_child(online_api)
		sound_enabled = false
		super._ready()
		set_process(false)
	func _make_sounds() -> void: pass

class LeagueFixture:
	extends "res://scripts/main.gd"
	var fixture_path: String = ""
	func _ready() -> void:
		session_save_path = fixture_path
		sound_enabled = false
		set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		_build_theme()
		_build_interface()
		progression.load_save(fixture_path)
		_initialize_identity()
		_prepare_rival()
		_refresh_manager()
		_update_portraits()
		online_api = UiFixtures.FixtureApi.new()
		add_child(online_api)
		set_process(false)

var checks: int = 0
var failures: int = 0

func _init() -> void: _run.call_deferred()
func _check(ok: bool, detail: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ONLINE INTEGRATION: "+detail)

func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var path: String = ""
	for arg: String in args:
		if arg.begins_with("--save-path="): path = arg.trim_prefix("--save-path=")
	var directory: String = ProjectSettings.globalize_path("res://../../work/online/fixtures").simplify_path()
	# Reject unsafe invocation before Main's _ready can read any user:// path.
	if not args.has("--online") or not path.is_absolute_path() or path.simplify_path().get_base_dir() != directory or FileAccess.file_exists(path):
		push_error("Use --online --save-path=/absolute/project/work/online/fixtures/new-unique.json")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(directory)
	var canvas := SubViewport.new()
	canvas.size = Vector2i(1360,880)
	root.add_child(canvas)
	var startup := StartupFixture.new()
	canvas.add_child(startup)
	startup.size = Vector2(1360,880)
	startup._layout_interface(startup.size)
	await process_frame
	_check(startup.session_save_path == path,"real Main startup uses explicit fixture save path")
	_check(startup.progression.data.is_empty(),"online startup does not create local progression")
	_check(is_instance_valid(startup.online_layer) and startup.online_layer._login.visible,"--online opens independent login without a local fighter")
	_check(not is_instance_valid(startup.customization_layer) and not is_instance_valid(startup.creation_layer),"local creator does not remain over online startup")
	_check(not FileAccess.file_exists(path) and not FileAccess.file_exists(path+".identity.json") and not FileAccess.file_exists(path+".story.json"),"online startup does not persist any local gameplay file")
	startup.online_layer._close_panel()
	await process_frame
	_check(not is_instance_valid(startup.online_layer) and is_instance_valid(startup.customization_layer),"closing online on empty local profile returns to local creation")
	startup._open_online()
	await process_frame
	_check(is_instance_valid(startup.online_layer) and not is_instance_valid(startup.customization_layer),"online can reopen from the local creator")
	startup.queue_free()
	await process_frame

	var league_path: String = directory.path_join("league_%d.json" % Time.get_ticks_usec())
	var league = Progress.new()
	league.load_save(league_path)
	league.select_character("mugo","Centinela local")
	var story = Story.new()
	story.load_save(league_path+".story.json")
	story.select_character("mugo","Centinela de historia")
	var league_bytes: String = FileAccess.get_file_as_string(league_path)
	var story_bytes: String = FileAccess.get_file_as_string(league_path+".story.json")
	var screen := LeagueFixture.new()
	screen.fixture_path = league_path
	canvas.add_child(screen)
	screen.size = Vector2(1360,880)
	screen._layout_interface(screen.size)
	await process_frame
	var local_data: Dictionary = screen.progression.data.duplicate(true)
	var local_story: Dictionary = screen.story_progression.data.duplicate(true)
	var local_history: Array = screen.progression.history.duplicate(true)
	screen._show_menu()
	var entry: Button
	for button: Button in screen.menu_actions:
		if button.text == "Arena online": entry = button
	_check(is_instance_valid(entry) and not entry.disabled,"Main menu exposes Arena online outside combat")
	entry.pressed.emit()
	await process_frame
	_check(is_instance_valid(screen.online_layer) and not is_instance_valid(screen.modal_layer),"menu opens online without stacked local modal")
	_check(screen.online_layer._fighter.fighter_id == PLAYER_ID,"online panel uses separate server account fighter")
	var space := InputEventKey.new()
	space.keycode = KEY_SPACE
	space.pressed = true
	screen._unhandled_key_input(space)
	screen.fight_button.pressed.emit()
	screen._start_fight()
	_check(not screen.active_match and not screen.combat.running,"Space and local fight actions cannot start beneath online overlay")
	var api: Node = screen.online_api
	api.fail_next = true
	await screen.online_layer._challenge(RIVAL_ID)
	var pending: Dictionary = api.pending_operation.duplicate(true)
	_check(not pending.is_empty(),"unconfirmed online operation is retained")
	screen.online_layer._close_panel()
	await process_frame
	_check(not is_instance_valid(screen.online_layer) and api.is_authenticated(),"closing panel keeps existing in-memory account session")
	_check(api.pending_operation == pending,"closing panel preserves unconfirmed operation")
	screen._open_online()
	await process_frame
	_check(screen.online_api == api and screen.online_layer._fighter.fighter_id == PLAYER_ID,"reopening reuses session and server account")
	_check(api.pending_operation == pending and screen.online_layer._retry.visible,"reopening offers recovery of exact operation")
	await screen.online_layer._retry_pending()
	_check(api.writes == 1 and str(api.mutation_keys[0]) == str(api.mutation_keys[1]),"recovered request retains idempotency key and one confirmed mutation")
	_check(is_instance_valid(screen.online_layer._replay) and not screen.active_match,"online result uses its own recorded-event replay")
	screen.online_layer._replay._process(120.0)
	_check(not screen.online_layer._replay.playing,"server replay finishes without Main combat loop")
	screen.online_layer._close_replay()
	await screen.online_layer._allocate("attack")
	_check(screen.online_layer._fighter.progression.stat_points == 2,"online training updates only the server DTO")
	screen.online_layer._close_panel()
	await process_frame
	_check(screen.progression.data == local_data and screen.story_progression.data == local_story and screen.progression.history == local_history,"online battle and training never award local XP or append local history")
	_check(FileAccess.get_file_as_string(league_path) == league_bytes and FileAccess.get_file_as_string(league_path+".story.json") == story_bytes,"local Liga and Story files remain byte-identical")
	_check(not FileAccess.file_exists(league_path+".identity.json"),"online session never creates a local identity save")
	screen.active_match = true
	screen._show_menu()
	for button: Button in screen.menu_actions:
		if button.text == "Arena online": _check(button.disabled,"online menu entry disabled during local combat")
	screen._open_online()
	_check(not is_instance_valid(screen.online_layer),"direct online entry also rejects active local combat")
	screen.active_match = false
	screen.queue_free()
	canvas.queue_free()
	await process_frame
	print("ONLINE INTEGRATION: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
