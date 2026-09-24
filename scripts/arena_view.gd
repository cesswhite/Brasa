extends Node2D
class_name ArenaView

## Illustrated scenery with procedural light, dust and combat effects.
## The original procedural scenery remains available as a resource fallback.
## Only scenery uses a cover transform. Actors and combat effects stay in
## viewport coordinates; this Node2D and its children are never scaled here.
var combat_active: bool = false
var winner_side: String = ""
var reduced_motion: bool = false

var _clock: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _stars: Array[Vector3] = []
var _sand: Array[Vector3] = []
var _sparks: Array[Dictionary] = []
var _painted_background: Texture2D
var _background_path: String = "res://assets/arena-faroles-v2.png"
var _viewport_size: Vector2 = Vector2(1360.0, 880.0)
var _size_was_set: bool = false
var _backdrop_rect: Rect2 = Rect2()
var _active_side: String = ""
var _player_at: Vector2 = Vector2.ZERO
var _rival_at: Vector2 = Vector2.ZERO
var _actor_scale: float = 1.0
var _player_focus: float = 0.0
var _rival_focus: float = 0.0

const DESIGN_SIZE: Vector2 = Vector2(1264.0, 414.0)
const DEFAULT_BACKGROUND: String = "res://assets/arena-faroles-v2.png"
const ParticleInk = preload("res://scripts/particle_ink.gd")

const SKY_TOP: Color = Color("101d2c")
const SKY_BOTTOM: Color = Color("24494d")
const GOLD: Color = Color("e8ba72")
const INK: Color = Color("122d36")


func _ready() -> void:
	set_background(_background_path)
	if not _size_was_set:
		_viewport_size = get_viewport_rect().size.max(Vector2.ONE)
	_update_backdrop_rect()
	_rng.seed = 47281
	for i in range(39):
		_stars.append(Vector3(_rng.randf_range(22.0, 1242.0), _rng.randf_range(18.0, 175.0), _rng.randf_range(0.6, 1.5)))
	for i in range(130):
		var angle: float = _rng.randf_range(0.0, TAU)
		var radius: float = sqrt(_rng.randf())
		_sand.append(Vector3(632.0 + cos(angle) * radius * 460.0, 345.0 + sin(angle) * radius * 67.0, _rng.randf_range(0.6, 1.7)))
	_rng.randomize()
	queue_redraw()


func set_background(path: String) -> void:
	var selected := path if path.begins_with("res://assets/") and path.ends_with(".png") and not path.contains("..") and ResourceLoader.exists(path) else DEFAULT_BACKGROUND
	if selected == _background_path and _painted_background != null:
		return
	_background_path = selected
	_painted_background = load(selected) as Texture2D if ResourceLoader.exists(selected) else null
	_update_backdrop_rect()
	queue_redraw()


func get_background_path() -> String:
	return _background_path


func set_viewport_size(view_size: Vector2) -> void:
	if not is_finite(view_size.x) or not is_finite(view_size.y):
		return
	_size_was_set = true
	var safe_size: Vector2 = view_size.max(Vector2.ONE)
	if safe_size.is_equal_approx(_viewport_size) and _backdrop_rect.has_area():
		return
	_viewport_size = safe_size
	_update_backdrop_rect()
	queue_redraw()


func get_backdrop_rect() -> Rect2:
	# Useful to verify cover cropping and align an effect with painted scenery.
	return _backdrop_rect


func get_floor_y() -> float:
	var control_space: float = 126.0 if _viewport_size.y <= 520.0 else 220.0
	return clampf(_viewport_size.y - control_space, _viewport_size.y * 0.64, _viewport_size.y * 0.80)


func set_active_fighter(side: String, player_at: Vector2, rival_at: Vector2, actor_scale: float = 1.0) -> void:
	_active_side = side if side in ["player", "rival"] else ""
	_player_at = player_at
	_rival_at = rival_at
	_actor_scale = clampf(actor_scale, 0.35, 2.5)
	queue_redraw()


