extends SceneTree
## Isolated presentation-only fixtures; no Main, save files or remote accounts.
const FX = preload("res://scripts/combat_fx.gd")
const Profiles = preload("res://scripts/move_visual_profile.gd")
var checks := 0
var failures := 0
class Actor extends Node2D:
	var facing := 1
	var travel := 0.0
	var lift := 0.0
	func effect_anchor(kind: String = "body") -> Vector2:
		if kind in ["ground","feet","left_foot","right_foot"]:
			return Vector2(travel*facing + (-12 if kind=="left_foot" else 12 if kind=="right_foot" else 0)*facing,0)
		return Vector2((travel + (30 if kind=="hand" else -20 if kind=="back" else 0))*facing,-76-lift)
func _init() -> void: _run.call_deferred()
func check(value: bool, message: String) -> void:
	checks+=1
	if not value:
		failures+=1
		push_error("VISUAL FX MARKERS: "+message)
func _event(kind: String = "charge", time: float = 0.0) -> Dictionary:
	return {"type":"move_started","side":"player","time":time,"move":{"id":"test_"+kind,"animation_type":kind,"windup":0.4,"travel":0.2,"recovery":0.4,"damage_multiplier":1.0}}
func _ids(state: Dictionary) -> Array[String]:
	var result: Array[String]=[]
	for marker: Dictionary in state.markers: result.append(str(marker.id))
	return result
