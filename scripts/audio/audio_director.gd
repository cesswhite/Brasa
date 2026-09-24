extends Node
class_name BrasaAudioDirector
## Presentation-only audio. Events, combat RNG, progress and snapshots are never
## modified. Missing production assets remain silent, with bounded diagnostics.
const VisualProfile = preload("res://scripts/move_visual_profile.gd")
const AnimationSet = preload("res://scripts/fighter_animation_set.gd")
const CATALOG_PATH := "res://data/audio_events.json"
const BUS_LAYOUT := preload("res://default_bus_layout.tres")
const BUS_PARENTS := {"Music":"Master","Ambience":"Master","SFX":"Master","Combat":"SFX","Movement":"SFX","UI":"SFX","Voice":"SFX"}
const POOL_LIMITS := {"Combat":12,"Movement":4,"UI":2,"Voice":2}
const MAX_PENDING := 96
const MAX_HISTORY := 384
const MAX_CACHE := 64
const MAX_SEEN := 2048
const MASTER_SAFETY_NAME := "Brasa Master Safety"
const DEFAULT_SETTINGS := {"master":0.85,"music":0.70,"sfx":0.85,"enabled":true}
var last_save_ok := true
var load_notice := ""
var silent := false
var _preferences_path := ""
var _settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)
var _catalog: Dictionary = {}
var _ready_audio := false
var _profiles: Dictionary = {}
var _context: Dictionary = {}
var _arena := "arena_faroles"
var _session := ""
var _generation := 0
var _clock := 0.0
var _wall_clock := 0.0
var _paused := false
var _terminal := false
var _pending: Array[Dictionary] = []
var _seen: Dictionary = {}
var _seen_order: Array[String] = []
var _actions: Array[Dictionary] = []
var _stances: Dictionary = {}
var _ko: Dictionary = {}
var _history: Array[Dictionary] = []
var _voices: Array[Dictionary] = []
var _beds: Array[Dictionary] = []
var _paths: Dictionary = {}
var _streams: Dictionary = {}
var _lru: Array[String] = []
var _last_variant: Dictionary = {}
var _cooldowns: Dictionary = {}
var _missing: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _duck_until := 0.0
var _duck_db := 0.0
var _counts := {"requested":0,"played":0,"silent":0,"missing":0,"late":0,"pool":0,"cooldown":0,"duplicate":0,"loads":0}

func _ready() -> void:
	add_to_group("brasa_audio_director")
	_ensure_ready()

func setup(preferences_path: String = "", silent_output: bool = false) -> void:
	_ensure_ready()
	silent = silent_output or DisplayServer.get_name()=="headless"
	_preferences_path = preferences_path
	load_notice = ""
	last_save_ok = true
	_settings = DEFAULT_SETTINGS.duplicate(true)
	if not preferences_path.is_empty() and FileAccess.file_exists(preferences_path):
		var config := ConfigFile.new()
		if config.load(preferences_path)==OK:
			var saved := {}
			for key: String in DEFAULT_SETTINGS:
				saved[key]=config.get_value("audio",key,DEFAULT_SETTINGS[key])
			_settings=_sanitize_settings(saved)
		else:
			load_notice="No se pudieron leer los ajustes de audio."
	_apply_volumes()

func get_settings() -> Dictionary:
	return _settings.duplicate(true)

func set_volumes(values: Dictionary, persist: bool = true) -> void:
	_ensure_ready()
	var merged := _settings.duplicate(true)
	for key: String in DEFAULT_SETTINGS:
		if values.has(key): merged[key]=values[key]
	_settings=_sanitize_settings(merged)
	_apply_volumes()
	last_save_ok=true
	if persist and not _preferences_path.is_empty():
		var config := ConfigFile.new()
		for key: String in _settings: config.set_value("audio",key,_settings[key])
		last_save_ok=config.save(_preferences_path)==OK

