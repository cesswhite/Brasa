class_name OnlineApi
extends Node
## Sessions use macOS Keychain when available, memory elsewhere. No local progression is uploaded.
const SessionStore = preload("res://scripts/online_session_store.gd")
signal session_changed
signal auth_changed
const DEFAULT_ORIGIN := "https://brasa-api-staging.acessloop.workers.dev"
const CLIENT_ID := "brasa-godot"
class Pending extends RefCounted:
	signal done(response: Dictionary)

var base_url: String = ""
var connected: bool = false
var generation: int = 0
var device: Dictionary = {}
var pending_operation: Dictionary = {}
var _token: String = ""
var _expires_at: int = 0
var _next_poll: int = 0
var _polling: bool = false
var _local_test: bool = false
var _requests: Dictionary = {}
var session_store: Node
var _restore_attempted := false
var _restoring := false
var _persisted := false
var auth_metrics: Array[Dictionary] = []

func configure(config: Dictionary) -> bool:
	var candidate: String = str(config.get("base_url", DEFAULT_ORIGIN)).trim_suffix("/")
	var local := RegEx.new()
	local.compile("^http://(127\\.0\\.0\\.1|localhost):([0-9]{1,5})$")
	var match_value: RegExMatch = local.search(candidate)
	var local_allowed: bool = bool(config.get("allow_local_test", false)) and match_value != null and int(match_value.get_string(2)) >= 1 and int(match_value.get_string(2)) <= 65535
	if candidate != DEFAULT_ORIGIN and not local_allowed: return false
	dispose_session()
	base_url = candidate
	_local_test = local_allowed
	_restore_attempted = false
	if not _local_test and is_inside_tree() and not is_instance_valid(session_store):
		session_store = SessionStore.new()
		add_child(session_store)
	return true

func configure_from_file(path: String = "res://data/online_config.json") -> bool:
	if not FileAccess.file_exists(path): return configure({"base_url":DEFAULT_ORIGIN})
	var config: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return configure(config) if config is Dictionary else false

func returning_fighter() -> Dictionary:
	if not is_instance_valid(session_store): return {}
	return session_store.hint().get("fighter",{}).duplicate(true)

func remember_fighter(fighter: Dictionary) -> void:
	if is_instance_valid(session_store) and is_authenticated(): session_store.remember_fighter(fighter)

func _metric(event: String, duration_ms: int = 0) -> void:
	auth_metrics.append({"event":event,"duration_ms":duration_ms})
	if auth_metrics.size()>40: auth_metrics.pop_front()

func restore_session() -> Dictionary:
	if is_authenticated(): return {"ok":true,"data":{}}
	if _restoring: return _error("WAIT","Entrando…")
	if not is_instance_valid(session_store) or _local_test: return _error("NO_SESSION","Continúa para entrar.")
	if not bool(session_store.hint().get("resume",false)): return _error("NO_SESSION","Continúa para entrar.")
	_restoring = true
	_restore_attempted = true
	var stamp := generation
	var started := Time.get_ticks_msec()
	var stored: Dictionary = await session_store.read_session()
	if stamp != generation:
		_restoring = false
		return _error("CANCELLED","El acceso se canceló.")
	var record: Variant = stored.get("data")
	if not stored.get("ok",false) or not record is Dictionary:
		_restoring = false
		return _error("NO_SESSION","Continúa para entrar.")
	var remaining := float(record.get("expires_at",0))-Time.get_unix_time_from_system()
	if record.get("origin","") != base_url or not _valid_token(record.get("token")) or remaining<=0 or remaining>604860:
		await session_store.forget()
		_restoring = false
		return _error("NO_SESSION","Continúa para entrar.")
	# A stored token is only a candidate. The server verifies it before any account UI.
	_token = str(record.token)
	_expires_at = Time.get_ticks_msec()+int(remaining*1000)
	var verified: Dictionary = await _request(HTTPClient.METHOD_GET,"/api/auth/get-session",{},"",true,true)
	_restoring = false
	if stamp != generation: return _error("CANCELLED","El acceso se canceló.")
	if not verified.ok or not verified.get("data",{}).get("user") is Dictionary:
		_token = ""
		_expires_at = 0
		if verified.get("status",0) in [200,401]: await session_store.forget()
		return verified if not verified.ok else _error("NO_SESSION","Continúa para entrar.")
	_persisted = true
	_metric("session_restored",Time.get_ticks_msec()-started)
	session_changed.emit()
	return {"ok":true,"data":{}}

