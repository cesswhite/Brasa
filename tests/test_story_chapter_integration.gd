extends SceneTree
## Main/StoryPanel chapter transitions with isolated fixtures only.
## Headless: Godot --headless --path outputs/Brasa --script res://tests/test_story_chapter_integration.gd
## Native captures: omit --headless and append -- --capture-dir=/absolute/path
const Story = preload("res://scripts/story_progression.gd")
const StoryData = preload("res://scripts/story_catalog.gd")
const SIZES: Array[Vector2i] = [
	Vector2i(1360,880),Vector2i(1224,792),Vector2i(1920,1080),
	Vector2i(768,1024),Vector2i(390,844),Vector2i(430,932),Vector2i(844,390),
]
const STORM := "res://assets/arena-tormenta-v3.png"
const VESPERA := "res://assets/sprites/vespera-v3.png"

class Fixture:
	extends "res://scripts/main.gd"
	var fixture_path: String
	func _ready() -> void:
		# Production boot must never read the player's normal save in this test.
		session_save_path = fixture_path
		sound_enabled = false
		set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		_build_theme()
		_build_interface()
		progression.load_save(fixture_path)
		progression.select_character("mugo","Prueba de capítulos")
		_prepare_rival()
		_refresh_manager()
		_update_portraits()
		set_process(false)

var screen: Fixture
var canvas: SubViewport
var checks := 0
var failures := 0
var fixture_path := ""
var capture_dir := ""
var capture_count := 0

func _init() -> void:
	_run.call_deferred()

func _check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CHAPTER INTEGRATION: "+description)