func configure_context(arena_id: String, fighter_profiles: Dictionary, session_context: Dictionary = {}) -> void:
	_ensure_ready()
	var requested := str(session_context.get("session_id",session_context.get("battle_id","")))
	var next_session := requested if not requested.is_empty() else "context_%d" % (_generation+1)
	if next_session!=_session:
		_clear_session(false)
		_session=next_session
		_rng.seed=int((str(session_context.get("battle_id",_session))+"|audio").hash())
	_profiles=fighter_profiles.duplicate(true)
	_context=session_context.duplicate(true)
	_arena=arena_id if _catalog.get("arenas",{}).has(arena_id) else "arena_faroles"
	# Rescan once at a context boundary so newly installed banks become available.
	_paths.clear()
	_missing.clear()
	var place: Dictionary = _catalog.get("arenas",{}).get(_arena,{})
	_sync_bed("Music",str(place.get("music","")) if bool(_context.get("music",true)) else "")
	_sync_bed("Ambience",str(place.get("ambience","")) if bool(_context.get("ambience",true)) else "")
	_warm_context()

func on_combat_event(event: Dictionary, presentation_time: float, event_index: int) -> void:
	_ensure_ready()
	if _paused or _session.is_empty() or event_index<0: return
	_clock=maxf(_clock,_number(presentation_time,_clock))
	var key := "%s|event|%d" % [_session,event_index]
	if _seen.has(key):
		_counts["duplicate"]+=1
		return
	_remember(key)
	var at := maxf(0,_number(event.get("time"),_clock))
	var side := str(event.get("side","player"))
	var target := str(event.get("target",_other(side)))
	match str(event.get("type","")):
		"defensive_stance":
			_stances[side]=clampf(_number(event.get("reduction"),0),0,1)
		"stance_expired":
			_stances.erase(side)
		"move_started":
			if not _ko.has(side): _schedule_move(event,side,at,key)
		"attack":
			_attack(event,side,target,at,key)
		"signature":
			_duck(0.55)
			# Modern signatures already prepared their charge during windup.
			if _profile_id(side)=="ascua" and not _has_signature_action(side,at):
				_queue("ascua_charge",side,at,key+"|signature_prepare",{"cap":0.16})
		"ability":
			if str(event.get("ability_id",""))=="phase_shift" and int(event.get("phase_index",0))>0 and _profile_id(side)=="ascua":
				_queue("ascua_transform",side,at,key+"|phase")
				_duck(0.8)
		"status_applied":
			if str(event.get("effect",""))=="burn" and _profile_id(str(event.get("source",side)))=="ascua":
				_queue("ascua_release",target,at,key+"|burn_start",{"gain":-7.0,"cooldown":0.7})
		"status_tick":
			# The initial burn and the hit carry its fire feedback; periodic damage
			# must not replay the same release over subsequent physical impacts.
			if event.has("target_hp") and _number(event.target_hp,1)<=0: _schedule_ko(target,at,key)
		"finished":
			if not _terminal:
				_terminal=true
				_cancel_actions("")
				if bool(_context.get("result_audio",true)):
					var result_at := at+0.30
					for contact: Variant in _ko.values(): result_at=maxf(result_at,float(contact)+0.12)
					var id := "victory" if str(event.get("winner",""))==str(_context.get("viewing_side","player")) else "defeat"
					_queue(id,"",result_at,key+"|result",{"important":true})
	advance(_clock)

func advance(presentation_time: float) -> void:
	if _paused or not is_finite(presentation_time): return
	_clock=maxf(_clock,maxf(0,presentation_time))
	_pending.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		return float(a.at)<float(b.at) if not is_equal_approx(float(a.at),float(b.at)) else int(a.order)<int(b.order))
	while not _pending.is_empty() and float(_pending[0].at)<=_clock+0.000001:
		var cue: Dictionary = _pending.pop_front()
		var definition: Dictionary = _catalog.get("cues",{}).get(cue.id,{})
		if _clock-float(cue.at)>float(definition.get("late_window",0.2)):
			_record(cue,"late")
			continue
		_emit_cue(cue)
	for index in range(_actions.size()-1,-1,-1):
		if _clock>float(_actions[index].until)+0.5: _actions.remove_at(index)
	_expire_action_voices()

