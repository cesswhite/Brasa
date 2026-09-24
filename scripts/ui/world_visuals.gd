extends RefCounted
class_name WorldVisuals
## Read-only visual registry. It never knows about a save, progression object or reward.

const MANIFEST_PATH := "res://data/ui_visual_manifest.json"
const MAX_PROPS := 3
static var _manifest: Dictionary = {}
static var _shared_textures: Dictionary = {}


static func _data() -> Dictionary:
	if _manifest.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
		if parsed is Dictionary: _manifest = parsed
	return _manifest


static func manifest() -> Dictionary:
	# Public snapshots remain isolated; internal reads do not clone the registry.
	return _data().duplicate(true)


static func context_id(section: String, chapter: int = 1, boss: bool = false) -> String:
	if section == "route":
		if boss:
			if chapter == 1: return "route_boss_journey"
			return "route_boss_storm" if chapter == 2 else "route_boss_late"
		if chapter == 2: return "route_storm"
		return "route_late" if chapter > 2 else "route_journey"
	return {"upgrades":"workshop", "workshop":"workshop", "moves":"moves", "companions":"camp", "camp":"camp", "legacy":"legacy"}.get(section,"route_journey")


static func context(id: String) -> Dictionary:
	var data := _data()
	var result: Dictionary = data.contexts.get(id,data.contexts.route_journey).duplicate(true)
	result["accent"] = Color(str(result.get("accent","efb66f")))
	result["shade"] = Color(str(result.get("shade","091b23")))
	return result


static func asset_definition(id: String) -> Dictionary:
	return _data().get("assets",{}).get(id,{}).duplicate(true)


static func asset_path(id: String) -> String:
	var definition := asset_definition(id)
	var path := str(definition.get("path",""))
	return path if path.begins_with("res://assets/") and not ".." in path.split("/") and not "\\" in path else ""


static func texture(id: String) -> Texture2D:
	var definition := asset_definition(id)
	var shared := bool(definition.get("shared",false))
	if shared and _shared_textures.has(id): return _shared_textures[id]
	var path := asset_path(id)
	if path.is_empty() or not ResourceLoader.exists(path): return null
	var loaded := ResourceLoader.load(path,"Texture2D") as Texture2D
	var runtime_scale := float(definition.get("runtime_scale",1.0))
	if loaded != null and runtime_scale > 0 and runtime_scale < 1:
		# Native adaptation for 48px controls: preserve the metal endcaps at their display scale.
		# The generated PNG and its import remain untouched; only this shared GPU texture is small.
		var pixels := loaded.get_image()
		pixels.resize(maxi(1,roundi(pixels.get_width()*runtime_scale)),maxi(1,roundi(pixels.get_height()*runtime_scale)),Image.INTERPOLATE_LANCZOS)
		loaded = ImageTexture.create_from_image(pixels)
	if shared and loaded != null: _shared_textures[id] = loaded
	return loaded


static func shared_texture_ids() -> Array[String]:
	var result: Array[String] = []
	for key: String in _shared_textures: result.append(key)
	result.sort()
	return result


static func region_texture(asset_id: String, region: Array) -> Texture2D:
	var sheet := texture(asset_id)
	if sheet == null: return null
	if region.size() != 4: return sheet
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = _pixel_region(sheet,region)
	atlas.filter_clip = true
	return atlas


static func _pixel_region(sheet: Texture2D, region: Array) -> Rect2:
	# Regions are fractions of the original sheet, retaining the original pixels.
	return Rect2(float(region[0])*sheet.get_width(),float(region[1])*sheet.get_height(),float(region[2])*sheet.get_width(),float(region[3])*sheet.get_height())


static func illustration(id: String) -> Texture2D:
	var definition: Dictionary = _data().get("surfaces",{}).get(id,{})
	if definition.is_empty(): return null
	return region_texture(str(definition.asset),definition.get("region",[]))


static func surface(role: String = "panel", state: String = "normal") -> StyleBox:
	var data := _data()
	var role_id := str(data.get("surface_aliases",{}).get(role,role))
	var definition: Dictionary = data.get("surfaces",{}).get(role_id,data.surfaces.panel)
	var sheet := texture(str(definition.asset))
	var tint := Color(str(data.get("states",{}).get(state,"ffffff")))
	if role == "danger": tint = Color("dc9a86") * tint
	if role == "navigation_active": tint = Color("ffe6b9") * tint
	if sheet == null: return _fallback(role,state)
	var style := StyleBoxTexture.new()
	style.texture = sheet
	style.region_rect = _pixel_region(sheet,definition.region)
	style.modulate_color = tint
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	var slices: Array = definition.get("slice",[14,14,14,14])
	var padding: Array = definition.get("padding",[16,10,16,10])
	for side: int in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		style.set_texture_margin(side,float(slices[side]))
		style.set_content_margin(side,float(padding[side]))
	return style


