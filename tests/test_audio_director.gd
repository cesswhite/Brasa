extends SceneTree
const Director = preload("res://scripts/audio/audio_director.gd")
const Combat = preload("res://scripts/combat_engine.gd")
const Story = preload("res://scripts/story_catalog.gd")
var checks := 0
var failures := 0
var serial := 0
var original_buses: AudioBusLayout

class SilentFixture extends Director:
	# Test-only silent PCM: validates scheduling/pool/decoder contracts without
	# creating assets or disguising synthetic output as produced ElevenLabs audio.
	func _available_paths(id: String) -> Array[String]:
		if not _catalog.get("cues",{}).has(id): return []
		return ["fixture://"+id+"/1","fixture://"+id+"/2","fixture://"+id+"/3"]
	func _load_stream(_path: String) -> AudioStream:
		var stream := AudioStreamWAV.new()
		stream.format=AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate=8000
		var silence := PackedByteArray()
		silence.resize(32000)
		stream.data=silence
		return stream

class CompleteBank extends SilentFixture:
	func _available_paths(id: String) -> Array[String]:
		var paths: Array[String] = []
		for variant in range(int(_catalog.cues.get(id,{}).get("variants",0))):
			paths.append("fixture://"+id+"/"+str(variant))
		return paths

class ArrivingBank extends SilentFixture:
	var bank_ready := false
	func _available_paths(id: String) -> Array[String]:
		if id=="ui_confirm" and not bank_ready: return []
		return super._available_paths(id)

func _init() -> void: _run.call_deferred()
func check(value: bool, message: String) -> void:
	checks+=1
	if not value:
		failures+=1
		push_error("AUDIO DIRECTOR: "+message)

func make_director() -> Node:
	var director := SilentFixture.new()
	root.add_child(director)
	director.set_process(false)
	director.setup("",true)
	return director

func context(director: Node, mode: String = "live", arena: String = "arena_faroles") -> void:
	serial+=1
	director.configure_context(arena,{"player":{"story_boss_id":"ascua"},"rival":{"character_id":"onix"}},{"session_id":"fixture_%d"%serial,"mode":mode,"result_audio":true})
	director._history.clear()

func events(director: Node, id: String = "") -> Array:
	var result: Array = []
	for record: Dictionary in director.debug_state().history:
		if (id.is_empty() or str(record.id)==id) and str(record.outcome) in ["silent","played"]: result.append(record)
	return result

func attack(result: String = "hit", damage: float = 10, absorbed: float = 0, hp: float = 50) -> Dictionary:
	return {"type":"attack","side":"player","target":"rival","time":0.3,"result":result,"damage":damage,"absorbed":absorbed,"target_hp":hp,"move_id":"fixture_move","animation_type":"heavy"}

func move(kind: String = "heavy", side: String = "player") -> Dictionary:
	return {"type":"move_started","side":side,"time":0.0,"move":{"id":"fixture_move","animation_type":kind,"windup":0.2,"travel":0.1,"recovery":0.3}}

