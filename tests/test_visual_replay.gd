extends SceneTree
## Actual seeded engine records; presentation only, disposable Main profiles.
const Base = preload("res://tests/test_identity_integration.gd")
const Progress = preload("res://scripts/progression.gd")
const StoryProgress = preload("res://scripts/story_progression.gd")
const Story = preload("res://scripts/story_catalog.gd")
const Combat = preload("res://scripts/combat_engine.gd")
const Records = preload("res://scripts/battle_identity.gd")
const Cosmetics = preload("res://scripts/cosmetic_catalog.gd")
const Replay = preload("res://scripts/ui/battle_replay_panel.gd")
const Visuals = preload("res://scripts/ui/game_visual_system.gd")
const Sizes = preload("res://tests/test_battle_layout.gd")
const BASELINE := "res://tests/fixtures/replay-stage-before-visual-migration.json"

var checks := 0
var failures := 0
var canvas: SubViewport
var screen
var panel
var scope := ""
var captures := ""
var closed_count := 0

func _init() -> void: _run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("VISUAL REPLAY: "+message+" "+scope)

func _run() -> void:
	create_timer(120,true,false,true).timeout.connect(func(): push_error("VISUAL REPLAY timeout"); quit(1))
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): captures=argument.trim_prefix("--capture-dir=")
	if not captures.is_empty(): DirAccess.make_dir_recursive_absolute(captures)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(360,240)
	canvas = SubViewport.new()
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	canvas.gui_embed_subwindows = true
	root.add_child(canvas)
	var directory := ProjectSettings.globalize_path("res://../../work/visual-system/replay-qa/fixtures").simplify_path()
	DirAccess.make_dir_recursive_absolute(directory)
	var history := _natural_history()
	var frozen_history := var_to_bytes(history)
	var old_rects: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASELINE)).sizes
	for view: Vector2 in Sizes.SIZES:
		scope = "%dx%d" % [view.x,view.y]
		canvas.size = Vector2i(view)
		var path := directory.path_join("replay-%s-%d.json" % [scope,Time.get_ticks_usec()])
		var league := Progress.new()
		league.load_save(path)
		league.select_character("tepa", "Nombre actual")
		var story := StoryProgress.new()
		story.load_save(path+".story.json")
		story.select_character("tepa")
		screen = Base.Fixture.new()
		screen.fixture_path = path
		canvas.add_child(screen)
		screen.size = view
		screen._layout_interface(view)
		var current := Cosmetics.default_appearance("balam")
		current.palette_id = "ocaso"
		check(screen.fighter_identity.update_fighter("tepa","NOMBRE NUEVO",current).ok,"Distinct present-day identity saved only in fixture")
		screen.progression.history.append_array(history)
		var files := _files(path)
		var profiles := var_to_bytes([screen.progression.data,screen.story_progression.data,screen.fighter_identity.data])
		var original_events := var_to_bytes(screen.progression.history)
		await _empty_history(view)
		screen._show_replays()
		panel = screen.replay_layer
		panel.set_process(false)
		closed_count = 0
		panel.closed.connect(func(): closed_count += 1)
		await _settle()
		check(panel.snapshots.size()==2 and panel._picker.item_count==2,"Picker excludes legacy/invalid entries and contains both real matches")
		check(panel.snapshot.rival.name=="Véspera" and int(panel.snapshot.rival.story_chapter_id)==2,"Latest actual boss snapshot selected")
		check(panel.snapshot.player.name=="LUZ HISTÓRICA","Current identity cannot rename recorded fighter")
		check(panel.actors.player.identity.display_name=="LUZ HISTÓRICA" and panel.actors.player.appearance.palette_id=="jade","Renderer receives immutable identity and palette")
		check(panel.actors.player.get_sprite_geometry().path=="res://assets/sprites/ajolote-v2.png","Historical Luma body survives current Balam appearance")
		check(panel.actors.rival.get_sprite_geometry().path=="res://assets/sprites/vespera-v3.png","Recorded boss body stays distinct from its gameplay base")
		_check_visual_contract(view,old_rects[scope])
		await _keyboard()
		await _capture("replay-ready")
		# Controls invoke the actual playback methods. Main remains stopped and
		# the records retain the natural engine's original times and HP values.
		panel._play.pressed.emit()
		check(panel.playing and panel._play.text=="Pausar","Play button starts recorded playback")
		var target_time := _first_attack_time(panel.snapshot)+0.02
		panel._process(target_time)
		check(panel.elapsed>0 and panel.event_index>0,"Playback consumes recorded chronological events")
		var expected := _hp_at(panel.snapshot,panel.elapsed)
		check(is_equal_approx(panel.bars.player.value,expected.player) and is_equal_approx(panel.bars.rival.value,expected.rival),"Both HP rails agree with authoritative record at current time")
		panel._play.pressed.emit()
		var paused_time: float = panel.elapsed
		var paused_index: int = panel.event_index
		var actor_times: Array = [panel.actors.player._action_time,panel.actors.rival._action_time]
		panel._process(3.0)
		for actor: Node2D in panel.actors.values(): actor._process(0.1)
		check(not panel.playing and panel.elapsed==paused_time and panel.event_index==paused_index,"Pause freezes replay time and event cursor")
		check(panel._fx.motion_paused and panel.actors.player.motion_paused and panel.actors.rival.motion_paused,"Pause freezes both fighters and FX")
		check([panel.actors.player._action_time,panel.actors.rival._action_time]==actor_times,"Paused renderer clocks do not drift")
		await _capture("replay-paused")
		panel._play.pressed.emit()
		panel._process(120)
		check(not panel.playing and panel.event_index==panel.snapshot.events.size() and is_equal_approx(panel.elapsed,panel.snapshot.duration),"Catch-up reaches exactly terminal time and consumes each event once")
		check(panel._play.text=="Repetir","Completed playback offers replay instead of a reward action")
		expected = _hp_at(panel.snapshot,panel.snapshot.duration)
		check(is_equal_approx(panel.bars.player.value,expected.player) and is_equal_approx(panel.bars.rival.value,expected.rival),"Terminal HP rails equal original result")
		check(panel.actors[str(panel.snapshot.winner)]._mode=="victory","Recorded winner enters victory presentation")
		var losing_side: String = "rival" if panel.snapshot.winner=="player" else "player"
		check(panel.actors[losing_side]._mode=="fall","Recorded loser enters defeat presentation")
		await _capture("replay-finished")
		panel._restart.pressed.emit()
		check(panel.elapsed==0 and panel.event_index==0 and not panel.playing,"Restart resets time/index and stays paused")
		check(panel.bars.player.value==panel.bars.player.max_value and panel.bars.rival.value==panel.bars.rival.max_value,"Restart restores original max HP")
		panel._picker.item_selected.emit(1)
		check(panel.snapshot.rival.name=="RIVAL HISTÓRICO" and panel.elapsed==0 and not panel.playing,"Picker changes match and restarts presentation")
		check(panel._background.texture.resource_path=="res://assets/arena-faroles-v2.png","League record restores recorded/default Faroles backdrop")
		var chosen_id: String = panel.snapshot.battle_id
		panel.select_snapshot(-1)
		panel.select_snapshot(99)
		check(panel.snapshot.battle_id==chosen_id,"Out-of-range selection cannot corrupt current record")
		check(var_to_bytes(screen.progression.history)==original_events and var_to_bytes(history)==frozen_history,"All source snapshots, names, event order and values stay immutable")
		var late_key := _key(KEY_ESCAPE)
		canvas.push_input(late_key,true)
		late_key.echo = true
		canvas.push_input(late_key,true)
		await _settle()
		check(closed_count==1 and not is_instance_valid(screen.replay_layer),"Escape closes exactly once without opening another overlay")
		check(var_to_bytes([screen.progression.data,screen.story_progression.data,screen.fighter_identity.data])==profiles,"Playback, selection, pause, restart and close do not reward or alter profiles")
		check(_files(path)==files,"Both save files, identity and backups remain byte-identical throughout replay")
		screen.free()
		await process_frame
	canvas.free()
	await process_frame
	print("VISUAL REPLAY: %d checks, %d failures across 7 sizes" % [checks,failures])
	quit(0 if failures==0 else 1)

