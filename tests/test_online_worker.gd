extends SceneTree
## Real local Worker+D1 via work/online/worker_harness.mjs. Disposable accounts only.
const Api = preload("res://scripts/online_api.gd")
const PanelScript = preload("res://scripts/ui/online_panel.gd")
const Cosmetics = preload("res://scripts/cosmetic_catalog.gd")
const Characters = preload("res://scripts/character_catalog.gd")
const Records = preload("res://scripts/battle_identity.gd")
var checks: int = 0
var failures: int = 0
var output_dir: String = ""

func _init() -> void: _run.call_deferred()
func _check(ok: bool,message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ONLINE WORKER: "+message)
func _run() -> void:
	var path: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--credential="): path = arg.trim_prefix("--credential=")
		if arg.begins_with("--capture-dir="): output_dir = arg.trim_prefix("--capture-dir=")
	if not path.is_absolute_path() or not FileAccess.file_exists(path):
		push_error("Pass --credential=/absolute/disposable/fixture.json")
		quit(1)
		return
	var credential: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var first := Api.new()
	var second := Api.new()
	root.add_child(first)
	root.add_child(second)
	_check(first.configure({"base_url":credential.base_url,"allow_local_test":true}),"first explicit loopback configuration")
	_check(second.configure({"base_url":credential.base_url,"allow_local_test":true}),"second explicit loopback configuration")
	_check(first.authenticate_local_test(str(credential.first.token)) and second.authenticate_local_test(str(credential.second.token)),"disposable developer sessions in memory")
	var me: Dictionary = await first.me()
	_check(me.ok and me.data.account_id == credential.first.account_id,"real Worker authenticates account")
	var created: Dictionary = await first.create_fighter("mugo","Ceniza",Api.new_key())
	var other: Dictionary = await second.create_fighter("mugo","Lumbre",Api.new_key())
	_check(created.ok and other.ok,"two persistent fighters created on real D1")
	if not created.ok or not other.ok:
		print("ONLINE WORKER: fixture creation failed, stop without touching other accounts")
		quit(1)
		return
	var player: Dictionary = created.data
	var rival: Dictionary = other.data
	var catalog: Dictionary = await first.catalog()
	_check(catalog.ok and catalog.data.characters.size()==Characters.IDS.size() and catalog.data.story_stages.size()==100,"real complete game catalog")
	var pool: Dictionary = await first.opponents(str(player.fighter_id))
	_check(pool.ok and pool.data.opponents.size()==1 and pool.data.opponents[0].fighter_id==rival.fighter_id,"matchmaking returns other actual account")
	var allocated: Dictionary = await first.allocate(str(player.fighter_id),"attack",1,int(player.progression_revision),Api.new_key())
	_check(allocated.ok and int(allocated.data.fighter.progression.stat_points)==2,"stat intent commits to server")
	player = allocated.data.fighter
	var styled: Dictionary = await first.set_ai(str(player.fighter_id),"defensive",int(player.progression_revision),Api.new_key())
	_check(styled.ok and styled.data.fighter.online.ai_style=="defensive","offline AI style is authoritative")
	player = styled.data.fighter
	var key: String = Api.new_key()
	var battle: Dictionary = await first.create_battle(str(player.fighter_id),str(rival.fighter_id),key)
	_check(battle.ok,"server resolves automatic real-player challenge")
	if not battle.ok:
		push_error(str(battle.get("error",{})))
		quit(1)
		return
	var replayed_request: Dictionary = await first.create_battle(str(player.fighter_id),str(rival.fighter_id),key)
	_check(replayed_request.ok and replayed_request.data.battle.id==battle.data.battle.id,"duplicate challenge returns same battle")
	_check(not Records.snapshot(battle.data.battle.record).is_empty(),"authoritative event record passes actual replay validation")
	var descriptor: Dictionary = Records.snapshot(battle.data.battle.record).player
	_check(descriptor.fighter_id==player.fighter_id and descriptor.name=="Ceniza","server snapshot keeps actual fighter identity")
	var history: Dictionary = await first.history(str(player.fighter_id))
	_check(history.ok and history.data.battles.size()==1,"idempotent retry adds only one history row")
	var defense: Dictionary = await second.battle(str(battle.data.battle.id))
	_check(defense.ok and defense.data.battle.viewing_side=="rival","defender can retrieve own perspective")
	var offline: Dictionary = await second.offline_results()
	_check(offline.ok and int(offline.data.totals.battles)==1,"defensive result persists while owner was inactive")
	var ids: Array = [str(offline.data.results[0].id)]
	var ack_key: String = Api.new_key()
	var ack: Dictionary = await second.acknowledge(ids,ack_key)
	var ack_again: Dictionary = await second.acknowledge(ids,ack_key)
	_check(ack.ok and ack_again.ok,"offline acknowledgement is repeatable")
	var clear: Dictionary = await second.offline_results()
	_check(clear.ok and int(clear.data.totals.battles)==0,"acknowledged results do not return as new")
	await create_timer(3.1).timeout
	var route: Dictionary = await first.story(str(player.fighter_id))
	_check(route.ok and int(route.data.next_stage.global_level)==1,"online Story starts at first encounter")
	var story: Dictionary = await first.story_battle(str(player.fighter_id),Api.new_key())
	_check(story.ok and story.data.battle.mode=="story","Story uses same authoritative battle response")
	var panel = PanelScript.new()
	root.add_child(panel)
	panel.configure(first)
	await _settle(panel)
	_check(panel._fighter.fighter_id==player.fighter_id and panel._catalog.characters.size()==Characters.IDS.size(),"real API drives integrated online panel")
	panel._select_tab(2)
	await _settle(panel)
	_check(panel._buttons.size()>10,"real server builds populate training, moves, talents and AI")
	await panel._open_customization()
	_check(is_instance_valid(panel._customizer),"actual owned inventory configures same cosmetic editor")
	var before: Dictionary = panel._fighter.progression.duplicate(true)
	await panel._confirm_cosmetic("mugo","Ceniza online",Cosmetics.default_appearance("copal"))
	_check(panel._fighter.identity.display_name=="Ceniza online" and panel._fighter.appearance.body_style_id=="copal","cosmetic edit roundtrips through actual Worker")
	var authoritative: Dictionary = await first.fighters()
	_check(authoritative.data.fighters[0].progression==before,"remote cosmetics preserve progression including derived display fields")
	_check(panel._fighter.has("online") and panel._fighter.has("combatant"),"cosmetic response retains complete online DTO for UI")
	panel._select_tab(3)
	await _settle(panel)
	_check(panel._history.size()==2,"panel shows both Arena and Story server history")
	if not output_dir.is_empty():
		_check(DisplayServer.get_name()!="headless" and output_dir.is_absolute_path(),"native isolated output destination")
		DirAccess.make_dir_recursive_absolute(output_dir)
		await RenderingServer.frame_post_draw
		_check(root.get_texture().get_image().save_png(output_dir.path_join("worker-online.png"))==OK,"real Worker UI capture saved")
	panel.free()
	first.dispose_session()
	second.dispose_session()
	first.queue_free()
	second.queue_free()
	await process_frame
	print("ONLINE WORKER: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
func _settle(panel: Control) -> void:
	for index in range(1000):
		if not panel._busy and not panel._loading_account: break
		await create_timer(0.01).timeout
	await process_frame
	await process_frame
	_check(not panel._busy and not panel._loading_account,"online request reached stable UI")
