extends Control
class_name CustomizationPanel
## Local draft only. The owner persists confirmed values; cancel never writes.
signal confirmed(archetype_id: String, fighter_name: String, appearance: Dictionary)
signal cancelled

const Cosmetics = preload("res://scripts/cosmetic_catalog.gd")
const Characters = preload("res://scripts/character_catalog.gd")
const Fighter = preload("res://scripts/fighter_view.gd")
const Moves = preload("res://scripts/move_catalog.gd")
const Visuals = preload("res://scripts/ui/game_visual_system.gd")
const OverlayFocus = preload("res://scripts/ui/components/game_overlay_focus.gd")
const CREAM = Visuals.CREAM
const MUTED = Visuals.MUTED
const GOLD = Visuals.GOLD
const TEAL = Visuals.TEAL
const DARK = Visuals.DARK
const SURFACE = Visuals.SURFACE
const ParticleEffects = preload("res://scripts/cosmetic_particles.gd")
const TAB_NAMES: Array[String] = ["Cuerpo", "Color", "Efectos", "Estilo"]

class EffectSwatch extends Control:
	var effect: Dictionary = {}
	var trail: bool = false
	func _draw() -> void:
		# Actual particle renderer, frozen at a readable moment in this card.
		draw_set_transform(Vector2.ZERO)
		var particles: Array[Dictionary] = ParticleEffects.samples(effect, 0.8, Vector2.ZERO, Vector2(0,80), 1.0, trail)
		for particle: Dictionary in particles:
			particle.at = Vector2(size.x*0.5, 8) + (Vector2(particle.at) + Vector2(30 if trail else 0, 26)) * 0.42
			particle.size = float(particle.size) * 0.75
		ParticleEffects.paint(self, particles)

class PreviewStage extends Control:
	var floor_y: float = -1.0

var _store: RefCounted
var _archetype_id: String = "nima"
var _creating: bool = false
var _draft: Dictionary = {}
var _owned: Array[String] = []
var _selected_tab: int = 0
var _color_section: int = 0
var _effect_section: int = 0
var _effect_demo_elapsed: float = 0.0
var _style_section: int = 0
var _style_auto: bool = true
var _style_demo_elapsed: float = 0.0
var _style_controls: HBoxContainer
var _style_auto_button: Button
# A locked item can be tried on the actor, but never enters the saved draft.
var _try_slot: String = ""
var _try_id: String = ""
var _built: bool = false
var _short: bool = false
var _portrait: bool = false
var _title: Label
var _subtitle: Label
var _close: Button
var _preview_panel: Panel
var _name_caption: Label
var _name_input: LineEdit
var _archetype: OptionButton
var _role: Label
var _stage: PreviewStage
var _actor: Node2D
var _preview_framing: String = "rest"
var _preview_actions: HBoxContainer
var _options: Control
var _tabs: HBoxContainer
var _tab_buttons: Array[Button] = []
var _toolbar: HBoxContainer
var _presets: OptionButton
var _random: Button
var _scroll: ScrollContainer
var _items: VBoxContainer
var _help: Label
var _error: Label
var _try_back: Button
var _cancel: Button
var _confirm: Button
var _item_buttons: Array[Button] = []

func configure(identity_store: RefCounted, archetype_id: String, creating: bool = false) -> void:
	_store = identity_store
	_archetype_id = archetype_id if archetype_id in Characters.IDS else "nima"
	_creating = creating
	_owned.assign(_store.owned_ids())
	var entry: Dictionary = _store.entry(_archetype_id)
	_draft = Cosmetics.normalize_appearance(entry.get("appearance", {}), _archetype_id).duplicate(true)
	_build()
	_name_input.text = str(entry.get("identity", {}).get("display_name", Characters.definition(_archetype_id).name))
	_archetype.select(Characters.IDS.find(_archetype_id))
	_selected_tab = 0
	_color_section = 0
	_effect_section = 0
	_style_section = 0
	_style_auto = true
	_try_slot = ""
	_try_id = ""
	set_error("")
	_refresh_preview()
	_rebuild_options()
	_layout()
	Visuals.reveal(self)
	_close.grab_focus.call_deferred()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	resized.connect(_layout)
	_layout()