func _update_backdrop_rect() -> void:
	var source_size: Vector2 = _painted_background.get_size() if _painted_background != null else DESIGN_SIZE
	var cover_scale: float = maxf(_viewport_size.x / source_size.x, _viewport_size.y / source_size.y)
	var drawn_size: Vector2 = source_size * cover_scale
	_backdrop_rect = Rect2((_viewport_size - drawn_size) * 0.5, drawn_size)


func _painted_point(point: Vector2) -> Vector2:
	return _backdrop_rect.position + point / DESIGN_SIZE * _backdrop_rect.size


func _process(delta: float) -> void:
	if reduced_motion:
		var player_amount := 1.0 if combat_active and _active_side == "player" else 0.0
		var rival_amount := 1.0 if combat_active and _active_side == "rival" else 0.0
		var changed := not _sparks.is_empty() or not is_equal_approx(_player_focus, player_amount) or not is_equal_approx(_rival_focus, rival_amount)
		_sparks.clear()
		_player_focus = player_amount
		_rival_focus = rival_amount
		if changed: queue_redraw()
		return
	_clock += delta
	var blend: float = 1.0 - exp(-delta * 12.0)
	_player_focus = lerpf(_player_focus, 1.0 if combat_active and _active_side == "player" else 0.0, blend)
	_rival_focus = lerpf(_rival_focus, 1.0 if combat_active and _active_side == "rival" else 0.0, blend)
	for i in range(_sparks.size() - 1, -1, -1):
		var spark: Dictionary = _sparks[i]
		spark["life"] = float(spark["life"]) - delta
		if float(spark["life"]) <= 0.0:
			_sparks.remove_at(i)
			continue
		spark["pos"] = Vector2(spark["pos"]) + Vector2(spark["vel"]) * delta
		spark["vel"] = Vector2(spark["vel"]) + Vector2(0.0, 150.0) * delta
	queue_redraw()


func pulse_impact(at: Vector2, critical: bool = false) -> void:
	if reduced_motion:
		return
	var count: int = 15 if critical else 8
	for i in range(count):
		var angle: float = _rng.randf_range(-PI, 0.4)
		var speed: float = _rng.randf_range(45.0, 145.0) * (1.25 if critical else 1.0)
		var life: float = _rng.randf_range(0.18, 0.44)
		_sparks.append({"pos": at, "vel": Vector2.from_angle(angle) * speed, "life": life, "max_life": life, "critical": critical})


func _poly(points: Array, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)


func _ellipse(center: Vector2, radius: Vector2, color: Color, count: int = 64) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(count):
		var angle: float = TAU * float(i) / float(count)
		var point: Vector2 = center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y)
		point.y = clampf(point.y, 0.0, 414.0)
		points.append(point)
	draw_colored_polygon(points, color)


func _arch(rect: Rect2, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	points.append(Vector2(rect.position.x, rect.end.y))
	var arc_center: Vector2 = rect.position + Vector2(rect.size.x * 0.5, rect.size.x * 0.5)
	for i in range(19):
		var angle: float = PI + PI * float(i) / 18.0
		points.append(arc_center + Vector2(cos(angle), sin(angle)) * rect.size.x * 0.5)
	points.append(rect.end)
	draw_colored_polygon(points, color)


func _glow(at: Vector2, radius: float, color: Color, strength: float = 1.0) -> void:
	for i in range(5, 0, -1):
		var glow_color: Color = color
		glow_color.a = (0.013 + float(5 - i) * 0.009) * strength
		draw_circle(at, radius * float(i) / 5.0, glow_color)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, _viewport_size), SKY_TOP)
	if _painted_background != null:
		draw_texture_rect(_painted_background, _backdrop_rect, false)
		_draw_painted_lights()
	else:
		# Transform drawing commands only: child fighters retain their coordinates.
		var cover_scale: float = _backdrop_rect.size.x / DESIGN_SIZE.x
		draw_set_transform(_backdrop_rect.position, 0.0, Vector2.ONE * cover_scale)
		_draw_sky()
		_draw_city()
		_draw_gallery()
		_draw_ring()
		_draw_festival()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_motes()
	_draw_turn_focus(_player_at, _player_focus, Color("ecc382"))
	_draw_turn_focus(_rival_at, _rival_focus, Color("edb28e"))
	_draw_impacts()