func play_ui(event_id: String, context: Dictionary = {}) -> void:
	_ensure_ready()
	var id := str(_catalog.get("ui_aliases",{}).get(event_id,""))
	if id.is_empty() or not bool(context.get("enabled",true)): return
	var options := {"gain":-6.0 if event_id=="navigate" else 0.0,"cooldown":0.09 if event_id=="navigate" else 0.12}
	var token := str(context.get("operation_id",""))
	var key := "ui|"+id+"|"+token if not token.is_empty() else ""
	if not key.is_empty():
		if _seen.has(key):
			_counts["duplicate"]+=1
			return
		_remember(key)
	_emit_cue({"id":id,"side":"","at":_clock,"key":key,"options":options,"ui":true})

func set_paused(value: bool) -> void:
	if _paused == value: return
	_paused=value
	for voice: Dictionary in _voices:
		if voice.active and float(voice.get("stop_at",-1))>=0:
			voice.player.stream_paused=value

func stop_session(expected_session_id: String = "") -> void:
	if not expected_session_id.is_empty() and expected_session_id!=_session: return
	_clear_session(true)
	_session=""
	_profiles.clear()
	_context.clear()

func _process(delta: float) -> void:
	# Engine.time_scale affects presentation delivery, not pitch or music fades.
	var real_delta := maxf(0,_number(delta,0))/maxf(0.001,Engine.time_scale)
	_wall_clock+=real_delta
	if _terminal and not _paused: advance(_clock+maxf(0,delta))
	_tick_voices(real_delta)
	_tick_beds(real_delta)
	var desired := -4.0 if _wall_clock<_duck_until else 0.0
	var previous_duck := _duck_db
	_duck_db=move_toward(_duck_db,desired,real_delta*(80.0 if desired<0 else 8.0))
	if _duck_db != previous_duck: _apply_volumes()

func _schedule_move(event: Dictionary, side: String, at: float, key: String) -> void:
	var move: Dictionary = event.get("move",{}).duplicate(true) if event.get("move",{}) is Dictionary else {}
	var resolved_event := event.duplicate(true)
	if bool(event.get("counter",false)): move["animation_type"]="dash"
	resolved_event["move"]=move
	var visual := VisualProfile.resolve(resolved_event)
	var kind := str(visual.get("animation_id","quick"))
	var windup := maxf(0.01,_number(move.get("windup"),0.12))
	var travel := maxf(0,_number(move.get("travel"),0.10))
	var recovery := maxf(0.06,_number(move.get("recovery"),0.20))
	_actions.append({"side":side,"move":move,"at":at,"until":at+windup+travel+recovery,"signature":bool(event.get("signature",false)),"key":key})
	while _actions.size()>16: _actions.pop_front()
	if kind not in ["guard","counter"]:
		var whoosh := "whoosh_heavy" if kind in ["heavy","charge","jump","signature"] else "whoosh_quick"
		_queue(whoosh,side,at+windup,key+"|swing",{"action":true})
	var contacts: Dictionary = {}
	for marker: Dictionary in visual.get("markers",[]):
		var when := at+float(marker.time)
		var marker_key := key+"|"+str(marker.id)
		match str(marker.event):
			"charge_start":
				if _profile_id(side)=="ascua":
					_queue("ascua_charge",side,when,marker_key,{"action":true,"stop_at":at+windup,"cap":windup})
			"left_foot_impact","right_foot_impact","step_back_start","jump_takeoff":
				if _arena=="arena_faroles":
					var contact_key := "%.5f" % when
					# landing_debris is the same physical contact as landing.
					if str(marker.id)=="landing_debris" or contacts.has(contact_key): continue
					contacts[contact_key]=true
					_queue("footstep_earth",side,when,marker_key,{"action":true})
			"slide_start":
				if _arena=="arena_faroles":
					# One friction gesture follows travel; do not layer another
					# complete scrape on the stop marker.
					_queue("slide_earth",side,when,marker_key,{"action":true,"cap":maxf(0.12,travel)})
			"landing":
				if _arena=="arena_faroles":
					contacts["%.5f" % when]=true
					_queue("landing_earth",side,when,marker_key,{"action":true})

