extends SceneTree
## Read-only presentation fixtures. No backend, game RNG, progression or saves.
const Fighter = preload("res://scripts/fighter_view.gd")
const Sets = preload("res://scripts/fighter_animation_set.gd")
const Profiles = preload("res://scripts/character_visual_profile.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Story = preload("res://scripts/story_catalog.gd")
var checks := 0
var failures := 0

func _init() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error("VISUAL CONSISTENCY: "+message)

func _actor(body: String) -> Node2D:
	var definition: Dictionary=Story.boss_definition(1 if body=="ascua" else 2) if body in ["ascua","vespera"] else preload("res://scripts/cosmetic_catalog.gd").body_definition(body)
	var actor := Fighter.new()
	root.add_child(actor)
	actor.set_process(false)
	actor.setup_character(definition)
	return actor

func _run() -> void:
	_test_terminals()
	_test_sockets()
	_test_paired_track()
	_test_reaction_aliases()
	_test_canvas_contract()
	_test_profiles()
	print("VISUAL CONSISTENCY: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func _test_terminals() -> void:
	var actor := _actor("ascua")
	var move := {"id":"test-heavy","animation_type":"heavy","windup":0.4,"travel":0.2,"recovery":0.3}
	actor.celebrate()
	check(actor.get_animation_state().mode=="idle","unresolved combat cannot start victory")
	actor.play_move(move)
	check(actor.get_animation_state().visual_state=="attacking","heavy starts with attack anticipation")
	actor.resolve_battle(true)
	check(actor.get_animation_state().mode=="victory","resolved winner starts victory")
	var elapsed: float=actor._action_time
	actor.play_move(move)
	actor.play_attack()
	actor.play_dodge()
	actor.play_hit()
	check(actor.get_animation_state().mode=="victory" and actor._action_time==elapsed,"normal commands cannot interrupt terminal victory")
	actor.play_reaction({"result":"hit","target_hp":0})
	check(actor.get_animation_state().visual_state=="KO","KO interrupts victory")
	actor.resolve_battle(true)
	actor.preview_victory()
	check(actor.get_animation_state().visual_state=="KO","no result or preview can revive a KO")
	actor._process(1.2)
	var pose: String=actor.get_animation_state().frame
	actor._process(2.0)
	check(actor.get_animation_state().frame==pose,"KO final pose remains held without oscillating libraries")
	actor.reset_pose()
	actor.preview_victory()
	check(actor.get_animation_state().battle_result=="preview","explicit noncombat preview remains supported")
	actor.reset_pose()
	actor.play_move({"id":"jump","animation_type":"jump","windup":0.2,"travel":0.3,"recovery":0.3},0.25)
	check(actor.get_animation_state().visual_state=="airborne" and not actor.get_animation_state().grounded,"jump travel cannot report idle or ground contact")
	actor.free()

func _test_sockets() -> void:
	var actor := _actor("ascua")
	actor.play_move({"id":"jump","animation_type":"jump","windup":0.2,"travel":0.3,"recovery":0.3},0.3)
	var frame: Dictionary=actor._current_frame().duplicate(true)
	frame["sockets_px"]={"core":Vector2(frame.anchor)+Vector2(13,-88),"ground":Vector2(frame.anchor),"left_foot":Vector2(frame.anchor)+Vector2(-18,0),"right_foot":Vector2(frame.anchor)+Vector2(18,0)}
	actor._sequence_frame=frame
	actor._resolve_render_frame()
	var core: Vector2=actor.effect_anchor("core")
	var expected: Vector2=actor._sprite.transform*Vector2(13,-88)
	check(core.is_equal_approx(expected),"authored socket follows sprite rotation, translation and scale")
	frame.bounds=Rect2i(3,11,400,100)
	check(actor.effect_anchor("core").is_equal_approx(core),"changing alpha diagnostics never moves an authored socket")
	for key: String in ["ground","feet","left_foot","right_foot"]:
		check(is_zero_approx(actor.effect_anchor(key).y),key+" is projected to the world floor even during a jump")
	actor.facing=-1
	actor._sprite.scale.x=-absf(actor._sprite.scale.x)
	check(actor.effect_anchor("core").is_finite(),"authored socket remains finite under mirroring")
	check(not Fighter.FLASH_SHADER.contains("form_glow") and not Fighter.FLASH_SHADER.contains("effect_light"),"charge cannot wash out base materials through a global light shader")
	actor.free()

func _test_canvas_contract() -> void:
	check(Profiles.valid_canvas([512,512]) and not Profiles.valid_canvas([511,512]),"normalized canvas has one exact production size")
	check(Profiles.valid_pivot([256,448]) and not Profiles.valid_pivot([256,447]),"pivot does not drift between images")
	for malformed: Variant in [null,{},[512],[true,512],[NAN,512],[INF,512]]:
		check(not Profiles.valid_canvas(malformed),"malformed canvas is rejected")
	var scene_scale := Profiles.scene_scale(Vector2(360,260))
	check(scene_scale>0 and scene_scale==Profiles.scene_scale(Vector2(360,260)),"one scene camera scale is independent of body or current pose")

func _test_reaction_aliases() -> void:
	var actor := _actor("nima")
	for reaction: String in ["head","low","airborne","guard","status","stagger"]:
		actor.reset_pose()
		var event := {"result":"hit","target_hp":40,"presentation":{"hit_reaction":reaction}}
		var original := event.duplicate(true)
		var data: Dictionary=actor.play_reaction(event)
		check(data.reaction==reaction and actor.get_animation_state().clip==reaction,reaction+" chooses a declared presentation sequence")
		check(event==original,reaction+" cannot alter authoritative damage or input event")
		actor._process(1.0)
		check(actor.get_animation_state().mode=="idle",reaction+" has bounded recovery")
	var invalid := Sets.reaction_for({"result":"hit","presentation":{"hit_reaction":"invented_reaction"}})
	check(invalid.reaction=="light","unknown reaction safely retains ordinary light hit")
	actor.free()


func _test_paired_track() -> void:
	var actor := _actor("ascua")
	actor.play_move({"id":"paired-charge","animation_type":"charge","windup":0.4,"travel":0.2,"recovery":0.3},0.2)
	var base: Texture2D=actor._sprite.texture
	var frame: Dictionary=actor._current_frame().duplicate(true)
	# A texture reference is enough to validate alignment/timing. This test does
	# not generate artwork or persist any synthetic image in the game library.
	frame["attached_fx_texture"]=base
	actor._sequence_frame=frame
	actor._update_attached_fx()
	check(actor._attached_fx.visible and is_equal_approx(actor._attached_fx_gain,0.5),"paired charge energy uses the same windup progress")
	check(actor._attached_fx.transform==actor._sprite.transform and actor._attached_fx.offset==actor._sprite.offset,"paired track matches the exact base transform and pivot")
	actor.attached_fx_enabled=false
	actor._update_attached_fx()
	check(not actor._attached_fx.visible and actor._sprite.texture==base,"FX toggle cannot replace or recolor the base texture")
	actor.attached_fx_enabled=true
	actor.reduced_motion=true
	actor._update_attached_fx()
	check(not actor._attached_fx.visible,"reduced motion hides attached energy")
	actor.reduced_motion=false
	actor.reset_pose()
	actor._sequence_frame=frame
	actor._update_attached_fx()
	check(not actor._attached_fx.visible,"ordinary idle has no charge overlay")
	actor.fall()
	actor._sequence_frame=frame
	actor._update_attached_fx()
	check(not actor._attached_fx.visible,"KO extinguishes paired energy")
	actor.free()

func _test_profiles() -> void:
	var require_normalized := "--require-normalized" in OS.get_cmdline_user_args()
	var heights: Dictionary={}
	for body: String in Sets.BASE_TO_BODY.values():
		var profile := Profiles.profile(body)
		check(not profile.is_empty() or not require_normalized,body+" has a canonical physical profile")
		if profile.is_empty(): continue
		var actor := _actor(body)
		var state: Dictionary=actor.get_animation_state()
		check(state.normalized,body+" actually renders the normalized base pack")
		check(state.profile_id==body+":normal:v1",body+" resolved the intended visual body profile")
		check(state.canvas_px==Profiles.CANVAS and state.anchor==Profiles.PIVOT,body+" full canvas and projected origin are fixed")
		check(is_equal_approx(state.draw_scale.y,1.0/Profiles.PIXELS_PER_WORLD_UNIT),body+" uses shared pixel density")
		var geometry: Dictionary=actor.get_sprite_geometry()
		heights[body]=geometry.frames[0].bounds.size.y*float(geometry.scale)
		for bank: String in ["base","movement","reactions"]:
			var pack := Sets.normalized_pack(body,bank)
			check(not pack.is_empty(),body+" has a validated normalized "+bank+" bank")
			if pack.is_empty(): continue
			for frame: Dictionary in pack.frames.values():
				check(frame.texture.region==Rect2(frame.region) and frame.region.size==Profiles.CANVAS,body+"/"+str(frame.name)+" renders full canvas without alpha fitting")
				check(frame.anchor==Profiles.PIVOT and is_equal_approx(frame.scale,float(geometry.scale)),body+"/"+str(frame.name)+" shares base pivot and scale across banks")
				if frame.has("attached_fx_texture"):
					check(frame.attached_fx_texture.region==frame.texture.region,body+" attached FX has identical sampling geometry")
		actor.play_move({"id":"canonical-charge","animation_type":"charge","windup":0.3,"travel":0.2,"recovery":0.3})
		for t: float in [0.0,0.11,0.31,0.50,0.62,0.79]:
			actor._action_time=t
			actor._update_pose()
			state=actor.get_animation_state()
			check(state.normalized and state.anchor==Profiles.PIVOT and is_equal_approx(state.draw_scale.y,geometry.scale),body+" charge preserves root and scale at "+str(t))
		actor.free()
	if require_normalized:
		check(heights.size()==Sets.BASE_TO_BODY.size(),"all current visual bodies are checked")
		if heights.has("ascua") and heights.has("luma"):
			check(float(heights.ascua)>float(heights.luma)*1.1,"deliberate boss/agile height difference survives shared runtime density")
