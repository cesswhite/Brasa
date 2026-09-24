extends Control
const CombatantHUD = preload("res://scripts/ui/components/game_combatant_hud.gd")
const ResultPanel = preload("res://scripts/ui/components/game_battle_result_panel.gd")
const Layout = preload("res://scripts/ui/battle_layout.gd")
const Visuals = preload("res://scripts/ui/game_visual_system.gd")
const OverlayFocus = preload("res://scripts/ui/components/game_overlay_focus.gd")
## Playback of recorded events only. No combat engine, rewards or live identities.
signal closed
const Records = preload("res://scripts/battle_identity.gd")
const Fighter = preload("res://scripts/fighter_view.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Story = preload("res://scripts/story_catalog.gd")
const CombatFXScript = preload("res://scripts/combat_fx.gd")
var snapshots: Array[Dictionary] = []
var snapshot: Dictionary = {}
var actors: Dictionary = {}
var bars: Dictionary = {}
var elapsed := 0.0
var event_index := 0
var playing := false
# The caller supplies the viewer's side for online records. Neither field changes
# the frozen combatants, recorded outcome, or rewards.
var playback_mode: String = "replay"
var viewing_side: String = "player"
var result_context: String = ""
var _audio_generation: int = 0
var _audio_session_id: String = ""
var _audio_active: bool = false
var _audio_arena_id: String = "arena_faroles"
var _stage: Control
var _background: TextureRect
var _top_veil: TextureRect
var _bottom_veil: TextureRect
var _rig: Node2D
var _fx: Node2D
var _picker: OptionButton
var _title: Label
var _note: Label
var _event: Label
var _clock: Label
var _close: Button
var _play: Button
var _restart: Button
var _names: Dictionary = {}
var _huds: Dictionary = {}
var _result: Panel
var _continue: Button
var _result_veil: ColorRect
var _finished := false

func configure(history: Array) -> void:
	_stop_audio()
	_ensure_ui()
	Visuals.reveal(self)
	snapshots.clear()
	_picker.clear()
	for index: int in range(history.size()-1, -1, -1):
		var frozen := Records.snapshot(history[index])
		if frozen.is_empty(): continue
		snapshots.append(frozen)
		_picker.add_item("%s · %s contra %s" % ["Victoria" if frozen.winner == "player" else "Derrota", frozen.player.get("name", "Compañero"), frozen.rival.get("name", "Rival")])
	if snapshots.is_empty():
		snapshot.clear()
		playing = false
		_note.text = "Las repeticiones se guardan con tus próximos combates."
		_play.disabled = true
		_restart.disabled = true
	else: select_snapshot(0)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ensure_ui()
	resized.connect(_layout)
	_layout()

func _ensure_ui() -> void:
	if _title != null: return
	set_meta("world_screen_background",true)
	theme = Visuals.theme()
	_background = TextureRect.new()
	_background.texture = load("res://assets/arena-faroles-v2.png")
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_top_veil = Visuals.battle_veil(false)
	_bottom_veil = Visuals.battle_veil(true)
	add_child(_top_veil)
	add_child(_bottom_veil)
	_title = _label("Repeticiones", "title")
	_note = _label("Nombre y aspecto originales · Repetición sin recompensas", "secondary", "text_secondary")
	_close = _button("×", _request_close, "icon")
	_close.tooltip_text = "Volver · Esc"
	_picker = OptionButton.new()
	_picker.fit_to_longest_item = false
	_picker.clip_text = true
	Visuals.apply_option(_picker)
	_picker.item_selected.connect(select_snapshot)
	add_child(_picker)
	_stage = Control.new()
	_stage.clip_contents = true
	add_child(_stage)
	_rig = Node2D.new()
	_stage.add_child(_rig)
	for side: String in ["player", "rival"]:
		var actor := Fighter.new()
		_rig.add_child(actor)
		actors[side] = actor
		var hud = CombatantHUD.new()
		add_child(hud)
		hud.configure(side == "rival")
		_huds[side] = hud
		_names[side] = hud.name_label
		bars[side] = hud.bar
	_fx = CombatFXScript.new()
	_rig.add_child(_fx)
	_event = _label("", "body")
	_event.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_clock = _label("00:00", "card", "current")
	_play = _button("Reproducir", _toggle, "primary")
	_restart = _button("Desde el inicio", restart)
	_result_veil = ColorRect.new()
	_result_veil.color = Color(0.015,0.025,0.03,0.38)
	_result_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_result_veil)
	_result_veil.hide()
	_result = ResultPanel.new()
	add_child(_result)
	_result.hide()
	_continue = _button("Volver a Arena online", _request_close, "primary")
	_continue.hide()
	move_child(_close,get_child_count()-1)
	_close.grab_focus.call_deferred()