func _run() -> void:
	original_buses=AudioServer.generate_bus_layout()
	var director := make_director()
	_contract(director)
	_master_safety(director)
	_semantics(director)
	_clocks(director)
	_settings(director)
	_pool_variation(director)
	_review_regressions(director)
	_speed_finish_review(director)
	_engine_read_only(director)
	director.free()
	_missing()
	AudioServer.set_bus_layout(original_buses)
	print("AUDIO DIRECTOR: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func _contract(director: Node) -> void:
	check(director.is_in_group("brasa_audio_director"),"shared director discovery")
	check(director.debug_state().voice_capacity==20,"bounded twenty one-shot players")
	check(director.get_child_count()==24,"twenty one-shot plus four crossfade players")
	for voice: Dictionary in director._voices:
		check((voice.player is AudioStreamPlayer)==(voice.pool=="UI"),"only UI one-shots are centered nonpositional players")
		if voice.player is AudioStreamPlayer2D:
			check(is_zero_approx(voice.player.attenuation) and is_equal_approx(voice.player.panning_strength,0.35),"soft stereo without viewport-distance gain")
	for bus: String in ["Master","Music","Ambience","SFX","Combat","Movement","UI","Voice"]:
		check(AudioServer.get_bus_index(bus)>=0,"named bus "+bus)
	for bus: String in ["Combat","Movement","UI","Voice"]:
		check(AudioServer.get_bus_send(AudioServer.get_bus_index(bus))==&"SFX","SFX controls child "+bus)
	context(director)
	check(director.debug_state().beds.size()==2,"one music and one ambience bed")
	var music_instance := 0
	for bed: Dictionary in director._beds:
		if bed.id=="faroles_music": music_instance=bed.player.get_instance_id()
	director.configure_context("arena_faroles",{},{"session_id":"same-place-new-fight"})
	var after_instance := 0
	for bed: Dictionary in director._beds:
		if bed.id=="faroles_music": after_instance=bed.player.get_instance_id()
	check(music_instance==after_instance,"same location reuses music without restarting a player")
	var session: String=director.debug_state().session
	director.stop_session("outdated-replay")
	check(director.debug_state().session==session,"old replay cannot stop new session")
	director.stop_session(session)
	check(director.debug_state().session.is_empty() and director.debug_state().pending.is_empty(),"owned close clears session")

func _semantics(director: Node) -> void:
	for outcome: String in ["miss","dodge","hit","critical","signature"]:
		context(director)
		var event := attack(outcome,0 if outcome in ["miss","dodge"] else 10)
		var original := event.duplicate(true)
		director.on_combat_event(event,0.3,0)
		check(event==original,"event immutable "+outcome)
		check(events(director,"impact_heavy").size()==(0 if outcome in ["miss","dodge"] else 1),"body contact respects "+outcome)
		check(events(director,"dodge").size()==(1 if outcome=="dodge" else 0),"no dodge reward on miss "+outcome)
		check(events(director,"critical_accent").size()==(1 if outcome=="critical" else 0),"critical accent "+outcome)
	context(director)
	director.on_combat_event(attack("hit",0,20),0.3,0)
	check(events(director,"guard").size()==1 and events(director,"impact_heavy").is_empty(),"total absorption only protective contact")
	context(director)
	director.on_combat_event(attack("hit",8,12),0.3,0)
	check(events(director,"guard").size()==1 and events(director,"impact_heavy").size()==1,"partial absorption permits both layers")
	context(director)
	director.on_combat_event({"type":"defensive_stance","side":"player","time":0},0,0)
	check(events(director).is_empty(),"entering guard never invents a defended hit")
	context(director)
	var started := move("signature")
	started["signature"]=true
	director.on_combat_event(started,0,0)
	director.advance(0.21)
	director.on_combat_event({"type":"signature","side":"player","time":0.3},0.3,1)
	var hit := attack("signature")
	director.on_combat_event(hit,0.3,2)
	director.on_combat_event(hit,0.3,2)
	check(events(director,"ascua_charge").size()==1,"signature has one preparation, not duplicate at announcement")
	check(events(director,"ascua_signature").size()==1 and events(director,"ascua_release").is_empty(),"signature uses one dedicated impact, not heavy release")
	check(events(director,"impact_heavy").size()==1,"duplicate event cannot double impact")
	check(int(director.debug_state().counters["duplicate"])>=1,"duplicate diagnostics")
	context(director)
	director.on_combat_event({"type":"ability","side":"rival","ability_id":"phase_shift","phase_index":1,"time":0},0,0)
	check(events(director,"ascua_transform").is_empty(),"non Ascua body does not acquire transformation sound")
	director.on_combat_event({"type":"ability","side":"player","ability_id":"phase_shift","phase_index":1,"time":0},0,1)
	check(events(director,"ascua_transform").size()==1,"real Ascua phase shift")
	context(director)
	director.on_combat_event({"type":"defensive_stance","side":"rival","reduction":0.25,"time":0},0,0)
	check(events(director).is_empty(),"real stance activates without contact sound")
	director.on_combat_event(attack(),0.3,1)
	check(events(director,"guard").size()==1 and events(director,"impact_heavy").size()==1,"actual reduced contact has guard plus quieter body")
	director.on_combat_event({"type":"stance_expired","side":"rival","time":0.6},0.6,2)
	var unguarded := attack()
	unguarded.time=0.8
	director.on_combat_event(unguarded,0.8,3)
	check(events(director,"guard").size()==1,"expired stance no longer sounds defended")
	context(director)
	var injected := attack()
	injected["presentation"]={"sound_event":"res://evil.wav"}
	director.on_combat_event(injected,0.3,0)
	check(events(director,"impact_heavy").size()==1,"raw path ignored; trusted contact remains")
	check(not str(director.debug_state()).contains("evil.wav"),"untrusted path never enters loader/history")
	context(director)
	injected.presentation.sound_event="impact_light"
	director.on_combat_event(injected,0.3,0)
	check(events(director,"impact_light").size()==1,"registered impact override is honored")
	context(director,"live","arena_tormenta")
	director.on_combat_event(move("jump"),0,0)
	director.advance(0.2)
	director.advance(0.5)
	check(events(director,"footstep_earth").is_empty() and events(director,"landing_earth").is_empty(),"wet stone never plays unproduced earth bank")

func _clocks(director: Node) -> void:
	var traces: Array = []
	for fps: int in [20,60,120]:
		context(director)
		director.on_combat_event(move("jump"),0,0)
		for tick in range(1,fps+1): director.advance(float(tick)/float(fps))
		var trace: Array = []
		for record: Dictionary in events(director): trace.append([record.id,record.at])
		traces.append(trace)
		check(events(director,"landing_earth").size()==1,"one landing at "+str(fps)+" FPS")
		check(events(director,"footstep_earth").size()==1,"landing debris is not a second footstep")
	check(traces[0]==traces[1] and traces[1]==traces[2],"delta-independent semantic schedule")
	context(director)
	director.on_combat_event(move("heavy"),0,0)
	director.set_paused(true)
	var clock_before: float=director.debug_state().clock
	var pending_before: Array=director.debug_state().pending
	director.advance(5)
	director._process(0.2)
	check(director.debug_state().clock==clock_before and director.debug_state().pending==pending_before,"pause preserves pending clock")
	director.set_paused(false)
	director.advance(0.2)
	check(events(director,"whoosh_heavy").size()==1,"resume dispatches pending cue once")
	root.set_meta("brasa_reduced_motion",true)
	context(director)
	director.on_combat_event(move("quick"),0,0)
	director.advance(0.2)
	check(events(director,"whoosh_quick").size()==1,"reduced motion cannot silence audio markers")
	root.remove_meta("brasa_reduced_motion")
	context(director)
	director.on_combat_event(move("jump"),2,0)
	check(events(director).is_empty(),"late batch does not create stale movement burst")
	check(director.debug_state().counters.late>0,"late cue diagnostics")
	context(director)
	director.on_combat_event(move("charge","rival"),0,0)
	director.on_combat_event({"type":"status_tick","side":"rival","target":"rival","source":"player","effect":"burn","damage":8,"target_hp":0,"time":0.1},0.1,1)
	director.on_combat_event({"type":"finished","winner":"player","reason":"ko","time":0.1},0.1,2)
	director.advance(0.6)
	check(events(director,"ko_ground").size()==1,"lethal status schedules one ground contact")
	check(events(director,"whoosh_heavy").is_empty(),"KO cancels pending attack")
	director._process(0.2)
	check(events(director,"victory").size()==1,"terminal presentation clock completes result without engine")
	director.advance(1.2)
	check(events(director,"ko_ground").size()==1 and events(director,"victory").size()==1,"finished cannot double KO/result")
	context(director)
	director.on_combat_event({"type":"finished","winner":"rival","reason":"surrender","time":0},0,0)
	director.advance(0.3)
	check(events(director,"ko_ground").is_empty() and events(director,"defeat").size()==1,"surrender is not a fabricated lethal hit")

func _settings(director: Node) -> void:
	var folder := ProjectSettings.globalize_path("res://").path_join("../../work/audio/audit/test-fixtures").simplify_path()
	DirAccess.make_dir_recursive_absolute(folder)
	var path := folder.path_join("audio_%d.cfg"%Time.get_ticks_usec())
	director.setup(path,true)
	director.set_volumes({"master":0.4,"music":0.2,"sfx":0.6,"enabled":false})
	check(director.last_save_ok and FileAccess.file_exists(path),"explicit disposable settings persisted")
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")),"mute acts on Master, including active tails")
	var saved: Dictionary = director.get_settings()
	director.setup(path,true)
	check(director.get_settings()==saved,"settings round trip")
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")) and is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")),linear_to_db(0.4)),"limiter and repeated setup preserve persisted user mute/fader")
	check(_safety_count()==1,"repeated persisted setup keeps exactly one named limiter")
	director.set_volumes({"enabled":true},false)
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")) and is_equal_approx(float(director.get_settings().master),0.4),"unmute preserves gain")
	director.set_volumes({"master":NAN,"music":1000,"sfx":-1},false)
	check(is_finite(float(director.get_settings().master)) and director.get_settings().music==1 and director.get_settings().sfx==0,"invalid levels sanitized")
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")),"zero SFX mutes child buses")
	var config := ConfigFile.new()
	config.load(path)
	check(config.get_value("audio","master")==0.4,"persist false does not modify file")
	director.setup("",true)
	director.set_volumes({"master":0.8})
	check(director.last_save_ok,"empty path has no user-save fallback")
	DirAccess.remove_absolute(path)

