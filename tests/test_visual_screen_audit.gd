extends SceneTree
## Baseline UI inventory, not product navigation or a natural-combat recording.
## Main runs only against new work/visual-system fixtures. Online uses a Node mock.
const Base = preload("res://tests/test_identity_integration.gd")
const Progress = preload("res://scripts/progression.gd")
const CampaignFixtures = preload("res://tests/test_story_campaign_ui.gd")
const StoryPanelScript = preload("res://scripts/ui/story_panel.gd")
const OnlineFixtures = preload("res://tests/test_online_ui.gd")
const OnlinePanelScript = preload("res://scripts/ui/online_panel.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const StoryCatalog = preload("res://scripts/story_catalog.gd")
const SIZES: Array[Vector2i] = [Vector2i(1360,880),Vector2i(390,844)]

class OfflineMain:
	extends Base.Fixture
	func _open_online() -> void:
		push_error("VISUAL AUDIT: actual OnlineApi is disabled; use FixtureApi")

var checks := 0
var failures := 0
var canvas: SubViewport
var screen
var capture_dir := ""
var capture_rows: Array[Dictionary] = []
var fixture_paths: Array[String] = []
var dimensions := Vector2i.ZERO
var only_ids: Array[String] = []

func _init() -> void: _run.call_deferred()
func check(ok: bool, description: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error("VISUAL AUDIT: "+description)

func _run() -> void:
	create_timer(300,true,false,true).timeout.connect(func(): push_error("VISUAL AUDIT timeout"); quit(1))
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): capture_dir=arg.trim_prefix("--capture-dir=")
		elif arg.begins_with("--only="):
			for id: String in arg.trim_prefix("--only=").split(",",false): only_ids.append("menu" if id=="main-menu" else id)
	if not capture_dir.is_empty():
		if not capture_dir.is_absolute_path() or DisplayServer.get_name()=="headless":
			push_error("Native renderer and absolute output directory required")
			quit(2)
			return
		DirAccess.make_dir_recursive_absolute(capture_dir)
	var directory := ProjectSettings.globalize_path("res://../../work/visual-system/fixtures").simplify_path()
	DirAccess.make_dir_recursive_absolute(directory)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(360,240)
	canvas=SubViewport.new()
	canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	for view: Vector2i in SIZES:
		dimensions=view
		canvas.size=view
		var path := directory.path_join("audit-%dx%d-%d.json" % [view.x,view.y,Time.get_ticks_usec()])
		fixture_paths.append(path)
		check(not FileAccess.file_exists(path),"Each viewport starts at a new disposable save")
		var seed_profile := Progress.new()
		seed_profile.load_save(path)
		check(seed_profile.select_character("mugo"),"Seed profile exists before safe Main boot")
		screen=OfflineMain.new()
		screen.fixture_path=path
		canvas.add_child(screen)
		screen.size=Vector2(view)
		screen._layout_interface(screen.size)
		_freeze(screen)
		if only_ids.is_empty() or _prefix_wanted("story-"): await _story_screens()
		if only_ids.is_empty() or _main_wanted(): await _main_screens()
		if only_ids.is_empty() or _prefix_wanted("online-"): await _online_screens()
		if _wanted("creation"): await _creator(directory)
		check(_http_count(screen)==0,"Main fixture never creates an HTTPRequest node")
		check(screen.session_save_path==path,"Main never replaces its explicit fixture path")
		screen.free()
		await process_frame
	if not capture_dir.is_empty():
		for view: Vector2i in SIZES: await _wall(view)
		var file := FileAccess.open(capture_dir.path_join("screens.json"),FileAccess.WRITE)
		check(file!=null,"Inventory manifest is writable")
		if file!=null:
			file.store_string(JSON.stringify({"checks":checks,"failures":failures,"fixture_paths":fixture_paths,"screens":capture_rows,"real_profiles_accessed":false,"network_used":false,"combat_note":"Deterministic synthetic initial HP for result fixtures; never described as a natural battle","capture_method":{"settle_frames":2,"transition_wait_seconds":0.3,"result_presentation_seconds":1.2,"frame_post_draw":true,"note":"After captures wait real time for UI transitions. Result fixtures additionally advance only Node2D presentation for 1.2s with Main/motor disabled and events/progress unchanged, then freeze. This is a UI wall, not a natural animation recording. Frozen Before results used two frames only and may show intermediate opacity; no Before image was replaced."}},"\t"))
			file.close()
	canvas.free()
	await process_frame
	print("VISUAL SCREEN AUDIT: %d checks, %d failures; %d %s" % [checks,failures,capture_rows.size(),"native screen captures" if not capture_dir.is_empty() else "surfaces visited (no rendering)"])
	quit(0 if failures==0 else 1)

func _freeze(node: Node) -> void:
	if node is Node2D: node.set_process(false)
	for child in node.get_children(): _freeze(child)

func _resume_presentation(node: Node) -> void:
	if node is Node2D: node.set_process(true)
	for child in node.get_children(): _resume_presentation(child)

func _http_count(node: Node) -> int:
	var count := 1 if node is HTTPRequest else 0
	for child in node.get_children(): count+=_http_count(child)
	return count

func _wanted(id: String) -> bool:
	return only_ids.is_empty() or id in only_ids

func _prefix_wanted(prefix: String) -> bool:
	for id: String in only_ids:
		if id.begins_with(prefix): return true
	return false

func _main_wanted() -> bool:
	for id: String in only_ids:
		if not id.begins_with("story-") and not id.begins_with("online-") and id!="creation": return true
	return false

func _story_screens() -> void:
	var model := CampaignFixtures.CampaignMemory.new()
	model.choose("mugo")
	model.data.chapter=2
	model.data.current_stage=4
	model.data.level=13
	model.data.xp=65
	model.data.points=6
	model.data.move_points=2
	model.data.perk_points=1
	model.data.allocations.attack=3
	model.data.last_hint="Tus golpes fallaron con frecuencia. Puedes revisar precisión antes de reintentar."
	model.sync_moves()
	var original := model.data.duplicate(true)
	var panel = StoryPanelScript.new()
	screen.add_child(panel)
	panel.configure(model)
	for tab: String in ["route","upgrades","moves","companions","legacy"]:
		panel.show_tab(tab)
		await _capture("story-"+tab,"Historia · "+{"route":"Ruta","upgrades":"Taller","moves":"Golpes","companions":"Refugio","legacy":"Legado pendiente"}[tab],"StoryPanel.show_tab(\""+tab+"\")","in_memory_campaign")
		check(panel._active_tab==tab,"Story navigates to "+tab)
		if tab=="upgrades":
			panel._open_respec_confirmation()
			check(is_instance_valid(panel._confirmation),"Respec confirmation is a real Story overlay")
			await _capture("story-respec","Historia · Redistribución","StoryPanel._open_respec_confirmation()","in_memory_campaign")
			panel._close_respec_confirmation()
		elif tab=="moves":
			panel._select_moves_section("perks")
			await _capture("story-perks","Historia · Talentos","StoryPanel._select_moves_section(perks)","in_memory_campaign")
	check(model.data==original,"Browsing Story and confirmation never modifies the fixture model")
	model.data.current_stage=8
	model.data.completed=true
	model.data.matches=22
	model.data.losses=6
	model.data.retries=6
	model.data.total_xp=2800
	panel.configure(model)
	panel.show_tab("legacy")
	await _capture("story-legacy-complete","Historia · Legado completado","StoryPanel.show_tab(\"legacy\") completed","in_memory_campaign")
	panel.free()
	await process_frame

func _main_screens() -> void:
	await _capture("arena-idle","Arena · Preparación","Main idle","disposable_local_profile")
	for entry: Array in [["menu","Menú principal","_show_menu"],["settings","Ajustes","_show_settings"],["training","Entrenamiento Liga","_show_training"],["profile","Ficha Liga","_show_fighter_details"],["help","Manual","_show_help"],["history-empty","Historial vacío","_show_history"],["log-empty","Registro vacío","_show_log"]]:
		if not _wanted(entry[0]): continue
		screen.call(entry[2])
		check(is_instance_valid(screen.modal_layer),"Actual Main modal opens: "+str(entry[0]))
		await _capture(entry[0],entry[1],"Main."+str(entry[2])+"()","disposable_local_profile")
		screen._close_modal()
		await process_frame
	if _wanted("roster"):
		screen._show_roster()
		await _capture("roster","Compañeros Liga","Main._show_roster()","disposable_local_profile")
		screen._close_roster()
		await process_frame
	if _wanted("customization"):
		screen._open_customization()
		await _capture("customization","Personalizar","Main._open_customization()","disposable_local_profile")
		for tab in [1,2,3]:
			screen.customization_layer.select_tab(tab)
			await _capture("customization-"+["body","color","effects","style"][tab],"Personalizar · "+["Cuerpo","Color","Efectos","Estilo"][tab],"CustomizationPanel.select_tab(%d)" % tab,"disposable_local_profile")
		screen._cancel_customization()
		await process_frame
	var needs_battle := only_ids.is_empty()
	for id: String in ["arena-active","surrender","result-victory","result-defeat","summary","history","log","replay"]:
		if id in only_ids: needs_battle=true
	if not needs_battle: return
	screen._start_fight()
	check(screen.active_match,"Arena starts through its actual action")
	screen.combat.start(screen._player_combatant(),screen.rival,84317,{"opening_time":0.2,"disable_signatures":true,"battle_id":"audit-battle"})
	screen._dispatch_events(screen.combat.advance(0.30))
	screen._refresh_combat_state()
	for actor in [screen.player_view,screen.rival_view]: actor._process(0.05)
	screen.combat_fx._process(0.05)
	await _capture("arena-active","Arena · Combate","Main event dispatch, manual engine time","deterministic_combat_fixture")
	screen._confirm_surrender()
	await _capture("surrender","Confirmar rendición","Main._confirm_surrender()","deterministic_combat_fixture")
	screen._close_modal()
	await process_frame
	for won: bool in [true,false]:
		if not screen.active_match: screen._start_fight()
		screen.combat.start(screen._player_combatant(),screen.rival,84318,{"initial_hp":{"rival":1.0} if won else {"player":1.0},"opening_time":0.2,"disable_signatures":true,"battle_id":"audit-result-"+str(won)+str(dimensions)})
		screen._dispatch_events(screen.combat.advance(120))
		while screen.active_match: await process_frame
		check(screen.result_panel.visible,"Result uses Main's actual finish handler")
		await _capture("result-victory" if won else "result-defeat","Resultado · Victoria" if won else "Resultado · Derrota","Main._finish_fight()","deterministic_initial_hp_fixture")
	for entry: Array in [["summary","Resumen de combate","_show_summary"],["history","Historial","_show_history"],["log","Registro","_show_log"]]:
		screen.call(entry[2])
		await _capture(entry[0],entry[1],"Main."+str(entry[2])+"()","deterministic_combat_fixture")
		screen._close_modal()
		await process_frame
	screen._show_replays()
	check(is_instance_valid(screen.replay_layer),"Recorded fixture battle can open Replay")
	await _capture("replay","Repetición","Main._show_replays()","actual_engine_record_fixture")
	screen._close_replays()
	await process_frame

func _online_screens() -> void:
	var api := OnlineFixtures.FixtureApi.new()
	screen.add_child(api)
	api.roster[0]["combatant"]={"combat_stats":Catalog.stats_for({"character_id":"mugo","level":12})}
	var panel = OnlinePanelScript.new()
	screen.add_child(panel)
	panel.configure(api)
	panel.set_process(false)
	for index in range(4):
		panel._select_tab(index)
		await _capture("online-"+["arena","story","profile","activity"][index],"Online · "+["Arena","Historia","Mi ficha","Actividad"][index],"OnlinePanel._select_tab("+str(index)+")","in_memory_api_no_http")
		if index==2:
			for section in [1,2,3]:
				panel._select_profile_section(section)
				await _capture("online-"+["attributes","techniques","perks","style"][section],"Online · "+["Atributos","Técnicas","Talentos","Estilo"][section],"OnlinePanel._select_profile_section(%d)" % section,"in_memory_api_no_http")
	api.rivals.clear()
	panel._select_tab(0)
	await _capture("online-empty","Online · Sin rivales","OnlinePanel with empty response","in_memory_api_no_http")
	panel._show_create()
	await _capture("online-create","Online · Crear luchador","OnlinePanel._show_create()","in_memory_api_no_http")
	panel._present_battle(api.battle_data)
	await _capture("online-replay","Online · Repetición y resultado","OnlinePanel._present_battle()","in_memory_api_no_http")
	panel._close_replay()
	api.signed_in=false
	panel._show_login()
	await _capture("online-login","Online · Acceso","OnlinePanel._show_login()","in_memory_api_no_http")
	api.device={"user_code":"ABCDEFGH"}
	panel._login_title.text="Un paso más"
	panel._login_copy.text="1. Confirma el código en el navegador.\n2. Regresa aquí; la sesión se abrirá sola."
	panel._auth_code.text="ABCDEFGH"
	panel._auth_help.hide()
	panel._auth_code.show()
	panel._auth_cancel.show()
	panel._login_button.text="Volver a abrir el navegador"
	await _capture("online-device","Online · Autorizar dispositivo","OnlinePanel pending UI fixture","in_memory_api_no_http")
	check(api.writes==0 and _http_count(panel)==0,"Online capture invokes no mutations, HTTP or real account")
	panel.free()
	api.free()
	await process_frame

func _creator(directory: String) -> void:
	screen.hide()
	var fresh := Base.FreshFixture.new()
	fresh.fixture_path=directory.path_join("creator-%d.json" % Time.get_ticks_usec())
	fixture_paths.append(fresh.fixture_path)
	canvas.add_child(fresh)
	fresh.size=Vector2(dimensions)
	fresh._layout_interface(fresh.size)
	check(fresh.progression.data.is_empty(),"Creator opens before any profile is created")
	await _capture("creation","Primera creación","Main._show_creation()","fresh_disposable_profile")
	check(fresh.progression.data.is_empty() and _http_count(fresh)==0,"Capturing creation neither creates a fighter nor accesses network")
	fresh.free()
	screen.show()
	await process_frame

func _capture(id: String, title: String, route: String, fixture: String) -> void:
	if not _wanted(id): return
	await process_frame
	await process_frame
	if not capture_dir.is_empty(): await create_timer(0.3,true,false,true).timeout
	var settled_visuals := false
	if not capture_dir.is_empty() and id in ["result-victory","result-defeat"]:
		var elapsed: float = screen.combat.elapsed
		var events: Array = screen.combat.event_log.duplicate(true)
		var profile: Dictionary = screen.progression.data.duplicate(true)
		check(not screen.is_processing(),"Result fixture keeps Main/motor manual during presentation settling")
		_resume_presentation(screen)
		await create_timer(1.2,true,false,true).timeout
		check(screen.combat.elapsed==elapsed and screen.combat.event_log==events,"Settling result visuals never advances motor/events")
		check(screen.progression.data==profile,"Settling result visuals never changes progress")
		settled_visuals = true
	_freeze(screen)
	var filename := "%s-%dx%d.png" % [id,dimensions.x,dimensions.y]
	if not capture_dir.is_empty():
		await RenderingServer.frame_post_draw
		if id in ["result-victory","result-defeat"]:
			check(screen.result_panel.modulate.a>=0.999,"Result transition completes naturally before capture: "+filename)
		check(canvas.get_texture().get_image().save_png(capture_dir.path_join(filename))==OK,"Captured "+filename)
	var capture := {"id":id,"title":title,"file":filename,"viewport":[dimensions.x,dimensions.y],"route":route,"fixture":fixture}
	if id in ["result-victory","result-defeat"]:
		capture["presentation_alpha"] = screen.result_panel.modulate.a
		capture["settled_visuals"] = settled_visuals
		capture["presentation_settle_seconds"] = 1.2 if settled_visuals else 0.0
	capture_rows.append(capture)

func _wall(view: Vector2i) -> void:
	var selected: Array[Dictionary] = []
	for row: Dictionary in capture_rows:
		if row.viewport==[view.x,view.y]: selected.append(row)
	if selected.is_empty(): return
	var columns := 4 if view.x>640 else 6
	var thumb := Vector2(340,220) if view.x>640 else Vector2(156,337.6)
	var margin := 24.0
	var cell := thumb+Vector2(16,44)
	var rows := ceili(float(selected.size())/columns)
	canvas.size=Vector2i(int(margin*2+cell.x*columns),int(78+cell.y*rows))
	var wall := Control.new()
	canvas.add_child(wall)
	var background := ColorRect.new()
	background.color=Color("091b21")
	background.size=Vector2(canvas.size)
	wall.add_child(background)
	var heading := Label.new()
	heading.text="BRASA · Auditoría visual · %dx%d · %d superficies" % [view.x,view.y,selected.size()]
	heading.position=Vector2(margin,20)
	heading.add_theme_font_size_override("font_size",23)
	heading.add_theme_color_override("font_color",Color("efd0a3"))
	wall.add_child(heading)
	for index in range(selected.size()):
		var row: Dictionary = selected[index]
		var at := Vector2(margin+(index%columns)*cell.x,66+(index/columns)*cell.y)
		var preview := TextureRect.new()
		preview.texture=ImageTexture.create_from_image(Image.load_from_file(capture_dir.path_join(row.file)))
		preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.position=at
		preview.size=thumb
		wall.add_child(preview)
		var label := Label.new()
		label.text=str(row.title)
		label.position=at+Vector2(0,thumb.y+5)
		label.size=Vector2(thumb.x,32)
		label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size",12 if view.x<640 else 14)
		label.add_theme_color_override("font_color",Color("c8dbd4"))
		wall.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	check(canvas.get_texture().get_image().save_png(capture_dir.path_join("wall-%dx%d.png" % [view.x,view.y]))==OK,"Saved native screenshot wall")
	wall.free()
	await process_frame