func is_authenticated() -> bool:
	return not _restoring and not _token.is_empty() and (_expires_at == 0 or Time.get_ticks_msec() < _expires_at)

func authenticate_local_test(token: String) -> bool:
	if not _local_test or token.length() < 20 or token.contains("\r") or token.contains("\n"): return false
	_token = token
	_expires_at = 0
	session_changed.emit()
	return true

func dispose_session() -> void:
	generation += 1
	_token = ""
	_expires_at = 0
	device.clear()
	pending_operation.clear()
	_polling = false
	_cancel_requests()
	session_changed.emit()
	auth_changed.emit()

func cancel_auth() -> void:
	generation += 1
	device.clear()
	_polling = false
	_cancel_requests()
	auth_changed.emit()

func _cancel_requests() -> void:
	var requests: Dictionary = _requests.duplicate()
	_requests.clear()
	for record: Dictionary in requests.values():
		record.http.cancel_request()
		record.http.queue_free()
		record.pending.done.emit(_error("CANCELLED", "La solicitud se canceló."))

func authorize_device() -> Dictionary:
	cancel_auth()
	var result: Dictionary = await _request(HTTPClient.METHOD_POST, "/api/auth/device/code", {"client_id":CLIENT_ID}, "", false, true)
	if not result.ok: return result
	var info: Dictionary = result.data
	for field: String in ["device_code","user_code","verification_uri","verification_uri_complete"]:
		if not info.get(field) is String or str(info[field]).is_empty(): return _error("INVALID_RESPONSE", "La autorización recibida no es válida.")
	if not trusted_browser_url(str(info.verification_uri_complete)): return _error("UNSAFE_AUTH_URL", "La dirección de autorización no pertenece al servicio.")
	var expires: int = int(info.get("expires_in", 0))
	if expires <= 0 or expires > 3600: return _error("INVALID_RESPONSE", "La autorización no tiene una caducidad válida.")
	device = info.duplicate(true)
	device["interval"] = clampi(int(info.get("interval", 5)), 1, 60)
	device["expires_at_ms"] = Time.get_ticks_msec() + expires * 1000
	_next_poll = Time.get_ticks_msec() + int(device.interval) * 1000
	auth_changed.emit()
	return result

func trusted_browser_url(url: String) -> bool:
	var path: String = base_url + "/device"
	return not base_url.is_empty() and (url == path or url.begins_with(path + "?")) and not url.contains("\n") and not url.contains("\r") and not url.contains("\\") and url.length() <= 2048

func verification_url() -> String:
	return str(device.get("verification_uri_complete", ""))

func poll_seconds_remaining() -> float:
	return maxf(0.0, float(_next_poll - Time.get_ticks_msec()) / 1000.0)

