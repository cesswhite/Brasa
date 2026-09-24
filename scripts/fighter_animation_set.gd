extends RefCounted
class_name FighterAnimationSet
## Optional presentation assets. No gameplay state, timers, stats, RNG or save access.
const ROOT := "res://assets/sprites/sequences/"
const NORMALIZED_ROOT := "res://assets/sprites/normalized/"
const VisualProfiles = preload("res://scripts/character_visual_profile.gd")
const BASE_POSES := ["idle","idle_breathe","windup","punch","hit","dodge","victory","defeat"]
const CACHE_LIMIT := 6
const DISPLAY_HEIGHT := 166.0
const BASE_TO_BODY := {
	"taro_roque-v1":"taro_roque","taro_sabio-v1":"taro_sabio","duna_cora-v1":"duna_cora","duna_pedernal-v1":"duna_pedernal","bruma_ambar-v1":"bruma_ambar","bruma_nieve-v1":"bruma_nieve",
	"lince-v2":"nima","ajolote-v2":"luma","golem-v2":"mugo","sira-v3":"sira","iria-v3":"iria","duna-v3":"duna","kiro-v3":"kiro","neris-v3":"neris","taro-v3":"taro","balam-v1":"balam","tepa-v1":"tepa","xuna-v1":"xuna","copal-v1":"copal","ascua-v3":"ascua","vespera-v3":"vespera","onix-v1":"onix","bruma-v1":"bruma"
}
const BANKS := {
	"movement":["guard_shift","step_back","charge_crouch","heavy_windup","quick_windup","quick_extend","follow_through","recovery","dash_lean","dash_stride","jump_start","jump_apex","jump_strike","jump_fall","landing","guard_settle"],
	"reactions":["light_hit","body_hit","heavy_hit","critical_stagger","fall_start","fall_mid","grounded","getup_support","getup_kneel","getup_rise","low_health","victory_start","victory_peak","transform_start","transform_peak","transformed_idle"]
}
const FALLBACK := {"guard_shift":0,"step_back":2,"charge_crouch":5,"heavy_windup":2,"quick_windup":2,"quick_extend":3,"follow_through":3,"recovery":2,"dash_lean":2,"dash_stride":3,"jump_start":5,"jump_apex":2,"jump_strike":3,"jump_fall":3,"landing":5,"guard_settle":5,"light_hit":4,"body_hit":4,"heavy_hit":4,"critical_stagger":4,"fall_start":4,"fall_mid":7,"grounded":7,"getup_support":5,"getup_kneel":5,"getup_rise":2,"low_health":0,"victory_start":6,"victory_peak":6,"transform_start":2,"transform_peak":6,"transformed_idle":0}
const ATTACK_CLIPS := {
	"quick":{"windup":["quick_windup"],"travel":["quick_extend"],"recovery":["follow_through","recovery","guard_shift"]},
	"heavy":{"windup":["step_back","heavy_windup"],"travel":["heavy_windup","quick_extend"],"recovery":["follow_through","recovery","guard_settle"]},
	"charge":{"windup":["step_back","charge_crouch","heavy_windup"],"travel":["dash_lean","dash_stride","quick_extend"],"recovery":["follow_through","recovery","guard_shift"]},
	"dash":{"windup":["dash_lean"],"travel":["dash_stride","quick_extend"],"recovery":["follow_through","recovery","guard_shift"]},
	"jump":{"windup":["charge_crouch","jump_start"],"travel":["jump_apex","jump_strike"],"recovery":["jump_fall","landing","recovery"]},
	"counter":{"windup":["guard_settle","step_back"],"travel":["quick_extend"],"recovery":["follow_through","recovery"]},
	"guard":{"windup":["guard_shift","guard_settle"],"travel":["guard_settle"],"recovery":["guard_settle","guard_shift"]},
	"special":{"windup":["guard_shift","heavy_windup"],"travel":["heavy_windup","quick_extend"],"recovery":["recovery","guard_settle"]},
	"signature":{"windup":["step_back","transform_start","transform_peak"],"travel":["dash_lean","dash_stride","quick_extend"],"recovery":["follow_through","recovery","transformed_idle"]}
}
const REACTION_CLIPS := {
	"head":{"duration":0.36,"frames":["critical_stagger","light_hit","recovery"]},
	"low":{"duration":0.36,"frames":["body_hit","guard_settle","recovery"]},
	"airborne":{"duration":0.52,"frames":["heavy_hit","jump_fall","landing","recovery"]},
	"guard":{"duration":0.28,"frames":["guard_settle","body_hit","guard_settle"]},
	"status":{"duration":0.40,"frames":["body_hit","low_health","guard_shift"]},
	"stagger":{"duration":0.50,"frames":["critical_stagger","heavy_hit","recovery"]},
	"light":{"duration":0.28,"frames":["light_hit","recovery"]},
	"body":{"duration":0.36,"frames":["body_hit","light_hit","recovery"]},
	"heavy":{"duration":0.48,"frames":["heavy_hit","critical_stagger","recovery"]},
	"critical":{"duration":0.55,"frames":["critical_stagger","heavy_hit","body_hit","recovery"]},
	"knockback":{"duration":0.60,"frames":["heavy_hit","critical_stagger","step_back","recovery"]},
	"knockdown":{"duration":0.92,"frames":["critical_stagger","fall_start","fall_mid","grounded","getup_support","getup_kneel","getup_rise","guard_shift"]},
	"getup":{"duration":0.48,"frames":["getup_support","getup_kneel","getup_rise","guard_shift"]},
	"ko":{"duration":0.66,"frames":["critical_stagger","fall_start","fall_mid","grounded"]},
	"victory":{"duration":0.62,"frames":["recovery","victory_start","victory_peak"]},
	"transformation":{"duration":0.72,"frames":["charge_crouch","transform_start","transform_peak","transformed_idle"]}
}
const TRANSFORMATIONS := {"ascua":{"ember_core":{"id":"ember_core","trigger":"phase_change","duration":0.72,"lifetime":8.0,"visual_only":true,"stat_modifiers":{},"move_changes":{},"clip_overrides":{"idle":"transformed_idle"}}}}
const IMPACT_FX := ["none","small_hit","heavy_hit","critical_hit","dust","dash_trail","landing_dust","charge_energy","transformation"]
const HIT_REACTIONS := ["light","body","head","low","airborne","guard","status","stagger","heavy","critical","knockback","knockdown","getup"]
const CAMERA_FEEDBACK := ["none","small","medium","strong"]
static var _cache: Dictionary = {}
static var _lru: Array[String] = []
static var _missing: Dictionary = {}

