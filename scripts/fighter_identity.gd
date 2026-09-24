class_name FighterIdentity
extends RefCounted
## Account-level cosmetic sidecar. Never writes either gameplay save.
const Cosmetics = preload("res://scripts/cosmetic_catalog.gd")
const Characters = preload("res://scripts/character_catalog.gd")
const League = preload("res://scripts/progression.gd")
const StoryProgress = preload("res://scripts/story_progression.gd")
const Balance = preload("res://scripts/balance.gd")
const VERSION: int = 2
# Version 1 predates these two free bodies. Older missing defaults remain corrupt.
const V1_ADDED_DEFAULTS: Array[String] = ["body_style:onix", "body_style:bruma"]
const MAX_BYTES: int = 1048576
var data: Dictionary = {}
var save_blocked: bool = false
var last_save_ok: bool = true
var load_notice: String = ""
var _save_path: String = "user://brasa_identity.json"
var _loaded_hash: String = ""
var _saved_snapshot: Dictionary = {}

func _init() -> void:
	data = _new_account()

func load_save(path: String = "user://brasa_identity.json") -> void:
	_save_path = path
	data = _new_account()
	_saved_snapshot = {}
	_loaded_hash = ""
	save_blocked = false
	last_save_ok = true
	load_notice = ""
	if not FileAccess.file_exists(path): return
	_loaded_hash = FileAccess.get_sha256(path)
	var original: Dictionary = _read(path)
	var decoded: Dictionary = _decode(original)
	if not decoded.is_empty():
		data = decoded
		_saved_snapshot = original.duplicate(true)
		return
	# Fail closed. Even a valid backup is read-only until explicit recovery exists.
	var backup: Dictionary = _decode(_read(path + ".bak"))
	if not backup.is_empty(): data = backup
	_block("La identidad está dañada o usa otra versión. Conservamos el archivo y su copia; la personalización está protegida.")

func migrate_legacy(league_roster: Dictionary, story_roster: Dictionary) -> void:
	if save_blocked: return
	for id: String in Characters.IDS:
		if not league_roster.has(id) and not story_roster.has(id): continue
		if _saved_snapshot.get("fighters",{}).has(id): continue
		if data.fighters.has(id) and str(data.fighters[id].identity.name_source) != "default": continue
		var league_name: String = _legacy_name(league_roster.get(id,{}))
		var story_name: String = _legacy_name(story_roster.get(id,{}))
		var default_name: String = str(Characters.definition(id).name)
		var name_value: String = default_name
		var source: String = "default"
		if not league_name.is_empty() and league_name != default_name:
			name_value = league_name
			source = "legacy_league"
		elif not story_name.is_empty() and story_name != default_name:
			name_value = story_name
			source = "legacy_story"
		_ensure_entry(data,id)
		if source != "default":
			var identity: Dictionary = data.fighters[id].identity
			identity.display_name = name_value
			identity.normalized_name = _normalized(name_value)
			identity.legacy_name = true
			identity.name_source = source

func entry(archetype_id: String) -> Dictionary:
	if not archetype_id in Characters.IDS: return {}
	if save_blocked and not data.fighters.has(archetype_id): return {}
	_ensure_entry(data,archetype_id)
	return data.fighters[archetype_id].duplicate(true)

func owned_ids() -> Array[String]:
	var result: Array[String] = []
	for id: String in data.get("inventory",{}): result.append(id)
	return result

func owned(slot: String, id: String) -> bool:
	return data.get("inventory",{}).has(Cosmetics.inventory_key(slot,id))

func decorate(combatant: Dictionary) -> Dictionary:
	var result: Dictionary = combatant.duplicate(true)
	# Explicit snapshots keep their historical identity, including foreign fighters.
	if result.get("fighter_id") is String and result.get("identity") is Dictionary and result.get("appearance") is Dictionary:
		return result
	var id: String = str(result.get("character_id",""))
	var fighter: Dictionary = entry(id)
	if fighter.is_empty(): return result
	result["fighter_id"] = fighter.fighter_id
	result["identity"] = fighter.identity.duplicate(true)
	result["appearance"] = fighter.appearance.duplicate(true)
	result["name"] = str(fighter.identity.display_name)
	result["display_name"] = str(fighter.identity.display_name)
	return result

