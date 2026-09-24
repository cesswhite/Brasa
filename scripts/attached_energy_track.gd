extends RefCounted
class_name AttachedEnergyTrack
## A paired FX canvas, not a new character illustration or an animation clock.
## Only authored Ascua sockets are accepted. Source body textures are never read
## or modified; every texel outside the tiny emissive regions stays transparent.
const CANVAS := Vector2i(512,512)
const PIVOT := Vector2(256,448)
const CORE_RADIUS := 12.0
const HAND_RADIUS := 10.0
const MAX_ALPHA := 0.35
const CACHE_LIMIT := 16
static var _cache: Dictionary = {}
static var _lru: Array[String] = []

static func _socket(value: Variant) -> Variant:
	var point: Vector2
	if value is Vector2 or value is Vector2i:
		point=Vector2(value)
	elif value is Array and value.size()==2:
		for coordinate: Variant in value:
			if not (coordinate is float or coordinate is int): return null
		point=Vector2(float(value[0]),float(value[1]))
	else: return null
	if not point.is_finite() or point.x<0 or point.y<0 or point.x>=CANVAS.x or point.y>=CANVAS.y: return null
	return point

static func texture_for(frame: Dictionary, channel: String = "core_hand") -> Texture2D:
	if str(frame.get("body_id",""))!="ascua" or not bool(frame.get("normalized",false)): return null
	if not channel in ["core","core_hand"]: return null
	var canvas: Variant=frame.get("canvas_px",CANVAS)
	if not (canvas is Vector2i or canvas is Vector2) or Vector2i(canvas)!=CANVAS: return null
	var sockets: Variant=frame.get("sockets_px",{})
	if not sockets is Dictionary: return null
	# No core inferred from chest/default zones, alpha bounds, warm colors or a
	# different pose. An unreviewed frame safely has no attached emission.
	var visibility: Variant=frame.get("socket_visibility",{})
	if not visibility is Dictionary: visibility={}
	if str(visibility.get("core","visible"))=="occluded": return null
	var core: Variant=_socket(sockets.get("core"))
	if core==null: return null
	var hand: Variant=_socket(sockets.get("hand")) if channel=="core_hand" and str(visibility.get("hand","visible"))!="occluded" else null
	var key := "%s|%s|%s|%s|%s|%s" % [str(frame.get("profile_id","ascua:normal:v1")),str(frame.get("source_path","")),str(frame.get("name","")),channel,str(core),str(hand)]
	if _cache.has(key):
		_lru.erase(key); _lru.append(key)
		return _cache[key]
	var image := Image.create(CANVAS.x,CANVAS.y,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	_pigment(image,core,CORE_RADIUS,0)
	if hand!=null: _pigment(image,hand,HAND_RADIUS,1)
	var texture := ImageTexture.create_from_image(image)
	_cache[key]=texture
	_lru.append(key)
	while _lru.size()>CACHE_LIMIT: _cache.erase(_lru.pop_front())
	return texture

static func _pigment(image: Image, center: Vector2, radius: float, salt: int) -> void:
	var extent := int(ceil(radius))
	for y: int in range(maxi(0,int(floor(center.y))-extent),mini(CANVAS.y,int(ceil(center.y))+extent+1)):
		for x: int in range(maxi(0,int(floor(center.x))-extent),mini(CANVAS.x,int(ceil(center.x))+extent+1)):
			var delta := Vector2(x,y)+Vector2(0.5,0.5)-center
			var distance := delta.length()/radius
			if distance>=1.0: continue
			# A compact uneven pigment patch, with no white center, outline ring,
			# stock flare or screen-wide bloom. Hand emission is slightly dimmer.
			var grain := fposmod(sin(float(x*73+y*151+salt*307))*43758.5453,1.0)
			var falloff := pow(1.0-distance,1.65)
			var alpha := MAX_ALPHA*falloff*(0.88+grain*0.12)*(0.84 if salt==1 else 1.0)
			var color := Color("f77a27").lerp(Color("eaa03a"),falloff*0.42)
			var prior := image.get_pixel(x,y)
			if prior.a>0:
				var combined := minf(MAX_ALPHA,alpha+prior.a*(1.0-alpha))
				color=prior.lerp(color,alpha/maxf(0.00001,alpha+prior.a))
				alpha=combined
			color.a=clampf(alpha,0,MAX_ALPHA)
			image.set_pixel(x,y,color)

static func clear_cache() -> void:
	_cache.clear()
	_lru.clear()

static func debug_info() -> Dictionary:
	return {"count":_cache.size(),"limit":CACHE_LIMIT,"canvas_px":CANVAS,"pivot_px":PIVOT,"max_alpha":MAX_ALPHA,"core_radius_px":CORE_RADIUS,"hand_radius_px":HAND_RADIUS,"clock":false}
