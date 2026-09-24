extends Control
class_name GameHomePanel
## A quiet illustrated refuge, with navigation grouped by intent.
signal closed
signal action_requested(id: String)
const Visuals = preload("res://scripts/ui/game_visual_system.gd")
const REFUGES := preload("res://scripts/ui/character_refuges.gd")
var buttons: Array[Button] = []
var _scroll: ScrollContainer
var _navigation: VBoxContainer
var _close: Button
var _backdrop: Control
var _veil: TextureRect
var _caption_veil: TextureRect
var _scene_label: Label
var _scene_caption: Label
var _utilities: GridContainer
var _groups: Array[GridContainer] = []
var _built := false
var selected_refuge := "nima"
var _menu_on_right := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = Visuals.theme()
	resized.connect(_layout)

func configure(profile: Dictionary, definition: Dictionary, state: Dictionary, actions: Array, paused: bool = false) -> void:
	if _built: return
	_built = true
	selected_refuge = REFUGES.resolve_body(profile,definition)
	var refuge := REFUGES.scene(selected_refuge)
	_menu_on_right = str(refuge.get("menu_side","left")) == "right"
	var environment := state.duplicate(true)
	environment["refuge_body_id"] = selected_refuge
	_backdrop = Visuals.mount_background(self,"main_menu",environment)
	_veil = Visuals.reading_veil(self)
	_caption_veil = Visuals.battle_veil(true)
	add_child(_caption_veil)
	_close = Button.new()
	_close.custom_minimum_size = Vector2(48,48)
	_close.text = "×"
	_close.tooltip_text = "Volver al combate · Esc" if paused else "Volver al patio · Esc"
	Visuals.apply_button(_close,"icon")
	_close.pressed.connect(func(): closed.emit())
	add_child(_close)
	_scroll = ScrollContainer.new()
	_scroll.name = "RefugeNavigation"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	add_child(_scroll)
	_navigation = VBoxContainer.new()
	_navigation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_navigation.add_theme_constant_override("separation",12)
	_scroll.add_child(_navigation)
	var by_id := {}
	for action: Dictionary in actions: by_id[str(action.id)] = action
	if by_id.has("story"):
		var primary := _button(by_id.story,"primary",_navigation)
		primary.text = "Continuar historia" if bool(state.get("story_started",false)) else "Empezar historia"
		primary.custom_minimum_size.y = 62
		# Focus remains visible through the painted fill, without an outer outline.
		primary.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
		primary.focus_entered.connect(func(): primary.add_theme_stylebox_override("normal",Visuals.World.surface("primary","hover")))
		primary.focus_exited.connect(func(): primary.add_theme_stylebox_override("normal",Visuals.World.surface("primary","normal")))
	var fights := _grid()
	for id: String in ["arena","online"]:
		if by_id.has(id): _button(by_id[id],"secondary",fights)
	_section("TU COMPAÑERO",12)
	var growth := _grid()
	for id: String in ["training","customize","companions","profile","legacy","history"]:
		if by_id.has(id): _button(by_id[id],"quiet",growth)
	# Any future navigation remains reachable even if not explicitly grouped yet.
	for action: Dictionary in actions:
		if not str(action.id) in ["story","arena","online","training","customize","companions","profile","legacy","history","settings","help","log"]:
			_button(action,"quiet",growth)
	_section("",12)
	_utilities = _grid()
	_utilities.columns = 3
	for id: String in ["settings","help","log"]:
		if by_id.has(id): _button(by_id[id],"utility",_utilities)
	_scene_label = Label.new()
	_scene_label.text = str(refuge.title)
	Visuals.apply_label(_scene_label,"title")
	add_child(_scene_label)
	_scene_caption = Label.new()
	_scene_caption.text = str(refuge.caption)
	_scene_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Visuals.apply_label(_scene_caption,"secondary","text_secondary")
	add_child(_scene_caption)
	var targets: Array[Button] = []
	for button: Button in buttons:
		if not button.disabled: targets.append(button)
	targets.append(_close)
	for i in range(targets.size()):
		var target := targets[i]
		target.focus_next = target.get_path_to(targets[(i+1)%targets.size()])
		target.focus_previous = target.get_path_to(targets[posmod(i-1,targets.size())])
	_layout()
	Visuals.reveal(self)
	if not targets.is_empty(): targets[0].grab_focus.call_deferred()

