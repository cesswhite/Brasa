extends SceneTree
## Disposable loopback HTTP server. No real credentials, saves or remote requests.
const Api = preload("res://scripts/online_api.gd")
const FIGHTER := "10000000-0000-4000-8000-000000000001"
const RIVAL := "20000000-0000-4000-8000-000000000002"
var checks: int = 0
var failures: int = 0
var server := TCPServer.new()
var clients: Array = []
var origin: String = ""
var received: Array = []
var writes: Dictionary = {}
var poll_count: int = 0
var hold_next: bool = false
var late_result: Dictionary = {}
var revision_expected: int = 4

func _init() -> void: _run.call_deferred()
func _check(ok: bool,message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ONLINE API: "+message)
func _process(_delta: float) -> bool:
	while server.is_connection_available(): clients.append({"peer":server.take_connection(),"buffer":"","delay":0,"response":""})
	for index in range(clients.size()-1,-1,-1):
		var client: Dictionary = clients[index]
		var peer: StreamPeerTCP = client.peer
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			clients.remove_at(index)
			continue
		if not str(client.response).is_empty():
			client.delay = int(client.delay)-1
			if int(client.delay) <= 0:
				peer.put_data(str(client.response).to_utf8_buffer())
				peer.disconnect_from_host()
				clients.remove_at(index)
			continue
		var available: int = peer.get_available_bytes()
		if available > 0: client.buffer += peer.get_utf8_string(available)
		var request: String = str(client.buffer)
		var split: int = request.find("\r\n\r\n")
		if split < 0: continue
		var header: String = request.substr(0,split)
		var length: int = 0
		for line: String in header.split("\r\n"):
			if line.to_lower().begins_with("content-length:"): length = int(line.split(":")[1].strip_edges())
		var body: String = request.substr(split+4)
		if body.to_utf8_buffer().size() < length: continue
		var line: PackedStringArray = header.split("\r\n")[0].split(" ")
		var parsed: Variant = JSON.parse_string(body) if not body.is_empty() else {}
		var entry := {"method":line[0],"path":line[1],"header":header,"body":parsed}
		received.append(entry)
		var answer: Dictionary = _answer(entry)
		var payload: String = JSON.stringify(answer.payload)
		client.response = "HTTP/1.1 %d %s\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\nX-Request-ID: fixture-request\r\nRetry-After: 7\r\n\r\n%s" % [int(answer.status),"OK" if int(answer.status)<400 else "Error",payload.to_utf8_buffer().size(),payload]
		client.delay = 12 if hold_next else 1
		hold_next = false
	return false

func _answer(request: Dictionary) -> Dictionary:
	if str(request.path) == "/api/auth/device/code":
		return {"status":200,"payload":{"device_code":"device-fixture","user_code":"BRAS-TEST","verification_uri":origin+"/device","verification_uri_complete":origin+"/device?user_code=BRAS-TEST","expires_in":300,"interval":5}}
	if str(request.path) == "/api/auth/device/token":
		poll_count += 1
		if poll_count == 1: return {"status":400,"payload":{"error":"authorization_pending"}}
		if poll_count == 2: return {"status":400,"payload":{"error":"slow_down"}}
		return {"status":200,"payload":{"access_token":"fixture-bearer-token-only-for-test","token_type":"Bearer","expires_in":3600}}
	if str(request.path) == "/api/auth/sign-out": return {"status":200,"payload":{"success":true}}
	if str(request.path) == "/v1/me": return {"status":200,"payload":{"data":{"account_id":"fixture"}}}
	if str(request.path) == "/v1/fighters": return {"status":200,"payload":{"data":{"fighters":[]}}}
	if str(request.path) == "/v1/battles":
		var key: String = ""
		for header: String in str(request.header).split("\r\n"):
			if header.to_lower().begins_with("idempotency-key:"): key = header.split(":")[1].strip_edges()
		writes[key] = int(writes.get(key,0))+1
		return {"status":200,"payload":{"data":{"battle":{"id":FIGHTER},"same_key":key}}}
	if str(request.path).ends_with("/allocate"):
		return {"status":200,"payload":{"data":{"fighter":{"progression_revision":int(request.body.expected_revision)+1}}}}
	return {"status":503,"payload":{"error":{"code":"UNAVAILABLE","message":"Fixture temporal."}}}

func _run() -> void:
	var port: int = 32400
	while port < 32500 and server.listen(port,"127.0.0.1") != OK: port += 1
	_check(port < 32500,"disposable local server bound")
	if port >= 32500:
		quit(1)
		return
	origin = "http://127.0.0.1:%d" % port
	var api := Api.new()
	root.add_child(api)
	_check(not api.configure({"base_url":"http://remote.example:8787"}),"remote HTTP refused")
	_check(not api.configure({"base_url":"https://attacker.example"}),"unapproved HTTPS origin refused")
	_check(not api.configure({"base_url":origin}),"loopback requires explicit test configuration")
	_check(api.configure({"base_url":origin,"allow_local_test":true}),"explicit loopback fixture accepted")
	var denied: Dictionary = await api.me()
	_check(not denied.ok and int(denied.status)==401 and received.is_empty(),"unauthenticated request is never sent")
	var code: Dictionary = await api.authorize_device()
	_check(code.ok and api.device.user_code=="BRAS-TEST","device authorization decoded")
	_check(api.trusted_browser_url(api.verification_url()),"verified same-origin browser URL")
	_check(not api.trusted_browser_url(origin+".attacker.example/device"),"browser rejects deceptive hostname")
	_check(not api.trusted_browser_url("https://attacker.example/device"),"browser rejects foreign origin")
	_check(not str(received[0].header).contains("Authorization:"),"device request carries no bearer token")
	var count: int = received.size()
	var waiting: Dictionary = await api.poll_device_token()
	_check(not waiting.ok and waiting.error.code=="WAIT" and received.size()==count,"client honors device polling interval")
	api._next_poll = 0
	var pending: Dictionary = await api.poll_device_token()
	_check(pending.error.code=="authorization_pending" and not api.is_authenticated(),"authorization pending is not a session")
	api._next_poll = 0
	var slow: Dictionary = await api.poll_device_token()
	_check(slow.error.code=="slow_down" and int(api.device.interval)==10,"slow_down increases polling interval")
	api._next_poll = 0
	var authorized: Dictionary = await api.poll_device_token()
	_check(authorized.ok and api.is_authenticated() and api.device.is_empty(),"authorized opaque session stays in memory")
	var me: Dictionary = await api.me()
	_check(me.ok and me.data.account_id=="fixture" and me.request_id=="fixture-request","central API carries request metadata")
	_check(str(received.back().header).contains("Bearer fixture-bearer-token-only-for-test"),"only authenticated calls attach session")
	count = received.size()
	var invalid: Dictionary = await api.create_battle(FIGHTER,RIVAL,"")
	_check(not invalid.ok and invalid.error.code=="IDEMPOTENCY_REQUIRED" and received.size()==count,"mutation without key never reaches server")
	var key: String = Api.new_key()
	var first: Dictionary = await api.create_battle(FIGHTER,RIVAL,key)
	var again: Dictionary = await api.create_battle(FIGHTER,RIVAL,key)
	_check(first.ok and again.ok and first.data.same_key==again.data.same_key,"mutation retry preserves same idempotency header")
	_check(received.back().body.keys().size()==2 and received.back().body.has_all(["fighter_id","opponent_id"]),"battle request sends intent only, never damage or rewards")
	var allocation: Dictionary = await api.allocate(FIGHTER,"attack",1,4,Api.new_key())
	_check(allocation.ok and int(received.back().body.expected_revision)==4 and int(received.back().body.amount)==1,"allocation sends bounded intent and explicit revision")
	hold_next = true
	_read_late(api)
	await process_frame
	await process_frame
	api.dispose_session()
	await process_frame
	_check(not late_result.ok and late_result.error.code=="CANCELLED","logout cancels in-flight response")
	_check(api._requests.is_empty() and not api.is_authenticated(),"logout clears pending request and token")
	for frame in range(15): await process_frame
	_check(late_result.error.code=="CANCELLED","late network reply cannot revive previous account")
	_check(Api.decode_response(200,"[]".to_utf8_buffer()).error.code=="INVALID_RESPONSE","invalid response root rejected")
	_check(Api.decode_response(401,'{"error":{"code":"UNAUTHENTICATED","message":"expired"}}'.to_utf8_buffer()).error.code=="UNAUTHENTICATED","structured unauthorized error preserved")
	_check(Api.decode_response(400,'{"error":"expired_token"}'.to_utf8_buffer(),true).error.code=="expired_token","device expiry error preserved")
	api.queue_free()
	server.stop()
	for client: Dictionary in clients: client.peer.disconnect_from_host()
	print("ONLINE API: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
func _read_late(api: Node) -> void:
	late_result = await api.me()
