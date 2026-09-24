extends Control
class_name OnlinePanel
signal closed
const ApiScript = preload("res://scripts/online_api.gd")
const Fighter = preload("res://scripts/fighter_view.gd")
const Characters = preload("res://scripts/character_catalog.gd")
const Replay = preload("res://scripts/ui/battle_replay_panel.gd")
const Records = preload("res://scripts/battle_identity.gd")
const Customizer = preload("res://scripts/ui/customization_panel.gd")
const Visuals = preload("res://scripts/ui/game_visual_system.gd")
const FighterPreview = preload("res://scripts/ui/components/game_fighter_preview.gd")
const SectionHeader = preload("res://scripts/ui/components/game_section_header.gd")
const AccountModal = preload("res://scripts/ui/components/game_modal.gd")
const Badge = preload("res://scripts/ui/components/game_badge.gd")
class RemoteIdentity extends RefCounted:
	var fighter: Dictionary = {}
	var inventory: Array[String] = []
	func entry(_archetype_id: String) -> Dictionary: return fighter.duplicate(true)
	func owned_ids() -> Array[String]: return inventory.duplicate()
const CREAM = Visuals.CREAM
const MUTED := Visuals.MUTED
const GOLD = Visuals.GOLD
const TEAL = Visuals.TEAL
const SURFACE = Visuals.SURFACE
var api: Node
var _catalog: Dictionary = {}
var _fighters: Array = []
var _fighter: Dictionary = {}
var _opponents: Array = []
var _history: Array = []
var _history_cursor: String = ""
var _offline: Dictionary = {}
var _story: Dictionary = {}
var _tab: int = 0
var _profile_section := 0
var _busy: bool = false
var _built: bool = false
var _loading_account: bool = false
var _view_generation: int = 0
var _creating: bool = false
var _last_result: Dictionary = {}
var _replay: Control
var _customizer: Control
var _last_mutation_ok: bool = false
var _retry_at_ms: int = 0
var _title: Label
var _subtitle: Label
var _close: Button
var _toolbar: HBoxContainer
var _picker: OptionButton
var _new: Button
var _logout: Button
var _preview: Panel
var _actor: Node2D
var _name: Label
var _stats: Label
var _body: Control
var _tabs: HBoxContainer
var _tab_buttons: Array[Button] = []
var _scroll: ScrollContainer
var _content: VBoxContainer
var _notice: Label
var _retry: Button
var _login: VBoxContainer
var _login_button: Button
var _auth_code: Label
var _auth_cancel: Button
var _login_copy: Label
var _create_name: LineEdit
var _create_base: OptionButton
var _buttons: Array[Button] = []
var _environment: Control
var _eyebrow: Label
var _personalize: Button
var _self_portrait: Control
var _selected_opponent_id := ""
var _layout_shape := ""
var _rendering := false
var _compact := false
var _short := false
var _login_title: Label
var _auth_portrait: Control
var _auth_help: Button
var _account_modal: Control
var _resume_retry := false

func configure(service: Node) -> void:
	api = service
	_build()
	Visuals.reveal(self)
	_enter_online()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	resized.connect(_layout)
	_layout()

func _build() -> void:
	if _built: return
	_built = true
	theme = Visuals.theme()
	_environment = Visuals.mount_background(self,"online")
	Visuals.reading_veil(self)
	_eyebrow = _label(self,"BRASA / ARENA ONLINE",12,GOLD)
	_title = _label(self,"Arena online",29,CREAM)
	_subtitle = _label(self,"Combate automático contra otros jugadores.",14,MUTED)
	_close = _button("×",_close_panel)
	_close.tooltip_text = "Cerrar Arena online · Esc"
	Visuals.apply_button(_close,"icon")
	_close.add_theme_font_size_override("font_size",24)
	add_child(_close)
	_toolbar = HBoxContainer.new()
	_toolbar.add_theme_constant_override("separation",8)
	add_child(_toolbar)
	_picker = OptionButton.new()
	_picker.name = "OnlineFighter"
	_picker.fit_to_longest_item = false
	_picker.clip_text = true
	_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_picker.custom_minimum_size.y = 48
	Visuals.apply_option(_picker)
	_picker.item_selected.connect(_select_fighter)
	_toolbar.add_child(_picker)
	_new = _button("Crear",_show_create)
	_new.custom_minimum_size.x = 64
	Visuals.apply_button(_new,"navigation")
	_toolbar.add_child(_new)
	_logout = _button("Cuenta",_open_account)
	_logout.custom_minimum_size.x = 64
	Visuals.apply_button(_logout,"navigation")
	_logout.tooltip_text = "Cuenta y seguridad"
	_toolbar.add_child(_logout)
	# Keep the public preview handle as a compact identity strip. Its actor moves
	# into the relevant scroll content instead of occupying a permanent card.
	_preview = Panel.new()
	_preview.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	add_child(_preview)
	_self_portrait = FighterPreview.new()
	_self_portrait.name = "YourFighter"
	_preview.add_child(_self_portrait)
	_self_portrait.configure({},Characters.definition("nima"))
	_actor = _self_portrait.actor()
	_self_portrait.hide()
	_name = _label(_preview,"",21,CREAM)
	_name.hide()
	_stats = _label(_preview,"",14,MUTED,true)
	_personalize = _button("Personalizar",_open_customization)
	_personalize.tooltip_text = "Cambiar nombre y apariencia de este luchador"
	_preview.add_child(_personalize)
	_body = Control.new()
	add_child(_body)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation",8)
	_body.add_child(_tabs)
	for index in range(4):
		var button := _button(["Arena","Historia","Mi ficha","Actividad"][index],_select_tab.bind(index))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Visuals.apply_button(button,"navigation")
		_tabs.add_child(button)
		_tab_buttons.append(button)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	_scroll.scroll_deadzone = 12
	_body.add_child(_scroll)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation",16)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_content)
	_notice = _label(self,"",14,GOLD,true)
	_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_retry = _button("Reintentar",_retry_pending)
	add_child(_retry)
	_retry.hide()
	_login = VBoxContainer.new()
	_login.add_theme_constant_override("separation",16)
	add_child(_login)
	_auth_portrait = FighterPreview.new()
	add_child(_auth_portrait)
	_auth_portrait.configure({},Characters.definition("nima"))
	_auth_portrait.set_motion(true,true)
	_login_title = _label(_login,"Entra al mundo",36,CREAM,true)
	_login_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_login_copy = _label(_login,"",16,MUTED,true)
	_login_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_login_button = _button("Continuar",_begin_login,true)
	_login.add_child(_login_button)
	_auth_code = _label(_login,"",20,GOLD,true)
	_auth_code.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_auth_cancel = _button("Cancelar",_cancel_login)
	_login.add_child(_auth_cancel)
	_auth_help = _button("No puedo entrar",_open_recovery)
	Visuals.apply_button(_auth_help,"navigation")
	_login.add_child(_auth_help)

