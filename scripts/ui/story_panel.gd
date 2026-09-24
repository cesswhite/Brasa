extends Control
class_name StoryPanel
## Story presentation only. All persistence and progression belong to the caller.

signal character_chosen(id: String)
signal fight_requested
signal upgrade_requested(key: String)
signal league_requested
signal next_chapter_requested
signal upgrade_move_requested(move_id: String)
signal perk_chosen(perk_id: String)
signal replay_requested(global_level: int)
signal respec_requested
signal closed
signal customize_requested(id: String)

const CompanionPreview = preload("res://scripts/ui/components/game_fighter_preview.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Story = preload("res://scripts/story_catalog.gd")
const Balance = preload("res://scripts/balance.gd")
const Fighter = preload("res://scripts/fighter_view.gd")
const Moves = preload("res://scripts/move_catalog.gd")
const Campaign = preload("res://scripts/campaign_config.gd")
const WorldVisualsScript = preload("res://scripts/ui/world_visuals.gd")
const WorldBackdropScript = preload("res://scripts/ui/world_backdrop.gd")
const Visuals = preload("res://scripts/ui/game_visual_system.gd")
const GameModalScript = preload("res://scripts/ui/components/game_modal.gd")
const OverlayFocus = preload("res://scripts/ui/components/game_overlay_focus.gd")
const CREAM := Visuals.CREAM
const GOLD := Visuals.GOLD
const TEAL := Visuals.TEAL
const MUTED := Visuals.MUTED
const CORAL := Visuals.CORAL
const DARK := Visuals.DARK
const SURFACE := Visuals.SURFACE
const Achievements = preload("res://scripts/story_achievements.gd")
const Cosmetics = preload("res://scripts/cosmetic_catalog.gd")
const TAB_IDS := ["route", "upgrades", "moves", "companions", "legacy"]

class JourneyPath extends Control:
	var columns: int = 8
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(_arrange)
		_arrange.call_deferred()
	func _arrange() -> void:
		var cell: float = size.x / maxi(1,columns)
		for index in range(get_child_count()):
			var button: Control = get_child(index)
			button.position = Vector2((index % columns)*cell, floori(float(index)/columns)*96)
			button.size = Vector2(cell,92)
		queue_redraw()
	func _draw() -> void:
		for index in range(get_child_count()-1):
			var left: Control = get_child(index)
			var right: Control = get_child(index+1)
			if index % columns == columns-1: continue
			var from: Vector2 = left.position+Vector2(left.size.x*0.5,24)
			var to: Vector2 = right.position+Vector2(right.size.x*0.5,24)
			draw_line(from,to,Color("56756a"),2,true)

class RouteMarker extends Button:
	var accent := Color("7dd7bd")
	var selected: bool = false
	var completed: bool = false
	var kind: String = "normal"
	var badge: Texture2D
	func _ready() -> void:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for state: String in ["normal","hover","pressed","focus","disabled"]: add_theme_stylebox_override(state,StyleBoxEmpty.new())
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)
	func _draw() -> void:
		var center := Vector2(size.x*0.5,24)
		if selected or has_focus(): draw_circle(center,25,Color(accent,0.16))
		if badge != null:
			var dimensions: Vector2 = badge.get_size()
			var fitted: Vector2 = dimensions * (48.0/maxf(dimensions.x,dimensions.y))
			draw_texture_rect(badge,Rect2(center-fitted*0.5,fitted),false,Color.WHITE if selected or completed else Color(0.82,0.87,0.85))
		else:
			draw_circle(center,20,Color("173336"))
			draw_arc(center,20,0,TAU,40,accent,1,true)
		if selected or is_hovered() or has_focus(): draw_arc(center,24,0,TAU,48,accent,1.5,true)

var _progression
var identity_store
var arena_wins_by_character: Dictionary = {}

func _identity_definition(id: String) -> Dictionary:
	var definition: Dictionary = Catalog.definition(id)
	if identity_store == null: return definition
	definition["character_id"] = id
	definition["base_name"] = str(definition.name)
	return identity_store.decorate(definition)

func _identity_name(profile: Dictionary) -> String:
	return str(identity_store.decorate(profile).get("name", profile.get("name", ""))) if identity_store != null else str(profile.get("name", ""))
var _built := false
var _active_tab := "route"
var _selected_id := ""
var _selected_stage := 0
var _last_id := ""
var _last_complete := false
var _last_stage := -1
var _last_chapter := -1
var _legacy_chapter := 1
var _achievement_character := ""
var _achievement_filter := "pending"
var _achievement_all := false
var _achievement_record := false
var _achievement_snapshot: Dictionary = {}
var _achievement_picker: OptionButton
var _achievement_filters: Dictionary = {}
var _route_chapter := 1
var _route_details := false
var _route_help: Button
var _route_detail_content: VBoxContainer
var _route_continue: Button
var _footer_spacer: Control
var _cooldown_remaining := -1
var _shape := ""
var _phone := false
var _short := false
var _margin: MarginContainer
var _shell: VBoxContainer
var _heading: Label
var _subtitle: Label
var _save_notice: Label
var _close: Button
var _tabs: HBoxContainer
var _tab_buttons: Dictionary = {}
var _scroll: ScrollContainer
var _body: VBoxContainer
var _footer: HBoxContainer
var _league: Button
var _primary: Button
var _stage_buttons: Array[Button] = []
var _character_buttons: Array[Button] = []
var _companion_help: Button
var _companion_details: VBoxContainer
var _companion_details_open := false
var _companion_custom: Button
var _companion_previews: Array[Control] = []
var _companion_progress_label: Label
var _companion_xp_label: Label
var _chapter_buttons: Array[Button] = []
var _upgrade_buttons: Dictionary = {}
var _upgrade_help_buttons: Dictionary = {}
var _upgrade_help_labels: Dictionary = {}
var _upgrade_help_key := ""
var _upgrade_notice := ""
var _upgrade_notice_label: Label
var _move_buttons: Dictionary = {}
var _perk_buttons: Dictionary = {}
var _moves_section := "techniques"
var _moves_sections: Dictionary = {}
var _moves_filters: Dictionary = {}
var _moves_details: Dictionary = {}
var _moves_help_buttons: Dictionary = {}
var _moves_detail_key := ""
var _moves_notice := ""
var _moves_notice_label: Label
var _route_picker: OptionButton
var _legacy_picker: OptionButton
var _campaign_status: Label
var _portraits: Array[Node2D] = []
var _content_grids: Array[GridContainer] = []
var _last_hint: Label
var _respec: Button
var _confirmation: Control
var _confirmation_card: PanelContainer
var _confirmation_accept: Button
var _confirmation_cancel: Button
var _backdrop: Control
var _display_font: Font
var _reading_gradient: Gradient


func configure(story_progression: RefCounted) -> void:
	_progression = story_progression
	_last_id = ""
	_last_complete = false
	_last_stage = -1
	_last_chapter = -1
	_ensure_interface()
	refresh()
	if is_inside_tree(): Visuals.reveal(self)


func refresh() -> void:
	if _progression == null: return
	_close_respec_confirmation()
	_ensure_interface()
	var profile: Dictionary = _progression.data
	var id := str(profile.get("character_id", ""))
	var complete := bool(profile.get("completed", false))
	var chapter: int = _progression.current_chapter()
	if id.is_empty():
		_active_tab = "companions"
		if _selected_id.is_empty(): _selected_id = str(Catalog.IDS[0])
	elif id != _last_id:
		_upgrade_notice = ""
		_upgrade_help_key = ""
		_moves_notice = ""
		_moves_detail_key = ""
		_moves_section = "techniques"
		_achievement_character = id
		_achievement_record = false
		_selected_id = id
		_route_chapter = chapter
		_selected_stage = clampi(_progression.current_stage(), 0, Story.stages(chapter).size()-1)
		_legacy_chapter = chapter
		_active_tab = "legacy" if complete else "route"
	elif chapter != _last_chapter:
		_achievement_record = false
		_route_chapter = chapter
		_selected_stage = clampi(_progression.current_stage(),0,Story.stages(chapter).size()-1)
		_legacy_chapter = chapter
		_active_tab = "legacy" if complete else "route"
	elif complete and not _last_complete:
		_achievement_record = false
		_route_chapter = chapter
		_active_tab = "legacy"
		_legacy_chapter = chapter
	elif int(_progression.current_stage()) != _last_stage:
		_route_chapter = chapter
		_selected_stage = clampi(_progression.current_stage(), 0, Story.stages(chapter).size()-1)
	_last_stage = int(_progression.current_stage())
	_last_chapter = chapter
	_last_id = id
	_last_complete = complete
	_save_notice.visible = not bool(_progression.last_save_ok) or bool(_progression.save_blocked)
	var notice := str(_progression.load_notice)
	_save_notice.text = ("Guardado protegido. " if bool(_progression.save_blocked) else "No se pudo guardar. ") + (notice if not notice.is_empty() else "El avance de esta sesión aún no está guardado.")
	_save_notice.tooltip_text = _save_notice.text
	_rebuild_body()
	_refresh_actions()


func show_tab(tab_id: String) -> void:
	if not tab_id in TAB_IDS: return
	if _progression == null: return
	if _progression.data.is_empty() and tab_id not in ["companions","legacy"]: return
	_close_respec_confirmation()
	_active_tab = tab_id
	_rebuild_body()
	_refresh_actions()
	_scroll.scroll_vertical = 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ensure_interface()
	resized.connect(_layout_responsive)
	_layout_responsive()


