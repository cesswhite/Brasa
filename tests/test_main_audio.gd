extends SceneTree
## Boundary checks use real Main + real seeded engine and disposable saves.
## RecordingAudio observes dispatch only; director routing/mixing has its own suite.
const Base = preload("res://tests/test_identity_integration.gd")
const Progress = preload("res://scripts/progression.gd")
const Story = preload("res://scripts/story_progression.gd")
const StoryCatalog = preload("res://scripts/story_catalog.gd")
const Director = preload("res://scripts/audio/audio_director.gd")
const Sizes = preload("res://tests/test_battle_layout.gd")
const Visuals = preload("res://scripts/ui/game_visual_system.gd")

class RecordingAudio:
	extends Node
	var events: Array[Dictionary] = []
	var ui: Array[String] = []
	var times: Array[float] = []
	var contexts: Array[Dictionary] = []
	var paused := false
	var last_save_ok := true
	var load_notice := ""
	var settings := {"master":0.65,"music":0.35,"sfx":0.75,"enabled":true}
	func setup(_path: String, _silent: bool = false) -> void: pass
	func configure_context(arena_id: String, profiles: Dictionary, context: Dictionary = {}) -> void:
		contexts.append({"arena":arena_id,"profiles":profiles.duplicate(true),"context":context.duplicate(true)})
	func on_combat_event(event: Dictionary, time: float, index: int) -> void:
		events.append({"event":event.duplicate(true),"time":time,"index":index})
	func advance(time: float) -> void: times.append(time)
	func set_paused(value: bool) -> void: paused=value
	func set_volumes(value: Dictionary, _persist: bool = true) -> void: settings.merge(value,true)
	func get_settings() -> Dictionary: return settings.duplicate(true)
	func play_ui(id: String, _context: Dictionary = {}) -> void: ui.append(id)
	func stop_session() -> void: pass
	func debug_state() -> Dictionary:
		return {"session":str(contexts.back().context.get("session_id","")) if not contexts.is_empty() else ""}

var checks := 0
var failures := 0
var screen
var viewport: SubViewport
var folder := ""

func _init() -> void: _run.call_deferred()
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("MAIN AUDIO: "+message)

