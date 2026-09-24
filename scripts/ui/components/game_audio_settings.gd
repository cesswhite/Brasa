extends Control
class_name GameAudioSettings
## Presentation only. The caller owns preference persistence and audio routing.
signal volume_changed(bus: String, value: float)
const Visuals = preload("res://scripts/ui/game_visual_system.gd")
const CONTENT_HEIGHT := 288.0
const MIX_HINT := "General controla toda la mezcla. Efectos incluye ambiente y voces."
const BUSES := [["master","General"],["music","Música"],["sfx","Efectos"]]
var sliders: Dictionary = {}
var values: Dictionary = {}
var _heading: Label
var _notice: Label

func _ready() -> void:
	theme = Visuals.theme()
	_ensure_ui()
	resized.connect(_layout)
	_layout()

func configure(settings: Dictionary) -> void:
	_ensure_ui()
	for item: Array in BUSES:
		var key := str(item[0])
		var value := clampf(float(settings.get(key,1.0)),0.0,1.0)
		sliders[key].set_value_no_signal(value)
		values[key].text = "%d%%" % roundi(value*100.0)
	_layout()

func set_notice(message: String) -> void:
	_ensure_ui()
	_notice.text = message if not message.is_empty() else MIX_HINT
	Visuals.apply_label(_notice,"secondary","danger" if not message.is_empty() else "text_muted")

func _ensure_ui() -> void:
	if is_instance_valid(_heading): return
	mouse_filter = Control.MOUSE_FILTER_PASS
	_heading = Label.new()
	_heading.text = "Volumen"
	Visuals.apply_label(_heading,"card")
	add_child(_heading)
	for item: Array in BUSES:
		var key := str(item[0])
		var label := Label.new()
		label.text = str(item[1])
		Visuals.apply_label(label,"body")
		add_child(label)
		var value_label := Label.new()
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		Visuals.apply_label(value_label,"label","text_secondary")
		add_child(value_label)
		values[key] = value_label
		var slider := HSlider.new()
		slider.name = "Volume_"+key
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.custom_minimum_size.y = 48.0
		slider.focus_mode = Control.FOCUS_ALL
		slider.tooltip_text = "Volumen de "+str(item[1])+" · Flechas para ajustar"
		slider.set_meta("volume_bus",key)
		slider.set_meta("title_label",label)
		slider.value_changed.connect(func(value: float):
			value_label.text = "%d%%" % roundi(value*100.0)
			volume_changed.emit(key,value)
		)
		add_child(slider)
		sliders[key] = slider
	_notice = Label.new()
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Visuals.apply_label(_notice,"secondary","text_muted")
	add_child(_notice)
	_notice.text = MIX_HINT

func _layout() -> void:
	if not is_instance_valid(_heading): return
	var width := maxf(1.0,size.x)
	_heading.position = Vector2.ZERO
	_heading.size = Vector2(width,28)
	for index: int in range(BUSES.size()):
		var key := str(BUSES[index][0])
		var y := 34.0+float(index)*66.0
		var label: Label = sliders[key].get_meta("title_label")
		label.position = Vector2(0,y)
		label.size = Vector2(maxf(1,width-60),20)
		values[key].position = Vector2(maxf(0,width-60),y)
		values[key].size = Vector2(60,20)
		sliders[key].position = Vector2(0,y+18)
		sliders[key].size = Vector2(width,48)
	_notice.position = Vector2(0,236)
	_notice.size = Vector2(width,52)