func _process(_delta: float) -> void:
	if _progression == null or _active_tab != "route": return
	var remaining := ceili(maxf(0.0,float(_progression.seconds_until_next_match())))
	if remaining != _cooldown_remaining:
		_refresh_actions()


func _ensure_interface() -> void:
	if _built: return
	_built = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Visuals.theme()
	_display_font = Visuals.font("title")
	_backdrop = WorldBackdropScript.new()
	add_child(_backdrop)
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var text_veil := TextureRect.new()
	text_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_veil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var gradient := Gradient.new()
	gradient.set_color(0,Color(0.015,0.025,0.025,0.66))
	gradient.set_color(1,Color(0.015,0.025,0.025,0.14))
	gradient.add_point(0.46,Color(0.015,0.025,0.025,0.42))
	_reading_gradient = gradient
	var veil := GradientTexture2D.new()
	veil.gradient = gradient
	veil.fill_from = Vector2(0,0)
	veil.fill_to = Vector2(1,0)
	text_veil.texture = veil
	add_child(text_veil)
	text_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_margin = MarginContainer.new()
	_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_margin)
	_shell = VBoxContainer.new()
	_shell.add_theme_constant_override("separation", 12)
	_margin.add_child(_shell)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	_shell.add_child(header)
	var title_stack := _stack(header)
	title_stack.add_theme_constant_override("separation",4)
	_label(title_stack, "BRASA  /  MODO HISTORIA", 12, GOLD)
	_heading = _label(title_stack, "Elige tu historia", 29, CREAM)
	_heading.add_theme_font_override("font",_display_font)
	_subtitle = _label(title_stack, "", 14, MUTED)
	_subtitle.mouse_filter = Control.MOUSE_FILTER_PASS
	_close = _button("×", false)
	_close.custom_minimum_size = Vector2(48,48)
	_close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_close.tooltip_text = "Cerrar Historia · Esc"
	Visuals.apply_button(_close,"icon")
	_close.pressed.connect(func(): closed.emit())
	header.add_child(_close)
	_save_notice = _label(_shell,"",14,CORAL)
	_save_notice.max_lines_visible = 2
	_save_notice.mouse_filter = Control.MOUSE_FILTER_PASS
	_save_notice.hide()
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 8)
	_shell.add_child(_tabs)
	for index in range(TAB_IDS.size()):
		var id: String = TAB_IDS[index]
		var tab := _button(["Ruta", "Mejoras", "Movimientos", "Compañeros", "Logros"][index], false)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.pressed.connect(show_tab.bind(id))
		_tabs.add_child(tab)
		_tab_buttons[id] = tab
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.follow_focus = true
	_scroll.scroll_deadzone = 12
	_shell.add_child(_scroll)
	_body = _stack(_scroll)
	_body.add_theme_constant_override("separation", 12)
	var line := HSeparator.new()
	line.modulate = Color("35504f")
	_shell.add_child(line)
	_footer = HBoxContainer.new()
	_footer.add_theme_constant_override("separation", 12)
	_shell.add_child(_footer)
	_league = _button("Volver a la liga", false)
	_league.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_league.pressed.connect(func(): league_requested.emit())
	_footer.add_child(_league)
	_primary = _button("Ver la ruta", true)
	_primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_primary.size_flags_stretch_ratio = 1.4
	_primary.pressed.connect(_primary_pressed)
	_footer.add_child(_primary)
	_footer_spacer = Control.new()
	_footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer.add_child(_footer_spacer)
	_footer.move_child(_footer_spacer,1)
	_route_continue = _button("Continuar historia",true)
	_route_continue.pressed.connect(_continue_route)
	_footer.add_child(_route_continue)
	_route_continue.hide()
	_footer_spacer.hide()
	_layout_responsive()


func _layout_responsive() -> void:
	if not _built: return
	var view := size if size.x > 0 else Vector2(1360,880)
	_phone = view.x < 600
	_short = view.y < 540
	var padding := 16 if _phone or _short else 32
	for edge: String in ["left", "top", "right", "bottom"]:
		_margin.add_theme_constant_override("margin_"+edge,padding)
	_shell.add_theme_constant_override("separation",10 if _short else 12)
	_heading.add_theme_font_size_override("font_size",20 if _phone or _short else 29)
	_subtitle.visible = not _short
	_tab_buttons.companions.text = "Equipo" if _phone or _short else "Compañeros"
	_tab_buttons.moves.text = "Técnicas" if _phone else "Movimientos"
	_tab_buttons.upgrades.text = "Mejora" if _phone else "Mejoras"
	for button: Button in _tab_buttons.values(): button.add_theme_font_size_override("font_size",13 if _phone else 15)
	_league.text = "Volver" if _phone else "Volver a la liga"
	_layout_footer()
	var next_shape := "%s:%s:%d:%s:%s" % [_phone,_short,_columns(),size.x>=1500,size.x<900]
	if next_shape != _shape:
		_shape = next_shape
		if _progression != null:
			_rebuild_body()
			_refresh_actions()


func _columns() -> int:
	return 1 if _phone else (2 if size.x < 1100 else 4)


func _rebuild_body() -> void:
	if _progression == null: return
	for child: Node in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	_stage_buttons.clear()
	_character_buttons.clear()
	_companion_previews.clear()
	_companion_custom = null
	_chapter_buttons.clear()
	_upgrade_buttons.clear()
	_upgrade_help_buttons.clear()
	_upgrade_help_labels.clear()
	_move_buttons.clear()
	_perk_buttons.clear()
	_moves_sections.clear()
	_moves_filters.clear()
	_moves_details.clear()
	_moves_help_buttons.clear()
	_route_picker = null
	_legacy_picker = null
	_campaign_status = null
	_portraits.clear()
	_content_grids.clear()
	_last_hint = null
	_respec = null
	match _active_tab:
		"route": _build_route()
		"upgrades": _build_upgrades()
		"moves": _build_moves()
		"companions": _build_companions()
		"legacy": _build_legacy()
	_update_world_context()


func _update_world_context() -> void:
	if _progression == null or not is_instance_valid(_backdrop): return
	var profile: Dictionary = _progression.data
	if _active_tab=="companions": profile = _progression.roster.get(_selected_id,{"character_id":_selected_id})
	var chapter: int = _route_chapter if _active_tab=="route" else _progression.current_chapter()
	var boss := _active_tab=="route" and str(Story.stage(_selected_stage,chapter).get("kind",""))=="boss"
	var decorated: Dictionary = identity_store.decorate(profile) if identity_store != null and not profile.is_empty() else profile
	var id := str(profile.get("character_id",_selected_id))
	var completed: int = _completed_encounters()
	if _active_tab=="companions": completed = _global_level(int(profile.get("chapter",1)),0)-1+int(profile.get("current_stage",0))
	var state := {"character_id":id,"appearance":decorated.get("appearance",{}),"owned_cosmetics":identity_store.owned_ids() if identity_store != null else [],"story_cleared":completed,"arena_wins":int(arena_wins_by_character.get(id,0))}
	_backdrop.set_context(WorldVisualsScript.context_id(_active_tab,chapter,boss),state)
	_backdrop.get_node("DecorativeMemories").visible = _active_tab not in ["legacy","route","upgrades","moves","companions"]
	_reading_gradient.set_color(2,Color(0.015,0.025,0.025,0.14 if _active_tab=="route" else 0.58))


func _refresh_actions() -> void:
	if _progression == null: return
	var profile: Dictionary = _progression.data
	_refresh_heading(profile)
	for id: String in TAB_IDS:
		var button: Button = _tab_buttons[id]
		button.disabled = profile.is_empty() and id not in ["companions","legacy"]
		Visuals.apply_button(button,"navigation_active" if id == _active_tab else "navigation")
		button.add_theme_font_size_override("font_size",13 if _phone else 15)
	_primary.disabled = bool(_progression.save_blocked)
	match _active_tab:
		"companions":
			_primary.text = "Continuar historia" if _companion_has_progress(_progression.roster.get(_selected_id,{})) else "Empezar historia"
			_primary.disabled = _primary.disabled or _selected_id.is_empty()
		"route":
			_cooldown_remaining = ceili(maxf(0.0,float(_progression.seconds_until_next_match())))
			var selected := _global_level(_route_chapter,_selected_stage)
			if _can_replay(selected):
				_primary.text = "Repetir encuentro %02d" % selected if _cooldown_remaining==0 else "Reintento en %d s" % _cooldown_remaining
				_primary.disabled = _primary.disabled or _cooldown_remaining>0
			elif _progression.is_complete():
				_primary.text = "Ver mis logros" if _route_chapter==_progression.current_chapter() else "Capítulo bloqueado"
				_primary.disabled = _primary.disabled or _route_chapter!=_progression.current_chapter()
			else:
				var current: int = _progression.current_stage()
				_cooldown_remaining = ceili(maxf(0.0,float(_progression.seconds_until_next_match())))
				_primary.text = "Pelear otra vez" if int(profile.get("attempts",{}).get(str(Story.stage(current,_progression.current_chapter()).id),0)) > 0 else "Entrar al combate"
				if _cooldown_remaining > 0: _primary.text = "Reintento en %d s" % _cooldown_remaining
				_primary.disabled = _primary.disabled or _route_chapter != _progression.current_chapter() or _selected_stage != current or _cooldown_remaining > 0
		"upgrades", "moves": _primary.text = "Ver la ruta"
		"legacy":
			if _achievement_character != str(profile.get("character_id","")):
				_primary.text = "Jugar con " + str(Catalog.definition(_achievement_character).name)
			elif _progression.can_start_next_chapter(): _primary.text = "Comenzar capítulo %d" % (_progression.current_chapter()+1)
			elif not _progression.is_complete(): _primary.text = "Volver al capítulo %d" % _progression.current_chapter()
			else: _primary.text = "Elegir compañero"
	_layout_footer()