func _draw_painted_lights() -> void:
	if _background_path != DEFAULT_BACKGROUND:
		return
	# Halos share exactly the image's crop and aspect-preserving cover transform.
	var lamps: Array[Vector2] = [Vector2(70, 131), Vector2(165, 157), Vector2(54, 230), Vector2(172, 259), Vector2(1019, 253), Vector2(1173, 150), Vector2(1243, 143)]
	var scenery_scale: float = _backdrop_rect.size.y / DESIGN_SIZE.y
	for i in range(lamps.size()):
		var position: Vector2 = _painted_point(lamps[i])
		var radius: float = (28.0 if i % 2 == 0 else 21.0) * scenery_scale
		if not Rect2(Vector2.ZERO, _viewport_size).grow(radius).has_point(position):
			continue
		var warmth: float = 0.6 + 0.24 * sin(_clock * 1.7 + float(i) * 1.9)
		_glow(position, radius, GOLD, warmth)


func _draw_turn_focus(at: Vector2, amount: float, color: Color) -> void:
	if amount < 0.01:
		return
	var pulse: float = 1.0 if reduced_motion else 0.90 + 0.10 * sin(_clock * 2.4)
	# Uneven overlapping patches fade into the floor without an enclosing edge.
	var glow_color := Color(color, amount * pulse * 0.17)
	ParticleInk.mote(self, at + Vector2(-12.0, 1.0) * _actor_scale, Vector2(34.0, 6.0) * _actor_scale, glow_color, -0.035)
	glow_color.a *= 0.70
	ParticleInk.mote(self, at + Vector2(16.0, -1.0) * _actor_scale, Vector2(29.0, 4.5) * _actor_scale, glow_color, 0.06)
	# A small lozenge adds a shape cue, so the active fighter is not color-only.
	var marker: Vector2 = at + Vector2(0.0, 12.0 * _actor_scale)
	var marker_size: Vector2 = Vector2(3.2, 2.0) * _actor_scale
	var marker_color := Color(color, amount * 0.75)
	_poly([marker + Vector2(0, -marker_size.y), marker + Vector2(marker_size.x, 0), marker + Vector2(0, marker_size.y), marker - Vector2(marker_size.x, 0)], marker_color)


func _draw_sky() -> void:
	for i in range(24):
		var ratio: float = float(i) / 23.0
		draw_rect(Rect2(0, i * 12, 1264, 13), SKY_TOP.lerp(SKY_BOTTOM, ratio))
	for star in _stars:
		var alpha: float = 0.25 + 0.16 * sin(_clock * 0.5 + star.x)
		draw_circle(Vector2(star.x, star.y), star.z, Color(0.82, 0.87, 0.77, alpha))
	_glow(Vector2(916, 76), 90, Color("e7ddb2"), 0.6)
	draw_circle(Vector2(916, 76), 25, Color("d3ceb0"))
	draw_circle(Vector2(925, 69), 25, SKY_TOP.lerp(SKY_BOTTOM, 0.24))
	_poly([Vector2(0, 244), Vector2(0, 190), Vector2(117, 151), Vector2(181, 174), Vector2(299, 121), Vector2(375, 165), Vector2(421, 151), Vector2(573, 218), Vector2(657, 177), Vector2(720, 192), Vector2(836, 133), Vector2(941, 169), Vector2(1007, 144), Vector2(1150, 193), Vector2(1264, 150), Vector2(1264, 278)], Color("24434c"))
	_poly([Vector2(0, 254), Vector2(0, 219), Vector2(120, 192), Vector2(218, 226), Vector2(367, 187), Vector2(461, 215), Vector2(548, 204), Vector2(698, 244), Vector2(838, 201), Vector2(977, 211), Vector2(1089, 181), Vector2(1264, 217), Vector2(1264, 284)], Color("294d51"))
	# Thin atmospheric bands keep the distant city quiet behind the actors.
	draw_rect(Rect2(0, 246, 1264, 54), Color("315559"))


