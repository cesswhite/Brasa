extends SceneTree
## Presentation fixtures only. No save, network or combat-rule mutation.
const Fighter = preload("res://scripts/fighter_view.gd")
const Sets = preload("res://scripts/fighter_animation_set.gd")
const Cosmetics = preload("res://scripts/cosmetic_catalog.gd")
const Story = preload("res://scripts/story_catalog.gd")
const Layout = preload("res://scripts/ui/battle_layout.gd")
var checks := 0
var failures := 0
var capture_dir := ""
var worst_outward := 0.0
func _init() -> void: run.call_deferred()
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		if failures < 20: push_error(message)
func definition(body: String) -> Dictionary:
	return Story.boss_definition(1 if body=="ascua" else 2) if body in ["ascua","vespera"] else Cosmetics.body_definition(body)
func verify(actor: Node2D, view: Vector2, origin: Vector2) -> void:
	var local_bounds: Rect2 = actor.painted_bounds_local()
	worst_outward=maxf(worst_outward,-local_bounds.position.x if actor.facing>0 else local_bounds.end.x)
	var bounds: Rect2 = actor.global_transform * local_bounds
	check(bounds.position.x>=-0.1 and bounds.end.x<=view.x+0.1,"viewport overflow: "+actor._sequence_body+" "+str(bounds))
	check(bounds.end.x<=view.x/2-5*actor.scale.x+0.1 if actor.facing>0 else bounds.position.x>=view.x/2+5*actor.scale.x-0.1,"fighters cross contact line: "+actor._sequence_body)
	check(actor.position==origin,"presentation clearance never moves the world root")
func run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): capture_dir=arg.trim_prefix("--capture-dir=")
	var actor := Fighter.new();root.add_child(actor);actor.set_process(false)
	for body: String in Sets.BASE_TO_BODY.values():
		for direction: int in [1,-1]:
			actor.setup_character(definition(body),direction)
			for view: Vector2 in [Vector2(360,780),Vector2(390,844),Vector2(430,932),Vector2(768,1024),Vector2(844,390),Vector2(1360,880),Vector2(1920,1080)]:
				var framing := Layout.calculate(view,true)
				actor.scale=Vector2.ONE*float(framing.actor_scale)
				actor.position=framing.player_at if direction>0 else framing.rival_at
				actor.set_combat_lane((framing.rival_at.x-framing.player_at.x)/(2*actor.scale.x)-6)
				var origin: Vector2=actor.position
				for kind: String in ["quick","heavy","charge","dash","jump","signature","knockdown","victory","ko"]:
					actor.reset_pose();actor.set_health_ratio(0.15);actor._process(1.0)
					if kind=="victory": actor.resolve_battle(true)
					elif kind=="ko": actor.fall()
					elif kind=="knockdown": actor.play_reaction({"result":"hit","presentation":{"hit_reaction":"knockdown"}})
					else: actor.play_move({"id":"fixture","animation_type":kind,"windup":0.3,"travel":0.2,"recovery":0.3})
					for tick: int in range(21):
						actor._action_time=float(tick)*0.05;actor._hit_stop_remaining=0;actor._update_pose()
						verify(actor,view,origin)
					# Resizing while paused must not accumulate translation.
					var before: Vector2=actor._sprite.position
					actor.set_combat_lane(actor.combat_lane_limit)
					check(actor._sprite.position.is_equal_approx(before),"lane constraint is idempotent")
	actor.free()
	if not capture_dir.is_empty() and DisplayServer.get_name()!="headless": await capture_pairs()
	print("WORST OUTWARD: ",worst_outward)
	print("FIGHTER CLEARANCE: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
func capture_pairs() -> void:
	DirAccess.make_dir_recursive_absolute(capture_dir)
	var canvas := SubViewport.new();canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(canvas)
	var bg := TextureRect.new();bg.texture=load("res://assets/arena-faroles-v2.png");bg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;bg.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;canvas.add_child(bg)
	var left := Fighter.new();var right := Fighter.new();canvas.add_child(left);canvas.add_child(right);left.set_process(false);right.set_process(false)
	for view: Vector2 in [Vector2(1360,780),Vector2(390,844)]:
		canvas.size=Vector2i(view);bg.size=view
		var framing := Layout.calculate(view,true)
		for actor in [left,right]: actor.scale=Vector2.ONE*framing.actor_scale
		left.position=framing.player_at;right.position=framing.rival_at
		for kind: String in ["attack","victory-ko","double-ko"]:
			left.setup_character(definition("mugo"),1);right.setup_character(definition("ascua"),-1)
			for actor in [left,right]: actor.set_combat_lane((right.position.x-left.position.x)/(2*actor.scale.x)-6)
			right.set_health_ratio(0.15);right._process(1)
			if kind=="attack":
				left.play_move({"id":"fixture","animation_type":"heavy","windup":0.3,"travel":0.2,"recovery":0.3});left._action_time=0.49;left._update_pose()
			else:
				left.fall();left._process(1)
				if kind=="double-ko": right.fall()
				else: right.resolve_battle(true)
				right._process(1)
			await process_frame;await process_frame;await RenderingServer.frame_post_draw
			canvas.get_texture().get_image().save_png(capture_dir.path_join("%dx%d-%s.png" % [view.x,view.y,kind]))
	canvas.free()