func _layout_footer() -> void:
	if not is_instance_valid(_route_continue): return
	var route: bool = _active_tab=="route" and _progression!=null and not _progression.data.is_empty()
	var compact_actions := route or _active_tab in ["upgrades","moves","companions"]
	_footer_spacer.visible = compact_actions
	_route_continue.hide()
	_league.custom_minimum_size.x = 84 if _phone and compact_actions else (160 if compact_actions else 0)
	_league.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if compact_actions else Control.SIZE_EXPAND_FILL
	_primary.size_flags_horizontal = Control.SIZE_SHRINK_END if compact_actions else Control.SIZE_EXPAND_FILL
	_primary.custom_minimum_size.x = 240 if compact_actions else 0
	_primary.add_theme_font_size_override("font_size",13 if _phone else 15)
	Visuals.apply_button(_primary,"primary")
	if not route: return
	var selected := _global_level(_route_chapter,_selected_stage)
	var current := _global_level(_progression.current_chapter(),mini(_progression.current_stage(),Story.stages(_progression.current_chapter()).size()-1))
	_route_continue.visible = selected!=current or _progression.is_complete()
	_route_continue.disabled = bool(_progression.save_blocked)
	_route_continue.text = "Ver logros" if _progression.is_complete() and not _progression.can_start_next_chapter() else ("Continuar" if _phone else "Continuar historia")
	_route_continue.custom_minimum_size.x = 116 if _phone else 220
	_route_continue.add_theme_font_size_override("font_size",13 if _phone else 15)
	if _route_continue.visible:
		Visuals.apply_button(_primary,"secondary")
		_primary.custom_minimum_size.x = 118 if _phone else 240
		if _phone and _can_replay(selected): _primary.text = "Repetir %d" % selected if _cooldown_remaining==0 else "Esperar %d s" % _cooldown_remaining
	if selected>_completed_encounters() and selected!=current: _primary.text = "Bloqueado"


func _continue_route() -> void:
	if _active_tab!="route" or _progression==null or _progression.save_blocked: return
	if _progression.is_complete():
		if _progression.can_start_next_chapter(): next_chapter_requested.emit()
		else: show_tab("legacy")
	else: _select_route_chapter(_progression.current_chapter(),true)


func _refresh_heading(profile: Dictionary) -> void:
	_heading.get_parent().get_child(0).visible = _active_tab not in ["legacy","route","upgrades","moves","companions"]
	if _active_tab == "companions":
		_heading.text = "Compañeros"
		_subtitle.text = "Cada historia conserva su progreso."
		_subtitle.tooltip_text = _subtitle.text
		return
	if _active_tab == "legacy":
		_heading.text = "Logros de " + str(_identity_definition(_achievement_character).name)
		_subtitle.text = "Tus metas, insignias y recompensas de Historia."
		_subtitle.tooltip_text = _subtitle.text
		return
	if profile.is_empty():
		_heading.text = "Elige tu historia"
		_subtitle.text = "Cada compañero comienza su propia ruta desde el Capítulo 1."
	else:
		var chapter: int = _route_chapter if _active_tab=="route" else _progression.current_chapter()
		_heading.text = _chapter_title(chapter)
		var experience := "%d / %d XP" % [int(profile.xp),_progression.xp_needed()] if _progression.xp_needed()>0 else "%d XP total" % int(profile.get("total_xp",0))
		_subtitle.text = "%s · Personaje nv. %d · %s · %d puntos" % [_identity_name(profile),int(profile.level),experience,int(profile.points)]
	if _active_tab in ["upgrades","moves"]:
		_heading.text = "Mejoras" if _active_tab=="upgrades" else "Movimientos"
		_subtitle.text = "%s · Nivel %d" % [_identity_name(profile),int(profile.get("level",1))]
	if _active_tab=="route":
		_subtitle.text = "%s · Nivel %d" % [_identity_name(profile),int(profile.get("level",1))]
		if int(profile.get("points",0))>0: _subtitle.text += " · %d mejoras disponibles" % int(profile.points)
	_subtitle.tooltip_text = _subtitle.text


func _primary_pressed() -> void:
	if _primary.disabled or _progression == null: return
	match _active_tab:
		"companions": character_chosen.emit(_selected_id)
		"route":
			var selected := _global_level(_route_chapter,_selected_stage)
			if _can_replay(selected):
				if _progression.seconds_until_next_match()>0: _refresh_actions()
				else: replay_requested.emit(selected)
			elif _progression.is_complete(): show_tab("legacy")
			elif _route_chapter==_progression.current_chapter() and _selected_stage == _progression.current_stage():
				if _progression.seconds_until_next_match() > 0: _refresh_actions()
				else: fight_requested.emit()
		"upgrades", "moves": _select_route_chapter(_progression.current_chapter(),true)
		"legacy":
			if _achievement_character != str(_progression.data.get("character_id","")):
				character_chosen.emit(_achievement_character)
			elif _progression.can_start_next_chapter(): next_chapter_requested.emit()
			elif not _progression.is_complete(): _select_route_chapter(_progression.current_chapter(),true)
			else: show_tab("companions")


func _build_route() -> void:
	var chapter: int = _route_chapter
	var stages: Array = Story.stages(chapter)
	if stages.is_empty(): return
	var current: int = _progression.current_stage()
	var profile: Dictionary = _progression.data
	var completed := _completed_encounters()
	var global_current := _global_level(_progression.current_chapter(),mini(current,Story.stages(_progression.current_chapter()).size()-1))
	_selected_stage = clampi(_selected_stage,0,stages.size()-1)
	var stage: Dictionary = stages[_selected_stage]
	var selected_global := _global_level(chapter,_selected_stage)
	var opponent: Dictionary = _progression.preview_opponent(selected_global) if _progression.has_method("preview_opponent") else Story.opponent(_selected_stage,chapter)
	var stacked := size.x < 900 and not _short
	var hero := GridContainer.new()
	hero.name = "EncounterHero"
	hero.columns = 1 if stacked else 2
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero.add_theme_constant_override("h_separation",32)
	hero.add_theme_constant_override("v_separation",12)
	_body.add_child(hero)
	var intro := _stack(hero)
	intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intro.add_theme_constant_override("separation",10)
	if not stacked: intro.custom_minimum_size.x = 300 if _short else minf(420,size.x*0.35)
	var cleared := selected_global<=completed
	var locked := selected_global>global_current
	var state := "SUPERADO · PRÁCTICA" if cleared else ("BLOQUEADO" if locked else "TU SIGUIENTE COMBATE")
	_label(intro,"ENCUENTRO %02d · %s" % [selected_global,state],12,TEAL if cleared else GOLD)
	_label(intro,str(opponent.get("name",stage.get("title","Rival"))),26 if _phone or _short else 32)
	var kind_name: String = {"boss":"Jefe","elite":"Élite"}.get(str(stage.get("kind","normal")),"Rival")
	_label(intro,"%s · Nivel %d" % [kind_name,int(stage.get("level",1))],14,MUTED)
	if cleared: _label(intro,"Practica sin XP ni recompensas. Tu avance se conserva.",14,MUTED)
	elif locked: _label(intro,"Supera los encuentros anteriores para llegar aquí.",14,MUTED)
	else: _label(intro,"Victoria +%d XP · Derrota +%d XP" % [int(stage.get("xp_win",0)),int(stage.get("xp_loss",0))],14,GOLD)
	var rewards: Dictionary = stage.get("rewards",{})
	var benefits: Array[String] = []
	if int(rewards.get("move_points",0))>0: benefits.append("+%d ficha de técnica" % int(rewards.move_points))
	if int(rewards.get("perk_points",0))>0: benefits.append("+%d elección de talento" % int(rewards.perk_points))
	if int(rewards.get("stat_points",0))>0: benefits.append("+%d puntos de atributo" % int(rewards.stat_points))
	if not benefits.is_empty() and not cleared and not locked: _label(intro,"Primera victoria · "+" · ".join(benefits),14,GOLD)
	var hint := str(profile.get("last_hint",""))
	if not hint.is_empty() and selected_global==global_current and not cleared:
		_last_hint = _label(intro,hint,14,TEAL)
	_route_help = _button("Conocer al rival",false)
	_route_help.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_route_help.custom_minimum_size.x = 200
	_route_help.toggle_mode = true
	_route_help.button_pressed = _route_details
	intro.add_child(_route_help)
	var art := _large_portrait(hero,opponent,224 if stacked else (160 if _short else 350))
	art.name = "EncounterArtwork"
	_route_detail_content = _stack(_body)
	_route_detail_content.visible = _route_details
	var description: Variant = stage.get("profile","")
	if description is String: _label(_route_detail_content,str(description),14,MUTED)
	var notes := _grid(_route_detail_content,1 if _phone else 2)
	_label(notes,"Fortaleza · "+str(stage.get("strength","")),14,TEAL)
	_label(notes,"Punto débil · "+str(stage.get("weakness","")),14,CORAL)
	var ability: Dictionary = opponent.get("ability",{})
	_label(_route_detail_content,str(ability.get("name","Habilidad"))+" · "+str(ability.get("description","")),14,CREAM)
	_build_known_moves(_route_detail_content,opponent)
	_route_help.text = "Ocultar detalles" if _route_details else "Conocer al rival"
	_route_help.toggled.connect(func(enabled: bool):
		_route_details = enabled
		_route_detail_content.visible = enabled
		_route_help.text = "Ocultar detalles" if enabled else "Conocer al rival")
	var path_heading := HBoxContainer.new()
	path_heading.add_theme_constant_override("separation",12)
	_body.add_child(path_heading)
	_route_picker = _chapter_picker(path_heading,chapter,Story.chapters().size())
	_route_picker.item_selected.connect(func(index: int): _select_route_chapter(index+1))
	var current_button := _button("Mi ruta",false)
	current_button.custom_minimum_size.x = 88
	current_button.tooltip_text = "Volver a tu próximo encuentro"
	current_button.pressed.connect(func(): _select_route_chapter(_progression.current_chapter(),true))
	path_heading.add_child(current_button)
	var path := JourneyPath.new()
	path.columns = 4 if _phone else stages.size()
	path.custom_minimum_size.y = ceili(float(stages.size())/path.columns)*96
	path.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(path)
	for index in range(stages.size()):
		var encounter: Dictionary = stages[index]
		var global_index := _global_level(chapter,index)
		var current_here: bool = chapter==_progression.current_chapter() and index==current and not _progression.is_complete()
		var status := "SUPERADO" if global_index <= completed else ("AHORA" if current_here else "POR LLEGAR")
		var kind := str(encounter.get("kind","normal"))
		var button := RouteMarker.new()
		button.accent = GOLD if kind=="boss" else (CORAL if kind=="elite" else TEAL)
		button.selected = index == _selected_stage
		button.completed = global_index <= completed
		button.kind = kind
		button.badge = WorldVisualsScript.illustration("boss_badge" if kind=="boss" else ("elite_badge" if kind=="elite" else "encounter_badge"))
		button.custom_minimum_size.y = 92
		button.tooltip_text = "%02d · %s · %s · Rival nv. %d%s" % [global_index,str(encounter.get("title","Encuentro")),status,int(encounter.get("level",1))," · JEFE" if kind=="boss" else (" · ÉLITE" if kind=="elite" else "")]
		button.pressed.connect(_select_stage.bind(index))
		path.add_child(button)
		var number := _label(button,"%02d" % global_index,15,CREAM,false)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var rival_name := str(Story.opponent(index,chapter).get("name",encounter.get("character_id","")))
		var name_label := _label(button,rival_name,13,CREAM,false)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var detail := _label(button,"Nv. %d%s\n%s" % [int(encounter.get("level",1))," · JEFE" if kind=="boss" else (" · ÉLITE" if kind=="elite" else ""),status],10,TEAL if global_index<=completed or current_here else MUTED,false)
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.resized.connect(func():
			number.position=Vector2(0,10); number.size=Vector2(button.size.x,24)
			name_label.position=Vector2(2,46); name_label.size=Vector2(button.size.x-4,18)
			detail.position=Vector2(0,64); detail.size=Vector2(button.size.x,28))
		_stage_buttons.append(button)
	_campaign_status = _label(_body,"TU CAMPAÑA · %d / %d ENCUENTROS SUPERADOS" % [completed,_total_encounters()],12,GOLD)
	var progress := ProgressBar.new()
	progress.max_value = _total_encounters()
	progress.value = completed
	progress.show_percentage = false
	progress.custom_minimum_size.y = 4
	_body.add_child(progress)