func _label(value: String, role: String, tone: String = "text_primary") -> Label:
	var label := Label.new()
	label.text = value
	Visuals.apply_label(label, role, tone)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(label)
	return label

func _button(value: String, action: Callable, role: String = "secondary") -> Button:
	var button := Button.new()
	button.text = value
	button.pressed.connect(action)
	button.clip_text = true
	Visuals.apply_button(button, role)
	add_child(button)
	return button

func _place(node: Control, rect: Rect2) -> void:
	node.position = rect.position
	node.size = rect.size

func _layout() -> void:
	if _title == null or size.x <= 0: return
	var short := size.y < 540
	var compact := size.x < 640 or short
	var margin := Visuals.space("lg") if size.x < 640 else Visuals.space("xxl")
	var width := size.x - margin * 2
	_place(_title, Rect2(margin, 12, width-56, 36))
	_title.add_theme_font_size_override("font_size", Visuals.font_size("title", compact))
	_place(_close, Rect2(size.x-margin-48, 8, 48, 48))
	_note.visible = not short
	_note.text = "Aspecto original · Sin recompensas" if size.x < 640 else "Nombre y aspecto originales · Repetición sin recompensas"
	if snapshots.is_empty(): _note.text = "Tus próximas peleas quedarán aquí."
	_note.tooltip_text = _note.text
	_place(_note, Rect2(margin, 54, width, 28))
	var top := 66.0 if short else 92.0
	_place(_picker, Rect2(margin, top, width, 44))
	var online: bool = playback_mode == "online"
	_title.visible = not online
	_note.visible = not online and not short
	_picker.visible = not online
	if online:
		_close.text = "Menú"
		Visuals.apply_button(_close,"secondary")
		_place(_close,Rect2(size.x/2-48,8,96,44))
	var hud := (60.0 if short else 72.0) if online else top+52
	var cell := (width-20)/2
	var hud_width: float = minf(360,cell) if online else cell
	_place(_huds.player, Rect2(margin,hud,hud_width,96 if short else 110))
	_place(_huds.rival, Rect2(size.x-margin-hud_width,hud,hud_width,96 if short else 110))
	if not online:
		for side: String in _huds:
			var frame = _huds[side]
			frame.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
			frame.level_label.hide()
			frame.hp_label.hide()
			_place(frame.name_label,Rect2(0,0,hud_width,28))
			_place(frame.bar,Rect2(0,30,hud_width,10))
	var stage_top := hud+((104 if short else 118) if online else 48)
	_place(_top_veil, Rect2(0, 0, size.x, stage_top+100))
	_place(_bottom_veil, Rect2(0, size.y-160, size.x, 160))
	_place(_stage, Rect2(margin, stage_top, width, maxf(60, size.y-stage_top-122)))
	# Include jump height and grounded recoil inside the clipped replay stage.
	var scale_value := minf((_stage.size.y-12)/Fighter.VisualProfiles.WORLD_ENVELOPE.size.y, width/460.0)
	var framing := Layout.actor_framing(width,scale_value,Layout.COMPACT_GAP_UNITS,8.0)
	for side: String in actors:
		if not online: _names[side].add_theme_font_size_override("font_size", Visuals.font_size("card", compact))
		actors[side].scale = Vector2.ONE * float(framing.scale)
		actors[side].position = Vector2(width/2 + (-1 if side == "player" else 1)*float(framing.half_gap), _stage.size.y-16*float(framing.scale)-4)
	# Both neutral roots must be placed before resolving their shared contact.
	for side: String in actors:
		actors[side].set_combat_lane(float(framing.half_gap)/float(framing.scale)-6.0, actors["rival" if side == "player" else "player"])
	_place(_event, Rect2(margin, size.y-114, width-76, 52))
	_place(_clock, Rect2(size.x-margin-72, size.y-108, 72, 28))
	_place(_play, Rect2(margin, size.y-56, cell, 44))
	_place(_restart, Rect2(margin+cell+20, size.y-56, cell, 44))
	if _result != null:
		var result_layout: Dictionary = Layout.calculate(size,false,true)
		_place(_result_veil,Rect2(Vector2.ZERO,size))
		_place(_result,result_layout.result)
		_result.layout_compact(short,size.x<640)
		_place(_continue,result_layout.primary)
		_play.visible = not (online and _finished)
		_restart.visible = not (online and _finished)
		_event.visible = not (online and _finished)
		_clock.visible = not (online and _finished)

