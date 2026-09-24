extends VBoxContainer
## Progressive disclosure for help and reports; presentation only, plain text.
const Visuals = preload("res://scripts/ui/game_visual_system.gd")

func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",16)

func paragraph(value: String, muted: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Visuals.apply_label(label,"body","text_secondary" if muted else "text_primary")
	label.add_theme_constant_override("line_spacing",5)
	add_child(label)
	return label

func section(title: String, body: String, expanded: bool = false) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.button_pressed = expanded
	button.custom_minimum_size.y = 48
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Visuals.apply_button(button,"navigation")
	add_child(button)
	var content := paragraph(body)
	content.visible = expanded
	var update := func(opened: bool):
		button.text = ("− " if opened else "+ ") + title
		button.tooltip_text = ("Ocultar " if opened else "Leer ") + title.to_lower()
		content.visible = opened
	button.toggled.connect(update)
	update.call(expanded)
	return button