func _safety_count() -> int:
	var count := 0
	var master := AudioServer.get_bus_index("Master")
	for index in range(AudioServer.get_bus_effect_count(master)):
		if AudioServer.get_bus_effect(master,index).resource_name=="Brasa Master Safety": count+=1
	return count

func _master_safety(director: Node) -> void:
	check(ClassDB.class_exists("AudioEffectHardLimiter"),"Godot provides native HardLimiter")
	check(_safety_count()==1,"default layout installs one named limiter")
	var master := AudioServer.get_bus_index("Master")
	for index in range(AudioServer.get_bus_effect_count(master)):
		var effect := AudioServer.get_bus_effect(master,index)
		if effect.resource_name=="Brasa Master Safety":
			check(effect.get_class()=="AudioEffectHardLimiter" and is_equal_approx(float(effect.get("pre_gain_db")),7) and is_equal_approx(float(effect.get("ceiling_db")),-1),"single global +7 dB gain and -1 dB ceiling")
	director.setup("",true)
	director.setup("",true)
	check(_safety_count()==1,"multiple setups never duplicate global gain")
	var snapshot := AudioServer.generate_bus_layout()
	for index in range(AudioServer.get_bus_effect_count(master)-1,-1,-1): AudioServer.remove_bus_effect(master,index)
	var host: AudioEffect = ClassDB.instantiate("AudioEffectHardLimiter")
	host.resource_name="Fixture Host Effect"
	host.set("pre_gain_db",1.0)
	AudioServer.add_bus_effect(master,host)
	AudioServer.set_bus_volume_db(master,-6.5)
	AudioServer.set_bus_mute(master,true)
	director._ensure_master_safety()
	director._ensure_master_safety()
	check(AudioServer.get_bus_effect_count(master)==2 and _safety_count()==1,"custom layout gains only the missing labeled safety effect")
	check(AudioServer.get_bus_effect(master,0)==host and is_equal_approx(float(host.get("pre_gain_db")),1.0),"host effect, gain and order preserved")
	check(AudioServer.is_bus_mute(master) and is_equal_approx(AudioServer.get_bus_volume_db(master),-6.5),"ensuring safety never modifies Master fader or mute")
	AudioServer.set_bus_layout(snapshot)