func _select_stage(index: int) -> void:
	_route_details = false
	_selected_stage = index
	_rebuild_body()
	_refresh_actions()


func _select_route_chapter(chapter: int, select_current: bool = false) -> void:
	if chapter < 1 or chapter > Story.chapters().size(): return
	_route_details = false
	_route_chapter = chapter
	_selected_stage = clampi(_progression.current_stage(),0,Story.stages(chapter).size()-1) if select_current or chapter==_progression.current_chapter() else 0
	_active_tab = "route"
	_rebuild_body()
	_refresh_actions()
	_scroll.scroll_vertical = 0


func _global_level(chapter: int, index: int) -> int:
	return mini(int(Story.chapter(chapter).start_level)+index,_total_encounters())


func _total_encounters() -> int:
	return Story.total_encounters()


func _completed_encounters() -> int:
	return _global_level(_progression.current_chapter(),0)-1+int(_progression.current_stage())


func _next_boss_level() -> int:
	var complete := _completed_encounters()
	for chapter: Dictionary in Story.chapters():
		if int(chapter.end_level)>complete: return int(chapter.end_level)
	return _total_encounters()


func _can_replay(global_level: int) -> bool:
	return _progression.has_method("can_replay") and bool(_progression.can_replay(global_level))


func _chapter_picker(parent: Node, selected: int, accessible: int) -> OptionButton:
	var picker := OptionButton.new()
	picker.custom_minimum_size = Vector2(0,48)
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.fit_to_longest_item = false
	picker.clip_text = true
	for chapter: Dictionary in Story.chapters():
		var number := int(chapter.number)
		picker.add_item("Capítulo %d · Encuentros %02d–%02d" % [number,int(chapter.start_level),int(chapter.end_level)],number)
		picker.set_item_disabled(number-1,number>accessible)
	picker.selected = selected-1
	Visuals.apply_option(picker)
	Visuals.apply_button(picker,"navigation")
	picker.add_theme_color_override("font_color",CREAM)
	parent.add_child(picker)
	return picker


func _build_known_moves(parent: Node, opponent: Dictionary) -> void:
	var id := str(opponent.get("character_id",""))
	var available: Array = opponent.get("moves",Moves.unlocked_moves(id,int(opponent.get("level",1))))
	var supplied: Array = opponent.get("unlocked_moves",[])
	if not supplied.is_empty():
		available = available.filter(func(move: Dictionary): return str(move.id) in supplied)
	if available.is_empty(): return
	_label(parent,"TÉCNICAS CONOCIDAS",12,GOLD)
	for move: Dictionary in available:
		_label(parent,str(move.name)+" · "+str(move.get("purpose",move.get("description",""))),14,MUTED)


func _build_upgrades() -> void:
	var profile: Dictionary = _progression.data
	if profile.is_empty(): return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",16)
	_body.add_child(row)
	var points_label := _amount_label(int(profile.points),"punto","puntos")
	if not _phone: points_label += " disponible" if int(profile.points)==1 else " disponibles"
	_label(row,points_label,26,TEAL)
	_respec = _button("Redistribuir" if _phone else "Redistribuir mejoras",false)
	_respec.custom_minimum_size.x = 140 if _phone else 210
	_respec.disabled = not _can_respec()
	_respec.tooltip_text = "Recupera los puntos de atributos, fichas y talentos para elegir de nuevo."
	_respec.pressed.connect(_open_respec_confirmation)
	row.add_child(_respec)
	_label(_body,"Cada mejora cuesta 1 punto y se aplica al instante." if int(profile.points)>0 else "Sin puntos disponibles. Gana experiencia en Historia para subir de nivel.",14,MUTED)
	_upgrade_notice_label = _label(_body,_upgrade_notice,14,TEAL)
	_upgrade_notice_label.visible = not _upgrade_notice.is_empty()
	var values: Dictionary = Story.stats_for(profile)
	var grid := _grid(_body,_columns())
	grid.add_theme_constant_override("h_separation",16)
	grid.add_theme_constant_override("v_separation",16)
	var descriptions := {"max_hp":"Resiste más golpes.","attack":"Golpea con más fuerza.","defense":"Reduce el daño recibido.","speed":"Ataca con más frecuencia.","accuracy":"Conecta más ataques.","evasion":"Esquiva más golpes.","crit_chance":"Consigue más críticos.","resistance":"Resiste efectos negativos."}
	for allocation: Dictionary in Story.allocations():
		var key := str(allocation.key)
		var surface := PanelContainer.new()
		surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		surface.add_theme_stylebox_override("panel",Visuals.training_card())
		grid.add_child(surface)
		var panel := _stack(surface)
		var title_row := HBoxContainer.new()
		panel.add_child(title_row)
		_label(title_row,str(allocation.get("name",key)),20)
		var help := _button("?",false)
		help.custom_minimum_size = Vector2(48,48)
		help.tooltip_text = "Cómo funciona "+str(allocation.get("name",key))
		Visuals.apply_button(help,"icon")
		help.pressed.connect(_toggle_upgrade_help.bind(key))
		title_row.add_child(help)
		_upgrade_help_buttons[key] = help
		var preview: Dictionary = profile.duplicate(true)
		preview.allocations = profile.get("allocations",{}).duplicate()
		preview.allocations[key] = int(preview.allocations.get(key,0))+1
		var after: Dictionary = Story.stats_for(preview)
		var assigned := int(profile.get("allocations",{}).get(key,0))
		var limited := assigned>=int(Story.CONFIG.get("allocation_cap",30)) or float(after.get(key,0))<=float(values.get(key,0))
		_label(panel,_upgrade_value(key,float(values.get(key,0))) + ("" if limited else " → " + _upgrade_value(key,float(after.get(key,0)))),24)
		_label(panel,"Máximo alcanzado" if limited else "Al invertir 1 punto",13,MUTED if limited else TEAL)
		_label(panel,str(descriptions.get(key,"")),14,MUTED)
		var upgrade := _button("Al máximo" if limited else "Mejorar · 1 punto",false)
		upgrade.custom_minimum_size.x = 190
		upgrade.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		upgrade.tooltip_text = "Este atributo llegó a su límite." if limited else "Asignar un punto a "+str(allocation.get("name",key))
		upgrade.disabled = int(profile.points)<=0 or bool(_progression.save_blocked) or limited
		upgrade.pressed.connect(_request_upgrade.bind(key))
		panel.add_child(upgrade)
		_upgrade_buttons[key] = upgrade
		_label(panel,"%d puntos asignados" % assigned,12,MUTED)
		var detail := _label(panel,str(allocation.get("description","")),14,CREAM)
		detail.visible = _upgrade_help_key==key
		_upgrade_help_labels[key] = detail


