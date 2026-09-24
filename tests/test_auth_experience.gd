extends SceneTree
## Memory fixtures for server authority + isolated Keychain namespace for actual IPC.
const Api = preload("res://scripts/online_api.gd")
const Store = preload("res://scripts/online_session_store.gd")
var checks := 0
var failures := 0
class MemoryStore extends Node:
	var record: Variant = null
	var resume := true
	var deletes := 0
	var hold_write := false
	func hint() -> Dictionary: return {"resume":resume}
	func read_session() -> Dictionary: return {"ok":true,"data":record}
	func forget(_clear: bool = false) -> void: record=null;resume=false;deletes+=1
	func save_session(token: String,expiry: float) -> bool:
		if hold_write: await get_tree().process_frame
		record={"token":token,"expires_at":expiry,"origin":Api.DEFAULT_ORIGIN};resume=true;return true
class FixtureApi extends Api:
	var answer := {"ok":true,"status":200,"data":{"user":{"id":"server-owner"},"session":{}}}
	var requests := 0
	var held := false
	var candidate_not_authenticated := false
	func _request(_method: int,_path: String,_body: Dictionary = {},_key: String = "",_authenticated: bool = true,_raw_auth: bool = false) -> Dictionary:
		requests+=1
		candidate_not_authenticated=not is_authenticated()
		if held: await get_tree().process_frame
		return answer.duplicate(true)
var late: Dictionary = {}
func _init() -> void: _run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error("AUTH EXPERIENCE: "+message)
func make_api() -> FixtureApi:
	var api := FixtureApi.new();root.add_child(api)
	api.base_url=Api.DEFAULT_ORIGIN
	api.session_store=MemoryStore.new();api.add_child(api.session_store)
	api.session_store.record={"origin":Api.DEFAULT_ORIGIN,"token":"fixture-only-token-without-real-access","expires_at":Time.get_unix_time_from_system()+3600}
	return api
func _run() -> void:
	var api:=make_api()
	var result: Dictionary=await api.restore_session()
	check(result.ok and api.is_authenticated() and api.requests==1,"stored candidate validated by server before entering")
	check(api.candidate_not_authenticated,"local token alone never exposes authenticated state")
	check(api.auth_metrics.size()==1 and api.auth_metrics[0].keys().size()==2,"session metric contains only category and duration")
	api.free()
	api=make_api();api.session_store.record.expires_at=Time.get_unix_time_from_system()-1
	result=await api.restore_session();check(not result.ok and api.requests==0 and api.session_store.deletes==1,"expired local candidate cleared before network")
	api.free()
	api=make_api();api.session_store.resume=false
	result=await api.restore_session();check(not result.ok and api.requests==0,"signout tombstone prevents restoring leftover OS item")
	api.free()
	api=make_api();api.answer=Api._error("UNAUTHENTICATED","fixture raw error",401)
	result=await api.restore_session();check(not result.ok and not api.is_authenticated() and api.session_store.deletes==1,"server revocation rejects cached candidate")
	api.free()
	api=make_api();api.answer=Api._error("CONNECTION_FAILED","fixture network error")
	result=await api.restore_session();check(not result.ok and not api.is_authenticated() and api.session_store.deletes==0,"offline never grants entry or deletes a retryable saved session")
	api.free()
	api=make_api();api.session_store.record.token="bad\r\nAuthorization: injected"
	result=await api.restore_session();check(not result.ok and api.requests==0,"invalid stored token cannot enter headers")
	api.free()
	api=make_api();api.held=true;_restore_late(api);api.dispose_session();await process_frame;await process_frame
	check(late.get("error",{}).get("code","")=="CANCELLED" and not api.is_authenticated(),"cancelled restore cannot revive an account")
	api.free()
	api=make_api();api.session_store.hold_write=true
	api.answer={"ok":true,"data":{"access_token":"fixture-token-cancelled-during-storage","expires_in":3600}}
	api.device={"device_code":"fixture","expires_at_ms":Time.get_ticks_msec()+30000}
	_poll_late(api)
	check(not api.is_authenticated(),"credential being persisted is not yet an active session")
	api.cancel_auth();await process_frame;await process_frame
	check(late.get("error",{}).get("code","")=="CANCELLED" and not api.is_authenticated() and api.session_store.record==null and not api.session_store.resume,"cancel during secure write cannot resurrect a session")
	api.free()
	check(Api.decode_response(200,"null".to_utf8_buffer(),true).status==401,"expired browser-style null session maps to sign-in")
	if OS.get_name()=="macOS": await _keychain()
	print("AUTH EXPERIENCE: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
func _restore_late(api: FixtureApi) -> void: late=await api.restore_session()
func _poll_late(api: FixtureApi) -> void: late=await api.poll_device_token()
func _keychain() -> void:
	var store:=Store.new();root.add_child(store)
	store.hint_path="user://fixture_auth_hint_%s.json" % Api.new_key()
	store.fixture_helper_args=PackedStringArray(["--fixture-namespace",Api.new_key()])
	var saved:=await store.save_session("fixture-only-pipe-token-no-real-account",Time.get_unix_time_from_system()+120)
	check(saved,"nonblocking Godot IPC stores a test credential in its unique Keychain namespace")
	var readback:=await store.read_session()
	check(readback.get("ok",false) and readback.get("data",{}).get("token","")=="fixture-only-pipe-token-no-real-account","a fresh child process restores exactly the stored fixture")
	var hinttext:=FileAccess.get_file_as_string(store.hint_path)
	check(not hinttext.contains("token") and not hinttext.contains("fixture-only-pipe"),"ordinary hint file never stores a credential")
	await store.forget(true)
	readback=await store.read_session()
	check(readback.get("ok",false) and readback.get("data")==null,"signout deletes only the unique test Keychain item")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(store.hint_path));store.free()
