extends Control

const Visuals = preload("res://scripts/ui/game_visual_system.gd")
const HomePanel = preload("res://scripts/ui/home_panel.gd")
const GameModalScript = preload("res://scripts/ui/components/game_modal.gd")
const FighterPreview = preload("res://scripts/ui/components/game_fighter_preview.gd")
const CombatantHUD = preload("res://scripts/ui/components/game_combatant_hud.gd")
const BattleResultPanel = preload("res://scripts/ui/components/game_battle_result_panel.gd")
const AudioDirectorScript = preload("res://scripts/audio/audio_director.gd")
const AudioSettingsScript = preload("res://scripts/ui/components/game_audio_settings.gd")

const EngineScript = preload("res://scripts/combat_engine.gd")
const ProgressScript = preload("res://scripts/progression.gd")
const FighterScript = preload("res://scripts/fighter_view.gd")
const ArenaScript = preload("res://scripts/arena_view.gd")
const CombatFXScript = preload("res://scripts/combat_fx.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const BalanceConfig = preload("res://scripts/balance.gd")
const Layout = preload("res://scripts/ui/battle_layout.gd")
const RosterScript = preload("res://scripts/ui/roster_panel.gd")
const StoryCatalog = preload("res://scripts/story_catalog.gd")
const StoryProgress = preload("res://scripts/story_progression.gd")
const StoryPanel = preload("res://scripts/ui/story_panel.gd")
const Moves = preload("res://scripts/move_catalog.gd")
const IdentityStore = preload("res://scripts/fighter_identity.gd")
const CustomizationPanel = preload("res://scripts/ui/customization_panel.gd")
const BattleIdentity = preload("res://scripts/battle_identity.gd")
const ReplayPanel = preload("res://scripts/ui/battle_replay_panel.gd")
const OnlineApiScript = preload("res://scripts/online_api.gd")
const OnlinePanelScript = preload("res://scripts/ui/online_panel.gd")
const CREAM = Visuals.CREAM
const MUTED = Visuals.MUTED
const GOLD = Visuals.GOLD
const TEAL = Visuals.TEAL
const CORAL = Visuals.CORAL
const SURFACE = Visuals.SURFACE
const DARK = Visuals.DARK
const SPECIES = ["Lince del desierto", "Ajolote del río", "Gólem de jade"]
const COLORS = [Color("dba06a"), Color("dfa3b2"), Color("80b5a8")]
const STAT_KEYS = ["life", "strength", "agility", "speed"]
const STAT_NAMES = ["Vida", "Fuerza", "Agilidad", "Velocidad"]

var combat = EngineScript.new()
var progression = ProgressScript.new()
var league_progression = progression
var story_progression = StoryProgress.new()
var story_mode := false
var story_loaded := false
var story_layer: Control
var story_button: Button
var rival: Dictionary = {}
var arena: Node2D
var combat_fx: Node2D
var player_view: Node2D
var rival_view: Node2D
var player_name_label: Label
var rival_name_label: Label
var player_hp_label: Label
var rival_hp_label: Label
var player_bar: ProgressBar
var rival_bar: ProgressBar
var timer_label: Label
var state_label: Label
var round_label: Label
var record_label: Label
var manager_label: Label
var xp_label: Label
var xp_bar: ProgressBar
var points_label: Label
var stat_values: Array[Label] = []
var stat_effects: Array[Label] = []
var stat_buttons: Array[Button] = []
var stat_deltas: Array[Label] = []
var stat_help_buttons: Array[Button] = []
var stat_descriptions: Array[Label] = []
var training_notice: Label
var training_detail_index := -1
const TRAINING_DESCRIPTIONS := [
	"Más vida para resistir los golpes y seguir en pie.",
	"Tus golpes hacen más daño. El resultado también depende de la defensa rival.",
	"Aumenta la probabilidad de esquivar y de conectar golpes críticos.",
	"Acorta la espera entre ataques: tu compañero golpea con más frecuencia."
]
var fight_button: Button
var speed_button: Button
var sound_button: Button
var help_button: Button
var rival_card_name: Label
var rival_card_info: Label
var rival_card_stats: Label
var status_label: Label
var feed_label: Label
var player_hud: Panel
var rival_hud: Panel
var result_veil: ColorRect
var result_panel: Panel
var result_title: Label
var result_copy: Label
var creation_layer: Control
var help_layer: Control
var active_match: bool = false
var sound_enabled: bool = true
var quick_mode: bool = false
var reduced_motion: bool = false
var match_generation: int = 0
var feed: Array[String] = []
var audio_director: Node
var audio_settings: Control
var _audio_event_index := 0
var _audio_session_finished := false
var save_notice: Label
var player_level_label: Label
var rival_level_label: Label
var player_status_label: Label
var rival_status_label: Label
var surrender_button: Button
var summary_button: Button
var roster_button: Button
var modal_layer: Control
var modal_kind := ""
var modal_body: RichTextLabel
var battle_log: Array[String] = []
var last_battle_summary: Dictionary = {}
var last_reward: Dictionary = {}
var finishing := false
var signature_banner: Label
var floating_lanes: Dictionary = {}
var session_save_path := ""
var online_api: Node
var online_layer: Control
var layout_rects: Dictionary = {}
var top_gradient: TextureRect
var bottom_gradient: TextureRect
var brand_label: Label
var menu_button: Button
var training_button: Button
var log_button: Button
var progress_label: Label
var progress_xp_label: Label
var progress_bar: ProgressBar
var training_content: Control
var training_scroll: ScrollContainer
var stat_cards: Array[Control] = []
var stat_titles: Array[Label] = []
var modal_panel: Control
var modal_canvas: Control
var profile_details: ScrollContainer
var document_preview: Control
var history_scroll: ScrollContainer
var modal_title: Label
var modal_subtitle: Label
var modal_close_button: Button
var modal_hint: Label
var modal_cancel: Button
var modal_accept: Button
var menu_actions: Array[Button] = []
var approach_tween: Tween
var result_tween: Tween
var feed_tween: Tween
var _layout_size := Vector2.ZERO
var _last_active_side := ""
var fighter_identity = IdentityStore.new()
var identity_loaded := false
var customization_layer: Control
var replay_layer: Control
var _customization_return := ""



func _ready() -> void:
	get_window().content_scale_size = Vector2i.ZERO
	get_window().min_size = Vector2i(360, 360)
	resized.connect(_layout_interface)
	_build_theme()
	_build_interface()
	_layout_interface()
	var args := OS.get_cmdline_user_args()
	var save_path := "user://brasa_save.json"
	if args.has("--smoke-test"):
		save_path = ProjectSettings.globalize_path("res://").path_join("../../work/ui_smoke_save_%d.json" % Time.get_ticks_usec()).simplify_path()
	for arg in args:
		if arg.begins_with("--save-path="):
			save_path = arg.trim_prefix("--save-path=")
	session_save_path = save_path
	_make_sounds()
	var preferences := ConfigFile.new()
	if preferences.load(session_save_path + ".prefs.cfg") == OK:
		reduced_motion = bool(preferences.get_value("display", "reduced_motion", false))
	_apply_motion_preference()
	progression.load_save(save_path)
	_initialize_identity()
	if progression.save_blocked:
		_open_document("Guardado protegido", "Tu archivo original sigue intacto.", progression.load_notice + "\n\nRuta: " + save_path + "\n\nRevisa la copia de seguridad antes de volver a abrir el juego.")
		save_notice.text = "Guardado protegido · consulta el aviso"
		fight_button.disabled = true
	elif progression.data.is_empty():
		_show_creation()
	else:
		_prepare_rival()
		_refresh_manager()
		_update_portraits()
		if not progression.load_notice.is_empty():
			feed_label.text = progression.load_notice
	_restore_audio_environment()
	if args.has("--smoke-test"):
		_run_smoke_test()
	elif args.has("--online") or (session_save_path=="user://brasa_save.json" and OnlineApiScript.SessionStore.has_session_hint()):
		_open_online()
	elif not progression.data.is_empty() and not progression.save_blocked:
		_show_menu.call_deferred()

func _open_online() -> void:
	if active_match or is_instance_valid(online_layer): return
	_close_modal()
	_close_roster()
	_close_story_panel()
	_close_replays()
	if is_instance_valid(customization_layer):
		customization_layer.queue_free()
		customization_layer = null
	if not is_instance_valid(online_api):
		online_api = OnlineApiScript.new()
		add_child(online_api)
		if not online_api.configure_from_file():
			_open_document("Arena online", "No se pudo leer la configuración.", "El servidor configurado no es válido.")
			return
	online_layer = OnlinePanelScript.new()
	add_child(online_layer)
	online_layer.closed.connect(_close_online)
	online_layer.configure(online_api)

func _close_online() -> void:
	if is_instance_valid(online_api): online_api.cancel_auth()
	if is_instance_valid(online_layer): online_layer.queue_free()
	online_layer = null
	_restore_audio_environment()
	if progression.data.is_empty(): _show_creation()

func _initialize_identity() -> void:
	if identity_loaded: return
	if not story_loaded:
		story_progression.load_save(session_save_path + ".story.json")
		story_loaded = true
	fighter_identity.load_save(session_save_path + ".identity.json")
	fighter_identity.migrate_legacy(league_progression.roster, story_progression.roster)
	identity_loaded = true

func _fighter_definition(id: String) -> Dictionary:
	var definition: Dictionary = Catalog.definition(id)
	if definition.is_empty() or not identity_loaded: return definition
	definition["character_id"] = id
	definition["base_name"] = str(definition.name)
	return fighter_identity.decorate(definition)

func _fighter_definitions() -> Array:
	var definitions: Array = []
	for id: String in Catalog.IDS: definitions.append(_fighter_definition(id))
	return definitions

func _display_name(profile: Dictionary) -> String:
	if not identity_loaded: return str(profile.get("name", "Compañero"))
	return str(fighter_identity.decorate(profile).get("name", profile.get("name", "Compañero")))

func _player_combatant() -> Dictionary:
	var descriptor: Dictionary = progression.active_combatant()
	return fighter_identity.decorate(descriptor) if identity_loaded else descriptor

func _open_customization(id: String = "", creating: bool = false) -> void:
	if active_match or is_instance_valid(customization_layer) or is_instance_valid(replay_layer): return
	_initialize_identity()
	if fighter_identity.save_blocked:
		_close_roster()
		_close_story_panel()
		_open_document("Identidad protegida", "Tu progreso de combate sigue disponible.", fighter_identity.load_notice)
		return
	var chosen := id if not id.is_empty() else str(progression.data.get("character_id", "nima"))
	fighter_identity.grant_from_progress(league_progression.roster, story_progression.roster)
	_customization_return = "story" if is_instance_valid(story_layer) else ("roster" if is_instance_valid(creation_layer) and not creating else "")
	if is_instance_valid(story_layer): story_layer.hide()
	_close_roster()
	customization_layer = CustomizationPanel.new()
	add_child(customization_layer)
	customization_layer.configure(fighter_identity, chosen, creating)
	customization_layer.confirmed.connect(_confirm_customization.bind(creating))
	customization_layer.cancelled.connect(_cancel_customization)

func _confirm_customization(id: String, fighter_name: String, appearance: Dictionary, creating: bool) -> void:
	var result: Dictionary = fighter_identity.update_fighter(id, fighter_name, appearance)
	if not bool(result.get("ok", false)):
		customization_layer.set_error(str(result.get("error", "No se pudo guardar la identidad.")))
		return
	if creating:
		var prior_roster: Dictionary = progression.roster.duplicate(true)
		var prior_id: String = progression.active_id
		if not progression.select_character(id) or not progression.last_save_ok:
			progression.roster = prior_roster
			progression.active_id = prior_id
			progression.data = prior_roster.get(prior_id, {})
			customization_layer.set_error("La apariencia se guardó, pero no pudimos iniciar el progreso. Puedes volver a intentarlo.")
			return
	_close_customization()
	if creating:
		_reset_mode_view()
		_enter_story()
		_choose_story_character(id)
	elif not progression.data.is_empty():
		_refresh_manager()
		if not result_panel.visible: _update_portraits()
	_play_sound("upgrade")

func _close_customization() -> void:
	if is_instance_valid(customization_layer): customization_layer.queue_free()
	customization_layer = null
	if _customization_return == "story" and is_instance_valid(story_layer):
		story_layer.show()
		story_layer.refresh()
		story_layer.show_tab("companions")
	elif _customization_return == "roster": _show_roster()
	_customization_return = ""

func _cancel_customization() -> void:
	_close_customization()
	if progression.data.is_empty(): _show_roster(true)

func _grant_cosmetics() -> void:
	if not identity_loaded or not progression.last_save_ok: return
	var unlocked: Array = fighter_identity.grant_from_progress(league_progression.roster, story_progression.roster)
	if not unlocked.is_empty():
		last_reward["cosmetics_unlocked"] = unlocked.duplicate()
		_log_event("Nuevos cosméticos disponibles en Personalizar.")

func _current_stats(profile: Dictionary) -> Dictionary:
	return StoryCatalog.stats_for(profile) if story_mode else Catalog.stats_for(profile)

func _rival_definition() -> Dictionary:
	var definition: Dictionary = Catalog.definition(str(rival.get("character_id","")))
	if definition.is_empty(): definition = StoryCatalog.boss_definition(int(rival.get("story_chapter_id",1)))
	for key: String in ["ability","signature","visual"]:
		if rival.has(key): definition[key] = rival[key].duplicate(true)
	definition["name"] = str(rival.get("name",definition.get("name","Rival")))
	definition["role"] = str(rival.get("title",definition.get("role","Guardián de la liga")))
	return definition

func _primary_action() -> void:
	if is_instance_valid(customization_layer) or is_instance_valid(replay_layer): return
	if is_instance_valid(story_layer) or is_instance_valid(modal_layer) or is_instance_valid(creation_layer): return
	if story_mode: _show_story_panel("legacy" if progression.is_complete() else "route")
	else: _start_fight()

func _enter_story(character_id: String = "") -> void:
	if is_instance_valid(customization_layer) or is_instance_valid(replay_layer): return
	if active_match or is_instance_valid(modal_layer) or is_instance_valid(creation_layer): return
	if not story_loaded:
		var path := session_save_path
		if path.is_empty(): path = "user://brasa_save.json"
		story_progression.load_save(path+".story.json")
		story_loaded = true
	if story_progression.save_blocked:
		_open_document("Historia protegida","Tu archivo original sigue intacto.",story_progression.load_notice)
		return
	# A menu invitation belongs to the selected fighter, not the last campaign opened.
	if not character_id.is_empty() and story_progression.active_id != character_id:
		var prior_roster: Dictionary = story_progression.roster.duplicate(true)
		var prior_id: String = story_progression.active_id
		var prior_replay: int = story_progression._replay_level
		if not story_progression.select_character(character_id) or not story_progression.last_save_ok:
			story_progression.roster = prior_roster
			story_progression.active_id = prior_id
			story_progression.data = prior_roster.get(prior_id,{})
			story_progression._replay_level = prior_replay
			_open_document("Historia protegida","No pudimos abrir esta historia.","Tu progreso anterior sigue intacto. Puedes volver a intentarlo.")
			return
	if not story_mode:
		league_progression = progression
		progression = story_progression
		story_mode = true
		_reset_mode_view()
	_show_story_panel()

func _show_story_panel(tab_id: String = "") -> void:
	if active_match or not story_mode or is_instance_valid(modal_layer) or is_instance_valid(creation_layer): return
	if not is_instance_valid(story_layer):
		story_layer = StoryPanel.new()
		add_child(story_layer)
		story_layer.character_chosen.connect(_choose_story_character)
		story_layer.upgrade_requested.connect(_upgrade_story_stat)
		story_layer.fight_requested.connect(_start_story_battle)
		story_layer.next_chapter_requested.connect(_start_next_story_chapter)
		story_layer.upgrade_move_requested.connect(_upgrade_story_move)
		story_layer.perk_chosen.connect(_choose_story_perk)
		story_layer.replay_requested.connect(_replay_story_battle)
		story_layer.respec_requested.connect(_respec_story_build)
		story_layer.league_requested.connect(_leave_story)
		story_layer.closed.connect(_close_story_panel)
		story_layer.customize_requested.connect(_open_customization)
		story_layer.identity_store = fighter_identity if identity_loaded else null
		for id: String in league_progression.roster:
			story_layer.arena_wins_by_character[id] = int(league_progression.roster[id].get("wins", 0))
		story_layer.configure(story_progression)
	else: story_layer.refresh()
	if not tab_id.is_empty(): story_layer.show_tab(tab_id)

func _close_story_panel() -> void:
	if is_instance_valid(story_layer): story_layer.queue_free()
	story_layer = null
	if story_mode and progression.data.is_empty(): _leave_story()

func _choose_story_character(id: String) -> void:
	if active_match or not story_mode: return
	if progression.select_character(id):
		if identity_loaded: fighter_identity.migrate_legacy(league_progression.roster, story_progression.roster)
		_reset_mode_view()
		if is_instance_valid(story_layer): story_layer.refresh()
		_play_sound("start")

func _upgrade_story_stat(key: String) -> void:
	if active_match or not story_mode: return
	if progression.upgrade(key):
		_refresh_manager()
		if not result_panel.visible: _update_portraits()
		if is_instance_valid(story_layer): story_layer.refresh()
		_play_sound("upgrade")

func _upgrade_story_move(move_id: String) -> void:
	if active_match or not story_mode: return
	if progression.upgrade_move(move_id):
		_play_sound("upgrade")
	if is_instance_valid(story_layer): story_layer.refresh()

func _choose_story_perk(perk_id: String) -> void:
	if active_match or not story_mode: return
	if progression.choose_perk(perk_id):
		_play_sound("upgrade")
	if is_instance_valid(story_layer): story_layer.refresh()

func _replay_story_battle(global_level: int) -> void:
	if active_match or not story_mode or progression.save_blocked: return
	if progression.select_replay(global_level):
		_reset_mode_view()
		_close_story_panel()
		_start_fight()

func _respec_story_build() -> void:
	if active_match or not story_mode or progression.save_blocked: return
	if progression.respec_build():
		_refresh_manager()
		if not result_panel.visible: _update_portraits()
		_play_sound("upgrade")
	if is_instance_valid(story_layer): story_layer.refresh()

func _start_next_story_chapter() -> void:
	if active_match or not story_mode or progression.save_blocked: return
	if progression.start_next_chapter():
		_reset_mode_view()
		if is_instance_valid(story_layer):
			story_layer.refresh()
			story_layer.show_tab("route")
		_play_sound("start")
	elif is_instance_valid(story_layer):
		story_layer.refresh()

func _story_round_text() -> String:
	var chapter: int = progression.current_chapter()
	return "CAP. %d · HISTORIA %d / %d" % [int(rival.get("story_chapter_id", chapter)), int(rival.get("story_level", progression.global_level())), StoryCatalog.total_encounters()]

func _sync_arena_background() -> void:
	var chapter: int = int(rival.get("story_chapter_id", progression.current_chapter())) if story_mode else 1
	var path: String = StoryCatalog.chapter(chapter).background if story_mode else ArenaScript.DEFAULT_BACKGROUND
	arena.set_background(path)

func _start_story_battle() -> void:
	if not story_mode or progression.data.is_empty() or progression.is_complete(): return
	if progression.seconds_until_next_match() > 0 or progression.save_blocked:
		if is_instance_valid(story_layer): story_layer.refresh()
		return
	progression.clear_replay()
	_prepare_rival()
	_close_story_panel()
	_start_fight()

func _leave_story() -> void:
	if active_match: return
	story_mode = false
	_close_story_panel()
	progression = league_progression
	_reset_mode_view()
	if progression.data.is_empty(): _show_creation()

func _reset_mode_view() -> void:
	result_panel.hide()
	summary_button.hide()
	surrender_button.hide()
	_close_signature_banner()
	last_reward = {}
	last_battle_summary = {}
	battle_log.clear()
	feed.clear()
	feed_label.text = str(StoryCatalog.chapter(progression.current_chapter()).title) if story_mode else "La liga te espera."
	_sync_arena_background()
	finishing = false
	arena.combat_active = false
	arena.winner_side = ""
	match_generation += 1
	round_label.text = "HISTORIA" if story_mode else "PATIO DE LOS FAROLES"
	timer_label.text = "VS"
	if not progression.data.is_empty():
		_prepare_rival()
		_refresh_manager()
		_update_portraits()
	_layout_interface(_layout_size)

func _layout_story_result(short: bool) -> void:
	var xp := int(last_reward.get("xp_gained",last_reward.get("player",{}).get("xp_gained",0)))
	var levels := int(last_reward.get("levels_gained",0))
	var hint := str(last_reward.get("hint",""))
	var cleared := bool(last_reward.get("advanced",false))
	var completed := bool(last_reward.get("completed",false))
	var title := "CAPÍTULO %d COMPLETADO" % progression.current_chapter() if completed else ("¡VICTORIA!" if cleared else ("RENDICIÓN" if str(last_battle_summary.get("reason",""))=="surrender" else "DERROTA"))
	if bool(last_reward.get("campaign_completed", false)): title = "¡HISTORIA COMPLETADA!"
	var continuation := ("Capítulo %d desbloqueado · Continúa desde Logros." % (progression.current_chapter()+1) if progression.can_start_next_chapter() else "Tu insignia y tu recorrido te esperan en Logros.") if completed else ("Nuevo encuentro disponible · Continúa tu ruta." if cleared else "Tu progreso se conserva. Puedes volver a intentarlo.")
	if bool(last_reward.get("replay", false)):
		title = "REPETICIÓN · " + ("VICTORIA" if str(last_battle_summary.get("winner", "")) == "player" else "DERROTA")
		continuation = "Práctica completada · Vuelve a tu ruta cuando quieras."
	if not hint.is_empty(): continuation = hint
	var unlocks: Array[String] = _new_story_moves()
	if not unlocks.is_empty(): continuation = "Nuevo movimiento: %s · Detalles en Movimientos." % ", ".join(unlocks)
	elif int(progression.data.get("perk_points", 0)) > 0: continuation = "Ventaja disponible · Elige tu estilo en Movimientos."
	var progress := "+%d XP" % xp
	if levels > 0: progress += " · ¡Nivel %d! · +%d puntos" % [int(progression.data.level),int(last_reward.get("player",{}).get("points_gained",levels*3))]
	var compact_progress := "+%d XP" % xp
	if levels > 0: compact_progress += " · Nv. %d" % int(progression.data.level)
	result_title.text = title + (" · "+compact_progress if short else "")
	result_copy.text = continuation if short else progress+"\n"+continuation
	result_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_copy.tooltip_text = progress+"\n"+continuation
	result_copy.mouse_filter = Control.MOUSE_FILTER_PASS

func _new_story_moves() -> Array[String]:
	var names: Array[String] = []
	if not story_mode: return names
	var reward: Dictionary = last_reward.get("player", {})
	for move: Dictionary in Moves.moves_for(str(progression.active_id)):
		if int(move.unlock_level) > int(reward.get("level_before", progression.data.level)) and int(move.unlock_level) <= int(reward.get("level_after", progression.data.level)):
			names.append(str(move.name))
	return names

func _build_theme() -> void:
	theme = Visuals.theme()

func _panel(parent: Node, rect: Rect2, color: Color = SURFACE, radius: int = 16) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new() if color.a == 0 else Visuals.panel("standard"))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel

func _label(parent: Node, content: String, rect: Rect2, font_size: int = 17, color: Color = CREAM, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = content
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_font_override("font",Visuals.font("card" if font_size >= 20 else "body"))
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	parent.add_child(label)
	return label

func _button(parent: Node, content: String, rect: Rect2, callback: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = content
	button.clip_text = true
	button.position = rect.position
	button.size = rect.size
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	Visuals.apply_button(button,"primary" if primary else "secondary")
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _bar(parent: Node, rect: Rect2, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = rect.position
	bar.size = rect.size
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background_style := Visuals.rail()
	var fill_style := Visuals.rail("current",true)
	fill_style.bg_color = color
	bar.add_theme_stylebox_override("background", background_style)
	bar.add_theme_stylebox_override("fill", fill_style)
	parent.add_child(bar)
	# Apply the requested height after removing the default percentage minimum.
	bar.size = rect.size
	return bar

func _build_interface() -> void:
	arena = ArenaScript.new()
	add_child(arena)
	player_view = FighterScript.new()
	rival_view = FighterScript.new()
	arena.add_child(player_view)
	arena.add_child(rival_view)
	combat_fx = CombatFXScript.new()
	arena.add_child(combat_fx)
	player_view.setup(0, COLORS[0], 1)
	rival_view.setup(2, COLORS[2], -1)
	top_gradient = _make_gradient(false)
	bottom_gradient = _make_gradient(true)
	brand_label = _label(self, "BRASA  /  ARENA", Rect2(), 28)
	menu_button = _button(self, "Menú", Rect2(), _show_menu)
	story_button = _button(self, "Historia", Rect2(), _enter_story)
	story_button.add_theme_color_override("font_color", GOLD)
	player_hud = CombatantHUD.new()
	rival_hud = CombatantHUD.new()
	add_child(player_hud)
	add_child(rival_hud)
	player_hud.configure(false)
	rival_hud.configure(true)
	player_name_label = player_hud.name_label
	rival_name_label = rival_hud.name_label
	player_level_label = player_hud.level_label
	rival_level_label = rival_hud.level_label
	player_bar = player_hud.bar
	rival_bar = rival_hud.bar
	player_hp_label = player_hud.hp_label
	rival_hp_label = rival_hud.hp_label
	player_status_label = _label(self, "", Rect2(), 13, TEAL)
	rival_status_label = _label(self, "", Rect2(), 13, CORAL, HORIZONTAL_ALIGNMENT_RIGHT)
	for label: Label in [player_status_label, rival_status_label]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		label.add_theme_color_override("font_outline_color", DARK)
		label.add_theme_constant_override("outline_size", 4)
	round_label = _label(self, "PATIO DE LOS FAROLES", Rect2(), 12, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	timer_label = _label(self, "VS", Rect2(), 24, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	timer_label.add_theme_font_override("font",Visuals.font("number"))
	state_label = _label(self, "Prepara a tu compañero", Rect2(), 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	progress_label = _label(self, "Tu historia empieza aquí", Rect2(), 18)
	progress_xp_label = _label(self, "", Rect2(), 12, MUTED)
	progress_bar = _bar(self, Rect2(), GOLD)
	feed_label = _label(self, "La liga te espera.", Rect2(), 13, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	fight_button = _button(self, "Entrar a la arena  →", Rect2(), _primary_action, true)
	fight_button.add_theme_font_size_override("font_size", 20)
	fight_button.add_theme_stylebox_override("disabled", Visuals.World.surface("primary","disabled"))
	fight_button.add_theme_color_override("font_disabled_color", CREAM)
	training_button = _button(self, "Entrenar", Rect2(), _show_training)
	roster_button = _button(self, "Compañeros", Rect2(), _show_roster)
	log_button = _button(self, "Registro", Rect2(), _show_log)
	speed_button = _button(self, "Ritmo ×1", Rect2(), _toggle_speed)
	surrender_button = _button(self, "Rendirse", Rect2(), _confirm_surrender)
	Visuals.apply_button(surrender_button,"danger")
	
	surrender_button.hide()
	summary_button = _button(self, "Resumen", Rect2(), _show_summary)
	summary_button.hide()
	status_label = _label(self, "Tú entrenas. Tu compañero pelea.", Rect2(), 12, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	save_notice = _label(self, "Progreso guardado", Rect2(), 11, MUTED)
	# Compatibility fields also power the menu and training drawer.
	record_label = _label(self, "", Rect2(), 14, MUTED)
	record_label.hide()
	rival_card_name = _label(self, "", Rect2(), 18)
	rival_card_info = _label(self, "", Rect2(), 14)
	rival_card_stats = _label(self, "", Rect2(), 14)
	for label: Label in [rival_card_name, rival_card_info, rival_card_stats]: label.hide()
	_build_manager()
	result_veil = ColorRect.new()
	result_veil.color = Color(0.015,0.025,0.03,0.38)
	result_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(result_veil)
	result_veil.hide()
	result_panel = BattleResultPanel.new()
	add_child(result_panel)
	for button: Button in [fight_button, menu_button, training_button, roster_button, summary_button]:
		move_child(button,get_child_count()-1)
	result_title = result_panel.title_label
	result_copy = result_panel.copy_label
	result_panel.hide()

func _make_gradient(bottom: bool) -> TextureRect:
	var rect := Visuals.battle_veil(bottom)
	add_child(rect)
	return rect

func _build_manager() -> void:
	training_content = Control.new()
	training_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(training_content)
	training_content.hide()
	manager_label = _label(training_content, "", Rect2(), 20)
	points_label = _label(training_content, "", Rect2(), 14, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	xp_label = _label(training_content, "", Rect2(), 13, MUTED)
	xp_bar = _bar(training_content, Rect2(), GOLD)
	training_notice = _label(training_content,"",Rect2(),13,MUTED)
	training_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for i in range(4):
		var card := Panel.new()
		card.add_theme_stylebox_override("panel",Visuals.training_card())
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		training_content.add_child(card)
		stat_cards.append(card)
		stat_titles.append(_label(card, STAT_NAMES[i], Rect2(), 18))
		stat_values.append(_label(card, "0", Rect2(), 24, TEAL, HORIZONTAL_ALIGNMENT_RIGHT))
		stat_effects.append(_label(card, "", Rect2(), 13, MUTED))
		var key: String = STAT_KEYS[i]
		stat_buttons.append(_button(card, "Mejorar · 1 punto", Rect2(), func(): _upgrade(key)))
		stat_buttons[i].add_theme_stylebox_override("focus",StyleBoxEmpty.new())
		stat_deltas.append(_label(card,"",Rect2(),13,TEAL))
		var index := i
		var info := Button.new()
		info.text = "?"
		info.toggle_mode = true
		info.tooltip_text = "Qué mejora " + STAT_NAMES[i]
		Visuals.apply_button(info,"icon")
		card.add_child(info)
		stat_help_buttons.append(info)
		info.pressed.connect(func(): _toggle_training_detail(index))
		var explanation := _label(card,TRAINING_DESCRIPTIONS[i],Rect2(),13,MUTED)
		explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		explanation.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		explanation.hide()
		stat_descriptions.append(explanation)
		card.mouse_entered.connect(func(): _training_card_state(index,true))
		card.mouse_exited.connect(func(): _training_card_state(index,false))
		stat_buttons[i].focus_entered.connect(func(): _training_card_state(index,true))
		stat_buttons[i].focus_exited.connect(func(): _training_card_state(index,false))
		info.focus_entered.connect(func(): _training_card_state(index,true))
		info.focus_exited.connect(func(): _training_card_state(index,false))
	_layout_training(800)

func _place(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size

func _layout_interface(view_size: Vector2 = Vector2.ZERO) -> void:
	if not is_instance_valid(arena): return
	var view := view_size if view_size != Vector2.ZERO else get_viewport_rect().size
	_layout_size = view
	layout_rects = Layout.calculate(view, active_match, result_panel.visible)
	var r := layout_rects
	var phone: bool = r.phone
	var short: bool = r.short
	var w: float = r.viewport.size.x
	var h: float = r.viewport.size.y
	arena.set_viewport_size(r.viewport.size)
	arena.position = Vector2.ZERO
	if is_instance_valid(approach_tween): approach_tween.kill()
	player_view.scale = Vector2.ONE * float(r.actor_scale)
	rival_view.scale = player_view.scale
	player_view.position = r.player_at
	rival_view.position = r.rival_at
	var lane_limit: float = (r.rival_at.x-r.player_at.x)/(2.0*float(r.actor_scale))-6.0
	player_view.set_combat_lane(lane_limit, rival_view)
	rival_view.set_combat_lane(lane_limit, player_view)
	_place(top_gradient, Rect2(0,0,w,230 if not short else 152))
	_place(bottom_gradient, Rect2(0,h-(340 if phone else (190 if short else 340)),w,340 if not short else 190))
	brand_label.hide()
	story_button.hide()
	_place(menu_button,r.menu)
	_place(player_hud,r.hud_player)
	_place(rival_hud,r.hud_rival)
	var center: Rect2 = r.center
	_place(round_label,Rect2(center.position,Vector2(center.size.x,20)))
	_place(timer_label,Rect2(center.position+Vector2(0,22),Vector2(center.size.x,32)))
	_place(state_label,Rect2(center.position+Vector2(0,57),Vector2(center.size.x,30)))
	if phone:
		_place(timer_label,Rect2(center.position,Vector2(center.size.x,28)))
		_place(state_label,Rect2(center.position+Vector2(0,30),Vector2(center.size.x,24)))
		round_label.hide()
	else: round_label.show()
	state_label.add_theme_font_size_override("font_size",12 if short else 14)
	for pair: Array in [[fight_button,"primary"],[training_button,"training"],[roster_button,"roster"],[speed_button,"speed"],[log_button,"log"],[surrender_button,"surrender"],[summary_button,"log"]]:
		_place(pair[0],r[pair[1]])
		pair[0].add_theme_font_size_override("font_size",14 if phone or short else 16)
	fight_button.add_theme_font_size_override("font_size",18 if phone or short else 20)
	fight_button.visible = not active_match
	roster_button.text = "Equipo" if phone or short else "Compañeros"
	if not progression.data.is_empty():
		training_button.text = "Entrenar" if phone or short else "Entrenar · %d" % int(progression.data.points)
		if phone and not active_match:
			progress_label.text = "%d XP total · %d puntos para entrenar" % [int(progression.data.get("total_xp",0)),progression.data.points] if progression.xp_needed() <= 0 else "%d / %d XP · %d puntos para entrenar" % [progression.data.xp,progression.xp_needed(),progression.data.points]
	training_button.visible = not (active_match and (phone or short or w<1000))
	roster_button.visible = training_button.visible
	speed_button.visible = not phone or active_match
	log_button.visible = not result_panel.visible and not active_match
	if phone: log_button.visible = not result_panel.visible
	if w<1000 and not phone and not short and active_match: roster_button.hide()
	progress_label.visible = not short and not result_panel.visible and not active_match
	progress_xp_label.visible = not phone and not short and not active_match and not result_panel.visible
	progress_bar.visible = progress_xp_label.visible
	_place(progress_label,Rect2(r.progress.position,Vector2(r.progress.size.x,28)))
	_place(progress_xp_label,Rect2(r.progress.position+Vector2(0,30),Vector2(r.progress.size.x,24)))
	_place(progress_bar,Rect2(r.progress.position+Vector2(0,61),Vector2(r.progress.size.x,3)))
	_place(feed_label,r.feed)
	feed_label.visible = not result_panel.visible and not is_instance_valid(signature_banner)
	_place(status_label,Rect2(w/2-minf(280,w/2-16),r.primary.end.y+8 if result_panel.visible else h-36,minf(560,w-32),24))
	status_label.visible = (status_label.text.begins_with("La arena se prepara") or status_label.text.begins_with("No se pudo")) if result_panel.visible else (not phone and not short)
	_place(save_notice,Rect2(r.pad,h-28,300,18))
	save_notice.visible = not phone and not short and w>=1180
	# Result and continuation form one centered group above the completed scene.
	_place(result_panel,r.result)
	_place(result_veil,Rect2(Vector2.ZERO,view))
	result_veil.visible = result_panel.visible
	if result_panel.visible:
		round_label.hide()
		timer_label.hide()
		state_label.hide()
	else:
		timer_label.show()
		state_label.show()
	result_panel.layout_compact(short,phone)
	if result_panel.visible:
		result_panel.configure_progress(xp_bar.value,xp_bar.max_value)
	if result_panel.visible and short and not last_reward.is_empty():
		result_copy.text = "Tú +%d XP · Rival +%d XP%s" % [int(last_reward.get("xp_gained",0)),int(last_reward.get("rival",{}).get("xp_gained",0))," · ¡Nivel %d!" % int(progression.data.level) if int(last_reward.get("levels_gained",0))>0 else ""]
	elif result_panel.visible and not last_reward.is_empty():
		result_copy.text = "Tu compañero +%d XP · Rival +%d XP\n%s" % [int(last_reward.get("xp_gained",0)),int(last_reward.get("rival",{}).get("xp_gained",0)),"¡Subes al nivel %d! · Consulta tus mejoras en Resumen" % int(progression.data.level) if int(last_reward.get("levels_gained",0))>0 else "Entrena, cambia de compañero o vuelve a la arena."]
	if story_mode and result_panel.visible and not last_reward.is_empty():
		_layout_story_result(short)
	_position_statuses()
	if is_instance_valid(signature_banner):
		_place(signature_banner,r.signature)
		signature_banner.add_theme_font_size_override("font_size",16 if phone or short else 23)
	if is_instance_valid(modal_layer): _layout_modal()
	arena.set_active_fighter(_last_active_side if active_match else "",player_view.position,rival_view.position,float(r.actor_scale))

func _position_statuses() -> void:
	if layout_rects.is_empty(): return
	var r := layout_rects
	var width: float = minf(290,(r.viewport.size.x-48)/2)
	var y: float = float(r.floor) + 8
	if result_panel.visible and not r.short and r.viewport.size.x >= 1000:
		_place(player_status_label,Rect2(r.hud_player.position+Vector2(0,r.hud_player.size.y+8),Vector2(width,40)))
		_place(rival_status_label,Rect2(r.hud_rival.position+Vector2(0,r.hud_rival.size.y+8),Vector2(width,40)))
		return
	if r.short:
		_place(player_status_label,Rect2(r.hud_player.position+Vector2(0,r.hud_player.size.y+8),Vector2(r.hud_player.size.x,42)))
		_place(rival_status_label,Rect2(r.hud_rival.position+Vector2(0,r.hud_rival.size.y+8),Vector2(r.hud_rival.size.x,42)))
		return
	_place(player_status_label,Rect2(maxf(16,player_view.position.x-width/2-24),y,width,40))
	_place(rival_status_label,Rect2(minf(r.viewport.size.x-width-16,rival_view.position.x-width/2+24),y,width,40))
	player_status_label.add_theme_font_size_override("font_size",12 if r.phone or r.short else 13)
	rival_status_label.add_theme_font_size_override("font_size",12 if r.phone or r.short else 13)

func _refresh_manager() -> void:
	if progression.data.is_empty():
		return
	var data: Dictionary = progression.data
	var stats: Dictionary = data.stats
	var detail: Dictionary = _current_stats(data)
	manager_label.text = "%s  ·  Nivel %d" % [_display_name(data), data.level]
	points_label.text = "%d %s" % [data.points,"punto" if int(data.points)==1 else "puntos"]
	points_label.add_theme_color_override("font_color",GOLD if int(data.points)>0 else MUTED)
	training_notice.text = "Gana experiencia en combate para obtener más puntos." if int(data.points)<=0 else "Cada mejora cuesta 1 punto."
	if progression.save_blocked: training_notice.text = "El guardado está protegido. No se pueden aplicar mejoras."
	training_notice.add_theme_color_override("font_color",CORAL if progression.save_blocked else MUTED)
	var needed: int = 0 if int(data.level) >= BalanceConfig.MAX_LEVEL else progression.xp_needed()
	xp_label.text = "Nivel máximo · XP acumulada" if needed <= 0 else "%d / %d XP   ·   +%d puntos al subir" % [data.xp, needed, StoryCatalog.points_for_level(int(data.level)+1) if story_mode else BalanceConfig.POINTS_PER_LEVEL]
	xp_bar.max_value = maxi(1, needed)
	xp_bar.value = data.xp if needed > 0 else 1
	record_label.text = "%d victorias · %d derrotas\nRacha %d · Mejor %d" % [data.wins, data.losses, data.get("streak", 0), data.get("best_streak", 0)]
	save_notice.text = "Progreso guardado en este Mac" if progression.last_save_ok else "No se pudo guardar · consulta la ayuda"
	save_notice.add_theme_color_override("font_color", MUTED if progression.last_save_ok else CORAL)
	save_notice.tooltip_text = progression.load_notice
	save_notice.mouse_filter = Control.MOUSE_FILTER_PASS
	roster_button.disabled = active_match or progression.save_blocked
	training_button.disabled = active_match or progression.save_blocked
	training_button.text = "Entrenar" if active_match else "Entrenar · %d" % int(data.points)
	training_button.tooltip_text = "Disponible al terminar la pelea" if active_match else "Reparte tus puntos de mejora"
	roster_button.tooltip_text = "Disponible al terminar la pelea" if active_match else "%d compañeros, cada uno con su progreso" % Catalog.IDS.size()
	progress_label.text = "" if active_match else "%s · Nivel %d" % [_display_name(data),data.level]
	progress_xp_label.text = "%d XP total · %d puntos para entrenar" % [int(data.get("total_xp",0)),data.points] if needed <= 0 else "%d / %d XP · %d puntos para entrenar" % [data.xp,needed,data.points]
	progress_bar.max_value = xp_bar.max_value
	progress_bar.value = xp_bar.value
	for i in range(4):
		stat_values[i].text = str(stats[STAT_KEYS[i]])
		stat_buttons[i].disabled = active_match or progression.save_blocked or int(data.points) <= 0 or int(stats[STAT_KEYS[i]]) >= BalanceConfig.TRAINING_CAP
		if stat_buttons[i].disabled and stat_buttons[i].has_focus():
			if modal_kind=="training": stat_help_buttons[i].grab_focus()
			else: stat_buttons[i].release_focus()
		stat_buttons[i].text = "Al máximo" if int(stats[STAT_KEYS[i]]) >= BalanceConfig.TRAINING_CAP else "Mejorar · 1 punto"
	stat_effects[0].text = "%d PV de vida" % int(detail.max_hp)
	stat_effects[1].text = "%.1f de ataque" % float(detail.attack)
	stat_effects[2].text = "%.1f%% evasión · %.1f%% crítico" % [float(detail.evasion)*100,float(detail.crit_chance)*100]
	stat_effects[3].text = "Un ataque cada %.2f s" % float(detail.interval)
	for i in range(4):
		var preview: Dictionary = data.duplicate(true)
		preview.stats[STAT_KEYS[i]] = mini(BalanceConfig.TRAINING_CAP,int(stats[STAT_KEYS[i]])+1)
		var after: Dictionary = _current_stats(preview)
		var gain := ""
		match i:
			0: gain = "+%d PV" % roundi(float(after.max_hp)-float(detail.max_hp))
			1: gain = "+%.1f de ataque" % (float(after.attack)-float(detail.attack))
			2: gain = "%.1f%% evasión · %.1f%% crítico" % [float(after.evasion)*100,float(after.crit_chance)*100]
			3: gain = "%.2f s entre ataques" % float(after.interval)
		stat_deltas[i].text = "Próxima: " + gain
		if int(stats[STAT_KEYS[i]])>=BalanceConfig.TRAINING_CAP: stat_deltas[i].text = "Atributo al máximo"
		stat_buttons[i].tooltip_text = "Un punto de %s: %s" % [STAT_NAMES[i],gain]
		stat_descriptions[i].text = TRAINING_DESCRIPTIONS[i]
	if not active_match and not result_panel.visible:
		_set_health(float(detail.max_hp), float(detail.max_hp), true)

func _prepare_rival() -> void:
	rival = progression.make_rival()
	if rival.is_empty() and story_mode:
		rival = StoryCatalog.opponent(StoryCatalog.stages(progression.current_chapter()).size()-1,progression.current_chapter())
	if rival.is_empty(): return
	var definition: Dictionary = _rival_definition()
	rival_card_name.text = str(rival.name)
	rival_card_info.text = "%s  ·  Nivel %d" % [str(definition.role), int(rival.level)]
	var stats: Dictionary = rival.combat_stats
	rival_card_stats.text = "%d vida · %.1f ataque · %s" % [int(stats.max_hp), float(stats.attack), str(definition.ability.name)]
	rival_card_stats.add_theme_font_size_override("font_size", 12)
	rival_card_stats.mouse_filter = Control.MOUSE_FILTER_PASS
	rival_card_stats.tooltip_text = str(definition.ability.description)
	fight_button.disabled = false
	fight_button.text = "Entrar a la arena  →"
	status_label.text = "Rivales de nivel y poder similares · ataques automáticos"
	if story_mode:
		fight_button.text = "Ver legado  →" if progression.is_complete() else "Ver encuentro  →"
		status_label.text = "Historia · Capítulo %d · %s" % [progression.current_chapter(),StoryCatalog.chapter(progression.current_chapter()).title]

func _update_portraits() -> void:
	_sync_arena_background()
	player_view.setup_character(_fighter_definition(str(progression.data.character_id)), 1)
	player_view.reset_pose()
	rival_view.setup_character(_rival_definition(), -1)
	rival_view.reset_pose()
	_layout_interface(_layout_size)
	player_name_label.text = _display_name(progression.data)
	rival_name_label.text = str(rival.name)
	player_level_label.text = "NIVEL %d" % int(progression.data.level)
	rival_level_label.text = "NIVEL %d" % int(rival.level)
	var pdetail: Dictionary = _current_stats(progression.data)
	var rdetail: Dictionary = rival.combat_stats
	_set_health(float(pdetail.max_hp), float(pdetail.max_hp), true)
	_set_health(float(rdetail.max_hp), float(rdetail.max_hp), false)
	player_status_label.text = ""
	rival_status_label.text = ""
	state_label.text = "TODO LISTO"
	if story_mode:
		round_label.text = _story_round_text()
		timer_label.text = "VS"

func _set_health(value: float, maximum: float, is_player: bool) -> void:
	var bar := player_bar if is_player else rival_bar
	var label := player_hp_label if is_player else rival_hp_label
	bar.max_value = maximum
	bar.value = maxf(0, value)
	label.text = "%d / %d" % [int(ceil(maxf(0, value))), int(maximum)]
	label.tooltip_text = label.text + " de vida"

func _upgrade(stat: String) -> void:
	if active_match:
		return
	if progression.upgrade(stat):
		_refresh_manager()
		var index := STAT_KEYS.find(stat)
		if index>=0:
			training_notice.text = "%s mejorada · %d %s restantes" % [STAT_NAMES[index],int(progression.data.points),"punto" if int(progression.data.points)==1 else "puntos"]
			training_notice.add_theme_color_override("font_color",TEAL)
			if not progression.last_save_ok:
				training_notice.text = "Mejora aplicada, pero no pudo guardarse."
				training_notice.add_theme_color_override("font_color",CORAL)
		_layout_interface(_layout_size)
		_play_sound("upgrade")
		status_label.text = "Mejora aplicada. Tu próximo combate empieza al máximo."

func _start_fight() -> void:
	if is_instance_valid(online_layer) or is_instance_valid(customization_layer) or is_instance_valid(replay_layer): return
	if active_match or progression.save_blocked or progression.data.is_empty() or is_instance_valid(creation_layer) or is_instance_valid(modal_layer) or is_instance_valid(story_layer):
		return
	if story_mode and progression.make_rival().is_empty(): return
	if progression.seconds_until_next_match() > 0:
		status_label.text = "La arena se prepara · %.0f s" % ceil(progression.seconds_until_next_match())
		return
	# Persist stable identity IDs before they are copied into an immutable battle.
	if identity_loaded and not fighter_identity.save_blocked and not fighter_identity.save():
		status_label.text = "No se pudo guardar tu identidad. Revisa Personalizar antes de pelear."
		status_label.show()
		return
	active_match = true
	match_generation += 1
	result_panel.hide()
	summary_button.hide()
	surrender_button.show()
	surrender_button.disabled = false
	finishing = false
	_close_signature_banner()
	_update_portraits()
	player_view.prepare_combat_animation()
	rival_view.prepare_combat_animation()
	round_label.show()
	timer_label.show()
	state_label.show()
	feed.clear()
	battle_log.clear()
	feed_label.text = "Se encienden los faroles. ¡Que empiece el combate!"
	fight_button.disabled = true
	fight_button.text = "Combate automático"
	status_label.text = "Observa los ataques, esquivas y golpes críticos."
	state_label.text = "COMBATE AUTOMÁTICO"
	round_label.text = _story_round_text() if story_mode else "RONDA %02d" % (int(progression.data.matches) + 1)
	arena.combat_active = true
	arena.winner_side = ""
	combat_fx.clear()
	_refresh_manager()
	_layout_interface(_layout_size)
	var start_gap: float = (0.0 if reduced_motion else 28.0) * float(layout_rects.actor_scale)
	player_view.position.x -= start_gap
	rival_view.position.x += start_gap
	approach_tween = create_tween().set_parallel(true)
	approach_tween.tween_property(player_view,"position:x",layout_rects.player_at.x,0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	approach_tween.tween_property(rival_view,"position:x",layout_rects.rival_at.x,0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var player_descriptor: Dictionary = _player_combatant()
	combat.start(player_descriptor, rival)
	_configure_combat_audio(player_descriptor, rival)
	if player_view.has_method("play_intro"): player_view.play_intro()
	_log_event("%s (Nv. %d) contra %s (Nv. %d)." % [_display_name(progression.data), progression.data.level, rival.name, rival.level])
	if is_instance_valid(audio_director): audio_director.play_ui("fight_intro")

func _arena_covered() -> bool:
	for layer: Control in [modal_layer,story_layer,creation_layer,customization_layer,replay_layer,online_layer]:
		if not is_instance_valid(layer) or not layer.is_visible_in_tree(): continue
		# During a reveal, or behind a translucent dialog, retain the live scene.
		if layer.modulate.a < 0.999 or not layer.get_meta("world_screen_background",false): continue
		if layer.get_global_rect().grow(1).encloses(get_global_rect()): return true
	return false


func _process(delta: float) -> void:
	if is_instance_valid(arena):
		var covered := _arena_covered()
		arena.visible = not covered
		arena.process_mode = Node.PROCESS_MODE_DISABLED if covered else Node.PROCESS_MODE_INHERIT
	if active_match and is_instance_valid(audio_director):
		audio_director.set_paused(is_instance_valid(modal_layer))
	if is_instance_valid(combat_fx):
		combat_fx.motion_paused = active_match and is_instance_valid(modal_layer)
		arena.position = combat_fx.camera_offset()
	if is_instance_valid(player_view): player_view.motion_paused = active_match and is_instance_valid(modal_layer)
	if is_instance_valid(rival_view): rival_view.motion_paused = active_match and is_instance_valid(modal_layer)
	if not active_match and not progression.data.is_empty():
		var cooldown: float = progression.seconds_until_next_match()
		fight_button.disabled = cooldown > 0 or progression.save_blocked
		if cooldown > 0:
			status_label.text = "La arena se prepara · %.0f s" % ceil(cooldown)
			if result_panel.visible: status_label.show()
		elif status_label.text.begins_with("La arena se prepara"):
			status_label.text = "Tu compañero está listo para volver a la arena."
			if result_panel.visible: status_label.hide()
	if not active_match or finishing or is_instance_valid(modal_layer):
		return
	var events: Array = combat.advance(delta)
	timer_label.text = "%02d:%02d" % [int(combat.elapsed) / 60, int(combat.elapsed) % 60]
	_dispatch_events(events)
	# Health, turns, shields and statuses change at combat events, not at display Hz.
	if not events.is_empty(): _refresh_combat_state()

func _dispatch_events(events: Array) -> void:
	for event: Dictionary in events:
		player_view.observe_combat_health(event,"player",combat.player_max_hp)
		rival_view.observe_combat_health(event,"rival",combat.rival_max_hp)
		if is_instance_valid(audio_director) and not _audio_session_finished:
			audio_director.on_combat_event(event, combat.elapsed, _audio_event_index)
			if str(event.get("type","")) == "finished": _audio_session_finished = true
		_audio_event_index += 1
		var message := str(event.get("message", ""))
		if event.type == "signature":
			message = "GOLPE FIRMA · " + message
		if not message.is_empty():
			_log_event("T%02d · %s" % [int(event.get("turn", combat.snapshot().get("turn", 0))), message])
		match str(event.type):
			"move_started": _handle_move_started(event)
			"attack": _handle_attack(event, match_generation)
			"defensive_stance": _effect_feedback(event)
			"finished": _finish_fight(event, match_generation)
			"signature": _show_signature(event)
			"heal", "shield", "status_tick", "ability", "status_applied", "status_expired", "status_resisted": _effect_feedback(event)
	if is_instance_valid(audio_director): audio_director.advance(combat.elapsed)

func _refresh_combat_state() -> void:
	var snapshot: Dictionary = combat.snapshot()
	_set_health(combat.player_hp, combat.player_max_hp, true)
	_set_health(combat.rival_hp, combat.rival_max_hp, false)
	var side_name := str(snapshot.get("active_side",""))
	_last_active_side = side_name
	var actor_name := str(combat.summary().get(side_name,{}).get("name","")) if not active_match else (player_name_label.text if side_name=="player" else rival_name_label.text)
	state_label.text = "T%d · %s" % [int(snapshot.get("turn",0)),actor_name] if not side_name.is_empty() else "COMIENZA LA RONDA"
	arena.set_active_fighter(side_name if active_match else "",player_view.position,rival_view.position,float(layout_rects.get("actor_scale",1.0)))
	player_level_label.text = "%sNIVEL %d" % ["› " if side_name=="player" and active_match else "",int(snapshot.get("fighters",{}).get("player",{}).get("level",1))]
	rival_level_label.text = "%sNIVEL %d" % ["› " if side_name=="rival" and active_match else "",int(snapshot.get("fighters",{}).get("rival",{}).get("level",1))]
	for side: String in ["player", "rival"]:
		var fighter: Dictionary = snapshot.get("fighters", {}).get(side, {})
		var parts: Array[String] = []
		var stance: Dictionary = fighter.get("stance", {})
		var actor := player_view if side == "player" else rival_view
		actor.set_health_ratio(float(fighter.get("hp",1))/maxf(1,float(fighter.get("max_hp",1))))
		actor.defensive_stance = not stance.is_empty()
		if not stance.is_empty(): parts.append(str(stance.get("name", "Guardia")))
		if float(fighter.get("shield", 0)) > 0:
			parts.append("ESCUDO %d" % int(ceil(float(fighter.shield))))
		for effect: Dictionary in fighter.get("statuses", []):
			if effect.get("type", "") != "shield":
				parts.append(_effect_label(effect))
		var label := player_status_label if side == "player" else rival_status_label
		label.text = "\n".join(parts) if not parts.is_empty() else ""
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		label.tooltip_text = "\n".join(parts) + "\nCada turno es una acción propia del afectado."

func _handle_move_started(event: Dictionary) -> void:
	var actor := player_view if str(event.get("side", "player")) == "player" else rival_view
	var move: Dictionary = event.get("move", {})
	if bool(event.get("counter", false)):
		move = move.duplicate(true)
		move["is_counter_reaction"] = true
		move["animation_type"] = "dash"
	actor.play_move(move, maxf(0.0, combat.elapsed - float(event.get("time", combat.elapsed))))
	combat_fx.play_move(event,actor,maxf(0,combat.elapsed-float(event.get("time",combat.elapsed))))

func _handle_attack(event: Dictionary, generation: int) -> void:
	var is_player: bool = event.side == "player"
	var attacker := player_view if is_player else rival_view
	var target := rival_view if is_player else player_view
	var critical: bool = event.result in ["critical", "signature"]
	if event.has("move_id"):
		attacker.move_impact(critical, str(event.move_id))
	else:
		attacker.play_attack(critical)
		await get_tree().create_timer(0.21).timeout
	if generation != match_generation:
		return
	if event.result in ["dodge", "miss"]:
		if event.result == "dodge":
			target.play_dodge()
		_float_text("ESQUIVA" if event.result == "dodge" else "FALLO", _feedback_position(target, false), TEAL)
	else:
		var reaction_event: Dictionary = attacker.prepare_reaction_event(event, maxf(0, combat.elapsed-float(event.get("time",combat.elapsed))))
		var presentation: Dictionary = target.play_reaction(reaction_event)
		presentation["animation_type"] = event.get("animation_type","")
		presentation["signature"] = str(event.get("result",""))=="signature"
		var pause: float = float(presentation.get("hit_stop",0))
		attacker.request_hit_stop(pause)
		target.request_hit_stop(pause)
		var impact_at: Vector2 = combat_fx.to_local(target.to_global(target.effect_anchor("chest")))
		combat_fx.play_impact(impact_at,presentation,target.scale.x,attacker.facing,float(reaction_event.presentation_elapsed),target)
		target.illuminate_effect(Color("ffd39a"),0.06 if critical else 0.025,0.18,float(reaction_event.presentation_elapsed))
		var prefix := "FIRMA " if event.result == "signature" else ("¡CRÍTICO! " if critical else "")
		var hit_text := prefix + "−%d" % int(event.damage)
		if float(event.get("absorbed", 0)) > 0:
			hit_text += " · ESCUDO %d" % int(event.absorbed)
		_float_text(hit_text, _feedback_position(target, false), GOLD if critical else CREAM)

func _effect_feedback(event: Dictionary) -> void:
	var side := str(event.get("target", event.get("side", "player")))
	var actor := player_view if side == "player" else rival_view
	var content := ""
	var color := TEAL
	combat_fx.play_status(event,actor,maxf(0,combat.elapsed-float(event.get("time",combat.elapsed))))
	if event.type=="ability" and str(event.get("ability_id",""))=="phase_shift" and int(event.get("phase_index",0))>0:
		actor.play_transformation("ember_core")
	match str(event.type):
		"defensive_stance": content = str(event.get("name", "GUARDIA"))
		"heal": content = "CURA +%d" % int(event.get("amount", 0))
		"shield": content = "ESCUDO +%d" % int(event.get("amount", 0))
		"status_tick":
			content = "EFECTO −%d" % int(event.get("damage", event.get("amount", 0)))
			color = CORAL
			if event.has("target_hp") and float(event.target_hp) <= 0.0:
				var reaction_event := event.duplicate(true)
				reaction_event["presentation_elapsed"] = maxf(0, combat.elapsed-float(event.get("time", combat.elapsed)))
				actor.play_reaction(reaction_event)
			else:
				actor.play_hit(false)
		"ability": content = str(event.get("name", "HABILIDAD"))
		"status_applied":
			content = _effect_label(event.get("status", {}))
			color = CORAL if str(event.get("effect", "")) in ["poison", "burn", "bleed", "attack_down", "slow", "defense_down", "accuracy_down", "healing_down", "stun"] else TEAL
		"status_expired": content = "FIN · " + str(event.get("status", {}).get("name", "EFECTO"))
		"status_resisted": content = "RESISTE"
	if not content.is_empty():
		_float_text(content, _feedback_position(actor, true), color)

func _show_signature(event: Dictionary) -> void:
	_close_signature_banner()
	signature_banner = _label(self, "✦ GOLPE FIRMA · %s ✦" % str(event.get("name", "Leyenda de la liga")), layout_rects.signature, 16 if layout_rects.phone or layout_rects.short else 23, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	signature_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	signature_banner.add_theme_color_override("font_outline_color", DARK)
	signature_banner.add_theme_constant_override("outline_size", 8)
	feed_label.hide()
	var actor := player_view if event.get("side", "player") == "player" else rival_view
	if actor.play_transformation("ember_core"):
		combat_fx.emit_attached("transformation",actor,"body",maxf(0.0,combat.elapsed-float(event.get("time",combat.elapsed))))
	var banner := signature_banner
	var tween := banner.create_tween()
	tween.tween_interval(2.1)
	if not reduced_motion: tween.tween_property(banner, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		if is_instance_valid(banner): banner.queue_free()
		feed_label.visible = not result_panel.visible
	)

func _close_signature_banner() -> void:
	if is_instance_valid(signature_banner):
		signature_banner.queue_free()
	signature_banner = null
	feed_label.visible = not result_panel.visible

func _effect_label(effect: Dictionary) -> String:
	var effect_type := str(effect.get("type", ""))
	var magnitude := float(effect.get("magnitude", 0))
	var value := ""
	if effect_type in ["poison", "burn", "bleed"]:
		value = " −%d PV" % roundi(magnitude)
	elif effect_type in ["accuracy_up", "accuracy_down"]:
		value = " %+.0f pp" % (magnitude * 100 * (1 if effect_type == "accuracy_up" else -1))
	elif effect_type in ["attack_down", "defense_down", "slow", "healing_down", "attack_up", "defense_up"]:
		value = " %+.0f%%" % (magnitude * 100 * (1 if effect_type.ends_with("_up") else -1))
	return "%s%s · %d t" % [str(effect.get("name", "Efecto")), value, int(effect.get("remaining_turns", 0))]

func _feedback_position(actor: Node2D, effect: bool) -> Vector2:
	var offset := Vector2(-30 if actor==player_view else 30, -185 if effect else -142)
	if is_instance_valid(signature_banner): offset.y = -100 if effect else -65
	if layout_rects.short: offset.y = -76 if effect else -42
	return actor.position + offset * actor.scale

func _float_text(content: String, at: Vector2, color: Color) -> void:
	var side := "player" if at.x < _layout_size.x/2 else "rival"
	var now := Time.get_ticks_msec()
	var lane: Dictionary = floating_lanes.get(side, {"time": 0, "index": 0})
	var index := (int(lane.index) + 1) % 3 if now - int(lane.time) < 400 else 0
	floating_lanes[side] = {"time": now, "index": index}
	at += Vector2(0, -index * 25)
	at.y = maxf(float(layout_rects.hud_player.end.y)+16, at.y)
	var width := minf(320,(_layout_size.x-40)/2)
	var left := clampf(at.x-width/2,16,_layout_size.x-width-16)
	var label := _label(self, content, Rect2(Vector2(left,at.y), Vector2(width,42)), 16 if layout_rects.phone or layout_rects.short else 20, color, HORIZONTAL_ALIGNMENT_CENTER)
	# Keep terminal hit numbers behind the outcome and its continuation control.
	move_child(label,result_veil.get_index())
	label.add_theme_color_override("font_outline_color", DARK)
	label.add_theme_constant_override("outline_size", 6)
	if reduced_motion:
		var stationary := create_tween()
		stationary.tween_interval(1.0)
		stationary.tween_callback(label.queue_free)
		return
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 46, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.35).set_delay(0.65)
	tween.chain().tween_callback(label.queue_free)

func _log_event(content: String) -> void:
	feed.append(content)
	if feed.size() > 4:
		feed.pop_front()
	battle_log.append(content)
	feed_label.text = content
	feed_label.modulate.a = 1.0
	if is_instance_valid(feed_tween): feed_tween.kill()
	feed_tween = create_tween()
	feed_tween.tween_interval(4.0)
	if not reduced_motion: feed_tween.tween_property(feed_label,"modulate:a",0.45,0.35)
	feed_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	feed_label.tooltip_text = content
	feed_label.mouse_filter = Control.MOUSE_FILTER_PASS
	if modal_kind == "log" and is_instance_valid(modal_body):
		modal_body.text = "\n\n".join(battle_log)

func _finish_fight(event: Dictionary, generation: int) -> void:
	if finishing or not active_match:
		return
	finishing = true
	surrender_button.disabled = true
	last_battle_summary = combat.summary().duplicate(true)
	# Commit rewards as soon as the engine finishes, before cosmetic timers.
	last_reward = progression.reward_match(last_battle_summary)
	_grant_cosmetics()
	if story_mode: progression.clear_replay()
	# The engine is already terminal; delay only the final pose for the last impact.
	if str(event.get("reason", "normal")) != "surrender":
		await get_tree().create_timer(0.30).timeout
	if generation != match_generation:
		return
	match_generation += 1
	var won: bool = event.winner == "player"
	active_match = false
	finishing = false
	arena.combat_active = false
	arena.winner_side = str(event.winner)
	if won:
		player_view.resolve_battle(true)
		rival_view.resolve_battle(false)
	else:
		rival_view.resolve_battle(true)
		player_view.resolve_battle(false)
	_refresh_manager()
	_refresh_combat_state()
	var was_surrender := str(event.get("reason", "")) == "surrender"
	result_title.text = "RENDICIÓN" if was_surrender else ("¡VICTORIA!" if won else "DERROTA")
	result_title.add_theme_color_override("font_color", GOLD if won else CREAM)
	var player_reward: Dictionary = last_reward.get("player", {})
	var rival_reward: Dictionary = last_reward.get("rival", {})
	var xp := int(player_reward.get("xp_gained", last_reward.get("xp_gained", 0)))
	result_copy.text = "Tu compañero +%d XP · Rival +%d XP\n%s" % [xp, int(rival_reward.get("xp_gained", 0)), "¡Subes al nivel %d! · Mira tus mejoras en Resumen" % int(progression.data.level) if int(last_reward.get("levels_gained", 0)) > 0 else "La liga continúa. Entrena y vuelve a la arena."]
	result_panel.show()
	_close_signature_banner()
	surrender_button.hide()
	summary_button.show()
	state_label.text = "RONDA TERMINADA"
	_layout_interface(_layout_size)
	result_panel.modulate.a = 1.0 if reduced_motion else 0.0
	result_tween = create_tween()
	result_tween.tween_property(result_panel,"modulate:a",1.0,0.2)
	for side: String in ["player", "rival"]:
		var reward: Dictionary = last_reward.get(side, {})
		if int(reward.get("level_after", 1)) > int(reward.get("level_before", 1)):
			_log_event("%s sube de nivel %d → %d. %s" % [str(last_battle_summary.get(side, {}).get("name", side)), int(reward.level_before), int(reward.level_after), _format_gains(reward.get("stat_gains", {}))])
	_log_event("%s · +%d XP para %s. Abre Resumen para ver la progresión de ambos." % [_reason_label(str(event.get("reason", "normal"))), xp, _display_name(progression.data)])
	_prepare_rival()
	fight_button.text = "Volver a pelear  →"
	if story_mode:
		fight_button.text = "Ver legado  →" if progression.is_complete() else ("Siguiente encuentro  →" if won else "Preparar reintento  →")
	status_label.text = "Entrena, cambia de compañero o vuelve a la arena."

func _toggle_speed() -> void:
	quick_mode = not quick_mode
	Engine.time_scale = 2.0 if quick_mode else 1.0
	speed_button.text = "Ritmo ×2" if quick_mode else "Ritmo ×1"

func _toggle_sound() -> void:
	sound_enabled = not sound_enabled
	if is_instance_valid(audio_director):
		audio_director.set_volumes({"enabled":sound_enabled})
		sound_enabled = bool(audio_director.get_settings().get("enabled",sound_enabled))
	if is_instance_valid(sound_button): sound_button.text = "Sonido: sí" if sound_enabled else "Sonido: no"
	if sound_enabled:
		_play_sound("upgrade")

func _toggle_reduced_motion() -> void:
	reduced_motion = not reduced_motion
	_apply_motion_preference()
	var preferences := ConfigFile.new()
	preferences.set_value("display", "reduced_motion", reduced_motion)
	preferences.save(session_save_path + ".prefs.cfg")

func _apply_motion_preference() -> void:
	get_tree().set_meta("brasa_reduced_motion", reduced_motion)
	if is_instance_valid(player_view): player_view.reduced_motion = reduced_motion
	if is_instance_valid(rival_view): rival_view.reduced_motion = reduced_motion
	if is_instance_valid(arena): arena.reduced_motion = reduced_motion
	if is_instance_valid(combat_fx): combat_fx.reduced_motion = reduced_motion

func _show_creation() -> void:
	_open_customization("nima", true)

func _show_roster(first_time: bool = false) -> void:
	if is_instance_valid(customization_layer) or is_instance_valid(replay_layer): return
	if story_mode:
		_show_story_panel("companions")
		return
	if active_match or progression.save_blocked or is_instance_valid(creation_layer) or is_instance_valid(modal_layer):
		return
	creation_layer = RosterScript.new()
	add_child(creation_layer)
	var profiles: Dictionary = progression.roster.duplicate(true)
	if identity_loaded:
		for id: String in profiles: profiles[id] = fighter_identity.decorate(profiles[id])
	creation_layer.configure(_fighter_definitions(), profiles, str(progression.data.get("character_id", "nima")), first_time)
	creation_layer.enable_customization(identity_loaded)
	creation_layer.character_chosen.connect(_choose_character)
	creation_layer.customize_requested.connect(_open_customization)
	creation_layer.closed.connect(_close_roster)

func _close_roster() -> void:
	if is_instance_valid(creation_layer):
		creation_layer.queue_free()
	creation_layer = null

func _choose_character(character_id: String, custom_name: String) -> void:
	if identity_loaded and not fighter_identity.save_blocked:
		var current: Dictionary = fighter_identity.entry(character_id)
		if current.is_empty(): return
		if custom_name != str(current.identity.display_name):
			var renamed: Dictionary = fighter_identity.update_fighter(character_id, custom_name, current.appearance)
			if not bool(renamed.get("ok", false)): return
	if not progression.select_character(character_id, "" if identity_loaded else custom_name):
		return
	if is_instance_valid(customization_layer): _close_customization()
	_close_roster()
	result_panel.hide()
	summary_button.hide()
	round_label.show()
	timer_label.show()
	timer_label.text = "VS"
	state_label.show()
	_prepare_rival()
	_refresh_manager()
	_update_portraits()
	_play_sound("start")
	feed_label.text = "%s entra al patio. Su nivel, experiencia y entrenamiento son individuales." % _display_name(progression.data)

func _open_document(title: String, subtitle: String, body: String, kind: String = "document") -> void:
	if is_instance_valid(customization_layer) or is_instance_valid(replay_layer): return
	if is_instance_valid(creation_layer) or is_instance_valid(modal_layer) or is_instance_valid(story_layer): return
	if active_match:
		player_view.motion_paused = true
		rival_view.motion_paused = true
		combat_fx.motion_paused = true
		if is_instance_valid(audio_director): audio_director.set_paused(true)
	modal_kind = kind
	var dialog := GameModalScript.new()
	dialog.max_width = 800
	dialog.preferred_height = 740
	modal_layer = dialog
	add_child(dialog)
	dialog.configure(title,subtitle+(" · En pausa" if active_match else ""),"Esc para cerrar")
	modal_canvas = dialog.canvas_content()
	var parts: Dictionary = dialog.parts()
	modal_panel = parts.panel
	modal_title = parts.heading
	modal_subtitle = parts.subtitle
	modal_close_button = parts.close
	modal_hint = parts.hint
	modal_close_button.custom_minimum_size = Vector2(48,48)
	modal_body = RichTextLabel.new()
	modal_body.add_theme_font_size_override("normal_font_size",Visuals.font_size("body"))
	modal_body.add_theme_color_override("default_color",CREAM)
	modal_body.add_theme_constant_override("line_separation",Visuals.space("xs"))
	modal_body.selection_enabled = true
	modal_body.bbcode_enabled = false
	modal_body.text = body
	modal_canvas.add_child(modal_body)
	modal_canvas.resized.connect(_layout_modal)
	dialog.closed.connect(_close_modal)
	dialog.open(menu_button)
	_layout_modal()

func _layout_modal() -> void:
	if not is_instance_valid(modal_canvas): return
	var width := maxf(1,modal_canvas.size.x)
	var height := maxf(1,modal_canvas.size.y)
	var compact := _layout_size.x < 640 or _layout_size.y < 540
	_place(modal_body,Rect2(0,0,width,height))
	modal_body.add_theme_font_size_override("normal_font_size",Visuals.font_size("body",compact))
	if modal_kind == "training" and is_instance_valid(training_scroll):
		if width >= 760:
			var block_width := minf(width,1120)
			var right_width := minf(620,block_width*0.57)
			var hero_width := block_width-right_width-40
			var origin := (width-block_width)*0.5
			var top := maxf(0,(height-610)*0.35)
			_place(document_preview,Rect2(origin,top+24,hero_width,clampf(height-top-48,120,500)))
			_place(modal_body,Rect2(origin+hero_width+40,top,right_width,height-top))
		else:
			var hero_height := clampf(height*0.30,120,205)
			_place(document_preview,Rect2(0,0,width,hero_height))
			_place(modal_body,Rect2(0,hero_height+20,width,maxf(48,height-hero_height-20)))
	elif is_instance_valid(document_preview):
		if width < 620:
			var hero_height := clampf(height*0.40,120,280)
			_place(document_preview,Rect2(0,0,width,hero_height))
			_place(modal_body,Rect2(0,hero_height+16,width,maxf(48,height-hero_height-16)))
		else:
			var hero_width := width*0.44
			_place(document_preview,Rect2(0,0,hero_width,height))
			_place(modal_body,Rect2(hero_width+32,0,width-hero_width-32,height))
	if is_instance_valid(profile_details):
		var details_rect := modal_body.get_rect()
		details_rect.size.x = minf(720,details_rect.size.x)
		_place(profile_details,details_rect)
	if modal_kind == "surrender":
		modal_body.size.y = maxf(48,height-64)
		var cell := maxf(48,(width-12)/2)
		if is_instance_valid(modal_cancel):
			_place(modal_cancel,Rect2(0,maxf(0,height-52),cell,52))
			_place(modal_accept,Rect2(cell+12,maxf(0,height-52),cell,52))
			modal_cancel.add_theme_font_size_override("font_size",Visuals.font_size("button",compact))
			modal_accept.add_theme_font_size_override("font_size",Visuals.font_size("button",compact))
	elif modal_kind == "training" and is_instance_valid(training_scroll):
		_place(training_scroll,modal_body.get_rect())
		_layout_training(maxf(200,training_scroll.size.x-12))
	elif modal_kind == "settings":
		for i in range(menu_actions.size()):
			_place(menu_actions[i],Rect2(0,i*60,width,48))
			menu_actions[i].add_theme_font_size_override("font_size",Visuals.font_size("button",compact))
		if is_instance_valid(audio_settings):
			_place(audio_settings,Rect2(0,252,width,AudioSettingsScript.CONTENT_HEIGHT))
	elif modal_kind in ["history","log"]:
		if is_instance_valid(modal_accept):
			modal_body.size.y = maxf(48,height-64)
			_place(modal_accept,Rect2(0,maxf(0,height-52),width,48))
		if is_instance_valid(history_scroll): _place(history_scroll,modal_body.get_rect())

func _close_modal() -> void:
	if is_instance_valid(audio_director) and not str(combat.battle_id).is_empty() and str(audio_director.debug_state().get("session","")).begins_with(str(combat.battle_id)+":"):
		audio_director.set_paused(false)
	if is_instance_valid(player_view): player_view.motion_paused = false
	if is_instance_valid(rival_view): rival_view.motion_paused = false
	if is_instance_valid(combat_fx): combat_fx.motion_paused = false
	if is_instance_valid(training_content) and is_instance_valid(training_scroll):
		training_content.reparent(self)
		training_content.hide()
	if is_instance_valid(modal_layer): modal_layer.queue_free()
	modal_layer = null
	modal_panel = null
	modal_canvas = null
	document_preview = null
	profile_details = null
	history_scroll = null
	audio_settings = null
	modal_body = null
	modal_kind = ""
	training_scroll = null
	modal_cancel = null
	modal_accept = null
	menu_actions.clear()

func _show_training() -> void:
	if story_mode:
		_show_story_panel("upgrades")
		return
	if active_match or progression.data.is_empty() or is_instance_valid(modal_layer): return
	_open_document("Entrenamiento", "", "", "training")
	if modal_kind != "training": return
	modal_body.hide()
	modal_layer.set_environment("upgrades",_visual_state())
	modal_layer.use_location_layout()
	modal_hint.hide()
	training_detail_index = -1
	for info: Button in stat_help_buttons: info.set_pressed_no_signal(false)
	_add_document_fighter()
	training_scroll = ScrollContainer.new()
	training_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	training_scroll.follow_focus = true
	modal_canvas.add_child(training_scroll)
	training_content.reparent(training_scroll)
	training_content.show()
	_refresh_manager()
	_layout_modal()

func _training_card_state(index: int, highlighted: bool) -> void:
	if index<0 or index>=stat_cards.size(): return
	stat_buttons[index].add_theme_stylebox_override("normal",Visuals.World.surface("secondary","hover" if highlighted else "normal"))
	stat_cards[index].add_theme_stylebox_override("panel",Visuals.training_card("selected" if training_detail_index==index else ("hover" if highlighted else "normal")))

func _toggle_training_detail(index: int) -> void:
	training_detail_index = -1 if training_detail_index==index else index
	for i in range(4):
		stat_help_buttons[i].set_pressed_no_signal(training_detail_index==i)
		_training_card_state(i,false)
	_layout_modal()
	if training_detail_index>=0:
		training_scroll.ensure_control_visible.call_deferred(stat_descriptions[index])

func _layout_training(width: float) -> void:
	var columns := 1 if width<560 else 2
	var gap := 20.0
	var cell := (width-gap*(columns-1))/columns
	var row_y := 140.0
	_place(manager_label,Rect2(0,0,width-124,32))
	manager_label.add_theme_font_size_override("font_size",18 if width<560 else 22)
	_place(points_label,Rect2(width-120,0,120,32))
	points_label.add_theme_font_size_override("font_size",22)
	_place(xp_label,Rect2(0,44,width,24))
	xp_label.add_theme_font_size_override("font_size",12 if width<400 else 13)
	_place(xp_bar,Rect2(0,76,width,6))
	_place(training_notice,Rect2(0,92,width,36))
	for row in range(ceili(4.0/columns)):
		var expanded := training_detail_index>=row*columns and training_detail_index<(row+1)*columns
		var card_height := 260.0 if expanded else 176.0
		for column in range(columns):
			var i := row*columns+column
			if i>=4: break
			_place(stat_cards[i],Rect2(column*(cell+gap),row_y,cell,card_height))
			_place(stat_titles[i],Rect2(16,12,cell-88,32))
			_place(stat_values[i],Rect2(cell-64,12,48,32))
			_place(stat_effects[i],Rect2(16,50,cell-32,24))
			stat_effects[i].add_theme_font_size_override("font_size",13)
			_place(stat_deltas[i],Rect2(16,78,cell-32,26))
			stat_deltas[i].add_theme_font_size_override("font_size",12)
			_place(stat_buttons[i],Rect2(16,112,cell-92,48))
			stat_buttons[i].add_theme_font_size_override("font_size",13)
			_place(stat_help_buttons[i],Rect2(cell-64,112,48,48))
			stat_descriptions[i].visible = i==training_detail_index
			_place(stat_descriptions[i],Rect2(16,176,cell-32,72))
		row_y += card_height+gap
	training_content.custom_minimum_size = Vector2(0,row_y)
	training_content.size = Vector2(width,row_y)

func _visual_state() -> Dictionary:
	if not story_loaded and not session_save_path.is_empty():
		story_progression.load_save(session_save_path+".story.json")
		story_loaded = true
	var id := str(progression.data.get("character_id",progression.active_id))
	var entry: Dictionary = fighter_identity.entry(id) if identity_loaded else {}
	var story_profile: Dictionary = story_progression.roster.get(id,{})
	var story_started := int(story_profile.get("matches",0)) > 0 or int(story_profile.get("current_stage",0)) > 0 or int(story_profile.get("chapter",1)) > 1 or int(story_profile.get("total_xp",0)) > 0 or bool(story_profile.get("completed",false))
	return {"character_id":id,"story_started":story_started,"appearance":entry.get("appearance",{}),"owned_cosmetics":fighter_identity.owned_ids() if identity_loaded else [],"arena_wins":int(league_progression.roster.get(id,{}).get("wins",0)),"story_cleared":0 if story_profile.is_empty() else int(StoryCatalog.chapter(int(story_profile.get("chapter",1))).start_level)-1+int(story_profile.get("current_stage",0))}

func _show_menu() -> void:
	if is_instance_valid(customization_layer) or is_instance_valid(replay_layer) or is_instance_valid(creation_layer) or is_instance_valid(modal_layer) or is_instance_valid(story_layer): return
	player_view.motion_paused = active_match
	rival_view.motion_paused = active_match
	combat_fx.motion_paused = active_match
	modal_kind = "menu"
	var home := HomePanel.new()
	modal_layer = home
	add_child(home)
	var id := str(progression.data.get("character_id",progression.active_id))
	var profile: Dictionary = progression.data.duplicate(true)
	if identity_loaded:
		var entry: Dictionary = fighter_identity.entry(id)
		profile["identity"] = entry.get("identity",{})
		profile["appearance"] = entry.get("appearance",{})
	var callbacks := {
		"story":func(): _enter_story(id),
		"arena":_leave_story if story_mode else func(): pass,
		"online":_open_online,"training":_show_training,"companions":_show_roster,
		"customize":func(): _open_customization(),"profile":_show_fighter_details,
		"legacy":func():
			_enter_story()
			if is_instance_valid(story_layer):
				story_layer._achievement_character = id
				story_layer.show_tab("legacy"),
		"history":_show_history,"settings":_show_settings,"help":_show_help,"log":_show_log
	}
	var actions: Array = []
	for item: Array in [["story","Historia"],["arena","Arena"],["online","Arena online"],["training","Entrenar"],["companions","Compañeros"],["customize","Personalizar"],["profile","Ficha"],["legacy","Logros"],["history","Historial"],["settings","Ajustes"],["help","Cómo jugar"],["log","Registro"]]:
		var blocked := active_match and str(item[0]) in ["story","arena","online","training","companions","customize","legacy"]
		actions.append({"id":item[0],"label":item[1],"disabled":blocked,"hint":"Disponible al terminar el combate" if blocked else ""})
	home.configure(profile,Catalog.definition(id),_visual_state(),actions,active_match)
	menu_actions = home.buttons
	home.closed.connect(_close_modal)
	home.action_requested.connect(func(action: String):
		_close_modal()
		if callbacks.has(action): callbacks[action].call()
	)

func _show_settings() -> void:
	if is_instance_valid(modal_layer): return
	_open_document("Ajustes","Sonido, velocidad y movimiento.","","settings")
	if modal_kind != "settings": return
	modal_body.hide()
	modal_layer.max_width = 640
	modal_layer.preferred_height = 660
	modal_layer.set_environment("settings",_visual_state())
	modal_layer.set_canvas_minimum_height(252+AudioSettingsScript.CONTENT_HEIGHT)
	modal_hint.text = "Esc para volver al patio"
	var options: Array = [
		["Sonido: sí" if sound_enabled else "Sonido: no",_toggle_sound],
		["Combate rápido: sí (×2)" if quick_mode else "Combate rápido: no (×1)",_toggle_speed],
		["Movimiento reducido: sí" if reduced_motion else "Movimiento reducido: no",_toggle_reduced_motion],
		["Pantalla completa",_toggle_fullscreen]
	]
	var selected_states := [sound_enabled,quick_mode,reduced_motion,get_window().mode in [Window.MODE_FULLSCREEN,Window.MODE_EXCLUSIVE_FULLSCREEN]]
	for entry: Array in options:
		var action: Callable = entry[1]
		menu_actions.append(_button(modal_canvas,str(entry[0]),Rect2(),func():
			_close_modal()
			action.call()
			_show_settings()
		))
		var button: Button = menu_actions.back()
		var enabled: bool = selected_states[menu_actions.size()-1]
		Visuals.apply_button(button,"navigation_active" if enabled else "navigation")
		button.icon = Visuals.icon("checked" if enabled else "unchecked")
	_make_sounds()
	audio_settings = AudioSettingsScript.new()
	modal_canvas.add_child(audio_settings)
	audio_settings.configure(audio_director.get_settings() if is_instance_valid(audio_director) else {"master":1.0,"music":1.0,"sfx":1.0})
	audio_settings.volume_changed.connect(_set_audio_volume)
	if is_instance_valid(audio_director): audio_settings.set_notice(str(audio_director.load_notice))
	modal_layer._layout()
	_layout_modal()

func _toggle_fullscreen() -> void:
	get_window().mode = Window.MODE_WINDOWED if get_window().mode in [Window.MODE_FULLSCREEN,Window.MODE_EXCLUSIVE_FULLSCREEN] else Window.MODE_FULLSCREEN

func _confirm_surrender() -> void:
	if not active_match or not combat.running or finishing or is_instance_valid(modal_layer): return
	_open_document("¿Rendirse?","El combate está en pausa.","%s ganará la ronda.\n\nRecibirás menos XP (al menos 1). Rendirse rápido o varias veces reduce la recompensa.\n\nQuedará registrado como rendición." % str(rival.name),"surrender")
	if story_mode:
		modal_body.text = "Puedes volver a intentar este encuentro. Conservas tu nivel, mejoras y ruta.\n\nRendirse concede una pequeña cantidad de XP y cuenta como derrota. Una pelea completa concede más experiencia."
	modal_cancel = _button(modal_canvas,"Seguir peleando",Rect2(),_close_modal,true)
	modal_accept = _button(modal_canvas,"Rendirme",Rect2(),_accept_surrender)
	Visuals.apply_button(modal_accept,"danger")
	modal_layer.max_width = 680
	modal_layer.preferred_height = 460
	modal_layer._layout()
	_layout_modal()

func _accept_surrender() -> void:
	if modal_kind != "surrender" or not active_match or not combat.running:
		return
	_close_modal()
	match_generation += 1
	_dispatch_events(combat.surrender("player"))
	_refresh_combat_state()

func _show_log() -> void:
	if is_instance_valid(modal_layer): return
	var body := "Aún no hay acciones. Entra a la arena para seguir ataques, habilidades y efectos turno a turno."
	if not battle_log.is_empty():
		body = "\n".join(battle_log)
	_open_document("Registro del combate", "Ataques y efectos, en orden de turno.", body, "log")
	if modal_kind == "log" and battle_log.is_empty():
		modal_layer.max_width = 680
		modal_layer.preferred_height = 280
		modal_accept = _button(modal_canvas,"Volver a la arena",Rect2(),_close_modal,true)
		modal_layer._layout()
		_layout_modal()
	if is_instance_valid(modal_body) and not battle_log.is_empty():
		modal_body.scroll_to_line(modal_body.get_line_count() - 1)

func _show_history() -> void:
	if is_instance_valid(modal_layer): return
	var lines: Array[String] = []
	for i in range(progression.history.size() - 1, -1, -1):
		var entry: Dictionary = progression.history[i]
		var player: Dictionary = entry.get("player", {})
		var other: Dictionary = entry.get("rival", {})
		var player_name := str(entry.get("player_name", player.get("name", "Compañero")))
		var other_name := str(entry.get("rival_name", other.get("name", "Rival")))
		var won := str(entry.get("winner", "rival")) == "player"
		lines.append("%s · %s contra %s\n%s · %d s · +%d XP" % ["VICTORIA" if won else "DERROTA", player_name, other_name, _reason_label(str(entry.get("reason", "normal"))), int(entry.get("duration", 0)), int(entry.get("player_xp", entry.get("xp_gained", 0)))])
	_open_document("Historial de Historia" if story_mode else "Historial de la liga", "Últimos %d combates · Todos tus compañeros" % progression.history.size(), "\n\n".join(lines) if not lines.is_empty() else "Tu historia empieza con la primera pelea.", "history")
	if modal_kind == "history":
		modal_layer.set_environment("history",_visual_state())
		if progression.history.is_empty():
			modal_layer.max_width = 680
			modal_layer.preferred_height = 280
			modal_accept = _button(modal_canvas,"Volver a la arena",Rect2(),_close_modal,true)
		else:
			modal_layer.preferred_height = clampf(260+progression.history.size()*156,380,740)
			_build_history_cards()
		modal_layer._layout()
		for record: Dictionary in progression.history:
			if not BattleIdentity.snapshot(record).is_empty():
				modal_accept = _button(modal_canvas, "Ver repeticiones", Rect2(), _show_replays, true)
				modal_accept.disabled = active_match
				modal_accept.tooltip_text = "Disponible al terminar el combate" if active_match else "Revisa nombre, aspecto y acciones originales"
				_layout_modal()
				break

func _build_history_cards() -> void:
	modal_body.hide()
	history_scroll = ScrollContainer.new()
	history_scroll.name = "BattleMemories"
	history_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	history_scroll.follow_focus = true
	modal_canvas.add_child(history_scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",Visuals.space("md"))
	history_scroll.add_child(list)
	for index in range(progression.history.size()-1,-1,-1):
		var record: Dictionary = progression.history[index]
		var frozen := BattleIdentity.snapshot(record)
		var memory := PanelContainer.new()
		memory.add_theme_stylebox_override("panel",Visuals.open_card("normal",12))
		memory.custom_minimum_size.y = 136
		list.add_child(memory)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",Visuals.space("lg"))
		memory.add_child(row)
		if not frozen.is_empty():
			var preview := FighterPreview.new()
			preview.custom_minimum_size = Vector2(96,116)
			row.add_child(preview)
			preview.configure(frozen.player,{})
			preview.set_motion(true,reduced_motion)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(text)
		var won := str(record.get("winner","rival")) == "player"
		for item: Array in [
			["VICTORIA" if won else "DERROTA","label","success" if won else "danger"],
			["%s contra %s" % [str(record.get("player_name",record.get("player",{}).get("name","Compañero"))),str(record.get("rival_name",record.get("rival",{}).get("name","Rival")))],"card","text_primary"],
			["%s · %d s · +%d XP" % [_reason_label(str(record.get("reason","normal"))),int(record.get("duration",0)),int(record.get("player_xp",record.get("xp_gained",0)))],"secondary","text_secondary"]
		]:
			var label := Label.new()
			label.text = str(item[0])
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			Visuals.apply_label(label,str(item[1]),str(item[2]))
			text.add_child(label)
	_layout_modal()

func _show_replays() -> void:
	if active_match or is_instance_valid(replay_layer) or is_instance_valid(customization_layer): return
	_close_modal()
	replay_layer = ReplayPanel.new()
	add_child(replay_layer)
	replay_layer.configure(progression.history)
	replay_layer.closed.connect(_close_replays)

func _close_replays() -> void:
	if is_instance_valid(replay_layer): replay_layer.queue_free()
	replay_layer = null
	_restore_audio_environment()

func _show_fighter_details() -> void:
	if story_mode and not active_match:
		_show_story_panel("upgrades")
		return
	if progression.data.is_empty() or is_instance_valid(modal_layer):
		return
	var profile: Dictionary = progression.data
	var definition: Dictionary = Catalog.definition(str(profile.character_id))
	var current: Dictionary = _current_stats(profile)
	var next_profile: Dictionary = profile.duplicate(true)
	next_profile.level = mini(BalanceConfig.MAX_LEVEL, int(profile.level) + 1)
	var next: Dictionary = _current_stats(next_profile)
	var rows: Array[Dictionary] = []
	for key: String in BalanceConfig.STAT_KEYS:
		var help: Dictionary = Catalog.STAT_HELP[key]
		var description := str(help.description)
		if story_mode:
			for choice: Dictionary in StoryCatalog.allocations():
				if choice.key == key: description = str(choice.description)
		rows.append({"key":key,"title":str(help.name),"value":_stat_value(key,float(current[key])),
			"growth":"+"+_gain_value(key,float(next[key])-float(current[key]))+" / nivel" if int(profile.level)<BalanceConfig.MAX_LEVEL else "Nivel máximo",
			"description":description,"range":str(help.range)})
	var rules := "Tus mejoras se conservan al subir de nivel. El crecimiento se suaviza al %d%% después del nivel %d. Nivel máximo: %d.\nEl poder estimado ayuda a buscar rivales; no multiplica el daño. Los efectos temporales solo duran durante el combate." % [int(BalanceConfig.GROWTH_AFTER_SOFT_CAP*100),BalanceConfig.LEVEL_SOFT_CAP,BalanceConfig.MAX_LEVEL]
	if story_mode:
		rules = "Estos atributos incluyen tus mejoras de Historia. Recibes tres puntos por nivel hasta el 20 y dos después. Puedes redistribuirlos entre combates. Los efectos temporales se consultan en el combate y en Registro."
	_open_document("%s · Nivel %d" % [_display_name(profile),int(profile.level)],str(definition.role),"")
	if not is_instance_valid(modal_canvas): return
	modal_layer.set_environment("fighter",_visual_state())
	modal_layer.use_location_layout()
	Visuals.reading_veil(modal_layer)
	# Keep decoration below header/content even though this location is configured
	# after the shell was opened.
	modal_layer.move_child(modal_layer.get_child(modal_layer.get_child_count()-1),1)
	modal_body.hide()
	modal_hint.text = "Esc para cerrar"
	profile_details = preload("res://scripts/ui/components/game_fighter_details.gd").new()
	modal_canvas.add_child(profile_details)
	profile_details.configure(definition,rows,rules)
	_add_document_fighter()
	_layout_modal()

func _add_document_fighter() -> void:
	var preview := FighterPreview.new()
	document_preview = preview
	modal_canvas.add_child(preview)
	var descriptor := _player_combatant()
	if active_match and combat._fighters.has("player"):
		descriptor = combat._fighters.player.descriptor.duplicate(true)
	preview.configure(descriptor,Catalog.definition(str(progression.data.character_id)))
	preview.set_motion(active_match,reduced_motion)

func _show_summary() -> void:
	if is_instance_valid(modal_layer): return
	if last_battle_summary.is_empty():
		return
	var lines: Array[String] = []
	var winning_side := str(last_battle_summary.get("winner", "player"))
	if story_mode and not str(last_reward.get("hint","")).is_empty():
		lines.append(str(last_reward.hint))
	if story_mode:
		for move: Dictionary in Moves.moves_for(str(progression.active_id)):
			if str(move.name) in _new_story_moves(): lines.append("NUEVO MOVIMIENTO · %s\n%s" % [str(move.name), str(move.description)])
	lines.append("Gana %s · %s\nDuración: %.1f s · %d turnos" % [str(last_battle_summary.get(winning_side, {}).get("name", "")), _reason_label(str(last_battle_summary.get("reason", "normal"))), float(last_battle_summary.get("duration", 0)), int(last_battle_summary.get("turns", 0))])
	for side: String in ["player", "rival"]:
		var participant: Dictionary = last_battle_summary.get(side, {})
		var reward: Dictionary = last_reward.get(side, {})
		var metrics: Dictionary = last_battle_summary.get("metrics", {}).get(side, {})
		var section := "%s · %s\n+%d XP · Nivel %d → %d\nProgreso: %d / %d XP" % [str(participant.get("name", side)).to_upper(), "VICTORIA" if winning_side == side else "DERROTA", int(reward.get("xp_gained", 0)), int(reward.get("level_before", participant.get("level", 1))), int(reward.get("level_after", participant.get("level", 1))), int(reward.get("xp_after", 0)), int(reward.get("xp_required", 0))]
		if int(reward.get("level_before",1)) == int(reward.get("level_after",1)):
			section = section.replace("Nivel %d → %d" % [int(reward.get("level_before",1)),int(reward.get("level_after",1))],"Nivel %d" % int(reward.get("level_after",1)))
		if story_mode and side == "rival":
			section = "%s · Nivel %d\nRival de campaña · Su perfil permanece igual en cada intento." % [str(participant.get("name","Rival")),int(participant.get("level",1))]
		if int(reward.get("level_after", 1)) >= BalanceConfig.MAX_LEVEL:
			section += " · NIVEL MÁXIMO"
		if not reward.get("stat_gains", {}).is_empty():
			section += "\nMejoras por nivel: " + _format_gains(reward.stat_gains)
		if int(reward.get("points_gained", 0)) > 0:
			section += "\n+%d puntos para entrenar" % int(reward.points_gained)
		section += "\nDaño %d · Críticos %d · Esquivas %d · Firmas %d" % [int(metrics.get("damage_dealt", 0)), int(metrics.get("criticals", metrics.get("crits", 0))), int(metrics.get("dodges", 0)), int(metrics.get("signatures", 0))]
		var used: Array[String] = []
		for move: Dictionary in participant.get("moves", []):
			var count: int = int(metrics.get("move_uses", {}).get(str(move.id), 0))
			if count > 0: used.append("%s ×%d" % [str(move.name), count])
		if not used.is_empty(): section += "\nTécnicas: " + ", ".join(used)
		lines.append(section)
	lines.append("Consulta Registro para leer los ataques, efectos y habilidades que decidieron el resultado.")
	_open_document("Resumen del combate", "Tu ruta conserva la XP, incluso al perder." if story_mode else "Ambos participantes ganan experiencia. Cada nivel conserva la XP sobrante.", "\n\n".join(lines))
	if is_instance_valid(modal_layer) and modal_kind == "document":
		modal_layer.manual_content = false
		var reader := preload("res://scripts/ui/components/game_reading_sections.gd").new()
		modal_layer.content().add_child(reader)
		for index in range(lines.size()-1):
			var section: String = lines[index]
			var first_line := section.get_slice("\n",0)
			if section.contains("\n") and (first_line.contains("VICTORIA") or first_line.contains("DERROTA") or first_line.contains(" · Nivel")):
				reader.section(first_line,section.substr(first_line.length()+1),true)
			else: reader.paragraph(section)
		var open_log := Button.new()
		open_log.text = "Ver acciones del combate"
		open_log.custom_minimum_size.y = 48
		Visuals.apply_button(open_log,"secondary")
		open_log.pressed.connect(func(): _close_modal(); _show_log())
		reader.add_child(open_log)

func _stat_value(key: String, value: float) -> String:
	match str(Catalog.STAT_HELP.get(key, {}).get("format", "decimal")):
		"integer": return "%.0f" % value
		"percent": return "%.2f%%" % (value * 100)
		"multiplier": return "%.3f×" % value
	return "%.2f" % value

func _gain_value(key: String, value: float) -> String:
	if str(Catalog.STAT_HELP.get(key, {}).get("format", "")) == "percent":
		return "%.2f pp" % (value * 100)
	return _stat_value(key, value)

func _stat_changes(before: Dictionary, after: Dictionary) -> String:
	var gains: Dictionary = {}
	for key: String in BalanceConfig.STAT_KEYS:
		var difference := float(after.get(key, 0)) - float(before.get(key, 0))
		if difference > 0.00001:
			gains[key] = difference
	return _format_gains(gains)

func _format_gains(gains: Dictionary) -> String:
	var parts: Array[String] = []
	for key: String in BalanceConfig.STAT_KEYS:
		var gain := float(gains.get(key, 0))
		if gain > 0.00001:
			parts.append("%s +%s" % [str(Catalog.STAT_HELP[key].name), _gain_value(key, gain)])
	return " · ".join(parts) if not parts.is_empty() else "Sin cambios adicionales"

func _reason_label(reason: String) -> String:
	return {"normal": "Fin por vida agotada", "timeout": "Límite de tiempo", "dot": "Fin por efecto de daño", "surrender": "Fin por rendición", "draw": "Empate"}.get(reason, reason)

func _show_help() -> void:
	if is_instance_valid(modal_layer): return
	var body := "1. Elige a tu compañero.\n2. Gasta tus puntos en Entrenar.\n3. Entra a la arena: peleará solo.\n4. Usa la XP ganada para mejorar.\n\nLA PELEA\nVelocidad marca cuándo actúas. Precisión se enfrenta a evasión; defensa reduce el daño. Los críticos se calculan aparte y el daño normal varía ±%d%%. Tener mejores números ayuda, pero no asegura ganar.\n\nCADA COMPAÑERO TIENE SU ESTILO\nAbre Compañeros o Ficha para conocer habilidad, fortalezas, debilidades y crecimiento. Todos tienen un Golpe Firma: alrededor de %d%% por combate, una sola vez, siempre acierta y deja un efecto temporal.\n\nEFECTOS Y TURNOS\nLos efectos aparecen bajo la vida con los turnos restantes. Un turno es una acción del personaje afectado; los efectos caducan solos. Escudos, curación y daño periódico también aparecen en Registro.\n\nRESULTADOS\nVictoria da más XP; derrota permite seguir avanzando. Rendirse siempre da al menos 1 XP, con reducciones por duración corta y repeticiones. La rendición se confirma con el combate en pausa.\n\nA los %d segundos gana quien tenga mayor proporción de vida. Resumen muestra XP de ambos, niveles y mejoras. Historial guarda los últimos %d combates.\n\nCONTROLES\nEspacio: entrar a la arena. F11: pantalla completa. Ritmo ×2: acelerar la reproducción. Menú: ficha, historial, registro, sonido y ayuda. Esc: cerrar paneles. Los paneles de lectura pausan la pelea.\n\nEl guardado es automático y conserva una copia al migrar partidas anteriores." % [int(BalanceConfig.COMBAT.variance * 100), int(BalanceConfig.SIGNATURE.chance * 100), int(BalanceConfig.COMBAT.max_duration), BalanceConfig.HISTORY_LIMIT]
	body += "\n\nMODO HISTORIA · 100 ENCUENTROS\nCada compañero comienza en nivel 1 con dos técnicas y tres puntos. Conserva tu ruta al cambiar de personaje o regresar a la liga. Los once capítulos incluyen los dos originales, élites y jefes; Ascua vuelve en el encuentro 50 y Véspera cierra el 100. El número del encuentro es distinto del nivel del personaje.\n\nMEJORAS Y MOVIMIENTOS\nMejora Vida, Ataque, Defensa, Velocidad, Precisión, Evasión, Crítico o Resistencia. Hasta el nivel 20 recibes tres puntos por nivel; después, dos. Desbloqueas técnicas en niveles 5, 12 y 20. Las fichas de la ruta mejoran cada técnica hasta dos grados. Los encuentros 10, 30 y 50 permiten elegir tres talentos entre seis opciones. En Mejoras puedes confirmar una redistribución de los recursos que ya ganaste.\n\nLA RUTA\nAntes de pelear revisa las técnicas, fortaleza y debilidad del rival. Algunas variantes cambian entre campañas, pero se mantienen en tus reintentos. Las derrotas dan menos XP y una pista basada en el combate. Puedes repetir encuentros superados como práctica sin XP. Cada capítulo guarda su cierre en Logros; inicia el siguiente cuando quieras.\n\nANIMACIÓN\nLos golpes fuertes y cargas tardan más en impactar; las cargas retroceden antes de avanzar. Los saltos dejan el suelo y las posturas pueden responder al rival. El Golpe Firma mantiene su tirada al inicio del combate, sin tiradas adicionales por técnica. Menú → Ajustes → Movimiento reducido elimina desplazamientos y destellos conservando las mismas reglas y tiempos."

	_open_document("Cómo jugar", "Prepara tu compañero; el combate es automático.", body)
	if is_instance_valid(modal_layer) and modal_kind == "document":
		var reader := preload("res://scripts/ui/components/game_reading_sections.gd").new()
		modal_layer.manual_content = false
		modal_layer.content().add_child(reader)
		var chunks := body.split("\n\n")
		reader.paragraph(chunks[0])
		reader.paragraph("Abre un tema para saber más.",true)
		var heading := ""
		var detail := ""
		for index in range(1,chunks.size()):
			var chunk: String = chunks[index]
			var first_line: String = chunk.get_slice("\n",0)
			if first_line==first_line.to_upper() and chunk.contains("\n"):
				if not heading.is_empty(): reader.section(heading.left(1)+heading.substr(1).to_lower(),detail)
				heading = first_line
				detail = chunk.substr(first_line.length()+1)
			else: detail += "\n\n"+chunk
		if not heading.is_empty(): reader.section(heading.left(1)+heading.substr(1).to_lower(),detail)
	if is_instance_valid(modal_layer) and modal_kind == "document":
		modal_layer.set_environment("help",_visual_state())

func _close_help() -> void:
	_close_modal()

func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(online_layer): return
	if is_instance_valid(customization_layer):
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_cancel_customization()
		return
	if is_instance_valid(replay_layer):
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE: _close_replays()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if is_instance_valid(story_layer): _close_story_panel()
			else: _close_modal()
		elif event.keycode == KEY_F11:
			_toggle_fullscreen()
		elif event.keycode == KEY_SPACE:
			_primary_action()

func _make_sounds() -> void:
	# Kept as an initialization adapter for existing isolated Main fixtures.
	# The director owns resources/buses; no synthetic fallback sounds are created.
	if is_instance_valid(audio_director): return
	var requested_enabled := sound_enabled
	audio_director = AudioDirectorScript.new()
	add_child(audio_director)
	if not audio_director.is_in_group("brasa_audio_director"):
		audio_director.add_to_group("brasa_audio_director")
	var preferences_path := session_save_path + ".audio.cfg" if not session_save_path.is_empty() else ""
	audio_director.setup(preferences_path, DisplayServer.get_name() == "headless")
	if not requested_enabled: audio_director.set_volumes({"enabled":false},false)
	sound_enabled = bool(audio_director.get_settings().get("enabled",true))

func _configure_combat_audio(player_descriptor: Dictionary, rival_descriptor: Dictionary) -> void:
	_make_sounds()
	_audio_event_index = 0
	_audio_session_finished = false
	if not is_instance_valid(audio_director): return
	audio_director.stop_session()
	audio_director.configure_context(_audio_arena_id(), {"player":player_descriptor.duplicate(true),"rival":rival_descriptor.duplicate(true)}, {
		"session_id":str(combat.battle_id)+":"+str(match_generation),"battle_id":str(combat.battle_id),
		"mode":"live","viewing_side":"player","result_audio":true})
	audio_director.set_paused(false)

func _audio_arena_id() -> String:
	var background := str(arena.get_background_path()) if is_instance_valid(arena) else ArenaScript.DEFAULT_BACKGROUND
	return "arena_tormenta" if background == "res://assets/arena-tormenta-v3.png" else "arena_faroles"

func _restore_audio_environment() -> void:
	if active_match or is_instance_valid(replay_layer) or is_instance_valid(online_layer): return
	if not is_instance_valid(audio_director): return
	var player_descriptor: Dictionary = _player_combatant() if not progression.data.is_empty() else {}
	# Returning from a recording restores the place, never the old combat clock,
	# pending attacks or rewards. Same music/ambience resources retain their playhead.
	audio_director.configure_context(_audio_arena_id(), {"player":player_descriptor,"rival":rival.duplicate(true)}, {
		"session_id":"main-preview:"+str(get_instance_id())+":"+str(match_generation),
		"mode":"preview","viewing_side":"player","result_audio":false})
	audio_director.set_paused(false)

func _set_audio_volume(bus: String, value: float) -> void:
	if not bus in ["master","music","sfx"] or not is_finite(value): return
	_make_sounds()
	if not is_instance_valid(audio_director): return
	audio_director.set_volumes({bus:clampf(value,0.0,1.0)})
	if is_instance_valid(audio_settings):
		audio_settings.configure(audio_director.get_settings())
		audio_settings.set_notice("" if audio_director.last_save_ok else "No se pudieron guardar los volúmenes. Revisa la carpeta de preferencias.")

func _play_sound(key: String) -> void:
	# Legacy callers here are committed UI actions, not combat events.
	if not sound_enabled: return
	_make_sounds()
	if is_instance_valid(audio_director) and key in ["start","upgrade"]:
		audio_director.play_ui("ui_confirm")

func _run_smoke_test() -> void:
	get_tree().create_timer(35.0, true, false, true).timeout.connect(func():
		push_error("UI_SMOKE_FAIL: timeout")
		get_tree().quit(1)
	)
	await get_tree().process_frame
	if not _smoke_check(player_bar.size.y == 14.0 and xp_bar.size.y == 5.0, "Health and XP bars must fit their layout"):
		return
	_choose_character("mugo", "Prueba")
	_show_training()
	await get_tree().process_frame
	if not _smoke_check(is_instance_valid(training_scroll) and stat_buttons[0].is_visible_in_tree(), "Training drawer exposes existing upgrades"):
		return
	var original_life := int(progression.data.stats.life)
	var original_points := int(progression.data.points)
	stat_buttons[0].pressed.emit()
	_close_modal()
	if not _smoke_check(int(progression.data.stats.life) == original_life + 1 and int(progression.data.points) == original_points - 1, "Upgrade spends one point"):
		return
	var previous_matches := int(progression.data.matches)
	_start_fight()
	combat.start(_player_combatant(), rival, 4321, {"force_signature": ["player"], "signature_turn": 2})
	Engine.time_scale = 32.0
	while active_match:
		await get_tree().process_frame
	if not _smoke_check(int(progression.data.matches) == previous_matches + 1, "A match rewards exactly once"):
		return
	if not _smoke_check(result_panel.visible and not fight_button.disabled and not rival.is_empty(), "Result and next rival available"):
		return
	if not _smoke_check("FIRMA" in " ".join(battle_log).to_upper(), "Signature appears in log"):
		return
	var duplicated: Dictionary = progression.reward_match(last_battle_summary)
	if not _smoke_check(bool(duplicated.get("duplicate", false)), "Duplicate reward prevented"):
		return
	_show_summary()
	if not _smoke_check(is_instance_valid(modal_body) and "XP" in modal_body.text, "Summary shows XP"):
		return
	_close_modal()
	_show_history()
	if not _smoke_check(is_instance_valid(modal_body) and "Prueba" in modal_body.text, "History shows participant"):
		return
	_close_modal()
	_show_fighter_details()
	if not _smoke_check(is_instance_valid(modal_body) and "RESISTENCIA" in modal_body.text, "Stats include resistance"):
		return
	_close_modal()
	_start_fight()
	while active_match:
		await get_tree().process_frame
	if not _smoke_check(int(progression.data.matches) == previous_matches + 2, "Replay rewards exactly once"):
		return
	_start_fight()
	_confirm_surrender()
	var paused_elapsed: float = combat.elapsed
	await get_tree().process_frame
	if not _smoke_check(is_instance_valid(modal_layer) and combat.elapsed == paused_elapsed, "Surrender confirmation pauses engine"):
		return
	_close_modal()
	if not _smoke_check(active_match and combat.running, "Cancelled surrender resumes battle"):
		return
	_confirm_surrender()
	_accept_surrender()
	if not _smoke_check(not active_match and not combat.running and last_battle_summary.reason == "surrender", "Confirmed surrender immediately terminal"):
		return
	if not _smoke_check(int(last_reward.player.xp_gained) >= 1 and int(progression.data.matches) == previous_matches + 3, "Surrender grants nonzero XP once"):
		return
	var restored = ProgressScript.new()
	var path: String = session_save_path
	restored.load_save(path)
	if not _smoke_check(restored.data == progression.data, "Progress survives reload"):
		return
	var saved_life: int = int(progression.data.stats.life)
	_choose_character("iria", "Iria")
	_choose_character("mugo", "Prueba")
	if not _smoke_check(int(progression.data.stats.life) == saved_life and int(progression.data.matches) == previous_matches + 3, "Roster preserves individual progression"):
		return
	Engine.time_scale = 1.0
	print("UI_SMOKE_PASS: roster, training drawer, upgrade, signature, fight, unique reward, summary, history, details, replay, surrender cancel/confirm, reload")
	get_tree().quit(0)

func _smoke_check(condition: bool, message: String) -> bool:
	if not condition:
		push_error("UI_SMOKE_FAIL: " + message)
		get_tree().quit(1)
	return condition