func _upgrade_value(key: String,value: float) -> String:
	var formatted := _stat_value(key,value)
	var suffix := "%" if formatted.ends_with("%") else ("×" if formatted.ends_with("×") else "")
	var number := formatted.trim_suffix(suffix) if not suffix.is_empty() else formatted
	if "." in number: number = number.rstrip("0").trim_suffix(".")
	return number+suffix


func _toggle_upgrade_help(key: String) -> void:
	_upgrade_help_key = "" if _upgrade_help_key==key else key
	for id: String in _upgrade_help_labels: _upgrade_help_labels[id].visible = id==_upgrade_help_key


func _request_upgrade(key: String) -> void:
	if not _upgrade_buttons.has(key) or _upgrade_buttons[key].disabled: return
	var before := int(_progression.data.get("allocations",{}).get(key,0))
	upgrade_requested.emit(key)
	if int(_progression.data.get("allocations",{}).get(key,0))>before:
		_upgrade_notice = "Mejora aplicada · %s: %s" % [str(Catalog.STAT_HELP[key].name),_upgrade_value(key,float(Story.stats_for(_progression.data)[key]))]
		if is_instance_valid(_upgrade_notice_label):
			_upgrade_notice_label.text = _upgrade_notice
			_upgrade_notice_label.show()
	_restore_upgrade_focus.call_deferred(key)


func _restore_upgrade_focus(key: String) -> void:
	if _active_tab!="upgrades" or not is_inside_tree(): return
	var target: Button = _upgrade_buttons.get(key)
	if is_instance_valid(target):
		if target.disabled: target = _upgrade_help_buttons.get(key)
		if is_instance_valid(target): target.grab_focus()


func _refundable_build() -> Dictionary:
	var refunds := {"stats":0,"moves":0,"perks":0}
	if _progression == null: return refunds
	var profile: Dictionary = _progression.data
	for value: Variant in profile.get("allocations",{}).values(): refunds.stats += maxi(0,int(value))
	for value: Variant in profile.get("move_upgrades",{}).values(): refunds.moves += maxi(0,int(value))
	refunds.perks = profile.get("perks",[]).size()
	return refunds


func _can_respec() -> bool:
	if _progression == null or bool(_progression.save_blocked): return false
	var refunds := _refundable_build()
	return int(refunds.stats)+int(refunds.moves)+int(refunds.perks)>0


func _open_respec_confirmation() -> void:
	if not _can_respec() or is_instance_valid(_confirmation): return
	var refunds := _refundable_build()
	var dialog := GameModalScript.new()
	_confirmation = dialog
	dialog.max_width = 520
	dialog.preferred_height = 320
	add_child(dialog)
	dialog.configure("Redistribuir mejoras")
	_confirmation_card = dialog.parts().panel
	var content: VBoxContainer = dialog.content()
	content.add_theme_constant_override("separation",12)
	_label(content,"Recuperarás %s, %s y %s para elegir de nuevo." % [_amount_label(int(refunds.stats),"punto de atributo","puntos de atributo"),_amount_label(int(refunds.moves),"ficha de técnica","fichas de técnica"),_amount_label(int(refunds.perks),"elección de talento","elecciones de talento")],15)
	_label(content,"Conservas tu nivel, XP, técnicas desbloqueadas, ruta y recuerdos.",14,TEAL)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation",12)
	content.add_child(actions)
	_confirmation_cancel = _button("Cancelar",false)
	_confirmation_cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirmation_cancel.pressed.connect(_close_respec_confirmation)
	actions.add_child(_confirmation_cancel)
	_confirmation_accept = _button("Redistribuir",true)
	_confirmation_accept.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirmation_accept.pressed.connect(_confirm_respec)
	actions.add_child(_confirmation_accept)
	dialog.closed.connect(_release_respec_confirmation)
	dialog.open(_respec)
	# The shell first queues focus on its close control. Keep the safe action
	# initially focused after that, without capturing short-lived UI nodes.
	_focus_respec_cancel.call_deferred()


func _focus_respec_cancel() -> void:
	if is_instance_valid(_confirmation) and _confirmation.is_visible_in_tree() and is_instance_valid(_confirmation_cancel):
		_confirmation_cancel.grab_focus()


func _amount_label(amount: int, singular: String, plural: String) -> String:
	return "%d %s" % [amount,singular if amount==1 else plural]


func _close_respec_confirmation() -> void:
	if is_instance_valid(_confirmation) and _confirmation.visible:
		_confirmation.close()
	else:
		_release_respec_confirmation()


func _release_respec_confirmation() -> void:
	var dialog := _confirmation
	_confirmation = null
	_confirmation_card = null
	_confirmation_accept = null
	_confirmation_cancel = null
	if is_instance_valid(dialog):
		remove_child(dialog)
		dialog.queue_free()


func _confirm_respec() -> void:
	var allowed := is_instance_valid(_confirmation) and _can_respec()
	_close_respec_confirmation()
	if allowed:
		_upgrade_notice = ""
		_moves_notice = ""
		respec_requested.emit()


func _build_moves() -> void:
	var profile: Dictionary = _progression.data
	if profile.is_empty(): return
	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation",12)
	_body.add_child(filters)
	for key: String in ["techniques","perks"]:
		var button := _button("Técnicas" if key=="techniques" else "Talentos",false)
		button.custom_minimum_size.x = 148 if _phone else 190
		button.pressed.connect(_select_moves_section.bind(key))
		filters.add_child(button)
		_moves_filters[key] = button
	_moves_notice_label = _label(_body,_moves_notice,14,TEAL)
	_moves_notice_label.visible = not _moves_notice.is_empty()
	var section := _stack(_body)
	_moves_sections.techniques = section
	var id := str(profile.character_id)
	var definitions: Array = Moves.moves_for(id)
	var unlocked: Array = _unlocked_move_ids(profile)
	_label(section,_amount_label(int(profile.get("move_points",0)),"ficha disponible","fichas disponibles"),24,TEAL)
	_label(section,"El combate usa tus técnicas automáticamente. Gasta fichas para mejorarlas.",14,MUTED)
	var grid := _grid(section,1 if _phone else (2 if size.x<1100 else 3))
	for definition: Dictionary in definitions:
		var move_id := str(definition.id)
		var available := move_id in unlocked
		var tier := int(profile.get("move_upgrades",{}).get(move_id,0))
		var maximum := int(definition.get("max_tier",Moves.MAX_TIER))
		var resolved: Dictionary = Moves.resolve_move(id,move_id,tier,profile.get("perks",[]))
		var card := _moves_card(grid)
		_moves_card_title(card,str(definition.name),move_id)
		_label(card,"Mejora %d / %d" % [tier,maximum] if available else "Se desbloquea en nivel %d" % int(definition.get("unlock_level",1)),12,TEAL if available else GOLD)
		_label(card,str(definition.get("purpose","")),14)
		_label(card,"Riesgo: "+str(definition.get("risk","")),14,MUTED)
		var cost := int(definition.get("cost",1))
		var button := _button("Mejorar · "+_amount_label(cost,"ficha","fichas"),false)
		button.custom_minimum_size.x = 184
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		button.disabled = not available or tier>=maximum or int(profile.get("move_points",0))<cost or bool(_progression.save_blocked)
		if _progression.has_method("can_upgrade_move"): button.disabled = button.disabled or not _progression.can_upgrade_move(move_id)
		if not available: button.text = "Bloqueada"
		elif tier>=maximum: button.text = "Al máximo"
		elif int(profile.get("move_points",0))<cost: button.text = "Sin fichas"
		button.pressed.connect(_request_move_upgrade.bind(move_id))
		card.add_child(button)
		_move_buttons[move_id] = button
		var detail := _stack(card)
		detail.visible = _moves_detail_key==move_id
		_moves_details[move_id] = detail
		var description := str(resolved.get("description",definition.get("description","")))
		if description!=str(definition.get("purpose",""))+" "+str(definition.get("risk","")): _label(detail,description,14,MUTED)
		_label(detail,"Siguiente mejora" if tier<maximum else "Mejora aplicada por grado",14,GOLD)
		_label(detail,str(definition.get("upgrade_description","Mejora controlada de esta técnica.")),14)
	_label(section,"Consigues fichas al superar por primera vez los encuentros %s. Repetirlos no da más fichas." % _milestone_list(Campaign.MOVE_TOKEN_LEVELS),14,MUTED)
	_build_perks()
	_select_moves_section(_moves_section,false)


func _moves_card(parent: Node) -> VBoxContainer:
	var surface := PanelContainer.new()
	surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	surface.add_theme_stylebox_override("panel",Visuals.training_card())
	parent.add_child(surface)
	return _stack(surface)


func _moves_card_title(parent: Node,title: String,key: String) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	_label(row,title,20)
	var help := _button("?",false)
	help.custom_minimum_size = Vector2(48,48)
	Visuals.apply_button(help,"icon")
	help.tooltip_text = "Ver detalles de "+title
	help.pressed.connect(_toggle_moves_detail.bind(key))
	row.add_child(help)
	_moves_help_buttons[key] = help


