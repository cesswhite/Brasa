extends Control
class_name WorldBackdrop
## One active environment, shared atlases, at most three purely decorative props.
const Visuals = preload("res://scripts/ui/world_visuals.gd")

var current_context := ""
var _background: TextureRect
var _base: ColorRect
var _shade: TextureRect
var _props_layer: Control
var _props: Array[Dictionary] = []
var _active_background_id := ""
var _state: Dictionary = {}
var _refuge_focus := Vector2(0.73,0.48)
var _is_refuge := false


func _ready() -> void:
	# Full-screen callers let the underlying arena suspend its hidden render tree.
	get_parent().set_meta("world_screen_background",true)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	clip_contents = true
	_ensure_nodes()
	resized.connect(_layout_props)
	if current_context.is_empty(): set_context("route_journey")


func _ensure_nodes() -> void:
	if _background != null: return
	_base = ColorRect.new()
	_base.name = "FallbackEnvironment"
	_base.color = Color("091b23")
	_add_full(_base)
	_background = TextureRect.new()
	_background.name = "CurrentEnvironment"
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_add_full(_background)
	_props_layer = Control.new()
	_props_layer.name = "DecorativeMemories"
	_add_full(_props_layer)
	_shade = TextureRect.new()
	_shade.name = "ReadabilityVeil"
	_shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_shade.stretch_mode = TextureRect.STRETCH_SCALE
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0,0.42,0.76,1.0])
	gradient.colors = PackedColorArray([Color(0.015,0.03,0.04,0.68),Color(0.015,0.03,0.04,0.14),Color(0.015,0.03,0.04,0.20),Color(0.015,0.03,0.04,0.88)])
	var veil := GradientTexture2D.new()
	veil.gradient = gradient
	veil.fill_from = Vector2(0,0)
	veil.fill_to = Vector2(0,1)
	_shade.texture = veil
	_add_full(_shade)


func _add_full(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.focus_mode = Control.FOCUS_NONE
	add_child(node)
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func set_context(id: String, state: Dictionary = {}) -> void:
	_ensure_nodes()
	current_context = id
	_state = state.duplicate(true)
	var theme_context := Visuals.context(id)
	_base.color = theme_context.shade
	var next_background := str(theme_context.background)
	_is_refuge = id == "main_menu" and state.has("refuge_body_id")
	if _is_refuge:
		var refuges: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/character_refuges.json"))
		var refuge: Dictionary = refuges.scenes.get(str(state.refuge_body_id),refuges.scenes.nima)
		next_background = str(refuge.asset)
		_refuge_focus = Vector2(float(refuge.focus[0]),float(refuge.focus[1]))
	_shade.visible = not _is_refuge
	if next_background != _active_background_id or _background.texture == null:
		# Replacing this reference releases the previous large environment. Only atlases cache.
		_background.texture = null
		_active_background_id = next_background
		_background.texture = Visuals.texture(next_background)
	_background.modulate = Color(str(theme_context.get("background_tint","ffffff")))
	for child: Node in _props_layer.get_children():
		_props_layer.remove_child(child)
		child.queue_free()
	_props = []
	for definition: Dictionary in Visuals.props_resolved(id,_state):
		if _is_refuge: break # Everyday props are painted into the illustration.
		var image := Visuals.region_texture(str(definition.asset),definition.get("region",[]))
		if image == null: continue
		var prop := TextureRect.new()
		prop.name = str(definition.id)
		prop.texture = image
		prop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		prop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		prop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		prop.focus_mode = Control.FOCUS_NONE
		prop.modulate = Color(str(definition.get("tint","ffffff")))
		_props_layer.add_child(prop)
		_props.append({"definition":definition,"node":prop})
	_layout_props()


func _layout_props() -> void:
	if _background != null:
		if _is_refuge and _background.texture != null:
			# Keep the painted subject in view on a portrait screen; never stretch art.
			_background.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			var view := Vector2(size.x,clampf(size.y*0.46,300,430) if size.x < 700 and size.y >= 540 else size.y)
			var pixels := Vector2(_background.texture.get_size())
			var factor := maxf(view.x/pixels.x,view.y/pixels.y)
			_background.size = pixels*factor
			_background.position = Vector2(clampf(view.x*0.5-_refuge_focus.x*_background.size.x,view.x-_background.size.x,0),clampf(view.y*0.5-_refuge_focus.y*_background.size.y,view.y-_background.size.y,0))
		else:
			_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for item: Dictionary in _props:
		var rect := Visuals.prop_rect(item.definition,size)
		item.node.position = rect.position
		item.node.size = rect.size
		item.node.visible = size.x >= float(item.definition.get("min_width",0))


func loaded_background_paths() -> Array[String]:
	var result: Array[String] = []
	if _background != null and _background.texture != null:
		result.append(Visuals.asset_path(_active_background_id))
	return result


func visible_prop_ids() -> Array[String]:
	var result: Array[String] = []
	for item: Dictionary in _props:
		if item.node.visible: result.append(str(item.definition.id))
	return result
