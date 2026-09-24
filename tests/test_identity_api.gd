extends SceneTree
## Needs disposable local credentials: -- --credential=/absolute/file.json
const Api = preload("res://scripts/identity_api.gd")
var checks := 0
var failures := 0
func _init() -> void: _run.call_deferred()
func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("IDENTITY API: "+message)
func _run() -> void:
	var credential_path := ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--credential="): credential_path = argument.trim_prefix("--credential=")
	if credential_path.is_empty():
		push_error("Pass a disposable local --credential=file.json; never use real account data.")
		quit(1)
		return
	var credential: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(credential_path))
	var api := Api.new()
	root.add_child(api)
	_check(not api.configure("http://remote.example:8787", str(credential.token)), "Local adapter rejects non-loopback host")
	_check(api.configure("http://127.0.0.1:8787", str(credential.token)), "Local adapter accepts explicit credential in memory")
	var catalog: Dictionary = await api.catalog()
	_check(catalog.ok and catalog.data.items.size()>=20, "Godot reads canonical Worker cosmetic catalog")
	var owned: Dictionary = await api.owned()
	_check(owned.ok and owned.data.account_id==credential.account_id and owned.data.owned.size()>=13, "Authenticated account inventory comes from server")
	var created: Dictionary = await api.create_fighter("tepa", "  COMETA   LOCAL  ")
	_check(created.ok and created.status==201, "Worker creates actual D1 fighter")
	if not created.ok:
		print("IDENTITY API: %d checks, %d failures" % [checks,failures])
		api.queue_free()
		quit(1)
		return
	var id := str(created.data.fighter_id)
	_check(created.data.identity.display_name=="COMETA LOCAL", "Server canonicalizes name")
	var progression: Dictionary = created.data.progression.duplicate(true)
	var appearance: Dictionary = created.data.appearance.duplicate(true)
	appearance.body_style_id = "luma"
	appearance.palette_id = "jade"
	var updated: Dictionary = await api.update_fighter(id,1,"LUNA LOCAL",appearance)
	_check(updated.ok and updated.data.revision==2 and updated.data.identity.display_name=="LUNA LOCAL", "Godot changes validated appearance/name atomically")
	_check(updated.data.progression==progression, "Cosmetic mutation cannot change gameplay layer")
	var stale: Dictionary = await api.update_fighter(id,1,"NO DEBE GANAR",appearance)
	_check(not stale.ok and stale.status==409, "Stale edit receives revision conflict")
	var locked := appearance.duplicate(true)
	locked.aura_id = "corona"
	var rejected: Dictionary = await api.update_fighter(id,2,"NO DEBE GUARDAR",locked)
	_check(not rejected.ok and rejected.status==403, "Client cannot equip unowned reward")
	var unsafe := appearance.duplicate(true)
	unsafe.shader = "arbitrary"
	var invalid: Dictionary = await api.update_fighter(id,2,"NO DEBE GUARDAR",unsafe)
	_check(not invalid.ok and invalid.status==422, "Server rejects arbitrary cosmetic/shader fields")
	var reserved: Dictionary = await api.update_fighter(id,2,"ADMIN",appearance)
	_check(not reserved.ok and reserved.status==422, "Server independently rejects reserved display names")
	var preview: Dictionary = await api.opponent(id)
	_check(preview.ok and preview.data.appearance==appearance and preview.data.identity.display_name=="LUNA LOCAL" and preview.data.revision==2, "Offline opponent preview reads persisted appearance, failed edits changed nothing")
	api.configure("http://127.0.0.1:8787", "invalid-credential-for-auth-test")
	var auth: Dictionary = await api.fighters()
	_check(not auth.ok and auth.status==401, "Backend rejects unauthenticated caller")
	api.disconnect_service()
	var disconnected: Dictionary = await api.owned()
	_check(not disconnected.ok and disconnected.error.code=="NOT_CONNECTED", "Disconnected client cannot retain use of token")
	api.queue_free()
	await process_frame
	print("IDENTITY API: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