func _build() -> void:
	if _built: return
	_built = true
	theme = Visuals.theme()
	Visuals.mount_background(self,"creation",{"character_id":_archetype_id,"appearance":_draft,"owned_cosmetics":_owned})
	Visuals.reading_veil(self)
	_title = _label(self, "Tu compañero", 28, CREAM)
	_subtitle = _label(self, "Una identidad propia para todas tus aventuras", 14, MUTED)
	_close = _button("×")
	Visuals.apply_button(_close,"icon")
	_close.tooltip_text = "Cancelar y descartar cambios"
	_close.pressed.connect(_cancel_draft)
	add_child(_close)
	_preview_panel = Panel.new()
	_preview_panel.name = "PreviewPanel"
	_preview_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(_preview_panel)
	_name_caption = _label(_preview_panel, "NOMBRE DE TU COMPAÑERO", 11, MUTED)
	_name_input = LineEdit.new()
	_name_input.name = "FighterName"
	_name_input.max_length = int(Cosmetics.NAME_POLICY.maximum_length)
	_name_input.placeholder_text = "Elige un nombre"
	_name_input.tooltip_text = "Nombre de tu compañero · de 2 a 24 caracteres"
	_name_input.add_theme_font_size_override("font_size", 19)
	_name_input.text_changed.connect(func(_value: String): set_error(""))
	_name_input.text_submitted.connect(func(_value: String): _confirm_draft())
	_preview_panel.add_child(_name_input)
	_archetype = OptionButton.new()
	_archetype.name = "CombatArchetype"
	_style_option(_archetype)
	for id: String in Characters.IDS:
		var definition: Dictionary = Characters.definition(id)
		_archetype.add_item("Base: %s · %s" % [definition.name, definition.role])
	_archetype.item_selected.connect(_choose_archetype)
	_preview_panel.add_child(_archetype)
	_role = _label(_preview_panel, "", 12, MUTED)
	_stage = PreviewStage.new()
	_stage.name = "FighterPreview"
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.clip_contents = true
	_preview_panel.add_child(_stage)
	_actor = Fighter.new()
	_actor.name = "PreviewFighter"
	_actor.cosmetic_preview = true
	_stage.add_child(_actor)
	_preview_actions = HBoxContainer.new()
	_preview_actions.add_theme_constant_override("separation", 6)
	_preview_panel.add_child(_preview_actions)
	for choice: String in ["Golpe", "Entrada", "Victoria"]:
		var button := _button(choice)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_preview_action.bind(choice))
		_preview_actions.add_child(button)
	_style_controls = HBoxContainer.new()
	_style_controls.add_theme_constant_override("separation", 8)
	_preview_panel.add_child(_style_controls)
	var repeat_button := _button("Repetir")
	repeat_button.name = "RepeatStyle"
	repeat_button.tooltip_text = "Volver a ver el estilo seleccionado sin cambiar tu apariencia"
	repeat_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	repeat_button.pressed.connect(_replay_style)
	_style_controls.add_child(repeat_button)
	_style_auto_button = _button("Auto: Sí")
	_style_auto_button.name = "AutoStyle"
	_style_auto_button.toggle_mode = true
	_style_auto_button.button_pressed = true
	_style_auto_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_auto_button.tooltip_text = "Repetir la demostración cada cuatro segundos. Pulsa para activar o desactivar."
	_style_auto_button.pressed.connect(_toggle_style_auto)
	_style_controls.add_child(_style_auto_button)
	_options = Control.new()
	_options.name = "AppearanceOptions"
	add_child(_options)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 4)
	_options.add_child(_tabs)
	for index in range(TAB_NAMES.size()):
		var button := _button(TAB_NAMES[index])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(select_tab.bind(index))
		_tabs.add_child(button)
		_tab_buttons.append(button)
	_toolbar = HBoxContainer.new()
	_toolbar.add_theme_constant_override("separation", 8)
	_options.add_child(_toolbar)
	_presets = OptionButton.new()
	_presets.name = "AppearancePreset"
	_presets.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_option(_presets)
	_presets.add_item("Color, efectos y gestos")
	_presets.set_item_disabled(0, true)
	_presets.tooltip_text = "Aplica juntos color, efectos, entrada y victoria. Conserva el cuerpo y el nombre."
	for preset: Dictionary in Cosmetics.presets(): _presets.add_item(str(preset.name))
	_presets.item_selected.connect(_choose_preset)
	_toolbar.add_child(_presets)
	_random = _button("Al azar")
	_random.custom_minimum_size.x = 96
	_random.tooltip_text = "Prueba un cuerpo, colores y efectos de tu colección. Guarda sólo si te gusta."
	_random.pressed.connect(randomize_owned)
	_toolbar.add_child(_random)
	_scroll = ScrollContainer.new()
	_scroll.name = "CosmeticChoices"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	_scroll.scroll_deadzone = 12
	_options.add_child(_scroll)
	_items = VBoxContainer.new()
	_items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items.add_theme_constant_override("separation", 12)
	_scroll.add_child(_items)
	_help = _label(_options, "", 12, MUTED)
	_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_help.clip_text = false
	_help.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_error = _label(self, "", Visuals.font_size("secondary"), Visuals.CORAL)
	_error.name = "CustomizationError"
	_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_try_back = _button("Volver")
	_try_back.tooltip_text = "Volver a la apariencia seleccionada"
	_try_back.pressed.connect(func():
		_end_try_on()
		_rebuild_options(true)
		_confirm.grab_focus())
	add_child(_try_back)
	_cancel = _button("Cancelar")
	_cancel.pressed.connect(_cancel_draft)
	add_child(_cancel)
	_confirm = _button("Guardar apariencia", true)
	_confirm.name = "ConfirmAppearance"
	_confirm.pressed.connect(_confirm_draft)
	add_child(_confirm)

