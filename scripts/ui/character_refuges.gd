extends RefCounted
class_name CharacterRefuges
## Read-only selection of authored art. It never mutates identity or progression.
const PATH := "res://data/character_refuges.json"
static var _scenes: Dictionary = {}

static func scenes() -> Dictionary:
	if _scenes.is_empty():
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_scenes = data.scenes
	return _scenes.duplicate(true)

static func resolve_body(profile: Dictionary, definition: Dictionary) -> String:
	var available := scenes()
	var appearance: Dictionary = profile.get("appearance",{})
	var body := str(appearance.get("body_style_id",""))
	if available.has(body): return body
	for candidate: Variant in [profile.get("character_id",""),definition.get("individual_id",""),definition.get("id","")]:
		if available.has(str(candidate)): return str(candidate)
	return "nima"

static func scene(body: String) -> Dictionary:
	var available := scenes()
	return available.get(body,available.nima).duplicate(true)
