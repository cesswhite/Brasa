extends SceneTree
## Presentation regression with real engine events and an in-memory Main.
## Never calls production boot/load_save or writes a gameplay/identity save.
const Moves = preload("res://scripts/move_catalog.gd")
const Records = preload("res://scripts/battle_identity.gd")
const Replay = preload("res://scripts/ui/battle_replay_panel.gd")
const Combat = preload("res://scripts/combat_engine.gd")

class MemoryProgress:
	extends "res://scripts/progression.gd"
	var memory_commits := 0
	func save() -> bool:
		memory_commits += 1
		last_save_ok = true
		return true
	func load_save(_path: String = "") -> void:
		push_error("STATUS KO fixture must never read a save")

class MemoryMain:
	extends "res://scripts/main.gd"
	func _ready() -> void:
		# Do not call super: it opens the user's normal save and preferences.
		progression = MemoryProgress.new()
		league_progression = progression
		sound_enabled = false
		_build_theme()
		_build_interface()
		progression.select_character("mugo", "Fixture KO")
		_prepare_rival()
		_refresh_manager()
		_update_portraits()
		set_process(false)
		player_view.set_process(false)
		rival_view.set_process(false)
		combat_fx.set_process(false)

var checks := 0
var failures := 0
var screen: MemoryMain
var replay
var heavy: Dictionary

func _init() -> void: _run.call_deferred()

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("STATUS KO: "+description)