func _natural_history() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for chapter: int in [1,2]:
		var profile := Progress._new_profile("tepa")
		profile.level = 20
		var player := Progress._combatant(profile)
		player["fighter_id"] = "fixture:historical-tepa"
		player["name"] = "LUZ HISTÓRICA"
		player["identity"] = {"display_name":"LUZ HISTÓRICA"}
		player["appearance"] = Cosmetics.default_appearance("luma")
		player.appearance.palette_id = "jade"
		player.appearance.victory_pose_id = "saludo"
		var rival: Dictionary
		if chapter==2: rival = Story.opponent(7,2)
		else:
			var opponent_profile := Progress._new_profile("copal")
			opponent_profile.level = 20
			rival = Progress._combatant(opponent_profile)
			rival.name = "RIVAL HISTÓRICO"
		var engine := Combat.new()
		engine.start(player,rival,730401+chapter)
		engine.advance(120)
		var summary: Dictionary = engine.summary()
		var record: Dictionary = {"winner":summary.winner,"reason":summary.reason,"duration":summary.duration}
		Records.attach(record,summary)
		check(not Records.snapshot(record).is_empty() and not summary.events.is_empty(),"Valid natural engine record without forced HP, move or winner")
		result.append(record)
	result.insert(1,{"player_name":"LEGADO SIN REPETICIÓN","winner":"player"})
	return result