func poll_device_token() -> Dictionary:
	if device.is_empty(): return _error("NO_AUTHORIZATION", "Inicia una autorización nueva.")
	if Time.get_ticks_msec() >= int(device.expires_at_ms):
		cancel_auth()
		return _error("expired_token", "El código ha caducado. Inicia sesión otra vez.")
	if _polling or poll_seconds_remaining() > 0: return _error("WAIT", "Esperando autorización.")
	_polling = true
	var own_generation: int = generation
	var response: Dictionary = await _request(HTTPClient.METHOD_POST, "/api/auth/device/token", {"grant_type":"urn:ietf:params:oauth:grant-type:device_code","device_code":device.device_code,"client_id":CLIENT_ID}, "", false, true)
	if own_generation != generation: return _error("CANCELLED", "La autorización se canceló.")
	_polling = false
	if response.ok:
		if not _valid_token(response.data.get("access_token")) or int(response.data.get("expires_in",0))<1 or int(response.data.get("expires_in",0))>604800: return _error("INVALID_RESPONSE", "La sesión recibida no es válida.")
		var accepted_token := str(response.data.access_token)
		var accepted_expiry := Time.get_ticks_msec() + maxi(1, int(response.data.get("expires_in", 3600))) * 1000
		device.clear()
		if is_instance_valid(session_store) and not _local_test:
			_persisted = await session_store.save_session(accepted_token,Time.get_unix_time_from_system()+float(maxi(1,int(response.data.get("expires_in",3600)))))
			if own_generation != generation:
				# A closed authorization must not become a resumable session later.
				if _token.is_empty(): await session_store.forget(true)
				return _error("CANCELLED","El acceso se canceló.")
		_token = accepted_token
		_expires_at = accepted_expiry
		_metric("login_success")
		session_changed.emit()
		auth_changed.emit()
	else:
		if str(response.error.code) == "slow_down": device.interval = mini(60, int(device.interval) + 5)
		_next_poll = Time.get_ticks_msec() + int(device.get("interval", 5)) * 1000
		if str(response.error.code) in ["access_denied","expired_token"]: device.clear()
	return response

func sign_out() -> Dictionary:
	var own_generation: int = generation
	var response: Dictionary = await _request(HTTPClient.METHOD_POST, "/api/auth/sign-out", {}, "", true, true)
	if own_generation == generation:
		dispose_session()
		if is_instance_valid(session_store): await session_store.forget(true)
	return response

static func _valid_token(value: Variant) -> bool:
	if not value is String: return false
	var pattern := RegEx.new()
	pattern.compile("^[A-Za-z0-9._%~-]{20,512}$")
	return pattern.search(value) != null

static func new_key() -> String:
	var bytes: PackedByteArray = Crypto.new().generate_random_bytes(16)
	bytes[6] = (bytes[6] & 15) | 64
	bytes[8] = (bytes[8] & 63) | 128
	var hex: String = bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [hex.substr(0,8),hex.substr(8,4),hex.substr(12,4),hex.substr(16,4),hex.substr(20)]

static func _uuid(value: String) -> bool:
	var pattern := RegEx.new()
	pattern.compile("^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$")
	return pattern.search(value) != null

func me() -> Dictionary: return await _request(HTTPClient.METHOD_GET, "/v1/me")
func fighters() -> Dictionary: return await _request(HTTPClient.METHOD_GET, "/v1/fighters")
func catalog() -> Dictionary: return await _request(HTTPClient.METHOD_GET, "/v1/game/catalog")
func owned() -> Dictionary: return await _request(HTTPClient.METHOD_GET, "/v1/owned")
func offline_results() -> Dictionary: return await _request(HTTPClient.METHOD_GET, "/v1/arena/offline-results")
func create_fighter(archetype_id: String, display_name: String, key: String) -> Dictionary:
	return await _request(HTTPClient.METHOD_POST, "/v1/fighters", {"archetype_id":archetype_id,"display_name":display_name}, key)
func opponents(fighter_id: String) -> Dictionary:
	if not _uuid(fighter_id): return _error("INVALID_ID","Luchador inválido.")
	return await _request(HTTPClient.METHOD_GET, "/v1/arena/opponents?fighter_id="+fighter_id)
func create_battle(fighter_id: String, opponent_id: String, key: String) -> Dictionary:
	if not _uuid(fighter_id) or not _uuid(opponent_id): return _error("INVALID_ID","Luchador inválido.")
	return await _request(HTTPClient.METHOD_POST, "/v1/battles", {"fighter_id":fighter_id,"opponent_id":opponent_id}, key)
