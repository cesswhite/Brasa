extends RefCounted
## Complete illustrated variants. Tiers 2 and 3 share one authored family of40 poses.
## No wear shader, procedural marks, gameplay state or negative resource cache.
const AnimationSet = preload("res://scripts/fighter_animation_set.gd")
const Profiles = preload("res://scripts/character_visual_profile.gd")
const ROOT := "res://assets/sprites/damage/illustrated-v2/"
const BANKS: Array[String] = ["base","movement","reactions"]
const CACHE_LIMIT := 6
static var _cache: Dictionary = {}
static var _lru: Array[String] = []
static var _validated: Dictionary = {}

static func clear_cache() -> void:
	_cache.clear()
	_lru.clear()
	_validated.clear()

static func cache_info() -> Dictionary:
	return {"limit":CACHE_LIMIT,"count":_cache.size(),"keys":_lru.duplicate(),"validated_bodies":_validated.keys(),"negative_cache":false}

static func expected_names(bank: String) -> Array:
	return AnimationSet.BASE_POSES.duplicate() if bank=="base" else AnimationSet.BANKS.get(bank,[]).duplicate()

static func _path(body: String, bank: String) -> String:
	return ROOT+body+"-"+bank+".png"

static func _stamp(body: String) -> String:
	if not body in AnimationSet.BASE_TO_BODY.values(): return ""
	var parts: PackedStringArray = []
	for bank: String in BANKS:
		var path := _path(body,bank)
		var meta := path.get_basename()+".json"
		# Missing packs are checked again: the art pipeline can finish during a session.
		if not FileAccess.file_exists(path) or not FileAccess.file_exists(meta) or not ResourceLoader.exists(path): return ""
		parts.append(str(FileAccess.get_modified_time(path))+":"+str(FileAccess.get_modified_time(meta)))
	return "/".join(parts)

static func prepare(body: String) -> bool:
	var stamp := _stamp(body)
	if stamp.is_empty(): return false
	if _validated.get(body,"")==stamp: return true
	var pending: Dictionary = {}
	for bank: String in BANKS:
		var pack := _read_bank(body,bank)
		if pack.is_empty(): return false
		pending[bank] = pack
	# Commit all three together: an incomplete grade never alternates clean/dirty by pose.
	for bank: String in BANKS: _remember(body+":"+bank,pending[bank])
	_validated[body] = stamp
	return true

static func bank(body: String, bank_name: String) -> Dictionary:
	# External callers may edit their snapshot without touching the shared cache.
	return _bank_reference(body,bank_name).duplicate(true)

static func _bank_reference(body: String, bank_name: String) -> Dictionary:
	# prepare() is the explicit revalidation boundary (combat preflight). Do not
	# stat six asset files on every rendered frame once this body is validated.
	if not bank_name in BANKS: return {}
	if not _validated.has(body) and not prepare(body): return {}
	var key := body+":"+bank_name
	if not _cache.has(key):
		var loaded := _read_bank(body,bank_name)
		if loaded.is_empty():
			_validated.erase(body)
			return {}
		_remember(key,loaded)
	_lru.erase(key)
	_lru.append(key)
	return _cache[key]

static func resolve_frame(body: String, tier: int, clean_frame: Dictionary) -> Dictionary:
	var result := clean_frame.duplicate(true)
	result["damage_art"] = false
	result["damage_variant"] = "clean"
	result["damage_tier"] = clampi(tier,0,3)
	result["damage_fallback"] = "" if tier<2 else "illustrated_pack_unavailable"
	if tier<2 or not bool(clean_frame.get("normalized",false)): return result
	if str(clean_frame.get("body_id",""))!=body: return result
	var loaded := _bank_reference(body,str(clean_frame.get("bank","base")))
	var illustrated: Dictionary = loaded.get("frames",{}).get(str(clean_frame.get("name","")),{})
	if illustrated.is_empty(): return result
	result = illustrated.duplicate(true)
	result["damage_tier"] = clampi(tier,2,3)
	return result

static func _remember(key: String, pack: Dictionary) -> void:
	_cache[key] = pack
	_lru.erase(key)
	_lru.append(key)
	while _lru.size()>CACHE_LIMIT: _cache.erase(_lru.pop_front())

