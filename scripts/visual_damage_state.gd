extends RefCounted
class_name VisualDamageState
## Presentation only: no combat RNG, HP mutation, inventory or save writes.
const PATH := "res://data/character_damage_profiles.json"
const NAMES := ["clean", "worn", "damaged", "critical"]
static var _catalog: Dictionary = {}
var tier := 0
var target_tier := 0
var intensity := 0.0
var minimum_health := 1.0
var elapsed_since_hit := 10.0
var pending_age := 0.0
var material_kind := 0
var profile: Dictionary = {}
var damage_type := "physical"

static func catalog() -> Dictionary:
	if _catalog.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary: _catalog = parsed
	return _catalog

func configure(body: String) -> void:
	profile = catalog().get("profiles", {}).get(body, catalog().get("default", {})).duplicate(true)
	material_kind = int(profile.get("shader_material", 0))
	reset()

func reset() -> void:
	pending_age = 0.0
	tier = 0
	target_tier = 0
	intensity = 0.0
	minimum_health = 1.0
	elapsed_since_hit = 10.0
	damage_type = "physical"

func observe_health(ratio: float) -> void:
	if not is_finite(ratio): return
	ratio = clampf(ratio, 0.0, 1.0)
	if ratio < minimum_health:
		minimum_health = ratio
		elapsed_since_hit = 0.0
		var thresholds: Array = profile.get("thresholds", catalog().get("thresholds", [0.72, 0.45, 0.22]))
		var before := target_tier
		for index: int in range(thresholds.size()):
			if ratio <= float(thresholds[index]): target_tier = maxi(target_tier, index + 1)

		if before == tier and target_tier > tier: pending_age = 0.0

func observe_event(event: Dictionary) -> void:
	# Diagnostic category only; illustrated damage uses the same authored family.
	# This metadata does not draw residue, alter the atlas or mutate combat state.
	var kind := str(event.get("effect", event.get("status_id", "")))
	var presentation: Dictionary = event.get("presentation", {}) if event.get("presentation") is Dictionary else {}
	if kind == "burn": damage_type = "fire"
	elif str(presentation.get("hit_reaction",event.get("hit_reaction", ""))) in ["knockdown", "knockback"]: damage_type = "ground"

func advance(delta: float, reacting: bool, terminal: bool = false) -> void:
	elapsed_since_hit += maxf(0.0, delta)
	if target_tier > tier: pending_age += maxf(0.0, delta)
	# Repeated small hits cannot starve a pending tier. KO commits before landing.
	if target_tier > tier and ((not reacting and elapsed_since_hit >= 0.16) or pending_age >= 0.85 or terminal): tier = target_tier
	intensity = move_toward(intensity, float(tier), maxf(0.0, delta) * 5.0)

func snapshot() -> Dictionary:
	return {"tier": tier, "name": NAMES[clampi(tier, 0, 3)], "target_tier": target_tier, "intensity": intensity, "minimum_health": minimum_health, "damage_type": damage_type}
