extends Node2D
class_name CombatFX
## Small organic particles; no gameplay RNG, radial sprite bursts or combat authority.

const MANIFEST_PATH := "res://data/combat_fx.json"
const Sequences = preload("res://scripts/fighter_animation_set.gd")
const VisualProfile = preload("res://scripts/move_visual_profile.gd")
const MAX_EFFECTS := 20
const MAX_PENDING := 12
const MAX_PARTICLES := 320
const MAX_SEEN_ACTIONS := 64
const MAX_MARKER_HISTORY := 128
const Ink = preload("res://scripts/particle_ink.gd")
static var _definitions: Dictionary = {}
static var _atlas: Texture2D
static var _textures: Dictionary = {}
var reduced_motion := false
var motion_paused := false
var _effects: Array[Dictionary] = []
var _pending: Array[Dictionary] = []
var _seen_actions: Array[String] = []
var _marker_history: Array[Dictionary] = []
var _shake_age := 1.0
var _shake_duration := 0.0
var _shake_strength := 0.0

static func definitions() -> Dictionary:
	if _definitions.is_empty() and FileAccess.file_exists(MANIFEST_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
		if parsed is Dictionary: _definitions = parsed
	return _definitions.duplicate(true)

static func effect_texture(id: String) -> Texture2D:
	if _textures.has(id): return _textures[id]
	var data := definitions()
	var entry: Dictionary = data.get("effects",{}).get(id,{})
	if entry.is_empty(): return null
	if _atlas == null:
		var path := str(data.get("atlas",""))
		if not path.begins_with("res://assets/fx/") or not ResourceLoader.exists(path): return null
		_atlas = load(path) as Texture2D
	var r: Array = entry.get("region",[])
	if r.size() != 4: return null
	var texture := AtlasTexture.new()
	texture.atlas = _atlas
	texture.region = Rect2(float(r[0]),float(r[1]),float(r[2]),float(r[3]))
	texture.filter_clip = true
	_textures[id] = texture
	return texture

func _ready() -> void:
	process_priority = -1

func clear() -> void:
	_effects.clear()
	_pending.clear()
	_seen_actions.clear()
	_marker_history.clear()
	_shake_duration = 0.0
	_shake_age = 1.0
	queue_redraw()

func _number(value: Variant, fallback: float) -> float:
	return float(value) if (value is float or value is int) and is_finite(float(value)) else fallback

func _facing(actor: Node2D) -> int:
	return -1 if _number(actor.get("facing"),1.0)<0 else 1

func _actor_scale(actor: Node2D) -> float:
	return clampf(absf(actor.global_scale.x)/maxf(0.01,absf(global_scale.x)),0.2,3.0)

func _anchor(actor: Node2D, kind: String) -> Vector2:
	var at := Vector2.ZERO
	if actor.has_method("effect_anchor"):
		at = actor.call("effect_anchor",kind)
	elif kind != "feet":
		at = Vector2(0,-78)
	return to_local(actor.to_global(at))

func emit_effect(id: String, at: Vector2, actor_scale: float = 1.0, facing: int = 1, age: float = 0.0, tint: Color = Color.WHITE) -> void:
	_emit(id,at,actor_scale,facing,age,tint)

func emit_attached(id: String, actor: Node2D, anchor: String = "body", age: float = 0.0, tint: Color = Color.WHITE) -> void:
	if reduced_motion or not is_instance_valid(actor): return
	_emit(id,_anchor(actor,anchor),_actor_scale(actor),_facing(actor),age,tint,actor,anchor)
	# Attached particle births are separate from anatomy-aligned paired sprite FX.
	# Never brighten the whole body to make charge/status particles visible.

func _emit(id: String, at: Vector2, actor_scale: float, facing: int, age: float, tint: Color, actor: Node2D = null, anchor: String = "body", style: String = "", emit_limit: float = -1.0) -> void:
	if reduced_motion or not at.is_finite(): return
	var entry: Dictionary = definitions().get("effects",{}).get(id,{})
	if entry.is_empty(): return
	var duration := clampf(_number(entry.get("duration"),0.3),0.05,1.2)
	age = maxf(0,_number(age,duration))
	if age >= duration: return
	while _effects.size() >= MAX_EFFECTS: _effects.pop_front()
	var scale_value := clampf(_number(actor_scale,1),0.2,3.0)
	var particles: Array[Dictionary] = []
	var count := clampi(int(entry.get("count",8)),1,24)
	var emission := clampf(float(entry.get("emission",0)),0,duration*0.7)
	if emit_limit>=0: emission=minf(emission,emit_limit)
	for index in range(count):
		particles.append({"index":index,"birth":emission*pow(float(index)/maxi(1,count-1),1.45),"origin":Vector2.ZERO,"spawned":false})
	var item := {"id":id,"at":at,"size":float(entry.get("size",40))*scale_value,"scale":scale_value,"age":age,"duration":duration,"emission":emission,"facing":-1 if facing<0 else 1,"tint":tint,"style":style if not style.is_empty() else str(entry.get("style","sparks")),"actor":weakref(actor) if is_instance_valid(actor) else null,"anchor":anchor,"particles":particles,"definition":entry.duplicate(true)}
	_spawn(item)
	_effects.append(item)
	while _particle_count()>MAX_PARTICLES and _effects.size()>1: _effects.pop_front()
	queue_redraw()

func _particle_count() -> int:
	var total := 0
	for item: Dictionary in _effects: total += item.particles.size()
	return total

func _noise(index: int, salt: int) -> float:
	# Stateless presentation variation. Never consumes a global or combat RNG.
	return fposmod(sin(float(index*73+salt*157+31))*43758.5453,1.0)

func _spawn(item: Dictionary) -> void:
	var actor: Variant = item.actor.get_ref() if item.actor is WeakRef else null
	if item.actor is WeakRef and not is_instance_valid(actor):
		for particle: Dictionary in item.particles:
			if not bool(particle.spawned): particle.birth=item.duration+1
		return
	if is_instance_valid(actor): item.at=_anchor(actor,str(item.anchor))
	var spread: Array = item.definition.get("spread",[3.0,3.0])
	for particle: Dictionary in item.particles:
		if bool(particle.spawned) or float(particle.birth)>float(item.age): continue
		particle.spawned=true
		var index := int(particle.index)
		var origin: Vector2 = item.at
		# Let pigment escape beside the torso and knuckles instead of burying all
		# births inside an opaque sprite. No ring or orbit around the character.
		if is_instance_valid(actor):
			if str(item.anchor) in ["body","chest"] and index%3!=0:
				var edge: String = "hand" if index%2==0 else "back"
				origin=_anchor(actor,edge)+Vector2((7.0 if edge=="hand" else -7.0)*float(item.facing),3.0)*float(item.scale)
			elif str(item.anchor)=="hand":
				origin+=Vector2(7.0*float(item.facing),0)*float(item.scale)
		particle.origin=origin+Vector2((_noise(index,1)-0.5)*float(spread[0]),(_noise(index,2)-0.5)*float(spread[1]))*float(item.scale)

func _sample(item: Dictionary, particle: Dictionary) -> Dictionary:
	if not bool(particle.spawned): return {}
	var life := maxf(0.01,float(item.duration)-float(particle.birth))
	var age := float(item.age)-float(particle.birth)
	if age<0 or age>=life: return {}
	var phase := age/life
	var index := int(particle.index)
	var style := str(item.style)
	var scale_value := float(item.scale)
	var facing := float(item.facing)
	var speed := float(item.definition.get("speed",70))
	var velocity: Vector2
	var gravity := 0.0
	var radius := Vector2.ONE
	var color := Color(str(item.definition.get("color","ffc582"))) * Color(item.tint)
	var kind := "mote"
	if style=="sparks":
		velocity=Vector2(lerpf(0.35,1.0,_noise(index,3))*speed*facing,lerpf(-0.8,0.35,_noise(index,4))*speed)
		if index%5==0:velocity.x *= -0.25
		gravity=120.0
		radius=Vector2(lerpf(1.0,1.5,_noise(index,5)),1)
		kind="spark"
	elif style in ["dust","wake","slide"]:
		velocity=Vector2((_noise(index,3)-0.5)*speed,-lerpf(7,20,_noise(index,4)))
		if style in ["wake","slide"]: velocity.x=-facing*lerpf(speed*0.35,speed,_noise(index,3))
		gravity=15
		radius=Vector2(lerpf(1.5,3.7,_noise(index,5)),lerpf(0.9,2.1,_noise(index,6)))*(1+phase*0.55)
		color.a *= 0.42
	elif style=="debris":
		velocity=Vector2((_noise(index,3)-0.5)*speed,-lerpf(24,43,_noise(index,4)))
		gravity=180
		radius=Vector2(lerpf(0.9,1.7,_noise(index,5)),lerpf(0.7,1.4,_noise(index,6)))
		color.a *= 0.80
	elif style=="shield":
		velocity=Vector2(facing*lerpf(1,8,_noise(index,3)),-lerpf(9,25,_noise(index,4)))
		radius=Vector2(1.2,1.8)
		kind="spark"
		color=Color("b8e5ee")*Color(item.tint)
	elif style in ["mist","poison","heal"]:
		velocity=Vector2((_noise(index,3)-0.5)*18,-lerpf(13,30,_noise(index,4)))
		velocity.x += sin(age*5+index)*3
		radius=Vector2(lerpf(1.8,3.0,_noise(index,5)),lerpf(1.6,2.8,_noise(index,6)))
		color=Color("b3c5ce") if style=="mist" else Color("b8db79") if style=="poison" else Color("8fefb0")
		color *= Color(item.tint)
		color.a *= 0.72 if style!="heal" else 0.88
	else:
		velocity=Vector2((_noise(index,3)-0.5)*speed*0.42,-lerpf(speed*0.45,speed,_noise(index,4)))
		gravity=-8
		radius=Vector2(lerpf(1.5,2.2,_noise(index,5)),lerpf(1.9,2.5,_noise(index,6)))
		if index%3==0:kind="spark"
		color=color.lerp(Color("da783d"),phase*0.3)
	var drag := 2.0 if style in ["sparks","wake"] else 1.1
	var travel := (1.0-exp(-drag*age))/drag
	var at := Vector2(particle.origin)+(velocity*travel+Vector2(0,gravity*age*age*0.5))*scale_value
	# Ground emitters settle at their own birth floor; they never follow a foot
	# into the air or sink through the arena after the actor has moved away.
	if bool(item.definition.get("grounded",false)): at.y=minf(at.y,Vector2(particle.origin).y)
	var fade_power := 0.85 if style in ["embers","heal","poison","shield"] else 1.15 if style=="sparks" else 1.5
	color.a *= pow(1.0-phase,fade_power)*minf(1.0,age/0.018+0.5)
	return {"at":at,"velocity":velocity*scale_value,"radius":radius*scale_value,"color":color,"kind":kind,"length":lerpf(3,7,_noise(index,7))*scale_value*(1-phase*0.6)}

func play_impact(at: Vector2, presentation: Dictionary, actor_scale: float = 1.0, facing: int = 1, age: float = 0.0, target_actor: Node2D = null) -> void:
	if reduced_motion: return
	var id := str(presentation.get("impact_fx","small_hit"))
	if id!="none":
		if id == "critical": id = "critical_hit"
		if not definitions().get("effects",{}).has(id): id = "heavy_hit" if str(presentation.get("reaction","")) in ["heavy","knockback","knockdown","critical"] else "small_hit"
		if id=="critical_hit" and str(presentation.get("animation_type","")) in ["charge","heavy","signature"]: emit_effect("heavy_hit",at,actor_scale,facing,age)
		emit_effect(id,at,actor_scale,facing,age)
		if bool(presentation.get("signature",false)): emit_effect("charge_energy",at,actor_scale,facing,age)
		if str(presentation.get("reaction","")) in ["critical","critical_hit"] and id != "critical_hit": emit_effect("critical_hit",at,actor_scale,facing,age)
	if is_instance_valid(target_actor):
		var reaction := str(presentation.get("reaction","light"))
		if reaction in ["heavy","critical","knockback","knockdown","ko"]:
			var ground := _anchor(target_actor,"ground")
			var dust := "knockback_dust" if reaction in ["knockback","knockdown","ko"] else "dust_medium"
			emit_effect(dust,ground,_actor_scale(target_actor),-_facing(target_actor),age)
			if reaction in ["knockdown","ko"]: emit_effect("stone_debris",ground,_actor_scale(target_actor),facing,age)
	var feedback: Variant = presentation.get("camera_feedback","none")
	var strength := _number(feedback,0) if feedback is float or feedback is int else float({"none":0.0,"small":1.2,"light":1.2,"medium":2.2,"strong":3.2,"heavy":3.2}.get(str(feedback),0.0))
	if strength > 0 and age < 0.15:
		_shake_strength = clampf(strength,0,3.2)
		_shake_duration = 0.15
		_shake_age = maxf(0,age)

func play_move(event: Dictionary, actor: Node2D, age: float = 0.0) -> void:
	if reduced_motion or not is_instance_valid(actor): return
	age=maxf(0,_number(age,0))
	var move: Dictionary = event.get("move",{}) if event.get("move",{}) is Dictionary else {}
	# Real engine and replay events include time and move ID. Hand-authored demo
	# events without either represent one action until clear(), not new attacks.
	var key := "%s:%s:%s:%s:%s" % [actor.get_instance_id(),str(event.get("side","")),str(event.get("time",0)),str(event.get("event_id","")),str(move.get("id",move.get("animation_type","quick")))]
	for action: Dictionary in _pending:
		if str(action.key)==key:
			action.age=maxf(float(action.age),age)
			_dispatch_markers(action)
			return
	if key in _seen_actions: return
	var profile := VisualProfile.resolve(event)
	var action := {"key":key,"actor":weakref(actor),"age":age,"cursor":0,"markers":profile.markers,"windup":maxf(0.01,_number(move.get("windup"),0.12))}
	while _pending.size() >= MAX_PENDING:
		_remember_action(str(_pending.pop_front().key))
	_dispatch_markers(action)
	if int(action.cursor)<action.markers.size(): _pending.append(action)
	else: _remember_action(key)

func _remember_action(key: String) -> void:
	if not key in _seen_actions: _seen_actions.append(key)
	while _seen_actions.size()>MAX_SEEN_ACTIONS: _seen_actions.pop_front()

func _dispatch_markers(action: Dictionary) -> void:
	var actor: Variant = action.actor.get_ref()
	if not is_instance_valid(actor):
		action.cursor=action.markers.size()
		return
	while int(action.cursor)<action.markers.size():
		var marker: Dictionary = action.markers[int(action.cursor)]
		if float(marker.time)>float(action.age)+0.000001: break
		action.cursor=int(action.cursor)+1
		var late := maxf(0,float(action.age)-float(marker.time))
		var anchor := str(marker.anchor)
		var at := _anchor(actor,anchor)
		var fx := str(marker.fx)
		var record := {"action_id":str(action.key),"id":str(marker.id),"event":str(marker.event),"time":float(marker.time),"age":late,"at":at,"anchor":anchor,"fx":fx}
		_marker_history.append(record)
		while _marker_history.size()>MAX_MARKER_HISTORY: _marker_history.pop_front()
		if fx=="none": continue
		if bool(marker.attached):
			_emit(fx,at,_actor_scale(actor),_facing(actor),late,Color.WHITE,actor,anchor,"",float(action.windup) if fx=="charge_energy" else -1.0)
		else:
			_emit(fx,at,_actor_scale(actor),_facing(actor),late,Color.WHITE)

func play_status(event: Dictionary, actor: Node2D, age: float = 0.0) -> void:
	if reduced_motion or not is_instance_valid(actor): return
	var type := str(event.get("type",""))
	var status: Variant = event.get("status",{})
	var effect := str(event.get("effect",status.get("type","") if status is Dictionary else ""))
	var id := "charge_energy"
	var style := "mist"
	if type=="heal": style="heal"
	elif type in ["shield","defensive_stance"] or effect=="shield": style="shield"
	elif type in ["status_tick","status_applied"]:
		style="poison" if effect=="poison" else "embers" if effect=="burn" else "mist"
	elif type=="ability" and str(event.get("ability_id",""))=="phase_shift":
		id="transformation"
		style="embers"
	elif type!="ability": return
	_emit(id,_anchor(actor,"chest"),_actor_scale(actor),_facing(actor),age,Color.WHITE,actor,"chest",style)

func _process(delta: float) -> void:
	if is_inside_tree() and get_tree().has_meta("brasa_reduced_motion"): reduced_motion = bool(get_tree().get_meta("brasa_reduced_motion"))
	if reduced_motion:
		if not _effects.is_empty() or not _pending.is_empty() or _shake_duration > 0: clear()
		return
	if motion_paused: return
	if _effects.is_empty() and _pending.is_empty() and _shake_age >= _shake_duration: return
	delta=maxf(0,_number(delta,0))
	for index in range(_effects.size()-1,-1,-1):
		_effects[index].age += delta
		if float(_effects[index].age) >= float(_effects[index].duration): _effects.remove_at(index)
		else: _spawn(_effects[index])
	for index in range(_pending.size()-1,-1,-1):
		var item: Dictionary = _pending[index]
		var actor: Variant = item.actor.get_ref()
		if not is_instance_valid(actor):
			_pending.remove_at(index)
			continue
		item.age=float(item.age)+delta
		_dispatch_markers(item)
		if int(item.cursor)>=item.markers.size():
			_pending.remove_at(index)
			_remember_action(str(item.key))
	_shake_age += delta
	queue_redraw()

func camera_offset() -> Vector2:
	if reduced_motion or _shake_age >= _shake_duration: return Vector2.ZERO
	var envelope := 1.0-_shake_age/maxf(0.001,_shake_duration)
	return Vector2(sin(_shake_age*145),sin(_shake_age*113+0.6)*0.45)*_shake_strength*envelope

func _draw() -> void:
	if reduced_motion: return
	for item: Dictionary in _effects:
		for particle: Dictionary in item.particles:
			var sample := _sample(item,particle)
			if sample.is_empty(): continue
			if sample.kind=="spark": Ink.spark(self,sample.at,sample.velocity,sample.radius.x,sample.color,sample.length)
			else: Ink.mote(self,sample.at,sample.radius,sample.color,sample.velocity.angle())

func debug_state() -> Dictionary:
	var active: Array[Dictionary] = []
	for item: Dictionary in _effects:
		var particles: Array[Dictionary] = []
		for particle: Dictionary in item.particles:
			var sample := _sample(item,particle)
			if not sample.is_empty(): particles.append(sample)
		active.append({"id":item.id,"age":item.age,"at":item.at,"size":item.size,"style":item.style,"particles":particles})
	return {"active":active,"pending":_pending.size(),"markers":_marker_history.duplicate(true),"seen_actions":_seen_actions.size(),"particles":_particle_count(),"shake":camera_offset().length(),"paused":motion_paused,"reduced_motion":reduced_motion}