static func body_for_atlas(path: String) -> String:
	if path.get_base_dir()!="res://assets/sprites" or path.get_extension().to_lower()!="png" or path.contains(".."): return ""
	return str(BASE_TO_BODY.get(path.get_file().get_basename(),""))

static func transformation(body: String, id: String) -> Dictionary:
	return TRANSFORMATIONS.get(body,{}).get(id,{}).duplicate(true)

static func phase_sample(move: Dictionary, time: float) -> Dictionary:
	var kind := str(move.get("animation",move.get("animation_type",move.get("type","quick"))))
	if bool(move.get("is_counter_reaction",false)): kind = "counter"
	elif kind=="counter" and float(move.get("damage_multiplier",0.0))<=0: kind="guard"
	if kind.begins_with("jump"): kind = "jump"
	if kind in ["technique","ability"]: kind = "special"
	if kind in ["defense","stance"]: kind = "guard"
	var clip: Dictionary = ATTACK_CLIPS.get(kind,ATTACK_CLIPS.quick)
	var windup := maxf(0.01,float(move.get("windup",0.12)))
	var travel := maxf(0.0,float(move.get("travel",0.10)))
	var recovery := maxf(0.06,float(move.get("recovery",0.20)))
	var phase := "windup"
	var progress := time/windup
	if time >= windup+travel:
		phase = "recovery"
		progress = (time-windup-travel)/recovery
	elif time >= windup:
		phase = "travel"
		progress = (time-windup)/maxf(0.001,travel)
	var frame := sample(clip[phase],progress)
	if phase == "recovery" and kind != "guard":
		# Reserve contact inside the existing recovery budget, then give every recovery
		# frame its share of the remaining time; never skip fall/follow-through at x2.
		var hold := minf(0.06,recovery*0.25)
		var since_contact := time-windup-travel
		frame = ("jump_strike" if kind=="jump" else "quick_extend") if since_contact<hold else sample(clip.recovery,(since_contact-hold)/maxf(0.001,recovery-hold))
	return {"clip":kind,"phase":phase,"progress":clampf(progress,0,1),"frame":frame}

static func sample(frames: Array, progress: float) -> String:
	if frames.is_empty(): return "guard_shift"
	return str(frames[mini(frames.size()-1,int(floor(clampf(progress,0,1)*frames.size())))])

