extends Node2D
class_name FighterView
## Canonical packs use a fixed full canvas, origin and shared pixel density.
## Legacy packs remain compatible without changing combat clocks or game state.

const ATLAS_PATHS: Array[String] = ["res://assets/sprites/lince-v2.png", "res://assets/sprites/ajolote-v2.png", "res://assets/sprites/golem-v2.png"]
const POSE_NAMES: Array[String] = ["idle", "idle_breathe", "windup", "punch", "hit", "dodge", "victory", "defeat"]
const DISPLAY_HEIGHT: float = 166.0
const ALPHA_THRESHOLD: float = 0.12
const ProceduralFallback = preload("res://scripts/fighter_procedural.gd")
const AnimationSet = preload("res://scripts/fighter_animation_set.gd")
const VisualProfiles = preload("res://scripts/character_visual_profile.gd")
const Cosmetics = preload("res://scripts/cosmetic_catalog.gd")
const CosmeticParticles = preload("res://scripts/cosmetic_particles.gd")
const ParticleInk = preload("res://scripts/particle_ink.gd")
const DamageArt = preload("res://scripts/damage_art.gd")
const DamageState = preload("res://scripts/visual_damage_state.gd")
const AttachedEnergy = preload("res://scripts/attached_energy_track.gd")
const FLASH_SHADER: String = """
shader_type canvas_item;
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 variant_tint : source_color = vec4(1.0);
uniform float palette_strength : hint_range(0.0, 0.6) = 0.0;
uniform vec4 palette_primary : source_color = vec4(1.0);
uniform vec4 palette_secondary : source_color = vec4(1.0);
uniform vec4 palette_accent : source_color = vec4(1.0);
void fragment() {
	vec4 pixel = COLOR;
	pixel.rgb *= mix(vec3(1.0), variant_tint.rgb, 0.28);
	// Curated pigment grading, not a clothing mask. Keep luminosity, painted
	// texture, pale highlights and the original alpha of every atlas pose.
	float luminosity = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));
	float high = max(pixel.r, max(pixel.g, pixel.b));
	float low = min(pixel.r, min(pixel.g, pixel.b));
	float pigment = smoothstep(0.035, 0.24, high - low) * smoothstep(0.08, 0.30, high);
	float warm = smoothstep(-0.10, 0.16, pixel.r - pixel.b);
	vec3 ink = mix(palette_secondary.rgb, palette_primary.rgb, warm);
	ink = mix(ink, palette_accent.rgb, smoothstep(0.60, 0.92, luminosity) * 0.30);
	vec3 graded = ink * (luminosity / max(0.08, dot(ink, vec3(0.299, 0.587, 0.114))));
	pixel.rgb = mix(pixel.rgb, clamp(graded, vec3(0.0), vec3(1.0)), palette_strength * pigment);
	// Charge and transformation energy are separate aligned sprites. The base
	// texture is never uniformly relit or replaced by emissive color.
	pixel.rgb = mix(pixel.rgb, vec3(1.0, 0.94, 0.76), flash_amount);
	COLOR = pixel;
}
"""

static var _atlas_cache: Dictionary = {}
static var _shared_shader: Shader
static var _contact_serial := 0

var archetype: int = 0
var palette_color: Color = Color("e99a58")
var facing: int = 1
var visual_tint: Color = Color.WHITE
var reduced_motion: bool = false
var attached_fx_enabled: bool = true
var _attached_fx_gain := 0.0
var motion_paused: bool = false
var movement_height_limit: float = 58.0
var defensive_stance: bool = false
var appearance: Dictionary = {}
var identity: Dictionary = {}
var _cosmetics: Dictionary = {}
var _intro_elapsed: float = 10.0
var _move: Dictionary = {}
var _counter_move: Dictionary = {}
var _counter_time: float = 0.0
var _clock: float = 0.0
var _action_time: float = 0.0
var _mode: String = "idle"
var _critical: bool = false
var _pending_reaction: String = ""
var _pending_critical: bool = false
var _overlay_elapsed: float = 10.0
var _hit_flash_elapsed: float = 10.0
var _hit_flash_critical: bool = false
var _atlas: Dictionary = {}
var _visual_profile: Dictionary = {}
var _battle_result := ""
var _sequence_body := ""
var _sequences_enabled := false
var _sequence_idle_enabled := false
var _sequence_frame: Dictionary = {}
var _render_frame: Dictionary = {}
var _resolved_clean_texture: Texture2D
var _resolved_tier := -1
var _render_damage_tier := 0
var _animation_sample: Dictionary = {}
var _reaction_kind := "light"
var _deferred_reaction := ""
var _hit_stop_remaining := 0.0
var damage_state := DamageState.new()
var combat_lane_limit := INF
var _lane_shift := 0.0
var _combat_opponent: Node2D
var _contact_order := 0
var _contact_offset := 0.0
var _contact_target := Vector2.ZERO
var _contact_anchor_source := "none"
var _terminal_draw_x := INF
var _health_ratio := 1.0
var _form_id := ""
var _form_elapsed := 0.0
var _transform_elapsed := 10.0
var _transform_pending := false
var _recover_into_move := false
var _frame_index: int = -1
var _sprite: Sprite2D
var _attached_fx: Sprite2D
class CosmeticLayer extends Node2D:
	var fighter: Node2D
	func _draw() -> void:
		if is_instance_valid(fighter): fighter._draw_cosmetics(self)

var cosmetic_preview: bool = false
var _cosmetic_layer: CosmeticLayer
var _cosmetic_trail_energy: float = 0.0
var _trail: Sprite2D
var _flash_material: ShaderMaterial
var _fallback: Node2D


func _ready() -> void:
	# Advance existing gestures before Main synchronizes new engine events.
	# Otherwise a newly synchronized gesture consumes this frame twice.
	process_priority = -1
	_ensure_sprite_nodes()


func setup(kind: int, color: Color, look_direction: int = 1) -> void:
	appearance = {}
	identity = {}
	_cosmetics = {}
	_setup_visual(kind, color, look_direction, "")
	_apply_palette()


func _setup_visual(kind: int, color: Color, look_direction: int, atlas_path: String) -> void:
	archetype = clampi(kind, 0, 2)
	palette_color = color
	facing = 1 if look_direction >= 0 else -1
	defensive_stance = false
	_ensure_sprite_nodes()
	set_visual_tint(Color.WHITE)
	# Catalog overrides remain portable project assets. Missing/invalid overrides
	# retain the original species art, including for older saved descriptors.
	_atlas = _load_atlas(atlas_path) if _valid_atlas_path(atlas_path) else {}
	if _atlas.is_empty():
		_atlas = _load_atlas(ATLAS_PATHS[archetype])
	_sprite.visible = not _atlas.is_empty()
	_trail.visible = false
	_cosmetic_trail_energy = 0.0
	if _atlas.is_empty():
		# Allows development before the corresponding illustrated asset is installed.
		if not is_instance_valid(_fallback):
			_fallback = ProceduralFallback.new()
			add_child(_fallback)
		_fallback.setup(archetype, palette_color, facing)
	elif is_instance_valid(_fallback):
		remove_child(_fallback)
		_fallback.queue_free()
		_fallback = null
	_sequence_body = str(_atlas.get("body_id",AnimationSet.body_for_atlas(str(_atlas.get("path","")))))
	_visual_profile = VisualProfiles.profile(_sequence_body)
	damage_state.configure(_sequence_body)
	_sequences_enabled = AnimationSet.available(_sequence_body) if not _sequence_body.is_empty() else false
	reset_pose()