func update_fighter(archetype_id: String, fighter_name: String, appearance: Dictionary) -> Dictionary:
	if save_blocked: return _failure(load_notice)
	if not archetype_id in Characters.IDS: return _failure("Arquetipo desconocido.")
	var candidate: Dictionary = data.duplicate(true)
	_ensure_entry(candidate,archetype_id)
	var old: Dictionary = candidate.fighters[archetype_id]
	var valid_name: Dictionary = validate_name(fighter_name)
	var unchanged_legacy: bool = bool(old.identity.legacy_name) and fighter_name == str(old.identity.display_name)
	if not bool(valid_name.ok) and not unchanged_legacy: return _failure(str(valid_name.error))
	var valid_appearance: Dictionary = Cosmetics.validate_appearance(appearance,owned_ids(),archetype_id)
	if not bool(valid_appearance.ok): return _failure(str(valid_appearance.error))
	old.appearance = valid_appearance.appearance
	if not unchanged_legacy:
		old.identity.display_name = valid_name.display_name
		old.identity.normalized_name = valid_name.normalized_name
		old.identity.legacy_name = false
		old.identity.name_source = "custom"
	old.identity.updated_at = maxi(_now(),int(old.identity.created_at))
	if not _persist(candidate): return {"ok":false,"error":load_notice,"entry":{}}
	return {"ok":true,"error":"","entry":entry(archetype_id)}

func save() -> bool:
	return _persist(data.duplicate(true))

func grant_from_progress(league_roster: Dictionary, story_roster: Dictionary) -> Array[String]:
	var added: Array[String] = []
	if save_blocked:
		last_save_ok = false
		return added
	var evidence: Dictionary = {"level":{"value":0},"league_wins":{"value":0},"story_cleared":{"value":0}}
	for id: String in Characters.IDS:
		for mode: String in ["league","story"]:
			var roster: Dictionary = league_roster if mode=="league" else story_roster
			var profile: Dictionary = _validated_progress(roster.get(id,{}),id,mode)
			if profile.is_empty(): continue
			_record_evidence(evidence,"level",int(profile.level),id,mode)
			if mode=="league": _record_evidence(evidence,"league_wins",int(profile.wins),id,mode)
			else: _record_evidence(evidence,"story_cleared",StoryProgress._cleared(profile),id,mode)
	var candidate: Dictionary = data.duplicate(true)
	for slot: Dictionary in Cosmetics.SLOTS:
		for item: Dictionary in Cosmetics.items(str(slot.id)):
			var key: String = str(item.inventory_id)
			if bool(item.default) or candidate.inventory.has(key): continue
			var requirement: Dictionary = item.unlock
			var earned: Dictionary = evidence[str(requirement.kind)]
			if int(earned.value) < int(requirement.threshold): continue
			candidate.inventory[key] = {"source":"reward","unlocked_at":_now(),"requirement":requirement.duplicate(true),"evidence":earned.duplicate(true)}
			added.append(key)
	if added.is_empty():
		last_save_ok = true
		return added
	if not _persist(candidate): return []
	return added

static func validate_name(value: String) -> Dictionary:
	for index: int in range(value.length()):
		var point: int = value.unicode_at(index)
		if point < 32 or (point >= 127 and point <= 159): return {"ok":false,"error":"El nombre no puede contener saltos de línea ni caracteres de control."}
	var name_value: String = _collapse_spaces(value.strip_edges())
	if name_value.length() < int(Cosmetics.NAME_POLICY.minimum_length) or name_value.length() > int(Cosmetics.NAME_POLICY.maximum_length):
		return {"ok":false,"error":"Usa entre 2 y 24 caracteres para el nombre."}
	var allowed: RegEx = RegEx.new()
	allowed.compile(str(Cosmetics.NAME_POLICY.allowed_pattern))
	var required: RegEx = RegEx.new()
	required.compile(str(Cosmetics.NAME_POLICY.required_pattern))
	if allowed.search(name_value)==null or required.search(name_value)==null:
		return {"ok":false,"error":"Usa letras, números, espacios, guiones o apóstrofos."}
	var normalized: String = name_value.to_lower()
	if normalized in Cosmetics.NAME_POLICY.reserved: return {"ok":false,"error":"Ese nombre está reservado."}
	return {"ok":true,"error":"","display_name":name_value,"normalized_name":normalized}

static func _collapse_spaces(value: String) -> String:
	var spaces: RegEx = RegEx.new()
	spaces.compile(" +")
	return spaces.sub(value," ",true)

static func _normalized(value: String) -> String:
	return _collapse_spaces(value.strip_edges()).to_lower()