func _input(event: InputEvent) -> void:
	OverlayFocus.handle(event, self, _request_close)

func _request_close() -> void:
	_stop_audio()
	closed.emit()

func select_snapshot(index: int) -> void:
	if index < 0 or index >= snapshots.size(): return
	snapshot = snapshots[index].duplicate(true)
	_picker.select(index)
	var chapter := int(snapshot.rival.get("story_chapter_id", 1))
	var background_path := str(Story.chapter(chapter).get("background", "res://assets/arena-faroles-v2.png"))
	_background.texture = load(background_path)
	_audio_arena_id = "arena_tormenta" if background_path == "res://assets/arena-tormenta-v3.png" else "arena_faroles"
	restart()

func restart() -> void:
	_finished = false
	_result.hide()
	_result_veil.hide()
	_continue.hide()
	_stop_audio()
	_fx.clear()
	_fx.motion_paused = true
	_rig.position = Vector2.ZERO
	elapsed = 0.0
	event_index = 0
	playing = false
	_play.text = "Reproducir"
	_event.text = "Repetición · Sin nuevas recompensas."
	_clock.text = "00:00"
	for side: String in actors:
		var descriptor: Dictionary = snapshot.get(side, {})
		actors[side].setup_character(descriptor, 1 if side == "player" else -1)
		actors[side].reset_pose()
		actors[side].prepare_combat_animation()
		actors[side].motion_paused = true
		_names[side].text = str(descriptor.get("name", "")) if playback_mode == "online" else "%s · Nv. %d" % [descriptor.get("name", ""), int(descriptor.get("level", 1))]
		_huds[side].level_label.text = "NIVEL %d" % int(descriptor.get("level",1))
		_names[side].tooltip_text = _names[side].text
		bars[side].max_value = float(descriptor.get("combat_stats", {}).get("max_hp", 1))
		bars[side].value = bars[side].max_value
		_huds[side].refresh_health()
	_layout()
	_begin_audio()

func _toggle() -> void:
	if snapshot.is_empty(): return
	if elapsed >= float(snapshot.duration): restart()
	playing = not playing
	_fx.motion_paused = not playing
	_play.text = "Pausar" if playing else "Reproducir"
	for actor: Node2D in actors.values(): actor.motion_paused = not playing
	var director := _audio_director()
	if _audio_active and director != null: director.set_paused(not playing)

func _process(delta: float) -> void:
	if is_instance_valid(_fx):
		_fx.motion_paused = not playing and elapsed < float(snapshot.get("duration",0))
		_rig.position = _fx.camera_offset()
	if not playing or snapshot.is_empty(): return
	elapsed = minf(elapsed+delta, float(snapshot.duration))
	while event_index < snapshot.events.size():
		var event: Dictionary = snapshot.events[event_index]
		if float(event.get("time", 0)) > elapsed: break
		_apply_event(event)
		event_index += 1
	var director := _audio_director()
	if _audio_active and director != null: director.advance(elapsed)
	_clock.text = "%02d:%02d" % [int(elapsed)/60, int(elapsed)%60]
	if elapsed >= float(snapshot.duration):
		playing = false
		_play.text = "Repetir"
		if playback_mode == "online" and not _finished:
			_finished = true
			_result.title_label.text = "¡VICTORIA!" if str(snapshot.get("winner","")) == viewing_side else "DERROTA"
			_result.copy_label.text = result_context if not result_context.is_empty() else "Combate terminado · Resultado registrado"
			_result.show()
			_result_veil.show()
			_continue.show()
			_layout()
			_continue.grab_focus()