func _draw_city() -> void:
	# Left: a stepped adobe observatory and its wind tower.
	_poly([Vector2(0, 120), Vector2(48, 120), Vector2(48, 140), Vector2(113, 140), Vector2(113, 278), Vector2(0, 290)], Color("25464d"))
	draw_rect(Rect2(0, 121, 46, 4), Color("3b6265"))
	draw_rect(Rect2(50, 143, 59, 4), Color("3b6265"))
	draw_rect(Rect2(81, 172, 63, 112), Color("2c5055"))
	draw_rect(Rect2(91, 168, 47, 7), Color("47696a"))
	_arch(Rect2(107, 190, 18, 43), Color("142e37"))
	_arch(Rect2(111, 196, 10, 31), Color("957c55"))
	draw_rect(Rect2(115, 197, 2, 31), Color("25434a"))
	_poly([Vector2(145, 274), Vector2(149, 124), Vector2(163, 117), Vector2(164, 92), Vector2(185, 83), Vector2(208, 92), Vector2(208, 117), Vector2(224, 124), Vector2(230, 274)], Color("365a5e"))
	_poly([Vector2(190, 95), Vector2(209, 93), Vector2(209, 117), Vector2(224, 124), Vector2(230, 274), Vector2(191, 274)], Color("29474e"))
	draw_line(Vector2(154, 125), Vector2(218, 125), Color("66827a"), 3)
	draw_line(Vector2(154, 133), Vector2(220, 133), Color("244149"), 2)
	for x in [167, 182, 197]:
		_arch(Rect2(x, 96, 9, 17), Color("18323b"))
	_arch(Rect2(169, 148, 28, 51), Color("163039"))
	_arch(Rect2(175, 154, 16, 39), Color("b28d57"))
	draw_rect(Rect2(181, 155, 3, 39), Color("28464c"))
	draw_rect(Rect2(175, 172, 16, 2), Color("28464c"))
	_glow(Vector2(183, 176), 48, GOLD, 0.5)
	draw_line(Vector2(187, 86), Vector2(187, 67), Color("6e8277"), 2)
	draw_circle(Vector2(187, 65), 3, GOLD)
	# Right: an offset roofline and a tall gateway.
	_poly([Vector2(1017, 291), Vector2(1022, 150), Vector2(1038, 143), Vector2(1038, 130), Vector2(1099, 130), Vector2(1099, 147), Vector2(1118, 156), Vector2(1124, 290)], Color("35565b"))
	draw_rect(Rect2(1033, 133, 72, 5), Color("557772"))
	for x in [1040, 1062, 1084]:
		draw_rect(Rect2(x, 122, 11, 14), Color("35565b"))
	_arch(Rect2(1043, 160, 31, 62), Color("18343d"))
	_arch(Rect2(1050, 168, 17, 45), Color("927c56"))
	draw_rect(Rect2(1057, 169, 3, 45), Color("2a464c"))
	_poly([Vector2(1115, 283), Vector2(1115, 185), Vector2(1150, 185), Vector2(1150, 164), Vector2(1207, 164), Vector2(1207, 116), Vector2(1245, 116), Vector2(1245, 143), Vector2(1264, 143), Vector2(1264, 302)], Color("24434c"))
	draw_rect(Rect2(1150, 164, 56, 5), Color("3a5a60"))
	draw_rect(Rect2(1207, 115, 38, 5), Color("406067"))
	for x in [1131, 1168, 1220]:
		_arch(Rect2(x, 203 if x < 1200 else 149, 12, 24), Color("162f39"))
	# Fine wall joints, placed deliberately rather than as a random texture.
	for joint in [Vector4(155, 215, 170, 215), Vector4(204, 230, 223, 230), Vector4(94, 248, 114, 248), Vector4(1034, 242, 1049, 242), Vector4(1083, 232, 1103, 232), Vector4(1168, 242, 1187, 242)]:
		draw_line(Vector2(joint.x, joint.y), Vector2(joint.z, joint.w), Color(0.1, 0.22, 0.26, 0.45), 1.0)


