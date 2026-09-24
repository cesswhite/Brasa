extends VBoxContainer
class_name GameSectionHeader
## The Story hierarchy, reusable without owning navigation or data.

const Visuals = preload("res://scripts/ui/game_visual_system.gd")

var eyebrow_label: Label
var heading_label: Label
var subtitle_label: Label
var _compact := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL


func configure(eyebrow: String, heading: String, subtitle: String = "") -> void:
	_ensure_interface()
	eyebrow_label.text = eyebrow
	eyebrow_label.visible = not eyebrow.is_empty()
	heading_label.text = heading
	subtitle_label.text = subtitle
	subtitle_label.visible = not subtitle.is_empty()
	_apply_style()


func set_compact(compact: bool) -> void:
	_compact = compact
	if is_instance_valid(heading_label): _apply_style()


func _ensure_interface() -> void:
	if is_instance_valid(heading_label): return
	theme = Visuals.theme()
	eyebrow_label = _label("Eyebrow")
	heading_label = _label("Heading")
	subtitle_label = _label("Subtitle")


func _label(node_name: String) -> Label:
	var label := Label.new()
	label.name = node_name
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
	return label


func _apply_style() -> void:
	add_theme_constant_override("separation", Visuals.space("xs"))
	Visuals.apply_label(eyebrow_label, "label", "current")
	Visuals.apply_label(heading_label, "title", "text_primary")
	Visuals.apply_label(subtitle_label, "body", "text_secondary")
	for item: Array in [[eyebrow_label, "label"], [heading_label, "title"], [subtitle_label, "body"]]:
		var label: Label = item[0]
		label.add_theme_font_size_override("font_size", Visuals.font_size(str(item[1]), _compact))