func setup_character(definition: Dictionary, look_direction: int = 1) -> void:
	# Appearance is descriptive only. Never rewrite the caller's identity,
	# archetype, statistics or battle snapshot when choosing another body.
	appearance = {}
	identity = definition.get("identity", {}).duplicate(true) if definition.get("identity", {}) is Dictionary else {}
	_cosmetics = {}
	var visual: Dictionary = definition.get("visual", {}).duplicate(true) if definition.get("visual", {}) is Dictionary else {}
	if definition.get("appearance") is Dictionary and not definition.appearance.is_empty():
		var fallback_id: String = str(definition.get("character_id", definition.get("id", "nima")))
		appearance = Cosmetics.normalize_appearance(definition.appearance, fallback_id)
		_cosmetics = Cosmetics.resolve(appearance)
		var body: Dictionary = _cosmetics.get("body_style", {})
		if body.get("visual") is Dictionary: visual = body.visual.duplicate(true)
	_setup_visual(int(visual.get("archetype", definition.get("archetype", 0))), palette_color, look_direction, str(visual.get("atlas", "")))
	set_visual_tint(Color(str(visual.get("tint", "ffffff"))))
	_apply_palette()
	play_intro()


func _apply_palette() -> void:
	if _flash_material == null: return
	var colors: Dictionary = Cosmetics.palette_colors(str(appearance.get("palette_id", "original")))
	_flash_material.set_shader_parameter("palette_strength", clampf(float(colors.get("strength", 0.0)), 0.0, 0.6))
	for channel: String in ["primary", "secondary", "accent"]:
		_flash_material.set_shader_parameter("palette_" + channel, colors.get(channel, Color.WHITE))


func play_intro() -> void:
	# Separate cosmetic clock: no move/counter timing or gameplay delay.
	_intro_elapsed = 0.0
	queue_redraw()


static func _valid_atlas_path(path: String) -> bool:
	return path.begins_with("res://assets/sprites/") and path.get_extension().to_lower() == "png" and not path.contains("..")


func set_visual_tint(color: Color) -> void:
	visual_tint = color
	if _flash_material != null:
		_flash_material.set_shader_parameter("variant_tint", color)
	if is_instance_valid(_fallback):
		_fallback.modulate = Color.WHITE.lerp(color, 0.28)


func play_attack(critical: bool = false) -> void:
	if _mode in ["fall","victory"]:
		return
	_sequence_idle_enabled = true
	_mark_contact_order()
	_start_action("attack", critical)
	if is_instance_valid(_fallback):
		_fallback.play_attack(critical)


func play_move(move: Dictionary, elapsed_offset: float = 0.0) -> void:
	if _mode in ["fall","victory"]:
		return
	_mark_contact_order()
	if bool(move.get("is_counter_reaction", false)) and _mode == "move" and _action_time < _move_duration():
		# A passive response can overlap a scheduled attack. Keep both clocks;
		# a brief response overlay must not erase the pending heavy windup.
		_counter_move = move.duplicate(true)
		_counter_time = maxf(0.0, elapsed_offset)
		_update_pose()
		return
	if _mode == "move" and bool(_move.get("is_counter_reaction", false)) and _action_time < _move_duration():
		_counter_move = _move.duplicate(true)
		_counter_time = _action_time
	_sequence_idle_enabled = true
	_recover_into_move = _mode == "reaction" and _reaction_kind in ["knockdown","getup"]
	_deferred_reaction = ""
	_move = move.duplicate(true)
	_start_action("move", bool(move.get("signature", false)))
	_action_time = maxf(0.0, elapsed_offset)
	_update_pose()
	if is_instance_valid(_fallback):
		_fallback.play_attack(_critical)


func move_impact(critical: bool = false, move_id: String = "") -> void:
	# The simulation sends contact after the anticipation, never another windup.
	if not _counter_move.is_empty() and str(_counter_move.get("id", "")) == move_id:
		_mark_contact_order()
		_counter_time = maxf(_counter_time, float(_counter_move.get("impact_delay", 0.13)))
		_update_pose()
		return
	if _mode != "move":
		return
	if not move_id.is_empty() and str(_move.get("id", "")) != move_id:
		return
	_mark_contact_order()
	_critical = critical
	_action_time = maxf(_action_time, _impact_time())
	_update_pose()


func _impact_time() -> float:
	return maxf(0.01, float(_move.get("windup", 0.12)) + float(_move.get("travel", 0.10)))


func _move_duration() -> float:
	return _impact_time() + maxf(0.06, float(_move.get("recovery", 0.20)))


func play_hit(critical: bool = false) -> void:
	if _mode in ["fall","victory"]:
		return
	_hit_flash_elapsed = 0.0
	_hit_flash_critical = critical
	_request_reaction("hit", critical)
	if is_instance_valid(_fallback):
		_fallback.play_hit(critical)


func play_dodge() -> void:
	if _mode in ["fall","victory"]:
		return
	_request_reaction("dodge")
	if is_instance_valid(_fallback):
		_fallback.play_dodge()


func resolve_battle(won: bool) -> void:
	# Only the terminal engine/replay event calls this API. KO always wins,
	# including when a late status event arrives after a result presentation.
	if _mode=="fall" or not won:
		_battle_result="defeat"
		fall()
		return
	_battle_result="victory"
	celebrate()


func preview_victory() -> void:
	# Explicitly cosmetic: Story/customization previews are not live matches.
	if _mode=="fall": return
	_battle_result="preview"
	celebrate()


func celebrate() -> void:
	if _mode in ["fall","victory"] or _battle_result not in ["victory","preview"]: return
	_hit_stop_remaining = 0.0
	_start_action("victory")
	if is_instance_valid(_fallback):
		_fallback.celebrate()


func fall() -> void:
	if _mode == "fall": return
	_battle_result="defeat"
	_form_id=""
	_transform_pending=false
	_hit_stop_remaining = 0.0
	_start_action("fall")
	if is_instance_valid(_fallback):
		_fallback.fall()


func reset_pose() -> void:
	_render_frame = {}
	_render_damage_tier = 0
	_terminal_draw_x = INF
	damage_state.reset()
	_battle_result=""
	_hit_stop_remaining = 0.0
	_form_id = ""
	_form_elapsed = 0.0
	_transform_pending = false
	_transform_elapsed = 10.0
	_health_ratio = 1.0
	_sequence_idle_enabled = false
	_deferred_reaction = ""
	_recover_into_move = false
	_start_action("idle")
	if is_instance_valid(_fallback):
		_fallback.reset_pose()


func _start_action(mode: String, critical: bool = false) -> void:
	if mode in ["fall", "victory"] and _has_combat_opponent() and not reduced_motion and not is_zero_approx(_contact_offset):
		# A finishing blow can interrupt an extended strike. Land where it happened,
		# rather than snapping the winner or fallen body back to its neutral lane.
		_terminal_draw_x = _sprite.position.x
	_mode = mode
	_action_time = 0.0
	_critical = critical
	_pending_reaction = ""
	_overlay_elapsed = 10.0
	if mode in ["idle", "victory", "fall"]:
		if mode == "idle": _contact_order = 0
		_deferred_reaction = ""
		_hit_flash_elapsed = 10.0
		_counter_move = {}
	_update_pose()
	queue_redraw()


func _request_reaction(reaction: String, critical: bool = false) -> void:
	if _mode=="reaction" and _reaction_kind in ["knockdown","getup"]:
		# Additional damage can flash a fallen body; it cannot teleport it upright.
		_update_pose()
		return
	if (_mode == "attack" and _action_time < 0.36) or (_mode == "move" and _action_time < _impact_time() + 0.06):
		# Both combatants can attack within the same contact window. Keep the
		# outgoing punch visible; receiving an impact must not erase its windup.
		_pending_reaction = reaction
		_pending_critical = critical
		_overlay_elapsed = 0.0
		_update_pose()
		queue_redraw()
	else:
		_start_action(reaction, critical)


func _ensure_sprite_nodes() -> void:
	if is_instance_valid(_sprite):
		return
	_trail = Sprite2D.new()
	_trail.name = "AttackTrail"
	_trail.centered = false
	_trail.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_trail.visible = false
	add_child(_trail)
	_sprite = Sprite2D.new()
	_sprite.name = "IllustratedFighter"
	_sprite.centered = false
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_sprite)
	_attached_fx = Sprite2D.new()
	_attached_fx.name = "AttachedFighterFX"
	_attached_fx.centered = false
	_attached_fx.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_attached_fx.visible = false
	add_child(_attached_fx)
	_cosmetic_layer = CosmeticLayer.new()
	_cosmetic_layer.name = "CosmeticParticles"
	_cosmetic_layer.fighter = self
	add_child(_cosmetic_layer)
	if _shared_shader == null:
		_shared_shader = Shader.new()
		_shared_shader.code = FLASH_SHADER
	_flash_material = ShaderMaterial.new()
	_flash_material.shader = _shared_shader
	_flash_material.set_shader_parameter("variant_tint", visual_tint)
	_sprite.material = _flash_material


