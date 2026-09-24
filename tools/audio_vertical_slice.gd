extends SceneTree
## Native, real-time audio QA only. No gameplay/profile is read from user://.
## --plan-only is a short headless coverage probe and does not play/record sound.
const FIXTURE_PATH := "res://tests/test_identity_integration.gd"
const EngineScript = preload("res://scripts/combat_engine.gd")
const Progress = preload("res://scripts/progression.gd")
const Story = preload("res://scripts/story_progression.gd")
const StoryCatalog = preload("res://scripts/story_catalog.gd")

var folder := ""
var check_count := 0
var failures := 0
var observations: Array[Dictionary] = []
var seed_value := 970217
var player_profile: Dictionary = {}
var player_descriptor: Dictionary = {}
var rival_descriptor: Dictionary = {}
var plan_only := false
var allow_missing := false
var section_mode := "all"
var fixture_class: GDScript

func _init() -> void: _run.call_deferred()
func check(condition: bool, detail: String) -> void:
	check_count += 1
	if not condition:
		failures += 1
		push_error("AUDIO VERTICAL: "+detail)

func _write(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null:
		check(false,"Write fixture artifact "+path)
		return
	file.store_string(JSON.stringify(value,"  "))
	file.close()

func _run() -> void:
	create_timer(180,true,false,true).timeout.connect(func(): push_error("AUDIO VERTICAL timeout"); quit(1))
	folder=ProjectSettings.globalize_path("res://../../work/audio/playtest/run-%d" % Time.get_unix_time_from_system()).simplify_path()
	for arg: String in OS.get_cmdline_user_args():
		if arg=="--plan-only": plan_only=true
		if arg=="--allow-missing": allow_missing=true
		if arg.begins_with("--output-dir="): folder=arg.trim_prefix("--output-dir=")
		if arg.begins_with("--section="): section_mode=arg.trim_prefix("--section=")
	DirAccess.make_dir_recursive_absolute(folder.path_join("fixtures"))
	player_profile=Progress._new_profile("mugo","Mugo · prueba de audio")
	player_profile.level=20
	player_profile.total_xp=Progress._xp_before_level(20)
	player_descriptor=Progress._combatant(player_profile)
	rival_descriptor=StoryCatalog.opponent(7,1)
	rival_descriptor["opponent_id"]="npc_audio_slice_ascua"
	var chosen := _choose_seed()
	seed_value=int(chosen.seed)
	_write(folder.path_join("coverage-plan.json"),chosen)
	print("AUDIO VERTICAL PLAN: "+JSON.stringify(chosen))
	if plan_only:
		quit(0 if bool(chosen.complete) else 1)
		return
	if DisplayServer.get_name()=="headless":
		push_error("Use native Godot for Master recording; --plan-only is the headless mode.")
		quit(2)
		return
	var missing:=_missing_assets()
	_write(folder.path_join("asset-preflight.json"),{"missing":missing,"allow_missing":allow_missing})
	if not missing.is_empty() and not allow_missing:
		push_error("Audio banks incomplete: "+", ".join(missing))
		quit(2)
		return
	var fixture_container := load(FIXTURE_PATH)
	var fixture_error := fixture_problem(fixture_container)
	check(fixture_error.is_empty(), "Main fixture is instantiable: "+fixture_error)
	if not fixture_error.is_empty():
		_finish(missing)
		return
	fixture_class=fixture_container.get_script_constant_map()["Fixture"]
	check(section_mode in ["all","normal","reduced"], "Recognized recording section")
	if failures>0:
		_finish(missing)
		return
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(1360,880)
	root.title="Brasa · PRUEBA DE AUDIO · Mugo contra Ascua · archivos desechables"
	if section_mode in ["all","normal"]: await _record_section("normal_pause",false,true)
	if section_mode in ["all","reduced"]: await _record_section("reduced_motion",true,false)
	_finish(missing)

func _finish(missing: Array[String]) -> void:
	var expected := expected_sections(section_mode)
	check(not expected.is_empty(), "Recognized finalization section")
	for problem: String in completion_problems(observations,expected):
		check(false,problem)
	check(observations.size()==expected.size(), "Every requested native recording completed")
	if observations.size()==2:
		check(observations[0].event_hash==observations[1].event_hash,"Reduced motion and pause preserve identical authoritative events")
	_write(folder.path_join("validation.json"),{"checks":check_count,"failures":failures,"seed":seed_value,
		"fixture":"Real Mugo20 vs Ascua12, force_signature=rival turn2 only in this tool; no balance or production probability change",
		"recording":"AudioEffectRecord on Master, native output, real-time engine/animation/audio",
		"sections":observations,"expected_sections":expected,"complete":failures==0,"missing_assets":missing,"human_listening_performed":false,
		"note":"Coverage is measured; no audio quality claim follows from successful recording. Both sections retain their real outcome; this is not a victory/defeat fabrication."})
	print("AUDIO VERTICAL: %d checks, %d failures; recordings in %s" % [check_count,failures,folder])
	quit(0 if failures==0 else 1)

func _options(id: String) -> Dictionary:
	return {"force_signature":"rival","signature_turn":2,"opening_time":0.2,"battle_id":id}

func _coverage(events: Array) -> Dictionary:
	var result := {"ascua_moves":[],"move_types":[],"results":[],"phases":[],"signature":0,"burn":0,"ko":false,"winner":"","reason":""}
	for event: Dictionary in events:
		var side := str(event.get("side",""))
		if event.type=="move_started":
			var move: Dictionary=event.move
			if not str(move.type) in result.move_types: result.move_types.append(str(move.type))
			if side=="rival" and not str(move.id) in result.ascua_moves: result.ascua_moves.append(str(move.id))
		if event.type=="attack":
			if not str(event.result) in result.results: result.results.append(str(event.result))
			if float(event.get("target_hp",1))<=0: result.ko=true
		if event.type=="signature" and side=="rival": result.signature+=1
		if event.type=="ability" and side=="rival" and str(event.get("ability_id",""))=="phase_shift": result.phases.append(int(event.phase_index))
		if event.type=="status_applied" and str(event.get("effect",""))=="burn": result.burn+=1
		if event.type=="finished":
			result.winner=event.winner
			result.reason=event.reason
	return result

static func _complete(coverage: Dictionary) -> bool:
	for id: String in ["ascua_cobre","ascua_forja","ascua_brasero","ascua_obsidiana","ascua_crater"]:
		if not id in coverage.get("ascua_moves",[]): return false
	var phases: Array[int]=[]
	for phase: Variant in coverage.get("phases",[]):
		if (phase is int or phase is float) and float(phase)==float(int(phase)): phases.append(int(phase))
	return int(coverage.get("signature",0))==1 and 1 in phases and 2 in phases and bool(coverage.get("ko",false)) and int(coverage.get("burn",0))>0 and "critical" in coverage.get("results",[]) and "dodge" in coverage.get("results",[])

func _choose_seed() -> Dictionary:
	var best := {}
	var best_score := -1
	for seed_index: int in range(970200,970264):
		var engine=EngineScript.new()
		engine.start(player_descriptor,rival_descriptor,seed_index,_options("audio-slice-plan"))
		engine.advance(120)
		var coverage := _coverage(engine.event_log)
		var score: int = coverage.ascua_moves.size()*10+coverage.phases.size()*5+coverage.results.size()+int(coverage.ko)*10+mini(1,coverage.burn)*5
		if score>best_score:
			best_score=score
			best={"seed":seed_index,"duration":engine.elapsed,"coverage":coverage,"complete":_complete(coverage),"sampled_candidates":seed_index-970199}
		if _complete(coverage):
			best={"seed":seed_index,"duration":engine.elapsed,"coverage":coverage,"complete":true,"sampled_candidates":seed_index-970199}
			break
	return best

func _missing_assets() -> Array[String]:
	var missing: Array[String]=[]
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/audio_events.json"))
	for id: String in manifest.cues:
		var cue: Dictionary=manifest.cues[id]
		var found:=false
		for variant: int in range(1,int(cue.get("variants",1))+1):
			var path := "res://assets/audio/%s/%s_%02d.%s" % [id,id,variant,str(cue.get("extension","wav"))]
			if FileAccess.file_exists(path): found=true
		if not found: missing.append(id)
	return missing

func _record_section(id: String, reduced: bool, pause_once: bool) -> void:
	var path:=folder.path_join("fixtures/"+id+".json")
	var progress=Progress.new()
	progress.load_save(path)
	progress.select_character("mugo",str(player_profile.name))
	progress._grant_xp(progress.data,Progress._xp_before_level(20))
	check(progress.save(),"Save explicit level20 fixture")
	var story=Story.new()
	story.load_save(path+".story.json")
	story.select_character("mugo")
	var untouched_story:=FileAccess.get_file_as_bytes(path+".story.json")
	var screen=fixture_class.new()
	check(is_instance_valid(screen) and screen is Control,"Instantiate Main fixture for "+id)
	if not is_instance_valid(screen) or not screen is Control: return
	screen.fixture_path=path
	root.add_child(screen)
	screen.size=Vector2(root.size)
	screen._layout_interface(screen.size)
	screen.sound_enabled=true
	screen.reduced_motion=reduced
	screen._apply_motion_preference()
	screen._make_sounds()
	screen.audio_director.set_volumes({"enabled":true,"master":0.85,"music":0.70,"sfx":0.85},false)
	screen.rival=rival_descriptor.duplicate(true)
	screen._start_fight()
	screen.combat.start(player_descriptor,rival_descriptor,seed_value,_options("audio-slice-"+str(seed_value)))
	screen._configure_combat_audio(player_descriptor,rival_descriptor)
	var recording := AudioEffectRecord.new()
	recording.format=AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0,recording)
	var effect_index:=AudioServer.get_bus_effect_count(0)-1
	recording.set_recording_active(true)
	screen.audio_director.play_ui("ui_confirm")
	screen.audio_director.play_ui("fight_intro")
	var wall_start:=Time.get_ticks_msec()
	var pauses: Array[Dictionary]=[]
	var audio_timeline: Array[Dictionary]=[]
	var seen_audio: Dictionary={}
	var next_audio_sample:=0.0
	var paused_once:=false
	while screen.active_match:
		await process_frame
		if pause_once and not paused_once and screen.combat.elapsed>=4.0 and screen.combat.running:
			paused_once=true
			screen._show_settings()
			var paused_time: float=screen.combat.elapsed
			var audio_time: float=screen.audio_director.debug_state().clock
			await create_timer(1.0,true,false,true).timeout
			check(is_equal_approx(screen.combat.elapsed,paused_time),"Pause holds real combat clock")
			check(is_equal_approx(float(screen.audio_director.debug_state().clock),audio_time),"Pause holds audio scheduling clock")
			pauses.append({"engine_time":paused_time,"wall_seconds":1.0,"state":"settings modal paused and resumed"})
			screen._close_modal()
		screen._process(screen.get_process_delta_time())
		if float(screen.combat.elapsed)>=next_audio_sample:
			_collect_audio(screen.audio_director,seen_audio,audio_timeline)
			next_audio_sample=float(screen.combat.elapsed)+0.20
	await create_timer(2.0,true,false,true).timeout
	# Generated result stings may outlast the old fixed two-second tail.
	# Capture until every terminal one-shot and queued cue has finished.
	var tail_deadline := Time.get_ticks_msec()+3000
	while Time.get_ticks_msec()<tail_deadline:
		var tail_state: Dictionary=screen.audio_director.debug_state()
		if tail_state.voices.is_empty() and tail_state.pending.is_empty(): break
		await create_timer(0.05,true,false,true).timeout
	var settled: Dictionary=screen.audio_director.debug_state()
	check(settled.voices.is_empty() and settled.pending.is_empty(),"Terminal KO/result tails finish before recording stops")
	recording.set_recording_active(false)
	await create_timer(0.20,true,false,true).timeout
	var stream:=recording.get_recording()
	check(stream!=null and stream.data.size()>0,"Master records native audio data")
	var wav_path:=folder.path_join(id+"-mix.wav")
	if stream!=null: check(stream.save_to_wav(wav_path)==OK,"Save mixed WAV")
	AudioServer.remove_bus_effect(0,effect_index)
	var trace: Dictionary=screen.audio_director.debug_state()
	_collect_audio(screen.audio_director,seen_audio,audio_timeline)
	var summary: Dictionary=screen.combat.summary()
	var immutable_events: Array=summary.events.duplicate(true)
	var coverage:=_coverage(immutable_events)
	check(_complete(coverage),"Measured run covers Ascua kit, phases, Firma, burn, critical, dodge and KO")
	check(FileAccess.get_file_as_bytes(path+".story.json")==untouched_story,"Separate Story fixture stays unchanged")
	check(screen.progression.history.size()==1,"Live fixture records one real result")
	var record := {"section":id,"reduced_motion":reduced,"seed":seed_value,"duration":screen.combat.elapsed,
		"wall_seconds":float(Time.get_ticks_msec()-wall_start)/1000.0,"pauses":pauses,"coverage":coverage,
		"event_hash":JSON.stringify(immutable_events).sha256_text(),"wav":wav_path,"wave_seconds":stream.get_length() if stream!=null else 0.0,
		"director":trace,"audio_timeline":audio_timeline,"player":summary.player,"rival":summary.rival,"events":immutable_events,
		"audio_catalog_sha256":FileAccess.get_sha256("res://data/audio_events.json")}
	_write(folder.path_join(id+"-trace.json"),record)
	observations.append({"id":id,"coverage":coverage,"event_hash":record.event_hash,"wav":wav_path,"trace":folder.path_join(id+"-trace.json"),"wave_seconds":record.wave_seconds,"duration":record.duration,"wall_seconds":record.wall_seconds,"reduced_motion":reduced})
	screen.audio_director.stop_session()
	screen.free()
	await process_frame