func _pool_variation(director: Node) -> void:
	context(director)
	var previous := -1
	for index in range(12):
		director._process(0.6)
		director.play_ui("ui_confirm")
		var history: Array=events(director,"ui_confirm")
		check(not history.is_empty(),"UI cue available")
		var latest: Dictionary=history.back()
		check(int(latest.variant)!=previous,"non-repeating variants")
		check(is_equal_approx(float(latest.pitch),1),"tonal UI pitch fixed")
		previous=int(latest.variant)
	context(director)
	director._process(0.6)
	director.play_ui("ui_confirm",{"operation_id":"saved-once"})
	director._process(0.6)
	director.play_ui("ui_confirm",{"operation_id":"saved-once"})
	check(events(director,"ui_confirm").size()==1,"commit operation ID deduplicated")
	for index in range(300):
		director.on_combat_event(attack("critical"),0.3,index)
	check(director.debug_state().voices.size()<=20,"voice population bounded under burst")
	check(director.debug_state().pending.size()<=Director.MAX_PENDING,"pending population bounded")
	check(director.debug_state().history.size()<=Director.MAX_HISTORY,"diagnostics bounded")
	check(director.debug_state().cache_entries<=Director.MAX_CACHE,"resource cache bounded")
	var loads: int=director.debug_state().counters.loads
	for index in range(100): director._process(0.01)
	check(director.debug_state().counters.loads==loads,"no resource loads per frame")
	context(director)
	for id: String in ["impact_light","impact_heavy","guard","ascua_release","ascua_charge"]:
		for index in range(2):
			director._emit_cue({"id":id,"side":"fixture_%d"%index,"at":0.0,"key":"pool:"+id+str(index),"options":{},"ui":false})
	check(director.debug_state().voices.size()==10,"ordinary contacts cannot consume two important reserved slots")
	director.on_combat_event(attack("critical"),0.3,0)
	var second_critical := attack("critical")
	second_critical.time=0.4
	director.on_combat_event(second_critical,0.4,1)
	check(events(director,"critical_accent").size()==2,"critical accents retain reserved capacity")
	var lethal := attack("hit",10,0,0)
	lethal.time=0.5
	director.on_combat_event(lethal,0.5,2)
	director.advance(1.0)
	director._process(0.02)
	var has_ko := false
	for voice: Dictionary in director.debug_state().voices: has_ko=has_ko or str(voice.id)=="ko_ground"
	check(has_ko,"important KO steals a lower-priority slot with bounded fade")
	check(director.debug_state().voices.size()<=12,"priority replacement does not allocate extra players")