func _process(delta: float) -> void:
	if motion_paused:
		return
	if is_inside_tree() and get_tree().has_meta("brasa_reduced_motion"):
		reduced_motion = bool(get_tree().get_meta("brasa_reduced_motion"))
	damage_state.advance(delta, _mode in ["hit", "reaction"] or not _pending_reaction.is_empty(), _mode in ["fall", "victory"])
	_cosmetic_trail_energy = maxf(0, _cosmetic_trail_energy - delta * 1.8)
	_clock += delta
	_intro_elapsed += delta
	_action_time += delta
	_overlay_elapsed += delta
	_hit_flash_elapsed += delta
	_hit_stop_remaining = maxf(0.0,_hit_stop_remaining-delta)
	if not _form_id.is_empty():
		_form_elapsed += delta
		if _form_elapsed >= float(AnimationSet.transformation(_sequence_body,_form_id).get("lifetime",8.0)):
			_form_id = ""
			_transform_pending = false
	if not _counter_move.is_empty():
		_counter_time += delta
		if _counter_time >= float(_counter_move.get("duration", 0.28)): _counter_move = {}
	if _mode == "attack" and _action_time >= 0.36 and not _pending_reaction.is_empty():
		_mode = _pending_reaction
		_critical = _pending_critical
		_action_time -= 0.36
		_pending_reaction = ""
	if (_mode == "attack" and _action_time >= 0.55) or (_mode == "hit" and _action_time >= 0.4) or (_mode == "dodge" and _action_time >= 0.5):
		_mode = "idle"
	if _mode == "reaction" and _action_time >= float(AnimationSet.REACTION_CLIPS.get(_reaction_kind,AnimationSet.REACTION_CLIPS.light).duration):
		_mode = "idle"
	if _mode == "move" and _action_time >= _move_duration():
		var surplus := _action_time-_move_duration()
		_mode = "idle"
		_pending_reaction = ""
		if not _deferred_reaction.is_empty():
			_reaction_kind = _deferred_reaction
			_deferred_reaction = ""
			_mode = "reaction"
			_action_time = surplus
	if _mode == "idle" and not _form_id.is_empty():
		if _transform_pending:
			_transform_pending = false
			_transform_elapsed = 0.0
		else: _transform_elapsed += delta
	_update_pose()
	if _hit_stop_remaining <= 0: queue_redraw()


func _ease(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _update_pose() -> void:
	if _hit_stop_remaining > 0 and not reduced_motion: return
	if _atlas.is_empty() or not is_instance_valid(_sprite):
		return
	var pose: int = int(floor(_clock / 0.6)) % 2
	if _mode == "idle" and defensive_stance: pose = 5
	var offset := Vector2(0.0, -absf(sin(_clock * 2.6)) * 1.1)
	var rotation_amount: float = 0.0
	var flash: float = maxf(0.0, 1.0 - _hit_flash_elapsed / 0.17) * (0.34 if _hit_flash_critical else 0.20)
	var trail_opacity: float = 0.0
	match _mode:
		"move":
			var movement: Dictionary = _move_pose()
			pose = int(movement.pose)
			offset = movement.offset
			rotation_amount = float(movement.rotation)
			trail_opacity = float(movement.trail)
		"attack":
			if _action_time < 0.15:
				pose = 2
				offset.x = -5.0 * _ease(_action_time / 0.15)
			elif _action_time < 0.36:
				pose = 3
				var extension := _ease((_action_time - 0.15) / 0.075)
				offset.x = lerpf(-5.0, 16.0 if _critical else 11.0, extension)
				trail_opacity = maxf(0.0, 1.0 - (_action_time - 0.15) / 0.17) * 0.19
			else:
				pose = 2
				offset.x = (7.0 if _critical else 4.0) * (1.0 - _ease((_action_time - 0.36) / 0.19))
		"reaction":
			pose = 4
			var duration := float(AnimationSet.REACTION_CLIPS.get(_reaction_kind,AnimationSet.REACTION_CLIPS.light).duration)
			var recoil := sin(clampf(_action_time/duration,0,1)*PI)
			offset.x = -recoil*(26.0 if _reaction_kind in ["knockback","knockdown"] else (17.0 if _reaction_kind in ["heavy","critical"] else 8.0))
			rotation_amount = -recoil*0.05
		"hit":
			pose = 4
			var recoil := sin(clampf(_action_time / 0.4, 0.0, 1.0) * PI)
			offset.x = -recoil * (14.0 if _critical else 8.0)
			rotation_amount = -recoil * 0.045
		"dodge":
			pose = 5
			offset = Vector2(-11.0 * sin(clampf(_action_time / 0.5, 0.0, 1.0) * PI), 0.0)
		"victory":
			pose = 6
			offset = Vector2(0.0, -absf(sin(_action_time * 4.0)) * 7.5)
			rotation_amount = sin(_action_time * 4.0) * 0.014
			if str(appearance.get("victory_pose_id", "classic")) == "saludo":
				# One modest bow, then the existing illustrated victory pose.
				var bow: float = sin(clampf(_action_time / 0.65, 0.0, 1.0) * PI)
				pose = 1 if _action_time < 0.65 else 6
				offset = Vector2(0.0, bow * 3.0)
				rotation_amount = bow * 0.055
			elif str(appearance.get("victory_pose_id", "classic")) in ["serena", "festival"]:
				offset = Vector2.ZERO
				rotation_amount = 0.0
		"fall":
			pose = 7
			offset = Vector2(-8.0 * _ease(_action_time / 0.28), 0.0)
	# This greeting only decorates idle. A real attack interrupts it immediately.
	if _mode == "idle" and str(appearance.get("intro_animation_id", "classic")) == "reverencia" and _intro_elapsed < 0.9:
		var bow: float = sin(clampf(_intro_elapsed / 0.9, 0, 1) * PI)
		offset.y = bow * 2.5
		rotation_amount = bow * 0.035
	if _mode in ["attack", "move"] and not _pending_reaction.is_empty():
		# An independent overlay responds immediately without resetting attack
		# time. The illustrated hit/crouch pose follows the full punch at 0.36 s.
		var reaction_length: float = 0.4 if _pending_reaction == "hit" else 0.5
		var overlay_recoil := sin(clampf(_overlay_elapsed / reaction_length, 0.0, 1.0) * PI)
		offset.x -= overlay_recoil * (7.0 if _pending_critical else 5.0)
		rotation_amount -= overlay_recoil * 0.025
	if not _counter_move.is_empty():
		var counter_impact: float = float(_counter_move.get("impact_delay", 0.13))
		if _counter_time >= float(_counter_move.get("windup", 0.05)) and _counter_time <= counter_impact + 0.06:
			pose = 3
			offset.x += 8.0
			trail_opacity = 0.14
	if reduced_motion:
		offset = Vector2.ZERO
		rotation_amount = 0.0
		trail_opacity = 0.0
		flash = 0.0
		if _mode == "idle": pose = 0
	_set_pose_frame(pose,false)
	_apply_sequence_frame(pose)
	_resolve_render_frame(true)
	var base_scale: float = float(_current_frame().get("scale",_atlas["scale"]))
	if not _sequence_frame.is_empty() and not bool(_sequence_frame.get("normalized",false)) and str(_sequence_frame.name) in ["jump_apex","jump_strike","jump_fall"]:
		# A drawn airborne pivot already contains height; do not add the same lift twice.
		var intrinsic_lift := maxf(0.0,(Vector2(_sequence_frame.anchor).y-Rect2i(_sequence_frame.bounds).end.y)*base_scale)
		if offset.y<0: offset.y=-maxf(0.0,-offset.y-intrinsic_lift)
	_sprite.scale = Vector2(float(facing), 1.0) * base_scale
	_sprite.position = Vector2(offset.x * facing, offset.y)
	_lane_shift = 0.0
	_sprite.rotation = rotation_amount * facing
	_flash_material.set_shader_parameter("flash_amount", flash)
	_constrain_combat_lane()
	_update_contact_depth()
	_update_attached_fx()
	_trail.visible = trail_opacity > 0.0
	if _trail.visible:
		_trail.texture = _sprite.texture
		_trail.offset = _sprite.offset
		_trail.scale = _sprite.scale
		_trail.rotation = _sprite.rotation
		_trail.position = _sprite.position - Vector2(11.0 * facing, 0.0)
		var trail_definition: Dictionary = _cosmetics.get("trail", {})
		var trail_color := Color(str(trail_definition.get("color", "ffe8b8"))) if str(appearance.get("trail_id", "none")) != "none" else Color("ffe8b8")
		trail_color.a = trail_opacity
		_trail.modulate = trail_color
		_cosmetic_trail_energy = 1.0
	if is_instance_valid(_cosmetic_layer): _cosmetic_layer.queue_redraw()


func set_combat_lane(limit: float, opponent: Node2D = null) -> void:
	combat_lane_limit = maxf(0.0, limit)
	_combat_opponent = opponent if opponent != self and opponent is FighterView else null
	_constrain_combat_lane()
	_update_contact_depth()
	_update_attached_fx()
	queue_redraw()

func painted_bounds_local() -> Rect2:
	if not is_instance_valid(_sprite) or _sprite.texture == null: return Rect2()
	var current := _current_frame()
	var bounds := Rect2(current.get("bounds", Rect2i()))
	var first := _sprite.transform * (bounds.position + _sprite.offset)
	var result := Rect2(first, Vector2.ZERO)
	for point: Vector2 in [Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)]:
		result = result.expand(_sprite.transform * (point + _sprite.offset))
	return result