func _attack(event: Dictionary, side: String, target: String, at: float, key: String) -> void:
	var outcome := str(event.get("result","hit"))
	var move := _move_for(side,str(event.get("move_id","")),at)
	var resolved := event.duplicate(true)
	if not resolved.has("move"): resolved["move"]=move
	var visual := VisualProfile.resolve(resolved)
	var kind := str(visual.get("animation_id",event.get("animation_type",move.get("animation_type","quick"))))
	if move.is_empty(): kind=str(event.get("animation_type","quick"))
	var heavy := kind in ["heavy","charge","jump","jump_down","jump_forward","signature"]
	if outcome=="dodge":
		_queue("dodge",target,at,key+"|dodge")
	elif outcome!="miss":
		var absorbed := maxf(0,_number(event.get("absorbed"),0))
		var damage := maxf(0,_number(event.get("damage"),0))
		var guarded := float(_stances.get(target,0))>0
		if absorbed>0 or guarded: _queue("guard",target,at,key+"|guard",{"gain":-4.0 if damage>0 else 0.0})
		if damage>0:
			var impact := "impact_heavy" if heavy or outcome in ["critical","signature"] else "impact_light"
			var override_id := str(_catalog.get("impact_overrides",{}).get(str(visual.get("sound_event","")),""))
			# A deliberate move/event presentation override can select only impact
			# families. Default quick metadata must not erase a critical's weight.
			if (event.get("presentation") is Dictionary and event.presentation.has("sound_event")) or (move.get("presentation") is Dictionary and move.presentation.has("sound_event")):
				if not override_id.is_empty(): impact=override_id
			_queue(impact,target,at,key+"|body",{"gain":-3.0 if guarded else 0.0})
			if outcome=="critical": _queue("critical_accent",target,at,key+"|critical")
			if _profile_id(side)=="ascua" and (heavy or outcome=="signature"):
				_queue("ascua_signature" if outcome=="signature" else "ascua_release",side,at,key+"|power")
			if outcome=="signature": _duck(0.6)
			var reaction_key := "%s|%s|%.6f|%s" % [side,target,at,str(event.get("move_id",""))]
			if _profile_id(target)=="ascua" and (heavy or outcome=="critical") and posmod(int(reaction_key.hash()),3)==0:
				_queue("ascua_reaction",target,at,key+"|reaction")
	if event.has("target_hp") and _number(event.target_hp,1)<=0:
		_schedule_ko(target,at,key)

func _schedule_ko(side: String, at: float, key: String) -> void:
	if _ko.has(side): return
	_stances.erase(side)
	_cancel_actions(side)
	var clip: Dictionary = AnimationSet.REACTION_CLIPS.ko
	var contact := at+float(clip.duration)*float(clip.frames.size()-1)/float(clip.frames.size())
	_ko[side]=contact
	if _arena=="arena_faroles": _queue("ko_ground",side,contact,key+"|ko",{"important":true})
	_duck(0.65)

func _cancel_actions(side: String) -> void:
	for index in range(_pending.size()-1,-1,-1):
		if bool(_pending[index].options.get("action",false)) and (side.is_empty() or str(_pending[index].side)==side):
			_pending.remove_at(index)
	for voice: Dictionary in _voices:
		if voice.active and float(voice.get("stop_at",-1))>=0 and (side.is_empty() or str(voice.side)==side): _fade_out_voice(voice)

func _queue(id: String, side: String, at: float, key: String, options: Dictionary = {}) -> void:
	if not _catalog.get("cues",{}).has(id) or bool(_catalog.cues[id].loop): return
	if _seen.has(key): return
	_remember(key)
	var cue := {"id":id,"side":side,"at":at,"key":key,"options":options.duplicate(true),"order":_seen_order.size(),"ui":false}
	if _pending.size()>=MAX_PENDING:
		var lowest := -1
		for index in range(_pending.size()):
			if lowest<0 or int(_catalog.cues[_pending[index].id].priority)<int(_catalog.cues[_pending[lowest].id].priority): lowest=index
		if lowest>=0 and int(_catalog.cues[_pending[lowest].id].priority)<int(_catalog.cues[id].priority):
			_record(_pending[lowest],"pool")
			_pending.remove_at(lowest)
		else:
			_record(cue,"pool")
			return
	_pending.append(cue)