static func reaction_for(event: Dictionary) -> Dictionary:
	var result := str(event.get("result","hit"))
	var move: Dictionary = event.move if event.get("move") is Dictionary else {}
	var kind := str(event.get("animation_type",move.get("animation_type","quick")))
	var reaction := "light"
	var fx := "small_hit"
	var stop := 0.0
	var camera := "none"
	if result in ["dodge","miss"]: return {"reaction":result,"impact_fx":"none","hit_stop":0.0,"camera_feedback":"none"}
	if bool(event.get("signature",false)) or result=="signature":
		reaction="knockdown"; fx="heavy_hit"; stop=0.075; camera="strong"
	elif result=="critical":
		reaction="critical"; fx="critical_hit"; stop=0.055; camera="medium"
	elif kind=="charge":
		reaction="knockback"; fx="heavy_hit"; stop=0.045; camera="medium"
	elif kind=="heavy" or kind.begins_with("jump"):
		reaction="heavy"; fx="heavy_hit"; stop=0.035; camera="small"
	elif kind in ["technique","special","counter"]: reaction="body"; fx="small_hit"
	# Only an explicit event can request a special knockdown, never a new random roll.
	if bool(event.get("knockdown",false)): reaction="knockdown"
	var presentation := {"reaction":reaction,"impact_fx":fx,"hit_stop":stop,"camera_feedback":camera}
	# Move defaults precede event overrides. Invalid individual values preserve the
	# previous value; neither authoritative events nor catalog data are mutated.
	for candidate: Variant in [move.get("presentation"),event.get("presentation")]:
		if not candidate is Dictionary: continue
		if candidate.get("impact_fx") is String and candidate.impact_fx in IMPACT_FX: presentation.impact_fx=candidate.impact_fx
		if candidate.get("hit_reaction") is String and candidate.hit_reaction in HIT_REACTIONS: presentation.reaction=candidate.hit_reaction
		if candidate.get("camera_feedback") is String and candidate.camera_feedback in CAMERA_FEEDBACK: presentation.camera_feedback=candidate.camera_feedback
		var hit_stop: Variant = candidate.get("hit_stop")
		if (hit_stop is float or hit_stop is int) and is_finite(float(hit_stop)): presentation.hit_stop=clampf(float(hit_stop),0,0.1)
	# Cosmetic configuration cannot revive a terminal actor or invent a knockout.
	if event.has("target_hp") and float(event.target_hp)<=0:
		presentation.reaction="ko"
		presentation.hit_stop=maxf(float(presentation.hit_stop),0.055)
	return presentation

static func frame(body: String, name: String) -> Dictionary:
	var bank := "movement" if name in BANKS.movement else "reactions"
	if not name in BANKS[bank] or not body in BASE_TO_BODY.values(): return {}
	var loaded := _load_bank(body,bank)
	return loaded.get("frames",{}).get(name,{})

static func available(body: String) -> bool:
	if not body in BASE_TO_BODY.values(): return false
	for bank: String in BANKS:
		var normalized_path := NORMALIZED_ROOT+body+"-"+bank+"-v2.png"
		if ResourceLoader.exists(normalized_path) and FileAccess.file_exists(normalized_path.get_basename()+".json") and not VisualProfiles.profile(body).is_empty(): return true
		var path := ROOT+body+"-"+bank+"-v1.png"
		if ResourceLoader.exists(path) and FileAccess.file_exists(path.get_basename()+".json"): return true
	return false

static func cache_info() -> Dictionary:
	return {"limit":CACHE_LIMIT,"count":_cache.size(),"keys":_lru.duplicate()}

static func clear_cache() -> void:
	_cache.clear()
	_lru.clear()
	_missing.clear()

