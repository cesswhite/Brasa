extends Control
class_name RosterPanel
## Data-driven roster modal. It emits a selection; persistence belongs to its caller.

signal character_chosen(character_id: String, custom_name: String)
signal closed
signal customize_requested(character_id: String)

const Catalog = preload("res://scripts/character_catalog.gd")
const BalanceConfig = preload("res://scripts/balance.gd")
const Fighter = preload("res://scripts/fighter_view.gd")
const Visuals = preload("res://scripts/ui/game_visual_system.gd")
const FighterPreview = preload("res://scripts/ui/components/game_fighter_preview.gd")
const OverlayFocus = preload("res://scripts/ui/components/game_overlay_focus.gd")
const CREAM = Visuals.CREAM
const MUTED = Visuals.MUTED
const GOLD = Visuals.GOLD
const TEAL = Visuals.TEAL
const CORAL = Visuals.CORAL

var _definitions: Array = []
var _profiles: Dictionary = {}
var _active_id: String = ""
var _first_time: bool = false
var _selected_index: int = 0
var _cards: Array[Button] = []
var _portraits: Array[Node2D] = []
var _detail: VBoxContainer
var _detail_scroll: ScrollContainer
var _grid: GridContainer
var _name_input: LineEdit
var _choose_button: Button
var _close_button: Button
var _title: Label
var _subtitle: Label
var _built: bool = false
var _name_drafts: Dictionary = {}
var _outer_margin: MarginContainer
var _shell: PanelContainer
var _content: VBoxContainer
var _header: HBoxContainer
var _body: HBoxContainer
var _roster_column: VBoxContainer
var _roster_scroll: ScrollContainer
var _detail_panel: PanelContainer
var _footer: BoxContainer
var _name_column: VBoxContainer
var _name_caption: Label
var _note: Label
var _brand: Label
var _keyboard_hint: Label
var _tabs: HBoxContainer
var _roster_tab: Button
var _detail_tab: Button
var _compact: bool = false
var _short: bool = false
var _portrait: bool = false
var _mobile_page: int = 0
var _layout_shape: String = ""
var _customization_enabled := false
var _customize_button: Button
var _card_fit_pending := false
var _show_growth := false
var _show_about := false
var _backdrop: Control

func enable_customization(enabled: bool) -> void:
	_customization_enabled = enabled
	_customize_button.visible = enabled
	_name_input.visible = not enabled
	_name_caption.text = "" if enabled else "NOMBRE DE TU COMPAÑERO"
	_name_caption.visible = not enabled


func configure(definitions: Array, profiles: Dictionary, active_id: String, first_time: bool = false) -> void:
	_definitions = definitions.duplicate(true)
	_profiles = profiles.duplicate(true)
	_active_id = active_id
	_first_time = first_time
	_selected_index = 0
	_name_drafts.clear()
	for index in range(_definitions.size()):
		if str(_definitions[index].get("id", "")) == active_id:
			_selected_index = index
	_ensure_interface()
	Visuals.reveal(self)
	_title.text = "Elige a tu primer compañero" if first_time else "Tus compañeros de la liga"
	_subtitle.text = "%d estilos de combate · todos disponibles · progreso individual" % _definitions.size()
	_close_button.visible = not first_time
	_rebuild_cards()
	_layout_responsive()
	if not _definitions.is_empty():
		_select(_selected_index, false)
		if is_inside_tree():
			_cards[_selected_index].call_deferred("grab_focus")
	else:
		_choose_button.disabled = true


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_interface()
	if not resized.is_connected(_layout_responsive):
		resized.connect(_layout_responsive)
	_layout_responsive()