static func _legacy_name(profile: Variant) -> String:
	if not profile is Dictionary or not profile.get("name") is String: return ""
	var value: String = profile.name
	return value if not value.is_empty() and value.length()<=256 else ""

static func _now() -> int:
	return int(Time.get_unix_time_from_system())

static func _id(prefix: String) -> String:
	return prefix + Crypto.new().generate_random_bytes(16).hex_encode()

static func _new_account() -> Dictionary:
	var stamp: int = _now()
	var inventory: Dictionary = {}
	for id: String in Cosmetics.default_owned(): inventory[id] = {"source":"default","unlocked_at":stamp,"requirement":{"kind":"default","threshold":0}}
	return {"version":VERSION,"account_id":_id("acct_"),"created_at":stamp,"updated_at":stamp,"fighters":{},"inventory":inventory}

static func _ensure_entry(target: Dictionary, id: String) -> void:
	if target.fighters.has(id): return
	var stamp: int = _now()
	var name_value: String = str(Characters.definition(id).name)
	target.fighters[id] = {"fighter_id":_id("ftr_"),"archetype_id":id,"identity":{"display_name":name_value,"normalized_name":_normalized(name_value),"created_at":stamp,"updated_at":stamp,"legacy_name":false,"name_source":"default"},"appearance":Cosmetics.default_appearance(id)}

static func _record_evidence(target: Dictionary, kind: String, value: int, id: String, mode: String) -> void:
	if value > int(target[kind].value): target[kind] = {"kind":kind,"value":value,"archetype_id":id,"mode":mode}

static func _validated_progress(raw: Variant, id: String, mode: String) -> Dictionary:
	if not raw is Dictionary or str(raw.get("character_id","")) != id: return {}
	for key: String in ["level","xp","wins","losses","matches","total_xp"]:
		if not _whole(raw.get(key),0,2000000000): return {}
	if not _whole(raw.level,1,Balance.MAX_LEVEL) or int(raw.matches)!=int(raw.wins)+int(raw.losses): return {}
	if not raw.get("stats") is Dictionary: return {}
	var decoded: Dictionary
	if mode=="league":
		decoded = League._validate_profile(raw,id)
		if decoded.is_empty(): return {}
		if int(raw.total_xp) > int(raw.matches)*Balance.reward_base(Balance.MAX_LEVEL,"win"): return {}
	else:
		if not _story_shape(raw): return {}
		var payload: Dictionary = StoryProgress._decode({"version":StoryProgress.SAVE_VERSION,"mode":"story","active_id":id,"roster":{id:raw},"history":[]})
		if payload.is_empty(): return {}
		decoded = payload.roster[id]
	for key: String in ["level","xp","wins","losses","matches","total_xp"]:
		if int(raw[key]) != int(decoded[key]): return {}
	return decoded

static func _story_shape(raw: Dictionary, depth: int = 0) -> bool:
	if depth>12: return false
	for key: String in ["chapter_records","allocations","attempts","move_upgrades"]:
		if not raw.get(key) is Dictionary: return false
	for key: String in ["defeated","allocation_history","perks","unlocked_moves"]:
		if not raw.get(key) is Array: return false
	if not raw.get("completed") is bool or not _whole(raw.get("chapter"),1,11): return false
	if not raw.get("completion_snapshot",{}) is Dictionary: return false
	for record: Variant in raw.chapter_records.values():
		if not record is Dictionary or not record.get("profile") is Dictionary or not record.get("summary") is Dictionary or not _story_shape(record.profile,depth+1): return false
	if not raw.get("completion_snapshot",{}).is_empty():
		var frozen: Dictionary = raw.completion_snapshot
		if not frozen.get("profile") is Dictionary or not frozen.get("summary") is Dictionary or not _story_shape(frozen.profile,depth+1): return false
	return true

func _persist(candidate: Dictionary) -> bool:
	if save_blocked:
		last_save_ok = false
		return false
	if _decode(candidate).is_empty():
		load_notice = "La identidad no superó la validación. El archivo anterior se conserva."
		last_save_ok = false
		return false
	var absolute: String = ProjectSettings.globalize_path(_save_path)
	if DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())!=OK:
		return _io_failure("No se pudo crear la carpeta de identidad.")
	var lock: String = absolute + ".lock"
	if DirAccess.make_dir_absolute(lock)!=OK: return _io_failure("La identidad está siendo guardada. Vuelve a intentarlo.")
	var ok: bool = _persist_locked(candidate,absolute)
	DirAccess.remove_absolute(lock)
	last_save_ok = ok
	return ok