func _layout() -> void:
	if not _built or size.x < 1: return
	_short = size.y < 540
	_compact = size.x < 600
	var margin: float = 16 if _compact or _short else 32
	var width: float = size.x-margin*2
	var header_h: float = 40 if _compact or _short else 64
	_eyebrow.visible = false
	_subtitle.visible = not _short and not _compact
	_place(_eyebrow,Rect2(margin,margin,width-60,18))
	_place(_title,Rect2(margin,margin,width-60,36))
	_title.add_theme_font_size_override("font_size",22 if _compact or _short else 29)
	_place(_subtitle,Rect2(margin,margin+38,width-60,22))
	_place(_close,Rect2(size.x-margin-48,margin,48,48))
	var top: float = margin+header_h+8
	_place(_toolbar,Rect2(margin,top,width,48))
	top += 56
	_place(_preview,Rect2(margin,top,width,52))
	_place(_stats,Rect2(0,0,width-140,50))
	_place(_name,Rect2(0,0,width-140,28))
	_place(_personalize,Rect2(width-132,0,132,48))
	top += 60
	# Status is a measured part of the shell, not an overlay on the last row.
	var notice_width: float = maxf(40,width-(120 if _retry.visible else 0))
	_notice.visible = not _notice.text.is_empty()
	_notice.size.x = notice_width
	var notice_h: float = maxf(48 if _retry.visible else 0,_notice.get_minimum_size().y) if _retry.visible or not _notice.text.is_empty() else 0
	notice_h = minf(notice_h,132 if not _short else 80)
	var bottom: float = size.y-margin-notice_h-(8 if notice_h>0 else 0)
	_place(_notice,Rect2(margin,size.y-margin-maxf(20,notice_h),notice_width,maxf(20,notice_h)))
	_place(_retry,Rect2(size.x-margin-112,size.y-margin-maxf(notice_h,48),112,48))
	_place(_body,Rect2(margin,top,width,maxf(52,bottom-top)))
	_tabs.visible = not _creating
	_place(_tabs,Rect2(0,0,width,48))
	var tabs_height: float = 0 if _creating else 60
	_place(_scroll,Rect2(0,tabs_height,width,maxf(0,_body.size.y-tabs_height)))
	for button: Button in _tab_buttons:
		button.add_theme_font_size_override("font_size",13 if _compact or _short else 15)
	var auth_view := _login.visible
	_title.visible = not auth_view
	_eyebrow.visible = false
	_subtitle.visible = not auth_view and not _short and not _compact
	_auth_portrait.visible = auth_view and not (_short and _compact)
	var login_w: float = minf(width,400) if _compact else minf(width*0.45,420)
	_login.add_theme_constant_override("separation",8 if _short else 12)
	_login_title.add_theme_font_size_override("font_size",28 if _short else 36)
	_login.size.x = login_w
	var login_h: float = _login.get_combined_minimum_size().y
	var login_x: float = (size.x-login_w)*0.5 if _compact else margin+width*0.06
	var login_top: float = maxf(margin+48,bottom-login_h-16) if _compact else maxf(margin+48,(bottom-login_h)*0.5)
	if _short: login_top = maxf(margin+40,(bottom-login_h)*0.5)
	_place(_login,Rect2(login_x,login_top,login_w,login_h))
	if _compact:
		_place(_auth_portrait,Rect2(margin,64,width,maxf(0,login_top-80)))
	else:
		_place(_auth_portrait,Rect2(size.x*0.54,margin+40,width*0.42,maxf(0,bottom-margin-56)))
	if is_instance_valid(_replay): _replay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shape := "%s:%s" % [_compact,_short]
	if shape != _layout_shape:
		_layout_shape = shape
		if not _rendering and not _fighter.is_empty() and not _creating and _body.visible: _render_tab()

func _enter_online() -> void:
	if api.is_authenticated():
		await _load_account()
		return
	_show_login()
	if api.has_method("restore_session"):
		_login_title.text = "Entrando…"
		_login_copy.text = ""
		_set_busy(true)
		var stamp := _view_generation
		var restored: Dictionary = await api.restore_session()
		if not _current(stamp): return
		_set_busy(false)
		if restored.ok:
			_resume_retry = false
			await _load_account()
			return
		_show_login()
		_resume_retry = str(restored.get("error",{}).get("code","")) not in ["NO_SESSION","CANCELLED"]
		if _resume_retry:
			_set_notice(_friendly_error(restored))
			_login_button.text = "Reintentar"

func _show_login() -> void:
	_toolbar.hide()
	_preview.hide()
	_body.hide()
	_login.show()
	var remembered: Dictionary = api.returning_fighter() if api != null and api.has_method("returning_fighter") else {}
	_login_title.text = "Bienvenido de nuevo" if not remembered.is_empty() else "Entra al mundo"
	_login_copy.text = "%s · Nivel %d
Tu último luchador" % [_fighter_name(remembered),int(remembered.get("progression",{}).get("level",1))] if not remembered.is_empty() else "Abre el navegador para entrar y guardar tu progreso online."
	var kind: String = str(remembered.get("archetype_id","nima"))
	if not kind in Characters.IDS: kind = "nima"
	_auth_portrait.configure(remembered,Characters.definition(kind))
	_auth_portrait.set_motion(true,true)
	_auth_cancel.visible = api != null and not api.device.is_empty()
	_auth_code.text = ""
	_auth_code.hide()
	_auth_help.visible = not _auth_cancel.visible
	_login_button.disabled = false
	_login_button.text = "Entrar con el navegador"
	_environment.set_context(Visuals.section_context("home"),{})
	_layout()

func _show_account() -> void:
	_login.hide()
	_toolbar.show()
	_preview.show()
	_body.show()
	_layout()

func _begin_login() -> void:
	if _busy: return
	if _resume_retry:
		await _enter_online()
		return
	if not api.device.is_empty():
		var existing_url: String = api.verification_url()
		if api.trusted_browser_url(existing_url): OS.shell_open(existing_url)
		return
	_set_busy(true)
	_set_notice("Entrando…")
	var response: Dictionary = await api.authorize_device()
	_set_busy(false)
	if not response.ok:
		_report(response)
		return
	_auth_code.text = str(api.device.user_code)
	_login_title.text = "Un paso más"
	_login_copy.text = "1. Confirma el código en el navegador.
2. Regresa aquí; la sesión se abrirá sola."
	_auth_help.hide()
	_auth_code.show()
	_auth_cancel.show()
	_login_button.text = "Abrir navegador"
	var url: String = api.verification_url()
	if api.trusted_browser_url(url):
		var error: Error = OS.shell_open(url)
		_set_notice("" if error == OK else "No pudimos abrir el navegador. Vuelve a intentarlo.")

func _cancel_login() -> void:
	api.cancel_auth()
	_set_busy(false)
	_show_login()
	_set_notice("")

func _process(_delta: float) -> void:
	if is_instance_valid(_retry) and _retry.visible:
		var remaining: int = maxi(0,ceili(float(_retry_at_ms-Time.get_ticks_msec())/1000.0))
		_retry.disabled = _busy or remaining > 0
		_retry.text = "En %d s" % remaining if remaining > 0 else "Reintentar"
	if api == null or _busy or _loading_account or not is_inside_tree(): return
	if not api.device.is_empty() and api.poll_seconds_remaining() <= 0: _poll_login()