func battle(battle_id: String) -> Dictionary:
	if not _uuid(battle_id): return _error("INVALID_ID","Combate inválido.")
	return await _request(HTTPClient.METHOD_GET, "/v1/battles/"+battle_id)
func history(fighter_id: String, cursor: String = "") -> Dictionary:
	if not _uuid(fighter_id): return _error("INVALID_ID","Luchador inválido.")
	return await _request(HTTPClient.METHOD_GET,"/v1/history?fighter_id="+fighter_id+("&cursor="+cursor.uri_encode() if not cursor.is_empty() else ""))
func story(fighter_id: String) -> Dictionary:
	if not _uuid(fighter_id): return _error("INVALID_ID","Luchador inválido.")
	return await _request(HTTPClient.METHOD_GET,"/v1/story?fighter_id="+fighter_id)
func story_battle(fighter_id: String, key: String) -> Dictionary:
	if not _uuid(fighter_id): return _error("INVALID_ID","Luchador inválido.")
	return await _request(HTTPClient.METHOD_POST,"/v1/story/battles",{"fighter_id":fighter_id},key)
func allocate(fighter_id: String, stat: String, amount: int, revision: int, key: String) -> Dictionary:
	if not _uuid(fighter_id): return _error("INVALID_ID","Luchador inválido.")
	return await _request(HTTPClient.METHOD_POST,"/v1/fighters/"+fighter_id+"/allocate",{"stat":stat,"amount":amount,"expected_revision":revision},key)
func set_ai(fighter_id: String, style: String, revision: int, key: String) -> Dictionary:
	if not _uuid(fighter_id): return _error("INVALID_ID","Luchador inválido.")
	return await _request(HTTPClient.METHOD_POST,"/v1/fighters/"+fighter_id+"/ai",{"style":style,"expected_revision":revision},key)
func upgrade_move(fighter_id: String, move_id: String, revision: int, key: String) -> Dictionary:
	if not _uuid(fighter_id): return _error("INVALID_ID","Luchador inválido.")
	return await _request(HTTPClient.METHOD_POST,"/v1/fighters/"+fighter_id+"/upgrade-move",{"move_id":move_id,"expected_revision":revision},key)
func choose_perk(fighter_id: String, perk_id: String, revision: int, key: String) -> Dictionary:
	if not _uuid(fighter_id): return _error("INVALID_ID","Luchador inválido.")
	return await _request(HTTPClient.METHOD_POST,"/v1/fighters/"+fighter_id+"/perk",{"perk_id":perk_id,"expected_revision":revision},key)
func respec(fighter_id: String, revision: int, key: String) -> Dictionary:
	if not _uuid(fighter_id): return _error("INVALID_ID","Luchador inválido.")
	return await _request(HTTPClient.METHOD_POST,"/v1/fighters/"+fighter_id+"/respec",{"expected_revision":revision},key)
func update_fighter(fighter_id: String, revision: int, display_name: String, appearance: Dictionary, key: String) -> Dictionary:
	if not _uuid(fighter_id): return _error("INVALID_ID","Luchador inválido.")
	return await _request(HTTPClient.METHOD_PATCH,"/v1/fighters/"+fighter_id,{"expected_revision":revision,"display_name":display_name,"appearance":appearance.duplicate(true)},key)
func acknowledge(ids: Array, key: String) -> Dictionary:
	for id: Variant in ids:
		if not id is String or not _uuid(id): return _error("INVALID_ID","Resultado inválido.")
	return await _request(HTTPClient.METHOD_POST,"/v1/arena/offline-results/ack",{"ids":ids.duplicate()},key)