static func _fallback(role: String, state: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var primary := role in ["primary","navigation_active"]
	style.bg_color = Color("d3a763") if primary else Color("142c30")
	if state == "hover": style.bg_color = style.bg_color.lightened(0.12)
	if state == "pressed": style.bg_color = style.bg_color.darkened(0.18)
	if state == "disabled": style.bg_color = Color("1c292c")
	style.border_color = Color("ac8558") if primary else Color("496261")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


static func focus_style() -> StyleBoxFlat:
	# A contained wash highlights keyboard focus without an outside outline.
	# Negative expansion keeps the highlight inside clipped cards and scroll rows.
	var box := StyleBoxFlat.new()
	box.bg_color = Color("efb66f",0.22)
	box.set_border_width_all(0)
	box.set_corner_radius_all(4)
	box.set_expand_margin_all(-4)
	box.set_content_margin_all(0)
	return box


static func apply_button(button: Button, role: String = "secondary") -> void:
	for state: String in ["normal","hover","pressed","hover_pressed","disabled"]:
		var box := surface(role,"pressed" if state == "hover_pressed" else state)
		if role in ["navigation","navigation_active"]:
			box.content_margin_left = 3
			box.content_margin_right = 3
			box.content_margin_top = 8
			box.content_margin_bottom = 8
		button.add_theme_stylebox_override(state,box)
	button.add_theme_stylebox_override("focus",focus_style())
	var primary := role in ["primary","navigation_active"]
	for state: String in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:
		button.add_theme_color_override(state,Color("152329") if primary else Color("f5e7cf"))
	button.add_theme_color_override("font_disabled_color",Color("9ca9a6"))
	button.add_theme_color_override("font_shadow_color",Color(0,0,0,0.2 if primary else 0.8))
	button.add_theme_constant_override("shadow_offset_y",1)
	button.custom_minimum_size.y = maxf(44,button.custom_minimum_size.y)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.set_meta("world_visual_role",role)


static func apply_card(panel: PanelContainer, role: String = "panel") -> void:
	panel.add_theme_stylebox_override("panel",surface(role))
	panel.set_meta("world_visual_role",role)


static func props_resolved(id: String, state: Dictionary = {}) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	for definition: Dictionary in _data().get("props",[]):
		if not id in definition.get("eligible_screens",[]): continue
		if not _condition(definition.get("condition",{}),state): continue
		matches.append(definition.duplicate(true))
	matches.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if int(a.get("priority",0)) != int(b.get("priority",0)): return int(a.get("priority",0)) > int(b.get("priority",0))
		return str(a.id) < str(b.id))
	var result: Array[Dictionary] = []
	var anchors: Array[String] = []
	for prop: Dictionary in matches:
		var anchor := str(prop.get("anchor","lower_right"))
		if anchor in anchors: continue
		anchors.append(anchor)
		result.append(prop)
		if result.size() == MAX_PROPS: break
	return result


static func _condition(condition: Dictionary, state: Dictionary) -> bool:
	if condition.is_empty(): return true
	if condition.has("all"):
		for term: Dictionary in condition.all:
			if not _condition(term,state): return false
		return true
	if condition.has("any"):
		for term: Dictionary in condition.any:
			if _condition(term,state): return true
		return false
	var field := str(condition.get("field",""))
	var expected: Variant = condition.get("value")
	if field == "cosmetic_owned": return expected in state.get("owned_cosmetics",[])
	if field == "cosmetic_equipped":
		return str(state.get("appearance",{}).get(str(condition.get("slot","")),"")) == str(expected)
	if field == "body_style_id": return str(state.get("appearance",{}).get("body_style_id",state.get("character_id",""))) == str(expected)
	if field == "character_id": return str(state.get(field,"")) in expected if expected is Array else str(state.get(field,"")) == str(expected)
	if field in ["story_cleared","arena_wins"]: return int(state.get(field,0)) >= int(expected)
	return false


static func prop_rect(prop: Dictionary, viewport_size: Vector2) -> Rect2:
	var anchors: Dictionary = _data().get("anchors",{})
	var anchor: Dictionary = anchors.get(str(prop.get("anchor","lower_right")),anchors.lower_right)
	var relative: Array = anchor.get("position",[0.95,0.90])
	var pivot: Array = anchor.get("pivot",[1,1])
	var dimensions: Array = prop.get("size",[128,128])
	var factor := clampf(minf(viewport_size.x/1360.0,viewport_size.y/880.0),0.55,1.25)
	var extent := Vector2(float(dimensions[0]),float(dimensions[1]))*factor
	extent.x = minf(extent.x,maxf(0,viewport_size.x-16))
	extent.y = minf(extent.y,maxf(0,viewport_size.y-16))
	var position := Vector2(viewport_size.x*float(relative[0]),viewport_size.y*float(relative[1]))-extent*Vector2(float(pivot[0]),float(pivot[1]))
	position.x = clampf(position.x,8,maxf(8,viewport_size.x-extent.x-8))
	position.y = clampf(position.y,8,maxf(8,viewport_size.y-extent.y-8))
	return Rect2(position,extent)