func _draw_gallery() -> void:
	# Back wall with an inset central entrance and long, low seating.
	_poly([Vector2(174, 274), Vector2(270, 229), Vector2(1001, 229), Vector2(1090, 273), Vector2(1040, 310), Vector2(221, 310)], Color("29434a"))
	draw_rect(Rect2(285, 230, 690, 9), Color("56716a"))
	draw_rect(Rect2(300, 241, 664, 44), Color("314d50"))
	_arch(Rect2(594, 223, 76, 72), Color("5a6a60"))
	_arch(Rect2(602, 230, 60, 65), Color("172f36"))
	draw_rect(Rect2(627, 247, 10, 44), Color("243c41"))
	for x in [314, 353, 392, 431, 470, 509, 711, 750, 789, 828, 867, 906]:
		draw_rect(Rect2(x, 247, 25, 18), Color("203b42"))
	draw_line(Vector2(243, 278), Vector2(1023, 278), Color("557068"), 3.0)
	draw_line(Vector2(220, 289), Vector2(1045, 289), Color("243b40"), 8.0)
	draw_line(Vector2(215, 293), Vector2(1050, 293), Color("48605b"), 3.0)
	# Market awnings sit on the sides, leaving the actual fight unobstructed.
	_stall(Vector2(31, 227), 139, Color("956556"), Color("c4926b"), false)
	_stall(Vector2(1097, 233), 140, Color("466b68"), Color("7e9580"), true)
	# A small audience: muted heads, shoulders and a few scarves.
	for i in range(27):
		var x: float = 242.0 + float(i) * 30.0
		if absf(x - 632.0) < 65.0:
			continue
		var bob: float = sin(_clock * (1.6 if combat_active else 0.6) + float(i) * 1.9) * (1.4 if combat_active else 0.4)
		var y: float = 270.0 + bob + float(i % 3) * 2.0
		var audience_color: Color = Color("19353c") if i % 3 != 0 else Color("294247")
		_ellipse(Vector2(x, y + 9), Vector2(8, 10), audience_color, 12)
		draw_circle(Vector2(x, y - 1), 5, audience_color)
		if i % 5 == 0:
			draw_line(Vector2(x - 4, y + 5), Vector2(x + 4, y + 7), Color("9b7957"), 2)
		if combat_active and i % 7 == 0:
			draw_line(Vector2(x + 5, y + 7), Vector2(x + 11, y - 4 + bob * 2), audience_color, 3)
	# Two pots anchor the depth at the edge of the arena.
	_pot(Vector2(91, 321), 19, Color("9b6450"))
	_pot(Vector2(1157, 328), 24, Color("7a5148"))
	_pot(Vector2(1199, 330), 13, Color("ba805e"))


func _stall(at: Vector2, width: float, dark: Color, light: Color, flip: bool) -> void:
	draw_rect(Rect2(at + Vector2(8, 3), Vector2(width - 16, 81)), Color("1e343b"))
	for offset in [10.0, width - 10.0]:
		draw_line(at + Vector2(offset, 0), at + Vector2(offset, 87), Color("79624f"), 4)
	var panels: int = 7
	for i in range(panels):
		var x: float = float(i) * width / float(panels)
		var next_x: float = float(i + 1) * width / float(panels)
		var col: Color = light if i % 2 == 0 else dark
		_poly([at + Vector2(x + 9, 0), at + Vector2(next_x + 5, 0), at + Vector2(next_x, 23), at + Vector2(x, 23)], col)
		_ellipse(at + Vector2((x + next_x) / 2, 23), Vector2(width / 14, 5), col, 12)
	draw_line(at + Vector2(9, -1), at + Vector2(width + 5, -1), light.lightened(0.12), 2)
	draw_rect(Rect2(at + Vector2(5, 57), Vector2(width - 10, 20)), dark.darkened(0.45))
	draw_rect(Rect2(at + Vector2(3, 54), Vector2(width - 6, 6)), Color("8e7156"))
	for i in range(4):
		var pos: Vector2 = at + Vector2(24 + i * 25, 48)
		_ellipse(pos, Vector2(7, 5), Color("a78658") if flip else Color("827e55"), 12)
	_lantern(at + Vector2(width * 0.5, 34), 0.55, 5.0 if flip else 2.0)


