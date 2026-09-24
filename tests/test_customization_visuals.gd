extends SceneTree
## Safe, memory-only identities. Native captures: -- --capture-dir=/absolute/path
const Fighter = preload("res://scripts/fighter_view.gd")
const EditorPanel = preload("res://scripts/ui/customization_panel.gd")
const Cosmetics = preload("res://scripts/cosmetic_catalog.gd")
const Characters = preload("res://scripts/character_catalog.gd")
const Moves = preload("res://scripts/move_catalog.gd")
const Arena = preload("res://scripts/arena_view.gd")
const Layout = preload("res://scripts/ui/battle_layout.gd")
const SIZES: Array[Vector2i] = [Vector2i(1360,880),Vector2i(1224,792),Vector2i(1920,1080),Vector2i(768,1024),Vector2i(390,844),Vector2i(430,932),Vector2i(844,390)]
var checks: int = 0
var failures: int = 0
var capture_dir: String = ""

class MemoryIdentity extends RefCounted:
	var entries: Dictionary = {}
	var inventory: Array[String] = Cosmetics.default_owned()
	func _init() -> void:
		for id: String in Characters.IDS:
			entries[id] = {"fighter_id":"fixture-"+id,"archetype_id":id,"identity":{"display_name":Characters.definition(id).name},"appearance":Cosmetics.default_appearance(id)}
	func entry(id: String) -> Dictionary:
		# Deliberately return a shared dictionary: the panel must own its draft.
		return entries[id]
	func owned_ids() -> Array[String]: return inventory.duplicate()

