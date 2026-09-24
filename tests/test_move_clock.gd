extends SceneTree
## Observe Main and FighterView after both real process callbacks, including the
## cold startup frame. The only save is a unique fixture under work/campaign100.
const Fixtures = preload("res://tests/test_story_chapter_integration.gd")
const Moves = preload("res://scripts/move_catalog.gd")

class Observer:
	extends Node
	signal sampled(delta: float)
	func _process(delta: float) -> void: sampled.emit(delta)

var checks := 0
var failures := 0
var screen
var observer: Observer
var canvas: SubViewport
var sampled_phases: Dictionary = {}
var fixture_path := ""
var initial_bytes := ""

func _init() -> void: _run.call_deferred()

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("MOVE CLOCK: " + description)

func _run() -> void:
	Engine.max_fps = 60
	Engine.time_scale = 1.0
	create_timer(12.0,true,false,true).timeout.connect(func(): push_error("MOVE CLOCK timed out"); quit(1))
	var directory: String = ProjectSettings.globalize_path("res://../../work/campaign100/integration").simplify_path()
	DirAccess.make_dir_recursive_absolute(directory)
	fixture_path = directory.path_join("move_clock_%d.json" % Time.get_ticks_usec())
	canvas = SubViewport.new()
	canvas.size = Vector2i(1360,880)
	root.add_child(canvas)
	screen = Fixtures.Fixture.new()
	screen.fixture_path = fixture_path
	canvas.add_child(screen)
	screen._layout_interface(Vector2(1360,880))
	initial_bytes = FileAccess.get_file_as_string(fixture_path)
	check(screen.progression.last_save_ok and not initial_bytes.is_empty(),"Fixture is explicitly isolated and valid")
	check(screen.player_view.process_priority < screen.process_priority,"Visual clock advances before Main aligns the current simulation frame")
	screen._start_fight()
	var player: Dictionary = screen.progression.active_combatant()
	var heavy: Dictionary = Moves.moves_for("mugo")[2]
	heavy.cooldown = 0
	player.moves = [heavy]
	player.combat_stats.speed = 36.0
	screen.combat.start(player,screen.rival,761,{"opening_time":0.05,"disable_signatures":true})
	# No incoming reactions obscure the clock being measured; rules and real
	# process ordering still run normally for the scheduled heavy attack.
	screen.combat._fighters.rival.next_action = 30.0
	observer = Observer.new()
	observer.process_priority = 1000
	canvas.add_child(observer)
	screen.set_process(true)
	await _frames(10,"startup ×1")
	await _wait_windup()
	var elapsed_before: float = screen.combat.elapsed
	var visual_before: float = screen.player_view._action_time
	var rival_before: float = screen.rival_view._action_time
	screen._open_document("Clock test","Fixture only","A modal pauses the simulation and both illustrated clocks.")
	check(screen.player_view.motion_paused and screen.rival_view.motion_paused,"Opening modal pauses both actors immediately")
	for index in range(5):
		await observer.sampled
		check(is_equal_approx(screen.combat.elapsed,elapsed_before),"Modal keeps engine time unchanged")
		check(is_equal_approx(screen.player_view._action_time,visual_before) and is_equal_approx(screen.rival_view._action_time,rival_before),"Modal keeps both visual clocks unchanged on the first and later frames")
	screen._close_modal()
	check(not screen.player_view.motion_paused and not screen.rival_view.motion_paused,"Closing modal releases both clocks immediately")
	await _frames(8,"resume ×1")
	check(screen.combat.elapsed>elapsed_before,"Closing modal resumes combat without skipping initiative")
	screen._toggle_speed()
	check(screen.quick_mode and Engine.time_scale==2.0,"Real speed control uses ×2 reproduction")
	await _frames(50,"×2")
	check(sampled_phases.has("windup") and sampled_phases.has("recovery"),"Real frames include anticipation and recovery")
	check(int(screen.combat._metrics.player.attacks)>=2,"Several scheduled contacts were observed")
	check(FileAccess.get_file_as_string(fixture_path)==initial_bytes,"Nonterminal clock test never modifies progression or the player save")
	screen.set_process(false)
	screen.active_match = false
	Engine.time_scale = 1.0
	canvas.queue_free()
	await process_frame
	print("MOVE CLOCK: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)

func _frames(count: int, label: String) -> void:
	for index in range(count):
		await observer.sampled
		_check_clock(label)

func _check_clock(label: String) -> void:
	var fighter: Dictionary = screen.combat._fighters.player
	var phase: String = str(fighter.move_phase)
	if phase not in ["windup","recovery"]: return
	sampled_phases[phase] = true
	var expected: float = screen.combat.elapsed-float(fighter.move_started_at)
	check(screen.player_view._mode=="move",label+": pending action has the matching visual mode")
	check(absf(screen.player_view._action_time-expected)<0.00001,label+": no extra-frame lead or lag after both process callbacks")
	if phase=="windup":
		check(screen.player_view._action_time<float(fighter.pending_move.impact_delay)+0.00001,label+": contact pose does not skip authoritative anticipation")

func _wait_windup() -> void:
	for index in range(120):
		if str(screen.combat._fighters.player.move_phase)=="windup": return
		await observer.sampled
	check(false,"Reach a real anticipation window before opening modal")