static func _load_bank(body: String, bank: String) -> Dictionary:
	if not body in BASE_TO_BODY.values() or not BANKS.has(bank): return {}
	var key := body+"/"+bank
	if _cache.has(key):
		_lru.erase(key); _lru.append(key)
		return _cache[key]
	if _missing.has(key): return {}
	var normalized := normalized_pack(body,bank)
	if not normalized.is_empty():
		_cache[key]=normalized; _lru.append(key)
		while _lru.size()>CACHE_LIMIT: _cache.erase(_lru.pop_front())
		return normalized
	_missing[key] = true
	var path := ROOT+body+"-"+bank+"-v1.png"
	var meta_path := path.get_basename()+".json"
	# A PNG without validated sidecar is not a complete pack. Missing packs remain silent.
	if not ResourceLoader.exists(path) or not FileAccess.file_exists(meta_path): return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
	if not parsed is Dictionary: return {}
	var metadata: Dictionary = parsed
	if int(metadata.get("version",0))!=1 or str(metadata.get("body_id",""))!=body or str(metadata.get("bank",""))!=bank: return {}
	var definitions: Array = metadata.get("frames",[])
	if definitions.size()!=16: return {}
	var texture := ResourceLoader.load(path,"Texture2D") as Texture2D
	if texture==null: return {}
	var source := texture.get_image()
	if source==null or source.is_empty(): return {}
	if source.is_compressed(): source.decompress()
	if source.detect_alpha()==Image.ALPHA_NONE: return {}
	var result: Dictionary = {}
	var expected: Array = BANKS[bank]
	for index: int in range(16):
		if not definitions[index] is Dictionary: return {}
		var definition: Dictionary = definitions[index]
		if str(definition.get("name",""))!=str(expected[index]): return {}
		var raw: Array = definition.get("region",[])
		if raw.size()!=4: return {}
		var region := Rect2i(int(raw[0]),int(raw[1]),int(raw[2]),int(raw[3]))
		if region.size.x<1 or region.size.y<1 or not Rect2i(Vector2i.ZERO,source.get_size()).encloses(region): return {}
		var bounds := _bounds(source,region)
		if not bounds.has_area(): return {}
		var anchor := Vector2(bounds.position.x+bounds.size.x*0.5,bounds.end.y)
		var anchor_data: Array = definition.get("anchor",[])
		if anchor_data.size()==2: anchor=Vector2(float(anchor_data[0]),float(anchor_data[1]))
		if not is_finite(anchor.x) or not is_finite(anchor.y): return {}
		var atlas := AtlasTexture.new()
		atlas.atlas=texture; atlas.region=Rect2(region.position+bounds.position,bounds.size); atlas.filter_clip=true
		result[str(expected[index])] = {"name":str(expected[index]),"texture":atlas,"region":region,"bounds":bounds,"anchor":anchor,"bank":bank,"body_id":body,"source_path":path}
	var reference_name := "guard_shift" if bank=="movement" else "transformed_idle"
	var reference := float(metadata.get("reference_height",result[reference_name].bounds.size.y))
	if not is_finite(reference) or reference<16 or reference>source.get_height(): return {}
	for entry: Dictionary in result.values(): entry["scale"]=DISPLAY_HEIGHT/reference
	var loaded := {"texture":texture,"frames":result,"reference_height":reference,"path":path}
	_missing.erase(key)
	_cache[key]=loaded; _lru.append(key)
	while _lru.size()>CACHE_LIMIT: _cache.erase(_lru.pop_front())
	return loaded