func _layout() -> void:
	if not _built or size.x < 1 or size.y < 1: return
	_short = size.y < 520
	_portrait = size.x < 860 and not _short
	var margin: float = Visuals.space("lg") if _short or size.x < 600 else Visuals.space("xxl")
	var gap: float = 12 if _portrait or _short else 24
	var header_height: float = 52 if _short else (60 if _portrait else 82)
	_title.text = "Crea tu compañero" if _creating else "Tu compañero"
	_title.add_theme_font_size_override("font_size", Visuals.font_size("title",_short or size.x < 600))
	_place(_title, Rect2(margin, 10 if _short else 16, size.x - margin * 2 - 55, 36))
	_subtitle.visible = not _short and not _portrait
	_subtitle.text = "Tu nombre. Tu estilo. Tu historia." if size.x < 600 else "Una identidad propia para todas tus aventuras"
	_place(_subtitle, Rect2(margin, 52, size.x - margin * 2 - (52 if size.x < 600 else 0), 22))
	_place(_close, Rect2(size.x - margin - 44, 10 if _short else 17, 44, 44))
	var trying: bool = not _try_id.is_empty()
	var footer_height: float = (64 if _short else 84) + (56 if trying else (34 if not _error.text.is_empty() else 0))
	var body_height: float = size.y - header_height - footer_height
	var available_width: float = size.x - margin * 2
	var preview_rect: Rect2
	var options_rect: Rect2
	if _portrait:
		var preview_height: float = clampf(body_height * 0.53, 348, 440)
		if _selected_tab == 3 and not _creating: preview_height = clampf(body_height * 0.53, 348, 440)
		preview_rect = Rect2(margin, header_height, available_width, preview_height)
		options_rect = Rect2(margin, preview_rect.end.y + gap, available_width, body_height - preview_height - gap)
	else:
		var preview_width: float = available_width * (0.42 if _short else 0.44)
		preview_rect = Rect2(margin, header_height, preview_width, body_height)
		options_rect = Rect2(preview_rect.end.x + gap, header_height, available_width - preview_width - gap, body_height)
	_place(_preview_panel, preview_rect)
	_place(_options, options_rect)
	for child: Node in _items.get_children():
		if child is GridContainer and child.get_meta("color_grid", false):
			child.columns = (1 if options_rect.size.x < 680 else 2) if child.get_meta("style_grid", false) else (1 if child.get_meta("skin_grid", false) and options_rect.size.x < 500 else (3 if options_rect.size.x >= 900 else 2))
	var inner: float = 12 if _short or _portrait else 24
	_name_caption.visible = not _short and not _portrait
	_place(_name_caption, Rect2(inner, 14, preview_rect.size.x - inner * 2, 18))
	var name_y: float = 8 if _short else (12 if _portrait else 36)
	_place(_name_input, Rect2(inner, name_y, preview_rect.size.x - inner * 2, 48))
	_archetype.visible = _creating
	_role.visible = not _creating and not _short
	_place(_archetype, Rect2(inner, name_y + 56, preview_rect.size.x - inner * 2, 44))
	_place(_role, Rect2(inner, name_y + 53, preview_rect.size.x - inner * 2, 21))
	var stage_y: float = name_y + (108 if _creating else (56 if _short else 80))
	_place(_stage, Rect2(6, stage_y, preview_rect.size.x - 12, maxf(72, preview_rect.size.y - stage_y - 58)))
	_stage.queue_redraw()
	_fit_actor()
	_preview_actions.visible = _selected_tab != 3
	_style_controls.visible = _selected_tab == 3
	_place(_preview_actions, Rect2(inner, preview_rect.size.y - 48, preview_rect.size.x - inner * 2, 44))
	_place(_style_controls, Rect2(inner, preview_rect.size.y - 48, preview_rect.size.x - inner * 2, 44))
	_place(_tabs, Rect2(0, 0, options_rect.size.x, 44))
	var toolbar_width: float = minf(352, options_rect.size.x)
	_place(_toolbar, Rect2(options_rect.size.x - toolbar_width, 52, toolbar_width, 44))
	_toolbar.visible = _selected_tab != 3
	var choices_y: float = 52 if _selected_tab == 3 else 104
	var help_height: float = 0 if _short else (52 if _portrait else 37)
	_help.visible = not _short and _error.text.is_empty()
	_place(_scroll, Rect2(0, choices_y, options_rect.size.x, maxf(40, options_rect.size.y - choices_y - help_height)))
	_place(_help, Rect2(0, options_rect.size.y - help_height + 4, options_rect.size.x, maxf(0,help_height-4)))
	var footer_y: float = size.y - (54 if _short else 60)
	var confirm_width: float = minf(200, available_width - 132)
	var cancel_width: float = minf(132, available_width - confirm_width - 12)
	_place(_confirm, Rect2(size.x - margin - confirm_width, footer_y, confirm_width, 44))
	_place(_cancel, Rect2(_confirm.position.x - 12 - cancel_width, footer_y, cancel_width, 44))
	_confirm.text = "Crear compañero" if _creating else "Guardar cambios"
	_try_back.visible = trying
	_place(_try_back, Rect2(size.x - margin - 96, footer_y - 54, 96, 44))
	_place(_error, Rect2(margin, footer_y - (54 if trying else 34), available_width - (108 if trying else 0), 48 if trying else 32))
	for button: Button in _tab_buttons:
		button.add_theme_font_size_override("font_size", 13 if size.x < 600 or _short else 15)