func _ensure_interface() -> void:
	if _built:
		return
	_built = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Visuals.theme()
	_backdrop = Visuals.mount_background(self,"companions")
	Visuals.reading_veil(self)
	_outer_margin = MarginContainer.new()
	_outer_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left", "top", "right", "bottom"]:
		_outer_margin.add_theme_constant_override("margin_" + edge, 32)
	add_child(_outer_margin)
	_shell = PanelContainer.new()
	_shell.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_outer_margin.add_child(_shell)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 16)
	_shell.add_child(_content)
	_header = HBoxContainer.new()
	_header.add_theme_constant_override("separation", 16)
	_content.add_child(_header)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation", 3)
	_header.add_child(heading)
	_brand = _label(heading, "BRASA  /  COMPAÑEROS", 12, GOLD)
	_title = _label(heading, "Tus compañeros de la liga", 29)
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title.clip_text = true
	_subtitle = _label(heading, "", 13, MUTED)
	_subtitle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_subtitle.clip_text = true
	_close_button = _button("×", false)
	Visuals.apply_button(_close_button,"icon")
	_close_button.custom_minimum_size = Vector2(48,48)
	_close_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_close_button.pressed.connect(_request_close)
	_close_button.tooltip_text = "Cerrar selección"
	_header.add_child(_close_button)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 8)
	_content.add_child(_tabs)
	_roster_tab = _button("Compañeros", false)
	_roster_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_roster_tab.pressed.connect(_set_mobile_page.bind(0))
	_tabs.add_child(_roster_tab)
	_detail_tab = _button("Ficha", false)
	_detail_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_tab.pressed.connect(_set_mobile_page.bind(1))
	_tabs.add_child(_detail_tab)
	_body = HBoxContainer.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 32)
	_content.add_child(_body)
	_roster_column = VBoxContainer.new()
	_roster_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_roster_column.size_flags_stretch_ratio = 1.6
	_roster_column.add_theme_constant_override("separation", 10)
	_body.add_child(_roster_column)
	_roster_scroll = ScrollContainer.new()
	_roster_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_roster_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_roster_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_roster_scroll.follow_focus = true
	_roster_scroll.scroll_deadzone = 12
	_roster_column.add_child(_roster_scroll)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_roster_scroll.add_child(_grid)
	_keyboard_hint = _label(_roster_column, "Selecciona una tarjeta · flechas para explorar · Tab para avanzar", 12, MUTED)
	_keyboard_hint.clip_text = true
	_keyboard_hint.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_detail_panel = PanelContainer.new()
	_detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_panel.size_flags_stretch_ratio = 1.0
	_detail_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_body.add_child(_detail_panel)
	_detail_scroll = ScrollContainer.new()
	_detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_scroll.scroll_deadzone = 12
	_detail_scroll.follow_focus = true
	_detail_panel.add_child(_detail_scroll)
	_detail = VBoxContainer.new()
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override("separation", 11)
	_detail_scroll.add_child(_detail)
	var separator := HSeparator.new()
	separator.modulate = Color(Visuals.color("bronze"),0.45)
	_content.add_child(separator)
	_footer = BoxContainer.new()
	_footer.add_theme_constant_override("separation", 18)
	_content.add_child(_footer)
	_name_column = VBoxContainer.new()
	_name_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_column.add_theme_constant_override("separation", 5)
	_footer.add_child(_name_column)
	_name_caption = _label(_name_column, "NOMBRE DE TU COMPAÑERO", 12, MUTED)
	_name_input = LineEdit.new()
	_name_input.name = "CompanionName"
	_name_input.max_length = 24
	_name_input.custom_minimum_size = Vector2(0, 48)
	_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_input.placeholder_text = "Ponle un nombre"
	_name_input.text_submitted.connect(func(_text: String): _emit_choice())
	_name_column.add_child(_name_input)
	_customize_button = _button("Personalizar", false)
	_customize_button.custom_minimum_size = Vector2(0, 48)
	_customize_button.clip_text = true
	_customize_button.pressed.connect(func(): customize_requested.emit(str(_definitions[_selected_index].id)))
	_name_column.add_child(_customize_button)
	_customize_button.hide()
	_note = _label(_footer, "Cada compañero conserva su nivel, experiencia\ny mejoras al cambiar de personaje.", 14, MUTED)
	_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_choose_button = _button("Usar compañero", true)
	_choose_button.name = "ChooseCharacter"
	_choose_button.custom_minimum_size = Vector2(232, 50)
	_choose_button.size_flags_vertical = Control.SIZE_SHRINK_END
	_choose_button.pressed.connect(_emit_choice)
	_footer.add_child(_choose_button)


