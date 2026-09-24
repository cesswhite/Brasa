extends RefCounted
class_name CharacterFamilies
## Curated presentation descriptors; never derives power from age or equipment.
const PATH := "res://data/character_families.json"
static var _data: Dictionary = {}
static func catalog() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary: _data = parsed
	return _data
static func individuals() -> Dictionary:
	return catalog().get("individuals", {}).duplicate(true)
static func individual(id: String) -> Dictionary:
	return catalog().get("individuals", {}).get(id, {}).duplicate(true)
static func base_body(id: String) -> String:
	return str(individual(id).get("base", id))
static func story_individual(body: String, level: int, boss: bool = false) -> Dictionary:
	if boss: return {}
	var selected: Dictionary = {}
	for entry: Dictionary in individuals().values():
		# Introductions guarantee encounter-to-unlock continuity. Afterwards,
		# variants belong to the original species and increase in experience.
		if int(entry.story_introduction) == level: return entry
		if str(entry.base) == body and level >= int(entry.story_introduction):
			if selected.is_empty() or int(entry.story_introduction) > int(selected.story_introduction): selected = entry
	return selected
