extends HBoxContainer
class_name GameBadge
## Non-interactive status marker. Text carries the meaning as well as colour.

const Visuals = preload("res://scripts/ui/game_visual_system.gd")
const World = preload("res://scripts/ui/world_visuals.gd")
const TONES := {
	"neutral":"text_secondary", "current":"current", "selected":"current",
	"completed":"success", "success":"success", "available":"text_primary",
	"locked":"text_muted", "disabled":"text_disabled", "danger":"danger",
	"warning":"warning", "boss":"boss", "elite":"elite",
	"online":"online", "offline":"offline", "victory":"success",
	"defeat":"danger", "defeated":"text_muted"
}
const ICONS := {"normal": "encounter_badge", "elite": "elite_badge", "boss": "boss_badge"}

var icon: TextureRect
var label: Label
var state := "neutral"
var kind := "normal"


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL


func configure(text: String, status: String = "neutral", badge_kind: String = "normal") -> void:
	_ensure_interface()
	state = status if TONES.has(status) else "neutral"
	kind = badge_kind if ICONS.has(badge_kind) else "normal"
	label.text = text
	tooltip_text = text
	icon.texture = World.illustration(str(ICONS[kind]))
	icon.modulate = Visuals.color("text_secondary") if state == "locked" else Color.WHITE
	Visuals.apply_label(label, "secondary", str(TONES[state]))


func _ensure_interface() -> void:
	if is_instance_valid(label): return
	theme = Visuals.theme()
	add_theme_constant_override("separation", Visuals.space("xs"))
	icon = TextureRect.new()
	icon.name = "Emblem"
	icon.custom_minimum_size = Vector2(32,32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)
	label = Label.new()
	label.name = "Status"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