func _layout_responsive() -> void:
	if not _built or size.x <= 0.0 or size.y <= 0.0:
		return
	_compact = size.x < 1080.0 or size.y < 650.0
	_short = size.y < 520.0
	_portrait = size.x < 600.0
	var gutter: int = 16 if _short or _portrait else 32
	for edge: String in ["left", "top", "right", "bottom"]:
		_outer_margin.add_theme_constant_override("margin_" + edge, gutter)
	_content.add_theme_constant_override("separation", 8 if _short else 12)
	_header.add_theme_constant_override("separation", 8 if _compact else 16)
	_brand.hide()
	_subtitle.hide()
	_title.add_theme_font_size_override("font_size", Visuals.font_size("title",_short or _portrait))
	_title.text = "Elige tu compañero" if _first_time else "Tus compañeros"
	_subtitle.text = ("%d estilos · todos disponibles" if _compact else "%d estilos de combate · todos disponibles · progreso individual") % _definitions.size()
	_close_button.text = "×"
	_close_button.custom_minimum_size = Vector2(48,48)
	_tabs.visible = _compact
	for tab: Button in [_roster_tab, _detail_tab]:
		tab.custom_minimum_size.y = 44 if _short else 48
	_roster_tab.text = "Compañeros (%d)" % _definitions.size()
	_keyboard_hint.hide()
	_roster_column.custom_minimum_size.x = 0 if _compact else 550
	_detail_panel.custom_minimum_size.x = 0 if _compact else 360
	_roster_column.size_flags_stretch_ratio = 1.6 if not _compact else 1.0
	_grid.columns = 2 if _portrait else 3
	_footer.vertical = _portrait
	_footer.add_theme_constant_override("separation", 8 if _compact else 18)
	_name_column.custom_minimum_size.x = 0 if _compact else 200
	_name_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_customize_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_customize_button.custom_minimum_size.x = 180
	_name_caption.visible = not _short and not _customization_enabled
	_name_input.custom_minimum_size.y = 44 if _short else 48
	_customize_button.custom_minimum_size.y = 44 if _short else 48
	_note.hide()
	_choose_button.custom_minimum_size = Vector2(0 if _portrait else 232, 44 if _short else 50)
	_choose_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL if _portrait else Control.SIZE_FILL
	_choose_button.size_flags_vertical = Control.SIZE_FILL if _portrait else Control.SIZE_SHRINK_END
	for card: Button in _cards:
		card.custom_minimum_size = Vector2(120,248 if _portrait else (252 if _short else 284))
		var portrait: Control = card.get_meta("portrait")
		portrait.custom_minimum_size.y = 158 if _portrait else 200
		portrait.fit()
	_schedule_card_fit()
	_set_mobile_page(_mobile_page)
	var shape: String = "%s_%s_%s" % [_compact, _short, _portrait]
	if shape != _layout_shape and not _definitions.is_empty() and _detail != null:
		_layout_shape = shape
		_rebuild_detail(_definitions[_selected_index], _preview_profile(_definitions[_selected_index]))


func _set_mobile_page(page: int) -> void:
	_mobile_page = clampi(page, 0, 1)
	_roster_column.visible = not _compact or _mobile_page == 0
	_detail_panel.visible = not _compact or _mobile_page == 1
	if not _definitions.is_empty():
		_detail_tab.text = "Ficha · " + str(_definitions[_selected_index].get("name", ""))
	for index in range(2):
		var tab: Button = _roster_tab if index == 0 else _detail_tab
		Visuals.apply_button(tab,"navigation_active" if index == _mobile_page else "navigation")
		tab.add_theme_font_size_override("font_size",Visuals.font_size("button",_compact))