func _empty_history(view: Vector2) -> void:
	var empty := Replay.new()
	canvas.add_child(empty)
	empty.set_process(false)
	empty.configure([])
	await _settle()
	check(empty._play.disabled and empty._restart.disabled,"Empty replay disables transport")
	check(empty._picker.item_count==0 and empty.snapshot.is_empty(),"Empty replay does not fabricate records")
	check(empty._background.get_global_rect().is_equal_approx(Rect2(Vector2.ZERO,view)),"Empty state retains full bleed Faroles backdrop")
	check(empty._background.texture.resource_path=="res://assets/arena-faroles-v2.png","Empty state has supported background")
	empty.free()
	await _settle()

func _check_visual_contract(view: Vector2, baseline: Array) -> void:
	check(panel.theme==Visuals.theme(),"Replay uses shared GVS theme")
	check(panel._background.get_global_rect().is_equal_approx(Rect2(Vector2.ZERO,view)),"Recorded background fills entire screen, not only battle stage")
	check(panel._background.texture.resource_path=="res://assets/arena-tormenta-v3.png","Recorded chapter selects correct storm backdrop")
	check(panel._background.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_COVERED and panel._background.expand_mode==TextureRect.EXPAND_IGNORE_SIZE,"Background preserves aspect and does not impose texture-sized minima")
	check(panel._background.mouse_filter==Control.MOUSE_FILTER_IGNORE,"Painted scenery cannot intercept replay controls")
	check(panel._stage.get_rect().is_equal_approx(Rect2(float(baseline[0]),float(baseline[1]),float(baseline[2]),float(baseline[3]))),"Migration preserves exact approved battle stage coordinates")
	check(panel._stage.clip_contents and Rect2(Vector2.ZERO,view).encloses(panel._stage.get_rect()),"Battle stage stays contained")
	var controls: Array[Control] = [panel._close,panel._picker,panel._play,panel._restart]
	for i in range(controls.size()):
		var control := controls[i]
		check(control.size.x>=44 and control.size.y>=44,"Replay control preserves approved 44px target")
		check(Rect2(Vector2.ZERO,view).grow(1).encloses(control.get_global_rect()),"Replay control fits viewport")
		check(not control.get_global_rect().intersects(panel._stage.get_global_rect()),"Replay control does not cover battle stage")
		check(control.get_meta("game_component","")=="button","Control is styled by shared button/option API")
		for state: String in ["normal","hover","pressed","disabled","focus"]:
			check(control.has_theme_stylebox_override(state),"Shared visual state available: "+state)
		for j in range(i): check(not control.get_global_rect().intersects(controls[j].get_global_rect()),"Interactive controls remain pairwise disjoint")
	check(panel._close.text=="×" and panel._close.size==Vector2(48,48),"Shared icon close uses exact 48px target")
	check(panel._play.get_meta("game_visual_role")=="primary" and panel._restart.get_meta("game_visual_role")=="secondary","Transport uses existing primary/secondary hierarchy")
	check(panel._picker.get_popup().theme==Visuals.theme(),"Open selector receives same theme")
	check(panel._title.get_theme_font("font")==Visuals.font("title"),"Heading uses shared serif")
	check(panel._title.get_theme_font_size("font_size")==Visuals.font_size("title",view.x<640 or view.y<540),"Heading follows shared responsive role")
	for side: String in ["player","rival"]:
		var bar: ProgressBar = panel.bars[side]
		check(bar.get_meta("game_component","")=="progress" and not bar.show_percentage,"Recorded HP uses shared progress component")
		check(bar.get_theme_stylebox("fill").bg_color==Visuals.color("success" if side=="player" else "danger"),"Health fill has correct player/rival semantics")
		check(bar.size.y==10 and bar.size.x>100,"Compact HP geometry retained")
		check(Rect2(Vector2.ZERO,view).encloses(bar.get_rect()),"HP rail stays visible")
		check(panel._names[side].tooltip_text==panel._names[side].text,"Clipped name still exposes complete historical label")
	check(panel._event.get_rect().end.y<=panel._play.get_rect().position.y,"Event text does not cover transport")

