extends ScrollContainer
## Read-only presentation. Formatted numbers and descriptions come from Main.
const Visuals = preload("res://scripts/ui/game_visual_system.gd")
var content: VBoxContainer
var attributes: GridContainer
var skills: GridContainer
var stat_buttons: Array[Button] = []
var growth_labels: Array[Label] = []
var growth_button: Button
var help_panel: PanelContainer
var help_label: Label
var profile_button: Button
var profile_content: VBoxContainer
var rules_button: Button
var rules_label: Label
var selected_stat := -1
var rows: Array[Dictionary] = []

func configure(definition: Dictionary, stat_rows: Array[Dictionary], rules: String) -> void:
	rows = stat_rows.duplicate(true)
	theme = Visuals.theme()
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	follow_focus = true
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",16)
	add_child(content)
	var heading := HBoxContainer.new()
	content.add_child(heading)
	var title := _label(heading,"Atributos",22,Visuals.CREAM,true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	growth_button = _button(heading,"Ver crecimiento")
	growth_button.toggle_mode = true
	growth_button.toggled.connect(func(enabled: bool):
		growth_button.text = "Ocultar crecimiento" if enabled else "Ver crecimiento"
		for label: Label in growth_labels: label.visible = enabled)
	_label(content,"Toca un atributo para ver cómo funciona.",13,Visuals.MUTED)
	attributes = GridContainer.new()
	attributes.columns = 3
	attributes.add_theme_constant_override("h_separation",8)
	attributes.add_theme_constant_override("v_separation",8)
	content.add_child(attributes)
	for i: int in range(rows.size()):
		var row := rows[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(0,76)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = "Ver detalle de " + str(row.title)
		for state: String in ["normal","hover","pressed"]:
			button.add_theme_stylebox_override(state,Visuals.open_card("normal" if state=="normal" else "selected",12))
		attributes.add_child(button)
		stat_buttons.append(button)
		var margin := MarginContainer.new()
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for edge: String in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,12)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(margin)
		var stack := VBoxContainer.new()
		stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_theme_constant_override("separation",2)
		margin.add_child(stack)
		_label(stack,str(row.title),13,Visuals.MUTED)
		_label(stack,_concise_value(str(row.value)),22,Visuals.CREAM,true)
		var growth := _label(stack,str(row.growth),12,Visuals.TEAL)
		growth.hide()
		growth_labels.append(growth)
		button.pressed.connect(_select_stat.bind(i))
		growth_button.toggled.connect(func(enabled: bool): button.custom_minimum_size.y = 98 if enabled else 76)
	help_panel = PanelContainer.new()
	help_panel.add_theme_stylebox_override("panel",Visuals.open_card("selected",12))
	content.add_child(help_panel)
	help_label = _label(help_panel,"",14,Visuals.CREAM)
	help_panel.hide()
	_label(content,"Selecciona un atributo para conocer su efecto.",12,Visuals.MUTED)
	skills = GridContainer.new()
	skills.add_theme_constant_override("h_separation",12)
	skills.add_theme_constant_override("v_separation",12)
	content.add_child(skills)
	for pair: Array in [["HABILIDAD",definition.ability],["GOLPE FIRMA",definition.signature]]:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel",Visuals.open_card("normal",12))
		skills.add_child(panel)
		var stack := VBoxContainer.new()
		stack.add_theme_constant_override("separation",6)
		panel.add_child(stack)
		_label(stack,str(pair[0]),12,Visuals.GOLD)
		_label(stack,str(pair[1].name),20,Visuals.CREAM,true)
		_label(stack,str(pair[1].description),14,Visuals.MUTED)
	profile_button = _button(content,"Perfil y estilo  +")
	profile_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	profile_button.toggle_mode = true
	profile_content = VBoxContainer.new()
	profile_content.add_theme_constant_override("separation",12)
	content.add_child(profile_content)
	_label(profile_content,str(definition.personality),14,Visuals.MUTED)
	_label(profile_content,"Destaca en · " + str(definition.strengths),14,Visuals.TEAL)
	_label(profile_content,"Cuida · " + str(definition.weaknesses),14,Visuals.CORAL)
	profile_content.hide()
	profile_button.toggled.connect(func(enabled: bool):
		profile_content.visible = enabled
		profile_button.text = "Perfil y estilo  −" if enabled else "Perfil y estilo  +")
	rules_button = _button(content,"Cómo progresa  +")
	rules_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	rules_button.toggle_mode = true
	rules_label = _label(content,rules,14,Visuals.MUTED)
	rules_label.hide()
	rules_button.toggled.connect(func(enabled: bool):
		rules_label.visible = enabled
		rules_button.text = "Cómo progresa  −" if enabled else "Cómo progresa  +")
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	if not is_instance_valid(attributes): return
	attributes.columns = 2 if size.x < 450 else 3
	skills.columns = 2 if size.x >= 600 else 1

func _select_stat(index: int) -> void:
	selected_stat = -1 if selected_stat == index else index
	help_panel.visible = selected_stat >= 0
	for i: int in range(stat_buttons.size()):
		stat_buttons[i].add_theme_stylebox_override("normal",Visuals.open_card("selected" if i==selected_stat else "normal",12))
	if selected_stat < 0: return
	var row := rows[index]
	help_label.text = "%s · %s\n%s\nRango: %s" % [row.title,row.value,row.description,row.range]
	_reveal_help.call_deferred()

func _reveal_help() -> void:
	await get_tree().process_frame
	if is_instance_valid(help_panel) and help_panel.visible: ensure_control_visible(help_panel)

func _label(parent: Node, text: String, font_size: int, color: Color, display: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font",Visuals.font("display" if display else "body"))
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Node, text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 44
	button.add_theme_font_size_override("font_size",13)
	parent.add_child(button)
	return button

func _concise_value(value: String) -> String:
	var suffix := "%" if value.ends_with("%") else ("×" if value.ends_with("×") else "")
	var number := value.trim_suffix(suffix) if not suffix.is_empty() else value
	if "." in number: number = number.rstrip("0").trim_suffix(".")
	return number + suffix