func _poll_login() -> void:
	_set_busy(true)
	var response: Dictionary = await api.poll_device_token()
	_set_busy(false)
	if response.ok:
		_set_notice("")
		await _load_account()
	elif str(response.error.code) not in ["WAIT","authorization_pending","slow_down","CANCELLED"]:
		_report(response)
		if api.device.is_empty(): _show_login()

func _load_account() -> void:
	if _loading_account: return
	_loading_account = true
	_retry.hide()
	_set_busy(true)
	_login_title.text = "Entrando…"
	_login_copy.text = ""
	var stamp: int = _view_generation
	var identity: Dictionary = await api.me()
	if not _current(stamp): return
	if not identity.ok:
		_loading_account = false
		_set_busy(false)
		_report(identity)
		return
	var catalog_response: Dictionary = await api.catalog()
	if not _current(stamp): return
	if not catalog_response.ok:
		_loading_account = false
		_set_busy(false)
		_report(catalog_response)
		return
	_catalog = catalog_response.data.duplicate(true)
	var fighters_response: Dictionary = await api.fighters()
	if not _current(stamp): return
	_loading_account = false
	_set_busy(false)
	if not fighters_response.ok:
		_report(fighters_response)
		return
	_fighters = fighters_response.data.get("fighters",[]).duplicate(true)
	_show_account()
	_refresh_picker()
	if _fighters.is_empty(): _show_create()
	else:
		if _fighter.is_empty(): _fighter = _fighters[0].duplicate(true)
		_refresh_preview()
		await _load_tab()
	if not api.pending_operation.is_empty():
		_set_notice("Hay una operación sin respuesta confirmada. Reinténtala para recuperar su resultado.")
		_retry.show()
		_layout()

func _refresh_picker() -> void:
	_picker.clear()
	var selected: int = 0
	for index in range(_fighters.size()):
		var fighter: Dictionary = _fighters[index]
		_picker.add_item("%s · Nv. %d" % [_fighter_name(fighter),int(fighter.get("progression",{}).get("level",1))])
		if str(fighter.get("fighter_id","")) == str(_fighter.get("fighter_id","")):
			selected = index
			_fighter = fighter.duplicate(true)
	if not _fighters.is_empty(): _picker.select(selected)

func _select_fighter(index: int) -> void:
	if _busy or index < 0 or index >= _fighters.size(): return
	_fighter = _fighters[index].duplicate(true)
	_creating = false
	_history_cursor = ""
	_refresh_preview()
	_load_tab()

func _refresh_preview() -> void:
	if _fighter.is_empty(): return
	_self_portrait.configure(_fighter,_visual_definition(_fighter))
	_actor = _self_portrait.actor()
	if api.has_method("remember_fighter"): api.remember_fighter(_fighter)
	_name.text = _fighter_name(_fighter)
	var progression: Dictionary = _fighter.get("progression",{})
	var online: Dictionary = _fighter.get("online",{})
	var xp_text: String = "%d / %d XP" % [int(progression.get("xp",0)),int(progression.xp_required)] if int(progression.get("xp_required",0)) > 0 else "%d XP" % int(progression.get("xp",0))
	_stats.text = "Nivel %d · %s\nRating %d · %d V / %d D%s" % [int(progression.get("level",1)),xp_text,int(online.get("rating",1000)),int(online.get("wins",0)),int(online.get("losses",0))," / %d E" % int(online.draws) if int(online.get("draws",0))>0 else ""]
	_personalize.disabled = _busy
	_layout()

func _select_tab(index: int) -> void:
	if _busy: return
	_tab = clampi(index,0,3)
	_creating = false
	_history_cursor = ""
	_refresh_preview()
	_load_tab()

func _load_tab() -> void:
	if _fighter.is_empty(): return
	_set_busy(true)
	var stamp: int = _view_generation
	var response: Dictionary = {"ok":true,"data":{}}
	match _tab:
		0: response = await api.opponents(str(_fighter.fighter_id))
		1: response = await api.story(str(_fighter.fighter_id))
		3:
			response = await api.offline_results()
			if response.ok: _offline = response.data.duplicate(true)
			if response.ok and _current(stamp): response = await api.history(str(_fighter.fighter_id))
	if not _current(stamp): return
	_set_busy(false)
	if not response.ok:
		_report(response)
		_clear_content()
		_label(_content,"No pudimos cargar esta sección. Tu progreso permanece en el servidor.",15,MUTED,true)
		_add_button("Volver a cargar",_load_tab)
		return
	match _tab:
		0: _opponents = response.data.get("opponents",[]).duplicate(true)
		1: _story = response.data.duplicate(true)
		3:
			_history = response.data.get("battles",[]).duplicate(true)
			_history_cursor = str(response.data.get("next_cursor","")) if response.data.get("next_cursor") != null else ""
	if api.pending_operation.is_empty(): _retry.hide()
	_render_tab()

func _render_tab() -> void:
	if _rendering: return
	_rendering = true
	_clear_content()
	for index in range(_tab_buttons.size()):
		Visuals.apply_button(_tab_buttons[index],"navigation_active" if index == _tab else "navigation")
	_title.text = ["Arena online","Historia online","Tu luchador online","Actividad online"][_tab]
	_set_environment("upgrades" if _tab==2 else ("history" if _tab==3 else "online"))
	match _tab:
		0: _render_arena()
		1: _render_story()
		2: _render_profile()
		3: _render_activity()
	_rendering = false
	_layout()

func _render_arena() -> void:
	if _opponents.is_empty():
		_section(_content,"EL PATIO COMPARTIDO","El patio está tranquilo","Aún no hay rivales disponibles para tu luchador. Vuelve a consultar el patio más tarde.")
		_add_button("Actualizar rivales",_load_tab)
		return
	var selected: Dictionary = {}
	for opponent: Dictionary in _opponents:
		if str(opponent.get("fighter_id",""))==_selected_opponent_id: selected=opponent
	if selected.is_empty(): selected=_opponents[0]
	_selected_opponent_id = str(selected.fighter_id)
	var hero := GridContainer.new()
	hero.name = "OnlineChallenger"
	hero.columns = 1 if _compact and not _short else 2
	hero.add_theme_constant_override("h_separation",32)
	hero.add_theme_constant_override("v_separation",8)
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(hero)
	var details := _stack(hero)
	var online: Dictionary = selected.get("online",{})
	_section(details,"RETADOR DEL PATIO",_fighter_name(selected),"Nivel %d · Rating %d" % [int(selected.get("progression",{}).get("level",1)),int(online.get("rating",1000))])
	var badge := Badge.new()
	badge.configure(_difficulty(str(selected.get("difficulty","similar"))),"current")
	details.add_child(badge)
	var definition := _visual_definition(selected)
	var role := str(definition.get("role",""))
	if not role.is_empty(): _label(details,role,14,TEAL,true)
	_label(details,"Combate automático contra su luchador, incluso si no está conectado.",14,MUTED,true)
	_add_button("Desafiar a "+_fighter_name(selected),_challenge.bind(_selected_opponent_id),true,details)
	var portrait := FighterPreview.new()
	portrait.name = "ChallengerPortrait"
	portrait.custom_minimum_size = Vector2(0,220 if _compact else (150 if _short else 390))
	portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero.add_child(portrait)
	portrait.configure(selected,definition)
	portrait.set_motion(false,bool(get_tree().get_meta("brasa_reduced_motion",false)))
	if hero.columns==1: hero.move_child(portrait,0)
	if _opponents.size()>1:
		_label(_content,"OTROS RETADORES",12,GOLD)
		for opponent: Dictionary in _opponents:
			var id := str(opponent.fighter_id)
			if id==_selected_opponent_id: continue
			var row := _stack(_content)
			_label(row,_fighter_name(opponent),21,CREAM,true)
			_label(row,"Nivel %d · Rating %d · %s" % [int(opponent.get("progression",{}).get("level",1)),int(opponent.get("online",{}).get("rating",1000)),_difficulty(str(opponent.get("difficulty","similar")))],14,MUTED,true)
			_add_button("Ver retador",_select_opponent.bind(id),false,row)
			_divider(row)
	_add_button("Actualizar rivales",_load_tab)

