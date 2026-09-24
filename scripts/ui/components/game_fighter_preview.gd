extends Control
class_name GameFighterPreview
## A presentation-only, grounded portrait using the same art and cosmetics as combat.

const Fighter = preload("res://scripts/fighter_view.gd")

var facing: int = 1
# Collections may share the smallest available camera across neighboring cells.
var max_scale: float = INF
var _actor: FighterView
var _envelope := Rect2(-83, -166, 166, 172)
var _configured := false
var _paused := false
var _reduced := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(fit)
	visibility_changed.connect(_sync_motion)


func _ready() -> void:
	# A clipped portrait is still visible_in_tree; observe scrolling/layout so
	# offscreen collection cards stop animation instead of consuming every frame.
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor is Control:
			ancestor.resized.connect(_sync_motion)
		if ancestor is ScrollContainer:
			ancestor.get_v_scroll_bar().value_changed.connect(_scroll_changed)
			ancestor.get_h_scroll_bar().value_changed.connect(_scroll_changed)
		ancestor = ancestor.get_parent()
	_sync_motion()
	fit()


func _scroll_changed(_value: float) -> void:
	# ScrollContainer applies the child offset after its scrollbar signal.
	_sync_motion.call_deferred()


func configure(profile: Dictionary, definition: Dictionary) -> void:
	# Profile identity/cosmetics can override a catalogue portrait without changing
	# its gameplay archetype or either input dictionary (including nested values).
	var display := definition.duplicate(true)
	for key: String in ["character_id", "fighter_id", "identity", "appearance", "name", "base_name", "visual"]:
		if profile.has(key):
			var value: Variant = profile[key]
			display[key] = value.duplicate(true) if value is Dictionary or value is Array else value
	if not is_instance_valid(_actor):
		_actor = Fighter.new()
		_actor.name = "Fighter"
		add_child(_actor)
	_actor.setup_character(display, facing)
	_configured = true
	_measure_envelope()
	_sync_motion()
	fit()


func actor() -> FighterView:
	return _actor


func set_motion(paused: bool, reduced: bool) -> void:
	_paused = paused
	_reduced = reduced
	_sync_motion()


func _sync_motion() -> void:
	if not is_instance_valid(_actor): return
	var on_screen := is_visible_in_tree()
	if on_screen and is_inside_tree():
		var rect := get_global_rect()
		var ancestor := get_parent()
		while ancestor != null:
			if ancestor is Control and ancestor.clip_contents and not rect.intersects(ancestor.get_global_rect()):
				on_screen = false
				break
			ancestor = ancestor.get_parent()
	_actor.motion_paused = _paused or not on_screen
	_actor.reduced_motion = _reduced
	_actor.set_process(on_screen and not _paused)


func _measure_envelope() -> void:
	# The same camera envelope preserves deliberate size differences when the
	# player browses bodies. Transparent space changes, never physical scale.
	_envelope = Fighter.VisualProfiles.REST_ENVELOPE


func fit() -> void:
	if not _configured or not is_instance_valid(_actor): return
	var available := Vector2(maxf(0, size.x - 12), maxf(0, size.y - 12))
	var factor := minf(max_scale,maxf(0, minf(available.x / maxf(1, _envelope.size.x), available.y / maxf(1, _envelope.size.y))))
	_actor.scale = Vector2.ONE * factor
	_actor.position = Vector2(size.x * 0.5, size.y - 6 - _envelope.end.y * factor)
	_sync_motion()


func visual_bounds() -> Rect2:
	## Stable local footprint reserved for the idle portrait, including breathing.
	if not is_instance_valid(_actor): return Rect2()
	return Rect2(_actor.position + _envelope.position * _actor.scale, _envelope.size * _actor.scale)