func _constrain_combat_lane() -> void:
	if not is_finite(combat_lane_limit) or not is_instance_valid(_sprite): return
	_sprite.position.x -= _lane_shift
	_lane_shift = 0.0
	_contact_offset = 0.0
	_contact_anchor_source = "none"
	var bounds := painted_bounds_local()
	var inward := bounds.end.x if facing > 0 else -bounds.position.x
	var rest_shift := -float(facing) * maxf(0.0, inward - combat_lane_limit)
	_lane_shift = rest_shift
	var contact := _contact_motion()
	if _has_combat_opponent() and not reduced_motion and float(contact.weight) > 0.0:
		# Aim at the opponent's neutral torso, never its already translated sprite.
		# Both fighters can strike concurrently without chasing each other's offset.
		_contact_target = _combat_opponent.to_global(_combat_opponent._neutral_torso_local())
		var target := to_local(_contact_target)
		var reach := _strike_reach(str(contact.clip))
		var shift := target.x + facing * 8.0 - reach
		# Keep each body on its own side when both attacks overlap. This limit uses
		# neutral anatomy/roots, not painted tails, current recoil or opponent shifts.
		var own_center := _neutral_torso_local(false)
		var other_center := to_local(_combat_opponent.to_global(_combat_opponent._neutral_torso_local(false)))
		var simultaneous := float(_combat_opponent._contact_motion().weight)
		var center_limit := lerpf(absf(other_center.x-own_center.x)*0.82, maxf(0.0,absf(other_center.x-own_center.x)*0.5-10.0), simultaneous)
		var advance := (shift + _sprite.position.x) * facing
		shift -= facing * maxf(0.0, advance-center_limit)
		# Existing outer-edge clearance remains valid: contact only moves inward
		# from the conservative lane placement, never farther toward the viewport.
		shift = facing * maxf(rest_shift*facing, shift*facing)
		_lane_shift = lerpf(rest_shift, shift, float(contact.weight))
		_contact_offset = _lane_shift-rest_shift
	elif _mode in ["fall", "victory"] and is_finite(_terminal_draw_x) and not reduced_motion:
		_lane_shift = facing * maxf(rest_shift*facing, (_terminal_draw_x-_sprite.position.x)*facing)
	_sprite.position.x += _lane_shift

func _has_combat_opponent() -> bool:
	return is_instance_valid(_combat_opponent) and _combat_opponent.get_parent() == get_parent() and not _combat_opponent._atlas.is_empty()

func _neutral_torso_local(front: bool = true) -> Vector2:
	var neutral: Dictionary = _atlas.frames[0]
	var density := float(neutral.get("scale", _atlas.scale))
	var anchor := Vector2(neutral.anchor)
	var anatomy: Dictionary = _visual_profile.get("canonical_anatomy_2d", {})
	var raw: Array = anatomy.get("torso_bbox_px", [])
	var point := Vector2(18.0 if front else 0.0, -92.0)
	if raw.size() == 4:
		# Aim inside the front third: the guard/receiving pose must visibly overlap
		# the fist, rather than merely touch the edge of its neutral bounding box.
		point = (Vector2(float(raw[0])+float(raw[2])*(0.65 if front else 0.5), float(raw[1])+float(raw[3])*0.5)-anchor)*density
	var neutral_bounds := Rect2(neutral.bounds)
	var neutral_front := (neutral_bounds.end.x-anchor.x)*density
	point.x = (point.x-maxf(0.0, neutral_front-combat_lane_limit))*facing
	return point

func _strike_reach(clip: String) -> float:
	# A fixed strike reference avoids pulling the body forward again when the
	# illustrated arm retracts. The whole canvas and species scale stay unchanged.
	var frame := AnimationSet.frame(_sequence_body, "jump_strike" if clip == "jump" else "quick_extend")
	if frame.is_empty(): frame = _atlas.frames[3]
	frame = DamageArt.resolve_frame(_sequence_body,_render_damage_tier,frame)
	var sockets: Dictionary = frame.get("sockets_px", {})
	var hand: Variant = sockets.get("hand")
	if hand is Array: hand = VisualProfiles.point(hand)
	var point: Vector2
	if hand is Vector2:
		point = hand + Vector2(9.0, 0.0)
		_contact_anchor_source = "authored_hand"
		if bool(frame.get("damage_art",false)) and str(frame.get("socket_annotation_method","")).to_lower().contains("approximate"):
			_contact_anchor_source = "illustrated_hand_approximate"
	else:
		# Unannotated packs use the strike's painted forward edge only as visual
		# reach. It is not an anatomical socket, collider, hitbox or scaling rule.
		var bounds := Rect2(frame.bounds)
		point = Vector2(bounds.end.x, bounds.get_center().y)
		_contact_anchor_source = "painted_strike_edge"
	var local := (point-Vector2(frame.anchor))*float(frame.get("scale",_atlas.scale))
	local.x *= facing
	return local.rotated(_sprite.rotation).x + _sprite.position.x

func _contact_sample(move: Dictionary, elapsed: float) -> Dictionary:
	var sample := AnimationSet.phase_sample(move, elapsed)
	var result := {"weight":0.0, "phase":str(sample.phase), "clip":str(sample.clip)}
	if sample.clip == "guard": return result
	var windup := maxf(0.01,float(move.get("windup",0.12)))
	var travel := maxf(0.0,float(move.get("travel",0.10)))
	var recovery := maxf(0.06,float(move.get("recovery",0.20)))
	var hold := minf(0.06,recovery*0.25)
	if elapsed < windup: return result
	if elapsed < windup+travel:
		result.weight = _ease((elapsed-windup)/maxf(0.001,travel))
	else:
		result.weight = 1.0-_ease((elapsed-windup-travel-hold)/maxf(0.001,recovery-hold))
		if elapsed < windup+travel+hold: result.phase = "contact"
	return result

