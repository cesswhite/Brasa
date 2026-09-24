class_name OnlineSessionStore
extends Node
## macOS Keychain adapter. The ordinary JSON file contains presentation only.
const ORIGIN := "https://brasa-api-staging.acessloop.workers.dev"
const HINT_PATH := "user://brasa_online_hint.json"
const HELPER := "res://native/macos/brasa-session-store"
var _busy := false
var hint_path := HINT_PATH
var fixture_helper_args := PackedStringArray()

static func has_session_hint() -> bool:
	var hint: Variant = JSON.parse_string(FileAccess.get_file_as_string(HINT_PATH)) if FileAccess.file_exists(HINT_PATH) else {}
	return hint is Dictionary and hint.get("origin","") == ORIGIN and bool(hint.get("resume",false))

func hint() -> Dictionary:
	if not FileAccess.file_exists(hint_path): return {}
	var file := FileAccess.open(hint_path,FileAccess.READ)
	if file == null or file.get_length()>32768: return {}
	var value: Variant = JSON.parse_string(file.get_as_text())
	return value if value is Dictionary and value.get("origin","")==ORIGIN else {}

func remember_fighter(fighter: Dictionary) -> void:
	var value := hint()
	value["origin"] = ORIGIN
	# A display cache only; never used as identity, ownership or progression authority.
	value["fighter"] = {"archetype_id":str(fighter.get("archetype_id","nima")),"identity":{"display_name":str(fighter.get("identity",{}).get("display_name","Viajero")).left(24)},"appearance":fighter.get("appearance",{}).duplicate(true),"progression":{"level":clampi(int(fighter.get("progression",{}).get("level",1)),1,100)}}
	_write_hint(value)

func _write_hint(value: Dictionary) -> void:
	var file := FileAccess.open(hint_path,FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(value))

func read_session() -> Dictionary:
	return await _call("read")

func save_session(token: String, expires_at: float) -> bool:
	var response := await _call("write",{"token":token,"expires_at":expires_at})
	var value := hint()
	value.merge({"origin":ORIGIN,"resume":bool(response.get("ok",false))},true)
	_write_hint(value)
	return bool(response.get("ok",false))

func forget(clear_hint: bool = false) -> void:
	# Mark unavailable before touching the OS store: failed deletion cannot auto-restore.
	if clear_hint:
		_write_hint({"origin":ORIGIN,"resume":false})
	else:
		var value := hint()
		value["resume"] = false
		value["origin"] = ORIGIN
		_write_hint(value)
	await _call("delete")

func _call(operation: String, data: Dictionary = {}) -> Dictionary:
	if OS.get_name() != "macOS": return {"ok":false,"code":"UNAVAILABLE"}
	var executable := ProjectSettings.globalize_path(HELPER)
	# Exported macOS apps embed the signed helper beside the main executable.
	if not FileAccess.file_exists(executable): executable = OS.get_executable_path().get_base_dir().path_join("brasa-session-store")
	if not FileAccess.file_exists(executable): return {"ok":false,"code":"UNAVAILABLE"}
	while _busy: await get_tree().process_frame
	_busy = true
	var child := OS.execute_with_pipe(executable,fixture_helper_args,false)
	if child.is_empty():
		_busy = false
		return {"ok":false,"code":"UNAVAILABLE"}
	var pipe: FileAccess = child.stdio
	pipe.store_buffer((JSON.stringify({"operation":operation,"origin":ORIGIN,"data":data})+"\n").to_utf8_buffer())
	var bytes := PackedByteArray()
	var deadline := Time.get_ticks_msec()+5000
	while Time.get_ticks_msec()<deadline:
		var chunk: PackedByteArray = pipe.get_buffer(4096)
		bytes.append_array(chunk)
		if bytes.size()>16384 or bytes.has(10): break
		if not OS.is_process_running(int(child.pid)):
			bytes.append_array(pipe.get_buffer(4096))
			break
		await get_tree().process_frame
	if OS.is_process_running(int(child.pid)): OS.kill(int(child.pid))
	pipe.close()
	(child.stderr as FileAccess).close()
	_busy = false
	if bytes.size()>16384: return {"ok":false,"code":"UNAVAILABLE"}
	var result: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	return result if result is Dictionary else {"ok":false,"code":"UNAVAILABLE"}