func _label(parent: Node, value: String, font_size: int = 15, color: Color = CREAM, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	var role := "title" if font_size >= 26 else ("card" if font_size >= 18 else ("label" if font_size <= 12 else ("secondary" if font_size <= 14 else "body")))
	Visuals.apply_label(label,role)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label


func _button(value: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = value
	button.clip_text = true
	Visuals.apply_button(button,"primary" if primary else "secondary")
	return button


func _clear_children(parent: Node) -> void:
	for child: Node in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _rebuild_cards() -> void:
	_clear_children(_grid)
	_cards.clear()
	_portraits.clear()
	for index in range(_definitions.size()):
		var definition: Dictionary = _definitions[index]
		var id: String = str(definition["id"])
		var profile: Dictionary = _preview_profile(definition)
		var card := Button.new()
		card.name = "Character_" + id
		card.custom_minimum_size = Vector2(174, 175)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.clip_contents = true
		card.tooltip_text = "%s · %s\n%s" % [definition.get("name", ""), definition.get("role", ""), definition.get("personality", "")]
		_grid.add_child(card)
		_cards.append(card)
		var inner := MarginContainer.new()
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for edge: String in ["left", "right", "top", "bottom"]:
			inner.add_theme_constant_override("margin_" + edge, 10)
		card.add_child(inner)
		var layout := VBoxContainer.new()
		layout.add_theme_constant_override("separation", 2)
		layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(layout)
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layout.add_child(row)
		var level := _label(row, "NV. %d" % int(profile.get("level", 1)), 12, MUTED)
		level.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_label(row, "EN USO" if id == _active_id else "", 12, TEAL)
		var portrait := FighterPreview.new()
		portrait.custom_minimum_size.y = 180
		portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
		layout.add_child(portrait)
		portrait.configure(profile,definition)
		portrait.resized.connect(_schedule_card_fit)
		var actor: Node2D = portrait.actor()
		card.set_meta("portrait", portrait)
		card.set_meta("actor", actor)
		_portraits.append(actor)
		var name_label := _label(layout, str(definition.get("name", "")), 20)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.clip_text = true
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		var role_label := _label(layout, str(definition.get("role", "")).get_slice(" · ",0), 13, MUTED)
		role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		role_label.clip_text = true
		role_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		var xp := ProgressBar.new()
		xp.custom_minimum_size.y = 4
		xp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Visuals.apply_progress(xp,"xp")
		xp.max_value = maxi(1,BalanceConfig.xp_needed(int(profile.get("level",1))))
		xp.value = xp.max_value if int(profile.get("level",1)) >= BalanceConfig.MAX_LEVEL else int(profile.get("xp",0))
		layout.add_child(xp)
		card.tooltip_text += "\nNivel máximo" if int(profile.get("level",1)) >= BalanceConfig.MAX_LEVEL else "\nNivel %d · %d / %d XP" % [int(profile.get("level",1)),int(profile.get("xp",0)),int(xp.max_value)]
		card.pressed.connect(_card_pressed.bind(index))
		card.gui_input.connect(_card_input.bind(index))
	_update_card_styles()


func _schedule_card_fit() -> void:
	if _card_fit_pending: return
	_card_fit_pending = true
	_fit_card_previews.call_deferred()

func _fit_card_previews() -> void:
	_card_fit_pending = false
	if not is_inside_tree() or _cards.is_empty(): return
	var common: float = INF
	for card: Button in _cards:
		var preview = card.get_meta("portrait")
		preview.max_scale = INF
		preview.fit()
		common = minf(common,preview.actor().scale.x)
	for card: Button in _cards:
		var preview = card.get_meta("portrait")
		preview.max_scale = common
		preview.fit()


func _preview_profile(definition: Dictionary) -> Dictionary:
	var id: String = str(definition.get("id", ""))
	if _profiles.has(id) and _profiles[id] is Dictionary:
		return _profiles[id].duplicate(true)
	return {"character_id": id, "name": definition.get("name", ""), "archetype": definition.get("archetype", 0), "level": 1, "xp": 0, "stats": definition.get("training_base", {}).duplicate(true)}


func _select(index: int, remember_name: bool = true) -> void:
	if index < 0 or index >= _definitions.size():
		return
	if remember_name and not _definitions.is_empty() and _name_input != null:
		_name_drafts[str(_definitions[_selected_index]["id"])] = _name_input.text
	_selected_index = index
	var definition: Dictionary = _definitions[index]
	var id: String = str(definition["id"])
	var profile: Dictionary = _preview_profile(definition)
	_name_input.text = str(_name_drafts.get(id, profile.get("name", definition.get("name", ""))))
	_choose_button.text = "Comenzar con " + str(definition.get("name", "")) if _first_time else ("Volver con " if id == _active_id else "Usar a ") + str(definition.get("name", ""))
	_choose_button.disabled = false
	_update_card_styles()
	_rebuild_detail(definition, profile)
	_detail_scroll.scroll_vertical = 0
	_backdrop.set_context("camp",{"character_id":id,"appearance":definition.get("appearance",profile.get("appearance",{})),"arena_wins":int(profile.get("wins",0))})
	_set_mobile_page(_mobile_page)


func _card_pressed(index: int) -> void:
	_select(index)
	if _compact:
		_set_mobile_page(1)


func _update_card_styles() -> void:
	for index in range(_cards.size()):
		var selected: bool = index == _selected_index
		var card: Button = _cards[index]
		Visuals.apply_card_button(card,selected)


func _rebuild_detail(definition: Dictionary, profile: Dictionary) -> void:
	_clear_children(_detail)
	var preview := FighterPreview.new()
	preview.name = "SelectedCompanion"
	preview.custom_minimum_size = Vector2(0,200 if _short else (340 if _portrait else 430))
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_child(preview)
	preview.configure(profile,definition)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	_detail.add_child(title_row)
	var title := _label(title_row, str(definition.get("name", "")), 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.tooltip_text = title.text
	var level := _label(title_row, "NIVEL %d" % int(profile.get("level", 1)), 12, TEAL)
	level.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_label(_detail, str(definition.get("role", "")), 14, GOLD, true)
	var experience := VBoxContainer.new()
	experience.add_theme_constant_override("separation", 5)
	_detail.add_child(experience)
	var needed: int = BalanceConfig.xp_needed(int(profile.get("level", 1)))
	var at_cap: bool = int(profile.get("level", 1)) >= BalanceConfig.MAX_LEVEL
	_label(experience, "Nivel máximo" if at_cap else "%d / %d XP" % [int(profile.get("xp", 0)), needed], 12, MUTED, true)
	var xp_bar := ProgressBar.new()
	xp_bar.custom_minimum_size.y = 7
	xp_bar.show_percentage = false
	xp_bar.max_value = maxi(1, needed)
	xp_bar.value = xp_bar.max_value if at_cap else int(profile.get("xp", 0))
	Visuals.apply_progress(xp_bar,"xp")
	experience.add_child(xp_bar)
	var points: int = int(profile.get("points",0))
	if points > 0: _label(experience,"%d puntos para entrenar" % points,12,TEAL)
	var stat_heading := HBoxContainer.new()
	_detail.add_child(stat_heading)
	var stat_title := _label(stat_heading, "ATRIBUTOS", 12, MUTED)
	stat_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var growth_button := _button("Ocultar crecimiento" if _show_growth else "Ver crecimiento",false)
	growth_button.name = "RosterGrowth"
	Visuals.apply_button(growth_button,"navigation")
	growth_button.custom_minimum_size = Vector2(172,44)
	growth_button.pressed.connect(_toggle_growth)
	stat_heading.add_child(growth_button)
	var stats: Dictionary = Catalog.stats_for(profile)
	var next_profile: Dictionary = profile.duplicate(true)
	next_profile["level"] = mini(BalanceConfig.MAX_LEVEL, int(profile.get("level", 1)) + 1)
	var next_stats: Dictionary = Catalog.stats_for(next_profile)
	var stat_grid := GridContainer.new()
	stat_grid.columns = 3
	stat_grid.name = "Attributes"
	stat_grid.add_theme_constant_override("h_separation", 12)
	stat_grid.add_theme_constant_override("v_separation", 10)
	_detail.add_child(stat_grid)
	for key: String in Catalog.STAT_HELP:
		if not stats.has(key):
			continue
		var help: Dictionary = Catalog.STAT_HELP[key]
		var stat_panel := PanelContainer.new()
		stat_panel.custom_minimum_size.y = 80 if _show_growth else 60
		stat_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat_panel.add_theme_stylebox_override("panel", Visuals.open_card("normal",8))
		stat_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		var gain: float = float(next_stats.get(key, stats[key])) - float(stats[key])
		stat_panel.tooltip_text = "%s\nRango: %s.\nPróximo nivel: %s → %s.\nEl crecimiento depende del personaje y se suaviza en niveles altos." % [help.get("description", ""), _as_text(help.get("range", "")), _format_stat(float(stats[key]), help), _format_stat(float(next_stats.get(key, stats[key])), help)]
		stat_grid.add_child(stat_panel)
		var stat_column := VBoxContainer.new()
		stat_column.add_theme_constant_override("separation", 1)
		stat_panel.add_child(stat_column)
		_label(stat_column, str(help.get("name", help.get("nombre", key))), 12, MUTED)
		_label(stat_column, _format_stat(float(stats[key]), help), 19, CREAM)
		if _show_growth: _label(stat_column, _format_gain(gain, help) if not at_cap else "Máximo", 12, TEAL)
	var more := _button("Ocultar habilidades y perfil" if _show_about else "Habilidades y perfil",false)
	more.name = "RosterAbout"
	more.custom_minimum_size.y = 44
	Visuals.apply_button(more,"navigation")
	more.pressed.connect(_toggle_about)
	_detail.add_child(more)
	if not _show_about: return
	if not str(definition.get("species", "")).is_empty(): _label(_detail,str(definition.species),12,MUTED,true)
	_label(_detail, "Destaca · " + _as_text(definition.get("strengths", "")), 14, TEAL, true)
	_label(_detail, "Punto débil · " + _as_text(definition.get("weaknesses", "")), 14, CORAL, true)
	var ability: Dictionary = definition.get("ability", {})
	_ability_box("HABILIDAD · " + str(ability.get("name", "")), str(ability.get("description", "")), TEAL)
	var signature: Dictionary = definition.get("signature", {})
	var signature_description: String = str(signature.get("description", ""))
	if signature_description.is_empty():
		signature_description = "Impacto certero. Aplica %s durante %d turnos." % [signature.get("effect", ""), int(signature.get("duration", 0))]
	_ability_box("GOLPE FIRMA · " + str(signature.get("name", "")), signature_description + "\n%.0f%% por partida · una vez como máximo." % (float(BalanceConfig.SIGNATURE["chance"]) * 100.0), GOLD)

	var biography: String = str(definition.get("biography",definition.get("personality",""))).strip_edges()
	if not biography.is_empty(): _label(_detail,biography,14,MUTED,true)

func _toggle_growth() -> void:
	_show_growth = not _show_growth
	_refresh_detail_focus("RosterGrowth")

func _toggle_about() -> void:
	_show_about = not _show_about
	_refresh_detail_focus("RosterAbout")

func _refresh_detail_focus(button_name: String) -> void:
	var scroll: int = _detail_scroll.scroll_vertical
	_rebuild_detail(_definitions[_selected_index],_preview_profile(_definitions[_selected_index]))
	_detail_scroll.set_deferred("scroll_vertical",scroll)
	_restore_detail_focus.call_deferred(button_name)

func _restore_detail_focus(button_name: String) -> void:
	var button := _detail.find_child(button_name,true,false) as Button
	if is_instance_valid(button) and button.is_visible_in_tree(): button.grab_focus()


func _ability_box(title: String, description: String, accent: Color) -> void:
	var panel := PanelContainer.new()
	panel.name = "Signature" if title.begins_with("GOLPE FIRMA") else "Ability"
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_detail.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	panel.add_child(content)
	_label(content, title, 12, accent, true)
	_label(content, description, 14, CREAM, true)


func _format_stat(value: float, help: Dictionary) -> String:
	var format: String = str(help.get("format", "number"))
	if format in ["percent", "percentage", "%"]:
		return "%.1f%%" % (value * 100.0)
	if format in ["multiplier", "x"]:
		return "×%.2f" % value
	if absf(value - roundf(value)) < 0.001:
		return str(int(roundf(value)))
	return "%.1f" % value


func _format_gain(value: float, help: Dictionary) -> String:
	var format: String = str(help.get("format", "number"))
	if format in ["percent", "percentage", "%"]:
		return "↗ +%.2f pp" % (value * 100.0)
	if format in ["multiplier", "x"]:
		return "↗ +%.3f×" % value
	if absf(value - roundf(value)) < 0.001:
		return "↗ +%d" % int(roundf(value))
	return "↗ +%.2f" % value


func _as_text(value: Variant) -> String:
	if value is Array:
		var texts := PackedStringArray()
		for item: Variant in value:
			texts.append(str(item))
		return " · ".join(texts)
	return str(value)


func _card_input(event: InputEvent, index: int) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var target: int = index
	match event.keycode:
		KEY_LEFT: target = maxi(0, index - 1)
		KEY_RIGHT: target = mini(_cards.size() - 1, index + 1)
		KEY_UP: target = maxi(0, index - _grid.columns)
		KEY_DOWN: target = mini(_cards.size() - 1, index + _grid.columns)
		_: return
	_select(target)
	_cards[target].grab_focus()
	accept_event()


func _input(event: InputEvent) -> void:
	OverlayFocus.handle(event,self,_request_close)


func _request_close() -> void:
	if not _first_time:
		closed.emit()


func _emit_choice() -> void:
	if _definitions.is_empty() or _choose_button.disabled:
		return
	var definition: Dictionary = _definitions[_selected_index]
	var custom_name: String = _name_input.text.strip_edges()
	if custom_name.is_empty():
		custom_name = str(definition.get("name", ""))
	character_chosen.emit(str(definition["id"]), custom_name)