func _run() -> void:
	var fx := FX.new()
	root.add_child(fx)
	fx.set_process(false)
	var actor := Actor.new()
	root.add_child(actor)
	actor.position=Vector2(300,280)
	var event := _event()
	var unchanged := event.duplicate(true)
	var profile := Profiles.resolve(event)
	for key: String in ["animation_id","composite_animation_variant","attached_fx_animation","impact_fx","trail_fx","ground_fx","hit_reaction","camera_feedback","hit_stop","sound_event","transformation_requirement","events","markers"]:
		check(profile.has(key),"complete move visual field "+key)
	check(profile.animation_id=="charge" and profile.attached_fx_animation=="charge_core_hand","charge references the anatomical paired track")
	check(event==unchanged,"profile resolution preserves authoritative data")
	var reference: Array[String]=[]
	for fps: int in [20,60,120]:
		for speed: float in [1.0,2.0]:
			fx.clear()
			actor.travel=0; actor.lift=0
			fx.play_move(event,actor)
			var elapsed := 0.0
			while elapsed<1.15:
				var dt := speed/float(fps)
				elapsed+=dt
				actor.travel=clampf((elapsed-0.4)/0.2,0,1)*70
				fx._process(dt)
				fx.play_move(event,actor,elapsed) # reconciliation must not re-emit
				var current := fx.debug_state()
				check(current.particles<=FX.MAX_PARTICLES and current.active.size()<=FX.MAX_EFFECTS and current.pending<=FX.MAX_PENDING,"bounded effects at %d FPS x%.0f" % [fps,speed])
			var result := _ids(fx.debug_state())
			if reference.is_empty(): reference=result
			check(result==reference,"all phase crossings in stable order at %d FPS x%.0f" % [fps,speed])
			var unique := {}
			for id: String in result: unique[id]=true
			check(result.size()==unique.size() and result.size()==profile.markers.size(),"each marker fires exactly once across frame skipping and contact reconciliation")
			fx._process(2)
			check(fx.debug_state().active.is_empty() and fx.debug_state().pending==0,"move and particles expire")
	check(event==unchanged,"frame-rate sampling cannot mutate battle events")
	fx.clear()
	fx.play_move(event,actor,0.61)
	var caught := fx.debug_state()
	check(_ids(caught).has("dash_ground") and _ids(caught).has("dash_trail"),"late entry catches up across multiple marker boundaries")
	var dash_age := -1.0
	for item: Dictionary in caught.active:
		if str(item.id)=="dash_trail": dash_age=float(item.age)
	check(is_equal_approx(dash_age,0.21),"catchup keeps the true age of the still-live trail")
	var count: int = caught.markers.size()
	fx.play_move(event,actor,0.61)
	check(fx.debug_state().markers.size()==count,"duplicate late event adds no particle or marker")
	fx.motion_paused=true
	var frozen := fx.debug_state()
	fx._process(0.3)
	check(fx.debug_state()==frozen,"pause freezes marker cursor and particles together")
	fx.motion_paused=false
	fx._process(0.5)
	check(fx.debug_state().pending==0,"resume completes remaining markers")
	fx.clear()
	fx.play_move(event,actor,8.0)
	check(fx.debug_state().active.is_empty() and fx.debug_state().pending==0,"expired catchup creates no ghost effects")
	fx.play_move(event,actor,0.0)
	check(fx.debug_state().active.is_empty(),"completed action dedup ignores a stale rewind until clear")
	fx.clear()
	fx.play_move(event,actor,0.0)
	check(not fx.debug_state().active.is_empty(),"explicit seek reset allows a fresh reconstruction")
	fx.clear()
	var jump := _event("jump")
	actor.travel=0; actor.lift=65
	fx.play_move(jump,actor,0.80)
	var landing_at := Vector2.ZERO
	for marker: Dictionary in fx.debug_state().markers:
		if marker.event in ["landing","jump_takeoff"]:
			landing_at=marker.at
			check(is_equal_approx(landing_at.y,actor.position.y),"jump contact remains at projected world floor despite airborne body")
	actor.position.x+=120
	actor.lift=0
	fx._process(0.05)
	for item: Dictionary in fx.debug_state().active:
		if FX.definitions().effects[item.id].get("grounded",false):
			for particle: Dictionary in item.particles:
				check(particle.at.y<=actor.position.y+0.001,"ground grains never sink under birth floor")
				check(absf(particle.at.x-landing_at.x)<65,"released ground grains stay behind when actor moves")
	fx.clear()
	actor.position=Vector2(300,280)
	actor.travel=25
	actor.facing=1
	fx.play_move(event,actor,0.15)
	var right_at := Vector2.ZERO
	for marker: Dictionary in fx.debug_state().markers:
		if str(marker.id)=="plant":right_at=marker.at
	fx.clear(); actor.facing=-1
	fx.play_move(event,actor,0.15)
	var left_at := Vector2.ZERO
	for marker: Dictionary in fx.debug_state().markers:
		if str(marker.id)=="plant":left_at=marker.at
	check(is_equal_approx(right_at.x-300,300-left_at.x) and right_at.y==left_at.y,"facing mirrors the contact X while preserving the floor")
	fx.clear()
	fx.play_impact(Vector2(300,200),{"impact_fx":"heavy_hit","reaction":"knockdown"},1,1,0,actor)
	var active_ids: Array[String]=[]
	for item: Dictionary in fx.debug_state().active:active_ids.append(str(item.id))
	check(active_ids.has("knockback_dust") and active_ids.has("stone_debris"),"heavy floor reaction composes world dust and debris")
	fx.reduced_motion=true
	fx._process(0.01)
	fx.play_move(event,actor)
	check(fx.debug_state().active.is_empty() and fx.debug_state().pending==0,"reduced motion clears all marker schedules and effects")
	fx.reduced_motion=false
	fx.clear()
	for index: int in range(100):fx.play_move(_event("charge",float(index)),actor,2.0)
	check(fx.debug_state().seen_actions<=FX.MAX_SEEN_ACTIONS and fx.debug_state().markers.size()<=FX.MAX_MARKER_HISTORY,"dedup and debug histories are bounded")
	fx.play_move(_event("jump",101),actor)
	actor.free()
	fx._process(0.01)
	check(fx.debug_state().pending==0,"freed actors remove all pending markers")
	fx.free()
	print("VISUAL FX MARKERS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