func _select_opponent(id: String) -> void:
	if _busy: return
	_selected_opponent_id = id
	_render_tab()

func _visual_definition(fighter: Dictionary) -> Dictionary:
	var id := str(fighter.get("archetype_id",fighter.get("character_id","nima")))
	var descriptor: Dictionary = Characters.definition(id)
	if fighter.get("combatant") is Dictionary: descriptor.merge(fighter.combatant.duplicate(true),true)
	for key: String in ["appearance","identity"]:
		if fighter.get(key) is Dictionary: descriptor[key]=fighter[key].duplicate(true)
	return descriptor

func _set_environment(section: String) -> void:
	var online: Dictionary = _fighter.get("online",{})
	var state := {"character_id":str(_fighter.get("archetype_id","")),"appearance":_fighter.get("appearance",{}),"story_cleared":int(online.get("story_cleared",0)),"arena_wins":int(online.get("wins",0))}
	_environment.set_context(Visuals.section_context(section),state)
	_environment.get_node("DecorativeMemories").hide()

func _section(parent: Node, eyebrow: String, title: String, subtitle: String = "") -> Control:
	var header := SectionHeader.new()
	header.configure(eyebrow,title,subtitle)
	header.set_compact(_compact or _short)
	parent.add_child(header)
	return header

func _stack(parent: Node) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",8)
	parent.add_child(column)
	return column

func _divider(parent: Node) -> void:
	var line := HSeparator.new()
	line.modulate = Color(1,1,1,0.28)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)

func _render_story() -> void:
	var cleared: int = int(_story.get("cleared",_fighter.get("online",{}).get("story_cleared",0)))
	var total: int = maxi(1,_catalog.get("story_stages",[]).size()) if not _catalog.get("story_stages",[]).is_empty() else 100
	var complete: bool = cleared>=total or bool(_story.get("complete",false))
	var encounter: Dictionary = _story.get("next_stage",_story.get("stage",{})) if _story.get("next_stage",_story.get("stage",{})) is Dictionary else {}
	var chapter: int = int(encounter.get("chapter",1))
	var boss: bool = str(encounter.get("kind",""))=="boss"
	_environment.set_context(Visuals.World.context_id("route",chapter,boss),{"appearance":_fighter.get("appearance",{}),"story_cleared":cleared,"arena_wins":int(_fighter.get("online",{}).get("wins",0))})
	var badge := Badge.new()
	badge.configure("%d de %d encuentros superados" % [cleared,total],"completed" if complete else "current","boss" if boss else "normal")
	_content.add_child(badge)
	if complete:
		_section(_content,"HISTORIA ONLINE","La ruta queda en tu legado","Has completado la ruta. Tu compañero puede seguir creciendo en Arena.")
		_add_button("Volver a Arena",_select_tab.bind(0),true)
		return
	var hero := GridContainer.new()
	hero.columns = 1 if _compact and not _short else 2
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero.add_theme_constant_override("h_separation",32)
	hero.add_theme_constant_override("v_separation",12)
	_content.add_child(hero)
	var detail := _stack(hero)
	_section(detail,"HISTORIA ONLINE · ENCUENTRO %02d" % (cleared+1),str(encounter.get("title","Siguiente encuentro")),str(encounter.get("description",encounter.get("profile","Prepara tu ficha y entra al siguiente duelo."))))
	if encounter.has("level"): _label(detail,"%s · nivel %d" % [str(encounter.get("opponent_name","Rival")),int(encounter.level)],14,MUTED)
	if not str(encounter.get("strength","")).is_empty(): _label(detail,"FORTALEZA · "+str(encounter.strength),14,TEAL,true)
	if not str(encounter.get("weakness","")).is_empty(): _label(detail,"PUNTO DÉBIL · "+str(encounter.weakness),14,Visuals.CORAL,true)
	if encounter.has("xp_win") and encounter.has("xp_loss"): _label(detail,"Victoria +%d XP · Derrota +%d XP" % [int(encounter.xp_win),int(encounter.xp_loss)],14,GOLD,true)
	_label(detail,"Esta ruta comparte el luchador y la progresión de Arena online.",14,MUTED,true)
	_add_button("Entrar al encuentro",_start_story,true,detail)
	var id: String = str(encounter.get("character_id",""))
	if not id.is_empty() and not boss:
		var portrait := FighterPreview.new()
		portrait.custom_minimum_size = Vector2(0,220 if _compact else (150 if _short else 380))
		portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hero.add_child(portrait)
		var rival_definition: Dictionary = Characters.definition(id)
		if encounter.get("appearance") is Dictionary: rival_definition["appearance"] = encounter.appearance.duplicate(true)
		portrait.configure({},rival_definition)
		portrait.set_motion(false,bool(get_tree().get_meta("brasa_reduced_motion",false)))
		if hero.columns==1: hero.move_child(portrait,0)
	else:
		# The public stage omits the boss descriptor. An honest emblem keeps the
		# route visual without substituting its base archetype for the real boss.
		var emblem := TextureRect.new()
		emblem.texture = Visuals.World.illustration("boss_badge" if boss else "encounter_badge")
		emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		emblem.custom_minimum_size = Vector2(0,112 if _compact or _short else 170)
		emblem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hero.add_child(emblem)
		var marker := _label(emblem,"%02d" % (cleared+1),32 if _compact or _short else 44,GOLD)
		marker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if hero.columns==1: hero.move_child(emblem,0)

