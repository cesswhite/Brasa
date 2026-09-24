extends RefCounted
class_name GameVisualSystem
## Story is the authority. Every location inherits these controls and materials.
const World = preload("res://scripts/ui/world_visuals.gd")
const Backdrop = preload("res://scripts/ui/world_backdrop.gd")
const TOKEN_PATH := "res://data/game_visual_tokens.json"
# Constant aliases allow GDScript default arguments; values mirror the token resource.
const CREAM := Color("f5e7cf")
const MUTED := Color("9ab3ac")
const GOLD := Color("efb66f")
const TEAL := Color("7dd7bd")
const CORAL := Color("ed997f")
const SURFACE := Color("153137")
const DARK := Color("0c2228")
static var _tokens: Dictionary = {}
static var _theme: Theme
static var _fonts: Dictionary = {}
static var _icons: Dictionary = {}

static func _data() -> Dictionary:
	if _tokens.is_empty(): _tokens = JSON.parse_string(FileAccess.get_file_as_string(TOKEN_PATH))
	return _tokens

static func tokens() -> Dictionary:
	return _data().duplicate(true)

static func color(token: String) -> Color:
	return Color(str(_data().colors.get(token,"f5e7cf")))

static func space(key: String) -> int:
	return int(_data().spacing.get(key,12))

static func font(role: String = "body") -> Font:
	var family := "display" if role in ["display","title","hero","section","card"] else "body"
	if not _fonts.has(family):
		var resource := SystemFont.new()
		resource.font_names = PackedStringArray(_data().fonts[family])
		_fonts[family] = resource
	return _fonts[family]

static func font_size(role: String, compact: bool = false) -> int:
	var sizes: Array = _data().typography.get(role,[15,14])
	return int(sizes[1 if compact else 0])

static func panel(role: String = "standard", padding: float = -1) -> StyleBox:
	var id: String = {"standard":"panel","featured":"boss_panel","boss":"boss_panel","modal":"dialog"}.get(role,role)
	var box := World.surface(id)
	if padding >= 0: box.set_content_margin_all(padding)
	return box

static func focus() -> StyleBoxFlat:
	return World.focus_style()

