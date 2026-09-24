extends RefCounted
## Layout in viewport points. The scenery is full bleed; controls have bounded widths.
# Common envelope includes the widest sequence silhouette, rotation and outward recoil.
# Framing is fixed for a viewport; individual poses never move their ground origin.
const VisualProfiles = preload("res://scripts/character_visual_profile.gd")
# Reserve outward space for extended and grounded poses when their painted
# silhouette is kept behind the shared contact line. Scale stays fixed per view.
const ACTOR_OUTER_EXTENT := 190.0
const COMPACT_GAP_UNITS := 90.0

static func actor_framing(width: float, desired_scale: float, gap_units: float = 78.0, margin: float = 12.0) -> Dictionary:
	var available := maxf(1.0, width * 0.5 - maxf(0.0, margin))
	var gap := maxf(COMPACT_GAP_UNITS, gap_units)
	var scale := minf(maxf(0.001, desired_scale), available / (gap + ACTOR_OUTER_EXTENT))
	return {"scale":scale, "half_gap":gap * scale}

static func calculate(view: Vector2, fighting: bool, finished: bool = false) -> Dictionary:
	var w := maxf(360, view.x)
	var h := maxf(360, view.y)
	var phone := w < 640
	var short := h < 540 and not phone
	var pad := 16.0 if phone or short else clampf(w * 0.035, 24, 64)
	var hud_w := (w - pad * 2 - 24) / 2 if phone else minf(360, w * 0.31)
	var hud_y := 64.0 if phone else (52.0 if short else 92.0)
	var hud_h := 106.0 if phone else (96.0 if short else 110.0)
	var scale := minf(w / 370.0, clampf((h - 300) / 290.0, 1.15, 2.05))
	if short: scale = clampf((h - 268) / 166.0, 0.55, 1.1)
	var floor_y := h - (126 if short else (260 if phone else 212))
	floor_y = maxf(h * 0.65, floor_y)
	# Compact screens keep one common framing in idle, battle and result. Test the
	# widest resting separation first so entering combat cannot change their scale.
	var gap_units := COMPACT_GAP_UNITS
	var framing := actor_framing(w, scale, gap_units)
	scale = float(framing.scale)
	var half_gap := float(framing.half_gap)
	var result: Dictionary = {
		"viewport": Rect2(Vector2.ZERO, Vector2(w, h)), "phone": phone, "short": short, "pad": pad,
		"actor_scale": scale, "floor": floor_y,
		"player_at": Vector2(w / 2 - half_gap, floor_y), "rival_at": Vector2(w / 2 + half_gap, floor_y),
		"brand": Rect2(pad, 16, 160, 36), "menu": Rect2(w - pad - 88, 16, 88, 44),
		"hud_player": Rect2(pad, hud_y, hud_w, hud_h), "hud_rival": Rect2(w - pad - hud_w, hud_y, hud_w, hud_h),
		"center": Rect2(w / 2 - 150, 84, 300, 106),
		"signature": Rect2(w / 2 - minf(360,w/2-pad), maxf(hud_y+hud_h+16, floor_y-scale*166-90), minf(720,w-pad*2), 60),
		"progress": Rect2(pad, h - 186, 300, 66),
		"feed": Rect2(w/2-minf(280,w/2-pad), h-180, minf(560,w-pad*2), 28),
		"controls": Rect2(0,h-200,w,200),
		"primary": Rect2(w/2-164,h-104,328,64),
		"training": Rect2(pad,h-96,148,52), "roster": Rect2(pad+160,h-96,148,52),
		"speed": Rect2(w-pad-256,h-96,120,52), "log": Rect2(w-pad-124,h-96,124,52),
		"surrender": Rect2(w-pad-124,h-96,124,52),
		"result": Rect2(w/2-330,h-248,660,128),
	}
	if w < 1180 and not phone:
		result.training = Rect2(pad,h-96,116,52)
		result.roster = Rect2(pad+124,h-96,120,52)
		result.primary = Rect2(w/2-140,h-104,280,64)
		result.speed = Rect2(w-pad-220,h-96,100,52)
		result.log = Rect2(w-pad-112,h-96,112,52)
	if phone:
		var cell := (w-pad*2-16)/3
		result.center = Rect2(w/2-150,170,300,56)
		result.progress = Rect2(pad,h-192,w-pad*2,36)
		result.controls = Rect2(0,h-224,w,224)
		result.feed = Rect2(pad,h-230,w-pad*2,28)
		result.primary = Rect2(pad,h-144,w-pad*2,56)
		result.training = Rect2(pad,h-76,cell,48)
		result.roster = Rect2(pad+cell+8,h-76,cell,48)
		result.speed = result.training
		result.log = Rect2(pad+2*(cell+8),h-76,cell,48)
		result.surrender = result.log
		if fighting: result.log = result.roster
		result.result = Rect2(pad,h-254,w-pad*2,104)
	elif short:
		result.brand = Rect2(pad,8,132,32)
		result.menu = Rect2(w-pad-88,8,88,44)
		result.center = Rect2(w/2-90,48,180,78)
		result.hud_player.size.y = 90
		result.hud_rival.size.y = 90
		result.controls = Rect2(0,h-108,w,108)
		result.primary = Rect2(w/2-116,h-72,232,52)
		result.training = Rect2(pad,h-68,96,44)
		result.roster = Rect2(pad+104,h-68,100,44)
		result.speed = Rect2(w-pad-204,h-68,96,44)
		result.log = Rect2(w-pad-100,h-68,100,44)
		result.surrender = result.log
		result.feed = Rect2(w/2-260,h-108,520,24)
		result.result = Rect2(w/2-240,h-124,480,48)
		result.signature = Rect2(w/2-230,h-124,460,40)
	elif w < 1000:
		# Tablet uses the same two-row thumb controls as portrait, with a bounded width.
		var left := w/2-288
		result.primary = Rect2(w/2-164,h-140,328,60)
		result.training = Rect2(left,h-64,136,48)
		result.roster = Rect2(left+144,h-64,136,48)
		result.speed = Rect2(left+288,h-64,136,48)
		result.log = Rect2(left+432,h-64,136,48)
		result.surrender = result.roster
		result.progress = Rect2(pad,h-196,w-pad*2,44)
	if not short:
		var height := minf(128, floor_y-166*scale-(hud_y+hud_h)-24)
		height = maxf(96,height)
		result.result = Rect2(w/2-minf(330,w/2-pad),hud_y+hud_h+12,minf(660,w-pad*2),height)
		if phone:
			result.result.position.y = 240
			result.result.size.y = 112
	if phone and fighting: result.feed.position.y = h-202
	result.menu = Rect2(w/2-48,8 if short else 12,96,44)
	if finished:
		var result_width: float = minf(560,w-pad*2)
		var result_height: float = 64 if short else (120 if phone else 128)
		var action_height: float = 48 if short else 56
		var group_height: float = result_height+12+action_height
		var group_top: float = (h-group_height)*0.5
		if phone:
			var above_actor: float = floor_y-VisualProfiles.REST_ENVELOPE.size.y*scale-group_height-16
			group_top = maxf(hud_y+hud_h+16,minf(group_top,above_actor))
		result.result = Rect2((w-result_width)*0.5,group_top,result_width,result_height)
		var action_width: float = minf(328,result_width)
		result.primary = Rect2((w-action_width)*0.5,result.result.end.y+12,action_width,action_height)
	result.actor_player = Rect2(result.player_at-Vector2(78,166)*scale,Vector2(156,166)*scale)
	result.actor_rival = Rect2(result.rival_at-Vector2(78,166)*scale,Vector2(156,166)*scale)
	return result