func _render_profile() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",16)
	_content.add_child(row)
	_self_portrait.reparent(row)
	_self_portrait.custom_minimum_size = Vector2(108,112)
	_self_portrait.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_self_portrait.show()
	_self_portrait.set_motion(false,bool(get_tree().get_meta("brasa_reduced_motion",false)))
	var introduction := _stack(row)
	introduction.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_label(introduction,_fighter_name(_fighter),24,CREAM,true)
	_label(introduction,"Elige una sección. Las mejoras se guardan al aplicarlas.",14,MUTED,true)
	var navigation := GridContainer.new()
	navigation.columns = 4
	navigation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navigation.add_theme_constant_override("h_separation",8)
	navigation.add_theme_constant_override("v_separation",8)
	_content.add_child(navigation)
	for index in range(4):
		var button := _add_button(["Atributos","Técnicas","Talentos","Estilo"][index],_select_profile_section.bind(index),false,navigation)
		button.name = "ProfileSection%d" % index
		button.add_theme_font_size_override("font_size",13 if _compact else 15)
		Visuals.apply_button(button,"navigation_active" if index==_profile_section else "navigation")
	match _profile_section:
		0: _render_profile_stats()
		1: _render_profile_moves()
		2: _render_profile_perks()
		3: _render_profile_style()
	if _profile_section != 3:
		var respec := _add_button("Redistribuir puntos…",_confirm_respec)
		respec.custom_minimum_size.x = 232
		respec.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		respec.tooltip_text = "Recupera tus puntos, fichas y elecciones. Requiere confirmación."

func _select_profile_section(index: int) -> void:
	if _busy: return
	_profile_section = clampi(index,0,3)
	_render_tab()
	var focus := _content.find_child("ProfileSection%d" % _profile_section,true,false) as Button
	if focus != null: _focus_profile_section.call_deferred(focus)

func _focus_profile_section(button: Button) -> void:
	if not is_instance_valid(button): return
	button.grab_focus()
	await get_tree().process_frame
	if is_instance_valid(_scroll): _scroll.scroll_vertical = 0

func _choice_card(parent: Node) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel",Visuals.training_card())
	parent.add_child(panel)
	return _stack(panel)

func _render_profile_stats() -> void:
	var progression: Dictionary = _fighter.get("progression",{})
	var combat_stats: Dictionary = _fighter.get("combatant",{}).get("combat_stats",{})
	_section(_content,"","%d puntos disponibles" % int(progression.get("stat_points",0)),"Cada mejora cuesta 1 punto.")
	var stats_grid := _grid(_content)
	for option: Dictionary in _catalog.get("stat_options",[]):
		var key: String = str(option.get("key",option.get("id","")))
		var row := _choice_card(stats_grid)
		_divider(row)
		var values := HBoxContainer.new()
		values.add_theme_constant_override("separation",12)
		row.add_child(values)
		var detail := _stack(values)
		_label(detail,str(option.get("name",key)),21,CREAM,true)
		var value := ""
		if combat_stats.has(key): value = "%.1f%%" % (float(combat_stats[key])*100.0) if key in ["accuracy","evasion","crit_chance","resistance"] else "%.1f" % float(combat_stats[key])
		_label(detail,(value+" · " if not value.is_empty() else "")+"%d puntos asignados" % int(progression.get("allocations",{}).get(key,0)),14,TEAL,true)
		var button := _add_button("Mejorar",_allocate.bind(key),false,values)
		button.custom_minimum_size.x = 108
		button.size_flags_horizontal = Control.SIZE_SHRINK_END
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.tooltip_text = "Mejorar "+str(option.get("name",key))
		button.disabled = int(progression.get("stat_points",0))<=0
		button.set_meta("locked",button.disabled)
		_label(row,str(option.get("description","")),14,MUTED,true)

func _render_profile_moves() -> void:
	var progression: Dictionary = _fighter.get("progression",{})
	_section(_content,"TU ESTILO","Técnicas","%d puntos de técnica disponibles" % int(progression.get("move_points",0)))
	var archetype_id: String = str(_fighter.get("archetype_id",""))
	var moves_grid := _grid(_content)
	for raw: Variant in _catalog.get("moves",{}).get(archetype_id,[]):
		if not raw is Dictionary: continue
		var move: Dictionary = raw
		var id: String = str(move.get("id",""))
		var tier: int = int(progression.get("move_upgrades",{}).get(id,0))
		var unlocked: bool = int(progression.get("level",1))>=int(move.get("unlock_level",1))
		var row := _choice_card(moves_grid)
		_divider(row)
		_label(row,"DISPONIBLE · MEJORA %d / %d" % [tier,int(move.get("max_tier",2))] if unlocked else "SE ABRE EN NIVEL %d" % int(move.get("unlock_level",1)),12,TEAL if unlocked else MUTED,true)
		_label(row,str(move.get("name",id)),21,CREAM,true)
		_label(row,str(move.get("description","")),14,MUTED,true)
		var button := _add_button("Mejorar técnica",_upgrade_move.bind(id),false,row)
		button.disabled = not unlocked or tier>=int(move.get("max_tier",2)) or int(progression.get("move_points",0))<=0
		button.set_meta("locked",button.disabled)
		if not unlocked: button.text="Disponible en nivel %d" % int(move.get("unlock_level",1))
		elif tier>=int(move.get("max_tier",2)): button.text="Mejora máxima"

func _render_profile_perks() -> void:
	var progression: Dictionary = _fighter.get("progression",{})
	var archetype_id: String = str(_fighter.get("archetype_id",""))
	var available := int(progression.get("perk_points",0))
	_section(_content,"TUS DECISIONES","Talentos","1 elección disponible" if available == 1 else "%d elecciones disponibles" % available)
	var perks_grid := _grid(_content)
	for raw: Variant in _catalog.get("perks",{}).get(archetype_id,[]):
		if not raw is Dictionary: continue
		var perk: Dictionary = raw
		var id: String = str(perk.get("id",""))
		var selected: bool = id in progression.get("perks",[])
		var row := _choice_card(perks_grid)
		_divider(row)
		_label(row,str(perk.get("name",id)),21,TEAL if selected else CREAM,true)
		_label(row,str(perk.get("description","")),14,MUTED,true)
		var button := _add_button("Elegido" if selected else "Elegir talento",_choose_perk.bind(id),selected,row)
		button.disabled = selected or int(progression.get("perk_points",0))<=0
		button.set_meta("locked",button.disabled)

func _render_profile_style() -> void:
	_section(_content,"CUANDO NO ESTÁS","Estilo de combate","Elige cómo pelea tu luchador cuando recibe desafíos.")
	var styles := _grid(_content)
	for raw: Variant in _catalog.get("ai_styles",[]):
		var style: Dictionary = raw if raw is Dictionary else {"id":str(raw),"name":{"balanced":"Equilibrado","aggressive":"Agresivo","defensive":"Defensivo","fast":"Veloz","counter":"Réplica","risky":"Arriesgado","unpredictable":"Imprevisible"}.get(str(raw),str(raw))}
		var id: String = str(style.get("id","balanced"))
		var selected: bool = id==str(_fighter.get("online",{}).get("ai_style","balanced"))
		_add_button(("✓ " if selected else "")+str(style.get("name",id)),_choose_ai.bind(id),selected,styles)