static func rail(tone: String = "surface_dark", filled: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color(tone)
	box.border_color = color("bronze").darkened(0.35)
	box.set_border_width_all(0 if filled else 1)
	box.set_corner_radius_all(2)
	box.set_content_margin_all(0)
	return box

static func icon(id: String) -> Texture2D:
	if _icons.has(id): return _icons[id]
	# Small engraved marks share one bronze/cream weight; no platform icon pack.
	var paths: Dictionary = {
		"check":"M5 12l4 4 10-10", "unchecked":"M5 5h14v14H5z",
		"checked":"M5 5h14v14H5z M7 12l3 3 7-7",
		"radio":"M12 3l9 9-9 9-9-9z M12 8l4 4-4 4-4-4z",
		"radio_off":"M12 3l9 9-9 9-9-9z",
		"down":"M5 9l7 6 7-6", "up":"M5 15l7-6 7 6",
		"left":"M15 5l-6 7 6 7", "right":"M9 5l6 7-6 7",
		"close":"M6 6l12 12M18 6L6 18", "grabber":"M12 3l7 9-7 9-7-9z",
		"fold":"M5 9l7 6 7-6", "expand":"M9 5l6 7-6 7"
	}
	var path: String = paths.get(id,paths.check)
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path d="%s" transform="translate(0 1)" fill="none" stroke="#152329" stroke-width="3.5"/><path d="%s" fill="none" stroke="#e5c69b" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/></svg>' % [path,path]
	var image := Image.new()
	if image.load_svg_from_string(svg) != OK: return null
	_icons[id] = ImageTexture.create_from_image(image)
	return _icons[id]

static func slider_rail(vertical: bool, filled: bool = false, highlighted: bool = false) -> StyleBoxFlat:
	var box := rail("focus" if highlighted else ("current" if filled else "surface_dark"),filled)
	box.border_color = color("bronze")
	# Slider thickness comes from the style's minimum size, not the control height.
	box.set_content_margin(SIDE_LEFT,5 if vertical else 0)
	box.set_content_margin(SIDE_RIGHT,5 if vertical else 0)
	box.set_content_margin(SIDE_TOP,0 if vertical else 5)
	box.set_content_margin(SIDE_BOTTOM,0 if vertical else 5)
	box.set_corner_radius_all(4)
	return box

static func slider_handle(state: String) -> Texture2D:
	var key := "slider_handle_"+state
	if _icons.has(key): return _icons[key]
	var fill := color("focus" if state=="highlight" else ("text_disabled" if state=="disabled" else "current")).to_html(false)
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32"><path d="M10 3h12l7 7v12l-7 7H10l-7-7V10z" fill="#152329"/><path d="M11 5h10l6 6v10l-6 6H11l-6-6V11z" fill="#%s" stroke="#ac8558" stroke-width="2"/><path d="M13 11v10m6-10v10" stroke="#152329" stroke-width="2" stroke-linecap="round"/></svg>' % fill
	var image := Image.new()
	if image.load_svg_from_string(svg)!=OK: return icon("grabber")
	_icons[key] = ImageTexture.create_from_image(image)
	return _icons[key]

static func theme() -> Theme:
	if _theme != null: return _theme
	var design := Theme.new()
	design.default_font = font()
	design.default_font_size = font_size("body")
	for type: String in ["Label","Button","LineEdit","TextEdit","OptionButton","CheckBox","CheckButton","PopupMenu","Tree","ItemList","TabBar","TabContainer"]:
		design.set_color("font_color",type,color("text_primary"))
		design.set_color("font_hover_color",type,color("text_primary"))
		design.set_color("font_focus_color",type,color("text_primary"))
		design.set_color("font_pressed_color",type,color("text_primary"))
		design.set_color("font_disabled_color",type,color("text_disabled"))
	for type: String in ["Button","OptionButton","CheckBox","CheckButton"]:
		for state: String in ["normal","hover","pressed","hover_pressed","disabled"]:
			design.set_stylebox(state,type,World.surface("secondary","pressed" if state=="hover_pressed" else state))
		design.set_stylebox("focus",type,focus())
		design.set_font_size("font_size",type,font_size("button"))
		design.set_constant("h_separation",type,space("sm"))
	for type: String in ["Panel","PanelContainer","PopupPanel","PopupMenu","TabContainer"]:
		design.set_stylebox("panel",type,panel())
	design.set_stylebox("panel","TooltipPanel",panel("tooltip",12))
	design.set_color("font_color","TooltipLabel",color("text_primary"))
	design.set_font_size("font_size","TooltipLabel",font_size("tooltip"))
	design.set_stylebox("hover","PopupMenu",World.surface("navigation_active"))
	design.set_color("font_hover_color","PopupMenu",color("ink"))
	design.set_constant("v_separation","PopupMenu",12)
	for type: String in ["LineEdit","TextEdit"]:
		design.set_stylebox("normal",type,panel("standard",12))
		design.set_stylebox("read_only",type,panel("standard",12))
		design.set_stylebox("focus",type,focus())
		design.set_color("caret_color",type,color("current"))
		design.set_color("font_placeholder_color",type,color("text_muted"))
		design.set_color("selection_color",type,Color(color("success"),0.28))
	design.set_color("default_color","RichTextLabel",color("text_primary"))
	design.set_constant("line_separation","RichTextLabel",space("xs"))
	for type: String in ["HScrollBar","VScrollBar"]:
		design.set_stylebox("scroll",type,rail())
		design.set_stylebox("scroll_focus",type,rail())
		for state: String in ["grabber","grabber_highlight","grabber_pressed"]:
			var grab := rail("bronze",true)
			grab.set_content_margin_all(5)
			design.set_stylebox(state,type,grab)
		for arrow: String in ["increment","decrement","increment_highlight","decrement_highlight","increment_pressed","decrement_pressed"]:
			design.set_icon(arrow,type,ImageTexture.create_from_image(Image.create(1,1,false,Image.FORMAT_RGBA8)))
	for type: String in ["HSlider","VSlider"]:
		design.set_stylebox("slider",type,slider_rail(type=="VSlider"))
		design.set_stylebox("grabber_area",type,slider_rail(type=="VSlider",true))
		design.set_stylebox("grabber_area_highlight",type,slider_rail(type=="VSlider",true,true))
		design.set_icon("grabber",type,slider_handle("normal"))
		design.set_icon("grabber_highlight",type,slider_handle("highlight"))
		design.set_icon("grabber_disabled",type,slider_handle("disabled"))
	for type: String in ["CheckBox","CheckButton"]:
		for state: String in ["checked","checked_disabled","on","on_disabled"]: design.set_icon(state,type,icon("checked"))
		for state: String in ["unchecked","unchecked_disabled","off","off_disabled"]: design.set_icon(state,type,icon("unchecked"))
		design.set_icon("radio_checked",type,icon("radio"))
		design.set_icon("radio_unchecked",type,icon("radio_off"))
	design.set_icon("arrow","OptionButton",icon("down"))
	design.set_constant("arrow_margin","OptionButton",12)
	for type: String in ["Tree","ItemList"]:
		design.set_stylebox("panel",type,panel("standard"))
		design.set_stylebox("focus",type,focus())
		design.set_stylebox("selected",type,open_card("selected"))
		design.set_stylebox("selected_focus",type,open_card("selected"))
		design.set_stylebox("cursor",type,focus())
		design.set_stylebox("cursor_unfocused",type,open_card())
		design.set_color("font_selected_color",type,color("text_primary"))
		design.set_color("guide_color",type,Color(color("bronze"),0.25))
	design.set_icon("checked","Tree",icon("checked"))
	design.set_icon("unchecked","Tree",icon("unchecked"))
	design.set_icon("arrow","Tree",icon("down"))
	design.set_icon("arrow_collapsed","Tree",icon("right"))
	for key: String in ["checked","unchecked","radio_checked","radio_unchecked"]:
		design.set_icon(key,"PopupMenu",icon({"radio_checked":"radio","radio_unchecked":"radio_off"}.get(key,key)))
	design.set_icon("submenu","PopupMenu",icon("right"))
	design.set_stylebox("separator","PopupMenu",rail("bronze",true))
	for type: String in ["TabBar","TabContainer"]:
		design.set_stylebox("tab_selected",type,World.surface("navigation_active"))
		design.set_stylebox("tab_unselected",type,World.surface("navigation"))
		design.set_stylebox("tab_hovered",type,World.surface("navigation","hover"))
		design.set_stylebox("tab_disabled",type,World.surface("navigation","disabled"))
		design.set_stylebox("tab_focus",type,focus())
		design.set_color("font_selected_color",type,color("ink"))
		design.set_color("font_unselected_color",type,color("text_primary"))
	for type: String in ["HBoxContainer","VBoxContainer","GridContainer"]:
		design.set_constant("separation",type,space("sm"))
		design.set_constant("h_separation",type,space("sm"))
		design.set_constant("v_separation",type,space("sm"))
	for type: String in ["HSeparator","VSeparator"]: design.set_stylebox("separator",type,rail("bronze",true))
	design.set_stylebox("background","ProgressBar",rail())
	design.set_stylebox("fill","ProgressBar",rail("current",true))
	# Named Theme variations let new scenes opt in without inventing local styles.
	for variation: String in ["GameButtonPrimary","GameButtonSecondary","GameButtonDanger","GameNavigation","GameNavigationActive"]:
		var role: String = {"GameButtonPrimary":"primary","GameButtonSecondary":"secondary","GameButtonDanger":"danger","GameNavigation":"navigation","GameNavigationActive":"navigation_active"}[variation]
		design.set_type_variation(variation,"Button")
		for state: String in ["normal","hover","pressed","hover_pressed","disabled"]:
			design.set_stylebox(state,variation,World.surface(role,"pressed" if state=="hover_pressed" else state))
		for state: String in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
			design.set_color(state,variation,color("ink") if role in ["primary","navigation_active"] else color("text_primary"))
	for variation: String in ["GamePanel","GameFeaturedPanel","GameBossPanel","GameRewardPanel"]:
		design.set_type_variation(variation,"PanelContainer")
		design.set_stylebox("panel",variation,panel({"GamePanel":"standard","GameFeaturedPanel":"featured","GameBossPanel":"boss","GameRewardPanel":"reward"}[variation]))
	_theme = design
	return _theme

static func apply_button(button: Button, role: String = "secondary") -> void:
	World.apply_button(button,"secondary" if role=="icon" else role)
	button.add_theme_font_override("font",font())
	button.add_theme_font_size_override("font_size",font_size("button"))
	if role == "icon":
		button.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover",open_card("hover",0))
		button.add_theme_stylebox_override("pressed",open_card("selected",0))
		button.add_theme_stylebox_override("hover_pressed",open_card("selected",0))
		button.add_theme_stylebox_override("disabled",StyleBoxEmpty.new())
		button.add_theme_font_size_override("font_size",24)
	button.set_meta("game_component","button")
	button.set_meta("game_visual_role",role)

static func apply_label(label: Label, role: String = "body", tone: String = "text_primary") -> void:
	label.add_theme_font_override("font",font(role))
	label.add_theme_font_size_override("font_size",font_size(role))
	label.add_theme_color_override("font_color",color(tone))
	label.set_meta("game_component","label")
	label.set_meta("game_typography",role)

static func apply_progress(bar: ProgressBar, kind: String = "xp") -> void:
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background",rail())
	bar.add_theme_stylebox_override("fill",rail({"xp":"current","health":"success","rival":"danger"}.get(kind,kind),true))
	bar.set_meta("game_component","progress")

static func apply_option(option: OptionButton) -> void:
	apply_button(option,"secondary")
	option.get_popup().theme = theme()
	option.add_theme_icon_override("arrow",icon("down"))

static func open_card(state: String = "normal", padding: float = 12) -> StyleBoxFlat:
	# Story's companion cards are open to the environment, with a stitched lower edge.
	var box := StyleBoxFlat.new()
	box.bg_color = Color(SURFACE,0.42 if state=="selected" else (0.55 if state=="hover" else 0.16))
	box.border_color = GOLD if state=="selected" else Color(MUTED,0.24)
	box.border_width_bottom = 2 if state=="selected" else 1
	box.set_content_margin_all(padding)
	return box

static func apply_card_button(button: Button, selected: bool = false) -> void:
	button.add_theme_stylebox_override("normal",open_card("selected" if selected else "normal"))
	button.add_theme_stylebox_override("hover",open_card("hover"))
	button.add_theme_stylebox_override("pressed",open_card("selected"))
	button.add_theme_stylebox_override("hover_pressed",open_card("selected"))
	button.add_theme_stylebox_override("disabled",open_card())
	button.add_theme_stylebox_override("focus",focus())
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.set_meta("game_component","character_card")

static func training_card(state: String = "normal") -> StyleBoxFlat:
	# The workshop needs a quieter reading surface behind numerical comparisons.
	var box := open_card(state,16)
	box.bg_color = Color(SURFACE,0.62 if state=="selected" else (0.56 if state=="hover" else 0.42))
	return box

static func stat_row(caption: String, value: String, tone: String = "text_primary") -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 32
	row.add_theme_constant_override("separation",space("md"))
	var label := Label.new()
	label.text = caption
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	apply_label(label,"body","text_secondary")
	row.add_child(label)
	var number := Label.new()
	number.text = value
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	apply_label(number,"body",tone)
	row.add_child(number)
	row.set_meta("game_component","stat_row")
	return row

static func apply_panel(control: Control, role: String = "standard", padding: float = -1) -> void:
	control.add_theme_stylebox_override("panel",panel(role,padding))
	control.set_meta("game_component","panel")
	control.set_meta("game_visual_role",role)

static func section_context(section: String) -> String:
	return str(_data().sections.get(section,section))

static func mount_background(parent: Control, section: String, state: Dictionary = {}) -> Control:
	var backdrop := Backdrop.new()
	backdrop.name = "GameEnvironment"
	parent.add_child(backdrop)
	parent.move_child(backdrop,0)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.set_context(section_context(section),state)
	return backdrop

static func reveal(control: Control) -> void:
	if bool(control.get_tree().get_meta("brasa_reduced_motion",false)): return
	control.modulate.a = 0.0
	control.create_tween().tween_property(control,"modulate:a",1.0,float(_data().motion.reveal_seconds)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

static func reading_veil(parent: Control) -> Control:
	var rect := TextureRect.new()
	rect.name = "StoryReadingVeil"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0,0.46,1])
	gradient.colors = PackedColorArray([Color(0.015,0.025,0.025,0.66),Color(0.015,0.025,0.025,0.42),Color(0.015,0.025,0.025,0.14)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2.ZERO
	texture.fill_to = Vector2.RIGHT
	rect.texture = texture
	parent.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return rect


static func battle_veil(bottom: bool) -> TextureRect:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.38, 0.72, 1.0])
	gradient.colors = PackedColorArray([Color(0.01,0.025,0.03,0), Color(0.01,0.025,0.03,0.38), Color(0.01,0.025,0.03,0.84), Color(0.005,0.012,0.016,0.96)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 4
	texture.height = 256
	texture.fill_from = Vector2(0,0) if bottom else Vector2(0,1)
	texture.fill_to = Vector2(0,1) if bottom else Vector2(0,0)
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect
