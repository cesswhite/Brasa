extends SceneTree
const OnlinePanelScript = preload("res://scripts/ui/online_panel.gd")
const Api = preload("res://scripts/online_api.gd")
const Cosmetics = preload("res://scripts/cosmetic_catalog.gd")
const Characters = preload("res://scripts/character_catalog.gd")
const Moves = preload("res://scripts/move_catalog.gd")
const Story = preload("res://scripts/story_catalog.gd")
const PLAYER_ID := "10000000-0000-4000-8000-000000000001"
const RIVAL_ID := "20000000-0000-4000-8000-000000000002"
const BATTLE_ID := "30000000-0000-4000-8000-000000000003"
const SIZES: Array[Vector2i] = [Vector2i(1360,880),Vector2i(1224,792),Vector2i(1920,1080),Vector2i(768,1024),Vector2i(390,844),Vector2i(430,932),Vector2i(844,390)]
var checks: int = 0
var failures: int = 0
var capture_dir: String = ""

class FixtureApi extends Node:
	var device: Dictionary = {}
	var pending_operation: Dictionary = {}
	var signed_in: bool = true
	var fail_next: bool = false
	var malformed_next: bool = false
	var next_error: Dictionary = {}
	var mutation_keys: Array = []
	var writes: int = 0
	var roster: Array = []
	var catalog_data: Dictionary = {}
	var battle_data: Dictionary = {}
	var rivals: Array = []
	func _init() -> void:
		var a := {"fighter_id":PLAYER_ID,"archetype_id":"mugo","revision":1,"progression_revision":4,"identity":{"display_name":"Ceniza"},"appearance":Cosmetics.default_appearance("balam"),"progression":{"level":12,"xp":65,"stat_points":3,"move_points":2,"perk_points":1,"allocations":{},"move_upgrades":{},"perks":[]},"online":{"rating":1042,"wins":4,"losses":2,"story_cleared":8,"ai_style":"balanced"}}
		var b: Dictionary = a.duplicate(true)
		b.fighter_id = RIVAL_ID
		b.archetype_id = "copal"
		b.identity.display_name = "Lumbre"
		b.appearance = Cosmetics.default_appearance("copal")
		b["difficulty"] = "similar"
		roster = [a]
		rivals = [b]
		catalog_data = {"characters":Characters.all_definitions(),"stat_options":Story.ALLOCATIONS.duplicate(true),"ai_styles":["balanced","aggressive","defensive"],"moves":{"mugo":Moves.moves_for("mugo")},"perks":{"mugo":Moves.perks_for("mugo")}}
		var first: Dictionary = Characters.definition("mugo")
		first.merge({"character_id":"mugo","name":"Ceniza","fighter_id":PLAYER_ID,"level":12,"appearance":a.appearance.duplicate(true),"identity":a.identity.duplicate(true),"combat_stats":{"max_hp":250}},true)
		var second: Dictionary = Characters.definition("copal")
		second.merge({"character_id":"copal","name":"Lumbre","fighter_id":RIVAL_ID,"level":12,"appearance":b.appearance.duplicate(true),"identity":b.identity.duplicate(true),"combat_stats":{"max_hp":250}},true)
		var move: Dictionary = Moves.moves_for("mugo")[0]
		var snapshot := {"version":1,"battle_id":BATTLE_ID,"player":first,"rival":second,"duration":2.0,"winner":"player","reason":"normal","events":[{"type":"move_started","side":"player","target":"rival","time":0.2,"move":move,"player_hp":250,"rival_hp":250},{"type":"attack","side":"player","target":"rival","time":0.2+float(move.impact_delay),"move_id":move.id,"result":"hit","damage":250,"player_hp":250,"rival_hp":0},{"type":"finished","time":2.0,"winner":"player","player_hp":250,"rival_hp":0}]}
		battle_data = {"id":BATTLE_ID,"mode":"arena","record":{"battle_snapshot":snapshot},"viewing_side":"player","rewards":{"player":{"xp_gained":40,"rating_change":12},"rival":{"xp_gained":25,"rating_change":-12}}}
	func is_authenticated() -> bool: return signed_in
	func cancel_auth() -> void: device.clear()
	func poll_seconds_remaining() -> float: return 10
	func me() -> Dictionary: return {"ok":true,"data":{"account_id":"fixture"}}
	func catalog() -> Dictionary: return {"ok":true,"data":catalog_data.duplicate(true)}
	func fighters() -> Dictionary: return {"ok":true,"data":{"fighters":roster.duplicate(true)}}
	func opponents(_id: String) -> Dictionary: return {"ok":true,"data":{"opponents":rivals.duplicate(true)}}
	func story(_id: String) -> Dictionary: return {"ok":true,"data":{"cleared":8,"complete":false,"next_stage":{"title":"El desfiladero rojo","description":"El siguiente encuentro pondrá a prueba tu defensa."}}}
	func offline_results() -> Dictionary: return {"ok":true,"data":{"results":[{"id":BATTLE_ID,"battle_id":BATTLE_ID,"fighter_name":"Ceniza","challenger_name":"Lumbre","won":true,"xp_gained":25,"rating_change":12}],"totals":{"battles":1,"wins":1,"losses":0,"xp":25,"rating_change":12}}}
	func history(_id: String,_cursor: String = "") -> Dictionary: return {"ok":true,"data":{"battles":[{"id":BATTLE_ID,"player_name":"Ceniza","rival_name":"Lumbre","winner":"player","mode":"arena","viewing_side":"player"}],"next_cursor":null}}
	func battle(_id: String) -> Dictionary: return {"ok":true,"data":{"battle":battle_data.duplicate(true),"fighter":roster[0].duplicate(true)}}
	func create_battle(_id: String,_opponent: String,key: String) -> Dictionary:
		mutation_keys.append(key)
		if not next_error.is_empty():
			var response: Dictionary = next_error.duplicate(true)
			next_error.clear()
			return response
		if malformed_next:
			malformed_next = false
			return Api._error("INVALID_RESPONSE","El servicio devolvió datos inválidos.",200)
		if fail_next:
			fail_next = false
			return Api._error("CONNECTION_FAILED","No llegó la respuesta.")
		writes += 1
		return await battle(BATTLE_ID)
	func allocate(_id: String,_stat: String,_amount: int,revision: int,key: String) -> Dictionary:
		mutation_keys.append(key)
		if revision != 4: return Api._error("REVISION_CONFLICT","Revisión equivocada.",409)
		writes += 1
		roster[0].progression.stat_points = 2
		return {"ok":true,"data":{"fighter":roster[0].duplicate(true)}}
	func set_ai(_id: String,style: String,revision: int,key: String) -> Dictionary:
		mutation_keys.append(key)
		if revision != 4: return Api._error("REVISION_CONFLICT","Revisión equivocada.",409)
		writes += 1
		roster[0].online.ai_style = style
		return {"ok":true,"data":{"fighter":roster[0].duplicate(true)}}
	func owned() -> Dictionary:
		var owned: Array = []
		for id: String in Cosmetics.default_owned(): owned.append({"inventory_id":id})
		return {"ok":true,"data":{"owned":owned}}
	func update_fighter(_id: String,revision: int,display_name: String,appearance: Dictionary,key: String) -> Dictionary:
		mutation_keys.append(key)
		if revision != 1: return Api._error("REVISION_CONFLICT","Revisión equivocada.",409)
		writes += 1
		roster[0].identity.display_name = display_name
		roster[0].appearance = appearance.duplicate(true)
		return {"ok":true,"data":roster[0].duplicate(true)}
	func sign_out() -> Dictionary:
		signed_in = false
		return {"ok":true,"data":{}}