static func normalized_pack(body: String, bank: String) -> Dictionary:
	if not body in BASE_TO_BODY.values() or (bank!="base" and not BANKS.has(bank)): return {}
	var profile := VisualProfiles.profile(body)
	if profile.is_empty(): return {}
	var path := NORMALIZED_ROOT+body+"-"+bank+"-v2.png"
	var meta_path := path.get_basename()+".json"
	if not ResourceLoader.exists(path) or not FileAccess.file_exists(meta_path): return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
	if not parsed is Dictionary: return {}
	var metadata: Dictionary = parsed
	if int(metadata.get("version",0))!=2 or str(metadata.get("body_id",""))!=body or str(metadata.get("bank",""))!=bank: return {}
	if str(metadata.get("profile_id",""))!=str(profile.profile_id): return {}
	if not VisualProfiles.valid_canvas(metadata.get("canvas_px")) or not VisualProfiles.valid_pivot(metadata.get("pivot_px")): return {}
	if not VisualProfiles._number_matches(metadata.get("ground_baseline_px"),VisualProfiles.PIVOT.y): return {}
	if not VisualProfiles._number_matches(metadata.get("pixels_per_world_unit"),VisualProfiles.PIXELS_PER_WORLD_UNIT): return {}
	var expected: Array = BASE_POSES if bank=="base" else BANKS[bank]
	var definitions: Variant = metadata.get("frames")
	if not definitions is Array or definitions.size()!=expected.size(): return {}
	var texture := ResourceLoader.load(path,"Texture2D") as Texture2D
	if texture==null: return {}
	var source := texture.get_image()
	if source==null or source.is_empty(): return {}
	if source.is_compressed(): source.decompress()
	if source.detect_alpha()==Image.ALPHA_NONE: return {}
	var fx_texture: Texture2D
	var fx_path := str(metadata.get("attached_fx_atlas",metadata.get("attached_fx_path","")))
	if not fx_path.is_empty():
		if not fx_path.begins_with(NORMALIZED_ROOT) or fx_path.contains("..") or not ResourceLoader.exists(fx_path): return {}
		fx_texture=ResourceLoader.load(fx_path,"Texture2D") as Texture2D
		if fx_texture==null or fx_texture.get_size()!=texture.get_size(): return {}
	var result: Dictionary = {}
	var regions: Array[Rect2i] = []
	for index: int in range(expected.size()):
		if not definitions[index] is Dictionary: return {}
		var definition: Dictionary=definitions[index]
		if str(definition.get("name",""))!=str(expected[index]): return {}
		var raw: Variant = definition.get("region")
		if not raw is Array or raw.size()!=4: return {}
		for component: Variant in raw:
			if not (component is int or component is float) or not is_finite(float(component)) or float(component)!=floor(float(component)): return {}
		var region := Rect2i(int(raw[0]),int(raw[1]),int(raw[2]),int(raw[3]))
		if region.size!=VisualProfiles.CANVAS or not Rect2i(Vector2i.ZERO,source.get_size()).encloses(region): return {}
		for prior: Rect2i in regions:
			if prior.intersects(region): return {}
		regions.append(region)
		var bounds := _bounds(source,region)
		# Optional offline alpha diagnostics exclude nearly invisible matte noise.
		# This rect never crops the full canvas or controls draw scale/origin.
		var supplied_bounds: Variant=definition.get("alpha_bounds_px",definition.get("alpha_bounds"))
		if supplied_bounds is Array and supplied_bounds.size()==4:
			bounds=Rect2i(int(supplied_bounds[0]),int(supplied_bounds[1]),int(supplied_bounds[2]),int(supplied_bounds[3]))
		if not bounds.has_area() or not Rect2i(Vector2i.ZERO,VisualProfiles.CANVAS).encloses(bounds): return {}
		var sockets: Dictionary = {}
		var socket_data: Variant=definition.get("sockets_px",{})
		if not socket_data is Dictionary: return {}
		for socket: String in socket_data:
			var point: Variant = VisualProfiles.point(socket_data[socket])
			if point==null: return {}
			sockets[socket]=point
		if not definition.get("grounded") is bool: return {}
		if not VisualProfiles._number_matches(definition.get("intrinsic_lift_px",0),0): return {}
		var atlas := AtlasTexture.new()
		atlas.atlas=texture; atlas.region=Rect2(region); atlas.filter_clip=true
		var entry := {"name":str(expected[index]),"texture":atlas,"region":region,"bounds":bounds,"anchor":VisualProfiles.PIVOT,"canvas_px":VisualProfiles.CANVAS,"bank":bank,"body_id":body,"profile_id":profile.profile_id,"source_path":path,"scale":1.0/VisualProfiles.PIXELS_PER_WORLD_UNIT,"normalized":true,"sockets_px":sockets,"socket_visibility":definition.get("socket_visibility",{}).duplicate(true) if definition.get("socket_visibility",{}) is Dictionary else {},"grounded":definition.grounded,"intrinsic_lift_px":0.0}
		var fx_region: Variant = definition.get("attached_fx_region")
		if fx_region!=null:
			# An empty entry means this frame has no attached effect. Geometry must
			# otherwise be identical: a second track may not choose its own framing.
			if not fx_region is Array: return {}
			if not fx_region.is_empty():
				if fx_texture==null or fx_region!=raw: return {}
				var fx_frame := AtlasTexture.new()
				fx_frame.atlas=fx_texture; fx_frame.region=Rect2(region); fx_frame.filter_clip=true
				entry["attached_fx_texture"]=fx_frame
		result[str(expected[index])]=entry
	return {"texture":texture,"frames":result,"profile":profile,"normalized":true,"source_size":source.get_size(),"path":path,"scale":1.0/VisualProfiles.PIXELS_PER_WORLD_UNIT,"body_id":body,"canvas_px":VisualProfiles.CANVAS,"pivot_px":VisualProfiles.PIVOT}

static func _bounds(image: Image, region: Rect2i) -> Rect2i:
	# Native image scanning avoids a ~100ms GDScript pixel loop on first contact.
	# Include soft alpha edges; the explicit floor anchor and bank scale stay fixed.
	return image.get_region(region).get_used_rect()