func _contact_motion() -> Dictionary:
	var result := {"weight":0.0,"phase":"rest","clip":"quick"}
	if _mode == "move": result = _contact_sample(_move,_action_time)
	elif _mode == "attack": result = _contact_sample({"windup":0.15,"travel":0.21,"recovery":0.19},_action_time)
	if not _counter_move.is_empty():
		var counter := _contact_sample(_counter_move,_counter_time)
		if float(counter.weight) >= float(result.weight): result = counter
	return result

func _mark_contact_order() -> void:
	_contact_serial += 1
	_contact_order = _contact_serial

func _update_contact_depth() -> void:
	if not _has_combat_opponent(): return
	var own_active := float(_contact_motion().weight) > 0.01
	var other_active := float(_combat_opponent._contact_motion().weight) > 0.01
	var front: Node2D = self if facing < 0 else _combat_opponent
	if own_active and (not other_active or _contact_order > int(_combat_opponent._contact_order)): front = self
	elif other_active: front = _combat_opponent
	elif _mode in ["fall", "victory"] or _combat_opponent._mode in ["fall", "victory"]:
		if _contact_order != int(_combat_opponent._contact_order):
			front = self if _contact_order > int(_combat_opponent._contact_order) else _combat_opponent
		if _mode == "victory": front = self
		elif _combat_opponent._mode == "victory": front = _combat_opponent
	# Reorder only the pair, beneath arena FX/HUD. Raising z_index would also
	# put fighters above unrelated overlays outside their parent.
	var index := maxi(get_index(), _combat_opponent.get_index())
	if front.get_index() != index:
		var back: Node2D = _combat_opponent if front == self else self
		var back_index := front.get_index()
		get_parent().move_child(front,index)
		get_parent().move_child(back,back_index)

func get_contact_state() -> Dictionary:
	var contact := _contact_motion()
	return {"paired":_has_combat_opponent(), "active":_has_combat_opponent() and float(contact.weight)>0.0, "weight":contact.weight, "phase":contact.phase, "offset":Vector2(_contact_offset,0), "target":_contact_target, "anchor_source":_contact_anchor_source}

func _resolve_render_frame(reuse_cached: bool = false) -> void:
	var desired := damage_state.tier
	# Never replace an illustrated strike reference halfway through contact.
	# State continues to observe HP; only the artwork waits for recovery to end.
	if desired>=2 and _render_damage_tier<2 and float(_contact_motion().weight)>0.0:
		desired = 1
	var clean := _clean_frame()
	if reuse_cached and not _render_frame.is_empty() and _resolved_clean_texture == clean.get("texture") and _resolved_tier == desired:
		return
	_render_frame = DamageArt.resolve_frame(_sequence_body,desired,clean)
	_resolved_clean_texture = clean.get("texture")
	# Unavailable art is retried, so an art pipeline completed in-session appears.
	_resolved_tier = desired if desired < 2 or bool(_render_frame.get("damage_art",false)) else -1
	_render_damage_tier = desired if bool(_render_frame.get("damage_art",false)) else mini(desired,1)
	_sprite.texture = _render_frame.texture
	_sprite.offset = -Vector2(_render_frame.anchor) if bool(_render_frame.get("normalized",false)) else Vector2(Rect2(_render_frame.bounds).position)-Vector2(_render_frame.anchor)


func _move_pose() -> Dictionary:
	var kind: String = str(_move.get("animation", _move.get("animation_type", _move.get("type", "quick"))))
	var path: Dictionary = _move.get("movement", {}) if _move.get("movement", {}) is Dictionary else {}
	if kind == "jump": kind = str(path.get("kind", "jump_down"))
	var windup: float = maxf(0.01, float(_move.get("windup", 0.12)))
	var travel: float = maxf(0.01, float(_move.get("travel", 0.10)))
	var impact: float = windup + travel
	var preparation: float = _ease(_action_time / windup)
	var flight: float = clampf((_action_time - windup) / travel, 0.0, 1.0)
	var recovery: float = _ease((_action_time - impact) / maxf(0.06, float(_move.get("recovery", 0.20))))
	var striking: bool = _action_time >= windup and _action_time < impact + 0.075
	var offset := Vector2.ZERO
	var angle: float = 0.0
	var pose: int = 3 if striking else 2
	var trail: float = 0.0
	var extension: float = 12.0
	if kind.begins_with("jump"):
		# A high descending blow, a low forward kick, and a curved vault have
		# different silhouettes and flight arcs while sharing contact timing.
		var height: float = 45.0 if kind in ["jump", "jump_down", "jump-slam"] else 31.0
		if kind in ["jump_over", "jump-vault", "jump_arc"]: height = 53.0
		extension = 34.0 if kind in ["jump_forward", "jump-forward", "jump-kick"] else 26.0
		height = clampf(float(path.get("height", height)), 10.0, 58.0)
		height = minf(height, movement_height_limit)
		extension = clampf(float(path.get("distance", extension)), 8.0, 42.0)
		if _action_time < windup:
			offset = Vector2(-3.0 * preparation, 4.0 * preparation)
			pose = 5
		elif _action_time < impact:
			offset = Vector2(extension * _ease(flight), -sin(flight * PI) * height)
			pose = 2 if flight < 0.35 else 3
			angle = (-0.09 + flight * 0.20) if kind in ["jump_over", "jump-vault", "jump_arc"] else flight * 0.06
		else:
			offset = Vector2(extension * (1.0 - recovery), sin(recovery * PI) * 3.0)
			pose = 3 if _action_time < impact + 0.065 else (5 if recovery < 0.55 else 2)
		trail = sin(flight * PI) * 0.12 if _action_time < impact else 0.0
	elif kind in ["guard", "defense", "counter", "stance"]:
		pose = 5
		offset.x = -5.0 * (1.0 - recovery)
	elif kind == "charge":
		var retreat: float = clampf(absf(float(path.get("retreat", 19.0))), 8.0, 24.0)
		var distance: float = clampf(float(path.get("distance", 39.0)), 14.0, 42.0)
		if _action_time < windup:
			offset.x = -retreat * _ease(minf(1.0, _action_time / (windup * 0.45)))
			angle = -0.06 * preparation
		else:
			offset.x = lerpf(-retreat, distance, _ease(flight)) * (1.0 - recovery)
			angle = 0.08 * (1.0 - recovery)
			trail = (1.0 - recovery) * 0.22 if flight > 0.1 else 0.0
	elif kind == "dash":
		offset.x = clampf(float(path.get("distance", 38.0)), 12.0, 42.0) * _ease(flight) * (1.0 - recovery)
		angle = 0.10 * sin(flight * PI)
		trail = 0.24 * (1.0 - recovery) if striking else 0.0
	elif kind in ["heavy", "signature"]:
		var force: float = 1.3 if kind == "signature" else 1.0
		offset.x = (-11.0 * preparation if _action_time < windup else lerpf(-11.0, 26.0, _ease(flight)) * (1.0 - recovery)) * force
		angle = (-0.10 * preparation if _action_time < windup else 0.08 * (1.0 - recovery))
		trail = 0.28 * (1.0 - recovery) if striking else 0.0
	else:
		offset.x = -3.0 * preparation if _action_time < windup else 14.0 * _ease(flight) * (1.0 - recovery)
		trail = 0.12 * (1.0 - recovery) if striking else 0.0
	return {"pose": pose, "offset": offset, "rotation": angle, "trail": trail}


func _set_pose_frame(index: int, apply_texture: bool = true) -> void:
	_sequence_frame = {}
	if not apply_texture:
		_frame_index = index
		return
	_render_frame = {}
	if _frame_index == index and _sprite.texture == _atlas["frames"][index]["texture"]:
		return
	_frame_index = index
	var frame: Dictionary = _atlas["frames"][index]
	_sprite.texture = frame["texture"]
	_sprite.offset = -Vector2(frame["anchor"]) if bool(frame.get("normalized",false)) else Vector2(frame["bounds"].position) - frame["anchor"]


