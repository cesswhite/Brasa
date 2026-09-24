extends SceneTree
## Godot --headless --path . --script res://tests/test_sprites.gd
## During art creation add: -- --only=lince

const Fighter = preload("res://scripts/fighter_view.gd")
const SPECIES: Array[String] = ["lince", "ajolote", "golem"]
var _checks: int = 0
var _failures: int = 0


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("SPRITE FAIL: " + description)


func _run() -> void:
	var selected: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			selected = argument.trim_prefix("--only=")
	for kind in range(3):
		if not selected.is_empty() and SPECIES[kind] != selected:
			continue
		_test_fighter(kind)
	print("SPRITE TESTS: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_fighter(kind: int) -> void:
	var name: String = SPECIES[kind]
	var actor = Fighter.new()
	root.add_child(actor)
	actor.set_process(false)
	actor.setup(kind, Color.WHITE, 1)
	var geometry: Dictionary = actor.get_sprite_geometry()
	_check(not geometry.is_empty(), name + ": illustrated atlas loaded instead of fallback")
	if geometry.is_empty():
		actor.free()
		return
	var sprite: Sprite2D = actor.get_node("IllustratedFighter")
	var frame_data: Array = geometry["frames"]
	_check(frame_data.size() == 8, name + ": all eight poses exist")
	var base_scale: float = geometry["scale"]
	_check(is_equal_approx(base_scale,1.0/Fighter.VisualProfiles.PIXELS_PER_WORLD_UNIT) if geometry.normalized else is_equal_approx(frame_data[0]["bounds"].size.y*base_scale,166.0), name+": one canonical density or compatible legacy idle scale")
	for index in range(8):
		var frame: Dictionary = frame_data[index]
		var region: Rect2i = frame["region"]
		var bounds: Rect2i = frame["bounds"]
		var anchor: Vector2 = frame["anchor"]
		_check(frame["name"] == Fighter.POSE_NAMES[index], name + ": pose order matches action contract")
		_check(bounds.size.x > 0 and bounds.size.y > 0, name + ": pose contains visible pixels")
		_check(bounds.position.x > 0 and bounds.position.y > 0 and bounds.end.x < region.size.x and bounds.end.y < region.size.y, name + ": " + frame["name"] + " has margin on all sides")
		_check(anchor.is_equal_approx(Fighter.VisualProfiles.PIVOT) if geometry.normalized else is_equal_approx(anchor.y,bounds.end.y), name+": "+frame["name"]+" uses its declared ground origin")
		_check(anchor.is_equal_approx(Fighter.VisualProfiles.PIVOT) if geometry.normalized else anchor.x>=bounds.position.x and anchor.x<=bounds.end.x, name+": pivot stays stable through pose changes")
		actor._set_pose_frame(index)
		_check(sprite.texture is AtlasTexture and sprite.texture.region == (Rect2(region) if geometry.normalized else Rect2(region.position+bounds.position,bounds.size)), name + ": atlas texture binds the intended pixels")
		_check(is_equal_approx(sprite.scale.x, base_scale) and is_equal_approx(sprite.scale.y, base_scale), name + ": pose preserves scale and aspect ratio")
	_check(frame_data[7]["bounds"].size.y < frame_data[0]["bounds"].size.y, name + ": fallen illustration is shorter than standing")
	actor.reset_pose()
	actor.play_attack(true)
	_check(actor.get_sprite_geometry()["active_frame"] == 2, name + ": attack starts with anticipation")
	actor._process(0.16)
	_check(actor.get_sprite_geometry()["active_frame"] == 3, name + ": punch follows anticipation")
	actor._process(0.22)
	_check(actor.get_sprite_geometry()["active_frame"] == 2, name + ": attack recoils")
	actor._process(0.20)
	_check(actor.get_sprite_geometry()["active_frame"] in [0, 1], name + ": attack returns to idle")
	actor.play_hit(true)
	_check(actor.get_sprite_geometry()["active_frame"] == 4, name + ": hit uses pose four")
	_check(float(sprite.material.get_shader_parameter("flash_amount")) > 0.0, name + ": hit flashes illustration")
	actor._process(0.41)
	_check(actor.get_sprite_geometry()["active_frame"] in [0, 1], name + ": hit reaction ends")
	_check(is_zero_approx(float(sprite.material.get_shader_parameter("flash_amount"))), name + ": flash resets")
	# Regression: an incoming impact between windup and contact must not erase
	# an outgoing attack whose damage has already been scheduled by main.
	actor.reset_pose()
	actor.play_attack()
	actor._process(0.10)
	actor.play_hit(true)
	_check(actor.get_sprite_geometry()["active_frame"] == 2, name + ": incoming hit preserves outgoing windup")
	_check(float(sprite.material.get_shader_parameter("flash_amount")) > 0.0, name + ": incoming hit flashes immediately during windup")
	actor._process(0.08)
	_check(actor.get_sprite_geometry()["active_frame"] == 3, name + ": interrupted windup still reaches punch before contact")
	_check(float(sprite.material.get_shader_parameter("flash_amount")) > 0.0, name + ": impact flash overlays outgoing punch")
	actor._process(0.14)
	_check(actor.get_sprite_geometry()["active_frame"] == 3, name + ": outgoing punch remains through its contact window")
	actor._process(0.05)
	_check(actor.get_sprite_geometry()["active_frame"] == 4, name + ": queued hit pose starts after full punch")
	_check(is_zero_approx(float(sprite.material.get_shader_parameter("flash_amount"))), name + ": queued pose does not flash a second time")
	actor._process(0.40)
	_check(actor.get_sprite_geometry()["active_frame"] in [0, 1], name + ": queued hit recovers")
	actor.play_attack()
	actor._process(0.10)
	actor.play_dodge()
	actor._process(0.08)
	_check(actor.get_sprite_geometry()["active_frame"] == 3, name + ": incoming dodge preserves outgoing punch")
	actor._process(0.19)
	_check(actor.get_sprite_geometry()["active_frame"] == 5, name + ": queued dodge follows full punch")
	actor._process(0.51)
	_check(actor.get_sprite_geometry()["active_frame"] in [0, 1], name + ": queued dodge recovers")
	actor.play_dodge()
	_check(actor.get_sprite_geometry()["active_frame"] == 5, name + ": dodge uses crouch")
	actor._process(0.51)
	_check(actor.get_sprite_geometry()["active_frame"] in [0, 1], name + ": dodge recovers")
	actor.preview_victory()
	actor._process(1.0)
	_check(actor.get_sprite_geometry()["active_frame"] == 6 and sprite.position.y < 0.0, name + ": victory bounces")
	actor.fall()
	actor.play_attack()
	actor.play_dodge()
	actor.play_hit()
	actor._process(2.0)
	_check(actor.get_sprite_geometry()["active_frame"] == 7, name + ": defeated fighter cannot act")
	_check(is_equal_approx(sprite.scale.y, base_scale), name + ": defeat never enlarges the character")
	actor.setup(kind, Color.WHITE, -1)
	_check(sprite.scale.x < 0.0 and is_equal_approx(absf(sprite.scale.x), sprite.scale.y), name + ": rival mirrors without distortion")
	_check(actor.get_sprite_geometry()["active_frame"] in [0, 1], name + ": setup resets defeat")
	print("  %s: source %s, scale %.4f, idle %s, defeat %s" % [name, geometry["source_size"], base_scale, frame_data[0]["bounds"], frame_data[7]["bounds"]])
	actor.free()