func _toggle_moves_detail(key: String) -> void:
	_moves_detail_key = "" if _moves_detail_key==key else key
	for id: String in _moves_details: _moves_details[id].visible = id==_moves_detail_key
	if not _moves_detail_key.is_empty(): _reveal_moves_control.call_deferred(_moves_details[key])


func _reveal_moves_control(control: Control) -> void:
	await get_tree().process_frame
	if _active_tab=="moves" and is_instance_valid(control) and control.is_visible_in_tree():
		_scroll.ensure_control_visible(control)


func _select_moves_section(key: String,reset_scroll: bool = true) -> void:
	_moves_section = key
	for id: String in _moves_sections: _moves_sections[id].visible = id==key
	for id: String in _moves_filters:
		Visuals.apply_button(_moves_filters[id],"primary" if id==key else "secondary")
	if reset_scroll:
		_scroll.scroll_vertical = 0
		_moves_notice = ""
		if is_instance_valid(_moves_notice_label): _moves_notice_label.hide()


func _unlocked_move_ids(profile: Dictionary) -> Array:
	if profile.has("unlocked_moves"): return profile.unlocked_moves
	var result: Array = []
	for move: Dictionary in Moves.unlocked_moves(str(profile.get("character_id","nima")),int(profile.get("level",1))): result.append(str(move.id))
	return result


func _request_move_upgrade(move_id: String) -> void:
	if _progression == null or bool(_progression.save_blocked): return
	if not _move_buttons.has(move_id) or _move_buttons[move_id].disabled: return
	var before := int(_progression.data.get("move_upgrades",{}).get(move_id,0))
	upgrade_move_requested.emit(move_id)
	if int(_progression.data.get("move_upgrades",{}).get(move_id,0))>before:
		_set_moves_notice("Técnica mejorada · "+str(Moves.resolve_move(str(_progression.data.character_id),move_id,before+1).get("name",move_id)))
	_restore_moves_focus.call_deferred(move_id,false)


func _build_perks() -> void:
	var profile: Dictionary = _progression.data
	var chosen: Array = profile.get("perks",[])
	var points := int(profile.get("perk_points",0))
	var section := _stack(_body)
	_moves_sections.perks = section
	_label(section,_amount_label(points,"elección disponible","elecciones disponibles"),24,TEAL)
	_label(section,"Elige hasta %d talentos. Sus ventajas se aplican automáticamente." % Campaign.MAX_PERKS,14,MUTED)
	_label(section,"%d / %d talentos activos" % [chosen.size(),Campaign.MAX_PERKS],14,GOLD)
	var available_ids: Array = []
	if _progression.has_method("available_perks"):
		for perk: Dictionary in _progression.available_perks(): available_ids.append(str(perk.id))
	var grid := _grid(section,1 if _phone else (2 if size.x<1100 else 3))
	for perk: Dictionary in Moves.perks_for(str(profile.character_id)):
		var id := str(perk.id)
		var card := _moves_card(grid)
		_moves_card_title(card,str(perk.name),id)
		_label(card,_perk_summary(perk),14)
		var button := _button("Elegir · 1 elección",false)
		button.custom_minimum_size.x = 184
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		button.disabled = points<=0 or id in chosen or chosen.size()>=Campaign.MAX_PERKS or bool(_progression.save_blocked)
		if _progression.has_method("available_perks"): button.disabled = button.disabled or not id in available_ids
		if id in chosen: button.text = "✓ Elegido"
		elif chosen.size()>=Campaign.MAX_PERKS: button.text = "Cupo completo"
		elif points<=0: button.text = "Sin elecciones"
		button.pressed.connect(_request_perk.bind(id))
		card.add_child(button)
		_perk_buttons[id] = button
		var detail := _stack(card)
		_label(detail,str(perk.get("description",perk.get("benefit",""))),14)
		_label(detail,"Ya está activo. No necesitas equiparlo." if id in chosen else "Consume 1 elección. Cada talento se elige una sola vez.",14,MUTED)
		_label(detail,"Para cambiar tus talentos: Mejoras → Redistribuir.",14,MUTED)
		detail.visible = _moves_detail_key==id
		_moves_details[id] = detail
	_label(section,"Ganas elecciones al superar por primera vez los encuentros %s." % _milestone_list(Campaign.PERK_LEVELS),14,MUTED)


func _perk_summary(perk: Dictionary) -> String:
	var modifiers: Dictionary = perk.get("modifiers",{})
	var types: Array = perk.get("types",[])
	var names := {"quick":"golpes rápidos","dash":"desplazamientos","heavy":"golpes pesados","charge":"cargas","jump":"saltos","technique":"técnicas","guard":"guardias","counter":"contraataques"}
	var labels: Array[String] = []
	for type: String in types: labels.append(str(names.get(type,type)))
	var scope := "tus ataques" if labels.is_empty() else "tus "+" y ".join(labels)
	if modifiers.has("damage_multiplier") and modifiers.has("priority") and modifiers.size()==2:
		return "Más fuerza e iniciativa en "+scope+"."
	if modifiers.has("accuracy_modifier") and modifiers.size()==1: return "Más precisión en "+scope+"."
	if modifiers.has("critical_chance_modifier") and modifiers.size()==1: return "Más posibilidades de crítico en "+scope+"."
	if modifiers.has("recovery") and modifiers.has("priority") and modifiers.size()==2:
		return "Más iniciativa y menos recuperación en "+scope+"."
	if modifiers.is_empty() and perk.get("runtime",{}).has("critical_reduction"): return "Recibe menos daño extra de golpes críticos."
	if modifiers.is_empty() and perk.get("runtime",{}).has("evasion"):
		return "Más evasión cuando estás por debajo del %d%% de vida." % roundi(float(perk.get("below_hp",1.0))*100)
	return str(perk.get("benefit",perk.get("description","")))


func _request_perk(perk_id: String) -> void:
	if _progression == null or bool(_progression.save_blocked): return
	if not _perk_buttons.has(perk_id) or _perk_buttons[perk_id].disabled: return
	var before: int = _progression.data.get("perks",[]).size()
	perk_chosen.emit(perk_id)
	if _progression.data.get("perks",[]).size()>before:
		for perk: Dictionary in Moves.perks_for(str(_progression.data.character_id)):
			if str(perk.id)==perk_id: _set_moves_notice("Talento activo · "+str(perk.name))
	_restore_moves_focus.call_deferred(perk_id,true)


func _set_moves_notice(value: String) -> void:
	_moves_notice = value
	if is_instance_valid(_moves_notice_label):
		_moves_notice_label.text = value
		_moves_notice_label.show()


func _restore_moves_focus(key: String,perk: bool) -> void:
	if _active_tab!="moves" or not is_inside_tree(): return
	var target: Button = _perk_buttons.get(key) if perk else _move_buttons.get(key)
	if is_instance_valid(target):
		if target.disabled: target = _moves_help_buttons.get(key)
		if is_instance_valid(target):
			target.grab_focus()
			_reveal_moves_control.call_deferred(target)


func _milestone_list(values: Array[int]) -> String:
	var labels: Array[String] = []
	for value: int in values: labels.append(str(value))
	return ", ".join(labels)


func _companion_has_progress(profile: Dictionary) -> bool:
	return int(profile.get("matches",0))>0 or int(profile.get("current_stage",0))>0 or int(profile.get("chapter",1))>1 or int(profile.get("total_xp",0))>0 or bool(profile.get("completed",false))


func _companion_cleared(profile: Dictionary) -> int:
	if profile.is_empty(): return 0
	var chapter: Dictionary = Story.chapter(int(profile.get("chapter",1)))
	return int(chapter.end_level) if bool(profile.get("completed",false)) else int(chapter.start_level)-1+int(profile.get("current_stage",0))


func _companion_status(profile: Dictionary) -> String:
	if not _companion_has_progress(profile): return "Historia sin empezar"
	if _companion_cleared(profile)>=100: return "Historia completada"
	if bool(profile.get("completed",false)): return "Capítulo %d completado" % int(profile.get("chapter",1))
	return "Capítulo %d · Encuentro %d" % [int(profile.get("chapter",1)),_companion_cleared(profile)+1]