func _init() -> void: _run.call_deferred()
func _check(ok: bool,message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ONLINE UI: "+message)
func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): capture_dir = arg.trim_prefix("--capture-dir=")
	if not capture_dir.is_empty():
		_check(capture_dir.is_absolute_path() and DisplayServer.get_name() != "headless","explicit native capture directory")
		DirAccess.make_dir_recursive_absolute(capture_dir)
	await _actions()
	for viewport_size: Vector2i in SIZES: await _viewport(viewport_size)
	print("ONLINE UI: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
func _actions() -> void:
	var api := FixtureApi.new()
	root.add_child(api)
	var panel = OnlinePanelScript.new()
	root.add_child(panel)
	panel.configure(api)
	await process_frame
	_check(panel._fighter.fighter_id == PLAYER_ID,"loads server fighter")
	_check(panel._opponents.size() == 1,"uses actual returned rival list")
	api.fail_next = true
	await panel._challenge(RIVAL_ID)
	_check(not api.pending_operation.is_empty(),"lost response retains exact operation")
	var key: String = str(api.mutation_keys[0])
	await panel._retry_pending()
	_check(api.mutation_keys.size() == 2 and str(api.mutation_keys[1]) == key,"retry reuses idempotency key")
	_check(api.pending_operation.is_empty() and is_instance_valid(panel._replay),"confirmed server result starts event replay")
	_check(api.writes == 1,"replaying result never awards or submits another write")
	panel._close_replay()
	api.malformed_next = true
	await panel._challenge(RIVAL_ID)
	_check(not api.pending_operation.is_empty(),"malformed HTTP success keeps possibly committed operation")
	var malformed_key: String = str(api.mutation_keys.back())
	await panel._retry_pending()
	_check(str(api.mutation_keys.back()) == malformed_key,"malformed response retry also preserves its operation key")
	panel._close_replay()
	api.next_error = Api._error("FIGHTER_BUSY","El luchador está recibiendo otro resultado.",409)
	await panel._challenge(RIVAL_ID)
	_check(not api.pending_operation.is_empty(),"busy fighter conflict keeps retryable operation")
	var busy_key: String = str(api.mutation_keys.back())
	await panel._retry_pending()
	_check(str(api.mutation_keys.back()) == busy_key,"busy fighter retry preserves its operation key")
	panel._close_replay()
	api.next_error = Api._error("FIGHTER_EXISTS","Ya existe un luchador de ese arquetipo.",409)
	await panel._challenge(RIVAL_ID)
	_check(api.pending_operation.is_empty() and panel._notice.text.begins_with("Ya existe"),"known conflict preserves server explanation without revision warning")
	await panel._allocate("attack")
	_check(panel._fighter.progression.stat_points == 2,"only authoritative returned points update UI")
	await panel._choose_ai("defensive")
	_check(panel._fighter.online.ai_style == "defensive","AI update uses progression revision")
	await panel._open_customization()
	var before: int = api.writes
	panel._customizer._choose_item("body_style_id","copal")
	panel._close_customization()
	_check(api.writes == before and panel._fighter.appearance.body_style_id == "balam","remote cosmetic cancel never writes")
	await panel._open_customization()
	await panel._confirm_cosmetic("mugo","Ceniza nueva",Cosmetics.default_appearance("copal"))
	_check(panel._fighter.identity.display_name == "Ceniza nueva" and panel._fighter.appearance.body_style_id == "copal","remote editor replaces profile only after server success")
	api.battle_data.viewing_side = "rival"
	panel._present_battle(api.battle_data)
	_check(panel._replay._picker.get_item_text(0).begins_with("Derrota") and panel._replay._note.text.contains("+25 XP"),"defender replay uses viewer outcome and reward")
	panel._close_replay()
	panel.queue_free()
	api.queue_free()
	await process_frame
func _viewport(viewport_size: Vector2i) -> void:
	var canvas := SubViewport.new()
	canvas.size = viewport_size
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	var api := FixtureApi.new()
	canvas.add_child(api)
	var panel = OnlinePanelScript.new()
	canvas.add_child(panel)
	panel.configure(api)
	for index in range(4):
		panel._select_tab(index)
		await process_frame
		await process_frame
		_layout_checks(panel,viewport_size)
		if not capture_dir.is_empty(): await _capture(canvas,"%dx%d-tab%d.png" % [viewport_size.x,viewport_size.y,index])
	api.rivals.clear()
	panel._select_tab(0)
	await process_frame
	_check(panel._opponents.is_empty(),"empty server pool never invents bots")
	panel._show_create()
	await process_frame
	_layout_checks(panel,viewport_size)
	_check(panel._create_base.item_count == api.catalog_data.characters.size(),"create uses the complete server character catalog")
	for id: String in ["onix","bruma"]:
		var cat_index: int = Characters.IDS.find(id)
		panel._create_base.select(cat_index)
		panel._preview_creation(cat_index)
		_check(str(panel._create_base.get_selected_metadata())==id and panel._name.text==str(Characters.definition(id).name),"Online creation offers "+id)
		_check(panel._actor.get_sprite_geometry().get("path","")=="res://assets/sprites/%s-v1.png" % id,"Online creation previews the cat's own art")
	panel._create_base.select(1)
	panel._preview_creation(1)
	_check(panel._name.text == str(api.catalog_data.characters[1].name),"creation preview follows chosen server archetype")
	if not capture_dir.is_empty(): await _capture(canvas,"%dx%d-create.png" % [viewport_size.x,viewport_size.y])
	panel._present_battle(api.battle_data)
	await process_frame
	if not capture_dir.is_empty(): await _capture(canvas,"%dx%d-battle.png" % [viewport_size.x,viewport_size.y])
	panel._close_replay()
	api.signed_in = false
	panel._show_login()
	await process_frame
	await process_frame
	var bounds := Rect2(Vector2.ZERO,Vector2(viewport_size))
	_check(bounds.encloses(panel._login_button.get_global_rect()),"login button is visible")
	if not capture_dir.is_empty(): await _capture(canvas,"%dx%d-login.png" % [viewport_size.x,viewport_size.y])
	api.device = {"user_code":"ABCDEFGH"}
	panel._auth_code.text = "Código: ABCDEFGH\nEsperando autorización en tu navegador…"
	panel._auth_code.show()
	panel._auth_cancel.show()
	panel._login_button.text = "Volver a abrir el navegador"
	await process_frame
	await process_frame
	_check(bounds.encloses(panel._auth_cancel.get_global_rect()),"authorization cancel is visible")
	_check(not panel._auth_cancel.get_global_rect().intersects(panel._notice.get_global_rect()),"authorization does not overlap status")
	if not capture_dir.is_empty(): await _capture(canvas,"%dx%d-auth-pending.png" % [viewport_size.x,viewport_size.y])
	canvas.queue_free()
	await process_frame
func _layout_checks(panel: Control,viewport_size: Vector2i) -> void:
	var bounds := Rect2(Vector2.ZERO,Vector2(viewport_size))
	for control: Control in [panel._title,panel._close,panel._toolbar,panel._preview,panel._body,panel._tabs,panel._scroll,panel._notice]:
		_check(bounds.grow(0.1).encloses(control.get_global_rect()),control.name+" fits viewport")
	_check(not panel._preview.get_global_rect().intersects(panel._body.get_global_rect()),"preview and controls stay separate")
	for button: Button in panel._tab_buttons:
		_check(button.size.y >= 40 and button.size.x >= 40,"tabs have usable touch targets")
	for button: Button in panel._buttons:
		_check(button.get_global_rect().end.x <= panel._scroll.get_global_rect().end.x+0.1,"actions never overflow horizontally")
func _capture(canvas: SubViewport,filename: String) -> void:
	await RenderingServer.frame_post_draw
	_check(canvas.get_texture().get_image().save_png(capture_dir.path_join(filename)) == OK,"save native "+filename)
