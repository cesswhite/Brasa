extends SceneTree
## Presentation-only fixtures. No network, rewards, profiles or user saves.
const Fighter = preload("res://scripts/fighter_view.gd")
const Sets = preload("res://scripts/fighter_animation_set.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Moves = preload("res://scripts/move_catalog.gd")
const Story = preload("res://scripts/story_catalog.gd")
const Layout = preload("res://scripts/ui/battle_layout.gd")
var checks := 0
var failures := 0
var require_pilot := false
var require_roster := false

func _init() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ANIMATION SEQUENCES FAIL: "+message)

func _run() -> void:
	require_pilot = "--require-pilot" in OS.get_cmdline_user_args()
	require_roster = "--require-roster" in OS.get_cmdline_user_args()
	require_pilot = require_pilot or require_roster
	_test_phase_contract()
	_test_presentation_overrides()
	_test_reaction_event_join()
	_test_reactions_and_clock()
	_test_body_selection()
	_test_pilot()
	_test_fixed_framing()
	if require_roster: _test_complete_roster()
	print("ANIMATION SEQUENCES: %d checks, %d failures; pilot=%s" % [checks,failures,str(Sets.available("ascua"))])
	quit(1 if failures else 0)

func _actor(definition: Dictionary) -> Node2D:
	var actor := Fighter.new()
	actor.setup_character(definition)
	actor.set_process(false)
	return actor

func _test_phase_contract() -> void:
	for id: String in Catalog.IDS:
		for move: Dictionary in Moves.moves_for(id):
			var before := move.duplicate(true)
			var impact := float(move.impact_delay)
			var start := Sets.phase_sample(move,0)
			var preparation := Sets.phase_sample(move,float(move.windup)*0.90)
			var contact := Sets.phase_sample(move,impact)
			var end := Sets.phase_sample(move,float(move.duration))
			check(start.phase=="windup" and preparation.phase=="windup",id+" anticipation uses authoritative windup")
			check(contact.phase=="recovery",id+" exact contact remains authoritative boundary")
			check(end.phase=="recovery",id+" frame count never extends move duration")
			if str(move.type) in ["guard","counter"]:
				check(contact.frame=="guard_settle",id+" defensive preparation cannot invent an attack")
			else: check(contact.frame in ["quick_extend","jump_strike"],id+" contact shows a striking silhouette")
			if str(move.type) in ["heavy","technique"]:
				check(Sets.phase_sample(move,impact-0.001).frame!="follow_through","follow-through never precedes impact")
			check(move==before,"phase sampling never edits catalog movement")
	var signature := {"animation_type":"signature","windup":0.34,"travel":0.16,"recovery":0.35}
	check(Sets.phase_sample(signature,0).frame=="step_back","Signature begins with meaningful anticipation")
	check(Sets.phase_sample(signature,0.50).frame=="quick_extend","Signature contact stays0.50 regardless frames")
	check(Sets.phase_sample({"animation_type":"counter","is_counter_reaction":true,"windup":0.05,"travel":0.08,"recovery":0.15},0.13).frame=="quick_extend","actual passive counter has a strike")
	check(Sets.frame("unknown","guard_shift").is_empty(),"unknown body silently uses canonical fallback")
	check(Sets.frame("ascua","unknown").is_empty(),"unknown frame safely ignored")

func _test_presentation_overrides() -> void:
	var event := {"result":"hit","animation_type":"quick","target_hp":80,"move":{"presentation":{"hit_reaction":"body","impact_fx":"charge_energy","camera_feedback":"small","hit_stop":0.03}},"presentation":{"hit_reaction":"knockback","impact_fx":"critical_hit","camera_feedback":"strong","hit_stop":0.08}}
	var before := event.duplicate(true)
	var actual := Sets.reaction_for(event)
	check(actual=={"reaction":"knockback","impact_fx":"critical_hit","camera_feedback":"strong","hit_stop":0.08},"event presentation overrides move defaults without changing gameplay")
	check(event==before,"nested presentation dictionaries remain immutable")
	event.presentation={"hit_reaction":"ko","impact_fx":"unknown","camera_feedback":3,"hit_stop":"0.1"}
	check(Sets.reaction_for(event)=={"reaction":"body","impact_fx":"charge_energy","camera_feedback":"small","hit_stop":0.03},"invalid fields preserve valid move defaults and cannot invent KO")
	for invalid: Variant in [null,[],"critical",12,true]:
		event.presentation=invalid
		check(Sets.reaction_for(event).reaction=="body","invalid presentation container ignored")
	for invalid: Variant in [NAN,INF,-INF,true,"0.05",{}]:
		event.presentation={"hit_stop":invalid}
		check(is_equal_approx(float(Sets.reaction_for(event).hit_stop),0.03),"invalid hitstop uses preceding default")
	event.presentation={"hit_stop":999.0}
	check(is_equal_approx(float(Sets.reaction_for(event).hit_stop),0.1),"declared hitstop bounded to100ms")
	event.presentation={"hit_stop":-2.0,"impact_fx":"none","camera_feedback":"none","hit_reaction":"light"}
	check(Sets.reaction_for(event)=={"reaction":"light","impact_fx":"none","camera_feedback":"none","hit_stop":0.0},"explicit zero and none disable optional presentation")
	event.target_hp=0
	check(Sets.reaction_for(event).reaction=="ko","KO cannot be overridden by cosmetic reaction")
	for result: String in ["dodge","miss"]:
		event.result=result
		check(Sets.reaction_for(event)=={"reaction":result,"impact_fx":"none","hit_stop":0.0,"camera_feedback":"none"},"non-contact results cannot produce impact effects")
	check(Sets.reaction_for({"move":null}).reaction=="light","malformed optional move safely ignored")
	var actor := _actor(Catalog.definition("nima"))
	actor.play_reaction({"result":"hit","presentation":{"hit_reaction":"getup","hit_stop":0.07}})
	check(actor.get_animation_state().clip=="getup","configured reaction reaches actor timeline")
	actor.free()

func _test_reaction_event_join() -> void:
	var actor := _actor(Catalog.definition("nima"))
	var move := {"id":"scheduled_quick","animation_type":"quick","windup":0.3,"travel":0.2,"recovery":0.3,"presentation":{"hit_reaction":"heavy","impact_fx":"heavy_hit","hit_stop":0.06}}
	var counter := {"id":"passive_counter","animation_type":"counter","is_counter_reaction":true,"windup":0.05,"travel":0.08,"recovery":0.15,"presentation":{"hit_reaction":"body","impact_fx":"small_hit","hit_stop":0.02}}
	actor.play_move(move,0.04)
	actor.play_move(counter,0.01)
	var state_before: Dictionary=actor.get_animation_state().duplicate(true)
	var event := {"type":"attack","move_id":"scheduled_quick","result":"hit","target_hp":90,"presentation":{"impact_fx":"charge_energy"}}
	var original := event.duplicate(true)
	var prepared: Dictionary=actor.prepare_reaction_event(event,0.04)
	check(prepared.move==move and is_equal_approx(float(prepared.presentation_elapsed),0.04),"attack ID retrieves its complete started move and event age")
	check(Sets.reaction_for(prepared).reaction=="heavy" and Sets.reaction_for(prepared).impact_fx=="charge_energy","joined move presentation reaches resolver while event override wins")
	check(event==original and actor.get_animation_state()==state_before,"preparing reaction never edits immutable event or animation clocks/state")
	prepared.move.presentation.hit_reaction="knockdown"
	prepared.presentation.impact_fx="none"
	check(actor._move.presentation.hit_reaction=="heavy" and event.presentation.impact_fx=="charge_energy","prepared nested dictionaries are independent of actor and event")
	prepared=actor.prepare_reaction_event({"move_id":"passive_counter","result":"hit"},0.01)
	check(prepared.move==counter and Sets.reaction_for(prepared).reaction=="body","overlapping passive counter resolves its own presentation")
	check(is_equal_approx(actor._counter_time,0.01) and is_equal_approx(actor._action_time,0.04),"counter lookup preserves both independent clocks")
	for absent: Dictionary in [{},{"move_id":""},{"move_id":null},{"move_id":7},{"move_id":"unrelated_old_move"}]:
		prepared=actor.prepare_reaction_event(absent)
		check(not prepared.has("move"),"absent or mismatching ID cannot borrow another move's presentation")
	for explicit: Variant in [{},{"id":"explicit","presentation":{"hit_reaction":"light"}},null]:
		prepared=actor.prepare_reaction_event({"move_id":"scheduled_quick","move":explicit},0.0)
		check(prepared.move==explicit,"explicit event.move always remains authoritative")
	for offset: float in [-1.0,NAN,INF]:
		check(actor.prepare_reaction_event(event,offset).presentation_elapsed==0.0,"invalid or negative presentation age becomes zero")
	actor._process(0.4)
	check(not actor.prepare_reaction_event({"move_id":"passive_counter"}).has("move"),"expired counter cannot borrow the scheduled attack")
	actor.play_move({"id":"next_attack","animation_type":"quick","windup":0.1,"travel":0.1,"recovery":0.2})
	check(not actor.prepare_reaction_event({"move_id":"scheduled_quick"}).has("move"),"replaced attack ID never inherits the next attack configuration")
	actor.free()

func _test_fixed_framing() -> void:
	for width: float in [360.0,390.0,430.0,639.0,768.0]:
		var idle := Layout.calculate(Vector2(width,844),false)
		for phase: Array in [[true,false],[false,true]]:
			var active := Layout.calculate(Vector2(width,844),phase[0],phase[1])
			check(active.actor_scale==idle.actor_scale and active.player_at==idle.player_at and active.rival_at==idle.rival_at,"compact ground origin and scale remain stable across battle/result")
	for body: String in Sets.BASE_TO_BODY.values():
		if Sets.frame(body,"heavy_hit").is_empty() or Sets.frame(body,"guard_shift").is_empty(): continue
		_test_body_framing(body)

func _test_body_framing(body: String) -> void:
	var definition: Dictionary=Catalog.definition(body) if body in Catalog.IDS else Story.boss_definition(1 if body=="ascua" else 2)
	var actor := _actor(definition)
	root.add_child(actor)
	var sizes: Array[Vector2] = [Vector2(360,780),Vector2(390,844),Vector2(430,932),Vector2(768,1024),Vector2(844,390),Vector2(1360,880)]
	for view: Vector2 in sizes:
		var layout := Layout.calculate(view,true)
		for direction: int in [1,-1]:
			actor.facing=direction
			actor.scale=Vector2.ONE*float(layout.actor_scale)
			actor.position=layout.player_at if direction==1 else layout.rival_at
			var origin: Vector2=actor.position
			var worst_left := INF
			var worst_right := -INF
			for kind: String in ["quick","heavy","charge","dash","jump","special","signature"]:
				actor.reset_pose()
				actor.play_move({"id":"framing_"+kind,"type":kind,"animation_type":kind,"windup":0.30,"travel":0.20,"recovery":0.30})
				# Concurrent recoil can extend the outward edge during anticipation.
				actor.play_reaction({"result":"critical"})
				for tick: int in range(81):
					actor._action_time=tick*0.01
					actor._overlay_elapsed=fmod(tick*0.01,0.4)
					actor._update_pose()
					var bounds := _draw_bounds(actor)
					worst_left=minf(worst_left,bounds.position.x)
					worst_right=maxf(worst_right,bounds.end.x)
			for kind: String in ["light","body","heavy","critical","knockback","knockdown","getup","ko"]:
				actor.reset_pose()
				actor.play_reaction({"result":"hit","target_hp":0 if kind=="ko" else 100,"presentation":{"hit_reaction":kind}})
				for tick: int in range(101):
					actor._action_time=tick*0.01
					actor._update_pose()
					var bounds := _draw_bounds(actor)
					worst_left=minf(worst_left,bounds.position.x)
					worst_right=maxf(worst_right,bounds.end.x)
			check(worst_left>=0 and worst_right<=view.x,"%s continuous poses fit at %s facing%d: %.2f..%.2f"%[body,str(view),direction,worst_left,worst_right])
			check(actor.position==origin,"animation never clamps or drifts ground origin")
	actor.free()

func _draw_bounds(actor: Node2D) -> Rect2:
	return actor.visible_sprite_bounds()


func _test_complete_roster() -> void:
	# Deployment gate: optional missing packs are fine in production, never in this mode.
	Sets.clear_cache()
	var bodies: Array[String]=Catalog.IDS.duplicate()
	bodies.append_array(["ascua","vespera"])
	check(bodies.size()==Sets.BASE_TO_BODY.size(),"every playable body and both bosses have an animation registry entry")
	for body: String in bodies:
		for bank: String in Sets.BANKS:
			var normalized_path: String=Sets.NORMALIZED_ROOT+body+"-"+bank+"-v2.png"
			var path: String=normalized_path if ResourceLoader.exists(normalized_path) and not Sets.VisualProfiles.profile(body).is_empty() else Sets.ROOT+body+"-"+bank+"-v1.png"
			check(ResourceLoader.exists(path),"required imported bank exists: "+path)
			check(FileAccess.file_exists(path.get_basename()+".json"),"required metadata exists: "+path)
			if not ResourceLoader.exists(path) or not FileAccess.file_exists(path.get_basename()+".json"): continue
			var source := (load(path) as Texture2D).get_image()
			if source.is_compressed(): source.decompress()
			check(source.detect_alpha()!=Image.ALPHA_NONE,"bank preserves real transparent background: "+path)
			var regions: Array[Rect2i]=[]
			for name: String in Sets.BANKS[bank]:
				var frame := Sets.frame(body,name)
				check(not frame.is_empty(),"required real frame "+body+"/"+name)
				if frame.is_empty(): continue
				check(str(frame.source_path)==path and frame.texture is AtlasTexture,"frame cannot substitute legacy atlas: "+body+"/"+name)
				check(Rect2i(Vector2i.ZERO,source.get_size()).encloses(frame.region) and frame.bounds.has_area(),"frame has visible silhouette inside source: "+body+"/"+name)
				for earlier: Rect2i in regions: check(not earlier.intersects(frame.region),"regions do not include neighboring poses: "+body+"/"+name)
				regions.append(frame.region)
			check(regions.size()==16,"bank provides16real poses without fallback: "+path)
		check(Sets.cache_info().count<=Sets.CACHE_LIMIT,"full roster loading keeps six-bank LRU bound")

func _test_reactions_and_clock() -> void:
	var actor := _actor(Catalog.definition("nima"))
	var quick: Dictionary = Moves.moves_for("nima")[0]
	var events: Array[Dictionary] = [
		{"result":"hit","animation_type":"quick","expected":"light"},
		{"result":"hit","animation_type":"technique","expected":"body"},
		{"result":"hit","animation_type":"heavy","expected":"heavy"},
		{"result":"critical","animation_type":"quick","expected":"critical"},
		{"result":"hit","animation_type":"charge","expected":"knockback"},
		{"result":"signature","signature":true,"expected":"knockdown"},
		{"result":"dodge","expected":"dodge"},{"result":"miss","expected":"miss"}]
	for event: Dictionary in events:
		actor.reset_pose()
		var original := event.duplicate(true)
		var metadata: Dictionary = actor.play_reaction(event)
		check(metadata.reaction==event.expected,"actual attack selects "+str(event.expected))
		check(metadata.impact_fx in ["small_hit","heavy_hit","critical_hit","none"],"reaction metadata uses shared FX identifiers")
		check(event==original,"reaction does not mutate replay event")
	actor.reset_pose()
	actor.play_move(quick,0.02)
	var outgoing_time: float = actor._action_time
	actor.play_reaction({"result":"critical","presentation_elapsed":0.04})
	check(actor._mode=="move" and is_equal_approx(actor._action_time,outgoing_time),"critical received during windup cannot erase or advance outgoing action")
	actor.move_impact(false,str(quick.id))
	check(actor._action_time>=float(quick.impact_delay),"overlap still reaches actual own impact")
	actor._process(float(quick.recovery)+0.01)
	check(actor._mode=="reaction","deferred recoil follows completed outgoing action")
	actor._process(1.0)
	check(actor._mode=="idle","deferred reaction finishes normally")
	actor.reset_pose()
	actor.play_move(quick,0.01)
	var clock_before: float = actor._action_time
	var sprite: Sprite2D = actor.get_node("IllustratedFighter")
	var before_texture: Texture2D = sprite.texture
	var before_position: Vector2 = sprite.position
	actor.request_hit_stop(0.07)
	actor._process(0.04)
	check(is_equal_approx(actor._action_time,clock_before+0.04),"hitstop does not delay authoritative animation clock")
	check(sprite.texture==before_texture and sprite.position==before_position,"hitstop really freezes visible sprite")
	actor._process(0.04)
	check(actor._hit_stop_remaining==0,"bounded hitstop ends without extra delay")
	check(actor._action_time>=clock_before+0.08-0.00001,"visual resumes at current clock without slow catchup")
	actor.motion_paused=true
	clock_before=actor._action_time
	actor._process(1.0)
	check(actor._action_time==clock_before,"modal pause still freezes both gesture and hitstop clocks")
	actor.motion_paused=false
	actor.reset_pose()
	var late: Dictionary = actor.play_reaction({"result":"critical","presentation_elapsed":0.10})
	check(is_equal_approx(actor._action_time,0.10),"late replay reaction uses same event-relative offset")
	check(float(late.hit_stop)==0,"already elapsed hitstop cannot restart late in replay")
	actor.play_reaction({"result":"hit","target_hp":0.0,"presentation_elapsed":0.12})
	check(actor._mode=="fall" and is_equal_approx(actor._action_time,0.12),"terminal event begins KO at original event time")
	actor._process(0.2)
	clock_before=actor._action_time
	actor.fall()
	check(actor._action_time==clock_before,"result screen cannot restart KO sequence")
	actor.play_move(quick)
	actor.play_reaction({"result":"critical"})
	check(actor._mode=="fall","KO rejects later moves and reactions")
	actor._process(2.0)
	check(actor.get_sprite_geometry().active_frame==7,"KO settles on canonical final resting pose")
	actor.reset_pose()
	actor.play_reaction({"result":"signature"})
	actor._process(0.45)
	clock_before=actor._action_time
	actor.play_reaction({"result":"hit","animation_type":"quick"})
	check(actor._reaction_kind=="knockdown" and actor._action_time==clock_before,"small hits cannot pop a fallen fighter upright")
	actor.play_hit()
	check(actor._mode=="reaction" and actor._reaction_kind=="knockdown","status hit preserves knockdown recovery")
	actor.play_move(quick)
	check(actor._mode=="move" and actor._recover_into_move,"next authoritative action incorporates getting up without delay")
	actor.reset_pose()
	actor.reduced_motion=true
	actor.request_hit_stop(0.08)
	check(actor._hit_stop_remaining==0,"reduced motion removes hitstop")
	actor.play_reaction({"result":"hit","animation_type":"charge"})
	actor._process(0.1)
	check(sprite.position==Vector2.ZERO and is_zero_approx(sprite.rotation),"reduced motion keeps readable reaction without displacement")
	actor.free()

func _test_body_selection() -> void:
	var descriptor := Catalog.definition("tepa")
	descriptor["appearance"]={"body_style_id":"mugo"}
	var before := descriptor.duplicate(true)
	var actor := _actor(descriptor)
	check(actor.get_animation_state().body_id=="mugo","animation set follows selected cosmetic body")
	check(descriptor==before,"visual body never rewrites character stats or descriptor")
	check(actor.get_sprite_geometry().frames.size()==8,"semantic pose contract remains8 for portraits")
	check(not actor.play_transformation(),"ordinary character cannot claim Ascua transformation")
	actor.free()
	var boss: Dictionary = Story.boss_definition(1)
	boss["id"]="mugo"
	actor=_actor(boss)
	check(actor.get_animation_state().body_id=="ascua","legacy live Boss id resolves by actual atlas")
	var state_before: Dictionary=actor.get_animation_state().duplicate(true)
	var texture_before: Texture2D=actor.get_node("IllustratedFighter").texture
	actor.prepare_combat_animation()
	check(actor.get_animation_state()==state_before,"resource preflight preserves frame, mode, form and all clocks")
	check(actor.get_node("IllustratedFighter").texture==texture_before and not actor._sequence_idle_enabled,"preflight does not replace the current sprite or activate expanded idle")
	actor.free()

func _test_pilot() -> void:
	Sets.clear_cache()
	var ready := Sets.available("ascua")
	check(ready or not require_pilot,"complete pilot has imported PNG plus local metadata")
	if not ready: return
	if not require_pilot and not FileAccess.file_exists(Sets.ROOT+"ascua-movement-v1.json"):
		print("Pilot movement metadata still pending; core contract only.")
		return
	var actor := _actor(Story.boss_definition(1))
	check(actor.get_animation_state().enabled,"pilot sequences enabled")
	for bank: String in Sets.BANKS:
		var bank_scale := 0.0
		for name: String in Sets.BANKS[bank]:
			var frame := Sets.frame("ascua",name)
			check(not frame.is_empty(),"pilot provides "+name)
			if frame.is_empty(): continue
			check(frame.texture is AtlasTexture,"new pose references source atlas")
			check(frame.bounds.size.x>0 and frame.bounds.size.y>0,"pose has alpha silhouette")
			check(frame.region.encloses(Rect2i(frame.region.position+frame.bounds.position,frame.bounds.size)),"pose cropping stays within declared cell")
			if bank_scale==0: bank_scale=float(frame.scale)
			check(is_equal_approx(float(frame.scale),bank_scale),"all poses in bank share one scale")
	check(Sets.cache_info().count<=Sets.CACHE_LIMIT,"sequence texture cache bounded")
	for kind: String in ["quick","heavy","charge","dash","jump","special","signature"]:
		var move := {"id":"probe_"+kind,"type":kind,"animation_type":kind,"windup":0.30,"travel":0.20,"recovery":0.30}
		actor.reset_pose()
		actor.play_move(move)
		var observed: Array[String] = []
		for t: float in [0.0,0.11,0.22,0.31,0.40,0.50,0.62,0.74]:
			actor._action_time=t
			actor._update_pose()
			var state: Dictionary=actor.get_animation_state()
			check(not bool(state.fallback),kind+" uses actual new sprite at "+str(t))
			if not str(state.frame) in observed: observed.append(str(state.frame))
		check(observed.size()>=3,kind+" has distinct preparation/contact/recovery frames")
	actor.reset_pose()
	check(actor.play_transformation(),"Ascua can enter declared purely visual form")
	check(actor.get_animation_state().transformation=="ember_core","form state explicit")
	actor._process(0.40)
	check(actor.get_animation_state().frame in ["transform_start","transform_peak"],"transformation plays intermediary sprite")
	actor._process(0.50)
	check(actor.get_animation_state().frame=="transformed_idle","transformation settles into distinct idle")
	actor.play_move({"id":"transformed_attack","type":"quick","windup":0.1,"travel":0.1,"recovery":0.2})
	check(actor.get_animation_state().transformation=="ember_core","same explicit visual form persists over attack frames without globally relighting materials")
	actor._process(8.0)
	check(actor.get_animation_state().transformation=="","visual form expires after8seconds")
	actor.reset_pose()
	actor.play_reaction({"result":"hit","target_hp":0})
	var seen: Array[String] = []
	for step: int in range(8):
		seen.append(str(actor.get_animation_state().frame))
		actor._process(0.11)
	check("fall_start" in seen and "fall_mid" in seen and "grounded" in seen,"KO uses fall, ground contact and final rest")
	check(actor.get_animation_state().frame==("grounded" if actor.get_animation_state().normalized else "defeat"),"KO holds its normalized ground pose without returning to another source library")
	actor.free()
