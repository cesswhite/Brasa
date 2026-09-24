extends Node2D
class_name FighterProcedural
## Original procedural fighters. The origin is the midpoint between their feet.
## Keep this node unscaled for a silhouette of approximately 130 × 150 pixels.

var archetype: int = 0
var palette_color: Color = Color("e99a58")
var facing: int = 1

var _clock: float = 0.0
var _action_time: float = 0.0
var _mode: String = "idle"
var _critical: bool = false
var _flash: float = 0.0
var _root_transform: Transform2D = Transform2D.IDENTITY
var _arm_extension: float = 0.0
var _arm_lift: float = 0.0
var _outline: Color = Color("263439")


func setup(kind: int, color: Color, look_direction: int = 1) -> void:
	archetype = clampi(kind, 0, 2)
	palette_color = color
	facing = 1 if look_direction >= 0 else -1
	reset_pose()


func play_attack(critical: bool = false) -> void:
	if _mode == "fall":
		return
	_mode = "attack"
	_action_time = 0.0
	_critical = critical


func play_hit(critical: bool = false) -> void:
	if _mode == "fall":
		return
	_mode = "hit"
	_action_time = 0.0
	_critical = critical


func play_dodge() -> void:
	if _mode == "fall":
		return
	_mode = "dodge"
	_action_time = 0.0


func celebrate() -> void:
	_mode = "victory"
	_action_time = 0.0


func fall() -> void:
	_mode = "fall"
	_action_time = 0.0


func reset_pose() -> void:
	_mode = "idle"
	_action_time = 0.0
	_flash = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	_clock += delta
	_action_time += delta
	if (_mode == "attack" and _action_time > 0.68) or (_mode == "hit" and _action_time > 0.4) or (_mode == "dodge" and _action_time > 0.5):
		_mode = "idle"
	queue_redraw()


