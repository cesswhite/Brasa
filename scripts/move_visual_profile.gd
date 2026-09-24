extends RefCounted
class_name MoveVisualProfile
## Pure presentation metadata. Timings follow the authoritative move; markers
## never inflict damage, consume RNG, change progression or write a replay.
const Sequences = preload("res://scripts/fighter_animation_set.gd")
const PHASES := ["windup", "travel", "recovery"]
const EVENTS := ["left_foot_impact", "right_foot_impact", "jump_takeoff", "landing", "slide_start", "slide_end", "step_back_start", "charge_start", "attached_fx_start", "dash_start", "follow_through", "recovery_complete"]
const ANCHORS := ["body", "core", "chest", "hand", "left_hand", "right_hand", "feet", "left_foot", "right_foot", "head", "back", "ground"]
const FX_IDS := ["none", "small_hit", "heavy_hit", "critical_hit", "dust", "dust_small", "dust_medium", "dust_heavy", "footplant_dust", "dash_dust", "slide_dust", "landing_dust", "knockback_dust", "stone_debris", "dash_trail", "charge_energy", "transformation"]

static func _marker(id: String, event: String, phase: String, at: float, anchor: String = "ground", fx: String = "none", attached: bool = false) -> Dictionary:
	return {"id":id,"event":event,"phase":phase,"at":at,"anchor":anchor,"fx":fx,"attached":attached}

static func defaults(kind: String) -> Dictionary:
	var profile := {"animation_id":kind,"composite_animation_variant":"","attached_fx_animation":"","impact_fx":"small_hit","trail_fx":"none","ground_fx":"none","hit_reaction":"light","camera_feedback":"none","hit_stop":0.0,"sound_event":"hit","transformation_requirement":"","events":[]}
	var events: Array[Dictionary] = []
	if kind in ["guard", "counter"]:
		events.append(_marker("guard_plant","left_foot_impact","windup",0.65))
	elif kind == "quick":
		profile.ground_fx="footplant_dust"
		events.append(_marker("quick_plant","right_foot_impact","windup",0.70,"right_foot","footplant_dust"))
	elif kind in ["heavy", "charge", "signature"]:
		profile.merge({"impact_fx":"heavy_hit","ground_fx":"footplant_dust","hit_reaction":"heavy","camera_feedback":"small","hit_stop":0.035,"sound_event":"heavy"},true)
		events.append(_marker("step_back","step_back_start","windup",0.0))
		events.append(_marker("charge_start","charge_start","windup",0.0,"hand","charge_energy",true))
		events.append(_marker("attached_fx","attached_fx_start","windup",0.25,"core"))
		events.append(_marker("plant","right_foot_impact","windup",0.35,"right_foot","footplant_dust"))
		profile.attached_fx_animation="charge_core_hand"
		if kind in ["charge", "signature"]:
			profile.merge({"trail_fx":"dash_trail","ground_fx":"dash_dust","hit_reaction":"knockback","camera_feedback":"medium","hit_stop":0.045},true)
			events.append(_marker("dash_ground","slide_start","travel",0.0,"ground","dash_dust"))
			events.append(_marker("dash_trail","dash_start","travel",0.0,"back","dash_trail",true))
			events.append(_marker("dash_stop","slide_end","recovery",0.18,"ground","slide_dust"))
	elif kind == "dash":
		profile.merge({"trail_fx":"dash_trail","ground_fx":"dash_dust","sound_event":"dash"},true)
		events.append(_marker("dash_ground","slide_start","travel",0.0,"ground","dash_dust"))
		events.append(_marker("dash_trail","dash_start","travel",0.0,"back","dash_trail",true))
		events.append(_marker("dash_stop","slide_end","recovery",0.18,"ground","slide_dust"))
	elif kind == "jump":
		profile.merge({"ground_fx":"landing_dust","impact_fx":"heavy_hit","hit_reaction":"heavy","sound_event":"heavy","camera_feedback":"small","hit_stop":0.035},true)
		events.append(_marker("takeoff","jump_takeoff","windup",0.60,"ground","dust_small"))
		events.append(_marker("landing","landing","recovery",0.40,"ground","landing_dust"))
		events.append(_marker("landing_debris","right_foot_impact","recovery",0.40,"ground","stone_debris"))
	elif kind == "special":
		events.append(_marker("special_plant","left_foot_impact","windup",0.70,"left_foot","footplant_dust"))
	if kind not in ["guard", "counter"]:
		events.append(_marker("follow_through","follow_through","recovery",0.10))
	events.append(_marker("recovery","recovery_complete","recovery",1.0))
	profile.events=events
	return profile

static func resolve(event: Dictionary) -> Dictionary:
	var move: Dictionary = event.get("move",{}) if event.get("move",{}) is Dictionary else {}
	var kind := str(Sequences.phase_sample(move,0.0).clip)
	var profile := defaults(kind)
	for raw: Variant in [move.get("presentation"), event.get("presentation")]:
		if not raw is Dictionary: continue
		for key: String in ["composite_animation_variant","attached_fx_animation","sound_event","transformation_requirement"]:
			if raw.get(key) is String and str(raw[key]).length() <= 80: profile[key]=raw[key]
		for key: String in ["impact_fx","trail_fx","ground_fx"]:
			if raw.get(key) is String and raw[key] in FX_IDS: profile[key]=raw[key]
		if raw.get("hit_reaction") is String and raw.hit_reaction in Sequences.HIT_REACTIONS: profile.hit_reaction=raw.hit_reaction
		if raw.get("camera_feedback") is String and raw.camera_feedback in Sequences.CAMERA_FEEDBACK: profile.camera_feedback=raw.camera_feedback
		if _finite(raw.get("hit_stop")): profile.hit_stop=clampf(float(raw.hit_stop),0.0,0.1)
	# A move's timing/animation comes from the simulation, not an arbitrary override.
	for marker: Dictionary in profile.events:
		if str(marker.id)=="dash_trail": marker.fx=profile.trail_fx
		if str(marker.id)=="dash_ground": marker.fx=profile.ground_fx
	profile["markers"]=_resolve_markers(profile.events,move)
	return profile

static func _finite(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func _duration(value: Variant, fallback: float, minimum: float) -> float:
	return maxf(minimum,float(value)) if _finite(value) else fallback

static func _resolve_markers(events: Array, move: Dictionary) -> Array[Dictionary]:
	var windup := _duration(move.get("windup"),0.12,0.01)
	var travel := _duration(move.get("travel"),0.10,0.0)
	var recovery := _duration(move.get("recovery"),0.20,0.06)
	var lengths := {"windup":windup,"travel":travel,"recovery":recovery}
	var starts := {"windup":0.0,"travel":windup,"recovery":windup+travel}
	var result: Array[Dictionary] = []
	for source: Dictionary in events:
		var marker := source.duplicate(true)
		marker["time"]=float(starts[marker.phase])+float(lengths[marker.phase])*clampf(float(marker.at),0,1)
		result.append(marker)
	result.sort_custom(func(a: Dictionary,b: Dictionary)->bool: return float(a.time)<float(b.time))
	return result