func _grid(parent: Node) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 1 if _compact else 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",32)
	grid.add_theme_constant_override("v_separation",20)
	parent.add_child(grid)
	return grid

func _own_hero(parent: Node, eyebrow: String, title: String, subtitle: String, preview_height: float = -1) -> VBoxContainer:
	var hero := GridContainer.new()
	hero.columns = 1 if _compact and not _short else 2
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero.add_theme_constant_override("h_separation",32)
	hero.add_theme_constant_override("v_separation",12)
	parent.add_child(hero)
	_self_portrait.reparent(hero)
	_self_portrait.custom_minimum_size = Vector2(0,150 if _short else (preview_height if preview_height>0 else (220 if _compact else 350)))
	_self_portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_self_portrait.show()
	_self_portrait.set_motion(false,bool(get_tree().get_meta("brasa_reduced_motion",false)))
	var detail := _stack(hero)
	_section(detail,eyebrow,title,subtitle)
	return detail

func _render_activity() -> void:
	_section(_content,"EL ARCHIVO","Mientras no estabas","Defensas nuevas de todos los luchadores de tu cuenta.")
	var results: Array = _offline.get("results",[])
	var totals: Dictionary = _offline.get("totals",{})
	if results.is_empty(): _label(_content,"Todavía no hay defensas nuevas que revisar.",15,MUTED,true)
	else:
		var panel := PanelContainer.new()
		Visuals.apply_panel(panel,"reward")
		_content.add_child(panel)
		var summary := _stack(panel)
		var battles := int(totals.get("battles",results.size()))
		var wins := int(totals.get("wins",0))
		var losses := int(totals.get("losses",0))
		_label(summary,"%d %s · %d %s · %d %s" % [battles,"combate" if battles==1 else "combates",wins,"victoria" if wins==1 else "victorias",losses,"derrota" if losses==1 else "derrotas"],18,CREAM,true)
		_label(summary,"+%d XP · Rating %+d" % [int(totals.get("xp",totals.get("xp_gained",0))),int(totals.get("rating_change",0))],22,GOLD,true)
		for result: Dictionary in results:
			var row := _card()
			_label(row,str(result.get("fighter_name","Tu luchador"))+" contra "+str(result.get("challenger_name","otro jugador")),21,CREAM,true)
			var outcome := "Empate" if bool(result.get("draw",false)) or str(result.get("winner",""))=="draw" else ("Victoria" if bool(result.get("won",false)) else "Derrota")
			_label(row,outcome+" · +%d XP · Rating %+d" % [int(result.get("xp_gained",0)),int(result.get("rating_change",result.get("rating_delta",0)))],14,MUTED,true)
			var battle_id: String = str(result.get("battle_id",""))
			if ApiScript._uuid(battle_id): _add_button("Ver defensa",_open_history.bind(battle_id),false,row)
		_add_button("Marcar como vistos",_acknowledge)
	_section(_content,"MEMORIA DE TU COMPAÑERO","Historial de este luchador",_fighter_name(_fighter))
	if _history.is_empty(): _label(_content,"Los próximos combates aparecerán aquí.",15,MUTED,true)
	for battle: Dictionary in _history:
		var row := _card()
		var side: String = str(battle.get("viewing_side","player"))
		var title: String = str(battle.get("opponent_name",battle.get("player_name" if side=="rival" else "rival_name","Combate online")))
		_label(row,title,21,CREAM,true)
		_label(row,_outcome(str(battle.get("winner","")),side)+" · "+("Historia" if str(battle.get("mode","arena"))=="story" else "Arena"),14,MUTED,true)
		var id: String = str(battle.get("id",battle.get("battle_id","")))
		if ApiScript._uuid(id): _add_button("Ver combate",_open_history.bind(id),false,row)
	if not _history_cursor.is_empty(): _add_button("Ver más",_next_history)

func _outcome(winner: String, side: String) -> String:
	if winner in ["draw","tie"]: return "Empate"
	if winner not in ["player","rival"]: return "Resultado no disponible"
	return "Victoria" if winner==side else "Derrota"

func _show_create() -> void:
	if _busy: return
	_creating = true
	_title.text = "Crear luchador online"
	_clear_content()
	_show_account()
	_personalize.disabled = true
	_set_environment("creation")
	var form := _own_hero(_content,"TU NUEVO COMPAÑERO","Tu luchador online","Elige su forma de pelear y su nombre. Tendrá progreso propio online.")
	_label(form,"BASE DE COMBATE",12,GOLD)
	_create_base = OptionButton.new()
	_create_base.fit_to_longest_item = false
	_create_base.clip_text = true
	_create_base.custom_minimum_size.y = 48
	Visuals.apply_option(_create_base)
	for character: Dictionary in _catalog.get("characters",[]):
		_create_base.add_item("Base: "+str(character.get("name",character.id))+" · "+str(character.get("role","")))
		_create_base.set_item_metadata(_create_base.item_count-1,str(character.id))
	_create_base.item_selected.connect(_preview_creation)
	form.add_child(_create_base)
	_label(form,"NOMBRE",12,GOLD)
	_create_name = LineEdit.new()
	_create_name.placeholder_text = "Nombre de tu luchador"
	_create_name.max_length = 24
	_create_name.custom_minimum_size.y = 48
	form.add_child(_create_name)
	_add_button("Crear luchador",_create_fighter,true,form)
	if not _fighter.is_empty(): _add_button("Volver a mi luchador",_cancel_creation,false,form)
	_preview_creation(0)

func _cancel_creation() -> void:
	_creating = false
	_refresh_preview()
	_render_tab()

func _preview_creation(index: int) -> void:
	if index<0 or index>=_create_base.item_count: return
	var id: String = str(_create_base.get_item_metadata(index))
	_self_portrait.configure({},Characters.definition(id))
	_actor = _self_portrait.actor()
	for character: Dictionary in _catalog.get("characters",[]):
		if str(character.id)!=id: continue
		_name.text = str(character.get("name",id))
		_stats.text = str(character.get("role",""))+"\n%d puntos iniciales" % int(_catalog.get("policy",{}).get("initial_stat_points",3))
		break

func _create_fighter() -> void:
	if _create_base.item_count == 0: return
	await _mutate("create_fighter",[str(_create_base.get_selected_metadata()),_create_name.text,ApiScript.new_key()])
func _challenge(opponent_id: String) -> void:
	await _mutate("create_battle",[str(_fighter.fighter_id),opponent_id,ApiScript.new_key()])
func _start_story() -> void:
	await _mutate("story_battle",[str(_fighter.fighter_id),ApiScript.new_key()])
func _allocate(stat: String) -> void:
	await _mutate("allocate",[str(_fighter.fighter_id),stat,1,int(_fighter.get("progression_revision",_fighter.get("revision",1))),ApiScript.new_key()])
func _choose_ai(style: String) -> void:
	await _mutate("set_ai",[str(_fighter.fighter_id),style,int(_fighter.get("progression_revision",1)),ApiScript.new_key()])
