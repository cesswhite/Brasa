extends SceneTree
## Regression: a live modal may outlast Main's terminal presentation delay.
const Base = preload("res://tests/test_identity_integration.gd")
const Progress = preload("res://scripts/progression.gd")
const Story = preload("res://scripts/story_progression.gd")
const Catalog = preload("res://scripts/story_catalog.gd")
var checks := 0
var failures := 0

func _init() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error("MAIN AUDIO PAUSE: "+message)

func _run() -> void:
	create_timer(30,true,false,true).timeout.connect(func(): push_error("MAIN AUDIO PAUSE timeout"); quit(1))
	var folder:=ProjectSettings.globalize_path("res://../../work/audio/main-integration/fixtures").simplify_path()
	DirAccess.make_dir_recursive_absolute(folder)
	var path:=folder.path_join("terminal-pause-%d.json" % Time.get_ticks_usec())
	var progression=Progress.new()
	progression.load_save(path)
	check(progression.select_character("mugo"),"Create isolated fixture")
	var story=Story.new()
	story.load_save(path+".story.json")
	story.select_character("mugo")
	var story_bytes:=FileAccess.get_file_as_bytes(path+".story.json")
	var screen=Base.Fixture.new()
	screen.fixture_path=path
	root.add_child(screen)
	screen.size=Vector2(1360,880)
	screen._layout_interface(screen.size)
	screen.sound_enabled=true
	screen._make_sounds()
	screen.rival=Catalog.opponent(7,1)
	screen.rival["opponent_id"]="npc_audio_terminal_ascua"
	screen._start_fight()
	screen.combat.start(screen._player_combatant(),screen.rival,620017,{"initial_hp":{"player":1.0},"opening_time":0.2,"disable_signatures":true,"battle_id":"audio-terminal-pause"})
	screen._configure_combat_audio(screen._player_combatant(),screen.rival)
	var events: Array[Dictionary]=screen.combat.advance(120.0)
	screen._dispatch_events(events)
	check(screen.active_match and screen.finishing,"Terminal callback entered delayed presentation")
	screen._open_document("Pausa al terminar","Fixture","El resultado debe continuar al cerrar.")
	check(is_instance_valid(screen.modal_layer) and bool(screen.audio_director.debug_state().paused),"Modal pauses actual director during terminal delay")
	while screen.active_match: await process_frame
	var paused_state: Dictionary=screen.audio_director.debug_state()
	check(bool(paused_state.terminal) and bool(paused_state.paused),"Director is terminal and paused after active_match clears")
	check(not paused_state.pending.is_empty(),"KO/result tail is pending while paused")
	var saved:=FileAccess.get_file_as_bytes(path)
	var history:=var_to_bytes(screen.progression.history)
	screen._close_modal()
	check(not bool(screen.audio_director.debug_state().paused),"Closing late modal resumes its own local audio session")
	await create_timer(1.0,true,false,true).timeout
	var resumed: Dictionary=screen.audio_director.debug_state()
	check(resumed.pending.is_empty(),"Terminal audio queue drains after closing")
	var result_count:=0
	for event: Dictionary in resumed.history:
		if str(event.id) in ["victory","defeat"]: result_count+=1
	check(result_count==1,"One result cue is delivered, without repeating combat")
	check(FileAccess.get_file_as_bytes(path)==saved and var_to_bytes(screen.progression.history)==history,"Resuming audio cannot change XP or history")
	# A foreign Replay can replace the director context before an old modal closes.
	screen._open_document("Modal anterior","Fixture","No debe reanudar otra sesión.")
	screen.audio_director.configure_context("arena_faroles",{}, {"session_id":"replay:foreign:1","mode":"replay","result_audio":false})
	screen.audio_director.set_paused(true)
	screen._close_modal()
	check(bool(screen.audio_director.debug_state().paused),"Closing local modal leaves foreign Replay paused")
	check(screen.audio_director.debug_state().session=="replay:foreign:1","Foreign session ownership remains unchanged")
	check(FileAccess.get_file_as_bytes(path+".story.json")==story_bytes,"Separate Story fixture stays byte-identical")
	screen.free()
	print("MAIN AUDIO PAUSE: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