func _collect_audio(director: Node, seen: Dictionary, timeline: Array[Dictionary]) -> void:
	# Incrementally retain all delivered cues, beyond the director's bounded UI log.
	for item: Dictionary in director.debug_state().history:
		var key:=str(item.get("session",""))+"|"+str(item.get("key",""))+"|"+str(item.get("outcome",""))
		if seen.has(key): continue
		seen[key]=true
		timeline.append(item.duplicate(true))


static func fixture_problem(container: Resource) -> String:
	if not container is GDScript or not container.can_instantiate():
		return "fixture script failed to compile"
	var candidate: Variant=container.get_script_constant_map().get("Fixture")
	if not candidate is GDScript or not candidate.can_instantiate():
		return "Main-derived Fixture failed to compile"
	return ""

static func completion_problems(records: Array[Dictionary], expected: Array[String]) -> Array[String]:
	var problems: Array[String]=[]
	for id: String in expected:
		var matches: Array[Dictionary]=[]
		for record: Dictionary in records:
			if str(record.get("id",""))==id: matches.append(record)
		if matches.size()!=1:
			problems.append("Exactly one completed recording required for "+id)
			continue
		var record: Dictionary=matches[0]
		var coverage: Dictionary=record.get("coverage",{})
		if coverage.is_empty() or not _complete(coverage): problems.append("Required measured coverage absent for "+id)
		if str(record.get("event_hash","")).is_empty(): problems.append("Authoritative event hash absent for "+id)
		if float(record.get("duration",0))<=0 or float(record.get("wave_seconds",0))<float(record.get("duration",0)):
			problems.append("Full-length recorded waveform required for "+id)
		var wav_path:=str(record.get("wav",""))
		var wav:=FileAccess.open(wav_path,FileAccess.READ) if not wav_path.is_empty() else null
		if wav==null or wav.get_length()<=44:
			problems.append("Recorded WAV missing or empty for "+id)
		elif wav.get_buffer(4).get_string_from_ascii()!="RIFF":
			problems.append("Recorded WAV header invalid for "+id)
		var trace_path:=str(record.get("trace",""))
		var trace: Variant=JSON.parse_string(FileAccess.get_file_as_string(trace_path)) if FileAccess.file_exists(trace_path) else null
		if not trace is Dictionary or trace.get("section")!=id or trace.get("event_hash")!=record.get("event_hash") or trace.get("events",[]).is_empty():
			problems.append("Matching immutable event trace missing for "+id)
	return problems


static func expected_sections(mode: String) -> Array[String]:
	var result: Array[String]=[]
	if mode in ["all","normal"]: result.append("normal_pause")
	if mode in ["all","reduced"]: result.append("reduced_motion")
	return result