func _emit_cue(cue: Dictionary) -> void:
	var id := str(cue.id)
	var definition: Dictionary = _catalog.get("cues",{}).get(id,{})
	if definition.is_empty(): return
	var options: Dictionary = cue.options
	var stop_at := _number(options.get("stop_at"),-1)
	if stop_at>=0 and _clock>=stop_at:
		_record(cue,"late")
		return
	var cooldown_key := id+"|"+str(cue.side)
	var timer := _wall_clock if bool(cue.get("ui",false)) else _clock
	var cooldown := maxf(0,_number(options.get("cooldown"),float(definition.cooldown)))
	if timer<float(_cooldowns.get(cooldown_key,-100.0)):
		_record(cue,"cooldown")
		return
	var available := _available_paths(id)
	if available.is_empty():
		_missing[id]=true
		_record(cue,"missing")
		return
	var same := 0
	for voice: Dictionary in _voices:
		if voice.active and str(voice.id)==id: same+=1
		if not voice.next.is_empty() and str(voice.next.id)==id: same+=1
	if same>=int(definition.max_simultaneous):
		_record(cue,"pool")
		return
	var slot := _find_voice(str(definition.bus),int(definition.priority))
	if slot<0:
		_record(cue,"pool")
		return
	var variant := _rng.randi_range(0,available.size()-1)
	if available.size()>1 and variant==int(_last_variant.get(id,-1)): variant=(variant+1)%available.size()
	var path := available[variant]
	var stream := _cached_stream(path,bool(definition.loop))
	if stream==null:
		_missing[id]=true
		_record(cue,"missing")
		return
	_missing.erase(id)
	_last_variant[id]=variant
	_cooldowns[cooldown_key]=timer+cooldown
	var payload := cue.duplicate(true)
	payload["stream"]=stream
	payload["variant"]=variant
	payload["path"]=path
	payload["pitch"]=1.0+_rng.randf_range(-float(definition.pitch_spread),float(definition.pitch_spread))
	payload["gain"]=float(definition.gain_db)+_number(options.get("gain"),0)+_rng.randf_range(-float(definition.gain_spread_db),float(definition.gain_spread_db))
	var voice: Dictionary = _voices[slot]
	if voice.active:
		# One bounded successor per slot, with a short click-avoiding fade.
		voice.next=payload
		voice.fade=0.012
	else:
		_start_voice(voice,payload)
	_record(payload,"silent" if silent else "played")
	if id in ["victory","defeat","ascua_transform"]: _duck(0.8)

func _start_voice(voice: Dictionary, cue: Dictionary) -> void:
	var player: Variant = voice.player
	var definition: Dictionary = _catalog.cues[cue.id]
	player.stop()
	player.stream_paused=false
	player.stream=cue.stream
	player.bus=str(definition.bus)
	player.volume_db=float(cue.gain)
	player.pitch_scale=float(cue.pitch)
	if player is AudioStreamPlayer2D:
		var viewport_size := get_viewport().get_visible_rect().size
		player.position=Vector2(viewport_size.x*(0.35 if str(cue.side)=="player" else 0.65),viewport_size.y*0.5)
	voice.active=true
	voice.id=cue.id
	voice.side=cue.side
	voice.priority=int(definition.priority)
	voice.gain=float(cue.gain)
	voice.stop_at=_number(cue.options.get("stop_at"),-1)
	# Playback duration changes with pitch; ordinary lowered-pitch foley must
	# retain its natural tail. Explicit action caps still follow the move.
	voice.remaining=minf(maxf(0.01,float(cue.stream.get_length())),float(definition.duration))/maxf(0.01,float(cue.pitch))
	if cue.options.has("cap"): voice.remaining=minf(float(voice.remaining),maxf(0.01,float(cue.options.cap)))
	voice.next={}
	voice.fade=0.0
	voice.ending=false
	if not silent: player.play()

func _find_voice(bus: String, priority: int) -> int:
	var best := -1
	var best_priority := 2147483647
	for index in range(_voices.size()):
		var voice: Dictionary = _voices[index]
		if str(voice.pool)!=bus: continue
		if bool(voice.reserved) and priority<85: continue
		if not voice.active: return index
		var effective := int(_catalog.cues[voice.next.id].priority) if not voice.next.is_empty() else int(voice.priority)
		if effective<priority and effective<best_priority:
			best=index
			best_priority=effective
	return best