func _fit_actor() -> void:
	if not is_instance_valid(_actor) or _actor.get_sprite_geometry().is_empty(): return
	# Camera selection is explicit and shared by every body. Hold it for the
	# entire chosen presentation, including its final pose; never follow bounds.
	var envelope: Rect2 = Fighter.VisualProfiles.portrait_envelope(_preview_framing)
	var scale_value: float = Fighter.VisualProfiles.portrait_scale(_stage.size,_preview_framing)
	# Fill the available camera without a desktop zoom cap. This same scale is
	# used by every species, preserving their authored height and volume ratios.
	_actor.scale = Vector2.ONE * scale_value
	var feet_y: float = _stage.size.y-6-envelope.end.y*float(_actor.scale.y)
	_actor.position = Vector2(_stage.size.x * 0.5, feet_y)
	_stage.floor_y = feet_y
	_stage.queue_redraw()

func select_tab(index: int) -> void:
	_end_try_on()
	_selected_tab = clampi(index, 0, 3)
	_rebuild_options()
	_layout()
	if _selected_tab == 3: _replay_style()

func _rebuild_options(preserve_scroll: bool = false) -> void:
	if not _built: return
	var previous_scroll: int = _scroll.scroll_vertical
	var focused: Control = get_viewport().gui_get_focus_owner()
	var focus_name: String = str(focused.name) if is_instance_valid(focused) and _items.is_ancestor_of(focused) else ""
	for child: Node in _items.get_children():
		_items.remove_child(child)
		child.queue_free()
	_item_buttons.clear()
	_scroll.scroll_vertical = 0
	for index in range(_tab_buttons.size()):
		Visuals.apply_button(_tab_buttons[index],"navigation_active" if index == _selected_tab else "navigation")
	match _selected_tab:
		0:
			_add_choices("body_style_id", "%d apariencias · familias y veteranos" % Cosmetics.items("body_style_id").size())
			_help.text = "Desbloquea individuos en Historia. Apariencia y edad no cambian tu estilo: %s." % Characters.definition(_archetype_id).name
		1:
			_add_color_sections()
			if _color_section == 0:
				_add_palette_choices()
				_help.text = "Toca una paleta para probarla."
			else:
				_add_skin_choices()
				_help.text = "Skins de Historia · Sin ventajas en combate."
		2:
			_add_effect_choices()
			_help.text = "Auras: acompañan al compañero en reposo." if _effect_section == 0 else "Estelas: prueba automática al golpear."
		3:
			_add_style_choices()
			_help.text = "Elige, prueba y guarda cuando te guste."
	_update_presets()
	_confirm.disabled = not _try_id.is_empty()
	_confirm.tooltip_text = "Elige una apariencia disponible para guardar." if _confirm.disabled else "Guardar nombre y apariencia"
	if preserve_scroll:
		_scroll.set_deferred("scroll_vertical", previous_scroll)
		if not focus_name.is_empty():
			_restore_choice_focus.call_deferred(focus_name)

func _restore_choice_focus(focus_name: String) -> void:
	if not is_inside_tree(): return
	var replacement := _items.find_child(focus_name, true, false) as Control
	if is_instance_valid(replacement) and replacement.is_inside_tree() and replacement.is_visible_in_tree(): replacement.grab_focus()

func _process(delta: float) -> void:
	if not _built or not is_visible_in_tree(): return
	if _actor.motion_paused or _actor.reduced_motion: return
	if _selected_tab == 3:
		if _style_auto:
			_style_demo_elapsed += delta
			if _style_demo_elapsed >= 4.0: _replay_style()
		return
	if _selected_tab != 2 or _effect_section != 1: return
	if str(_actor.appearance.get("trail_id", "none")) == "none": return
	_effect_demo_elapsed += delta
	if _effect_demo_elapsed >= 2.2 and _actor._mode == "idle": _preview_action("Golpe")

func _toggle_style_auto() -> void:
	_style_auto = _style_auto_button.button_pressed
	_style_auto_button.text = "Auto: Sí" if _style_auto else "Auto: No"
	_style_demo_elapsed = 0.0
	if _style_auto: _replay_style()

func _update_style_caption() -> void:
	var slot: String = "intro_animation_id" if _style_section == 0 else "victory_pose_id"
	var item: Dictionary = Cosmetics.definition(slot, str(_actor.appearance.get(slot, "classic")))
	_role.text = ("Entrada" if _style_section == 0 else "Victoria") + " · " + str(item.name) + (" · En prueba" if not _try_id.is_empty() else " · Vista previa")

