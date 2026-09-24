extends SceneTree
const Integration = preload("res://tests/test_identity_integration.gd")
const Records = preload("res://scripts/battle_identity.gd")
const Api = preload("res://scripts/identity_api.gd")
const Progress = preload("res://scripts/progression.gd")
const EngineScript = preload("res://scripts/combat_engine.gd")
const Cosmetics = preload("res://scripts/cosmetic_catalog.gd")
const Replay = preload("res://scripts/ui/battle_replay_panel.gd")
class WriteFailure:
	extends "res://scripts/progression.gd"
	func save() -> bool:
		last_save_ok = false
		return false
var checks := 0
var failures := 0
func _init() -> void: _run.call_deferred()
func check(value: bool, detail: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("IDENTITY EDGES: "+detail)
func _run() -> void:
	for invalid: Dictionary in [{"data":null},{"data":[]},{"data":"wrong"},{"error":"wrong"},{"error":null},{"error":{"code":3,"message":"wrong"}}]:
		var status := 200 if invalid.has("data") else 422
		var response := Api.decode_response(status,JSON.stringify(invalid).to_utf8_buffer())
		check(not response.ok and response.error.code=="INVALID_RESPONSE", "Malformed HTTP data is rejected safely")
	check(Api.decode_response(200,'{"data":{"revision":2}}'.to_utf8_buffer()).ok,"Valid HTTP response remains accepted")
	var directory := ProjectSettings.globalize_path("res://../../work/identity/edge-fixtures").simplify_path()
	DirAccess.make_dir_recursive_absolute(directory)
	var stamp := str(Time.get_ticks_usec())
	var failed = Integration.FreshFixture.new()
	failed.fixture_path = directory.path_join("write_failure_"+stamp+".json")
	failed.progression = WriteFailure.new()
	failed.league_progression = failed.progression
	root.add_child(failed)
	failed.size = Vector2(1224,792)
	failed._layout_interface(failed.size)
	failed.customization_layer.confirmed.emit("tepa","Sin perder",Cosmetics.default_appearance("tepa"))
	check(is_instance_valid(failed.customization_layer) and not failed.story_mode, "Gameplay write failure keeps creator open before Story")
	check(failed.progression.data.is_empty() and failed.progression.roster.is_empty(), "Failed creation rolls back the unsaved profile")
	check(not FileAccess.file_exists(failed.fixture_path), "Failed gameplay write creates no fake save")
	failed.queue_free()
	await process_frame
	var protected_path := directory.path_join("protected_"+stamp+".json")
	var league := Progress.new()
	league.load_save(protected_path)
	league.select_character("tepa")
	var corrupt := FileAccess.open(protected_path+".identity.json",FileAccess.WRITE)
	corrupt.store_string('{"version":999}')
	corrupt.close()
	var protected_game = Integration.Fixture.new()
	protected_game.fixture_path = protected_path
	root.add_child(protected_game)
	protected_game.size = Vector2(1224,792)
	protected_game._layout_interface(protected_game.size)
	check(protected_game.fighter_identity.save_blocked,"Corrupt sidecar is protected")
	protected_game._choose_character("mugo","Mugo")
	check(protected_game.progression.active_id=="mugo", "Protected identity does not break existing gameplay selection")
	check(FileAccess.get_file_as_string(protected_path+".identity.json")=='{"version":999}',"Protected identity file remains byte-identical")
	protected_game.queue_free()
	await process_frame
	var player := Progress._combatant(Progress._new_profile("tepa"))
	player["fighter_id"] = "edge-test"
	player["appearance"] = Cosmetics.default_appearance("tepa")
	player["identity"] = {"display_name":"Tepa"}
	var engine := EngineScript.new()
	engine.start(player,Progress._combatant(Progress._new_profile("balam")),993)
	engine.advance(120)
	var record: Dictionary = {}
	Records.attach(record,engine.summary())
	check(not Records.snapshot(record).is_empty(),"Complete recorded battle is replayable")
	for key: String in ["player", "rival", "winner", "events", "duration"]:
		var invalid := record.duplicate(true)
		invalid.battle_snapshot.erase(key)
		check(Records.snapshot(invalid).is_empty(),"Incomplete replay missing "+key+" is skipped")
	for change: Dictionary in [{"events":[1]},{"events":[{"type":"attack","time":-1}]},{"events":[{"type":"finished","time":1,"winner":"third"}]},{"events":[{"type":"move_started","time":1,"move":{"windup":{}}}]},{"winner":"third"},{"player":{}}]:
		var invalid := record.duplicate(true)
		invalid.battle_snapshot.merge(change,true)
		check(Records.snapshot(invalid).is_empty(),"Malformed event or participant is skipped without erasing history")
	var replay := Replay.new()
	root.add_child(replay)
	replay.configure([record])
	replay.actors.rival.reset_pose()
	replay._apply_event({"type":"attack","side":"player","target":"rival","result":"dodge"})
	check(replay.actors.rival._mode=="dodge","Recorded dodge shows dodge gesture")
	replay.actors.rival.reset_pose()
	replay._apply_event({"type":"attack","side":"player","target":"rival","result":"miss"})
	check(replay.actors.rival._mode=="idle","Recorded miss does not invent a received hit")
	replay._apply_event({"type":"attack","side":"player","target":"rival","result":"signature"})
	check(replay.actors.rival._mode=="reaction" and replay.actors.rival._reaction_kind=="knockdown" and replay.actors.rival._critical and replay.actors.rival._hit_flash_critical,"Signature retains critical feedback and its illustrated knockdown reaction")
	replay.queue_free()
	await process_frame
	print("IDENTITY EDGES: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