func _run() -> void:
	create_timer(90,true,false,true).timeout.connect(func():
		push_error("CHAPTER INTEGRATION: asynchronous timeout")
		_cleanup()
		quit(1))
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
	if not capture_dir.is_empty():
		_check(capture_dir.is_absolute_path(),"Capture directory must be absolute")
		_check(DisplayServer.get_name()!="headless","Captures require a native rendering backend")
		if not capture_dir.is_absolute_path() or DisplayServer.get_name()=="headless":
			quit(1)
			return
		DirAccess.make_dir_recursive_absolute(capture_dir)
	var directory := ProjectSettings.globalize_path("res://../../work/level2/integration_fixtures").simplify_path()
	DirAccess.make_dir_recursive_absolute(directory)
	fixture_path = directory.path_join("chapters_%d.json" % Time.get_ticks_usec())
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(360,240)
	canvas = SubViewport.new()
	canvas.size = SIZES[0]
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	screen = Fixture.new()
	screen.fixture_path = fixture_path
	canvas.add_child(screen)
	await _place(SIZES[0])
	var league_bytes := FileAccess.get_file_as_string(fixture_path)
	var league_data: Dictionary = screen.progression.data.duplicate(true)
	var league_background: String = screen.arena.get_background_path()
	_check(screen.progression.last_save_ok,"League bootstrap writes only the unique fixture")
	_check(int(StoryData.stage(1,1).level)==2,"First chapter's Nima encounter uses corrected level two")
	_check(StoryData.chapters().size()==11 and StoryData.total_encounters()==100,"The two original chapters lead into the 100-encounter campaign")
	screen.story_button.pressed.emit()
	_check(screen.story_mode and is_instance_valid(screen.story_layer),"Story entry opens character selection")
	screen.story_layer.character_chosen.emit("mugo")
	screen.story_layer.upgrade_requested.emit("accuracy")
	screen.story_layer.upgrade_requested.emit("max_hp")
	_check(screen.progression.current_chapter()==1 and screen.progression.current_stage()==0,"New campaign starts in chapter one")
	_check(screen.progression.data.level==1 and screen.progression.data.points==1,"New Story keeps balanced start and spends exactly two points")
	_check(screen.arena.get_background_path()==str(StoryData.chapter(1).background),"First chapter binds original lantern arena")
	screen._close_story_panel()
	for stage_index in range(StoryData.stages(1).size()):
		await _fight_fixture(true)
		_check(screen.progression.current_stage()==stage_index+1,"Chapter one victory advances one encounter")
	_check(screen.progression.is_complete() and screen.progression.can_start_next_chapter(),"Ascua completion unlocks the next chapter")
	_check(screen.last_battle_summary.rival.visual.atlas=="res://assets/sprites/ascua-v3.png","Chapter one final descriptor still uses Ascua")
	screen._primary_action()
	_check(is_instance_valid(screen.story_layer) and screen.story_layer._active_tab=="legacy","Ascua result routes to chapter-one legacy")
	_check(screen.story_layer._primary.text.contains("2") and not screen.story_layer._primary.disabled,"Legacy exposes an enabled chapter-two CTA")
	var chapter_one: Dictionary = screen.progression.completion_summary(1).duplicate(true)
	var before_transition: Dictionary = _build_state(screen.progression.data)
	var before_stats: Dictionary = screen._current_stats(screen.progression.data)
	_check(bool(chapter_one.completed) and str(chapter_one.badge)==str(StoryData.chapter(1).badge),"First legacy awards the declared badge")
	await _layouts("legacy-chapter1",true)
	# Pressing the actual primary emits next_chapter_requested and reaches Main.
	screen.story_layer._primary.pressed.emit()
	_check(screen.progression.current_chapter()==2 and screen.progression.current_stage()==0,"Chapter CTA starts the new route at its first encounter")
	_check(not screen.progression.is_complete() and not screen.progression.can_start_next_chapter(),"Chapter two is playable and cannot be started twice")
	_check(_equivalent(_build_state(screen.progression.data),before_transition),"Chapter transition preserves level, XP, points, stats and allocations")
	_check(_equivalent(screen._current_stats(screen.progression.data),before_stats),"Transition preserves all derived combat statistics")
	_check(_equivalent(screen.progression.completion_summary(1),chapter_one),"Chapter-one legacy is archived without rewriting its build")
	_check(screen.progression.chapter_summaries().size()==1,"Completed chapter summary is available through the archive API")
	_check(screen.arena.get_background_path()==STORM,"Chapter two immediately switches the arena texture")
	_check(screen.story_layer._active_tab=="route" and screen.story_layer._selected_stage==0,"Panel refresh selects chapter-two route")
	_check(screen.story_layer._heading.text.contains(str(StoryData.chapter(2).title)),"Panel shows chapter-two identity")
	await _layouts("route-chapter2",true)
	var state_before_legacy: Dictionary = screen.progression.data.duplicate(true)
	screen.story_layer.show_tab("legacy")
	screen.story_layer._chapter_buttons[0].pressed.emit()
	_check(screen.story_layer._legacy_chapter==1,"Archived chapter-one selector opens its legacy")
	_check(_equivalent(screen.progression.data,state_before_legacy),"Browsing an old legacy cannot reset or mutate the campaign")
	_check(screen.arena.get_background_path()==STORM,"Reading old legacy does not replace current chapter arena")
	screen.story_layer.show_tab("route")
	screen._close_story_panel()
	var xp_before_loss: int = int(screen.progression.data.total_xp)
	await _fight_fixture(false)
	_check(screen.progression.current_chapter()==2 and screen.progression.current_stage()==0,"Chapter-two defeat keeps the current encounter retryable")
	_check(screen.last_reward.xp_gained>0 and int(screen.progression.data.total_xp)>xp_before_loss,"Chapter-two defeat grants positive saved XP")
	_check(not str(screen.last_reward.hint).is_empty() and screen.result_copy.text.contains(str(screen.last_reward.hint)),"Defeat hint is visible on the battlefield result")
	var losing_summary: Dictionary = screen.last_battle_summary.duplicate(true)
	var after_loss: Dictionary = screen.progression.data.duplicate(true)
	var restored = Story.new()
	restored.load_save(fixture_path+".story.json")
	_check(not restored.save_blocked and _equivalent(restored.data,after_loss),"Chapter-two defeat and build survive disk reload")
	_check(restored.current_chapter()==2 and restored.current_stage()==0,"Reload resumes chapter two at the failed encounter")
	_check(_equivalent(restored.completion_summary(1),chapter_one),"Reload preserves the archived first legacy")
	_check(restored.reward_match(losing_summary).get("duplicate",false),"Reloaded reward ledger rejects duplicate chapter-two result")
	screen.story_progression = restored
	screen.progression = restored
	screen._reset_mode_view()
	_check(screen.arena.get_background_path()==STORM,"Restored campaign reapplies its chapter-two backdrop")
	for stage_index in range(StoryData.stages(2).size()):
		if stage_index==StoryData.stages(2).size()-1:
			screen._show_story_panel("route")
			screen.story_layer.fight_requested.emit()
			_check(screen.active_match,"Second boss preview starts combat")
			_check(str(screen.rival.name)=="Véspera","Second boss displays Véspera's name")
			_check(is_equal_approx(float(screen.rival.combat_stats.max_hp),780.0) and is_equal_approx(float(screen.rival.combat_stats.attack),52.0),"Véspera uses final 780 HP and 52 attack tuning")
			_check(screen.rival_hp_label.text.contains("780 / 780"),"Boss HUD displays the final 780 HP before combat")
			_check(screen.rival.get("visual",{}).get("atlas","")==VESPERA,"Second boss descriptor propagates Véspera's atlas")
			_check(screen.rival_view.get_sprite_geometry().get("path","")==VESPERA,"Battlefield renders Véspera without Ascua fallback")
			_check(screen.rival_view.get_sprite_geometry().frames.size()==8,"Véspera supplies all eight animation poses")
			_check(screen.rival_name_label.text=="Véspera","Battle HUD matches the second boss identity")
			await _layouts("boss-vespera",false)
			await _finish_fixture(true)
		else:
			await _fight_fixture(true)
		_check(screen.progression.current_stage()==stage_index+1,"Chapter two victory advances one encounter")
		_check(screen.progression.last_save_ok,"Every chapter-two result saves successfully")
	_check(screen.progression.is_complete() and screen.progression.current_chapter()==2,"Véspera completion finishes chapter two")
	_check(screen.progression.can_start_next_chapter(),"Chapter two now unlocks the declared third chapter")
	_check(_equivalent(screen.progression.completion_summary(1),chapter_one),"Second chapter progress never overwrites first legacy")
	var chapter_two: Dictionary = screen.progression.completion_summary(2)
	_check(bool(chapter_two.completed) and str(chapter_two.badge)==str(StoryData.chapter(2).badge),"Second legacy awards its own declared badge")
	_check(_equivalent(screen.progression.completion_summary(),chapter_two),"Default completion summary selects the current chapter")
	_check(str(chapter_one.badge)!=str(chapter_two.badge),"The two completed chapters have distinct badges")
	screen._primary_action()
	_check(is_instance_valid(screen.story_layer) and screen.story_layer._active_tab=="legacy","Final result opens chapter-two legacy")
	_check(screen.story_layer._legacy_chapter==2,"Legacy initially selects the newly completed chapter")
	await _layouts("legacy-chapter2",true)
	screen.story_layer._chapter_buttons[0].pressed.emit()
	_check(screen.story_layer._legacy_chapter==1 and not screen.story_layer._chapter_buttons[1].disabled,"Both archived chapters remain accessible")
	_check(_equivalent(screen.progression.completion_summary(1),chapter_one),"Legacy selector retrieves exact frozen chapter-one record")
	var final_profile: Dictionary = screen.progression.data.duplicate(true)
	var final_reloaded = Story.new()
	final_reloaded.load_save(fixture_path+".story.json")
	_check(final_reloaded.is_complete() and _equivalent(final_reloaded.data,final_profile),"Both completed chapters and build survive final disk reload")
	_check(_equivalent(final_reloaded.completion_summary(1),chapter_one),"Final reload retains chapter-one archive")
	_check(_equivalent(final_reloaded.completion_summary(2),chapter_two),"Final reload retains chapter-two archive")
	screen._leave_story()
	_check(not screen.story_mode and screen.progression.data==league_data,"Return to League restores its original progression")
	_check(screen.arena.get_background_path()==league_background,"Return to League restores the previous arena")
	_check(FileAccess.get_file_as_string(fixture_path)==league_bytes,"League save remains byte-identical across both Story chapters")
	_cleanup()
	print("STORY CHAPTER INTEGRATION: %d checks, %d failures; %d native captures" % [checks,failures,capture_count])
	quit(0 if failures==0 else 1)

