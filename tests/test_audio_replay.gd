extends SceneTree
## Isolated presentation-contract test: no HTTP, user saves, or audio files.
const Replay = preload("res://scripts/ui/battle_replay_panel.gd")
const Characters = preload("res://scripts/character_catalog.gd")
const Moves = preload("res://scripts/move_catalog.gd")
const AudioDirector = preload("res://scripts/audio/audio_director.gd")

class FakeDirector extends Node:
	var contexts: Array[Dictionary] = []
	var events: Array[Dictionary] = []
	var times: Array[float] = []
	var pauses: Array[bool] = []
	var stops: Array[String] = []
	var ui_cues: Array[String] = []
	var active_session := ""
	func _ready() -> void: add_to_group("brasa_audio_director")
	func configure_context(arena: String, profiles: Dictionary, options: Dictionary) -> void:
		contexts.append({"arena":arena,"profiles":profiles.duplicate(true),"options":options.duplicate(true)})
		active_session = str(options.session_id)
		profiles.player["name"] = "must not mutate the recorded identity"
	func on_combat_event(event: Dictionary, now: float, index: int) -> void:
		events.append({"event":event.duplicate(true),"now":now,"index":index,"session":active_session})
		event["audio_only_test"] = true
	func advance(now: float) -> void: times.append(now)
	func set_paused(value: bool) -> void: pauses.append(value)
	func stop_session(expected_session_id: String = "") -> void:
		if not expected_session_id.is_empty() and expected_session_id != active_session: return
		stops.append(active_session)
		active_session = ""
	func play_ui(cue: String) -> void: ui_cues.append(cue)

var checks := 0
var failures := 0

func _init() -> void: _run.call_deferred()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("AUDIO REPLAY: " + message)

func _record(chapter: int = 2) -> Dictionary:
	var player: Dictionary = Characters.definition("mugo")
	var rival: Dictionary = Characters.definition("nima")
	for entry: Dictionary in [player,rival]:
		entry["character_id"] = str(entry.id)
		entry["level"] = 3
		entry["combat_stats"] = {"max_hp":250.0}
	rival["story_chapter_id"] = chapter
	var move: Dictionary = Moves.moves_for("mugo")[0].duplicate(true)
	move.merge({"windup":.3,"travel":.2,"recovery":.3,"impact_delay":.5,"duration":.8},true)
	return {"battle_snapshot":{
		"version":1,"battle_id":"audio-replay-fixture","player":player,"rival":rival,
		"duration":1.0,"winner":"player","reason":"normal","events":[
			{"type":"move_started","time":.2,"side":"player","target":"rival","move":move,"player_hp":250.0,"rival_hp":250.0},
			{"type":"attack","time":.7,"side":"player","target":"rival","move_id":move.id,"result":"hit","damage":250.0,"target_hp":0.0,"player_hp":250.0,"rival_hp":0.0},
			{"type":"finished","time":1.0,"winner":"player","player_hp":250.0,"rival_hp":0.0},
		],
	}}

func _panel(record: Dictionary, side: String = "player", mode: String = "replay") -> Control:
	var panel := Replay.new()
	panel.viewing_side = side
	panel.playback_mode = mode
	root.add_child(panel)
	panel.set_process(false)
	panel.configure([record])
	return panel