func _ease(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _draw() -> void:
	# The ground shadow stays level even while the actor leans or falls.
	_root_transform = Transform2D.IDENTITY
	_ellipse(Vector2(0, -1), Vector2(44, 8), Color(0.04, 0.07, 0.08, 0.24), Color.TRANSPARENT)
	var bob := sin(_clock * 3.1) * 1.9
	var shift := Vector2(0, bob)
	var lean := sin(_clock * 1.55) * 0.014
	var squash := Vector2(1.0, 1.0)
	_arm_extension = 0.0
	_arm_lift = sin(_clock * 3.1 + 0.4) * 2.1
	_flash = 0.0
	match _mode:
		"attack":
			var reach: float
			if _action_time < 0.15:
				reach = -0.22 * _ease(_action_time / 0.15)
			elif _action_time < 0.27:
				reach = lerpf(-0.22, 1.0, _ease((_action_time - 0.15) / 0.12))
			else:
				reach = 1.0 - _ease((_action_time - 0.32) / 0.36)
			_arm_extension = reach * (58.0 if _critical else 47.0)
			_arm_lift = reach * -24.0
			shift.x += reach * 9.0
			lean += reach * 0.11
		"hit":
			var recoil := sin(clampf(_action_time / 0.4, 0.0, 1.0) * PI)
			shift.x -= recoil * (13.0 if _critical else 8.0)
			lean -= recoil * 0.18
			_flash = maxf(0.0, 1.0 - _action_time / 0.19) * 0.68
		"dodge":
			var duck := sin(clampf(_action_time / 0.5, 0.0, 1.0) * PI)
			squash = Vector2(1.0 + duck * 0.12, 1.0 - duck * 0.29)
			shift.x -= duck * 14.0
			lean -= duck * 0.22
		"victory":
			shift.y -= absf(sin(_action_time * 4.6)) * 9.0
			_arm_lift = -35.0 - sin(_action_time * 4.6) * 4.0
			lean = sin(_action_time * 4.6) * 0.035
		"fall":
			var fallen := _ease(_action_time / 0.56)
			lean = -1.43 * fallen
			shift = Vector2(-20.0 * fallen, -3.0 * fallen)
			_arm_lift = 12.0 * fallen
	_root_transform = Transform2D(lean * facing, Vector2(float(facing), 1.0) * squash, 0.0, Vector2(shift.x * facing, shift.y))
	_set_local()
	match archetype:
		0:
			_draw_lynx()
		1:
			_draw_axolotl()
		2:
			_draw_golem()
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _set_local(position: Vector2 = Vector2.ZERO, angle: float = 0.0, local_scale: Vector2 = Vector2.ONE) -> void:
	draw_set_transform_matrix(_root_transform * Transform2D(angle, local_scale, 0.0, position))


func _color(color: Color) -> Color:
	return color.lerp(Color(1.0, 0.98, 0.87, color.a), _flash)


func _shape(points: Array, fill: Color, border: Color = Color("263439"), width: float = 2.8) -> void:
	var poly := PackedVector2Array(points)
	draw_colored_polygon(poly, _color(fill))
	if border.a > 0.0:
		poly.append(poly[0])
		draw_polyline(poly, _color(border), width, true)


func _ellipse(center: Vector2, radius: Vector2, fill: Color, border: Color = Color("263439"), width: float = 2.8, angle: float = 0.0) -> void:
	var points: Array = []
	for i in range(32):
		var theta := float(i) / 32.0 * TAU
		points.append(center + Vector2(cos(theta) * radius.x, sin(theta) * radius.y).rotated(angle))
	_shape(points, fill, border, width)


func _line(points: Array, color: Color, width: float = 2.0) -> void:
	draw_polyline(PackedVector2Array(points), _color(color), width, true)


func _limb(points: Array, fill: Color, width: float) -> void:
	_line(points, _outline, width + 5.0)
	_line(points, fill, width)
	for point in [points[0], points[-1]]:
		draw_circle(point, (width + 5.0) / 2.0, _color(_outline))
		draw_circle(point, width / 2.0, _color(fill))


func _draw_lynx() -> void:
	var fur := palette_color
	var shadow := fur.darkened(0.18)
	var cream := Color("ffe0ac")
	var cloth := Color("354e56")
	# Curling tail, far leg and far glove.
	_line([Vector2(-21, -42), Vector2(-45, -42), Vector2(-55, -54), Vector2(-54, -65)], _outline, 15.0)
	_line([Vector2(-21, -42), Vector2(-45, -42), Vector2(-55, -54), Vector2(-54, -65)], shadow, 10.0)
	_line([Vector2(-55, -60), Vector2(-54, -66)], cloth, 11.0)
	_limb([Vector2(-13, -39), Vector2(-20, -17), Vector2(-23, -7)], cloth.darkened(0.12), 14.0)
	_ellipse(Vector2(-25, -7), Vector2(15, 7), shadow)
	_limb([Vector2(-18, -77), Vector2(-33, -63), Vector2(-24, -54 - _arm_lift * 0.15)], cloth.darkened(0.1), 13.0)
	_ellipse(Vector2(-24, -54 - _arm_lift * 0.15), Vector2(10, 11), shadow)
	# Compact travel jacket with an amber sash and little stitched hem.
	_shape([Vector2(-21, -89), Vector2(18, -87), Vector2(25, -43), Vector2(11, -33), Vector2(-19, -36), Vector2(-28, -46)], cloth)
	_shape([Vector2(-7, -84), Vector2(11, -81), Vector2(15, -41), Vector2(-7, -38)], cloth.lightened(0.10), Color.TRANSPARENT)
	_line([Vector2(-21, -45), Vector2(17, -43)], Color("edb361"), 7.0)
	_ellipse(Vector2(5, -45), Vector2(4, 5), Color("ffdc8c"), _outline, 1.8)
	_limb([Vector2(13, -37), Vector2(20, -18), Vector2(18, -7)], cloth, 15.0)
	_ellipse(Vector2(22, -7), Vector2(17, 7), fur)
	_line([Vector2(27, -10), Vector2(28, -5)], shadow, 1.4)
	_line([Vector2(33, -10), Vector2(34, -5)], shadow, 1.4)
	# Scarf trails on the silhouette, with a contrasting knot under the face.
	_shape([Vector2(-10, -91), Vector2(-26, -96), Vector2(-45, -83), Vector2(-29, -82), Vector2(-24, -73)], Color("df6552"))
	_shape([Vector2(-23, -91), Vector2(22, -94), Vector2(24, -83), Vector2(-19, -80)], Color("f18660"))
	_line([Vector2(-19, -88), Vector2(17, -88)], Color("ffc58a"), 2.0)
	# Tall tufts and cheek ruffs make the species readable at small scale.
	_shape([Vector2(-24, -116), Vector2(-30, -145), Vector2(-13, -132), Vector2(-5, -127), Vector2(15, -133), Vector2(27, -145), Vector2(29, -118), Vector2(35, -103), Vector2(22, -104), Vector2(22, -92), Vector2(6, -87), Vector2(-14, -90), Vector2(-25, -102), Vector2(-33, -104)], fur)
	_shape([Vector2(-24, -138), Vector2(-21, -121), Vector2(-11, -128)], Color("c66863"), Color.TRANSPARENT)
	_shape([Vector2(24, -138), Vector2(14, -128), Vector2(24, -121)], Color("c66863"), Color.TRANSPARENT)
	_shape([Vector2(-28, -145), Vector2(-28, -153), Vector2(-23, -143)], cloth, Color.TRANSPARENT)
	_shape([Vector2(25, -143), Vector2(29, -152), Vector2(29, -139)], cloth, Color.TRANSPARENT)
	_shape([Vector2(-23, -109), Vector2(-13, -99), Vector2(-2, -97), Vector2(8, -105), Vector2(26, -108), Vector2(25, -96), Vector2(7, -89), Vector2(-13, -94)], cream, Color.TRANSPARENT)
	# Forehead stripes and nose.
	_shape([Vector2(-6, -127), Vector2(0, -125), Vector2(-2, -115)], shadow, Color.TRANSPARENT)
	_shape([Vector2(3, -127), Vector2(10, -126), Vector2(5, -116)], shadow, Color.TRANSPARENT)
	_draw_eyes(Vector2(-6, -111), Vector2(15, -111), Color("f5cf6c"))
	_shape([Vector2(8, -102), Vector2(17, -103), Vector2(13, -97)], _outline, Color.TRANSPARENT)
	_line([Vector2(13, -97), Vector2(13, -94), Vector2(19, -95)], _outline, 1.5)
	_line([Vector2(-18, -103), Vector2(-10, -101)], shadow, 1.5)
	_line([Vector2(-19, -99), Vector2(-11, -98)], shadow, 1.5)
	_draw_front_arm(cloth, fur, Color("f8d299"), 0)


func _draw_axolotl() -> void:
	var skin := palette_color.lerp(Color("92d7cd"), 0.34)
	var gill := Color("ed908c")
	var coat := Color("3b6164")
	var cream := Color("e5e6c4")
	# A soft fin tail and six distinct external gills.
	_shape([Vector2(-17, -38), Vector2(-46, -34), Vector2(-60, -47), Vector2(-49, -61), Vector2(-40, -49), Vector2(-17, -53)], skin.darkened(0.18))
	_shape([Vector2(-42, -38), Vector2(-55, -47), Vector2(-49, -55), Vector2(-43, -47)], skin.lightened(0.20), Color.TRANSPARENT)
	_limb([Vector2(-13, -35), Vector2(-16, -10)], coat.darkened(0.15), 15.0)
	_ellipse(Vector2(-19, -7), Vector2(15, 7), skin.darkened(0.16))
	_limb([Vector2(-24, -79), Vector2(-37, -62), Vector2(-29, -52 - _arm_lift * 0.15)], coat.darkened(0.1), 15.0)
	_ellipse(Vector2(-29, -52 - _arm_lift * 0.15), Vector2(10, 10), skin.darkened(0.12))
	# Flared guardian coat and two strong contrasting lapels.
	_shape([Vector2(-21, -92), Vector2(21, -91), Vector2(26, -67), Vector2(34, -32), Vector2(8, -29), Vector2(0, -37), Vector2(-8, -29), Vector2(-33, -33), Vector2(-28, -67)], coat)
	_shape([Vector2(-19, -89), Vector2(-5, -86), Vector2(0, -65), Vector2(-15, -76)], cream)
	_shape([Vector2(17, -90), Vector2(5, -86), Vector2(0, -65), Vector2(17, -77)], cream)
	_line([Vector2(0, -64), Vector2(0, -39)], coat.darkened(0.3), 2.0)
	for y in [-60, -50, -40]:
		_ellipse(Vector2(7, y), Vector2(2.7, 2.7), Color("e9bd69"), Color.TRANSPARENT)
	_line([Vector2(-25, -38), Vector2(-10, -35)], Color("66918e"), 2.0)
	_line([Vector2(12, -35), Vector2(26, -37)], Color("66918e"), 2.0)
	_limb([Vector2(17, -32), Vector2(19, -9)], coat, 15.0)
	_ellipse(Vector2(24, -7), Vector2(17, 7), skin)
	for side in [-1.0, 1.0]:
		for i in range(3):
			var start := Vector2(side * 23.0, -110.0 + i * 7.0)
			var end := Vector2(side * (46.0 - absf(float(i - 1)) * 4.0), -131.0 + i * 17.0)
			_limb([start, end], gill.darkened(0.16) if side < 0 else gill, 6.0)
			_line([end + Vector2(side * 2.0, 1.0), end + Vector2(side * 5.0, -3.0)], gill.lightened(0.3), 2.6)
	_ellipse(Vector2(1, -110), Vector2(31, 25), skin)
	_ellipse(Vector2(-9, -121), Vector2(16, 8), skin.lightened(0.15), Color.TRANSPARENT, 0.0, -0.12)
	_ellipse(Vector2(9, -96), Vector2(18, 7), skin.lightened(0.24), Color.TRANSPARENT)
	_draw_eyes(Vector2(-9, -111), Vector2(15, -111), Color("ffe4a1"))
	_ellipse(Vector2(-20, -102), Vector2(5, 3), gill, Color.TRANSPARENT)
	_ellipse(Vector2(25, -102), Vector2(4, 3), gill, Color.TRANSPARENT)
	if _mode != "fall":
		_line([Vector2(2, -99), Vector2(8, -97), Vector2(14, -99)], _outline, 1.7)
	else:
		_line([Vector2(3, -99), Vector2(13, -99)], _outline, 1.7)
	# Woven headband with one tiny guardian emblem.
	_shape([Vector2(-28, -123), Vector2(25, -126), Vector2(29, -119), Vector2(-28, -116)], Color("eac279"))
	_shape([Vector2(1, -126), Vector2(6, -130), Vector2(11, -126), Vector2(6, -120)], Color("fff0b0"), _outline, 1.6)
	_draw_front_arm(coat, skin, Color("dee9c5"), 1)


func _draw_golem() -> void:
	var stone := palette_color.lerp(Color("9baba4"), 0.42)
	var shade := stone.darkened(0.23)
	var highlight := stone.lightened(0.20)
	var crystal := Color("91e6d2")
	var glove := Color("be7953")
	# Broad feet anchor the squat angular silhouette.
	_shape([Vector2(-26, -32), Vector2(-8, -30), Vector2(-7, -8), Vector2(-13, -3), Vector2(-36, -4), Vector2(-37, -15)], shade)
	_shape([Vector2(8, -30), Vector2(27, -32), Vector2(35, -16), Vector2(41, -12), Vector2(40, -4), Vector2(12, -3), Vector2(6, -9)], stone)
	_shape([Vector2(15, -23), Vector2(25, -25), Vector2(32, -15), Vector2(14, -13)], highlight, Color.TRANSPARENT)
	_limb([Vector2(-26, -77), Vector2(-41, -61), Vector2(-33, -50 - _arm_lift * 0.15)], shade, 15.0)
	_ellipse(Vector2(-34, -49 - _arm_lift * 0.15), Vector2(13, 12), glove.darkened(0.17))
	# Layered stone plates, moss and a glowing heart crystal.
	_shape([Vector2(-22, -96), Vector2(19, -96), Vector2(34, -77), Vector2(31, -43), Vector2(15, -29), Vector2(-14, -30), Vector2(-34, -45), Vector2(-35, -77)], stone)
	_shape([Vector2(-33, -77), Vector2(-19, -85), Vector2(-20, -48), Vector2(-11, -31), Vector2(-29, -39), Vector2(-35, -57)], shade, Color.TRANSPARENT)
	_shape([Vector2(-16, -88), Vector2(16, -90), Vector2(28, -77), Vector2(12, -75), Vector2(-17, -77)], highlight, Color.TRANSPARENT)
	_line([Vector2(-28, -55), Vector2(-15, -59), Vector2(-8, -51)], shade, 2.0)
	_line([Vector2(19, -39), Vector2(18, -47), Vector2(27, -53)], shade, 2.0)
	_shape([Vector2(-7, -75), Vector2(4, -81), Vector2(16, -73), Vector2(13, -56), Vector2(3, -48), Vector2(-8, -59)], _outline, Color.TRANSPARENT)
	_shape([Vector2(-3, -72), Vector2(4, -76), Vector2(12, -71), Vector2(9, -59), Vector2(3, -53), Vector2(-4, -60)], crystal, Color.TRANSPARENT)
	_shape([Vector2(4, -76), Vector2(4, -56), Vector2(-4, -60), Vector2(-3, -72)], Color("d7fff0"), Color.TRANSPARENT)
	_shape([Vector2(-19, -92), Vector2(-6, -99), Vector2(0, -90), Vector2(-6, -84), Vector2(-13, -88)], Color("6d9773"), Color.TRANSPARENT)
	# Asymmetric rock head with a small mint crystal crest.
	_shape([Vector2(-30, -124), Vector2(-18, -138), Vector2(14, -139), Vector2(29, -127), Vector2(32, -106), Vector2(20, -93), Vector2(-17, -93), Vector2(-32, -107)], stone)
	_shape([Vector2(-28, -121), Vector2(-16, -133), Vector2(12, -134), Vector2(22, -127), Vector2(-10, -122)], highlight, Color.TRANSPARENT)
	_shape([Vector2(-30, -118), Vector2(-21, -111), Vector2(-19, -98), Vector2(-29, -107)], shade, Color.TRANSPARENT)
	_shape([Vector2(-8, -137), Vector2(-6, -149), Vector2(3, -154), Vector2(11, -146), Vector2(10, -138)], crystal)
	_shape([Vector2(3, -152), Vector2(3, -139), Vector2(-5, -139), Vector2(-5, -147)], Color("d7fff0"), Color.TRANSPARENT)
	_line([Vector2(18, -135), Vector2(14, -126), Vector2(18, -120)], shade, 2.0)
	_draw_eyes(Vector2(-9, -111), Vector2(15, -111), crystal)
	_line([Vector2(-1, -101), Vector2(8, -99), Vector2(17, -102)], _outline, 2.2)
	_draw_front_arm(stone, glove, Color("dcad73"), 2)


func _draw_front_arm(sleeve: Color, hand: Color, cuff: Color, kind: int) -> void:
	var shoulder := Vector2(23, -76)
	var fist := Vector2(36 + _arm_extension, -57 + _arm_lift)
	var elbow := shoulder.lerp(fist, 0.52) + Vector2(-3, 10 if _arm_extension < 20 else 2)
	_limb([shoulder, elbow, fist - Vector2(3, -1)], sleeve, 15.0 if kind != 2 else 18.0)
	var cuff_start := fist.lerp(elbow, 0.16)
	_ellipse(cuff_start, Vector2(10, 10), cuff, _outline, 2.0)
	_ellipse(fist + Vector2(3, -1), Vector2(12.0 if kind != 2 else 15.0, 11.0 if kind != 2 else 13.0), hand)
	_ellipse(fist + Vector2(5, -6), Vector2(7, 3), hand.lightened(0.17), Color.TRANSPARENT)
	_line([fist + Vector2(8, -4), fist + Vector2(8, 1)], hand.darkened(0.25), 1.5)
	_line([fist + Vector2(3, -4), fist + Vector2(3, 0)], hand.darkened(0.25), 1.5)
	if kind == 2:
		_line([fist + Vector2(-4, 6), fist + Vector2(6, 7)], Color("e7bf83"), 2.0)
	if _mode == "attack" and _action_time > 0.19 and _action_time < 0.37:
		var fade := 1.0 - absf(_action_time - 0.27) / 0.1
		var streak_color := Color(1.0, 0.86, 0.59, clampf(fade, 0.0, 1.0) * 0.8)
		_line([fist + Vector2(-24, -19), fist + Vector2(8, -17)], streak_color, 2.6)
		_line([fist + Vector2(-17, 17), fist + Vector2(11, 14)], streak_color, 2.0)


func _draw_eyes(left: Vector2, right: Vector2, iris: Color) -> void:
	var is_blinking := fmod(_clock + archetype * 0.8, 4.1) > 3.95
	if _mode == "fall":
		for eye in [left, right]:
			_line([eye + Vector2(-4, -3), eye + Vector2(4, 3)], _outline, 2.5)
			_line([eye + Vector2(-4, 3), eye + Vector2(4, -3)], _outline, 2.5)
	elif is_blinking or _mode == "hit":
		for eye in [left, right]:
			_line([eye + Vector2(-4, 0), eye + Vector2(4, -1)], _outline, 2.8)
	else:
		for eye in [left, right]:
			_ellipse(eye, Vector2(6.1, 7.0), Color("fff0d7"), _outline, 2.1)
			_ellipse(eye + Vector2(1.6, 0.5), Vector2(3.4, 4.7), iris, Color.TRANSPARENT)
			_ellipse(eye + Vector2(2.2, 0.6), Vector2(2.1, 3.8), _outline, Color.TRANSPARENT)
			_ellipse(eye + Vector2(1.1, -1.6), Vector2(1.1, 1.3), Color.WHITE, Color.TRANSPARENT)
		if _mode == "attack":
			_line([left + Vector2(-6, -10), left + Vector2(5, -7)], _outline, 2.6)
			_line([right + Vector2(-4, -7), right + Vector2(6, -10)], _outline, 2.6)