func _build_companions() -> void:
	var selected: Dictionary = _identity_definition(_selected_id)
	if not selected.is_empty():
		var profile: Dictionary = _progression.roster.get(_selected_id,{})
		var welcome := GridContainer.new()
		welcome.columns = 1 if _phone else 2
		welcome.add_theme_constant_override("h_separation",24)
		welcome.add_theme_constant_override("v_separation",12)
		welcome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_body.add_child(welcome)
		var portrait := _companion_portrait(welcome,selected,180 if _short else (300 if _phone else 390))
		portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var detail := _moves_card(welcome)
		_label(detail,"EN USO" if _selected_id==str(_progression.data.get("character_id","")) else "VISTA PREVIA",12,TEAL)
		_label(detail,str(selected.name),28)
		_label(detail,str(selected.role),16,GOLD)
		_label(detail,"Nivel %d" % int(profile.get("level",1)),14)
		_companion_progress_label = _label(detail,_companion_status(profile),16,TEAL)
		var cleared := _companion_cleared(profile)
		var bar := ProgressBar.new()
		bar.custom_minimum_size.y = 8
		bar.show_percentage = false
		bar.max_value = 100
		bar.value = cleared
		Visuals.apply_progress(bar,"xp")
		detail.add_child(bar)
		_label(detail,"%d / 100 encuentros superados" % cleared,12,MUTED)
		var level := int(profile.get("level",1))
		_companion_xp_label = _label(detail,"Nivel máximo" if level>=Balance.MAX_LEVEL else "%d / %d XP para el siguiente nivel" % [int(profile.get("xp",0)),Balance.xp_for_level(level)],12,MUTED)
		_companion_help = _button("Conocer al compañero",false)
		_companion_help.custom_minimum_size.x = 224
		_companion_help.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_companion_help.pressed.connect(_toggle_companion_details)
		detail.add_child(_companion_help)
		_companion_details = _stack(detail)
		_companion_details.visible = _companion_details_open
		_companion_help.text = "Ocultar detalles" if _companion_details_open else "Conocer al compañero"
		_label(_companion_details,"Fortaleza · "+str(selected.get("strengths","")),14,TEAL)
		_label(_companion_details,"Punto débil · "+str(selected.get("weaknesses","")),14,CORAL)
		_label(_companion_details,str(selected.ability.name)+" · "+str(selected.ability.description),14)
		var biography := str(selected.get("biography",selected.get("personality","")))
		if not biography.is_empty(): _label(_companion_details,biography,14,MUTED)
		if identity_store != null:
			_companion_custom = _button("Personalizar",false)
			_companion_custom.custom_minimum_size.x = 180
			_companion_custom.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			_companion_custom.pressed.connect(func(): customize_requested.emit(_selected_id))
			detail.add_child(_companion_custom)
	_label(_body,"Elige un compañero",20)
	var grid := _grid(_body,2 if size.x<1100 else 3)
	for base: Dictionary in Catalog.all_definitions():
		var definition: Dictionary = _identity_definition(str(base.id))
		var id := str(definition.id)
		var profile: Dictionary = _progression.roster.get(id,{})
		var is_selected := id==_selected_id
		var button := _button("",false)
		button.custom_minimum_size.y = 278 if _phone else 302
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = str(definition.name)+" · "+str(definition.role)+" · "+_companion_status(profile)
		button.pressed.connect(_select_character.bind(id))
		Visuals.apply_card_button(button,is_selected)
		grid.add_child(button)
		var inside := _button_content(button,12)
		button.set_meta("companion_content",inside)
		var preview := _companion_portrait(inside,definition,168 if _phone else 220)
		_companion_previews.append(preview)
		preview.resized.connect(_fit_companion_previews.call_deferred)
		_label(inside,("✓ " if is_selected else "")+str(definition.name),18,CREAM)
		_label(inside,"Nivel %d" % int(profile.get("level",1)),12,MUTED)
		_label(inside,_companion_status(profile),12,TEAL if _companion_has_progress(profile) else MUTED)
		_character_buttons.append(button)
	_fit_companion_previews.call_deferred()


func _companion_portrait(parent: Node,definition: Dictionary,height: float) -> Control:
	var preview := CompanionPreview.new()
	preview.custom_minimum_size = Vector2(0,height)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(preview)
	preview.configure({},definition)
	preview.set_motion(false,bool(get_tree().get_meta("brasa_reduced_motion",false)))
	_portraits.append(preview.actor())
	return preview


func _fit_companion_previews() -> void:
	var card_height := 278.0 if _phone else 302.0
	for button: Button in _character_buttons:
		if button.has_meta("companion_content"):
			card_height = maxf(card_height,button.get_meta("companion_content").get_combined_minimum_size().y+24)
	for button: Button in _character_buttons: button.custom_minimum_size.y = card_height
	var common := INF
	for preview: Control in _companion_previews:
		if not is_instance_valid(preview): continue
		preview.max_scale = INF
		preview.fit()
		common = minf(common,preview.actor().scale.x)
	for preview: Control in _companion_previews:
		if is_instance_valid(preview):
			preview.max_scale = common
			preview.fit()


func _toggle_companion_details() -> void:
	_companion_details_open = not _companion_details_open
	_companion_details.visible = _companion_details_open
	_companion_help.text = "Ocultar detalles" if _companion_details_open else "Conocer al compañero"


func _select_character(id: String) -> void:
	_selected_id = id
	_companion_details_open = false
	_rebuild_body()
	_refresh_actions()
	_reveal_companion.call_deferred()


func _reveal_companion() -> void:
	await get_tree().process_frame
	if _active_tab!="companions" or not is_instance_valid(_companion_help): return
	_companion_help.grab_focus()
	_scroll.scroll_vertical = 0


func _achievement_profile() -> Dictionary:
	if _achievement_character == str(_progression.data.get("character_id","")): return _progression.data
	return _progression.roster.get(_achievement_character,{})


func _build_legacy() -> void:
	if _achievement_character.is_empty(): _achievement_character = str(_progression.data.get("character_id",Catalog.IDS[0]))
	var profile := _achievement_profile()
	var records: Dictionary = {}
	if _achievement_character == str(_progression.data.get("character_id","")):
		for number: int in range(1,_progression.current_chapter()+1):
			var summary: Dictionary = _progression.completion_summary(number)
			if bool(summary.get("completed",false)): records[str(number)] = summary
	_achievement_snapshot = Achievements.snapshot(profile,records)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation",20)
	_body.add_child(top)
	if not _phone and not _short:
		_portrait(top,_identity_definition(_achievement_character),0.55,true)
	var summary_box: BoxContainer
	if _short:
		summary_box = HBoxContainer.new()
		summary_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		summary_box.add_theme_constant_override("separation",24)
		top.add_child(summary_box)
	else: summary_box = _stack(top)
	_achievement_picker = OptionButton.new()
	_achievement_picker.custom_minimum_size = Vector2(0,48)
	_achievement_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_achievement_picker.fit_to_longest_item = false
	Visuals.apply_option(_achievement_picker)
	for id: String in Catalog.IDS:
		_achievement_picker.add_item(str(Catalog.definition(id).name)+( " · Sin campaña" if not _progression.roster.has(id) else ""))
	_achievement_picker.select(Catalog.IDS.find(_achievement_character))
	_achievement_picker.tooltip_text = "Consultar otro personaje no cambia tu campaña activa."
	_achievement_picker.item_selected.connect(func(index: int):
		_achievement_character = str(Catalog.IDS[index])
		_achievement_record = false
		_rebuild_body()
		_refresh_actions()
		_achievement_picker.grab_focus())
	summary_box.add_child(_achievement_picker)
	var metrics := _grid(summary_box,3)
	if _short: metrics.size_flags_stretch_ratio = 1.5
	for entry: Array in [["Logros", "%d / %d" % [_achievement_snapshot.earned,_achievement_snapshot.total]],["Encuentros","%d / 100" % _achievement_snapshot.cleared],["Capítulos","%d / %d" % [_achievement_snapshot.chapters,Story.chapters().size()]]]:
		var box := _stack(metrics)
		_label(box,str(entry[1]),22,TEAL)
		_label(box,str(entry[0]),12,MUTED)
	if _achievement_record:
		_build_achievement_record()
		return
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation",8)
	_body.add_child(tabs)
	_achievement_filters.clear()
	for entry: Array in [["pending","Por conseguir"],["earned","Conseguidos"],["collection","Colección"]]:
		var button := _button(str(entry[1]),false)
		button.add_theme_font_size_override("font_size",13 if _phone else 15)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Visuals.apply_button(button,"navigation_active" if _achievement_filter==str(entry[0]) else "navigation")
		button.pressed.connect(_select_achievement_filter.bind(str(entry[0])))
		tabs.add_child(button)
		_achievement_filters[str(entry[0])] = button
	if _achievement_filter=="collection":
		_build_achievement_collection(profile)
		return
	if _achievement_filter=="pending":
		var next := _stack(_body)
		if profile.is_empty():
			_label(next,"Tu primera meta",22,GOLD)
			_label(next,"Empieza su Historia y gana el primer encuentro.",15)
		elif _achievement_character == str(_progression.data.get("character_id","")) and _progression.can_start_next_chapter():
			_label(next,"CAPÍTULO %d DESBLOQUEADO" % (_progression.current_chapter()+1),12,TEAL)
			_label(next,"Siguiente paso · "+str(Story.chapter(_progression.current_chapter()+1).title),22,GOLD)
			_label(next,"Usa el botón inferior para continuar tu Historia.",14,MUTED)
		elif _achievement_snapshot.cleared < Story.total_encounters():
			_label(next,"Tu siguiente paso",22,GOLD)
			_label(next,"Supera el encuentro %d para avanzar hacia tu próxima insignia." % (_achievement_snapshot.cleared+1),15)
		else:
			_label(next,"Historia completada",22,GOLD)
			_label(next,"Consulta tus insignias o empieza la Historia de otro compañero.",15)
	var items: Array[Dictionary] = []
	for item: Dictionary in _achievement_snapshot.entries:
		if bool(item.done)==(_achievement_filter=="earned"): items.append(item)
	if _achievement_filter=="pending":
		items.sort_custom(func(a: Dictionary,b: Dictionary):
			var next_chapter := int(_achievement_snapshot.chapters)+1
			if int(a.chapter)==next_chapter and int(b.chapter)!=next_chapter: return true
			if int(b.chapter)==next_chapter and int(a.chapter)!=next_chapter: return false
			return float(a.current)/a.target > float(b.current)/b.target)
	if items.is_empty():
		_label(_body,"Aún no hay logros conseguidos. Tu primera victoria abre el camino." if _achievement_filter=="earned" else "Has conseguido todos los logros de este personaje.",18,TEAL)
	else:
		var grid := _grid(_body,1 if _phone else (2 if size.x<1500 else 3))
		for i: int in range(items.size() if _achievement_all else mini(6,items.size())):
			_build_achievement_card(grid,items[i])
		if items.size()>6:
			var more := _button("Mostrar menos" if _achievement_all else "Ver los %d logros" % items.size(),false)
			more.name = "MoreAchievements"
			more.pressed.connect(func():
				_achievement_all = not _achievement_all
				_rebuild_body()
				var control := _body.find_child("MoreAchievements",true,false)
				if control != null: control.grab_focus())
			_body.add_child(more)
	_label(_body,"Los logros se registran automáticamente. No necesitas reclamarlos.",13,MUTED)