func _tick_voices(delta: float) -> void:
	for voice: Dictionary in _voices:
		if not voice.active: continue
		if not voice.next.is_empty():
			voice.fade=maxf(0,float(voice.fade)-delta)
			voice.player.volume_db=float(voice.gain)+linear_to_db(maxf(0.001,float(voice.fade)/0.012))
			if float(voice.fade)<=0:
				var next: Dictionary = voice.next
				_start_voice(voice,next)
				continue
		if _paused and float(voice.stop_at)>=0: continue
		voice.remaining=float(voice.remaining)-delta
		if bool(voice.get("ending",false)):
			voice.player.volume_db=float(voice.gain)+linear_to_db(clampf(float(voice.remaining)/0.012,0.0001,1.0))
		if float(voice.remaining)<=0 or (not silent and not voice.player.playing and voice.next.is_empty()):
			_release_voice(voice)

func _expire_action_voices() -> void:
	for voice: Dictionary in _voices:
		if voice.active and float(voice.stop_at)>=0 and _clock>=float(voice.stop_at): _fade_out_voice(voice)

func _fade_out_voice(voice: Dictionary) -> void:
	voice.player.stream_paused=false
	voice.stop_at=-1.0
	voice.remaining=minf(float(voice.remaining),0.012)
	voice.ending=true

func _release_voice(voice: Dictionary) -> void:
	voice.player.stop()
	voice.player.stream_paused=false
	voice.player.stream=null
	voice.active=false
	voice.next={}
	voice.fade=0.0
	voice.ending=false

func _sync_bed(bus: String, id: String) -> void:
	var existing := -1
	for index in range(_beds.size()):
		if str(_beds[index].bus)!=bus: continue
		if not id.is_empty() and str(_beds[index].id)==id:
			existing=index
			_beds[index].target=1.0
		else: _beds[index].target=0.0
	if id.is_empty() or existing>=0: return
	var available := _available_paths(id)
	if available.is_empty():
		_missing[id]=true
		return
	var stream := _cached_stream(available[0],true)
	if stream==null: return
	_missing.erase(id)
	var slot := -1
	for index in range(_beds.size()):
		if str(_beds[index].bus)==bus and (slot<0 or float(_beds[index].fade)<float(_beds[slot].fade)): slot=index
	if slot<0: return
	var bed: Dictionary = _beds[slot]
	bed.player.stop()
	bed.id=id
	bed.fade=0.0
	bed.target=1.0
	bed.player.stream=stream
	bed.player.volume_db=-70
	if not silent: bed.player.play()

func _tick_beds(delta: float) -> void:
	for bed: Dictionary in _beds:
		bed.fade=move_toward(float(bed.fade),float(bed.target),delta/0.6)
		if str(bed.id).is_empty(): continue
		bed.player.volume_db=float(_catalog.cues[bed.id].gain_db)+linear_to_db(maxf(0.0001,float(bed.fade)))
		if float(bed.fade)<=0 and float(bed.target)<=0:
			bed.player.stop()
			bed.player.stream=null
			bed.id=""

func _available_paths(id: String) -> Array[String]:
	if _paths.has(id): return _paths[id]
	var result: Array[String] = []
	var definition: Dictionary = _catalog.get("cues",{}).get(id,{})
	if not definition.is_empty():
		for variant in range(1,clampi(int(definition.get("variants",1)),1,12)+1):
			var path := "res://assets/audio/%s/%s_%02d.%s" % [id,id,variant,str(definition.get("extension","wav"))]
			if FileAccess.file_exists(path) or ResourceLoader.exists(path): result.append(path)
	if result.is_empty(): _missing[id]=true
	else: _missing.erase(id)
	_paths[id]=result
	return result

func _load_stream(path: String) -> AudioStream:
	# Files downloaded after editor import are also playable. Exported resources
	# use ResourceLoader's remap; no network/event-provided path is accepted here.
	if FileAccess.file_exists(path):
		if path.ends_with(".wav"): return AudioStreamWAV.load_from_file(path)
		if path.ends_with(".ogg"): return AudioStreamOggVorbis.load_from_file(path)
	return ResourceLoader.load(path) as AudioStream if ResourceLoader.exists(path) else null

