extends SceneTree
## Menu migration regression; safe explicit saves, offline route spy, no settings writes.
const Base = preload("res://tests/test_identity_integration.gd")
const Progress = preload("res://scripts/progression.gd")
const Story = preload("res://scripts/story_progression.gd")
const SIZES: Array[Vector2i] = [Vector2i(1360,880),Vector2i(390,844),Vector2i(844,390)]

class Fixture:
	extends Base.Fixture
	var online_opened := 0
	func _open_online() -> void: online_opened += 1

class FailedStory:
	extends Story
	func save() -> bool:
		last_save_ok = false
		return false

var checks := 0
var failures := 0
var screen: Fixture
var canvas: SubViewport

func _init() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("MENU NAVIGATION: " + message)

func _run() -> void:
	create_timer(90,true,false,true).timeout.connect(func(): push_error("MENU NAVIGATION timeout"); quit(1))
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(360,240)
	canvas = SubViewport.new()
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	var directory := ProjectSettings.globalize_path("res://../../work/visual-system/fixtures").simplify_path()
	DirAccess.make_dir_recursive_absolute(directory)
	for view: Vector2i in SIZES:
		canvas.size = view
		var path := directory.path_join("menu-nav-%dx%d-%d.json" % [view.x,view.y,Time.get_ticks_usec()])
		var league := Progress.new()
		league.load_save(path)
		league.select_character("mugo")
		var campaign := Story.new()
		campaign.load_save(path+".story.json")
		campaign.select_character("mugo")
		var original_league := FileAccess.get_file_as_string(path)
		var original_story := FileAccess.get_file_as_string(path+".story.json")
		screen = Fixture.new()
		screen.fixture_path = path
		canvas.add_child(screen)
		screen.size = Vector2(view)
		screen._layout_interface(screen.size)
		screen._show_menu()
		await process_frame
		await process_frame
		var home = screen.modal_layer
		check(screen.modal_kind=="menu" and screen.menu_actions.size()==12,"Home preserves Main menu contract at "+str(view))
		check(canvas.gui_get_focus_owner()==home.buttons[0],"Primary adventure has initial keyboard focus")
		check(home._close.size.x>=48 and home._close.size.y>=48,"Close preserves touch size")
		check(home._scroll.follow_focus,"Scrolling follows keyboard navigation")
		check(home.buttons[0].text=="Empezar historia","An untouched campaign starts, even when a profile already exists")
		check(home.buttons[0].get_theme_stylebox("focus") is StyleBoxEmpty,"Primary has no outer focus border")
		var original_profile: Dictionary = screen.story_progression.roster.mugo.duplicate(true)
		screen.story_progression.roster.mugo.matches = 1
		check(bool(screen._visual_state().story_started),"A first attempt can be continued even before a win")
		screen._close_modal()
		await process_frame
		screen._show_menu()
		await process_frame
		home = screen.modal_layer
		check(home.buttons[0].text=="Continuar historia","Started character gets Continue invitation")
		screen.story_progression.roster.mugo = original_profile
		screen.story_progression.data = screen.story_progression.roster.mugo
		screen.story_progression.roster.mugo.chapter = 2
		check(bool(screen._visual_state().story_started),"New chapter continues with zero matches")
		screen.story_progression.roster.mugo.chapter = 1
		for button: Button in home.buttons:
			check(button.size.y>=48 and button.size.x>=48,"Touch target: "+button.text)
			check(not button.disabled,"Idle route enabled: "+button.text)
			button.grab_focus()
			await process_frame
			await process_frame
			check(home._scroll.get_global_rect().encloses(button.get_global_rect()),"Focus scrolls complete button into view: "+button.text+" "+str(view))
		var focus: Control = home._close
		for i in range(home.buttons.size()+1):
			focus = focus.find_next_valid_focus()
			check(focus!=null and home.is_ancestor_of(focus),"Tab stays inside Home: "+str(i)+" "+str(view))
			if focus==null: break
		check(focus==home._close,"Forward focus cycle returns to close")
		focus = home._close.find_prev_valid_focus()
		check(focus==home.buttons.back(),"Shift-Tab wraps from close to last destination")
		await _choose("Ajustes")
		check(screen.modal_kind=="settings" and screen.menu_actions.size()==4,"Settings owns four controls after Home closes")
		for button: Button in screen.menu_actions:
			check(button.size.y>=48 and button.size.x>=48,"Settings touch target: "+button.text)
		screen._close_modal()
		await process_frame
		check(not is_instance_valid(screen.modal_layer) and screen.menu_actions.is_empty(),"Closing settings clears modal contract")
		for item: Array in [["Ficha","document"],["Historial","history"],["Registro","log"],["Cómo jugar","document"],["Entrenar","training"]]:
			screen._show_menu()
			await _choose(item[0])
			check(screen.modal_kind==item[1],"Home destination: "+str(item[0]))
			screen._close_modal()
			await process_frame
		screen._show_menu()
		await _choose("Arena online")
		check(screen.online_opened==1 and not is_instance_valid(screen.modal_layer),"Online dispatches once, without actual network")
		for label: String in ["Historia","Logros"]:
			screen._show_menu()
			await _choose(label)
			check(screen.story_mode and is_instance_valid(screen.story_layer),"Home opens campaign "+label)
			if label=="Logros": check(screen.story_layer._active_tab=="legacy","Legacy action lands on archived campaigns")
			screen._close_story_panel()
			await process_frame
			screen._show_menu()
			await _choose("Arena")
			check(not screen.story_mode and not is_instance_valid(screen.modal_layer),"Arena returns to League and closes Home")
		screen._show_menu()
		await _choose("Compañeros")
		check(is_instance_valid(screen.creation_layer),"Companions route opens roster")
		screen._close_roster()
		await process_frame
		screen._show_menu()
		await _choose("Personalizar")
		check(is_instance_valid(screen.customization_layer),"Customize route opens editor")
		screen._cancel_customization()
		await process_frame
		screen._start_fight()
		check(screen.active_match,"Real fixture fight starts for pause test")
		var elapsed: float = screen.combat.elapsed
		screen._show_menu()
		await process_frame
		for button: Button in screen.menu_actions:
			check(button.disabled==(str(button.get_meta("action_id")) in ["story","arena","online","training","companions","customize","legacy"]),"Fight availability: "+button.text)
		var battle_home = screen.modal_layer
		focus = battle_home._close
		for i in range(6):
			focus = focus.find_next_valid_focus()
			check(focus!=null and battle_home.is_ancestor_of(focus) and not focus.disabled,"Paused focus cycle skips disabled destinations")
		check(focus==battle_home._close,"Paused cycle closes after five available destinations")
		screen._process(1.0)
		check(screen.combat.elapsed==elapsed and screen.player_view.motion_paused and screen.rival_view.motion_paused and screen.combat_fx.motion_paused,"Home pauses simulation and all presentation clocks")
		await _choose("Ficha")
		screen._process(1.0)
		check(screen.modal_kind=="document" and screen.combat.elapsed==elapsed,"Read-only fight profile preserves pause")
		var escape := InputEventKey.new()
		escape.pressed = true
		escape.keycode = KEY_ESCAPE
		screen._unhandled_key_input(escape)
		check(not is_instance_valid(screen.modal_layer) and not screen.player_view.motion_paused,"Escape resumes after fight profile")
		check(FileAccess.get_file_as_string(path)==original_league and FileAccess.get_file_as_string(path+".story.json")==original_story,"Menu routes never rewrite either gameplay save")
		# Clicking Start must open this fighter, not the previously active campaign.
		screen.set_process(false)
		screen.active_match = false
		screen.league_progression.select_character("luma")
		screen.progression = screen.league_progression
		screen.story_mode = false
		var previous_campaign: Dictionary = screen.story_progression.roster.mugo.duplicate(true)
		screen.story_progression.roster.mugo.matches = 3
		check(not bool(screen._visual_state().story_started),"Other fighter progress does not mark Luma as started")
		screen.story_progression.roster.mugo = previous_campaign
		screen._show_menu()
		await process_frame
		check(screen.menu_actions[0].text=="Empezar historia","Different fresh character gets Start")
		await _choose("Historia")
		check(screen.story_mode and screen.story_progression.active_id=="luma","Story action opens selected fighter")
		check(screen.story_progression.roster.mugo==previous_campaign,"Switching story preserves former character progress")
		screen._close_story_panel()
		screen._leave_story()
		var failed := FailedStory.new()
		failed.roster = screen.story_progression.roster.duplicate(true)
		failed.active_id = "luma"
		failed.data = failed.roster.luma
		failed._replay_level = 1
		var intact := failed.roster.duplicate(true)
		screen.story_progression = failed
		screen._enter_story("mugo")
		check(not screen.story_mode and failed.active_id=="luma","Failed character switch does not enter the wrong campaign")
		check(failed.roster==intact and failed.data==intact.luma and failed._replay_level==1,"Failed save restores the previous campaign and replay selection")
		screen.free()
		await process_frame
	canvas.free()
	await process_frame
	print("VISUAL MENU NAVIGATION: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)

func _choose(label: String) -> void:
	for button: Button in screen.menu_actions:
		if button.text==label or (label=="Historia" and str(button.get_meta("action_id",""))=="story"):
			button.pressed.emit()
			await process_frame
			await process_frame
			return
	check(false,"Missing route button: "+label)