func _upgrade_move(move_id: String) -> void:
	await _mutate("upgrade_move",[str(_fighter.fighter_id),move_id,int(_fighter.get("progression_revision",1)),ApiScript.new_key()])
func _choose_perk(perk_id: String) -> void:
	await _mutate("choose_perk",[str(_fighter.fighter_id),perk_id,int(_fighter.get("progression_revision",1)),ApiScript.new_key()])
func _confirm_respec() -> void:
	_clear_content()
	var panel := PanelContainer.new()
	Visuals.apply_panel(panel,"modal")
	_content.add_child(panel)
	var content := _stack(panel)
	_section(content,"TUS DECISIONES","Redistribuir tus mejoras","El servidor devolverá los puntos invertidos en estadísticas, técnicas y talentos. Conservas tu nivel y tu ruta.")
	_add_button("Confirmar redistribución",_respec,true,content)
	_add_button("Conservar mi ficha",_render_tab,false,content)

func _respec() -> void:
	await _mutate("respec",[str(_fighter.fighter_id),int(_fighter.get("progression_revision",1)),ApiScript.new_key()])
func _acknowledge() -> void:
	var ids: Array = []
	for item: Dictionary in _offline.get("results",[]):
		var id: String = str(item.get("id",item.get("battle_id","")))
		if ApiScript._uuid(id): ids.append(id)
	if not ids.is_empty(): await _mutate("acknowledge",[ids,ApiScript.new_key()])

func _mutate(method: String, args: Array, retrying: bool = false) -> void:
	_last_mutation_ok = false
	if _busy: return
	if not retrying and not api.pending_operation.is_empty():
		_set_notice("Recupera primero la operación pendiente.")
		_retry.show()
		_layout()
		return
	api.pending_operation = {"method":method,"args":args.duplicate(true)}
	_set_busy(true)
	_retry.hide()
	_set_notice("Confirmando en el servidor…")
	var stamp: int = _view_generation
	var response: Dictionary = await api.callv(method,args)
	if not _current(stamp): return
	_set_busy(false)
	if not response.ok:
		var status: int = int(response.get("status",0))
		var code: String = str(response.get("error",{}).get("code",""))
		# A malformed success response can still describe an already committed write.
		# Preserve its key until the server returns an unambiguous result.
		if status >= 400 and status < 500 and status not in [408,429] and code not in ["INVALID_RESPONSE","FIGHTER_BUSY"]:
			api.pending_operation.clear()
		_report(response)
		_retry.visible = not api.pending_operation.is_empty()
		if status == 409 and code == "REVISION_CONFLICT":
			await _load_account()
			_set_notice("La ficha cambió en el servidor. Ya está actualizada; revisa antes de repetir el cambio.")
		_layout()
		return
	api.pending_operation.clear()
	_last_mutation_ok = true
	_last_result = response.data.duplicate(true)
	_set_notice("Guardado en el servidor.")
	if response.data.get("fighter") is Dictionary: _replace_fighter(response.data.fighter)
	elif response.data.has("fighter_id"): _replace_fighter(response.data)
	if response.data.get("battle") is Dictionary:
		_present_battle(response.data.battle)
	elif method == "create_fighter":
		_creating = false
		await _load_account()
	else: await _load_tab()

func _retry_pending() -> void:
	if Time.get_ticks_msec() < _retry_at_ms: return
	if api.pending_operation.is_empty():
		if api.is_authenticated(): await _load_account()
		else: _show_login()
		return
	var pending: Dictionary = api.pending_operation.duplicate(true)
	await _mutate(str(pending.method),pending.args,true)

func _replace_fighter(fighter: Dictionary) -> void:
	var replaced: bool = false
	for index in range(_fighters.size()):
		if str(_fighters[index].fighter_id) == str(fighter.get("fighter_id","")):
			_fighters[index] = fighter.duplicate(true)
			replaced = true
	if not replaced: _fighters.append(fighter.duplicate(true))
	_fighter = fighter.duplicate(true)
	_refresh_picker()
	_refresh_preview()

func _present_battle(battle: Dictionary) -> void:
	var record: Dictionary = battle.get("record",{})
	if Records.snapshot(record).is_empty():
		_set_notice("El resultado está guardado, pero esta repetición no es compatible con la versión del juego.")
		return
	if is_instance_valid(_replay): _replay.queue_free()
	_replay = Replay.new()
	_replay.theme = Visuals.theme()
	_replay.playback_mode = "online"
	add_child(_replay)
	_replay.viewing_side = str(battle.get("viewing_side","player"))
	_replay.configure([record])
	Visuals.apply_label(_replay._title,"title")
	Visuals.apply_label(_replay._note,"secondary","text_secondary")
	Visuals.apply_option(_replay._picker)
	Visuals.apply_button(_replay._close,"secondary")
	Visuals.apply_button(_replay._play,"primary")
	Visuals.apply_button(_replay._restart,"secondary")
	for actor_side: String in _replay.bars:
		Visuals.apply_progress(_replay.bars[actor_side],"health" if actor_side=="player" else "rival")
	_replay._title.text = "Combate online"
	var rewards: Dictionary = battle.get("rewards",{})
	var side: String = str(battle.get("viewing_side","player"))
	var player_reward: Dictionary = rewards.get(side,{})
	_replay.result_context = "+%d XP · Rating %+d" % [int(player_reward.get("xp_gained",0)),int(player_reward.get("rating_change",0))]
	_replay._note.text = "Resultado del servidor · " + _replay.result_context
	var snapshot: Dictionary = Records.snapshot(record)
	_replay._picker.set_item_text(0,_outcome(str(snapshot.winner),side)+" · "+str(snapshot.player.name)+" contra "+str(snapshot.rival.name))
	_replay.closed.connect(_close_replay)
	_replay._toggle()
	_layout()

func _close_replay() -> void:
	if is_instance_valid(_replay): _replay.queue_free()
	_replay = null
	_load_tab()

func _open_history(id: String) -> void:
	if _busy: return
	_set_busy(true)
	var stamp: int = _view_generation
	var response: Dictionary = await api.battle(id)
	if not _current(stamp): return
	_set_busy(false)
	if response.ok: _present_battle(response.data.get("battle",{}))
	else: _report(response)

func _next_history() -> void:
	if _busy or _history_cursor.is_empty(): return
	_set_busy(true)
	var stamp: int = _view_generation
	var response: Dictionary = await api.history(str(_fighter.fighter_id),_history_cursor)
	if not _current(stamp): return
	_set_busy(false)
	if response.ok:
		_history.append_array(response.data.get("battles",[]))
		_history_cursor = str(response.data.get("next_cursor","")) if response.data.get("next_cursor") != null else ""
		_render_tab()
	else: _report(response)

func _sign_out() -> void:
	if _busy: return
	_set_busy(true)
	var stamp: int = _view_generation
	var response: Dictionary = await api.sign_out()
	if not _current(stamp): return
	_set_busy(false)
	_fighters.clear()
	_fighter.clear()
	_show_login()
	_set_notice("Sesión cerrada." if response.ok else "Sesión borrada de este juego. No pudimos confirmar la revocación en el servidor.")