func _apply_event(event: Dictionary) -> void:
	var side := str(event.get("side", "player"))
	var target := str(event.get("target", "rival" if side == "player" else "player"))
	if not actors.has(side) or not actors.has(target): return
	var director := _audio_director()
	if _audio_active and director != null:
		director.on_combat_event(event.duplicate(true), elapsed, event_index)
	if not str(event.get("message", "")).is_empty(): _event.text = str(event.message)
	for team: String in bars:
		actors[team].observe_combat_health(event,team,float(bars[team].max_value))
		if event.has(team+"_hp"): bars[team].value = float(event[team+"_hp"])
		actors[team].set_health_ratio(float(bars[team].value)/maxf(1,float(bars[team].max_value)))
	var age := maxf(0,elapsed-float(event.get("time",elapsed)))
	match str(event.get("type", "")):
		"move_started":
			var move: Dictionary = event.get("move", {}).duplicate(true)
			if bool(event.get("counter", false)):
				move["is_counter_reaction"] = true
				move["animation_type"] = "dash"
			actors[side].play_move(move, maxf(0, elapsed-float(event.get("time", elapsed))))
			_fx.play_move(event,actors[side],age)
		"attack":
			var critical: bool = str(event.get("result", "")) in ["critical", "signature"]
			actors[side].move_impact(critical, str(event.get("move_id", "")))
			if str(event.get("result", "")) == "dodge": actors[target].play_dodge()
			elif str(event.get("result", "")) != "miss":
				var reaction_event: Dictionary = actors[side].prepare_reaction_event(event, age)
				var presentation: Dictionary = actors[target].play_reaction(reaction_event)
				presentation["animation_type"] = event.get("animation_type","")
				presentation["signature"] = str(event.get("result",""))=="signature"
				actors[side].request_hit_stop(float(presentation.get("hit_stop",0)))
				actors[target].request_hit_stop(float(presentation.get("hit_stop",0)))
				var impact_at: Vector2 = _fx.to_local(actors[target].to_global(actors[target].effect_anchor("chest")))
				_fx.play_impact(impact_at,presentation,actors[target].scale.x,actors[side].facing,age,actors[target])
				actors[target].illuminate_effect(Color("ffd39a"),0.06 if critical else 0.025,0.18,age)
		"heal", "shield", "status_tick", "ability", "status_applied", "defensive_stance":
			var affected := str(event.get("target",side))
			if actors.has(affected):
				_fx.play_status(event,actors[affected],age)
				if str(event.get("type",""))=="status_tick":
					if event.has("target_hp") and float(event.target_hp) <= 0.0:
						var reaction_event := event.duplicate(true)
						reaction_event["presentation_elapsed"] = age
						actors[affected].play_reaction(reaction_event)
					else:
						actors[affected].play_hit(false)
				if str(event.get("type",""))=="defensive_stance": actors[affected].defensive_stance = true
				if str(event.get("ability_id",""))=="phase_shift" and int(event.get("phase_index",0))>0: actors[affected].play_transformation("ember_core")
		"signature":
			if actors[side].play_transformation("ember_core"):
				_fx.emit_attached("transformation",actors[side],"body",age)
		"stance_expired":
			actors[side].defensive_stance = false
		"finished":
			var winner := str(event.get("winner", "player"))
			actors[winner].resolve_battle(true)
			actors["rival" if winner == "player" else "player"].resolve_battle(false)

func _audio_director() -> Node:
	if not is_inside_tree(): return null
	return get_tree().get_first_node_in_group("brasa_audio_director")

func _begin_audio() -> void:
	if snapshot.is_empty(): return
	_audio_generation += 1
	_audio_session_id = "replay:%d:%d" % [get_instance_id(), _audio_generation]
	var director := _audio_director()
	if director == null: return
	director.configure_context(_audio_arena_id, {
		"player": snapshot.player.duplicate(true), "rival": snapshot.rival.duplicate(true),
	}, {
		"session_id": _audio_session_id, "battle_id": str(snapshot.get("battle_id", "")),
		"mode": playback_mode, "viewing_side": viewing_side if viewing_side in ["player", "rival"] else "player",
		"result_audio": true,
	})
	director.set_paused(true)
	_audio_active = true

func _stop_audio() -> void:
	if not _audio_active: return
	var director := _audio_director()
	if director != null:
		# A deferred queue_free from an older panel cannot stop a newer session.
		director.stop_session(_audio_session_id)
	_audio_active = false

func _exit_tree() -> void:
	_stop_audio()