func _cached_stream(path: String, loop: bool) -> AudioStream:
	if _streams.has(path):
		_lru.erase(path)
		_lru.append(path)
		return _streams[path]
	var stream := _load_stream(path)
	if stream==null: return null
	if loop:
		stream=stream.duplicate()
		if stream is AudioStreamOggVorbis: stream.loop=true
		elif stream is AudioStreamWAV: stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
	_streams[path]=stream
	_lru.append(path)
	_counts.loads+=1
	while _lru.size()>MAX_CACHE: _streams.erase(_lru.pop_front())
	return stream

func _warm_context() -> void:
	for id: String in _catalog.get("cues",{}):
		if bool(_catalog.cues[id].loop): continue
		if id.begins_with("ascua_") and _profile_id("player")!="ascua" and _profile_id("rival")!="ascua": continue
		if id.ends_with("_earth") and _arena!="arena_faroles": continue
		if id=="ko_ground" and _arena!="arena_faroles": continue
		var available := _available_paths(id)
		# The full slice has 71 files: loading every variant would evict its own
		# first entries from the 64-stream cache on every context switch.
		# Warm one representative; alternate takes are cached on first use.
		if not available.is_empty(): _cached_stream(available[0],false)

func _move_for(side: String, id: String, at: float) -> Dictionary:
	for index in range(_actions.size()-1,-1,-1):
		var action: Dictionary = _actions[index]
		if str(action.side)==side and str(action.move.get("id",""))==id and float(action.at)<=at+0.0001:
			return action.move.duplicate(true)
	return {}

func _has_signature_action(side: String, at: float) -> bool:
	for action: Dictionary in _actions:
		if str(action.side)==side and bool(action.signature) and at<=float(action.until): return true
	return false

func _profile_id(side: String) -> String:
	var profile: Variant = _profiles.get(side,{})
	if not profile is Dictionary: return ""
	# Power identity uses the authoritative character/boss, never a palette.
	for key: String in ["story_boss_id","audio_profile_id","id","character_id"]:
		var id := str(profile.get(key,""))
		if _catalog.get("profiles",{}).has(id): return id
	return ""

func _ensure_ready() -> void:
	if _ready_audio: return
	_ready_audio=true
	silent=DisplayServer.get_name()=="headless"
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if parsed is Dictionary and parsed.get("cues") is Dictionary: _catalog=parsed
	else: _catalog={"cues":{}}
	# Godot normally discovers default_bus_layout.tres. Add missing named buses
	# without replacing an existing layout or unrelated host effects.
	for name: String in BUS_PARENTS:
		if AudioServer.get_bus_index(name)<0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count-1,name)
		AudioServer.set_bus_send(AudioServer.get_bus_index(name),str(BUS_PARENTS[name]))
	_ensure_master_safety()
	for pool: String in POOL_LIMITS:
		for index in range(int(POOL_LIMITS[pool])):
			var player: Variant = AudioStreamPlayer.new() if pool=="UI" else AudioStreamPlayer2D.new()
			if player is AudioStreamPlayer2D:
				player.attenuation=0.0
				player.max_distance=100000.0
				player.panning_strength=0.35
			player.bus=pool
			add_child(player)
			_voices.append({"player":player,"pool":pool,"reserved":pool=="Combat" and index>=10,"active":false,"id":"","side":"","priority":0,"remaining":0.0,"stop_at":-1.0,"next":{},"fade":0.0,"gain":0.0})
	for bus: String in ["Music","Ambience"]:
		for index in range(2):
			var player := AudioStreamPlayer.new()
			player.bus=bus
			add_child(player)
			_beds.append({"player":player,"bus":bus,"id":"","fade":0.0,"target":0.0})
	_apply_volumes()

func _ensure_master_safety() -> void:
	var master := AudioServer.get_bus_index("Master")
	if master<0 or not ClassDB.class_exists("AudioEffectHardLimiter"): return
	for index in range(AudioServer.get_bus_effect_count(master)):
		if AudioServer.get_bus_effect(master,index).resource_name==MASTER_SAFETY_NAME: return
	var policy: Dictionary = _catalog.get("mix_policy",{})
	var limiter: AudioEffect = ClassDB.instantiate("AudioEffectHardLimiter")
	limiter.resource_name=MASTER_SAFETY_NAME
	limiter.set("pre_gain_db",clampf(_number(policy.get("master_pre_gain_db"),7.0),-24.0,24.0))
	limiter.set("ceiling_db",clampf(_number(policy.get("master_ceiling_db"),-1.0),-24.0,0.0))
	# Append to a host's existing chain; never replace its layout/effects or
	# modify the Master fader/mute while ensuring the single named safety stage.
	AudioServer.add_bus_effect(master,limiter)