func _run() -> void:
	Engine.time_scale = 1.0
	create_timer(15,true,false,true).timeout.connect(func(): push_error("STATUS KO timeout"); quit(1))
	var canvas := SubViewport.new()
	canvas.size = Vector2i(1360,880)
	root.add_child(canvas)
	screen = MemoryMain.new()
	canvas.add_child(screen)
	screen.size = Vector2(1360,880)
	screen._layout_interface(screen.size)
	replay = Replay.new()
	canvas.add_child(replay)
	replay.set_process(false)
	for move: Dictionary in Moves.moves_for("mugo"):
		if str(move.type)=="heavy": heavy=move; break
	check(not heavy.is_empty(),"Fixture uses a real pending heavy attack")
	for effect: String in ["poison","burn","bleed"]:
		await _lethal(effect, "rival" if effect=="burn" else "player")
	_nonlethal()
	_move_presentation()
	check(not screen.identity_loaded and screen.session_save_path.is_empty(),"Fixture never initializes identity or a save path")
	check(screen.progression.memory_commits>1,"Result path commits only through the in-memory save override")
	canvas.queue_free()
	await process_frame
	print("STATUS KO PRESENTATION: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)

func _events(effect: String, side: String, lethal: bool) -> Array:
	var options := {"opening_time":0.20,"disable_signatures":true,"battle_id":"status_ko_"+effect+"_"+side+str(lethal),"initial_hp":{},"initial_statuses":{}}
	options.initial_hp[side]=1.0 if lethal else 150.0
	options.initial_statuses[side]=[{"type":effect,"magnitude":9.0,"duration":2}]
	var player: Dictionary = screen.progression.active_combatant()
	player["fighter_id"]="fixture:status-ko:mugo"
	screen.combat.start(player,screen.rival,1701,options)
	return screen.combat.advance(0.21)

func _pending(actor) -> void:
	actor.reset_pose()
	actor.play_move(heavy,0.08)
	actor.play_move({"id":"fixture_counter","is_counter_reaction":true,"animation_type":"dash","windup":0.05,"impact_delay":0.13,"duration":0.28},0.06)
	check(actor._mode=="move" and not actor._counter_move.is_empty(),"Fixture begins with both outgoing attack and counter overlay")

func _lethal(effect: String, side: String) -> void:
	var events := _events(effect,side,true)
	var tick: Dictionary = {}
	var finished: Dictionary = {}
	for event: Dictionary in events:
		if str(event.type)=="status_tick": tick=event
		elif str(event.type)=="finished": finished=event
	check(not tick.is_empty() and float(tick.get("target_hp",1))<=0 and finished.get("reason","")=="dot",effect+": actual engine emits a lethal DOT and terminal result")
	if tick.is_empty() or finished.is_empty(): return
	var original := JSON.stringify(screen.combat.summary().events)
	var actor = screen.player_view if side=="player" else screen.rival_view
	_pending(actor)
	screen._effect_feedback(tick)
	check(actor._mode=="fall",effect+": Main enters KO during tick dispatch, before result delay")
	check(is_equal_approx(actor._action_time,screen.combat.elapsed-float(tick.time)),effect+": live KO starts at event-relative time")
	check(actor._counter_move.is_empty() and actor._pending_reaction.is_empty() and actor._deferred_reaction.is_empty(),effect+": KO clears outgoing overlays and deferred reactions")
	actor._process(0.17)
	var clock_before: float = actor._action_time
	actor.move_impact(false,str(heavy.id))
	actor.play_move(heavy)
	check(actor._mode=="fall" and actor._action_time==clock_before,effect+": a pending contact or later move cannot restart the defeated actor")
	screen.active_match=true
	screen.finishing=false
	await screen._finish_fight(finished,screen.match_generation)
	check(screen.result_panel.visible and not screen.active_match,effect+": actual Main result path completes")
	check(actor._mode=="fall" and actor._action_time==clock_before,effect+": result presentation preserves the existing KO clock")
	check(JSON.stringify(screen.combat.summary().events)==original,effect+": presentation leaves authoritative events unchanged")
	var record := {}
	Records.attach(record,screen.combat.summary())
	replay.configure([record])
	check(not replay.snapshot.is_empty(),effect+": real DOT battle forms an immutable replay record")
	for body in replay.actors.values(): body.set_process(false)
	var replay_actor = replay.actors[side]
	_pending(replay_actor)
	replay.elapsed=float(tick.time)+0.075
	replay._apply_event(tick)
	check(replay_actor._mode=="fall" and is_equal_approx(replay_actor._action_time,0.075),effect+": delayed replay tick enters KO immediately at its original timestamp")
	check(replay_actor._counter_move.is_empty(),effect+": replay KO cancels the counter overlay")
	replay_actor._process(0.12)
	clock_before=replay_actor._action_time
	replay._apply_event(finished)
	check(replay_actor._mode=="fall" and replay_actor._action_time==clock_before,effect+": replay finished event cannot reset KO progress")
	check(JSON.stringify(screen.combat.summary().events)==original,effect+": replay also preserves the source events")

func _nonlethal() -> void:
	var tick: Dictionary = {}
	for event: Dictionary in _events("poison","player",false):
		if str(event.type)=="status_tick": tick=event; break
	check(not tick.is_empty() and float(tick.get("target_hp",0))>0,"Nonlethal case comes from the same real DOT engine path")
	if tick.is_empty(): return
	var original := tick.duplicate(true)
	var actor = screen.player_view
	actor.reset_pose()
	screen._effect_feedback(tick)
	check(actor._mode=="hit","Nonlethal live tick retains the ordinary hit response")
	_pending(actor)
	var clock_before: float = actor._action_time
	screen._effect_feedback(tick)
	check(actor._mode=="move" and actor._action_time==clock_before and actor._pending_reaction=="hit","Nonlethal live tick preserves a pending outgoing contact")
	var replay_actor = replay.actors.player
	replay_actor.reset_pose()
	replay.elapsed=float(tick.time)
	replay._apply_event(tick)
	check(replay_actor._mode=="hit","Nonlethal replay tick retains the ordinary hit response")
	_pending(replay_actor)
	clock_before=replay_actor._action_time
	replay._apply_event(tick)
	check(replay_actor._mode=="move" and replay_actor._action_time==clock_before,"Nonlethal replay tick preserves a pending outgoing contact")
	check(tick==original,"Neither nonlethal presentation path mutates its input event")

func _move_presentation() -> void:
	# A real descriptor goes through the engine's normal move selection/serialization.
	# Only presentation metadata differs from the catalog; combat rules stay intact.
	var move := heavy.duplicate(true)
	move["presentation"]={"hit_reaction":"body","impact_fx":"dust","hit_stop":0.08,"camera_feedback":"strong"}
	var player: Dictionary = screen.progression.active_combatant()
	player["fighter_id"]="fixture:move-presentation:mugo"
	player["moves"]=[move]
	var rival: Dictionary = screen.rival.duplicate(true)
	var descriptor_before := JSON.stringify(player)
	var engine := Combat.new()
	engine.start(player,rival,1702,{"opening_time":0.20,"disable_signatures":true,"battle_id":"fixture:move-presentation"})
	engine.advance(120.0)
	var summary: Dictionary = engine.summary()
	var source_before := JSON.stringify(summary)
	var log_before := JSON.stringify(engine.event_log)
	var started: Dictionary = {}
	var attack: Dictionary = {}
	for event: Dictionary in summary.get("events",[]):
		if str(event.get("side",""))!="player": continue
		if str(event.type)=="move_started": started=event
		elif str(event.type)=="attack" and str(event.result)=="hit" and float(event.target_hp)>0 and str(event.move_id)==str(started.get("move",{}).get("id","")):
			attack=event
			break
	check(not attack.is_empty(),"Presentation fixture produces a real nonlethal engine contact")
	if attack.is_empty(): return
	check(started.get("move",{}).get("presentation",{})==move.presentation,"Engine move_started preserves the declared presentation metadata")
	check(attack.has("move_id") and not attack.has("move") and not attack.has("presentation"),"Engine impact references move_id without embedding the move or presentation")
	check(JSON.stringify(player)==descriptor_before,"Engine fixture construction preserves its source descriptor")
	var record := {}
	Records.attach(record,summary)
	replay.configure([record])
	check(not replay.snapshot.is_empty(),"Real presentation events form a valid historical replay")
	var record_before := JSON.stringify(record)
	var replay_before := JSON.stringify(replay.snapshot)
	for actor in replay.actors.values(): actor.set_process(false)
	replay._fx.set_process(false)
	for overridden: bool in [false,true]:
		var impact := attack.duplicate(true)
		if overridden:
			impact["presentation"]={"hit_reaction":"light","impact_fx":"small_hit","hit_stop":0.03,"camera_feedback":"none"}
		var impact_before := JSON.stringify(impact)
		var expected: Dictionary = impact.presentation if overridden else move.presentation
		var label := "Event override" if overridden else "Move defaults"
		for historical: bool in [false,true]:
			var attacker = replay.actors.player if historical else screen.player_view
			var target = replay.actors.rival if historical else screen.rival_view
			var fx = replay._fx if historical else screen.combat_fx
			attacker.reset_pose()
			target.reset_pose()
			fx.clear()
			if historical:
				replay.elapsed=float(started.time)
				replay._apply_event(started)
			else:
				screen.combat.elapsed=float(started.time)
				screen._handle_move_started(started)
			# Isolate the impact's emitted effect from the heavy windup's energy.
			fx.clear()
			var age := 0.005
			if historical:
				replay.elapsed=float(impact.time)+age
				replay._apply_event(impact)
			else:
				screen.combat.elapsed=float(impact.time)+age
				screen._handle_attack(impact,screen.match_generation)
			var context := label+(" replay" if historical else " Main")
			check(target._mode=="reaction" and target._reaction_kind==str(expected.hit_reaction),context+": matching outgoing move supplies the reaction, with event fields taking priority")
			check(fx._effects.size()==1 and str(fx._effects[0].id)==str(expected.impact_fx),context+": impact effect follows the same presentation priority")
			check(is_equal_approx(attacker._hit_stop_remaining,float(expected.hit_stop)-age) and is_equal_approx(target._hit_stop_remaining,float(expected.hit_stop)-age),context+": both actors receive the selected pause minus elapsed event time")
			check((fx._shake_duration>0)==(str(expected.camera_feedback)!="none"),context+": camera feedback follows the same presentation priority")
			check(is_equal_approx(target._action_time,age),context+": recovered metadata preserves the reaction's event-relative clock")
			check(attacker._move.get("presentation",{})==move.presentation,context+": applying event overrides never rewrites the stored outgoing move")
			check(JSON.stringify(impact)==impact_before and JSON.stringify(summary)==source_before,context+": input event and source battle remain immutable")
	check(JSON.stringify(record)==record_before and JSON.stringify(replay.snapshot)==replay_before,"Presentation recovery leaves the historical record and loaded replay snapshot unchanged")
	check(JSON.stringify(engine.event_log)==log_before and JSON.stringify(engine.summary())==source_before,"Main and replay never modify the authoritative engine log or terminal summary")