func _run() -> void:
	create_timer(90,true,false,true).timeout.connect(func(): push_error("MAIN AUDIO timeout"); quit(1))
	folder=ProjectSettings.globalize_path("res://../../work/audio/main-integration").simplify_path()
	DirAccess.make_dir_recursive_absolute(folder.path_join("fixtures"))
	var path := folder.path_join("fixtures/main-%d.json" % Time.get_ticks_usec())
	var league = Progress.new()
	league.load_save(path)
	check(league.select_character("mugo"),"Create Mugo fixture")
	var story = Story.new()
	story.load_save(path+".story.json")
	check(story.select_character("mugo"),"Create separate Story fixture")
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(360,240)
	viewport=SubViewport.new()
	viewport.size=Vector2i(1360,880)
	root.add_child(viewport)
	screen=Base.Fixture.new()
	screen.fixture_path=path
	viewport.add_child(screen)
	screen.size=Vector2(viewport.size)
	screen._layout_interface(screen.size)
	screen.sound_enabled=true
	var before := _bytes(path)
	screen._make_sounds()
	check(is_instance_valid(screen.audio_director),"Main initializes the real central director")
	check(screen.audio_director.is_in_group("brasa_audio_director"),"Replay can discover the same director")
	check(not FileAccess.file_exists(path+".audio.cfg"),"Boot does not write volume preferences")
	check(_bytes(path)==before,"Audio boot leaves both gameplay files unchanged")
	screen._show_settings()
	check(is_instance_valid(screen.audio_settings) and screen.audio_settings.sliders.size()==3,"Three volume controls appear within shared Settings")
	check(screen.menu_actions.size()==4,"Four existing settings actions remain")
	check(not FileAccess.file_exists(path+".audio.cfg"),"Opening Settings does not write preferences")
	for view: Vector2 in Sizes.SIZES:
		viewport.size=Vector2i(view)
		screen.size=view
		screen._layout_interface(view)
		await process_frame
		await process_frame
		for key: String in ["master","music","sfx"]:
			var slider: HSlider=screen.audio_settings.sliders[key]
			check(slider.size.y>=48 and slider.focus_mode==Control.FOCUS_ALL,"Accessible 48px volume "+key+str(view))
			check(slider.get_theme_stylebox("slider")==Visuals.theme().get_stylebox("slider","HSlider"),"Slider uses shared material "+key)
			check(Rect2(Vector2.ZERO,screen.audio_settings.size).grow(1).encloses(slider.get_rect()),"Volume slider fits its responsive content "+key)
		var scroll: ScrollContainer=screen.modal_layer.parts().scroll
		var last: HSlider=screen.audio_settings.sliders.sfx
		last.grab_focus()
		scroll.ensure_control_visible(last)
		await process_frame
		check(scroll.get_global_rect().grow(1).encloses(last.get_global_rect()),"Last volume is reachable in scroll "+str(view))
	check(_bytes(path)==before,"Resizing/focusing/scrolling Settings never writes gameplay")
	screen.audio_settings.sliders.master.value=0.64
	screen.audio_settings.sliders.music.value=0.31
	screen.audio_settings.sliders.sfx.value=0.78
	check(FileAccess.file_exists(path+".audio.cfg"),"Changing volume writes only explicit fixture .audio.cfg")
	check(screen.audio_director.last_save_ok,"Preference commit succeeds")
	check(_bytes(path)==before,"Volume changes preserve both gameplay files")
	var saved_audio := FileAccess.get_file_as_bytes(path+".audio.cfg")
	screen._close_modal()
	screen._show_settings()
	check(FileAccess.get_file_as_bytes(path+".audio.cfg")==saved_audio,"Reopening Settings is read-only")
	var settings: Dictionary=screen.audio_director.get_settings()
	check(is_equal_approx(settings.master,0.64) and is_equal_approx(settings.music,0.31) and is_equal_approx(settings.sfx,0.78),"Displayed controls reach correct independent buses")
	var probe:=Director.new()
	root.add_child(probe)
	probe.setup(path+".audio.cfg",true)
	check(probe.get_settings()==settings,"Preferences survive fresh director reload")
	probe.free()
	screen._toggle_sound()
	var muted: Dictionary=screen.audio_director.get_settings()
	check(not bool(muted.enabled) and muted.master==settings.master and muted.music==settings.music and muted.sfx==settings.sfx,"Mute retains all mix values")
	screen._toggle_sound()
	check(screen.audio_director.get_settings()==settings,"Unmute restores retained mix")
	screen._close_modal()
	# Observe Main's dispatch independently from its director implementation.
	screen.audio_director.free()
	var audio:=RecordingAudio.new()
	screen.add_child(audio)
	screen.audio_director=audio
	viewport.size=Vector2i(1360,880)
	screen.size=Vector2(viewport.size)
	screen._layout_interface(screen.size)
	var boss: Dictionary=StoryCatalog.opponent(7,1)
	boss["opponent_id"]="npc_audio_ascua"
	screen.rival=boss
	screen._start_fight()
	check(screen.active_match,"Real Main action starts isolated Ascua fight")
	check(audio.contexts.size()==1 and audio.contexts[0].arena=="arena_faroles","Audio follows actual rendered Faroles arena")
	check(audio.contexts[0].profiles.rival.get("story_boss_id","")=="ascua","Ascua body is preserved despite mugo archetype")
	check(audio.ui==["fight_intro"],"Battle confirm emits one intro, no legacy start tone")
	var player: Dictionary=screen._player_combatant()
	var player_before := var_to_bytes(player)
	var boss_before := var_to_bytes(boss)
	# Force only a rare presentation branch in this fixture; keep all damage rules.
	screen.combat.start(player,boss,970217,{"force_signature":"rival","signature_turn":2,"opening_time":0.20,"battle_id":"audio-main-ascua"})
	screen._configure_combat_audio(player,boss)
	check(var_to_bytes(player)==player_before and var_to_bytes(boss)==boss_before,"Audio context does not mutate either descriptor")
	var clock_before: float=screen.combat.elapsed
	screen._open_document("Pausa de prueba","Fixture","El reloj debe detenerse.")
	check(audio.paused,"Opening live modal pauses director immediately")
	screen._process(1.0)
	check(screen.combat.elapsed==clock_before and audio.events.is_empty(),"Paused Main emits no extra audio or gameplay events")
	screen._close_modal()
	check(not audio.paused,"Closing modal resumes director")
	screen.reduced_motion=true
	screen._apply_motion_preference()
	var authoritative: Array[Dictionary]=[]
	while screen.combat.running:
		var batch: Array[Dictionary]=screen.combat.advance(0.07)
		var before_batch := var_to_bytes(batch)
		authoritative.append_array(batch.duplicate(true))
		screen._dispatch_events(batch)
		check(var_to_bytes(batch)==before_batch,"Dispatch leaves authoritative batch immutable")
	while screen.active_match: await process_frame
	check(audio.events.size()==authoritative.size(),"Every real engine event reaches audio exactly once with reduced motion")
	for index: int in range(audio.events.size()):
		check(audio.events[index].index==index,"Main assigns monotonic event cursor")
		check(audio.events[index].event==authoritative[index],"Audio receives unchanged event "+str(index))
	check(not audio.times.is_empty() and is_equal_approx(audio.times.back(),screen.combat.elapsed),"Director advances to authoritative presentation time")
	check(audio.ui==["fight_intro"],"Combat handlers no longer add tones for hit/ability/Firma/result")
	var signatures:=0
	var signature_impacts:=0
	for event: Dictionary in authoritative:
		if str(event.type)=="signature": signatures+=1
		if str(event.type)=="attack" and bool(event.get("signature",false)): signature_impacts+=1
	check(signatures==1 and signature_impacts==1,"Fixture exercised one rare Signature announcement and contact")
	check(screen.progression.history.size()==1,"Real match still awards and records once")
	var after_match := _bytes(path)
	var event_count := audio.events.size()
	screen._dispatch_events([authoritative.back()])
	check(audio.events.size()==event_count,"Repeated terminal callback cannot replay victory audio")
	check(_bytes(path)==after_match and screen.progression.history.size()==1,"Repeated terminal callback cannot award or rewrite gameplay")
	# Inactive Main must not unpause an audio session owned by Replay.
	audio.paused=true
	screen._process(0.25)
	check(audio.paused,"Inactive Main does not steal Replay pause ownership")
	var intro_count := audio.ui.size()
	screen._close_replays()
	check(audio.contexts.back().context.mode=="preview" and not bool(audio.contexts.back().context.result_audio),"Closing Replay restores only preview ambience, never an old result")
	check(audio.ui.size()==intro_count and audio.events.size()==event_count,"Preview restoration generates no combat/intro/UI cue")
	check(_bytes(path)==after_match,"Preview restoration cannot mutate progression")
	screen.free()
	viewport.free()
	var report:=FileAccess.open(folder.path_join("validation.json"),FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks":checks,"failures":failures,"fixture":"Real engine Mugo vs Ascua, seed970217 with internal forced rival Signature; preferences and gameplay files disposable","runtime":"headless" if DisplayServer.get_name()=="headless" else "native","event_count":authoritative.size(),"audio_assets_evaluated":false},"  "))
	report.close()
	print("MAIN AUDIO: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)

func _bytes(path: String) -> Array:
	return [FileAccess.get_file_as_bytes(path),FileAccess.get_file_as_bytes(path+".story.json")]