func _pot(at: Vector2, size: float, color: Color) -> void:
	_ellipse(at + Vector2(0, size * 0.13), Vector2(size * 0.95, size * 0.28), Color(0.04, 0.08, 0.09, 0.3), 22)
	_poly([at + Vector2(-size * 0.52, -size), at + Vector2(-size * 0.8, -size * 0.65), at + Vector2(-size * 0.63, -size * 0.06), at + Vector2(size * 0.55, -size * 0.06), at + Vector2(size * 0.77, -size * 0.65), at + Vector2(size * 0.48, -size)], color)
	_ellipse(at + Vector2(0, -size), Vector2(size * 0.55, size * 0.16), color.lightened(0.2), 22)
	_ellipse(at + Vector2(0, -size), Vector2(size * 0.38, size * 0.09), color.darkened(0.4), 22)
	draw_line(at + Vector2(-size * 0.6, -size * 0.58), at + Vector2(size * 0.6, -size * 0.58), color.lightened(0.13), 2)


func _draw_ring() -> void:
	# Soft shadow, raised stone rim, then the warm sand fighting surface.
	draw_rect(Rect2(0, 319, 1264, 95), Color("263e42"))
	_ellipse(Vector2(632, 365), Vector2(556, 91), Color("1b3037"))
	_ellipse(Vector2(632, 359), Vector2(517, 85), Color("6c594e"))
	_ellipse(Vector2(632, 353), Vector2(517, 82), Color("a68061"))
	_ellipse(Vector2(632, 351), Vector2(496, 73), Color("5e4d44"))
	_ellipse(Vector2(632, 348), Vector2(489, 71), Color("a16f53"))
	_ellipse(Vector2(632, 342), Vector2(480, 63), Color("b17c58"))
	_ellipse(Vector2(632, 341), Vector2(398, 51), Color("b8815b"))
	# Inlaid brick joints along the rim.
	for i in range(42):
		var angle: float = TAU * float(i) / 42.0
		var outer: Vector2 = Vector2(632, 353) + Vector2(cos(angle) * 514.0, sin(angle) * 81.0)
		var inner: Vector2 = Vector2(632, 351) + Vector2(cos(angle) * 498.0, sin(angle) * 73.0)
		draw_line(inner, outer, Color("796451"), 1.5, true)
	# A faint sun seal is a physical arena marking, never a UI element.
	var emblem_color: Color = Color(0.85, 0.67, 0.44, 0.29)
	var emblem: PackedVector2Array = PackedVector2Array()
	for i in range(65):
		var angle: float = TAU * float(i) / 64.0
		emblem.append(Vector2(632, 346) + Vector2(cos(angle) * 122.0, sin(angle) * 27.0))
	draw_polyline(emblem, emblem_color, 2, true)
	for i in range(12):
		var angle: float = TAU * float(i) / 12.0
		draw_line(Vector2(632, 346) + Vector2(cos(angle) * 131, sin(angle) * 30), Vector2(632, 346) + Vector2(cos(angle) * 142, sin(angle) * 33), emblem_color, 2, true)
	for grain in _sand:
		draw_line(Vector2(grain.x, grain.y), Vector2(grain.x + grain.z * 2.3, grain.y), Color(0.40, 0.25, 0.19, 0.20), 1.0)
	# Foreground silhouettes create a vignette without dimming the fight.
	_poly([Vector2(0, 363), Vector2(47, 369), Vector2(82, 386), Vector2(136, 398), Vector2(186, 414), Vector2(0, 414)], Color("192e35"))
	_poly([Vector2(1264, 362), Vector2(1227, 372), Vector2(1199, 386), Vector2(1142, 399), Vector2(1090, 414), Vector2(1264, 414)], Color("192e35"))
	for i in range(4):
		var x: float = 16 + i * 21
		draw_line(Vector2(x, 402 + i * 2), Vector2(x + 6, 370 + i * 7), Color("35504b"), 2)
		draw_line(Vector2(1246 - i * 18, 409), Vector2(1244 - i * 19, 383 + i * 3), Color("35504b"), 2)


