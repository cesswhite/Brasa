extends SceneTree
## Production UI + persistence adapter, isolated from both real save files.
const Story = preload("res://scripts/story_progression.gd")
const StoryData = preload("res://scripts/story_catalog.gd")
const SIZES = [Vector2(1360,880),Vector2(1224,792),Vector2(1920,1080),Vector2(768,1024),Vector2(390,844),Vector2(430,932),Vector2(844,390)]

class Fixture:
	extends "res://scripts/main.gd"
	var fixture_path: String
	func _ready() -> void:
		session_save_path = fixture_path
		sound_enabled = false
		_build_theme()
		_build_interface()
		progression.load_save(fixture_path)
		progression.select_character("mugo")
		_prepare_rival()
		_refresh_manager()
		_update_portraits()
		set_process(false)

var screen: Fixture
var checks := 0
var failures := 0
var path: String

func _init() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("STORY UI: "+message)

func _run() -> void:
	create_timer(40,true,false,true).timeout.connect(func(): push_error("Story integration timeout"); quit(1))
	var directory := ProjectSettings.globalize_path("res://../../work/story/integration").simplify_path()
	DirAccess.make_dir_recursive_absolute(directory)
	path = directory.path_join("ui_%d.json" % Time.get_ticks_usec())
	screen = Fixture.new()
	screen.fixture_path = path
	root.add_child(screen)
	await process_frame
	var league_bytes := FileAccess.get_file_as_string(path)
	var league_data: Dictionary = screen.progression.data.duplicate(true)
	screen.story_button.pressed.emit()
	check(screen.story_mode and is_instance_valid(screen.story_layer),"Historia opens character selection")
	check(screen.progression.data.is_empty(),"League profile is not imported into Story")
	screen.story_layer.character_chosen.emit("mugo")
	check(screen.progression.data.level == 1 and screen.progression.data.points == 3,"Story starts balanced level one with three points")
	var stats_before: Dictionary = screen._current_stats(screen.progression.data)
	screen.story_layer.upgrade_requested.emit("accuracy")
	check(screen.progression.data.points == 2,"Stat investment spends exactly one Story point")
	check(screen._current_stats(screen.progression.data).accuracy > stats_before.accuracy,"Accuracy improvement reaches combat stats")
	check(screen.league_progression.data == league_data,"Story allocation leaves league data untouched")
	screen._close_story_panel()
	screen._primary_action()
	check(not screen.active_match and is_instance_valid(screen.story_layer),"Primary action previews opponent before battle")
	screen.story_layer.fight_requested.emit()
	check(screen.active_match and screen.combat.running,"Preview CTA starts the shared engine")
	check(not is_instance_valid(screen.story_layer),"Battle removes route overlay")
	check(screen.combat.snapshot().fighters.player.runtime_stats.accuracy > stats_before.accuracy,"Runtime fighter includes purchased Accuracy")
	screen._show_menu()
	var details: Array = screen.menu_actions.filter(func(button: Button): return button.text == "Ficha")
	details[0].pressed.emit()
	check(is_instance_valid(screen.modal_layer) and screen.modal_kind=="document", "Story Menu → Ficha opens a read-only document during combat")
	screen.profile_details.rules_button.button_pressed = true
	check(screen.profile_details.rules_label.visible and screen.profile_details.rules_label.text.contains("mejoras de Historia"), "Combat Ficha explains Story allocations on demand")
	for row: Dictionary in screen.profile_details.rows:
		check(row.value==screen._stat_value(row.key,screen._current_stats(screen.progression.data)[row.key]),"Story Ficha uses campaign attributes: "+str(row.key))
	var paused_time: float = screen.combat.elapsed
	screen._process(2.0)
	check(screen.combat.elapsed==paused_time,"Reading Story fighter details pauses combat")
	screen._close_modal()
	var before: Dictionary = screen.progression.data.duplicate(true)
	for size: Vector2 in SIZES:
		screen._layout_interface(size)
		var viewport := Rect2(Vector2.ZERO,size)
		check(viewport.encloses(screen.story_button.get_rect()),"Story access stays within viewport %s" % size)
		check(not screen.story_button.get_rect().intersects(screen.menu_button.get_rect()),"Story and Menu remain separate %s" % size)
		check(not screen.story_button.visible,"Removed Story shortcut stays hidden during battle %s" % size)
	check(screen.progression.data == before,"Resize never allocates or awards progression")
	# A real engine loss provides XP and keeps the encounter retryable.
	await finish_fixture(false)
	check(screen.progression.current_stage()==0 and screen.progression.data.losses==1,"Loss stays at current encounter")
	check(screen.last_reward.xp_gained>0,"Failed attempt still awards XP")
	check(not str(screen.last_reward.get("hint","")).is_empty(),"Defeat presents a contextual hint")
	check(screen.result_copy.text.contains(str(screen.last_reward.hint)),"Hint is visible in battle result")
	check(not screen.progression.reward_match(screen.last_battle_summary).get("xp_gained",0)>0,"Duplicate UI finish cannot repeat reward")
	var failed_profile: Dictionary = screen.progression.data.duplicate(true)
	screen._leave_story()
	check(not screen.story_mode and screen.progression.data==league_data,"Returning to league restores original character")
	screen._enter_story()
	check(screen.progression.data==failed_profile,"Returning to Story resumes failed attempt and build")
	screen._close_story_panel()
	# Every actual victory advances one stage. Initial rival HP is test-only.
	for stage_index in range(StoryData.stages().size()):
		screen._start_fight()
		await finish_fixture(true)
		check(screen.progression.current_stage()==stage_index+1,"Victory unlocks only the next encounter")
		check(screen.result_panel.visible,"Story victory reuses battlefield result")
		var name_before := screen.rival_name_label.text
		check(name_before == str(screen.last_battle_summary.rival.name),"Result retains defeated opponent portrait and name")
	check(screen.progression.is_complete(),"Final Boss completes Story")
	check(screen.fight_button.text.contains("legado"),"Completion routes primary action to legacy")
	screen._primary_action()
	check(is_instance_valid(screen.story_layer) and not screen.active_match,"Completion opens legacy instead of another battle")
	var complete_data: Dictionary = screen.progression.data.duplicate(true)
	screen.story_layer.character_chosen.emit("iria")
	check(screen.progression.data.level==1 and not screen.progression.is_complete(),"Another character starts an independent Story")
	screen._start_story_battle()
	screen._confirm_surrender()
	screen._accept_surrender()
	check(not screen.active_match and screen.progression.seconds_until_next_match()>0,"Story surrender finishes with the brief retry cooldown")
	screen._enter_story()
	var waiting_panel: Control = screen.story_layer
	screen._start_story_battle()
	check(screen.story_layer==waiting_panel and not screen.active_match,"Retry during cooldown retains the preview and explanation")
	check(screen.story_layer._primary.disabled,"Preview cannot submit an unavailable retry")
	screen.story_layer.character_chosen.emit("mugo")
	check(screen.progression.data==complete_data,"Completed campaign survives switching characters")
	var restored = Story.new()
	restored.load_save(path+".story.json")
	check(same_profile(restored.data,complete_data) and restored.is_complete(),"Completion and build survive disk reload")
	check(FileAccess.get_file_as_string(path)==league_bytes,"League save remains byte-identical throughout Story")
	screen._leave_story()
	screen.queue_free()
	await process_frame
	await process_frame
	for suffix in ["",".bak",".story.json",".story.json.bak"]:
		DirAccess.remove_absolute(path+suffix)
	print("STORY INTEGRATION: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)

func finish_fixture(won: bool) -> void:
	screen.combat.start(screen.progression.active_combatant(), screen.rival, 7144+screen.progression.data.matches, {"initial_hp":{"rival":1.0} if won else {"player":1.0},"disable_signatures":true,"opening_time":0.2,"battle_id":"story_ui_%d_%d" % [Time.get_ticks_usec(),screen.progression.current_stage()]})
	var events: Array = screen.combat.advance(60.0)
	for event: Dictionary in events:
		if event.type=="finished": screen._dispatch_events([event])
	await create_timer(0.36).timeout
	check(not screen.active_match and screen.result_panel.visible,"Terminal engine state reaches Story result")

func same_profile(a: Variant, b: Variant) -> bool:
	# JSON represents numbers as floats; compare recursively without weakening
	# the key set, array ordering or any non-numeric saved value.
	if (a is int or a is float) and (b is int or b is float):
		return is_equal_approx(float(a), float(b))
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not same_profile(a[key], b[key]): return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size(): return false
		for i in range(a.size()):
			if not same_profile(a[i], b[i]): return false
		return true
	return a == b