func prepare_combat_animation() -> void:
	# Explicit preflight for the two visible fighters only; portraits stay lazy.
	# Loading resources must not start an animation or change the current frame.
	if _sequence_body.is_empty(): return
	AnimationSet.frame(_sequence_body,"guard_shift")
	AnimationSet.frame(_sequence_body,"light_hit")
	DamageArt.prepare(_sequence_body)


func set_health_ratio(ratio: float) -> void:
	var next_ratio := clampf(ratio,0,1) if is_finite(ratio) else 1.0
	if _health_ratio == next_ratio: return
	_health_ratio = next_ratio
	damage_state.observe_health(_health_ratio)
	_update_pose()


func observe_combat_health(event: Dictionary, side: String, maximum: float) -> void:
	# Per-event minima survive a heal in the same engine batch. This never writes HP.
	if not side in ["player","rival"] or not is_finite(maximum) or maximum<=0.0: return
	var value: Variant = event.get(side+"_hp")
	if not (value is int or value is float) or not is_finite(float(value)): return
	damage_state.observe_health(float(value)/maximum)


func prepare_reaction_event(event: Dictionary, elapsed_offset: float = 0.0) -> Dictionary:
	# Authoritative attack events carry an ID, while move_started supplied the
	# presentation definition. Join them only on that ID, without editing either.
	var prepared := event.duplicate(true)
	prepared["presentation_elapsed"] = maxf(0.0,elapsed_offset) if is_finite(elapsed_offset) else 0.0
	if event.has("move"): return prepared
	var move_id: Variant = event.get("move_id")
	if not move_id is String or move_id.is_empty(): return prepared
	for candidate: Dictionary in [_counter_move,_move]:
		if not candidate.is_empty() and candidate.get("id") == move_id:
			prepared["move"] = candidate.duplicate(true)
			break
	return prepared


func play_reaction(event: Dictionary) -> Dictionary:
	damage_state.observe_event(event)
	var presentation := AnimationSet.reaction_for(event)
	var offset := maxf(0.0,float(event.get("presentation_elapsed",0.0)))
	if not is_finite(offset): offset = 0.0
	presentation.hit_stop = maxf(0.0,float(presentation.hit_stop)-offset)
	var kind := str(presentation.reaction)
	if _mode=="fall": return presentation
	# A terminal KO must interrupt even a displayed victory.
	if _mode=="victory" and kind!="ko": return presentation
	if kind == "miss": return presentation
	if kind == "dodge":
		play_dodge()
		if _mode == "dodge": _action_time = offset
		else: _overlay_elapsed = offset
		_update_pose()
		return presentation
	if kind == "ko":
		fall()
		_action_time = offset
		_update_pose()
		return presentation
	var critical := str(event.get("result","")) in ["critical","signature"] or bool(event.get("signature",false))
	_hit_flash_elapsed = offset
	_hit_flash_critical = critical
	if _mode=="reaction" and _reaction_kind in ["knockdown","getup"]:
		_update_pose()
		queue_redraw()
		return presentation
	_reaction_kind = kind
	_sequence_idle_enabled = true
	if (_mode=="move" and _action_time<_move_duration()) or (_mode=="attack" and _action_time<0.36):
		# Keep authoritative outgoing action intact; react immediately through recoil/flash.
		_pending_reaction = "hit"
		_pending_critical = critical
		_overlay_elapsed = offset
		_deferred_reaction = kind if _mode=="move" else ""
	else:
		_start_action("reaction",critical)
		_action_time = offset
	_update_pose()
	queue_redraw()
	return presentation


func request_hit_stop(duration: float) -> void:
	if reduced_motion or not is_finite(duration) or _mode=="fall": return
	_hit_stop_remaining = maxf(_hit_stop_remaining,clampf(duration,0,0.10))


func play_transformation(id: String = "ember_core", active: bool = true) -> bool:
	if not active:
		_form_id = ""
		_transform_pending = false
		_update_pose()
		return true
	if _mode in ["fall","victory"] or AnimationSet.transformation(_sequence_body,id).is_empty(): return false
	if AnimationSet.frame(_sequence_body,"transform_peak").is_empty(): return false
	if _form_id == id: return true
	_form_id = id
	_form_elapsed = 0.0
	_transform_elapsed = 0.0
	_transform_pending = _mode != "idle"
	_update_pose()
	return true


func _apply_sequence_frame(semantic_pose: int) -> void:
	_animation_sample = {"clip":_mode,"phase":"rest","frame":POSE_NAMES[semantic_pose]}
	if not _sequences_enabled and _mode!="reaction": return
	var selected := ""
	match _mode:
		"move":
			_animation_sample = AnimationSet.phase_sample(_move,_action_time)
			selected = str(_animation_sample.frame)
			if _recover_into_move and str(_animation_sample.phase)=="windup" and float(_animation_sample.progress)<0.40: selected="getup_rise"
		"attack":
			_animation_sample = AnimationSet.phase_sample({"windup":0.15,"travel":0.21,"recovery":0.19},_action_time)
			selected = str(_animation_sample.frame)
		"reaction":
			var clip: Dictionary = AnimationSet.REACTION_CLIPS.get(_reaction_kind,AnimationSet.REACTION_CLIPS.light)
			selected = AnimationSet.sample(clip.frames,_action_time/float(clip.duration))
			_animation_sample.clip = _reaction_kind
			_animation_sample.phase = "reaction"
		"hit": selected=AnimationSet.sample(AnimationSet.REACTION_CLIPS.critical.frames if _critical else AnimationSet.REACTION_CLIPS.light.frames,_action_time/0.4)
		"dodge": selected=AnimationSet.sample(["step_back","guard_settle","recovery"],_action_time/0.5)
		"fall":
			if _action_time<float(AnimationSet.REACTION_CLIPS.ko.duration): selected=AnimationSet.sample(AnimationSet.REACTION_CLIPS.ko.frames,_action_time/float(AnimationSet.REACTION_CLIPS.ko.duration))
			elif bool(_atlas.get("normalized",false)): selected="grounded"
			_animation_sample.clip="ko"
		"victory":
			var salute := str(appearance.get("victory_pose_id","classic"))=="saludo"
			if str(appearance.get("victory_pose_id","classic")) in ["serena","festival"]: selected="victory_peak"
			elif not salute and _action_time<float(AnimationSet.REACTION_CLIPS.victory.duration): selected=AnimationSet.sample(AnimationSet.REACTION_CLIPS.victory.frames,_action_time/float(AnimationSet.REACTION_CLIPS.victory.duration))
			elif bool(_atlas.get("normalized",false)): selected="victory_peak"
		"idle":
			if defensive_stance: selected="guard_settle"
			elif not _form_id.is_empty():
				var transformation: Dictionary = AnimationSet.REACTION_CLIPS.transformation
				selected=AnimationSet.sample(transformation.frames,_transform_elapsed/float(transformation.duration)) if _transform_elapsed<float(transformation.duration) else "transformed_idle"
				_animation_sample.clip="transformation" if _transform_elapsed<float(transformation.duration) else "transformed_idle"
			elif damage_state.tier >= 1: selected="low_health"
			elif not bool(_atlas.get("normalized",false)) and _sequence_idle_enabled and int(floor(_clock/0.6))%4==2: selected="guard_shift"
	if not _counter_move.is_empty() and _counter_time>=float(_counter_move.get("windup",0.05)) and _counter_time<=float(_counter_move.get("impact_delay",0.13))+0.06:
		selected="quick_extend"
		_animation_sample.phase="counter_overlay"
	if reduced_motion and _mode=="idle": selected=""
	if selected.is_empty(): return
	var frame := AnimationSet.frame(_sequence_body,selected) if _sequences_enabled else {}
	if frame.is_empty():
		var fallback := int(AnimationSet.FALLBACK.get(selected,semantic_pose))
		_set_pose_frame(fallback)
		_animation_sample.frame=POSE_NAMES[fallback]
		return
	_sequence_frame = frame
	_animation_sample.frame=selected


func _current_frame() -> Dictionary:
	return _render_frame if not _render_frame.is_empty() else _clean_frame()


