extends Control
class_name GameModal
## A visual shell only. Callers own actions, confirmation and persistence.

signal closed

const Visuals = preload("res://scripts/ui/game_visual_system.gd")
const OverlayFocus = preload("res://scripts/ui/components/game_overlay_focus.gd")
const Header = preload("res://scripts/ui/components/game_section_header.gd")

var max_width: float = 720.0
var preferred_height: float = 560.0
var manual_content: bool = false:
	set(value):
		manual_content = value
		if is_instance_valid(_canvas): _sync_content_mode()
var _panel: PanelContainer
var _body: VBoxContainer
var _canvas: Control
var _scroll: ScrollContainer
var _header: GameSectionHeader
var _close: Button
var _hint: Label
var _opener: WeakRef
var _environment: Control
var _location_layout := false


func _init() -> void:
	name = "GameModal"
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	resized.connect(_layout)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ensure_interface()
	_layout()


func configure(heading: String, subtitle: String = "", hint: String = "") -> void:
	_ensure_interface()
	_header.configure("", heading, subtitle)
	_hint.text = hint
	_hint.visible = not hint.is_empty()
	_layout()


func content() -> VBoxContainer:
	_ensure_interface()
	return _body


func canvas_content() -> Control:
	## Freeform coordinates start at (0, 0) below the shared heading. The canvas
	## follows the available viewport, so callers can keep their manual layout.
	_ensure_interface()
	manual_content = true
	return _canvas


func set_canvas_minimum_height(height: float) -> void:
	## Leave zero for a RichTextLabel with its own scrollbar. A taller form can
	## opt into the shell's scrolling without moving its children or callbacks.
	_ensure_interface()
	_canvas.custom_minimum_size.y = maxf(0, height) if is_finite(height) else 0.0


func parts() -> Dictionary:
	## Node aliases for incremental migrations; the shell still owns their layout.
	_ensure_interface()
	return {"panel": _panel, "heading": _header.heading_label, "subtitle": _header.subtitle_label, "close": _close, "hint": _hint, "scroll": _scroll}


func set_environment(section: String, state: Dictionary = {}) -> void:
	## Optional location behind the same shared modal. The caller supplies only
	## earned/owned state; the World registry resolves eligible decoration.
	_ensure_interface()
	if is_instance_valid(_environment):
		remove_child(_environment)
		_environment.queue_free()
	_environment = Visuals.mount_background(self, section, state)
	get_node("Overlay").color = Color(Visuals.color("background_dark"), 0.28)


func use_location_layout() -> void:
	## Full-screen sections keep the same header, close, focus and scrolling
	## contract, with Story's open composition over the illustrated location.
	_ensure_interface()
	_location_layout = true
	var open_surface := StyleBoxEmpty.new()
	_panel.add_theme_stylebox_override("panel",open_surface)
	_layout()


func _sync_content_mode() -> void:
	_body.visible = not manual_content
	_canvas.visible = manual_content
	_scroll.scroll_vertical = 0
	_layout.call_deferred()


func open(opener: Control = null) -> void:
	_ensure_interface()
	var entering := not visible
	if entering:
		var previous := opener
		if previous == null and is_inside_tree(): previous = get_viewport().gui_get_focus_owner()
		_opener = weakref(previous) if is_instance_valid(previous) else null
	show()
	if entering: Visuals.reveal(self)
	_layout()
	_focus_close.call_deferred()


func close() -> void:
	if not visible: return
	hide()
	var previous: Control = _opener.get_ref() as Control if _opener != null else null
	_opener = null
	if is_instance_valid(previous) and previous.is_visible_in_tree() and previous.focus_mode != Control.FOCUS_NONE:
		previous.grab_focus()
	closed.emit()


func _focus_close() -> void:
	if is_visible_in_tree(): _close.grab_focus()


func _ensure_interface() -> void:
	if is_instance_valid(_panel): return
	theme = Visuals.theme()
	var shade := ColorRect.new()
	shade.name = "Overlay"
	shade.color = Color(Visuals.color("background_dark"), 0.82)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.add_theme_stylebox_override("panel", Visuals.panel("modal"))
	add_child(_panel)
	# Wrapped header minima settle after the first container sort. Refit then,
	# rather than retaining a tall minimum measured before a width was assigned.
	_panel.minimum_size_changed.connect(_layout.call_deferred)
	var stack := VBoxContainer.new()
	stack.name = "Stack"
	stack.add_theme_constant_override("separation", Visuals.space("md"))
	_panel.add_child(stack)
	var top := HBoxContainer.new()
	top.name = "HeaderRow"
	top.add_theme_constant_override("separation", Visuals.space("sm"))
	stack.add_child(top)
	_header = Header.new()
	_header.configure("", "", "")
	top.add_child(_header)
	_close = Button.new()
	_close.name = "Close"
	_close.text = "×"
	_close.tooltip_text = "Cerrar · Esc"
	_close.custom_minimum_size = Vector2(48,48)
	_close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	Visuals.apply_button(_close, "icon")
	_close.pressed.connect(close)
	top.add_child(_close)
	_scroll = ScrollContainer.new()
	_scroll.name = "BodyScroll"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	stack.add_child(_scroll)
	_body = VBoxContainer.new()
	_body.name = "Content"
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", Visuals.space("sm"))
	_scroll.add_child(_body)
	_canvas = Control.new()
	_canvas.name = "CanvasContent"
	_canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_canvas)
	_hint = Label.new()
	_hint.name = "Hint"
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Visuals.apply_label(_hint, "secondary", "text_secondary")
	_hint.hide()
	stack.add_child(_hint)
	_sync_content_mode()


func _layout() -> void:
	if not is_instance_valid(_panel): return
	var compact := size.x < 600 or size.y < 540
	_header.set_compact(compact)
	_hint.visible = not _hint.text.is_empty() and size.x >= 600
	var margin := float(Visuals.space("sm") if compact else Visuals.space("lg"))
	if _location_layout: margin = float(Visuals.space("lg") if compact else Visuals.space("xxl"))
	var extent := Vector2(maxf(0,size.x-margin*2), maxf(0,size.y-margin*2)) if _location_layout else Vector2(minf(maxf(0,size.x-margin*2),max_width), minf(maxf(0,size.y-margin*2),preferred_height))
	_panel.position = (size-extent)*0.5
	_panel.size = extent


func _input(event: InputEvent) -> void:
	OverlayFocus.handle(event,self,close)
