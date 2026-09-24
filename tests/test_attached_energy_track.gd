extends SceneTree
const Track = preload("res://scripts/attached_energy_track.gd")
const Sets = preload("res://scripts/fighter_animation_set.gd")
const Fighter = preload("res://scripts/fighter_view.gd")
const Story = preload("res://scripts/story_catalog.gd")
var checks := 0
var failures := 0
func _init() -> void: _run.call_deferred()
func check(value: bool, message: String) -> void:
	checks+=1
	if not value:
		failures+=1
		push_error("ATTACHED ENERGY: "+message)
func _frame(name: String = "charge_crouch") -> Dictionary:
	return {"name":name,"body_id":"ascua","profile_id":"ascua:normal:v1","normalized":true,"canvas_px":Vector2i(512,512),"anchor":Vector2(256,448),"sockets_px":{"core":Vector2(260,274),"hand":Vector2(304,273),"ground":Vector2(256,448)}}
func _run() -> void:
	Track.clear_cache()
	var frame := _frame()
	var untouched := frame.duplicate(true)
	var texture := Track.texture_for(frame)
	check(texture!=null and texture.get_size()==Vector2(512,512),"paired track retains the full character canvas")
	check(frame==untouched,"generating emissive details never edits frame geometry")
	check(Track.texture_for(frame)==texture,"a pose reuses its cached aligned texture")
	var image := texture.get_image()
	var alpha_max := 0.0
	var outside := 0
	var lit := 0
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var color := image.get_pixel(x,y)
			alpha_max=maxf(alpha_max,color.a)
			if color.a<=0: continue
			lit+=1
			var point := Vector2(x,y)+Vector2(0.5,0.5)
			if point.distance_to(frame.sockets_px.core)>=Track.CORE_RADIUS and point.distance_to(frame.sockets_px.hand)>=Track.HAND_RADIUS: outside+=1
	check(lit>100 and lit<800,"usable emission occupies only tiny anatomical patches")
	check(outside==0,"every texel outside authored core/hand regions is transparent")
	check(alpha_max<=Track.MAX_ALPHA+1.0/255.0,"maximum opacity cannot wash out the underlying body")
	var core_only := Track.texture_for(frame,"core").get_image()
	check(core_only.get_pixelv(Vector2i(frame.sockets_px.hand)).a==0,"core-only channel does not invent hand emission")
	var absent := _frame()
	absent.sockets_px.erase("core")
	check(Track.texture_for(absent)==null,"missing authored core gives no guessed body glow")
	absent=_frame(); absent["socket_visibility"]={"core":"occluded"}
	check(Track.texture_for(absent)==null,"occluded core cannot glow through other anatomy")
	absent=_frame(); absent["socket_visibility"]={"hand":"occluded"}
	check(Track.texture_for(absent).get_image().get_pixelv(Vector2i(absent.sockets_px.hand)).a==0,"occluded hand cannot emit over another body part")
	absent=_frame(); absent.sockets_px.core=Vector2(NAN,0)
	check(Track.texture_for(absent)==null,"non-finite anatomical socket is rejected")
	absent=_frame(); absent.sockets_px.core=Vector2(900,0)
	check(Track.texture_for(absent)==null,"outside-canvas socket is rejected")
	absent=_frame(); absent.body_id="luma"
	check(Track.texture_for(absent)==null,"Ascua emissive anatomy is never applied to another fighter")
	absent=_frame(); absent.normalized=false
	check(Track.texture_for(absent)==null,"legacy crop geometry cannot silently enter the paired pipeline")
	absent=_frame(); absent.canvas_px=Vector2i(256,256)
	check(Track.texture_for(absent)==null,"incompatible canvas is rejected instead of being fitted")
	check(Track.texture_for(frame,"unknown")==null,"unknown emission channel is rejected")
	var overlap := _frame("overlap")
	overlap.sockets_px.hand=overlap.sockets_px.core
	var overlap_image := Track.texture_for(overlap).get_image()
	var center_alpha := overlap_image.get_pixelv(Vector2i(overlap.sockets_px.core)).a
	check(center_alpha<=Track.MAX_ALPHA+1.0/255.0,"overlapping core and hand cannot accumulate above opacity cap")
	Track.clear_cache()
	var repeat := Track.texture_for(frame).get_image()
	check(repeat.get_data()==image.get_data(),"a rebuilt texture is deterministic without an animation clock")
	seed(509)
	var random_expected := randi()
	seed(509)
	for index: int in range(48): Track.texture_for(_frame("pose_%d" % index))
	check(randi()==random_expected,"procedural pigments never consume gameplay RNG")
	check(Track.debug_info().count==Track.CACHE_LIMIT,"texture cache remains bounded")
	var real_authored := 0
	for bank: String in ["base","movement","reactions"]:
		var pack := Sets.normalized_pack("ascua",bank)
		if pack.is_empty(): continue
		for actual: Dictionary in pack.frames.values():
			if not actual.get("sockets_px",{}).has("core"):continue
			var paired := Track.texture_for(actual)
			if str(actual.get("socket_visibility",{}).get("core","visible"))=="occluded":
				check(paired==null,"occluded production core remains unlit "+str(actual.name))
				continue
			check(paired!=null and paired.get_size()==actual.texture.get_size(),"authored production pose receives an identically-sized paired canvas "+str(actual.name))
			real_authored+=1
	check(real_authored>=16,"the actual Ascua pilot contains authored sockets for a complete movement bank")
	_runtime_contract()
	print("ATTACHED ENERGY: %d checks, %d failures, %d authored production poses" % [checks,failures,real_authored])
	Track.clear_cache()
	quit(1 if failures else 0)

