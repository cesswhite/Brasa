class_name IdentityApi
extends Node
## Optional local Workers adapter. Never uploads local progression or ownership.
## Credentials stay in memory and are supplied explicitly by a local dev caller.
var _base_url := ""
var _token := ""
var _busy := false

func configure(base_url: String, token: String) -> bool:
	if _busy: return false
	var url := base_url.trim_suffix("/")
	var pattern := RegEx.new()
	pattern.compile("^http://(127\\.0\\.0\\.1|localhost):[0-9]{1,5}$")
	if pattern.search(url) == null or token.length() < 20 or token.contains("\n") or token.contains("\r"):
		_base_url = ""
		_token = ""
		return false
	_base_url = url
	_token = token
	return true

func disconnect_service() -> void:
	_base_url = ""
	_token = ""

func catalog() -> Dictionary:
	return await _request(HTTPClient.METHOD_GET, "/v1/catalog")

func owned() -> Dictionary:
	return await _request(HTTPClient.METHOD_GET, "/v1/owned")

func fighters() -> Dictionary:
	return await _request(HTTPClient.METHOD_GET, "/v1/fighters")

func create_fighter(archetype_id: String, display_name: String) -> Dictionary:
	return await _request(HTTPClient.METHOD_POST, "/v1/fighters", {"archetype_id":archetype_id,"display_name":display_name})

func update_fighter(fighter_id: String, revision: int, display_name: String, appearance: Dictionary) -> Dictionary:
	if not _uuid(fighter_id): return _error("INVALID_ID", "ID de luchador inválido.")
	return await _request(HTTPClient.METHOD_PATCH, "/v1/fighters/"+fighter_id,
		{"expected_revision":revision,"display_name":display_name,"appearance":appearance.duplicate(true)})

func opponent(fighter_id: String) -> Dictionary:
	if not _uuid(fighter_id): return _error("INVALID_ID", "ID de luchador inválido.")
	return await _request(HTTPClient.METHOD_GET, "/v1/opponents/"+fighter_id)

func battle_snapshot(snapshot_id: String) -> Dictionary:
	if not _uuid(snapshot_id): return _error("INVALID_ID", "ID de repetición inválido.")
	return await _request(HTTPClient.METHOD_GET, "/v1/snapshots/"+snapshot_id)

static func _uuid(value: String) -> bool:
	var pattern := RegEx.new()
	pattern.compile("^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$")
	return pattern.search(value) != null

static func _error(code: String, message: String, status: int = 0) -> Dictionary:
	return {"ok":false,"status":status,"error":{"code":code,"message":message}}

func _request(method: int, path: String, body: Dictionary = {}) -> Dictionary:
	if _base_url.is_empty() or not is_inside_tree(): return _error("NOT_CONNECTED", "Configura el servidor local antes de conectar.")
	if _busy: return _error("BUSY", "Espera a que termine la solicitud anterior.")
	_busy = true
	var request := HTTPRequest.new()
	request.timeout = 8
	request.max_redirects = 0 # A redirect must never forward the credential.
	request.body_size_limit = 1048576
	add_child(request)
	var code := request.request(_base_url+path, PackedStringArray(["Authorization: Bearer "+_token,"Content-Type: application/json"]), method, "" if method == HTTPClient.METHOD_GET else JSON.stringify(body))
	if code != OK:
		request.queue_free()
		_busy = false
		return _error("CONNECTION_FAILED", "No se pudo contactar con el servidor local.")
	var response: Array = await request.request_completed
	request.queue_free()
	_busy = false
	if int(response[0]) != HTTPRequest.RESULT_SUCCESS: return _error("CONNECTION_FAILED", "El servidor local no respondió.")
	var status := int(response[1])
	var bytes: PackedByteArray = response[3]
	return decode_response(status, bytes)

static func decode_response(status: int, bytes: PackedByteArray) -> Dictionary:
	var payload: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	if not payload is Dictionary: return _error("INVALID_RESPONSE", "El servidor devolvió una respuesta inválida.", status)
	if status < 200 or status >= 300:
		if not payload.get("error") is Dictionary or not payload.error.get("code") is String or not payload.error.get("message") is String:
			return _error("INVALID_RESPONSE", "El servidor devolvió un error inválido.", status)
		return {"ok":false,"status":status,"error":payload.error.duplicate(true)}
	if not payload.get("data") is Dictionary: return _error("INVALID_RESPONSE", "El servidor devolvió datos inválidos.", status)
	return {"ok":true,"status":status,"data":payload.data.duplicate(true)}
