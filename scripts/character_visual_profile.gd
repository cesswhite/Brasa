extends RefCounted
class_name CharacterVisualProfile
## Physical artwork dimensions. This never reads gameplay stats or player saves.
const PATH := "res://data/character_visual_profiles.json"
const CANVAS := Vector2i(512,512)
const PIVOT := Vector2(256,448)
const PIXELS_PER_WORLD_UNIT := 1.5
const MAX_STANDING_HEIGHT := 214.0
# One camera envelope for all bodies, including anticipation, jumps and recoil.
const WORLD_ENVELOPE := Rect2(-184,-292,368,318)
# Shared idle/portrait camera, measured across all17 canonical idle/breathe
# poses (outward112.67, height214) plus cosmetic/breathing margin. A portrait
# never reserves the combat dash/jump envelope or fits an individual body.
const REST_ENVELOPE := Rect2(-122,-224,244,232)
# Explicit presentation cameras, measured across all17 bodies. The first
# unlocked attack is a quick strike; victory also reserves its raised arm/hop.
# Choose once when a preview button is pressed, never from a sampled frame.
const PORTRAIT_ATTACK_ENVELOPE := Rect2(-154,-224,308,232)
const PORTRAIT_VICTORY_ENVELOPE := Rect2(-132,-260,264,276)
static var _profiles: Dictionary = {}
static var _loaded := false

static func clear_cache() -> void:
	_profiles.clear()
	_loaded = false

static func profile(body_id: String) -> Dictionary:
	_load_profiles()
	return _profiles.get(body_id,{}).duplicate(true)

static func _load_profiles() -> void:
	if _loaded: return
	_loaded = true
	if not FileAccess.file_exists(PATH): return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not parsed is Dictionary or int(parsed.get("version",0)) != 1: return
	if not valid_canvas(parsed.get("canvas_px")) or not valid_pivot(parsed.get("pivot_px")): return
	if not _number_matches(parsed.get("pixels_per_world_unit"),PIXELS_PER_WORLD_UNIT): return
	var definitions: Variant = parsed.get("profiles")
	if not definitions is Dictionary: return
	for body: String in definitions:
		var entry: Variant = definitions[body]
		if not entry is Dictionary: continue
		if str(entry.get("profile_id",body+":normal:v1")) != body+":normal:v1": continue
		var accepted: Dictionary = entry.duplicate(true)
		accepted["body_id"] = body
		accepted["profile_id"] = body+":normal:v1"
		accepted["canvas_px"] = [CANVAS.x,CANVAS.y]
		accepted["pivot_px"] = [PIVOT.x,PIVOT.y]
		accepted["ground_baseline_px"] = PIVOT.y
		accepted["pixels_per_world_unit"] = PIXELS_PER_WORLD_UNIT
		_profiles[body] = accepted

static func valid_canvas(value: Variant) -> bool:
	return value is Array and value.size()==2 and _number_matches(value[0],CANVAS.x) and _number_matches(value[1],CANVAS.y)

static func valid_pivot(value: Variant) -> bool:
	return value is Array and value.size()==2 and _number_matches(value[0],PIVOT.x) and _number_matches(value[1],PIVOT.y)

static func _number_matches(value: Variant, expected: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and is_equal_approx(float(value),expected)

static func point(value: Variant) -> Variant:
	if not value is Array or value.size()!=2: return null
	for component: Variant in value:
		if not (component is int or component is float) or not is_finite(float(component)): return null
	return Vector2(float(value[0]),float(value[1]))

static func scene_scale(extent: Vector2, padding: Vector2 = Vector2(24,24)) -> float:
	var available := (extent-padding).max(Vector2.ONE)
	return maxf(0.05,minf(available.x/WORLD_ENVELOPE.size.x,available.y/WORLD_ENVELOPE.size.y))

static func portrait_envelope(presentation: String = "rest") -> Rect2:
	match presentation:
		"attack": return PORTRAIT_ATTACK_ENVELOPE
		"victory": return PORTRAIT_VICTORY_ENVELOPE
	return REST_ENVELOPE

static func portrait_scale(extent: Vector2, presentation: String = "rest", padding: Vector2 = Vector2(16,12)) -> float:
	var available := (extent-padding).max(Vector2.ONE)
	var envelope := portrait_envelope(presentation)
	return maxf(0.05,minf(available.x/envelope.size.x,available.y/envelope.size.y))