func _draw_festival() -> void:
	# Catenaries are deliberately high at center to frame the fighters.
	_string(Vector2(0, 76), Vector2(436, 94), 47.0, 6, 0.0)
	_string(Vector2(835, 91), Vector2(1264, 61), 47.0, 6, 3.4)
	var center_cord: PackedVector2Array = PackedVector2Array()
	for i in range(37):
		var t: float = float(i) / 36.0
		center_cord.append(Vector2(226 + 811 * t, 140 + sin(t * PI) * 21))
	draw_polyline(center_cord, Color("536864"), 1.1, true)
	for i in range(16):
		var t: float = (float(i) + 0.5) / 16.0
		var pos: Vector2 = Vector2(226 + 811 * t, 140 + sin(t * PI) * 21)
		var sway: float = sin(_clock * 1.3 + float(i) * 0.7) * 3
		var flag_color: Color = [Color("ad7459"), Color("809582"), Color("b29461"), Color("4f7976")][i % 4]
		_poly([pos + Vector2(-6, 0), pos + Vector2(7, 0), pos + Vector2(sway, 14)], flag_color)
	# Side standards with an original diamond-and-ember insignia.
	_banner(Vector2(264, 184), Color("975b49"), 0.0)
	_banner(Vector2(968, 181), Color("406f6a"), 2.0)
	# Braziers emit warm pools at the arena entrance.
	_brazier(Vector2(260, 302), 0.0)
	_brazier(Vector2(1004, 302), 2.6)


func _string(a: Vector2, b: Vector2, sag: float, count: int, phase: float) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(49):
		var t: float = float(i) / 48.0
		points.append(a.lerp(b, t) + Vector2(0, sin(t * PI) * sag))
	draw_polyline(points, Color("77816b"), 1.2, true)
	for i in range(count):
		var t: float = (float(i) + 0.55) / float(count)
		var point: Vector2 = a.lerp(b, t) + Vector2(0, sin(t * PI) * sag)
		_lantern(point + Vector2(0, 10), 0.75 + (0.15 if i % 2 == 0 else 0.0), phase + float(i))


func _lantern(at: Vector2, size: float, phase: float) -> void:
	var sway: float = sin(_clock * 0.85 + phase) * 2.0
	var pos: Vector2 = at + Vector2(sway, 0)
	var warmth: float = 0.84 + sin(_clock * 1.6 + phase) * 0.10
	_glow(pos + Vector2(0, 8 * size), 43 * size, GOLD, warmth)
	draw_line(at + Vector2(0, -10), pos + Vector2(0, -3 * size), Color("9c9676"), 1)
	_poly([pos + Vector2(-7, 0) * size, pos + Vector2(7, 0) * size, pos + Vector2(9, 7) * size, pos + Vector2(6, 18) * size, pos + Vector2(-6, 18) * size, pos + Vector2(-9, 7) * size], Color("c38a4c"))
	_poly([pos + Vector2(-5, 2) * size, pos + Vector2(5, 2) * size, pos + Vector2(6, 8) * size, pos + Vector2(4, 15) * size, pos + Vector2(-4, 15) * size, pos + Vector2(-6, 8) * size], Color("f0c477").lerp(Color("ffdfa1"), warmth * 0.5))
	draw_line(pos + Vector2(-7, 0) * size, pos + Vector2(7, 0) * size, Color("5e5848"), 2)
	draw_line(pos + Vector2(-6, 18) * size, pos + Vector2(6, 18) * size, Color("5e5848"), 2)
	draw_line(pos + Vector2(0, 2) * size, pos + Vector2(0, 16) * size, Color(0.67, 0.40, 0.19, 0.55), 1)
	draw_line(pos + Vector2(0, 19) * size, pos + Vector2(0, 24) * size, Color("b79760"), 1)


