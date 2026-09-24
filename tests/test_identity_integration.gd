extends SceneTree
const EngineScript = preload("res://scripts/combat_engine.gd")
const Progress = preload("res://scripts/progression.gd")
const Story = preload("res://scripts/story_progression.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Cosmetics = preload("res://scripts/cosmetic_catalog.gd")
const Records = preload("res://scripts/battle_identity.gd")
const Identity = preload("res://scripts/fighter_identity.gd")

class Fixture:
	extends "res://scripts/main.gd"
	var fixture_path := ""
	func _ready() -> void:
		session_save_path = fixture_path
		sound_enabled = false
		set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		_build_theme()
		_build_interface()
		progression.load_save(fixture_path)
		_initialize_identity()
		_prepare_rival()
		_refresh_manager()
		_update_portraits()
		set_process(false)

var checks := 0
var failures := 0
var screen: Fixture
var canvas: SubViewport
var capture_dir := ""

func _init() -> void: _run.call_deferred()
func _check(ok: bool, detail: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("IDENTITY INTEGRATION: "+detail)

func _run() -> void:
	create_timer(90,true,false,true).timeout.connect(func(): push_error("IDENTITY INTEGRATION timeout"); quit(1))
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): capture_dir = arg.trim_prefix("--capture-dir=")
	if not capture_dir.is_empty(): DirAccess.make_dir_recursive_absolute(capture_dir)
	var directory := ProjectSettings.globalize_path("res://../../work/identity/fixtures").simplify_path()
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory.path_join("integration_%d.json" % Time.get_ticks_usec())
	var league = Progress.new()
	league.load_save(path)
	league.select_character("tepa", "Conejo Antiguo")
	var story = Story.new()
	story.load_save(path+".story.json")
	story.select_character("tepa", "Conejo Historia")
	var league_bytes := FileAccess.get_file_as_string(path)
	var story_bytes := FileAccess.get_file_as_string(path+".story.json")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(360,240)
	canvas = SubViewport.new()
	canvas.size = Vector2i(1360,880)
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	screen = Fixture.new()
	screen.fixture_path = path
	canvas.add_child(screen)
	screen.size = Vector2(1360,880)
	screen._layout_interface(screen.size)
	await process_frame
	_check(FileAccess.get_file_as_string(path)==league_bytes and FileAccess.get_file_as_string(path+".story.json")==story_bytes, "Boot migration leaves both gameplay files byte-identical")
	_check(not FileAccess.file_exists(path+".identity.json"), "Read-only boot does not write identity")
	var original_build: Dictionary = screen.progression.data.duplicate(true)
	var original_story: Dictionary = screen.story_progression.data.duplicate(true)
	var original_power: Dictionary = Catalog.stats_for(original_build)
	screen._show_roster()
	_check(screen.creation_layer._customize_button.visible, "Roster exposes visual editor")
	screen.creation_layer.customize_requested.emit("tepa")
	await process_frame
	_check(is_instance_valid(screen.customization_layer), "Roster opens customization")
	_check(not is_instance_valid(screen.creation_layer), "Editor replaces roster without duplicate overlays")
	var appearance := Cosmetics.default_appearance("tepa")
	appearance.body_style_id = "luma"
	appearance.palette_id = "jade"
	appearance.victory_pose_id = "saludo"
	appearance.intro_animation_id = "pulso"
	screen.customization_layer.confirmed.emit("tepa", "COMETA NEGRO", appearance)
	await process_frame
	_check(not is_instance_valid(screen.customization_layer), "Valid confirmation closes editor")
	_check(is_instance_valid(screen.creation_layer), "Editing from roster returns to roster")
	screen._close_roster()
	await process_frame
	_check(screen.progression.data == original_build and screen.story_progression.data == original_story, "Cosmetics never rewrite either gameplay profile")
	_check(Catalog.stats_for(screen.progression.data)==original_power, "Different body and colors leave every combat stat unchanged")
	_check(screen.player_name_label.text == "COMETA NEGRO", "HUD shows chosen identity")
	_check(screen.player_view.get_sprite_geometry().path == "res://assets/sprites/ajolote-v2.png", "Tepa gameplay can use Luma visual body")
	var persisted := FileAccess.get_file_as_string(path+".identity.json")
	screen._open_customization()
	screen.customization_layer.cancelled.emit()
	await process_frame
	_check(FileAccess.get_file_as_string(path+".identity.json")==persisted, "Cancel preserves stored equipment and name")
	var before: Dictionary = screen.fighter_identity.entry("tepa")
	var stable_id := str(before.fighter_id)
	screen._enter_story()
	_check(screen.story_layer._subtitle.text.contains("COMETA NEGRO"), "Same identity reaches Story heading")
	_check(screen.player_view.get_sprite_geometry().path == "res://assets/sprites/ajolote-v2.png", "Same appearance reaches Story battlefield")
	screen.story_layer.show_tab("companions")
	await _capture("historia-identidad.png")
	screen._leave_story()
	await process_frame
	screen._start_fight()
	_check(screen.active_match, "Customized fighter enters league battle")
	_check(screen.combat._fighters.player.descriptor.fighter_id == stable_id, "Battle captures stable ID")
	screen._open_customization()
	_check(not is_instance_valid(screen.customization_layer), "In-progress battle rejects customization UI")
	# Simulate an external identity change while the immutable battle is active.
	var later := appearance.duplicate(true)
	later.body_style_id = "balam"
	later.palette_id = "ocaso"
	_check(screen.fighter_identity.update_fighter("tepa","NUEVA COMETA",later).ok, "Later appearance can be saved independently")
	_check(screen.combat._fighters.player.descriptor.name == "COMETA NEGRO", "Active match retains old name")
	_check(screen.combat._fighters.player.descriptor.appearance.body_style_id == "luma", "Active match retains old body")
	_check(screen.player_view.get_sprite_geometry().path == "res://assets/sprites/ajolote-v2.png", "Active render stays frozen")
	await _capture("combate-identidad.png")
	screen._dispatch_events(screen.combat.advance(120.0))
	while screen.active_match: await process_frame
	_check(screen.progression.history.size()==1, "Natural match rewards once and writes one history record")
	var record: Dictionary = screen.progression.history.back()
	_check(record.player_name == "COMETA NEGRO" and record.player_fighter_id == stable_id, "History records battle-time name and stable ID")
	_check(Records.snapshot(record).player.appearance == appearance, "History saves original appearance snapshot")
	var reloaded = Progress.new()
	reloaded.load_save(path)
	_check(not reloaded.save_blocked and Records.snapshot(reloaded.history.back()).player.name == "COMETA NEGRO", "Historical identity survives gameplay reload")
	var history_copy: Dictionary = Records.snapshot(record)
	history_copy.player.appearance.body_style_id = "mugo"
	_check(Records.snapshot(record).player.appearance.body_style_id == "luma", "Snapshot access returns deep copies")
	var gameplay_after := FileAccess.get_file_as_string(path)
	screen._show_history()
	_check(is_instance_valid(screen.modal_accept), "History exposes replay action")
	screen.modal_accept.pressed.emit()
	await process_frame
	_check(is_instance_valid(screen.replay_layer) and screen.replay_layer.snapshot.player.name == "COMETA NEGRO", "Replay uses historical name")
	_check(screen.replay_layer.actors.player.get_sprite_geometry().path == "res://assets/sprites/ajolote-v2.png", "Replay renders historical body, not current Balam")
	screen.replay_layer._toggle()
	screen.replay_layer._process(120)
	_check(not screen.replay_layer.playing and screen.replay_layer.event_index == screen.replay_layer.snapshot.events.size(), "Replay consumes recorded events and finishes")
	await _capture("repeticion-identidad.png")
	for view: Vector2i in [Vector2i(390,844),Vector2i(844,390)]:
		canvas.size = view
		screen.size = Vector2(view)
		screen._layout_interface(screen.size)
		await process_frame
		await _capture("repeticion-%dx%d.png" % [view.x,view.y])
		_check(screen.replay_layer._stage.get_rect().end.y < screen.replay_layer.size.y, "Replay stage fits viewport")
	screen._close_replays()
	await process_frame
	_check(FileAccess.get_file_as_string(path)==gameplay_after, "Replay cannot grant XP or rewrite history")
	screen._enter_story()
	screen._close_story_panel()
	await process_frame
	screen._start_fight()
	screen._dispatch_events(screen.combat.advance(120))
	while screen.active_match: await process_frame
	var story_record: Dictionary = screen.story_progression.history.back()
	_check(story_record.player_name == "NUEVA COMETA" and story_record.player_fighter_id == stable_id, "Story shares stable identity and stores newer name")
	_check(Records.snapshot(story_record).player.appearance.body_style_id == "balam", "Story records new appearance independently of old league replay")
	_cosmetic_parity()
	await _creation_flow(directory)
	screen.queue_free()
	canvas.queue_free()
	await process_frame
	print("IDENTITY INTEGRATION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

class FreshFixture:
	extends "res://scripts/main.gd"
	var fixture_path := ""
	func _ready() -> void:
		session_save_path = fixture_path
		sound_enabled = false
		set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		_build_theme()
		_build_interface()
		progression.load_save(fixture_path)
		_initialize_identity()
		_show_creation()
		set_process(false)

func _creation_flow(directory: String) -> void:
	var fresh := FreshFixture.new()
	fresh.fixture_path = directory.path_join("new_player_%d.json" % Time.get_ticks_usec())
	canvas.add_child(fresh)
	fresh.size = Vector2(canvas.size)
	fresh._layout_interface(fresh.size)
	await process_frame
	_check(is_instance_valid(fresh.customization_layer) and fresh.progression.data.is_empty(), "New account sees creator before any progression")
	_check(fresh.customization_layer._archetype.visible and not fresh.customization_layer._archetype.disabled, "Gameplay base chooser exists during creation")
	var appearance := Cosmetics.default_appearance("mugo")
	appearance.body_style_id = "tepa"
	appearance.palette_id = "ocaso"
	fresh.customization_layer.confirmed.emit("mugo", "Mi Guardián", appearance)
	await process_frame
	_check(fresh.story_mode and is_instance_valid(fresh.story_layer), "Confirming a first fighter enters Story preparation")
	_check(fresh.league_progression.active_id=="mugo" and fresh.story_progression.active_id=="mugo", "First fighter is shared between Liga and Story")
	_check(fresh.league_progression.data.level==1 and fresh.story_progression.data.level==1, "Creation does not grant hidden power")
	_check(fresh._player_combatant().name=="Mi Guardián" and fresh.player_view.get_sprite_geometry().path.ends_with("tepa-v1.png"), "Chosen name/body appear in Story with Mugo gameplay")
	fresh.queue_free()
	await process_frame

func _cosmetic_parity() -> void:
	for id: String in Catalog.IDS:
		var profile := Progress._new_profile(id)
		var raw := Progress._combatant(profile)
		var dressed := raw.duplicate(true)
		dressed["fighter_id"] = "parity:"+id
		dressed["identity"] = {"display_name":"OTRO NOMBRE"}
		dressed["name"] = "OTRO NOMBRE"
		dressed["appearance"] = Cosmetics.default_appearance("luma")
		dressed.appearance.palette_id = "jade"
		for seed_value: int in [917,1223,7397]:
			var left = EngineScript.new()
			var right = EngineScript.new()
			var rival := Progress._combatant(Progress._new_profile("balam"))
			left.start(raw,rival,seed_value)
			right.start(dressed,rival,seed_value)
			left.advance(120)
			right.advance(120)
			var a: Dictionary = left.summary()
			var b: Dictionary = right.summary()
			# Battle IDs intentionally fingerprint their different identity snapshots.
			a.terminal_state.erase("battle_id")
			b.terminal_state.erase("battle_id")
			_check(a.winner==b.winner and a.duration==b.duration and a.metrics==b.metrics and a.terminal_state==b.terminal_state, "Cosmetics are numerically inert: "+id+" seed "+str(seed_value))

func _capture(filename: String) -> void:
	if capture_dir.is_empty(): return
	if DisplayServer.get_name()=="headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	_check(canvas.get_texture().get_image().save_png(capture_dir.path_join(filename))==OK,"Saved native capture "+filename)