func _fight_fixture(won: bool) -> void:
	screen._start_fight()
	_check(screen.active_match and screen.combat.running,"Production action starts a Story battle")
	await _finish_fixture(won)

func _finish_fixture(won: bool) -> void:
	screen.combat.start(screen.progression.active_combatant(),screen.rival,8244+int(screen.progression.data.matches),{
		"initial_hp":{"rival":1.0} if won else {"player":1.0},
		"disable_signatures":true,"opening_time":0.2,
		"battle_id":"chapter_ui_%d_%d_%d" % [Time.get_ticks_usec(),screen.progression.current_chapter(),screen.progression.current_stage()]})
	var events: Array = screen.combat.advance(60.0)
	var summary: Dictionary = screen.combat.summary()
	_check(summary.get("winner","")==("player" if won else "rival"),"Deterministic engine fixture reaches the requested terminal side")
	for event: Dictionary in events:
		if event.type=="finished": screen._dispatch_events([event])
	await create_timer(0.36).timeout
	_check(not screen.active_match and screen.result_panel.visible,"Terminal engine event reaches Main result")
	_check(bool(screen.last_reward.get("accepted",false)) and screen.progression.last_save_ok,"Terminal result is accepted and persisted exactly once")

func _place(view_size: Vector2i) -> void:
	canvas.size = view_size
	screen.size = Vector2(view_size)
	screen._layout_interface(Vector2(view_size))
	for _frame in range(5): await process_frame