func _select_achievement_filter(id: String) -> void:
	_achievement_filter = id
	_achievement_all = false
	_rebuild_body()
	_refresh_actions()
	_achievement_filters[id].grab_focus()
	_scroll.scroll_vertical = 0


func _build_achievement_card(parent: Node,item: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel",Visuals.training_card("selected" if item.done else "normal"))
	parent.add_child(panel)
	var box := _stack(panel)
	_label(box,"✓ CONSEGUIDO" if item.done else "POR CONSEGUIR",12,TEAL if item.done else MUTED)
	_label(box,str(item.title),20)
	_label(box,str(item.description),14,MUTED)
	if not item.done:
		var bar := ProgressBar.new()
		bar.custom_minimum_size.y = 6
		bar.show_percentage = false
		bar.max_value = item.target
		bar.value = item.current
		box.add_child(bar)
		_label(box,"%d / %d %s" % [item.current,item.target,item.unit],13,TEAL)
		if int(item.current)>=int(item.target) and int(item.chapter)>0:
			_label(box,"Falta el cierre de este capítulo en tu historial.",13,MUTED)
	_label(box,str(item.reward)+( " · sin premio extra" if int(item.chapter)==0 else ""),13,GOLD)
	if item.done and int(item.chapter)>0:
		var view := _button("Ver recuerdo",false)
		view.pressed.connect(_select_legacy.bind(int(item.chapter)))
		box.add_child(view)
		_chapter_buttons.append(view)


func _build_achievement_collection(profile: Dictionary) -> void:
	_label(_body,"Técnicas de este personaje",22,GOLD)
	if profile.is_empty():
		_label(_body,"Comienza su Historia para aprender sus primeras técnicas.",14,MUTED)
	else:
		var names: Array[String] = []
		for move: Dictionary in Moves.unlocked_moves(_achievement_character,int(profile.get("level",1))): names.append(str(move.name))
		_label(_body," · ".join(names),15)
	_label(_body,"Tu colección compartida",22,GOLD)
	_label(_body,"Colores, apariencias y efectos que ya ganaste. Puedes usarlos en Personalizar con cualquier compañero compatible.",14,MUTED)
	if identity_store == null:
		_label(_body,"La colección no está disponible en esta vista.",14,MUTED)
		return
	var owned: Array[String] = identity_store.owned_ids()
	var grid := _grid(_body,1 if _phone else 3)
	var count := 0
	for slot: Dictionary in Cosmetics.SLOTS:
		for item: Dictionary in Cosmetics.items(str(slot.id)):
			if bool(item.default) or not str(item.inventory_id) in owned: continue
			count += 1
			var box := _card(grid)
			_label(box,str(slot.name),12,MUTED)
			_label(box,str(item.name),20,TEAL)
			_label(box,"✓ Disponible",13,MUTED)
			_label(box,str(item.requirement),13,MUTED)
	if count==0: _label(_body,"Aún no has ganado cosméticos adicionales. Personalizar muestra las opciones iniciales y cómo desbloquear las demás.",15,MUTED)
	var customize := _button("Ver en Personalizar",false)
	customize.pressed.connect(func(): customize_requested.emit(_achievement_character))
	_body.add_child(customize)


func _build_achievement_record() -> void:
	var back := _button("← Volver a logros",false)
	back.pressed.connect(func():
		_achievement_record = false
		_achievement_filter = "earned"
		_rebuild_body()
		_refresh_actions()
		_achievement_filters.earned.grab_focus())
	_body.add_child(back)
	var summary: Dictionary = _achievement_snapshot.records.get(str(_legacy_chapter),{})
	if summary.is_empty():
		_label(_body,"Completa este capítulo para conservar su recuerdo.",18,MUTED)
		return
	_label(_body,"CAPÍTULO %d COMPLETADO · %d / %d ENCUENTROS" % [_legacy_chapter,Story.stages(_legacy_chapter).size(),Story.stages(_legacy_chapter).size()],12,TEAL)
	_label(_body,str(Story.chapter(_legacy_chapter).title),26)
	_label(_body,"Insignia · "+str(summary.get("badge",Story.chapter(_legacy_chapter).badge)),20,GOLD)
	_label(_body,"Así terminó este capítulo. Este recuerdo conserva tus resultados de entonces.",14,MUTED)
	var metrics := _grid(_body,2 if _phone else 4)
	for entry: Array in [["Nivel",summary.get("level",1)],["Victorias",summary.get("wins",0)],["Combates",summary.get("battles",0)],["Reintentos",summary.get("retries",0)]]:
		var cell := _stack(metrics)
		_label(cell,str(entry[1]),24,TEAL)
		_label(cell,str(entry[0]),13,MUTED)
	var details := _button("Ver atributos y decisiones",false)
	details.toggle_mode = true
	_body.add_child(details)
	var expanded := _stack(_body)
	expanded.hide()
	details.toggled.connect(func(enabled: bool): expanded.visible = enabled)
	var stats: Dictionary = summary.get("stats",{})
	var values := _grid(expanded,2 if _phone else 3)
	for key: String in Balance.STAT_KEYS:
		if stats.has(key): _label(values,str(Catalog.STAT_HELP[key].name)+" · "+_stat_value(key,float(stats[key])),15)
	for allocation: Dictionary in Story.allocations():
		var count := int(summary.get("allocations",{}).get(str(allocation.key),0))
		if count>0: _label(expanded,"%s · %d puntos asignados" % [allocation.name,count],14,MUTED)


func _select_legacy(chapter: int) -> void:
	if not _achievement_snapshot.get("records",{}).has(str(chapter)): return
	_achievement_record = true
	_legacy_chapter = chapter
	_rebuild_body()
	_refresh_actions()
	_scroll.scroll_vertical = 0


func _chapter_title(chapter: int) -> String:
	return "Capítulo %d · %s" % [chapter,str(Story.chapter(chapter).title)]


func _portrait(parent: Node, definition: Dictionary, factor: float, victory: bool) -> Control:
	var holder := Control.new()
	var presentation := "victory" if victory else "rest"
	var envelope := Fighter.VisualProfiles.portrait_envelope(presentation)
	holder.custom_minimum_size = envelope.size*factor if victory else Vector2(166,172)*factor
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(holder)
	var actor := Fighter.new()
	actor.setup_character(definition,1)
	holder.add_child(actor)
	var fit := func():
		var camera := Fighter.VisualProfiles.portrait_scale(holder.size,presentation)
		actor.scale = Vector2.ONE*camera
		actor.position = Vector2(holder.size.x*0.5,holder.size.y-6-envelope.end.y*camera)
	holder.resized.connect(fit)
	fit.call()
	if victory: actor.preview_victory()
	_portraits.append(actor)
	return holder


func _large_portrait(parent: Node, definition: Dictionary, height: float) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0,height)
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(holder)
	var actor := Fighter.new()
	actor.setup_character(definition,1)
	holder.add_child(actor)
	var fit := func():
		var visible_height: float = minf(holder.size.y,height)
		var factor: float = Fighter.VisualProfiles.portrait_scale(Vector2(holder.size.x,visible_height))
		actor.scale = Vector2.ONE*factor
		actor.position = Vector2(holder.size.x*0.5,visible_height-6-Fighter.VisualProfiles.REST_ENVELOPE.end.y*factor)
	holder.resized.connect(fit)
	fit.call()
	_portraits.append(actor)
	return holder


func _grid(parent: Node, columns: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(grid)
	_content_grids.append(grid)
	return grid


func _divider(parent: Node) -> void:
	var line := HSeparator.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.modulate = Color(0.65,0.64,0.48,0.38)
	parent.add_child(line)


func _card(parent: Node) -> VBoxContainer:
	var panel := PanelContainer.new()
	Visuals.apply_panel(panel,"reward" if _active_tab=="legacy" else "standard")
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	return _stack(panel)


func _stack(parent: Node) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",8)
	parent.add_child(box)
	return box


func _button_content(button: Button, padding: int) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for edge: String in ["left","top","right","bottom"]: margin.add_theme_constant_override("margin_"+edge,padding)
	button.add_child(margin)
	var box := _stack(margin)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return box


func _label(parent: Node, value: String, font_size: int = 15, color: Color = CREAM, wrap: bool = true) -> Label:
	var label := Label.new()
	label.text = value
	Visuals.apply_label(label,"title" if font_size>=20 else "body")
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING if wrap else TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = not wrap
	parent.add_child(label)
	return label


func _button(value: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = value
	button.clip_text = true
	button.custom_minimum_size = Vector2(0,48)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	Visuals.apply_button(button,"primary" if primary else "secondary")
	return button


func _stat_value(key: String, value: float) -> String:
	match str(Catalog.STAT_HELP.get(key,{}).get("format","decimal")):
		"integer": return "%.0f" % value
		"percent": return "%.1f%%" % (value*100)
		"multiplier": return "%.2f×" % value
	return "%.2f" % value


func _input(event: InputEvent) -> void:
	# A child modal or an OptionButton popup owns its own keyboard scope.
	if is_instance_valid(_confirmation): return
	OverlayFocus.handle(event,self,func(): closed.emit())


func _unhandled_key_input(event: InputEvent) -> void:
	_input(event)