func _persist_locked(candidate: Dictionary, absolute: String) -> bool:
	var current_hash: String = FileAccess.get_sha256(absolute) if FileAccess.file_exists(absolute) else ""
	if current_hash != _loaded_hash:
		_block("La identidad cambió fuera de esta ventana. No se sobrescribió; vuelve a abrirla.")
		return false
	if not current_hash.is_empty() and _decode(_read(absolute)).is_empty():
		_block("La identidad guardada dejó de ser válida. No se sobrescribió.")
		return false
	if not current_hash.is_empty() and _equivalent(candidate,_saved_snapshot):
		load_notice = ""
		return true
	candidate.updated_at = maxi(_now(),int(candidate.created_at))
	var temporary: String = absolute + ".tmp"
	if not _write(temporary,JSON.stringify(candidate,"\t")):
		DirAccess.remove_absolute(temporary)
		return _io_failure("No se pudo guardar la identidad; se conserva la versión anterior.")
	if _decode(_read(temporary)).is_empty():
		DirAccess.remove_absolute(temporary)
		return _io_failure("La escritura de identidad no pudo verificarse.")
	if not current_hash.is_empty():
		if FileAccess.file_exists(absolute+".bak") and _decode(_read(absolute+".bak")).is_empty():
			DirAccess.remove_absolute(temporary)
			return _io_failure("La copia de identidad necesita revisión. No se reemplazó.")
		var backup_temp: String = absolute + ".bak.tmp"
		if not _copy(absolute,backup_temp) or not _rename(backup_temp,absolute+".bak"):
			DirAccess.remove_absolute(temporary)
			DirAccess.remove_absolute(backup_temp)
			return _io_failure("No se pudo conservar la copia anterior de identidad.")
	if not _rename(temporary,absolute):
		DirAccess.remove_absolute(temporary)
		return _io_failure("No se pudo completar el guardado de identidad.")
	data = candidate.duplicate(true)
	_saved_snapshot = data.duplicate(true)
	_loaded_hash = FileAccess.get_sha256(absolute)
	load_notice = ""
	return true

func _write(path: String, value: String) -> bool:
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(value)
	file.flush()
	var ok: bool = file.get_error()==OK
	file.close()
	return ok

func _copy(from: String, to: String) -> bool:
	return DirAccess.copy_absolute(from,to)==OK

func _rename(from: String, to: String) -> bool:
	return DirAccess.rename_absolute(from,to)==OK

func _io_failure(message: String) -> bool:
	last_save_ok = false
	load_notice = message
	return false

func _failure(message: String) -> Dictionary:
	last_save_ok = false
	return {"ok":false,"error":message,"entry":{}}

func _block(message: String) -> void:
	save_blocked = true
	last_save_ok = false
	load_notice = message

static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var file: FileAccess = FileAccess.open(path,FileAccess.READ)
	if file==null: return {}
	if file.get_length()>MAX_BYTES:
		file.close()
		return {}
	var parser: JSON = JSON.new()
	var error: Error = parser.parse(file.get_as_text())
	file.close()
	return parser.data if error==OK and parser.data is Dictionary else {}

static func _whole(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value)) and float(value)>=low and float(value)<=high

static func _identifier(value: Variant, prefix: String) -> bool:
	if not value is String: return false
	var pattern: RegEx = RegEx.new()
	pattern.compile("^"+prefix+"[0-9a-f]{32}$")
	return pattern.search(value)!=null

static func _exact_keys(value: Dictionary, expected: Array[String]) -> bool:
	if value.size()!=expected.size(): return false
	for key: String in expected:
		if not value.has(key): return false
	return true

