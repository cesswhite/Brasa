extends RefCounted
## Small soft pigment grains shared by the character and world emitters.
## Generated in memory; no atlas edits, rings, scene nodes or simulation RNG.
static var _grain: GradientTexture2D

static func texture() -> GradientTexture2D:
	if _grain == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.24, 0.60, 1.0])
		gradient.colors = PackedColorArray([Color.WHITE, Color(1,1,1,0.85), Color(1,1,1,0.24), Color(1,1,1,0)])
		_grain = GradientTexture2D.new()
		_grain.gradient = gradient
		_grain.width = 32
		_grain.height = 32
		_grain.fill = GradientTexture2D.FILL_RADIAL
		_grain.fill_from = Vector2(0.5,0.5)
		_grain.fill_to = Vector2(0.5,1.0)
	return _grain

static func mote(canvas: CanvasItem, at: Vector2, radius: Vector2, color: Color, angle: float = 0.0) -> void:
	if color.a <= 0.001 or radius.x <= 0.0 or radius.y <= 0.0: return
	canvas.draw_set_transform(at,angle)
	canvas.draw_texture_rect(texture(),Rect2(-radius,radius*2.0),false,color)
	canvas.draw_set_transform(Vector2.ZERO)

static func spark(canvas: CanvasItem, at: Vector2, velocity: Vector2, width: float, color: Color, length: float = 5.0) -> void:
	var direction := velocity.normalized() if velocity.length_squared() > 0.01 else Vector2.UP
	var extent := clampf(length,1.0,16.0)
	var thickness := clampf(width,0.2,2.4)
	var haze := color
	haze.a *= 0.22
	mote(canvas,at,Vector2(extent*0.75,thickness*2.8),haze,direction.angle())
	mote(canvas,at,Vector2(extent*0.5,thickness),color,direction.angle())
	# A small hot core survives mobile downscaling; the surrounding grain stays soft.
	var core := color.lerp(Color(1,0.94,0.8,color.a),0.18)
	core.a *= 0.78
	canvas.draw_line(at-direction*extent*0.3,at+direction*extent*0.2,core,maxf(0.55,thickness*0.7),true)
