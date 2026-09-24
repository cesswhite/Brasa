extends Panel
class_name GameBattleResultPanel
## Presentation only: the caller owns result text, XP, visibility and timing.
## Its children always fit the rectangle supplied by BattleLayout.

const Visuals = preload("res://scripts/ui/game_visual_system.gd")

var title_label: Label
var copy_label: Label
var xp_bar: ProgressBar
var _short := false
var _phone := false
var _progress_available := false


func _init() -> void:
	theme = Visuals.theme()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_meta("game_component", "battle_result")
	title_label = _label("Title")
	Visuals.apply_label(title_label, "hero", "current")
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	copy_label = _label("Copy")
	Visuals.apply_label(copy_label, "secondary", "text_primary")
	copy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	xp_bar = ProgressBar.new()
	xp_bar.name = "XP"
	xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xp_bar.step = 0.0
	Visuals.apply_progress(xp_bar, "xp")
	add_child(xp_bar)
	resized.connect(_layout)
	_layout()


func configure_progress(value: float, maximum: float) -> void:
	_progress_available = is_finite(maximum) and maximum > 0
	xp_bar.max_value = maximum if _progress_available else 1.0
	xp_bar.value = clampf(value, 0.0, xp_bar.max_value) if is_finite(value) else 0.0
	_layout()


func layout_compact(short: bool, phone: bool) -> void:
	_short = short
	_phone = phone
	_layout()


func _label(node_name: String) -> Label:
	var label := Label.new()
	label.name = node_name
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.max_lines_visible = 1
	label.add_theme_constant_override("line_spacing", 0)
	add_child(label)
	return label


func _layout() -> void:
	if not is_instance_valid(xp_bar): return
	var compact := _short or size.y < 80.0
	var phone := _phone or size.x < 420.0
	add_theme_stylebox_override("panel", Visuals.open_card("normal", 0) if compact else Visuals.panel("reward", 0))
	set_meta("game_visual_role", "open_card" if compact else "reward")
	var title_role := "title" if compact or phone or size.y < 120.0 else "hero"
	title_label.add_theme_font_override("font", Visuals.font(title_role))
	title_label.add_theme_font_size_override("font_size", 20 if compact else Visuals.font_size(title_role, phone))
	title_label.set_meta("game_typography", title_role)
	copy_label.add_theme_font_size_override("font_size", 12 if compact else Visuals.font_size("secondary", phone))
	xp_bar.visible = _progress_available and not compact
	var padding_x := 12.0 if compact else (16.0 if phone else 24.0)
	var padding_y := 1.0 if compact else (4.0 if size.y < 104.0 else 8.0)
	var content_width := maxf(0.0, size.x - padding_x * 2.0)
	var title_height := ceilf(title_label.get_theme_font("font").get_height(title_label.get_theme_font_size("font_size")))
	title_label.position = Vector2(padding_x, padding_y)
	title_label.size = Vector2(content_width, title_height)
	var bar_height := 4.0
	xp_bar.position = Vector2(padding_x, maxf(0.0, size.y - padding_y - bar_height))
	xp_bar.size = Vector2(content_width, bar_height)
	var copy_top := padding_y + title_height + (0.0 if compact else 2.0)
	var copy_bottom := xp_bar.position.y - 4.0 if xp_bar.visible else size.y - padding_y
	var copy_height := maxf(0.0, copy_bottom - copy_top)
	var copy_line_height := ceilf(copy_label.get_theme_font("font").get_height(copy_label.get_theme_font_size("font_size")))
	copy_label.max_lines_visible = maxi(1, floori(copy_height / maxf(1.0, copy_line_height)))
	copy_label.position = Vector2(padding_x, copy_top)
	copy_label.size = Vector2(content_width, copy_height)