static func _read_bank(body: String, bank_name: String) -> Dictionary:
	var path := _path(body,bank_name)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path.get_basename()+".json"))
	if not parsed is Dictionary: return {}
	var texture := ResourceLoader.load(path,"Texture2D",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	return _decode_bank(body,bank_name,parsed,texture,path)

static func _rect(raw: Variant) -> Rect2i:
	if not raw is Array or raw.size()!=4: return Rect2i()
	for value: Variant in raw:
		if not (value is int or value is float) or not is_finite(float(value)) or float(value)!=floor(float(value)): return Rect2i()
	return Rect2i(int(raw[0]),int(raw[1]),int(raw[2]),int(raw[3]))

static func _decode_bank(body: String, bank_name: String, metadata: Dictionary, texture: Texture2D, path: String) -> Dictionary:
	var profile := Profiles.profile(body)
	if profile.is_empty() or not bank_name in BANKS or texture==null: return {}
	if int(metadata.get("version",0))!=2 or metadata.get("body_id")!=body or metadata.get("bank")!=bank_name: return {}
	if metadata.get("profile_id")!=profile.profile_id: return {}
	if not Profiles.valid_canvas(metadata.get("canvas_px")) or not Profiles.valid_pivot(metadata.get("pivot_px")): return {}
	if not Profiles._number_matches(metadata.get("ground_baseline_px"),Profiles.PIVOT.y): return {}
	if not Profiles._number_matches(metadata.get("pixels_per_world_unit"),Profiles.PIXELS_PER_WORLD_UNIT): return {}
	var names := expected_names(bank_name)
	var definitions: Variant = metadata.get("frames")
	if not definitions is Array or definitions.size()!=names.size(): return {}
	var image := texture.get_image()
	if image==null or image.is_empty(): return {}
	if image.is_compressed(): image.decompress()
	if image.detect_alpha()==Image.ALPHA_NONE: return {}
	var frames: Dictionary = {}
	var regions: Array[Rect2i] = []
	for index: int in range(names.size()):
		var definition: Variant = definitions[index]
		if not definition is Dictionary or definition.get("name")!=names[index]: return {}
		var region := _rect(definition.get("region"))
		if region.size!=Profiles.CANVAS or not Rect2i(Vector2i.ZERO,image.get_size()).encloses(region): return {}
		for prior: Rect2i in regions:
			if prior.intersects(region): return {}
		regions.append(region)
		var used := image.get_region(region).get_used_rect()
		var bounds := _rect(definition.get("alpha_bounds_px",definition.get("alpha_bounds")))
		if not used.has_area() or not bounds.has_area() or not Rect2i(Vector2i.ZERO,Profiles.CANVAS).encloses(bounds): return {}
		if not definition.get("grounded") is bool or not Profiles._number_matches(definition.get("intrinsic_lift_px",0),0): return {}
		var sockets: Dictionary = {}
		var raw_sockets: Variant = definition.get("sockets_px",{})
		if not raw_sockets is Dictionary: return {}
		for socket: String in raw_sockets:
			var point: Variant = Profiles.point(raw_sockets[socket])
			if point==null or point.x<0 or point.y<0 or point.x>Profiles.CANVAS.x or point.y>Profiles.CANVAS.y: return {}
			sockets[socket] = point
		var visibility: Variant = definition.get("socket_visibility",{})
		if not visibility is Dictionary: return {}
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(region)
		atlas.filter_clip = true
		frames[str(names[index])] = {"name":str(names[index]),"texture":atlas,"region":region,"bounds":bounds,"anchor":Profiles.PIVOT,"canvas_px":Profiles.CANVAS,"bank":bank_name,"body_id":body,"profile_id":str(profile.profile_id),"illustrated_profile_id":body+":illustrated:v2","source_path":path,"scale":1.0/Profiles.PIXELS_PER_WORLD_UNIT,"normalized":true,"sockets_px":sockets,"socket_visibility":visibility.duplicate(true),"grounded":definition.grounded,"intrinsic_lift_px":0.0,"damage_art":true,"damage_variant":"illustrated","damage_tier":2,"damage_fallback":""}
		# Preserve the source's confidence/provenance: a projected landmark is not
		# promoted to newly authored anatomy merely because this texture is active.
		for key: String in ["socket_annotation_method","socket_verification","foot_socket_annotation"]:
			if definition.has(key): frames[str(names[index])][key] = definition[key].duplicate(true) if definition[key] is Dictionary else definition[key]
	return {"texture":texture,"frames":frames,"path":path,"body_id":body,"bank":bank_name,"normalized":true}