func _replay_style() -> void:
	_update_style_caption()
	_preview_action("Entrada" if _style_section == 0 else "Victoria")

func _select_style_section(index: int) -> void:
	_end_try_on()
	_style_section = clampi(index, 0, 1)
	_rebuild_options()
	_layout()
	_replay_style()
	_restore_choice_focus.call_deferred("StyleSection%d" % _style_section)

func _add_style_choices() -> void:
	_style_auto_button.button_pressed = _style_auto
	_style_auto_button.text = "Auto: Sí" if _style_auto else "Auto: No"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_items.add_child(row)
	for index: int in range(2):
		var button := _button("Entrada" if index == 0 else "Victoria")
		button.name = "StyleSection%d" % index
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Visuals.apply_button(button, "navigation_active" if index == _style_section else "navigation")
		button.pressed.connect(_select_style_section.bind(index))
		row.add_child(button)
	var context := _label(_items, "Antes de luchar · Así se presenta tu compañero." if _style_section == 0 else "Al ganar · Así celebra tu compañero.", 13, MUTED)
	context.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	context.custom_minimum_size.y = 40
	var grid := _choice_grid(true)
	grid.set_meta("style_grid", true)
	grid.columns = 1 if _options.size.x < 680 else 2
	var slot: String = "intro_animation_id" if _style_section == 0 else "victory_pose_id"
	for item: Dictionary in Cosmetics.items(slot):
		var owned: bool = str(item.inventory_id) in _owned
		var trying: bool = _try_slot == slot and _try_id == str(item.id)
		var selected: bool = _try_id.is_empty() and str(_draft.get(slot,"")) == str(item.id)
		var button := _catalog_button(grid, slot, item, 172)
		var stage := Control.new()
		stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.position = Vector2(8,12)
		stage.size = Vector2(116,144)
		button.add_child(stage)
		var actor = Fighter.new()
		stage.add_child(actor)
		var descriptor: Dictionary = Characters.definition(_archetype_id)
		descriptor.appearance = _draft.duplicate(true)
		descriptor.appearance[slot] = str(item.id)
		actor.setup_character(descriptor)
		actor.cosmetic_preview = true
		actor.set_process(false)
		if _style_section == 1: actor.preview_victory()
		else: actor.play_intro()
		actor._process(0.4)
		var framing: String = "victory" if _style_section == 1 else "rest"
		actor.scale = Vector2.ONE * Fighter.VisualProfiles.portrait_scale(stage.size, framing)
		actor.position = Vector2(stage.size.x*0.5,stage.size.y-6-Fighter.VisualProfiles.portrait_envelope(framing).end.y*actor.scale.y)
		var name_label := _label(button, ("✓ " if selected else "") + str(item.name), 15, CREAM)
		name_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		name_label.offset_left = 136
		name_label.offset_right = -12
		name_label.offset_top = 12
		name_label.offset_bottom = 38
		var description := _label(button, str(item.description), 12, MUTED)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		description.offset_left = 136
		description.offset_right = -12
		description.offset_top = 44
		description.offset_bottom = 114
		var status: String = "En prueba · " + _unlock_short(item) if trying else ("Seleccionado" if selected else ("Disponible" if owned else _unlock_short(item)))
		var caption := _label(button, status, 12, MUTED if owned else GOLD)
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		caption.offset_left = 136
		caption.offset_right = -12
		caption.offset_top = 122
		caption.offset_bottom = 166


func _select_effect_section(index: int) -> void:
	_end_try_on()
	_effect_section = clampi(index, 0, 1)
	_rebuild_options()
	_layout()
	_restore_choice_focus.call_deferred("EffectSection%d" % _effect_section)
	if _effect_section == 1: _play_slot_preview("trail_id")

func _add_effect_choices() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_items.add_child(row)
	for index: int in range(2):
		var button := _button("Auras" if index == 0 else "Estelas")
		button.name = "EffectSection%d" % index
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Visuals.apply_button(button, "navigation_active" if index == _effect_section else "navigation")
		button.pressed.connect(_select_effect_section.bind(index))
		row.add_child(button)
	var slot: String = "aura_id" if _effect_section == 0 else "trail_id"
	var grid := _choice_grid()
	for item: Dictionary in Cosmetics.items(slot):
		var owned: bool = str(item.inventory_id) in _owned
		var trying: bool = _try_slot == slot and _try_id == str(item.id)
		var selected: bool = _try_id.is_empty() and str(_draft.get(slot,"")) == str(item.id)
		var button := _catalog_button(grid, slot, item, 152)
		var swatch := EffectSwatch.new()
		swatch.effect = item
		swatch.trail = _effect_section == 1
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(swatch)
		swatch.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		swatch.offset_top = 8
		swatch.offset_bottom = 70
		swatch.resized.connect(swatch.queue_redraw)
		if str(item.id) == "none":
			var empty := _label(button, "Sin partículas", 12, MUTED)
			empty.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
			empty.offset_top = 28
			empty.offset_bottom = 52
			empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var label := _label(button, ("✓ " if selected else "") + str(item.name), 14, CREAM)
		label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		label.offset_left = 12
		label.offset_right = -12
		label.offset_top = 76
		label.offset_bottom = 100
		var status: String = "En prueba · " + _unlock_short(item) if trying else ("Seleccionado" if selected else ("Disponible" if owned else _unlock_short(item)))
		var caption := _label(button, status, 12, MUTED if owned else GOLD)
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		caption.offset_left = 12
		caption.offset_right = -12
		caption.offset_top = 104
		caption.offset_bottom = 148