func _keyboard() -> void:
	check(canvas.gui_get_focus_owner()==panel._close,"Overlay begins with close focused")
	var visited := {}
	for i in range(16):
		canvas.push_input(_key(KEY_TAB,i>=8),true)
		var focus: Control = canvas.gui_get_focus_owner()
		check(focus!=null and panel.is_ancestor_of(focus),"Tab/Shift-Tab never escapes into Main HUD")
		if focus in [panel._close,panel._picker,panel._play,panel._restart]: visited[focus.get_instance_id()] = true
	check(visited.size()==4,"Keyboard reaches selector, play, restart and close")
	var popup: PopupMenu = panel._picker.get_popup()
	var rect: Rect2 = panel._picker.get_global_rect()
	popup.popup(Rect2i(rect.position+Vector2(0,rect.size.y),Vector2(rect.size.x,100)))
	await _settle()
	check(popup.visible,"Real selector popup opens")
	panel._input(_key(KEY_ESCAPE))
	check(closed_count==0 and is_instance_valid(screen.replay_layer),"Overlay yields Escape while popup owns input")
	canvas.push_input(_key(KEY_ESCAPE),true)
	await _settle()
	check(not popup.visible and closed_count==0,"First Escape dismisses only selector popup")
	if popup.visible: popup.hide()

func _first_attack_time(record: Dictionary) -> float:
	for event: Dictionary in record.events:
		if event.type=="attack": return float(event.time)
	return float(record.duration)*0.5

func _hp_at(record: Dictionary, time_value: float) -> Dictionary:
	var result := {"player":float(record.player.combat_stats.max_hp),"rival":float(record.rival.combat_stats.max_hp)}
	for event: Dictionary in record.events:
		if float(event.time)>time_value: break
		for side: String in ["player","rival"]:
			if event.has(side+"_hp"): result[side]=float(event[side+"_hp"])
	return result

func _files(path: String) -> Dictionary:
	var result := {}
	for suffix: String in ["",".bak",".story.json",".story.json.bak",".identity.json",".identity.json.bak"]:
		result[suffix]=FileAccess.get_file_as_bytes(path+suffix) if FileAccess.file_exists(path+suffix) else null
	return result

func _key(code: Key, shift: bool=false) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode=code
	event.pressed=true
	event.shift_pressed=shift
	return event

func _settle() -> void:
	for i in range(3): await process_frame

func _capture(label: String) -> void:
	if captures.is_empty() or DisplayServer.get_name()=="headless": return
	if canvas.size not in [Vector2i(1360,880),Vector2i(390,844),Vector2i(844,390)]: return
	await create_timer(0.32,true,false,true).timeout
	await RenderingServer.frame_post_draw
	check(canvas.get_texture().get_image().save_png(captures.path_join(label+"-"+scope+".png"))==OK,"Native replay capture "+label)