func _section(title: String, top: float = 0) -> void:
	if top > 0:
		var gap := Control.new()
		gap.custom_minimum_size.y = top
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_navigation.add_child(gap)
	if title.is_empty(): return
	var label := Label.new()
	label.text = title
	Visuals.apply_label(label,"label","current")
	_navigation.add_child(label)

func _grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",8)
	_navigation.add_child(grid)
	_groups.append(grid)
	return grid

func _button(action: Dictionary, role: String, parent: Control) -> Button:
	var button := Button.new()
	button.name = "Action_"+str(action.id)
	button.set_meta("action_id",str(action.id))
	button.set_meta("refuge_role",role)
	button.text = str(action.label)
	button.clip_text = true
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = 48
	button.disabled = bool(action.get("disabled",false))
	button.tooltip_text = str(action.get("hint",""))
	Visuals.apply_button(button,"secondary" if role in ["quiet","utility"] else role)
	if role in ["quiet","utility"]:
		Visuals.apply_card_button(button)
		button.add_theme_stylebox_override("normal",StyleBoxEmpty.new() if role=="utility" else Visuals.open_card("normal",8))
		if role=="quiet": button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if role=="utility": button.add_theme_color_override("font_color",Visuals.color("text_secondary"))
	button.pressed.connect(func(): action_requested.emit(str(action.id)))
	buttons.append(button)
	parent.add_child(button)
	return button

func _layout() -> void:
	if not _built or _scene_caption == null: return
	var compact := size.x < 700
	var short := size.y < 540
	var pad := 24.0 if compact or short else roundf(clampf(size.x*0.045,40,80))
	_place(_close,Rect2(size.x-pad-48,pad-4,48,48))
	var start := pad
	var nav_width := minf(420,(size.x-pad*2)*0.44)
	var nav_x := size.x-pad-nav_width if _menu_on_right else pad
	if compact and not short:
		nav_width = size.x-pad*2
		nav_x = pad
		start = clampf(size.y*0.36,248,330)
	else:
		_place(_close,Rect2(pad if _menu_on_right else size.x-pad-48,pad-4,48,48))
	_place(_scroll,Rect2(nav_x,start,nav_width,maxf(80,size.y-start-pad)))
	_scene_label.visible = not compact and not short
	_scene_caption.visible = _scene_label.visible
	_caption_veil.visible = _scene_label.visible
	_place(_caption_veil,Rect2(0,size.y-180,size.x,180))
	var caption_x := pad if _menu_on_right else size.x*0.56
	_place(_scene_label,Rect2(caption_x,size.y-pad-78,size.x*0.44-pad,40))
	_place(_scene_caption,Rect2(caption_x,size.y-pad-34,size.x*0.44-pad,40))
	for button: Button in buttons:
		button.add_theme_font_size_override("font_size",13 if compact or short or str(button.get_meta("refuge_role"))=="utility" else 15)
	var gradient := Gradient.new()
	var texture := GradientTexture2D.new()
	if compact and not short:
		gradient.offsets = PackedFloat32Array([0,0.12,0.24,start/size.y,(start+65)/size.y,1])
		gradient.colors = PackedColorArray([Color(0.02,0.04,0.045,0.8),Color(0.02,0.04,0.045,0.35),Color(0.02,0.04,0.045,0.02),Color(0.02,0.04,0.045,0.90),Color(0.02,0.04,0.045,1),Color(0.02,0.04,0.045,1)])
		texture.fill_to = Vector2.DOWN
	else:
		gradient.offsets = PackedFloat32Array([0,0.28,0.48,0.65,1])
		gradient.colors = PackedColorArray([Color(0.02,0.04,0.045,0.93),Color(0.02,0.04,0.045,0.84),Color(0.02,0.04,0.045,0.38),Color(0.02,0.04,0.045,0.03),Color(0.02,0.04,0.045,0.09)])
		texture.fill_from = Vector2.RIGHT if _menu_on_right else Vector2.ZERO
		texture.fill_to = Vector2.ZERO if _menu_on_right else Vector2.RIGHT
	texture.gradient = gradient
	_veil.texture = texture

func _place(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size