func _banner(at: Vector2, color: Color, phase: float) -> void:
	var sway: float = sin(_clock * 1.2 + phase) * 2.4
	draw_line(at + Vector2(0, -6), at + Vector2(0, 89), Color("7b755c"), 3)
	draw_circle(at + Vector2(0, -8), 3, GOLD)
	draw_line(at, at + Vector2(28, 0), Color("958365"), 2)
	_poly([at + Vector2(3, 2), at + Vector2(27, 2), at + Vector2(27 + sway, 48), at + Vector2(16 + sway, 59), at + Vector2(3 + sway, 49)], color)
	draw_line(at + Vector2(6, 5), at + Vector2(25, 5), color.lightened(0.3), 1)
	var center: Vector2 = at + Vector2(15 + sway * 0.35, 26)
	_poly([center + Vector2(0, -10), center + Vector2(6, 0), center + Vector2(0, 10), center + Vector2(-6, 0)], Color("dbb578"))
	_poly([center + Vector2(0, -5), center + Vector2(3, 0), center + Vector2(0, 5), center + Vector2(-3, 0)], color)


func _brazier(at: Vector2, phase: float) -> void:
	_glow(at + Vector2(0, -31), 61, Color("ecaa59"), 0.75)
	_ellipse(at + Vector2(0, 5), Vector2(19, 5), Color(0.07, 0.14, 0.16, 0.5), 24)
	draw_line(at + Vector2(-8, 1), at + Vector2(-5, -22), Color("6b6252"), 3)
	draw_line(at + Vector2(8, 1), at + Vector2(5, -22), Color("6b6252"), 3)
	_poly([at + Vector2(-15, -25), at + Vector2(15, -25), at + Vector2(9, -16), at + Vector2(-9, -16)], Color("89734f"))
	draw_line(at + Vector2(-15, -25), at + Vector2(15, -25), Color("c4975e"), 2)
	var flicker: float = sin(_clock * 7.0 + phase) * 3.0
	_poly([at + Vector2(-9, -26), at + Vector2(-7, -35), at + Vector2(-2, -32), at + Vector2(1 + flicker, -48), at + Vector2(6, -37), at + Vector2(10, -40), at + Vector2(9, -27)], Color("de9350"))
	_poly([at + Vector2(-5, -26), at + Vector2(-3, -32), at + Vector2(1, -30), at + Vector2(3 + flicker * 0.4, -39), at + Vector2(6, -26)], Color("f7cc78"))


func _draw_motes() -> void:
	# Screen-space ambient dust remains sparse on small displays after cropping.
	var count: int = clampi(roundi(_viewport_size.x * _viewport_size.y / 46000.0), 10, 38)
	for i in range(count):
		var phase: float = float(i) * 2.399
		var travel: float = _clock * (4.5 if combat_active else 2.1)
		var x: float = fposmod(float(i) * 0.618 * _viewport_size.x + travel, _viewport_size.x + 50.0) - 25.0
		var y: float = _viewport_size.y * (0.46 + sin(phase + _clock * 0.17) * 0.19 + float(i % 3) * 0.045)
		var alpha: float = 0.13 + 0.13 * sin(_clock * 0.8 + phase)
		draw_circle(Vector2(x, y), 1.15 if i % 3 == 0 else 0.8, Color(0.89, 0.76, 0.48, alpha))


func _draw_impacts() -> void:
	for spark in _sparks:
		var life_ratio: float = clampf(float(spark["life"]) / float(spark["max_life"]), 0.0, 1.0)
		var pos: Vector2 = spark["pos"]
		var critical: bool = spark["critical"]
		var spark_color: Color = Color("ffe5a4") if critical else Color("f9ca87")
		spark_color.a = life_ratio * 0.90
		var vel: Vector2 = spark["vel"]
		ParticleInk.spark(self, pos, vel, 1.3 if critical else 1.0, spark_color, 4.5 if critical else 3.0)