func _runtime_contract() -> void:
	var actor := Fighter.new()
	root.add_child(actor)
	actor.set_process(false)
	var move := {"id":"paired_charge_test","animation_type":"charge","windup":0.4,"travel":0.2,"recovery":0.4}
	for facing: int in [1,-1]:
		actor.setup_character(Story.boss_definition(1),facing)
		for time: float in [0.1,0.2,0.3,0.41,0.55,0.7,0.88]:
			actor.play_move(move,time)
			var state := actor.get_animation_state()
			check(state.normalized and state.body_id=="ascua" and state.attached_fx,"real Ascua charge frame produces visible paired FX "+str(state.frame))
			check(actor._attached_fx.texture.get_size()==Vector2(512,512),"runtime keeps the paired full canvas")
			check(actor._attached_fx.transform==actor._sprite.transform and actor._attached_fx.offset==actor._sprite.offset,"body and FX share pivot, scale, position, mirror and rotation")
			check(is_equal_approx(actor._attached_fx.modulate.a,float(state.attached_fx_gain)) and state.attached_fx_gain>0 and state.attached_fx_gain<=1,"intensity comes from the body's charge phase clock")
			var body_texture: Texture2D=actor._sprite.texture
			var body_transform: Transform2D=actor._sprite.transform
			var body_data := body_texture.get_image().get_data()
			actor.attached_fx_enabled=false
			actor._update_attached_fx()
			check(not actor._attached_fx.visible and actor._sprite.texture==body_texture and actor._sprite.transform==body_transform,"disabling FX preserves the exact body pose and geometry")
			check(actor._sprite.texture.get_image().get_data()==body_data,"FX toggling never modifies a body texel")
			actor.attached_fx_enabled=true
			actor._update_attached_fx()
		actor.motion_paused=true
		var paused_transform: Transform2D=actor._attached_fx.transform
		var paused_texture: Texture2D=actor._attached_fx.texture
		var paused_gain: float=actor._attached_fx.modulate.a
		actor._process(0.3)
		check(actor._attached_fx.transform==paused_transform and actor._attached_fx.texture==paused_texture and actor._attached_fx.modulate.a==paused_gain,"pause freezes the paired track with the body")
		actor.motion_paused=false
		actor.request_hit_stop(0.08)
		actor._process(0.03)
		check(actor._attached_fx.transform==paused_transform and actor._attached_fx.texture==paused_texture and actor._attached_fx.modulate.a==paused_gain,"hit stop does not let the paired effect drift to another frame")
		actor.reduced_motion=true
		actor._hit_stop_remaining=0
		actor._update_pose()
		check(not actor._attached_fx.visible,"reduced motion suppresses the paired energy layer")
		actor.reduced_motion=false
	actor.free()