func _add_color_sections() -> void:
	var skin_count: int = 0
	for item: Dictionary in Cosmetics.items("body_style_id"):
		if item.has("species_id"): skin_count += 1
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_items.add_child(row)
	for index: int in range(2):
		var button := _button("Colores" if index == 0 else "Skins · %d" % skin_count)
		button.name = "ColorSection%d" % index
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Visuals.apply_button(button, "navigation_active" if index == _color_section else "navigation")
		button.pressed.connect(_select_color_section.bind(index))
		row.add_child(button)

func _select_color_section(index: int) -> void:
	_end_try_on()
	_color_section = clampi(index, 0, 1)
	_rebuild_options()
	_layout()
	_restore_choice_focus.call_deferred("ColorSection%d" % _color_section)

func _choice_grid(skins: bool = false) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 1 if skins and _options.size.x < 500 else (3 if _options.size.x >= 900 else 2)
	grid.set_meta("color_grid", true)
	grid.set_meta("skin_grid", skins)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	_items.add_child(grid)
	return grid

func _catalog_button(grid: GridContainer, slot: String, item: Dictionary, height: float) -> Button:
	var owned: bool = str(item.inventory_id) in _owned
	var trying: bool = _try_slot == slot and _try_id == str(item.id)
	var selected: bool = _try_id.is_empty() and str(_draft.get(slot, "")) == str(item.id)
	var button := _button("")
	button.name = slot + "_" + str(item.id)
	button.set_meta("slot", slot)
	button.set_meta("item_id", str(item.id))
	button.set_meta("owned", owned)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, height)
	button.tooltip_text = str(item.name) + " · " + str(item.description) + ("" if owned else "\n" + str(item.requirement) + " Puedes probarla sin equiparla.")
	Visuals.apply_card_button(button, selected or trying)
	button.pressed.connect(_choose_item.bind(slot, str(item.id)))
	grid.add_child(button)
	_item_buttons.append(button)
	return button

func _unlock_short(item: Dictionary) -> String:
	match str(item.unlock.kind):
		"level": return "Nivel %d" % int(item.unlock.threshold)
		"story_cleared": return "Historia · Encuentro %d" % int(item.unlock.threshold)
		"league_wins": return "Liga · %d victorias" % int(item.unlock.threshold)
	return "Disponible"

func _add_palette_choices() -> void:
	var grid := _choice_grid()
	for item: Dictionary in Cosmetics.items("palette_id"):
		var owned: bool = str(item.inventory_id) in _owned
		var trying: bool = _try_slot == "palette_id" and _try_id == str(item.id)
		var selected: bool = _try_id.is_empty() and str(_draft.palette_id) == str(item.id)
		var button := _catalog_button(grid, "palette_id", item, 148)
		var swatches := HBoxContainer.new()
		swatches.mouse_filter = Control.MOUSE_FILTER_IGNORE
		swatches.add_theme_constant_override("separation", 0)
		button.add_child(swatches)
		swatches.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		swatches.offset_left = 12
		swatches.offset_right = -12
		swatches.offset_top = 12
		swatches.offset_bottom = 68
		for tone: String in ["primary", "secondary", "accent"]:
			var swatch := ColorRect.new()
			swatch.color = Color(str(item.colors[tone]))
			swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
			swatch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			swatches.add_child(swatch)
		var label := _label(button, ("✓ " if selected else "") + str(item.name), 14, CREAM)
		label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		label.offset_left = 12
		label.offset_right = -12
		label.offset_top = 76
		label.offset_bottom = 100
		var status: String = "En prueba · " + _unlock_short(item) if trying else ("Seleccionado" if selected else ("Disponible" if owned else _unlock_short(item)))
		var caption := _label(button, status, 12, MUTED if owned else GOLD)
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		caption.offset_left = 12
		caption.offset_right = -12
		caption.offset_top = 103
		caption.offset_bottom = 143

