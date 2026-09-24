extends SceneTree
## Validate real illustrated movement, pause, mirroring, reaction and timing.
## Optional native contact sheet: -- --capture-dir=/absolute/path
const Fighter = preload("res://scripts/fighter_view.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Moves = preload("res://scripts/move_catalog.gd")
const Layout = preload("res://scripts/ui/battle_layout.gd")
var checks := 0
var failures := 0

func _init() -> void: _run.call_deferred()

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("MOVE PRESENTATION: " + message)

func _run() -> void:
	for definition: Dictionary in Catalog.all_definitions():
		var actor = Fighter.new()
		root.add_child(actor)
		actor.set_process(false)
		actor.setup_character(definition)
		var sprite: Sprite2D = actor.get_node("IllustratedFighter")
		for move: Dictionary in Moves.moves_for(str(definition.id)):
			var impact := float(move.windup) + float(move.travel)
			actor.reset_pose()
			actor.play_move(move)
			actor._process(float(move.windup) * 0.7)
			_check(sprite.position.x <= 0.1, str(move.id) + " anticipation precedes extension")
			if move.type == "charge": _check(sprite.position.x < -8, "charge steps backward before rushing")
			var before: float = actor._action_time
			actor.motion_paused = true
			actor._process(0.5)
			_check(is_equal_approx(actor._action_time, before), "modal pause holds movement timeline")
			actor.motion_paused = false
			actor.play_move(move, float(move.windup) + float(move.travel) * 0.5)
			if move.type == "jump": _check(sprite.position.y < -15, "jump really leaves the floor")
			if move.type == "dash": _check(sprite.position.x > 8, "dash moves forward rapidly")
			actor.play_move(move, impact * 0.2)
			actor.play_hit(true)
			_check(actor._mode == "move", "incoming reaction cannot erase pending outgoing impact")
			actor.move_impact()
			_check(actor._action_time >= impact, "contact aligns to authoritative impact")
			actor._process(float(move.recovery) + 0.1)
			_check(actor._mode == "idle", "bounded recovery returns to idle")
			for facing: int in [1, -1]:
				actor.facing = facing
				actor.play_move(move, impact)
				_check(sprite.position.x * facing >= -8, "move mirrors toward opponent")
			actor.facing = 1
			actor.reduced_motion = true
			actor.play_move(move, impact * 0.6)
			_check(sprite.position == Vector2.ZERO and is_zero_approx(sprite.rotation), "reduced motion preserves poses without displacement")
			_check(not actor.get_node("AttackTrail").visible, "reduced motion removes trails")
			actor.reduced_motion = false
		_test_jump_clearance(actor, definition)
		actor.free()
	_test_counter_overlap()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): await _capture(arg.trim_prefix("--capture-dir="))
	print("MOVE PRESENTATION: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _test_jump_clearance(actor: Node2D, definition: Dictionary) -> void:
	for size: Vector2 in [Vector2(1360,880),Vector2(1224,792),Vector2(1920,1080),Vector2(768,1024),Vector2(390,844),Vector2(430,932),Vector2(844,390)]:
		var layout: Dictionary = Layout.calculate(size,true)
		actor.position = layout.player_at
		actor.scale = Vector2.ONE * float(layout.actor_scale)
		for move: Dictionary in Moves.moves_for(str(definition.id)):
			if move.type != "jump": continue
			actor.play_move(move,float(move.windup)+float(move.travel)*0.5)
			var sprite: Sprite2D = actor.get_node("IllustratedFighter")
			var bounds: Rect2 = actor.visible_sprite_bounds()
			_check(not bounds.intersects(layout.primary),"jump never covers main controls")
			_check(not bounds.intersects(layout.hud_player),"jump leaves the fighter HUD readable")

func _test_counter_overlap() -> void:
	var actor = Fighter.new()
	root.add_child(actor)
	actor.set_process(false)
	actor.setup_character(Catalog.definition("taro"))
	var own: Dictionary = Moves.moves_for("taro")[0]
	var reaction := {"id":"reaction_counter","is_counter_reaction":true,"animation_type":"dash","windup":0.05,"travel":0.08,"impact_delay":0.13,"recovery":0.15,"duration":0.28}
	actor.play_move(reaction)
	actor._process(0.013767)
	actor.play_move(own)
	actor._process(0.116233)
	var before: float = actor._action_time
	actor.move_impact(false,"reaction_counter")
	_check(is_equal_approx(before,actor._action_time),"counter starting before normal move cannot advance that move's impact clock")
	_check(str(actor._counter_move.get("id", "")) == "reaction_counter", "pending counter transfers to its independent overlay")
	actor.move_impact(false,"unknown")
	_check(is_equal_approx(before,actor._action_time),"unrelated move event cannot fast-forward an animation")
	actor.move_impact(false,str(own.id))
	_check(actor._action_time >= float(own.impact_delay),"normal impact still reaches its own clock")
	actor.free()

func _capture(directory: String) -> void:
	_check(DisplayServer.get_name() != "headless", "native renderer required for image")
	if DisplayServer.get_name() == "headless": return
	DirAccess.make_dir_recursive_absolute(directory)
	var canvas := SubViewport.new()
	canvas.size = Vector2i(1360, 1000)
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	var background := ColorRect.new()
	background.color = Color("0c2228")
	background.size = Vector2(1360, 1000)
	canvas.add_child(background)
	var rows := [["kiro", "charge", "CARGA"], ["nima", "dash", "DESPLAZAMIENTO"], ["neris", "jump", "SALTO"], ["mugo", "heavy", "GOLPE FUERTE"], ["taro", "counter", "CONTRAGUARDIA"], ["luma", "quick", "GOLPE RÁPIDO"]]
	for index in range(rows.size()):
		var row: Array = rows[index]
		var move: Dictionary = {}
		for candidate: Dictionary in Moves.moves_for(str(row[0])):
			if candidate.type == row[1]:
				move = candidate
				break
		if move.is_empty(): continue
		var label := Label.new()
		label.text = "%s · %s" % [row[2], move.name]
		label.position = Vector2(26, 15 + index * 160)
		label.add_theme_font_size_override("font_size", 18)
		label.modulate = Color("efb66f")
		canvas.add_child(label)
		var impact := float(move.windup) + float(move.travel)
		var moments := [float(move.windup) * 0.10, float(move.windup) * 0.75, float(move.windup) + float(move.travel) * 0.5, impact, impact + float(move.recovery) * 0.7]
		for frame in range(moments.size()):
			var actor = Fighter.new()
			canvas.add_child(actor)
			actor.setup_character(Catalog.definition(str(row[0])))
			actor.set_process(false)
			actor.scale = Vector2.ONE * 0.56
			actor.position = Vector2(180 + frame * 245, 144 + index * 160)
			actor.play_move(move, float(moments[frame]))
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	_check(canvas.get_texture().get_image().save_png(directory.path_join("movimientos.png")) == OK, "save illustrated contact sheet")
	canvas.queue_free()