static func _decode(raw: Dictionary) -> Dictionary:
	if not _exact_keys(raw,["version","account_id","created_at","updated_at","fighters","inventory"]) or not _whole(raw.get("version"),1,VERSION): return {}
	if not _identifier(raw.account_id,"acct_") or not _whole(raw.created_at,1,32503680000) or not _whole(raw.updated_at,int(raw.created_at),32503680000): return {}
	if not raw.fighters is Dictionary or not raw.inventory is Dictionary or raw.fighters.size()>Characters.IDS.size(): return {}
	var owned: Array[String] = []
	for key: Variant in raw.inventory:
		if not key is String or not raw.inventory[key] is Dictionary: return {}
		var item: Dictionary = Cosmetics.definition_for_inventory(key)
		var record: Dictionary = raw.inventory[key]
		if item.is_empty() or not record.get("source") is String or not record.get("requirement") is Dictionary or not _whole(record.get("unlocked_at"),1,32503680000): return {}
		if not _equivalent(record.requirement,item.unlock): return {}
		if bool(item.default):
			if not _exact_keys(record,["source","unlocked_at","requirement"]) or str(record.source)!="default": return {}
		else:
			if not _exact_keys(record,["source","unlocked_at","requirement","evidence"]) or str(record.source)!="reward" or not record.get("evidence") is Dictionary: return {}
			var evidence: Dictionary = record.evidence
			if not _exact_keys(evidence,["kind","value","archetype_id","mode"]): return {}
			var kind: String = str(item.unlock.kind)
			var cap: int = 50 if kind=="level" else 100 if kind=="story_cleared" else 10000000
			if str(evidence.kind)!=kind or not _whole(evidence.value,int(item.unlock.threshold),cap) or not str(evidence.archetype_id) in Characters.IDS: return {}
			if not str(evidence.mode) in ["league","story"] or (kind=="league_wins" and str(evidence.mode)!="league") or (kind=="story_cleared" and str(evidence.mode)!="story"): return {}
		owned.append(str(key))
	for key: String in Cosmetics.default_owned():
		if not key in owned and not (int(raw.version)==1 and key in V1_ADDED_DEFAULTS): return {}
	var fighter_ids: Array[String] = []
	for key: Variant in raw.fighters:
		if not key is String or not str(key) in Characters.IDS or not raw.fighters[key] is Dictionary: return {}
		var fighter: Dictionary = raw.fighters[key]
		if not _exact_keys(fighter,["fighter_id","archetype_id","identity","appearance"]): return {}
		if not _identifier(fighter.fighter_id,"ftr_") or str(fighter.fighter_id) in fighter_ids or str(fighter.archetype_id)!=str(key): return {}
		fighter_ids.append(str(fighter.fighter_id))
		if not fighter.identity is Dictionary or not fighter.appearance is Dictionary: return {}
		var identity: Dictionary = fighter.identity
		if not _exact_keys(identity,["display_name","normalized_name","created_at","updated_at","legacy_name","name_source"]): return {}
		if not identity.display_name is String or not identity.normalized_name is String or not identity.legacy_name is bool or not identity.name_source is String: return {}
		if not _whole(identity.created_at,int(raw.created_at),32503680000) or not _whole(identity.updated_at,int(identity.created_at),32503680000): return {}
		if bool(identity.legacy_name):
			if not str(identity.name_source) in ["legacy_league","legacy_story"] or str(identity.display_name).is_empty() or str(identity.display_name).length()>256: return {}
		else:
			var name_check: Dictionary = validate_name(str(identity.display_name))
			if not str(identity.name_source) in ["default","custom"] or not bool(name_check.ok) or str(name_check.display_name)!=str(identity.display_name): return {}
		if str(identity.normalized_name)!=_normalized(str(identity.display_name)): return {}
		var appearance: Dictionary = Cosmetics.validate_appearance(fighter.appearance,owned,str(key))
		if not bool(appearance.ok) or not _equivalent(appearance.appearance,fighter.appearance): return {}
	# Validate every original appearance against original ownership first. Migration
	# cannot repair equipped-but-unowned bodies, malformed records or old defaults.
	var result: Dictionary = raw.duplicate(true)
	if int(raw.version)==1:
		for key: String in V1_ADDED_DEFAULTS:
			if result.inventory.has(key): continue
			var item: Dictionary = Cosmetics.definition_for_inventory(key)
			if item.is_empty() or not bool(item.default): return {}
			result.inventory[key] = {"source":"default","unlocked_at":int(raw.updated_at),"requirement":item.unlock.duplicate(true)}
		result.version = VERSION
	return result

static func _equivalent(left: Variant, right: Variant) -> bool:
	if (left is int or left is float) and (right is int or right is float):
		return is_finite(float(left)) and is_finite(float(right)) and float(left)==float(right)
	if left is Dictionary and right is Dictionary:
		if left.size()!=right.size(): return false
		for key: Variant in left:
			if not right.has(key) or not _equivalent(left[key],right[key]): return false
		return true
	if left is Array and right is Array:
		if left.size()!=right.size(): return false
		for index: int in range(left.size()):
			if not _equivalent(left[index],right[index]): return false
		return true
	return typeof(left)==typeof(right) and left==right