func _run() -> void:
	var director := FakeDirector.new()
	root.add_child(director)
	var record := _record()
	var original := record.duplicate(true)
	var panel = _panel(record,"rival","online")
	_check(director.contexts.size()==1,"one shared director context at configuration")
	_check(director.contexts[0].arena=="arena_tormenta","chapter 2 audio uses displayed storm background")
	_check(director.contexts[0].options.mode=="online" and director.contexts[0].options.viewing_side=="rival","caller supplies online defender perspective")
	_check(director.contexts[0].options.result_audio,"cinematic result audio is explicitly allowed")
	_check(director.pauses.back() and not panel.playing,"selection begins paused")
	_check(panel.snapshot.player.name==original.battle_snapshot.player.name,"director receives detached identity data")
	panel._process(.4)
	_check(director.events.is_empty() and director.times.is_empty(),"paused selection neither consumes nor advances audio")
	panel._toggle()
	_check(not director.pauses.back(),"play resumes the same director")
	panel._process(.25)
	_check(director.events.size()==1 and director.events[0].event.type=="move_started","only due anticipation is sent")
	_check(director.events[0].index==0 and is_equal_approx(float(director.events[0].now),.25),"event index and actual presentation time travel together")
	_check(is_equal_approx(director.times.back(),.25),"scheduled marker queue advances after event delivery")
	panel._toggle()
	var count: int = director.events.size()
	panel._process(.8)
	_check(director.pauses.back() and director.events.size()==count and is_equal_approx(panel.elapsed,.25),"manual pause freezes event and sound clocks")
	panel._toggle()
	panel._process(.4)
	_check(director.events.size()==1,"impact cannot sound early before recorded contact")
	panel._process(.2)
	_check(director.events.size()==2 and director.events[1].event.type=="attack","impact is delivered at the crossing frame")
	_check(director.events[1].index==1 and is_equal_approx(float(director.events[1].now),.85),"impact lateness remains available for the director")
	panel._process(.15)
	_check(director.events.size()==3 and director.events[2].event.type=="finished","finished delivered exactly once")
	_check(not panel.playing and not director.pauses.back(),"end does not pause terminal KO/result tails")
	panel._process(1.0)
	_check(director.events.size()==3,"completed idle view does not replay terminal events")
	_check(record==original and panel.snapshot==original.battle_snapshot,"all presentation inputs and frozen identities remain immutable")
	_check(director.ui_cues.is_empty(),"recorded outcomes never announce new XP or unlock rewards")
	var previous_session: String = director.active_session
	panel.restart()
	_check(director.stops.back()==previous_session,"restart cancels prior generation and voices")
	_check(director.active_session!=previous_session and director.pauses.back(),"restart creates a fresh paused session")
	panel._toggle()
	panel._process(.8)
	_check(director.events[-2].index==0 and director.events[-1].index==1,"coarse delta still emits stable sequential event IDs")
	_check(is_equal_approx(float(director.events[-2].now),.8) and is_equal_approx(float(director.events[-1].now),.8),"both late events share the real crossing frame, not invented times")
	var fallback := _record()
	fallback.battle_snapshot.rival.erase("story_chapter_id")
	var second = _panel(fallback)
	_check(director.contexts.back().arena=="arena_faroles","missing chapter uses same Faroles fallback as replay art")
	var current_session: String = director.active_session
	var stops_before: int = director.stops.size()
	panel.queue_free()
	await process_frame
	_check(director.active_session==current_session and director.stops.size()==stops_before,"deferred old panel destruction cannot stop newer audio")
	second._request_close()
	_check(director.active_session.is_empty() and director.stops.size()==stops_before+1,"explicit close releases owned session immediately")
	second.queue_free()
	await process_frame
	_check(director.stops.size()==stops_before+1,"tree exit does not stop twice")
	var empty = _panel(_record(3))
	_check(director.contexts.back().arena=="arena_faroles","chapter 3 follows actual Faroles combat rather than late-route illustration")
	empty.configure([])
	_check(director.active_session.is_empty() and empty.snapshot.is_empty() and not empty.playing,"empty replacement invalidates old audio and playback")
	empty.queue_free()
	director.queue_free()
	await process_frame
	var silent = _panel(_record())
	silent._toggle()
	silent._process(1.0)
	_check(silent.elapsed==1.0 and not silent.playing,"missing director leaves replay fully functional and silent")
	_check(get_nodes_in_group("brasa_audio_director").is_empty(),"replay never creates a second director")
	silent.queue_free()
	await process_frame
	await _real_director()
	print("AUDIO REPLAY: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)

func _real_director() -> void:
	var director := AudioDirector.new()
	root.add_child(director)
	director.setup("",true) # In-memory preferences; no player file or audible output.
	director.set_process(false)
	var record := _record()
	var original := record.duplicate(true)
	var panel = _panel(record,"rival","online")
	_check(get_nodes_in_group("brasa_audio_director").size()==1,"real replay reuses exactly one director")
	_check(director.debug_state().paused,"real director remains paused before playback")
	panel._toggle()
	panel._process(.25)
	_check(is_equal_approx(float(director.debug_state().clock),.25),"real director clock follows presentation")
	_check(_cue_count(director.debug_state().history,"impact_light")==0 and _cue_count(director.debug_state().history,"impact_heavy")==0,"real director does not produce contact before impact")
	panel._toggle()
	panel._process(.5)
	director._process(.5)
	_check(is_equal_approx(float(director.debug_state().clock),.25),"real paused replay cannot advance scheduled combat sound")
	panel._toggle()
	panel._process(.45)
	var contact_count := _cue_count(director.debug_state().history,"impact_light") + _cue_count(director.debug_state().history,"impact_heavy")
	_check(contact_count==1,"real director records one authoritative impact even without imported assets")
	panel._process(.3)
	_check(director.debug_state().terminal and not director.debug_state().paused,"real terminal queue remains alive after replay reaches duration")
	for index in range(40): director._process(.05)
	var history: Array = director.debug_state().history
	_check(_cue_count(history,"defeat")==1 and _cue_count(history,"victory")==0,"real result uses online defender perspective exactly once")
	_check(_cue_count(history,"ui_confirm")==0,"real replay does not announce a progression transaction")
	_check(record==original and panel.snapshot==original.battle_snapshot,"real director leaves recorded battle byte-equivalent in memory")
	director.configure_context("arena_faroles",{}, {"session_id":"preparation-after-replay","mode":"preview","result_audio":false})
	panel.queue_free()
	await process_frame
	_check(director.debug_state().session=="preparation-after-replay","late exit cannot erase restored Main preview context")
	director.stop_session()
	_check(director.debug_state().pending.is_empty() and director.debug_state().session.is_empty(),"explicit owner shutdown clears remaining queue")
	director.queue_free()
	await process_frame

func _cue_count(history: Array, id: String) -> int:
	var count := 0
	for entry: Dictionary in history:
		if str(entry.get("id",""))==id: count += 1
	return count