func _apply_volumes() -> void:
	if not _ready_audio: return
	for pair: Array in [["Master","master"],["Music","music"],["SFX","sfx"],["Ambience","sfx"]]:
		var index := AudioServer.get_bus_index(str(pair[0]))
		if index<0: continue
		var value := float(_settings[pair[1]])
		AudioServer.set_bus_volume_db(index,linear_to_db(maxf(0.0001,value))+(_duck_db if str(pair[0])=="Music" else 0.0))
		AudioServer.set_bus_mute(index,value<=0 or (str(pair[0])=="Master" and not bool(_settings.enabled)))

func _sanitize_settings(raw: Dictionary) -> Dictionary:
	var result := DEFAULT_SETTINGS.duplicate(true)
	for key: String in ["master","music","sfx"]:
		result[key]=clampf(_number(raw.get(key),float(DEFAULT_SETTINGS[key])),0,1)
	result.enabled=raw.get("enabled",true) if raw.get("enabled",true) is bool else true
	return result

func _clear_session(clear_beds: bool) -> void:
	_generation+=1
	_pending.clear()
	_seen.clear()
	_seen_order.clear()
	_actions.clear()
	_stances.clear()
	_ko.clear()
	var ui_cooldown := float(_cooldowns.get("ui_confirm|",-100.0))
	_cooldowns.clear()
	_cooldowns["ui_confirm|"]=ui_cooldown
	_last_variant.clear()
	_clock=0
	_paused=false
	_terminal=false
	_duck_until=0
	_duck_db=0
	for voice: Dictionary in _voices:
		# A page transition may coincide with a successful UI commit. Preserve
		# its tiny confirmation tail; combat/result voices belong to the session.
		if str(voice.id)!="ui_confirm": _release_voice(voice)
	if clear_beds:
		for bed: Dictionary in _beds: bed.target=0.0

func _duck(seconds: float) -> void:
	_duck_until=maxf(_duck_until,_wall_clock+seconds)

func _remember(key: String) -> void:
	_seen[key]=true
	_seen_order.append(key)
	while _seen_order.size()>MAX_SEEN: _seen.erase(_seen_order.pop_front())

func _record(cue: Dictionary, outcome: String) -> void:
	_counts.requested+=1
	if _counts.has(outcome): _counts[outcome]+=1
	_history.append({"id":str(cue.id),"side":str(cue.side),"at":float(cue.at),"delivered_at":_clock,"key":str(cue.get("key","")),"outcome":outcome,"variant":int(cue.get("variant",-1)),"pitch":float(cue.get("pitch",1)),"gain":float(cue.get("gain",0)),"session":_session})
	while _history.size()>MAX_HISTORY: _history.pop_front()

func debug_state() -> Dictionary:
	var active: Array[Dictionary] = []
	for voice: Dictionary in _voices:
		if voice.active: active.append({"id":voice.id,"side":voice.side,"bus":voice.pool,"priority":voice.priority,"remaining":voice.remaining,"stop_at":voice.stop_at,"successor":voice.next.get("id","")})
	var beds: Array[Dictionary] = []
	for bed: Dictionary in _beds:
		if not str(bed.id).is_empty(): beds.append({"id":bed.id,"bus":bed.bus,"fade":bed.fade,"target":bed.target})
	return {"session":_session,"clock":_clock,"paused":_paused,"terminal":_terminal,"pending":_pending.duplicate(true),"history":_history.duplicate(true),"voices":active,"voice_capacity":_voices.size(),"beds":beds,"cache_entries":_streams.size(),"seen":_seen.size(),"missing":_missing.keys(),"counters":_counts.duplicate(true),"settings":get_settings(),"last_save_ok":last_save_ok,"load_notice":load_notice,"duck_db":_duck_db}

static func _number(value: Variant, fallback: float) -> float:
	return float(value) if (value is int or value is float) and is_finite(float(value)) else fallback

static func _other(side: String) -> String:
	return "rival" if side=="player" else "player"