func _open_customization() -> void:
	if _busy or _fighter.is_empty(): return
	_set_busy(true)
	var stamp: int = _view_generation
	var response: Dictionary = await api.owned()
	if not _current(stamp): return
	_set_busy(false)
	if not response.ok:
		_report(response)
		return
	var identity := RemoteIdentity.new()
	identity.fighter = _fighter.duplicate(true)
	for raw: Variant in response.data.get("owned",[]):
		var id: String = str(raw.get("inventory_id","")) if raw is Dictionary else str(raw)
		if not id.is_empty(): identity.inventory.append(id)
	_customizer = Customizer.new()
	add_child(_customizer)
	_customizer.configure(identity,str(_fighter.archetype_id),false)
	_customizer.confirmed.connect(_confirm_cosmetic)
	_customizer.cancelled.connect(_close_customization)
func _confirm_cosmetic(_archetype: String, fighter_name: String, appearance: Dictionary) -> void:
	if not api.pending_operation.is_empty():
		if str(api.pending_operation.method) == "update_fighter": await _retry_pending()
		else:
			_customizer.set_error("Recupera primero la operación pendiente al cerrar este editor.")
			return
	else:
		await _mutate("update_fighter",[str(_fighter.fighter_id),int(_fighter.get("revision",1)),fighter_name,appearance.duplicate(true),ApiScript.new_key()])
	if _last_mutation_ok: _close_customization()
	elif is_instance_valid(_customizer): _customizer.set_error(_notice.text)
func _close_customization() -> void:
	if is_instance_valid(_customizer): _customizer.queue_free()
	_customizer = null

func _open_recovery() -> void:
	if api is ApiScript and not api.base_url.is_empty(): OS.shell_open(api.base_url+"/auth?screen=recovery")

func _open_account() -> void:
	if _busy: return
	if is_instance_valid(_account_modal): _account_modal.queue_free()
	_account_modal = AccountModal.new()
	add_child(_account_modal)
	_account_modal.max_width = 480
	_account_modal.preferred_height = 330
	_account_modal.configure("Cuenta y seguridad","Tu luchador y tu progreso siguen guardados.")
	var body: VBoxContainer = _account_modal.content()
	body.add_child(_button("Gestionar mis passkeys",_open_security_browser,true))
	body.add_child(_button("Cerrar sesión en este juego",_account_sign_out))
	_account_modal.open(_logout)

func _open_security_browser() -> void:
	if api is ApiScript and not api.base_url.is_empty(): OS.shell_open(api.base_url+"/auth?screen=security")

func _account_sign_out() -> void:
	if is_instance_valid(_account_modal): _account_modal.close()
	await _sign_out()

static func _friendly_error(response: Dictionary) -> String:
	var code: String = str(response.get("error",{}).get("code",""))
	if int(response.get("status",0))==429: return "Espera un momento antes de volver a intentarlo."
	var messages := {
		"CONNECTION_FAILED":"No pudimos conectar. Comprueba tu conexión y vuelve a intentarlo.",
		"UNAUTHENTICATED":"Continúa para volver a entrar.","expired_token":"Este acceso venció. Vuelve a intentarlo.",
		"access_denied":"No se conectó el juego. Puedes volver a intentarlo.","CANCELLED":"",
		"FIGHTER_EXISTS":"Ya existe un luchador de esta base.","FIGHTER_BUSY":"Tu luchador está terminando otro encuentro. Reintenta en un momento.",
		"REVISION_CONFLICT":"Tu luchador cambió. Actualiza su ficha y vuelve a intentarlo.",
		"INVALID_NAME":"Elige un nombre válido para tu luchador.","INSUFFICIENT_POINTS":"Necesitas más puntos para esta mejora.",
		"NO_OPPONENTS":"No hay rivales disponibles por ahora.","NOT_FOUND":"No encontramos ese encuentro. Actualiza e inténtalo de nuevo."}
	return str(messages.get(code,"No pudimos completar la acción. Vuelve a intentarlo."))

func _report(response: Dictionary) -> void:
	var error: Dictionary = response.get("error",{})
	_set_notice(_friendly_error(response))
	if int(response.get("status",0)) == 429: _retry_at_ms = Time.get_ticks_msec()+clampi(int(response.get("retry_after",5)),1,300)*1000
	if int(response.get("status",0)) == 401 or str(error.get("code","")) == "UNAUTHENTICATED": _show_login()
	elif _login.visible:
		_retry.hide()
		_login_button.text = "Reintentar"
	elif str(error.get("code","")) != "CANCELLED":
		_retry.show()
		_layout()

func _set_notice(text: String) -> void:
	_notice.text = text
	_layout()
func _set_busy(value: bool) -> void:
	_busy = value
	if not _built: return
	_picker.disabled = value
	_new.disabled = value
	_logout.disabled = value
	_personalize.disabled = value or _fighter.is_empty() or _creating
	_login_button.disabled = value
	_retry.disabled = value
	for button: Button in _tab_buttons: button.disabled = value
	for button: Button in _buttons:
		if is_instance_valid(button): button.disabled = value or bool(button.get_meta("locked",false))

func _current(stamp: int) -> bool:
	return is_inside_tree() and stamp == _view_generation
func _close_panel() -> void:
	_view_generation += 1
	if api != null: api.cancel_auth()
	closed.emit()
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if is_instance_valid(_account_modal) and _account_modal.visible: return
		if is_instance_valid(_customizer): _close_customization()
		elif is_instance_valid(_replay): _close_replay()
		else: _close_panel()
		get_viewport().set_input_as_handled()

func _clear_content() -> void:
	_buttons.clear()
	if is_instance_valid(_self_portrait) and _self_portrait.get_parent()!=_preview:
		_self_portrait.reparent(_preview)
	_self_portrait.hide()
	for node: Node in _content.get_children():
		_content.remove_child(node)
		node.queue_free()
	_scroll.scroll_vertical = 0

func _card() -> VBoxContainer:
	var row := _stack(_content)
	_divider(row)
	return row

func _add_button(text: String, action: Callable, primary: bool = false, parent: Node = null) -> Button:
	var button := _button(text,action,primary)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(parent if parent != null else _content).add_child(button)
	_buttons.append(button)
	return button
func _button(text: String, action: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(40,48)
	button.clip_text = true
	Visuals.apply_button(button,"primary" if primary else "secondary")
	button.pressed.connect(action)
	return button

func _label(parent: Node, text: String, font_size: int, color: Color, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	Visuals.apply_label(label,"section" if font_size>=20 else "body")
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = not wrap
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING if wrap else TextServer.OVERRUN_TRIM_ELLIPSIS
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

func _place(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size
static func _fighter_name(fighter: Dictionary) -> String:
	return str(fighter.get("identity",{}).get("display_name",fighter.get("name","Luchador")))
static func _difficulty(value: String) -> String:
	return {"easier":"Más accesible","similar":"Poder similar","harder":"Más exigente"}.get(value,value)