func _layouts(label: String, panel_visible: bool) -> void:
	var before: Dictionary = screen.progression.data.duplicate(true)
	var combat_before: Dictionary = screen.combat.snapshot()
	for view_size: Vector2i in SIZES:
		await _place(view_size)
		var boundary := Rect2(Vector2.ZERO,Vector2(view_size))
		var context := label+" "+str(view_size)
		_check(screen.arena.get_backdrop_rect().grow(1).encloses(boundary),context+": backdrop covers native viewport")
		_check(screen.arena.scale.is_equal_approx(Vector2.ONE),context+": arena nodes are not globally stretched")
		if panel_visible:
			var panel: Control = screen.story_layer
			_check(is_instance_valid(panel) and panel.size.is_equal_approx(Vector2(view_size)),context+": panel uses native viewport dimensions")
			_check(boundary.grow(1).encloses(panel._primary.get_global_rect()),context+": chapter action remains visible")
			_check(boundary.grow(1).encloses(panel._league.get_global_rect()),context+": League return remains visible")
			_check(not panel._primary.get_global_rect().intersects(panel._league.get_global_rect()),context+": primary and League actions do not overlap")
			_check(panel._scroll.size.y>=70,context+": chapter content retains a usable scroll area")
			_check(panel._primary.size.y>=44 and panel._league.size.y>=44,context+": touch targets remain usable")
		else:
			_check(screen.active_match and not is_instance_valid(screen.story_layer),context+": boss fight stays visible")
			_check(screen.story_button.disabled,context+": chapter cannot switch during combat")
			for actor: Node2D in [screen.player_view,screen.rival_view]:
				var sprite: Sprite2D = actor.get_node("IllustratedFighter")
				var actual: Rect2 = sprite.get_global_transform()*sprite.get_rect()
				_check(boundary.grow(2).encloses(actual),context+": actual boss/player pixels remain onscreen")
				_check(not actual.intersects(screen.fight_button.get_global_rect()),context+": characters remain clear of controls")
			_check(boundary.grow(1).encloses(screen.rival_name_label.get_global_rect()),context+": Véspera HUD remains visible")
		if not capture_dir.is_empty():
			await RenderingServer.frame_post_draw
			var screenshot := canvas.get_texture().get_image()
			_check(screenshot.get_size()==view_size,context+": native screenshot preserves requested dimensions")
			_check(screenshot.save_png(capture_dir.path_join("%s-%dx%d.png" % [label,view_size.x,view_size.y]))==OK,context+": native screenshot saves")
			capture_count += 1
	_check(_equivalent(screen.progression.data,before),label+": resizing/capturing cannot award XP or reset progression")
	_check(_equivalent(screen.combat.snapshot(),combat_before),label+": rendering cannot advance combat")
	await _place(SIZES[0])

func _build_state(profile: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: String in ["character_id","name","level","xp","points","stats","allocations","allocation_history","total_xp","cap_xp"]:
		result[key] = profile.get(key)
	return result.duplicate(true)

func _equivalent(a: Variant, b: Variant) -> bool:
	if (a is int or a is float) and (b is int or b is float):
		return is_equal_approx(float(a),float(b))
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not _equivalent(a[key],b[key]): return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size(): return false
		for index in range(a.size()):
			if not _equivalent(a[index],b[index]): return false
		return true
	return a==b

func _cleanup() -> void:
	if fixture_path.is_empty(): return
	var directory := DirAccess.open(fixture_path.get_base_dir())
	if directory==null: return
	for file_name: String in directory.get_files():
		if file_name.begins_with(fixture_path.get_file()):
			DirAccess.remove_absolute(fixture_path.get_base_dir().path_join(file_name))