func _engine_read_only(director: Node) -> void:
	var player := {"character_id":"onix","level":12}
	var rival: Dictionary=Story.opponent(7,1)
	var first := Combat.new()
	var second := Combat.new()
	var options := {"force_signature":["player","rival"],"signature_turn":2,"opening_time":0.1,"battle_id":"fixture:audio:unchanged"}
	first.start(player,rival,8432,options)
	second.start(player,rival,8432,options)
	context(director)
	var index := 0
	while first.running:
		var batch: Array=first.advance(0.05)
		for event: Dictionary in batch:
			var copy := event.duplicate(true)
			director.on_combat_event(event,first.elapsed,index)
			check(event==copy,"real engine event remains immutable")
			index+=1
		director.advance(first.elapsed)
		director._tick_voices(0.05)
	second.advance(180)
	check(first.event_log==second.event_log,"audio variation does not change seeded engine event stream")
	check(first.summary()==second.summary(),"audio leaves winner/stats/rewards source unchanged")
	var source := first.summary().duplicate(true)
	var traces: Array = []
	for mode: String in ["live","replay","online"]:
		context(director,mode)
		var cursor := 0
		for event: Dictionary in source.events:
			director.on_combat_event(event,float(event.time),cursor)
			cursor+=1
		director.advance(float(source.duration)+0.8)
		var trace: Array = []
		for row: Dictionary in director.debug_state().history: trace.append([row.id,row.at,row.outcome])
		traces.append(trace)
	check(traces[0]==traces[1] and traces[1]==traces[2],"same consumer semantics for live/replay/online")
	check(source==first.summary(),"replaying never rewrites the historical record")