func _add_skin_choices() -> void:
	var grid := _choice_grid(true)
	for item: Dictionary in Cosmetics.items("body_style_id"):
		if not item.has("species_id"): continue
		var owned: bool = str(item.inventory_id) in _owned
		var trying: bool = _try_slot == "body_style_id" and _try_id == str(item.id)
		var selected: bool = _try_id.is_empty() and str(_draft.body_style_id) == str(item.id)
		var button := _catalog_button(grid, "body_style_id", item, 276)
		var stage := Control.new()
		stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(stage)
		stage.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		stage.offset_top = 12
		stage.offset_bottom = 184
		var actor = Fighter.new()
		stage.add_child(actor)
		actor.setup_character(Cosmetics.body_definition(str(item.id)))
		actor.set_process(false)
		# A shared camera preserves size differences in all card widths.
		stage.resized.connect(func():
			actor.scale = Vector2.ONE * Fighter.VisualProfiles.portrait_scale(stage.size)
			actor.position = Vector2(stage.size.x * 0.5, stage.size.y - 6 - 8 * actor.scale.y))
		var label := _label(button, ("✓ " if selected else "") + str(item.name), 16, CREAM)
		label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		label.offset_left = 12
		label.offset_right = -12
		label.offset_top = 184
		label.offset_bottom = 212
		var status: String = "En prueba · " + _unlock_short(item) if trying else ("Seleccionada" if selected else ("Disponible" if owned else _unlock_short(item)))
		var caption := _label(button, status, 12, MUTED if owned else GOLD)
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		caption.offset_left = 12
		caption.offset_right = -12
		caption.offset_top = 216
		caption.offset_bottom = 268
		button.resized.connect(_layout_skin_card.bind(button, stage, label, caption))
		_layout_skin_card(button, stage, label, caption)

func _layout_skin_card(button: Button, stage: Control, label: Label, caption: Label) -> void:
	var compact: bool = _options.size.x < 500
	button.custom_minimum_size.y = 124 if compact else 276
	stage.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT if compact else Control.PRESET_TOP_WIDE)
	stage.offset_left = 12 if compact else 0
	stage.offset_right = 116 if compact else 0
	stage.offset_top = 8 if compact else 12
	stage.offset_bottom = 116 if compact else 184
	label.offset_left = 128 if compact else 12
	label.offset_top = 16 if compact else 184
	label.offset_bottom = 44 if compact else 212
	caption.offset_left = 128 if compact else 12
	caption.offset_top = 50 if compact else 216
	caption.offset_bottom = 116 if compact else 268

func _end_try_on() -> void:
	_try_slot = ""
	_try_id = ""
	_confirm.disabled = false
	set_error("")
	_refresh_preview()

func _add_choices(slot: String, heading: String) -> void:
	_label(_items, heading, 13, MUTED)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items.add_child(grid)
	for item: Dictionary in Cosmetics.items(slot):
		var owned: bool = str(item.inventory_id) in _owned
		var selected: bool = str(_draft.get(slot, "")) == str(item.id)
		var button := _button("")
		button.name = slot + "_" + str(item.id)
		button.set_meta("slot", slot)
		button.set_meta("item_id", str(item.id))
		button.set_meta("owned", owned)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 80 if slot == "body_style_id" else 84)
		button.tooltip_text = str(item.description) + ("" if owned else "\n" + str(item.requirement))
		Visuals.apply_card_button(button,selected)
		button.pressed.connect(_choose_item.bind(slot, str(item.id)))
		grid.add_child(button)
		_item_buttons.append(button)
		var label := _label(button, ("✓ " if selected else "") + str(item.name), 14, CREAM if owned else MUTED)
		label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		label.offset_left = 72 if slot == "body_style_id" else 12
		label.offset_right = -7
		label.offset_top = 13
		label.offset_bottom = 38
		if slot == "body_style_id":
			var actor = Fighter.new()
			button.add_child(actor)
			actor.setup_character(Cosmetics.body_definition(str(item.id)))
			actor.set_process(false)
			actor.scale = Vector2.ONE * 0.32
			actor.position = Vector2(37, 69)
			actor.modulate.a = 1.0 if owned else 0.45
			var caption := _label(button, "Disponible" if owned else str(item.requirement), 11, MUTED)
			caption.position = Vector2(72, 43)
			caption.size = Vector2(80, 24)
		else:
			var caption := _label(button, str(item.description) if owned else "Bloqueado · " + str(item.requirement), 11, MUTED if owned else GOLD)
			caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			caption.offset_left = 12
			caption.offset_right = -10
			caption.offset_top = 37
			caption.offset_bottom = -7

func _choose_item(slot: String, id: String) -> void:
	var item: Dictionary = Cosmetics.definition(slot, id)
	if item.is_empty(): return
	if not str(item.inventory_id) in _owned:
		if slot in ["palette_id", "body_style_id", "aura_id", "trail_id", "intro_animation_id", "victory_pose_id"]:
			if _try_slot == slot and _try_id == id:
				_end_try_on()
				_rebuild_options(true)
				return
			_try_slot = slot
			_try_id = id
			_refresh_preview()
			_rebuild_options(true)
		set_error(str(item.name) + ": " + str(item.requirement))
		_play_slot_preview(slot)
		return
	_try_slot = ""
	_try_id = ""
	_draft[slot] = id
	set_error("")
	_refresh_preview()
	_rebuild_options(true)
	_play_slot_preview(slot)

func _play_slot_preview(slot: String) -> void:
	if _selected_tab == 3: _update_style_caption()
	if slot == "victory_pose_id": _preview_action("Victoria")
	elif slot == "intro_animation_id": _preview_action("Entrada")
	elif slot == "trail_id": _preview_action("Golpe")