func _clean_frame() -> Dictionary:
	if not _sequence_frame.is_empty(): return _sequence_frame
	if _atlas.is_empty(): return {}
	return _atlas.frames[maxi(0,_frame_index)]


func get_animation_state() -> Dictionary:
	var current := _current_frame()
	return {"damage":damage_state.snapshot(),"damage_art":bool(current.get("damage_art",false)),"damage_variant":current.get("damage_variant","clean"),"damage_fallback":current.get("damage_fallback",""),"illustrated_profile_id":current.get("illustrated_profile_id",""),"body_id":_sequence_body,"enabled":_sequences_enabled,"mode":_mode,"visual_state":_visual_state(),"clip":_animation_sample.get("clip",_mode),"phase":_animation_sample.get("phase","rest"),"frame":_animation_sample.get("frame",POSE_NAMES[maxi(0,_frame_index)]),"elapsed":_action_time,"active_frame":_frame_index,"fallback":_sequence_frame.is_empty(),"hit_stop_remaining":_hit_stop_remaining,"transformation":_form_id,"form_profile_id":_sequence_body+":"+_form_id+":v1" if not _form_id.is_empty() else current.get("profile_id","legacy"),"battle_result":_battle_result,"source_path":current.get("source_path",_atlas.get("path","")),"draw_scale":_sprite.scale if is_instance_valid(_sprite) else Vector2.ONE,"region":current.get("region",Rect2i()),"bounds":current.get("bounds",Rect2i()),"anchor":current.get("anchor",Vector2.ZERO),"normalized":bool(current.get("normalized",false)),"profile_id":current.get("profile_id","legacy"),"canvas_px":current.get("canvas_px",Vector2i()),"pixels_per_world_unit":VisualProfiles.PIXELS_PER_WORLD_UNIT if bool(current.get("normalized",false)) else 0.0,"grounded":_is_grounded(),"attached_fx":is_instance_valid(_attached_fx) and _attached_fx.visible,"attached_fx_gain":_attached_fx_gain}


func _is_grounded() -> bool:
	if _mode=="move":
		var kind := str(AnimationSet.phase_sample(_move,_action_time).clip)
		if kind=="jump" and _action_time>=float(_move.get("windup",0.12)) and _action_time<_impact_time(): return false
	return bool(_current_frame().get("grounded",true))


func _visual_state() -> String:
	if _mode=="fall": return "KO"
	if _mode=="victory": return "victory"
	if not _is_grounded(): return "airborne"
	if _mode=="reaction":
		return {"knockdown":"knockdown","getup":"recovering","knockback":"knockback","critical":"stagger","stagger":"stagger","airborne":"airborne"}.get(_reaction_kind,"hit")
	if _mode=="move":
		var sample := AnimationSet.phase_sample(_move,_action_time)
		if sample.phase=="recovery": return "recovering"
		if sample.clip=="charge" and sample.phase=="windup": return "charging"
		if sample.clip=="dash": return "movement"
		return "attacking"
	if _mode=="idle" and not _form_id.is_empty() and _transform_elapsed<float(AnimationSet.REACTION_CLIPS.transformation.duration): return "transforming"
	return {"hit":"hit","dodge":"movement","attack":"attacking"}.get(_mode,"idle")


func effect_anchor(kind: String = "body") -> Vector2:
	# Sockets are authored canvas coordinates. Alpha bounds are never anatomy.
	if not is_instance_valid(_sprite) or _sprite.texture==null: return Vector2.ZERO if kind in ["ground","feet","left_foot","right_foot"] else Vector2(0,-76)
	var aliases := {"hands":"hand","chest":"core"}
	var frame := _current_frame()
	var sockets: Dictionary=frame.get("sockets_px",{})
	var socket: Variant=sockets.get(kind,sockets.get(str(aliases.get(kind,""))))
	if socket==null:
		var defaults: Dictionary=_visual_profile.get("sockets_px",{})
		var raw: Variant=defaults.get(kind,defaults.get(str(aliases.get(kind,""))))
		socket=VisualProfiles.point(raw)
	if socket==null:
		# Safe fixed zones for unreviewed legacy art. Even this fallback is stable
		# as tails, raised hands or transparent margins change the alpha bounds.
		var local: Vector2={"body":Vector2(0,-78),"chest":Vector2(0,-92),"core":Vector2(0,-92),"hand":Vector2(35,-87),"back":Vector2(-26,-86),"feet":Vector2.ZERO,"ground":Vector2.ZERO,"left_foot":Vector2(-16,0),"right_foot":Vector2(16,0)}.get(kind,Vector2(0,-78))
		var scale_value := maxf(0.001,absf(_sprite.scale.y))
		socket=Vector2(frame.get("anchor",Vector2.ZERO))+local/scale_value
	var point := _sprite.transform*(Vector2(socket)-Vector2(frame.get("anchor",Vector2.ZERO)))
	if kind in ["ground","feet","left_foot","right_foot"]:
		point.y=0.0
	return point


func illuminate_effect(_color: Color, _strength: float = 0.07, _duration: float = 0.35, _age: float = 0.0) -> void:
	# Compatibility for older callers. Base material relighting is deliberately
	# absent; energy lives in aligned FX and world particles instead.
	pass


func _update_attached_fx() -> void:
	if not is_instance_valid(_attached_fx): return
	var frame := _current_frame()
	var texture: Variant=frame.get("attached_fx_texture")
	_attached_fx_gain=_attached_gain()
	if texture==null and _attached_fx_gain>0:
		texture=AttachedEnergy.texture_for(frame)
	_attached_fx.visible=texture is Texture2D and attached_fx_enabled and not reduced_motion and _mode!="fall" and _attached_fx_gain>0
	if not _attached_fx.visible:
		_attached_fx.texture=null
		return
	_attached_fx.texture=texture
	_attached_fx.offset=_sprite.offset
	_attached_fx.transform=_sprite.transform
	_attached_fx.modulate=Color(1,1,1,_attached_fx_gain)


func _attached_gain() -> float:
	if not attached_fx_enabled or reduced_motion or _mode=="fall": return 0.0
	var gain := 0.0
	if not _form_id.is_empty():
		gain=0.5
		if _mode=="idle" and not _transform_pending:
			gain=clampf(_transform_elapsed/float(AnimationSet.REACTION_CLIPS.transformation.duration),0,1) if _transform_elapsed<float(AnimationSet.REACTION_CLIPS.transformation.duration) else 0.5
	if _mode=="move":
		var sample := AnimationSet.phase_sample(_move,_action_time)
		if sample.clip in ["charge","signature"]:
			var charge := float(sample.progress) if sample.phase=="windup" else (1.0 if sample.phase=="travel" else 1.0-float(sample.progress))
			gain=maxf(gain,charge)
	return clampf(gain,0,1)


func visible_sprite_bounds() -> Rect2:
	# Diagnostics/layout tests inspect painted pixels; rendering retains all
	# transparent canvas space. Neither this rect nor its alpha drives scaling.
	return global_transform * painted_bounds_local()


func _draw() -> void:
	if _atlas.is_empty():
		return
	# The ground shadow is independent of the sprite's mirror, flash and jump.
	var width: float = 41.0 if _mode != "fall" else 57.0
	var opacity: float = 0.21
	if _mode == "move" and not reduced_motion:
		var movement: Dictionary = _move_pose()
		var altitude: float = maxf(0.0, -Vector2(movement.offset).y)
		width *= 1.0 - altitude / 180.0
		opacity *= 1.0 - altitude / 120.0
	if _mode == "victory" and not reduced_motion and str(appearance.get("victory_pose_id", "classic")) == "classic":
		var jump := absf(sin(_action_time * 4.0))
		width *= 1.0 - jump * 0.09
		opacity -= jump * 0.04
	draw_set_transform(Vector2(_lane_shift, -1.0), 0.0, Vector2(width, 5.8))
	draw_circle(Vector2.ZERO, 1.0, Color(0.035, 0.055, 0.06, opacity))
	draw_set_transform(Vector2.ZERO)