func _review_regressions(director: Node) -> void:
	var complete := CompleteBank.new()
	root.add_child(complete)
	complete.set_process(false)
	complete.setup("",true)
	context(complete)
	var loaded: int=complete.debug_state().counters.loads
	context(complete)
	check(int(complete.debug_state().counters.loads)==loaded,"full 71-file manifest does not reload bank when switching session")
	check(loaded<=22,"preflight warms one real variant per relevant group")
	complete.free()
	var arriving := ArrivingBank.new()
	root.add_child(arriving)
	arriving.set_process(false)
	arriving.setup("",true)
	context(arriving)
	arriving.play_ui("ui_confirm")
	check("ui_confirm" in arriving.debug_state().missing,"missing bank is diagnosed")
	arriving.bank_ready=true
	context(arriving)
	arriving.play_ui("ui_confirm")
	check(events(arriving,"ui_confirm").size()==1 and not "ui_confirm" in arriving.debug_state().missing,"newly available bank clears stale missing diagnostic")
	arriving.free()
	context(director)
	var stream: AudioStream=director._load_stream("fixture://pitched_tail")
	var slot: Dictionary=director._voices[0]
	director._start_voice(slot,{"id":"impact_light","side":"player","stream":stream,"gain":-8.0,"pitch":0.97,"options":{}})
	var nominal: float=minf(stream.get_length(),float(director._catalog.cues.impact_light.duration))
	check(float(slot.remaining)>=nominal/0.97-0.0001,"slightly lowered pitch does not truncate sample tail at nominal duration")
	context(director)
	for id: String in ["ascua_charge","impact_light","impact_heavy","guard","ascua_release"]:
		for variant in range(2):
			director._emit_cue({"id":id,"side":"fixture_%d"%variant,"at":0.0,"key":"priority:"+id+str(variant),"options":{},"ui":false})
	for variant in range(2):
		director._emit_cue({"id":"critical_accent","side":"fixture_%d"%variant,"at":0.0,"key":"reserve"+str(variant),"options":{},"ui":false})
	for id: String in ["ascua_transform","ascua_signature","ko_ground"]:
		director._emit_cue({"id":id,"side":"player","at":0.0,"key":"priority:"+id,"options":{},"ui":false})
	var successors: Array = []
	for voice: Dictionary in director.debug_state().voices:
		if not str(voice.successor).is_empty(): successors.append(voice.successor)
	check("ascua_transform" in successors and "ascua_signature" in successors and "ko_ground" in successors,"new KO keeps already queued high-priority cues when lower-priority voices remain")

func _speed_finish_review(director: Node) -> void:
	var original_speed := Engine.time_scale
	for speed: float in [1.0,2.0]:
		Engine.time_scale=speed
		for fps: int in [20,60,120]:
			context(director)
			director.on_combat_event(move("heavy"),0.0,0)
			var finished := false
			for frame in range(1,fps*2+1):
				var now := float(frame)*speed/float(fps)
				if not finished:
					if now>=0.3:
						director.on_combat_event(attack("critical",15,0,0),now,1)
						director.on_combat_event({"type":"finished","winner":"player","reason":"ko","time":0.3},now,2)
						finished=true
					else: director.advance(now)
				director._process(speed/float(fps))
			for id: String in ["ascua_charge","whoosh_heavy","impact_heavy","critical_accent","ko_ground","victory"]:
				check(events(director,id).size()==1,"%s exactly once at %d FPS / speed %.0f, including autonomous terminal queue" % [id,fps,speed])
	Engine.time_scale=original_speed
	context(director)
	director.on_combat_event({"type":"defensive_stance","side":"rival","reduction":0.25,"time":0},0,0)
	director.on_combat_event(attack("hit",5,10,20),0.3,1)
	check(events(director,"guard").size()==1,"shield plus active stance still produces one protective contact")

func _missing() -> void:
	var director := Director.new()
	root.add_child(director)
	director.set_process(false)
	director.setup("",true)
	director.configure_context("arena_tormenta",{},{"session_id":"missing-banks","music":false,"ambience":false})
	director.play_ui("not-a-real-id")
	check(director.debug_state().history.is_empty(),"unknown ID stays silent")
	director.play_ui("ui_confirm")
	var records: Array=director.debug_state().history
	check(records.size()<=1,"missing bank never multiplies fallback tones")
	check(director.debug_state().voice_capacity==20,"actual director remains bounded without assets")
	director.stop_session()
	var only_ui := true
	for voice: Dictionary in director.debug_state().voices: only_ui=only_ui and str(voice.id)=="ui_confirm"
	check(only_ui,"close removes old combat voices while allowing UI confirmation tail")
	director.free()