func _choose_archetype(index: int) -> void:
	if not _creating or index < 0 or index >= Characters.IDS.size(): return
	_end_try_on()
	var previous: String = _archetype_id
	_archetype_id = Characters.IDS[index]
	if _name_input.text == str(Characters.definition(previous).name):
		_name_input.text = str(Characters.definition(_archetype_id).name)
	if str(_draft.get("body_style_id", "")) == previous:
		_draft["body_style_id"] = _archetype_id
	_refresh_preview()
	_rebuild_options()

func _refresh_preview() -> void:
	_effect_demo_elapsed = 0.0
	_style_demo_elapsed = 0.0
	var descriptor: Dictionary = Characters.definition(_archetype_id)
	descriptor["appearance"] = _draft.duplicate(true)
	if not _try_id.is_empty(): descriptor.appearance[_try_slot] = _try_id
	descriptor["identity"] = {"display_name": _name_input.text}
	_actor.setup_character(descriptor)
	_preview_framing = "rest"
	_role.text = "Vista previa · %s · Sin desbloquear" % Cosmetics.definition(_try_slot, _try_id).name if not _try_id.is_empty() else "Combate: %s · %s" % [descriptor.name, descriptor.role]
	_fit_actor()
	if _selected_tab == 3: _update_style_caption()

func _preview_action(action: String) -> void:
	_effect_demo_elapsed = 0.0
	_style_demo_elapsed = 0.0
	_actor.reset_pose()
	_preview_framing = "attack" if action == "Golpe" else ("victory" if action == "Victoria" else "rest")
	_fit_actor()
	match action:
		"Golpe":
			var moves: Array = Moves.unlocked_moves(_archetype_id, 1)
			if not moves.is_empty(): _actor.play_move(moves[0])
		"Entrada": _actor.play_intro()
		"Victoria": _actor.preview_victory()

func randomize_owned() -> void:
	_end_try_on()
	var result: Dictionary = Cosmetics.randomize_owned(_archetype_id, _owned)
	if result.is_empty(): return
	_draft = result.duplicate(true)
	set_error("")
	_refresh_preview()
	_rebuild_options()

func _update_presets() -> void:
	var presets: Array[Dictionary] = Cosmetics.presets()
	for index in range(presets.size()):
		var candidate: Dictionary = _draft.duplicate(true)
		candidate.merge(presets[index].appearance, true)
		var validation: Dictionary = Cosmetics.validate_appearance(candidate, _owned, _archetype_id)
		_presets.set_item_disabled(index + 1, not bool(validation.ok))
		_presets.set_item_text(index + 1, str(presets[index].name) + (" · bloqueado" if not bool(validation.ok) else ""))
	_presets.select(0)
	_presets.text = "Conjunto visual…"

func _choose_preset(index: int) -> void:
	if index <= 0: return
	var presets: Array[Dictionary] = Cosmetics.presets()
	if index > presets.size(): return
	_end_try_on()
	var candidate: Dictionary = _draft.duplicate(true)
	candidate.merge(presets[index - 1].appearance, true)
	var validation: Dictionary = Cosmetics.validate_appearance(candidate, _owned, _archetype_id)
	if not bool(validation.ok):
		set_error(str(validation.error))
		return
	_draft = validation.appearance.duplicate(true)
	set_error("")
	_refresh_preview()
	_rebuild_options()

func set_error(message: String) -> void:
	if not _built: return
	_error.text = message
	_error.add_theme_color_override("font_color", GOLD if not _try_id.is_empty() else Visuals.CORAL)
	_error.visible = not message.is_empty()
	_help.visible = message.is_empty() and not _short
	_layout()

func _confirm_draft() -> void:
	if not _try_id.is_empty(): return
	var validation: Dictionary = Cosmetics.validate_appearance(_draft, _owned, _archetype_id)
	if not bool(validation.ok):
		set_error(str(validation.error))
		return
	confirmed.emit(_archetype_id, _name_input.text, validation.appearance.duplicate(true))

func _cancel_draft() -> void:
	cancelled.emit()

func _input(event: InputEvent) -> void:
	OverlayFocus.handle(event, self, _cancel_draft)

func _place(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size

func _label(parent: Node, value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	if font_size >= 20: label.add_theme_font_override("font",Visuals.font("title"))
	label.add_theme_color_override("font_color", color)
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	parent.add_child(label)
	return label

func _button(value: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = value
	Visuals.apply_button(button,"primary" if primary else "secondary")
	return button

func _style_option(option: OptionButton) -> void:
	Visuals.apply_option(option)
	option.fit_to_longest_item = false
	option.clip_text = true
	# Keep text off the painted end caps and reserve space for the native arrow.
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var surface: StyleBox = option.get_theme_stylebox(state).duplicate()
		surface.content_margin_left = 24
		surface.content_margin_right = 36
		option.add_theme_stylebox_override(state, surface)