func _draw_cosmetics(canvas: CanvasItem) -> void:
	var effect: Dictionary = _cosmetics.get("aura", {})
	var color := Color(str(effect.get("color", "efb66f")))
	CosmeticParticles.paint(canvas, CosmeticParticles.samples(effect, _clock, effect_anchor("body"), effect_anchor("feet"), facing, false, 1.0, reduced_motion))
	var trail_effect: Dictionary = _cosmetics.get("trail", {})
	var energy: float = 0.65 if reduced_motion and cosmetic_preview else (0.0 if reduced_motion else _cosmetic_trail_energy)
	CosmeticParticles.paint(canvas, CosmeticParticles.samples(trail_effect, _clock, effect_anchor("back"), effect_anchor("feet"), facing, true, energy, reduced_motion))
	if str(appearance.get("intro_animation_id", "classic")) == "pulso" and _intro_elapsed < 0.9 and not reduced_motion:
		var progress: float = clampf(_intro_elapsed / 0.9, 0, 1)
		for index in range(12):
			var seed := float(index)*1.618
			var origin := effect_anchor("back" if index%2==0 else "feet")
			var point := origin + Vector2((fposmod(seed*7.3,1.0)-0.5)*54.0,0)
			point += Vector2(sin(seed)*9.0,-25.0-fposmod(seed*13.0,30.0))*progress
			ParticleInk.spark(canvas,point,Vector2(sin(seed)*7,-30),1.0,Color(color,sin(progress*PI)*0.78),4.2)

	if str(appearance.get("intro_animation_id", "classic")) == "bruma" and _intro_elapsed < 1.3:
		var intro_strength: float = 0.65 if reduced_motion else 1.0 - _intro_elapsed / 1.3
		var mist := {"id":"entry_mist","shape":"mist","color":"c8d8d2","particles":10}
		CosmeticParticles.paint(canvas, CosmeticParticles.samples(mist, _intro_elapsed, effect_anchor("feet") + Vector2(0,-10), effect_anchor("feet"), facing, false, intro_strength, reduced_motion))
	if _mode == "victory" and str(appearance.get("victory_pose_id", "classic")) == "festival" and _action_time < 2.2:
		var victory_strength: float = 0.65 if reduced_motion else 1.0 - _action_time / 2.2
		var petals := {"id":"victory_petals","shape":"petal","color":"ffcf70","particles":24}
		CosmeticParticles.paint(canvas, CosmeticParticles.samples(petals, _action_time, effect_anchor("body"), effect_anchor("feet"), facing, false, victory_strength, reduced_motion))


static func _load_atlas(path: String) -> Dictionary:
	if _atlas_cache.has(path):
		return _atlas_cache[path]
	var body := AnimationSet.body_for_atlas(path)
	var normalized := AnimationSet.normalized_pack(body,"base")
	if not normalized.is_empty():
		var ordered: Array[Dictionary]=[]
		for name: String in POSE_NAMES: ordered.append(normalized.frames[name])
		normalized.frames=ordered
		normalized["legacy_path"]=path
		_atlas_cache[path]=normalized
		return normalized
	if not ResourceLoader.exists(path):
		return {}
	var texture: Texture2D = load(path) as Texture2D
	var source: Image = texture.get_image() if texture != null else null
	if source == null or source.is_empty():
		push_warning("No se pudo leer el atlas de personaje: " + path)
		return {}
	if source.is_compressed():
		source.decompress()
	var metadata: Dictionary = {}
	var metadata_path: String = path.get_basename() + ".json"
	if FileAccess.file_exists(metadata_path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
		if parsed is Dictionary:
			metadata = parsed
	var columns: int = maxi(1, int(metadata.get("columns", 4)))
	var rows: int = maxi(1, int(metadata.get("rows", 2)))
	var frame_metadata: Array = metadata.get("frames", [])
	var frames: Array[Dictionary] = []
	for index in range(8):
		# Rounding both edges retains all source pixels for non-divisible dimensions.
		var column: int = index % columns
		var row: int = index / columns
		var start := Vector2i(roundi(float(column) * source.get_width() / columns), roundi(float(row) * source.get_height() / rows))
		var end := Vector2i(roundi(float(column + 1) * source.get_width() / columns), roundi(float(row + 1) * source.get_height() / rows))
		var region := Rect2i(start, end - start)
		var frame_meta: Dictionary = frame_metadata[index] if index < frame_metadata.size() and frame_metadata[index] is Dictionary else {}
		var supplied_region: Array = frame_meta.get("region", [])
		if supplied_region.size() == 4:
			region = Rect2i(int(supplied_region[0]), int(supplied_region[1]), int(supplied_region[2]), int(supplied_region[3]))
		region = region.intersection(Rect2i(Vector2i.ZERO, source.get_size()))
		if region.size.x < 1 or region.size.y < 1:
			push_warning("Región vacía en %s, pose %s" % [path, POSE_NAMES[index]])
			return {}
		var cell: Image = source.get_region(region)
		var bounds: Rect2i = _find_alpha_bounds(cell)
		if bounds.size.x < 1 or bounds.size.y < 1:
			push_warning("Pose transparente en %s: %s" % [path, POSE_NAMES[index]])
			return {}
		var anchor: Vector2 = _find_foot_anchor(cell, bounds)
		var supplied_anchor: Array = frame_meta.get("anchor", [])
		if supplied_anchor.size() == 2:
			anchor = Vector2(float(supplied_anchor[0]), float(supplied_anchor[1]))
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = texture
		atlas_texture.region = Rect2(region.position + bounds.position, bounds.size)
		atlas_texture.filter_clip = true
		frames.append({"name": POSE_NAMES[index], "texture": atlas_texture, "region": region, "bounds": bounds, "anchor": anchor})
	var idle_height: float = float(frames[0]["bounds"].size.y)
	var atlas: Dictionary = {"path": path, "source_size": source.get_size(), "texture": texture, "scale": DISPLAY_HEIGHT / idle_height, "frames": frames}
	_atlas_cache[path] = atlas
	return atlas


static func _find_alpha_bounds(cell: Image) -> Rect2i:
	var min_x: int = cell.get_width()
	var min_y: int = cell.get_height()
	var max_x: int = -1
	var max_y: int = -1
	for y in range(cell.get_height()):
		for x in range(cell.get_width()):
			if cell.get_pixel(x, y).a >= ALPHA_THRESHOLD:
				min_x = mini(min_x, x)
				max_x = maxi(max_x, x)
				min_y = mini(min_y, y)
				max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


static func _find_foot_anchor(cell: Image, bounds: Rect2i) -> Vector2:
	var bottom_y: int = bounds.end.y
	var band_height: int = maxi(2, int(round(bounds.size.y * 0.10)))
	var min_x: int = bounds.end.x
	var max_x: int = bounds.position.x
	for y in range(maxi(bounds.position.y, bottom_y - band_height), bottom_y):
		for x in range(bounds.position.x, bounds.end.x):
			if cell.get_pixel(x, y).a >= ALPHA_THRESHOLD:
				min_x = mini(min_x, x)
				max_x = maxi(max_x, x)
	return Vector2(float(min_x + max_x + 1) * 0.5, float(bottom_y))


func get_sprite_geometry() -> Dictionary:
	## Read-only diagnostic data for validating assets, pose binding and grounding.
	if _atlas.is_empty():
		return {}
	var frames: Array[Dictionary] = []
	for frame: Dictionary in _atlas["frames"]:
		frames.append({"name": frame["name"], "region": frame["region"], "bounds": frame["bounds"], "anchor": frame["anchor"],"normalized":bool(frame.get("normalized",false)),"canvas_px":frame.get("canvas_px",Vector2i())})
	return {"path": _atlas.get("legacy_path",_atlas["path"]), "source_path":_atlas["path"], "source_size": _atlas["source_size"], "scale": _atlas["scale"], "frames": frames, "active_frame": _frame_index,"normalized":bool(_atlas.get("normalized",false)),"profile":_visual_profile.duplicate(true),"legacy_path":_atlas.get("legacy_path",_atlas["path"])}