func _request(method: int, path: String, body: Dictionary = {}, key: String = "", authenticated: bool = true, raw_auth: bool = false) -> Dictionary:
	if base_url.is_empty() or not is_inside_tree(): return _error("NOT_CONFIGURED","El servicio online no está configurado.")
	if authenticated and not is_authenticated() and not (_restoring and path=="/api/auth/get-session" and not _token.is_empty()): return _error("UNAUTHENTICATED","Inicia sesión para continuar.",401)
	if not path.begins_with("/") or path.begins_with("//"): return _error("INVALID_PATH","Solicitud inválida.")
	if method != HTTPClient.METHOD_GET and not raw_auth and not _uuid(key): return _error("IDEMPOTENCY_REQUIRED","No se pudo identificar la operación.")
	var http := HTTPRequest.new()
	http.timeout = 20
	http.max_redirects = 0
	http.body_size_limit = 2097152
	add_child(http)
	var pending := Pending.new()
	var request_id: String = new_key()
	var own_generation: int = generation
	_requests[request_id] = {"http":http,"pending":pending,"generation":own_generation}
	http.request_completed.connect(_completed.bind(request_id, raw_auth), CONNECT_ONE_SHOT)
	var headers := PackedStringArray(["Content-Type: application/json","Accept: application/json"])
	if authenticated: headers.append("Authorization: Bearer "+_token)
	if not key.is_empty(): headers.append("Idempotency-Key: "+key)
	var status: Error = http.request(base_url+path,headers,method,"" if method == HTTPClient.METHOD_GET else JSON.stringify(body))
	if status != OK:
		_requests.erase(request_id)
		http.queue_free()
		return _error("CONNECTION_FAILED","No se pudo conectar. Puedes reintentar la misma operación.")
	var response: Dictionary = await pending.done
	if own_generation != generation: return _error("CANCELLED","La sesión cambió; se descartó la respuesta.")
	connected = int(response.get("status",0)) > 0
	if int(response.get("status",0)) == 401 and authenticated:
		_token = ""
		_expires_at = 0
		if is_instance_valid(session_store): await session_store.forget()
		session_changed.emit()
	return response

func _completed(result: int, status: int, headers: PackedStringArray, bytes: PackedByteArray, request_id: String, raw_auth: bool) -> void:
	if not _requests.has(request_id): return
	var record: Dictionary = _requests[request_id]
	_requests.erase(request_id)
	record.http.queue_free()
	var response: Dictionary
	if result != HTTPRequest.RESULT_SUCCESS: response = _error("CONNECTION_FAILED","No llegó la respuesta. Reintentar conservará la misma operación.")
	else: response = decode_response(status,bytes,raw_auth)
	for header: String in headers:
		if header.to_lower().begins_with("x-request-id:"): response["request_id"] = header.substr(header.find(":")+1).strip_edges()
		if header.to_lower().begins_with("retry-after:"): response["retry_after"] = clampi(int(header.substr(header.find(":")+1)),1,300)
	record.pending.done.emit(response)

static func decode_response(status: int, bytes: PackedByteArray, raw_auth: bool = false) -> Dictionary:
	var value: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	if not value is Dictionary: return _error("UNAUTHENTICATED","Continúa para entrar.",401) if raw_auth and status==200 and value==null else _error("INVALID_RESPONSE","El servicio devolvió una respuesta inválida.",status)
	if status < 200 or status >= 300:
		if raw_auth and value.get("error") is String:
			return _error(str(value.error),str(value.get("error_description","Esperando autorización.")).left(300),status)
		if value.get("error") is Dictionary:
			return _error(str(value.error.get("code","SERVER_ERROR")),str(value.error.get("message","No se pudo completar la solicitud.")).left(300),status)
		return _error(str(value.get("code","SERVER_ERROR")),str(value.get("message","No se pudo completar la solicitud.")).left(300),status)
	var data: Variant = value if raw_auth else value.get("data")
	if not data is Dictionary: return _error("INVALID_RESPONSE","El servicio devolvió datos inválidos.",status)
	return {"ok":true,"status":status,"data":data.duplicate(true)}

static func _error(code: String, message: String, status: int = 0) -> Dictionary:
	return {"ok":false,"status":status,"error":{"code":code,"message":message}}