func _init() -> void: _run.call_deferred()

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CUSTOMIZATION: " + message)

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): capture_dir = arg.trim_prefix("--capture-dir=")
	if not capture_dir.is_empty():
		_check(capture_dir.is_absolute_path(), "capture destination is explicitly absolute")
		_check(DisplayServer.get_name() != "headless", "captures require native rendering")
		if DisplayServer.get_name() == "headless": capture_dir = ""
		else: DirAccess.make_dir_recursive_absolute(capture_dir)
	_test_renderer()
	await _test_panel()
	await _test_viewports()
	if not capture_dir.is_empty(): await _test_palette_pixels()
	print("CUSTOMIZATION VISUALS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _test_renderer() -> void:
	var actor = Fighter.new()
	root.add_child(actor)
	actor.set_process(false)
	for gameplay_id: String in Characters.IDS:
		for body_id: String in Characters.IDS:
			var descriptor: Dictionary = Characters.definition(gameplay_id)
			descriptor["appearance"] = Cosmetics.default_appearance(body_id)
			descriptor.appearance.palette_id = "jade"
			descriptor["identity"] = {"display_name":"Ceniza"}
			var before: Dictionary = descriptor.duplicate(true)
			actor.setup_character(descriptor)
			_check(actor.get_sprite_geometry().path == Cosmetics.body_definition(body_id).visual.atlas, gameplay_id + " independently wears " + body_id)
			_check(descriptor == before, "renderer never modifies gameplay/identity snapshot")
			_check(actor.appearance == descriptor.appearance and actor.identity.display_name == "Ceniza", "renderer resolves supplied appearance and identity")
			descriptor.appearance.palette_id = "ocaso"
			_check(actor.appearance.palette_id == "jade", "renderer keeps its own immutable appearance copy")
	var decorated: Dictionary = Characters.definition("mugo")
	decorated["appearance"] = Cosmetics.default_appearance("copal")
	decorated.appearance.merge({"palette_id":"luna","aura_id":"corona","trail_id":"estela","victory_pose_id":"saludo","intro_animation_id":"pulso"}, true)
	actor.setup_character(decorated)
	var geometry: Dictionary = actor.get_sprite_geometry()
	var other = Fighter.new()
	root.add_child(other)
	other.set_process(false)
	other.setup_character(Cosmetics.body_definition("copal"))
	_check(geometry.frames == other.get_sprite_geometry().frames and geometry.scale == other.get_sprite_geometry().scale, "cosmetics never change atlas scale, regions or foot anchors")
	_check(actor._flash_material != other._flash_material, "per-actor palette material cannot recolor another fighter")
	var move: Dictionary = Moves.moves_for("mugo")[0]
	actor.play_move(move)
	other.play_move(move)
	for delta: float in [0.017,0.044,0.061,0.03,0.12,0.05,0.25,0.17]:
		actor._process(delta)
		other._process(delta)
		_check(is_equal_approx(actor._action_time,other._action_time) and actor._mode == other._mode, "cosmetic timeline never changes combat move clock")
		_check(actor._sprite.position == other._sprite.position and actor._frame_index == other._frame_index, "body and palette share exact combat motion")
	actor.play_move(move,0.03)
	var clock_before: float = actor._action_time
	actor.play_intro()
	_check(actor._action_time == clock_before and actor._mode == "move", "intro pulse cannot interrupt an attack")
	actor.motion_paused = true
	var intro_before: float = actor._intro_elapsed
	actor._process(1)
	_check(actor._intro_elapsed == intro_before and actor._action_time == clock_before, "pause holds cosmetic and attack clocks")
	actor.motion_paused = false
	actor.reduced_motion = true
	actor._process(0.09)
	_check(actor._sprite.position == Vector2.ZERO and not actor._trail.visible, "reduced motion suppresses cosmetic motion feedback")
	var boss := {"id":"ascua","archetype":2,"visual":{"atlas":"res://assets/sprites/ascua-v3.png","tint":"ffffff"}}
	actor.setup_character(boss)
	_check(actor.appearance.is_empty() and actor.get_sprite_geometry().path == boss.visual.atlas, "old descriptors and boss atlas overrides stay intact")
	_check(is_zero_approx(float(actor._flash_material.get_shader_parameter("palette_strength"))), "reusing actor clears previous palette on old descriptor")
	actor.free()
	other.free()

func _test_panel() -> void:
	var store := MemoryIdentity.new()
	var original: Dictionary = store.entries.duplicate(true)
	var panel = EditorPanel.new()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(1360,880)
	panel.configure(store,"mugo",false)
	await process_frame
	var signals: Array = []
	panel.confirmed.connect(func(id: String, fighter_name: String, appearance: Dictionary): signals.append({"id":id,"name":fighter_name,"appearance":appearance}))
	var cancellations: Array = []
	panel.cancelled.connect(func(): cancellations.append(true))
	_check(not panel._archetype.visible, "editing never exposes an archetype change")
	panel._choose_archetype(0)
	_check(panel._archetype_id == "mugo", "archetype handler cannot change gameplay while editing")
	panel._choose_item("body_style_id","copal")
	panel._choose_item("palette_id","jade")
	panel._name_input.text = "Ceniza"
	panel._cancel_draft()
	_check(cancellations.size() == 1 and store.entries == original, "cancel discards all name and appearance edits without persistence")
	panel.configure(store,"mugo",false)
	_check(panel._draft.body_style_id == "mugo" and panel._name_input.text == "Mugo", "reopening restores only committed identity")
	panel.select_tab(1)
	var before_locked: Dictionary = panel._draft.duplicate(true)
	panel._choose_item("palette_id","luna")
	_check(panel._draft == before_locked and not panel._error.text.is_empty(), "locked choice displays requirement without changing appearance")
	_check(panel._error.text.contains("10"), "locked message explains the actual unlock requirement")
	_check(panel._actor.appearance.palette_id == "luna" and panel._confirm.disabled, "locked palette can be tried without being equipped")
	panel._confirm_draft()
	_check(signals.is_empty() and store.entries == original, "confirm handler cannot save a locked preview")
	panel._choose_item("palette_id", "luna")
	_check(panel._actor.appearance == before_locked and not panel._confirm.disabled, "selecting a trial again restores the actual draft")
	panel._select_color_section(1)
	_check(panel._item_buttons.size() == 6, "skins view exposes the six authored family appearances")
	panel._choose_item("body_style_id", "duna_pedernal")
	_check(panel._actor.appearance.body_style_id == "duna_pedernal" and panel._draft == before_locked, "locked shield skin is a visual preview only")
	_check(panel._error.text.contains("62") and panel._confirm.disabled, "skin preview explains its real Story unlock")
	panel._select_color_section(0)
	_check(panel._actor.appearance == before_locked and not panel._confirm.disabled, "leaving skins restores draft and save action")
	for trial: Array in [["aura_id","corona"],["trail_id","cometa"]]:
		panel._choose_item(trial[0],trial[1])
		_check(panel._actor.appearance[trial[0]] == trial[1] and panel._draft == before_locked, "locked effect is previewed without changing draft")
		panel._confirm_draft()
		_check(signals.is_empty() and panel._confirm.disabled, "locked effects cannot be confirmed")
		panel._try_back.pressed.emit()
		_check(panel._actor.appearance == before_locked, "return removes the effect trial")
	for index in range(24):
		panel.randomize_owned()
		_check(bool(Cosmetics.validate_appearance(panel._draft,store.inventory,"mugo").ok), "randomization only chooses owned compatible IDs")
	_check(store.entries == original, "random drafts never write identity store")
	panel._choose_preset(2)
	_check(panel._draft.palette_id == "jade" and panel._draft.intro_animation_id == "pulso", "curated preset applies owned parts")
	panel._name_input.text = "Náhuatl"
	panel._confirm_draft()
	_check(signals.size() == 1 and signals[0].id == "mugo" and signals[0].name == "Náhuatl", "confirmation sends selected archetype and name to owner")
	_check(store.entries == original, "confirmation delegates persistence instead of writing itself")
	signals[0].appearance.palette_id = "ocaso"
	_check(panel._draft.palette_id == "jade", "confirmation payload is a copy of draft")
	panel.set_error("Nombre reservado. Elige otro nombre.")
	_check(panel._error.visible and panel.visible, "save/name errors leave draft open for correction")
	panel.configure(store,"nima",true)
	_check(panel._archetype.visible, "creation exposes combat archetype choice")
	panel._choose_archetype(2)
	_check(panel._archetype_id == "mugo", "creation can select initial combat archetype")
	panel._choose_item("body_style_id","balam")
	_check(panel._archetype_id == "mugo" and panel._actor.get_sprite_geometry().path.ends_with("balam-v1.png"), "body selector remains separate from chosen combat archetype")
	panel.free()
	await process_frame

func _test_viewports() -> void:
	var store := MemoryIdentity.new()
	for slot: Dictionary in Cosmetics.SLOTS:
		for item: Dictionary in Cosmetics.items(str(slot.id)):
			if not str(item.inventory_id) in store.inventory: store.inventory.append(str(item.inventory_id))
	store.entries.mugo.identity.display_name = "Ceniza"
	store.entries.mugo.appearance.merge({"body_style_id":"balam","palette_id":"jade","aura_id":"farol","intro_animation_id":"pulso"},true)
	for viewport_size: Vector2i in SIZES:
		var canvas := SubViewport.new()
		canvas.size = viewport_size
		canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(canvas)
		var panel = EditorPanel.new()
		canvas.add_child(panel)
		panel.configure(store,"mugo",true)
		await process_frame
		await process_frame
		panel._actor.set_process(false)
		panel._actor._process(1)
		_check(panel.size == Vector2(viewport_size), "editor fills requested viewport")
		for tab in range(4):
			panel.select_tab(tab)
			await process_frame
			await process_frame
			_check_layout(panel,viewport_size)
			if not capture_dir.is_empty() and tab in [0,1,2,3]:
				await _capture(canvas,"%dx%d-editor-%d.png" % [viewport_size.x,viewport_size.y,tab])
			if tab == 1:
				panel._select_color_section(1)
				await process_frame
				await process_frame
				_check_layout(panel, viewport_size)
				if not capture_dir.is_empty(): await _capture(canvas,"%dx%d-skins.png" % [viewport_size.x,viewport_size.y])
				panel._select_color_section(0)
		# The locked inventory and save/name error share the same responsive UI.
		panel._owned.assign(Cosmetics.default_owned())
		panel.select_tab(1)
		panel._select_color_section(1)
		panel._choose_item("body_style_id", "duna_pedernal")
		await process_frame
		await process_frame
		_check_layout(panel, viewport_size)
		_check(panel._try_back.visible and panel._confirm.disabled, "trial offers a visible return action and cannot save")
		_check(not panel._error.get_global_rect().intersects(panel._try_back.get_global_rect()), "trial requirement does not overlap return action")
		if not capture_dir.is_empty(): await _capture(canvas,"%dx%d-locked-skin.png" % [viewport_size.x,viewport_size.y])
		panel._try_back.pressed.emit()
		_check(panel._try_id.is_empty() and not panel._confirm.disabled and panel._actor.appearance == panel._draft, "return restores the draft and save action")
		panel._owned.append(Cosmetics.inventory_key("aura","farol"))
		panel.select_tab(2)
		panel._choose_item("aura_id","corona")
		await process_frame
		await process_frame
		_check_layout(panel,viewport_size)
		_check(not panel._scroll.get_global_rect().intersects(panel._error.get_global_rect()), "error message does not cover choices")
		_check(not panel._preview_panel.get_global_rect().intersects(panel._error.get_global_rect()), "error message does not cover preview")
		if not capture_dir.is_empty():
			await _capture(canvas,"%dx%d-locked.png" % [viewport_size.x,viewport_size.y])
		panel._try_back.pressed.emit()
		var descriptor: Dictionary = Characters.definition("mugo")
		descriptor.appearance = panel._draft.duplicate(true)
		var battle_actor = Fighter.new()
		canvas.add_child(battle_actor)
		battle_actor.setup_character(descriptor)
		battle_actor.set_process(false)
		_check(battle_actor.appearance == panel._actor.appearance and battle_actor.get_sprite_geometry().frames == panel._actor.get_sprite_geometry().frames, "preview and combat resolve identical appearance")
		_check(battle_actor._flash_material.get_shader_parameter("palette_primary") == panel._actor._flash_material.get_shader_parameter("palette_primary"), "preview and combat use identical shader palette")
		panel.visible = false
		var arena = Arena.new()
		canvas.add_child(arena)
		canvas.move_child(arena,0)
		arena.set_viewport_size(Vector2(viewport_size))
		arena.set_process(false)
		var layout: Dictionary = Layout.calculate(Vector2(viewport_size),true)
		battle_actor.position = layout.player_at
		battle_actor.scale = Vector2.ONE * float(layout.actor_scale)
		var rival = Fighter.new()
		canvas.add_child(rival)
		var rival_descriptor: Dictionary = Characters.definition("nima")
		rival_descriptor.appearance = Cosmetics.default_appearance("copal")
		rival_descriptor.appearance.merge({"palette_id":"ocaso","aura_id":"luciernagas","trail_id":"brasa"},true)
		rival.setup_character(rival_descriptor,-1)
		rival.set_process(false)
		rival.position = layout.rival_at
		rival.scale = battle_actor.scale
		battle_actor.play_move(Moves.moves_for("mugo")[0],0.16)
		rival.play_hit()
		rival._process(0.12)
		for actor: Node2D in [battle_actor,rival]:
			var rect: Rect2 = actor.visible_sprite_bounds()
			_check(Rect2(Vector2.ZERO,Vector2(viewport_size)).encloses(rect), "customized combat silhouettes fit viewport")
		if not capture_dir.is_empty(): await _capture(canvas,"%dx%d-battle.png" % [viewport_size.x,viewport_size.y])
		canvas.queue_free()
		await process_frame

func _check_layout(panel: Control, viewport_size: Vector2i) -> void:
	var viewport_rect := Rect2(Vector2.ZERO,Vector2(viewport_size))
	for control: Control in [panel._preview_panel,panel._options,panel._name_input,panel._tabs,panel._toolbar,panel._scroll,panel._cancel,panel._confirm]:
		_check(viewport_rect.grow(0.1).encloses(control.get_global_rect()), "%s stays in %s" % [control.name,viewport_size])
	_check(not panel._preview_panel.get_global_rect().intersects(panel._options.get_global_rect()), "preview and options never overlap")
	_check(not panel._scroll.get_global_rect().intersects(panel._confirm.get_global_rect()), "choice list stays clear of apply action")
	_check(panel._confirm.size.x <= 200 and panel._cancel.size.x <= 132, "footer actions remain compact")
	_check(is_equal_approx(panel._confirm.get_global_rect().end.x,panel._options.get_global_rect().end.x), "save aligns with right edge of editor")
	_check(not panel._cancel.get_global_rect().intersects(panel._confirm.get_global_rect()), "footer actions have independent hit areas")
	for control: Control in [panel._presets,panel._random]:
		_check(panel._toolbar.get_global_rect().grow(0.1).encloses(control.get_global_rect()), "compact utilities stay within their row")
		_check(control.size.y >= 44, "compact utilities retain touch height")
	_check(panel._presets.text == "Conjunto visual…" and panel._presets.is_item_disabled(0), "preset placeholder explains the action and popup description is not selectable")
	for button: Button in panel._tab_buttons:
		_check(button.size.x >= 40 and button.size.y >= 40, "tabs keep a usable touch target")
	var sprite: Sprite2D = panel._actor._sprite
	var bounds: Rect2 = panel._actor.visible_sprite_bounds()
	_check(panel._stage.get_global_rect().grow(0.1).encloses(bounds), "large preview silhouette is fully visible")
	for button: Button in panel._item_buttons:
		_check(button.size.x >= 100, "choice cards retain readable width")
		_check(panel._scroll.get_global_rect().position.x <= button.global_position.x and button.get_global_rect().end.x <= panel._scroll.get_global_rect().end.x + 0.1, "cards never overflow horizontal scrolling")

func _capture(canvas: SubViewport, filename: String) -> void:
	await RenderingServer.frame_post_draw
	var result: Error = canvas.get_texture().get_image().save_png(capture_dir.path_join(filename))
	_check(result == OK, "native screenshot saved: " + filename)

func _test_palette_pixels() -> void:
	var canvas := SubViewport.new()
	canvas.size = Vector2i(360,320)
	canvas.transparent_bg = true
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	var actor = Fighter.new()
	canvas.add_child(actor)
	actor.position = Vector2(180,280)
	actor.set_process(false)
	var original: Image
	for palette_item: Dictionary in Cosmetics.items("palette_id"):
		var palette: String = str(palette_item.id)
		var descriptor: Dictionary = Characters.definition("balam")
		descriptor.appearance = Cosmetics.default_appearance("balam")
		descriptor.appearance.palette_id = palette
		actor.setup_character(descriptor)
		actor._clock = 0
		actor._update_pose()
		await process_frame
		await RenderingServer.frame_post_draw
		var current: Image = canvas.get_texture().get_image()
		if palette == "original":
			original = current
		else:
			var alpha_differences: int = 0
			var changed: int = 0
			var opaque: int = 0
			for y in range(current.get_height()):
				for x in range(current.get_width()):
					var a: Color = original.get_pixel(x,y)
					var b: Color = current.get_pixel(x,y)
					if absf(a.a - b.a) > 0.005: alpha_differences += 1
					if a.a > 0.9:
						opaque += 1
						if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.02: changed += 1
			_check(alpha_differences == 0, palette + " preserves the atlas alpha exactly")
			_check(changed > opaque * 0.1, palette + " visibly changes pigment without a new asset")
		_check(current.save_png(capture_dir.path_join("palette-"+palette+".png")) == OK, "palette crop saved")
	canvas.queue_free()
	await process_frame
