extends SceneTree
## Catalog-to-atlas, all-pose grounding and responsive scene geometry.
## Native render: -- --capture-dir=/absolute/path
## During asset generation only: -- --allow-pending (never used for final QA).
const Fighter = preload("res://scripts/fighter_view.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Story = preload("res://scripts/story_catalog.gd")
const Layout = preload("res://scripts/ui/battle_layout.gd")
const ORIGINAL := {"nima":"res://assets/sprites/lince-v2.png","luma":"res://assets/sprites/ajolote-v2.png","mugo":"res://assets/sprites/golem-v2.png"}
const VERSION_ONE_IDS: Array[String] = ["balam", "tepa", "xuna", "copal", "onix", "bruma"]
const SIZES: Array[Vector2] = [Vector2(1360,880),Vector2(1224,792),Vector2(1920,1080),Vector2(768,1024),Vector2(390,844),Vector2(430,932),Vector2(844,390)]
var checks := 0
var failures := 0
var pending: Array[String] = []
var definitions: Array[Dictionary] = []
var installed: Array[Dictionary] = []
var allow_pending := false
var capture_dir := ""
var canvas: SubViewport
var scene: Control

func _init() -> void: call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("DISTINCT SPRITE FAIL: "+message)

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--allow-pending": allow_pending = true
		if arg.begins_with("--capture-dir="): capture_dir = arg.trim_prefix("--capture-dir=")
	definitions = Catalog.all_definitions()
	definitions.append(Story.boss_definition())
	definitions.append(Story.boss_definition(2))
	var paths: Dictionary = {}
	var hashes: Dictionary = {}
	for definition: Dictionary in definitions:
		var id := str(definition.id)
		var suffix: String = "v1" if VERSION_ONE_IDS.has(id) else "v3"
		var path: String = ORIGINAL.get(id,"res://assets/sprites/%s-%s.png" % [id,suffix])
		if not ORIGINAL.has(id): _check(definition.visual.get("atlas","")==path,id+": identity references its expected unique atlas")
		_check(Color(str(definition.visual.tint))==Color.WHITE,id+": illustration keeps its own original colors")
		if not ResourceLoader.exists(path):
			pending.append(id)
			if not allow_pending: _check(false,id+": final PNG exists and is imported")
			continue
		var actor = Fighter.new()
		root.add_child(actor)
		actor.set_process(false)
		actor.setup_character(definition)
		var data: Dictionary = actor.get_sprite_geometry()
		_check(not data.is_empty() and data.path==path,id+": actual actor uses expected art, never a silent fallback")
		if data.is_empty():
			actor.free()
			continue
		_check(not paths.has(data.path),id+": rendered texture path is unique across all identities")
		paths[data.path] = id
		var digest := FileAccess.get_sha256(path)
		_check(not hashes.has(digest),id+": PNG content differs from other identities")
		hashes[digest] = id
		_check_frames(actor,definition,data)
		_check_battle_fit(actor,definition)
		installed.append(definition)
		actor.free()
	_check_fallback()
	_check(Story.opponent(7).visual.get("atlas","")=="res://assets/sprites/ascua-v3.png","Story Boss descriptor propagates Ascua's atlas")
	if pending.is_empty(): _check(paths.size()==definitions.size() and hashes.size()==definitions.size(),"every identity binds a different illustrated source")
	if not capture_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(capture_dir)
		await _render()
	print("DISTINCT SPRITES: %d checks, %d failures; %d installed, pending=%s" % [checks,failures,installed.size(),str(pending)])
	quit(0 if failures==0 else 1)

func _check_frames(actor: Node2D, definition: Dictionary, data: Dictionary) -> void:
	var id := str(definition.id)
	var sprite: Sprite2D = actor.get_node("IllustratedFighter")
	_check(data.frames.size()==8,id+": all eight poses present")
	_check(is_equal_approx(float(data.scale),1.0/Fighter.VisualProfiles.PIXELS_PER_WORLD_UNIT) if data.normalized else is_equal_approx(float(data.frames[0].bounds.size.y)*float(data.scale),166),id+": one canonical density or compatible legacy idle scale")
	var source: Texture2D = load(str(data.get("source_path",data.path)))
	var source_image := source.get_image()
	if source_image.is_compressed(): source_image.decompress()
	_check(source_image.detect_alpha()!=Image.ALPHA_NONE,id+": transparent PNG art")
	var covered_pixels: int = 0
	for index in range(data.frames.size()):
		var frame: Dictionary = data.frames[index]
		var bounds: Rect2i = frame.bounds
		var region: Rect2i = frame.region
		var anchor: Vector2 = frame.anchor
		if not ORIGINAL.has(id):
			covered_pixels += _opaque_count(source_image.get_region(region))
			for previous in range(index):
				_check(not region.intersects(data.frames[previous].region),id+": pose %d region cannot include another pose's pixels" % index)
		_check(frame.name==Fighter.POSE_NAMES[index],id+": pose %d follows action ordering" % index)
		_check(bounds.size.x>0 and bounds.size.y>0,id+": %s has visible art" % frame.name)
		# Some illustrated poses touch the adjacent row at one exact boundary.
		# The coverage + disjoint-region checks prove no visible pixel is lost or
		# shared; requiring artificial vertical padding would mix those poses.
		_check(bounds.position.x>0 and bounds.end.x<region.size.x and bounds.position.y>=0 and bounds.end.y<=region.size.y,id+": %s fits its isolated region with lateral gutters" % frame.name)
		_check(anchor.is_equal_approx(Fighter.VisualProfiles.PIVOT) if data.normalized else absf(anchor.y-bounds.end.y)<0.01,id+": %s uses stable declared ground origin" % frame.name)
		_check(anchor.is_equal_approx(Fighter.VisualProfiles.PIVOT) if data.normalized else anchor.x>=bounds.position.x and anchor.x<=bounds.end.x,id+": %s pivot cannot follow alpha bounds" % frame.name)
		actor._set_pose_frame(index)
		_check(sprite.texture is AtlasTexture and sprite.texture.region==(Rect2(region) if data.normalized else Rect2(region.position+bounds.position,bounds.size)),id+": %s binds only its bounded pixels" % frame.name)
		_check(is_equal_approx(sprite.scale.y,float(data.scale)),id+": %s keeps the common scale" % frame.name)
	if not ORIGINAL.has(id):
		_check(covered_pixels==_opaque_count(source_image),id+": metadata preserves every visible source pixel exactly once")
	_check(data.frames[7].bounds.size.y < data.frames[0].bounds.size.y*0.8,id+": defeated pose remains visibly lower than idle")
	actor.setup_character(definition,-1)
	_check(actor.get_sprite_geometry().path==data.path and sprite.scale.x<0,id+": rival mirrors the same unique art")
	actor.play_attack(true)
	actor._process(0.18)
	_check(actor.get_sprite_geometry().active_frame==3,id+": attack reaches punch")
	actor.play_hit(true)
	_check(float(sprite.material.get_shader_parameter("flash_amount"))>0,id+": impact preserves flash material on unique atlas")
	_check(actor.visual_tint==Color.WHITE,id+": no old recolor remains after mirrored setup")

func _opaque_count(image: Image) -> int:
	image.convert(Image.FORMAT_RGBA8)
	var pixels := image.get_data()
	var count := 0
	for offset in range(3,pixels.size(),4):
		if pixels[offset]>=31: count += 1
	return count

func _check_battle_fit(actor: Node2D, definition: Dictionary) -> void:
	var id := str(definition.id)
	for view: Vector2 in SIZES:
		var r: Dictionary = Layout.calculate(view,true)
		for side: String in ["player","rival"]:
			actor.setup_character(definition,1 if side=="player" else -1)
			actor.scale = Vector2.ONE*float(r.actor_scale)
			actor.position = r.player_at if side=="player" else r.rival_at
			var sprite: Sprite2D = actor.get_node("IllustratedFighter")
			for pose in range(8):
				actor._set_pose_frame(pose)
				var actual: Rect2 = actor.visible_sprite_bounds()
				_check(Rect2(Vector2.ZERO,view).grow(2).encloses(actual),"%s %s %s %s remains onscreen" % [id,str(view),side,Fighter.POSE_NAMES[pose]])
				_check(not actual.intersects(r.primary),"%s %s %s %s stays clear of primary" % [id,str(view),side,Fighter.POSE_NAMES[pose]])
	actor.scale = Vector2.ONE
	actor.position = Vector2.ZERO

func _check_fallback() -> void:
	var actor = Fighter.new()
	root.add_child(actor)
	actor.set_process(false)
	for kind in range(3):
		for path: String in ["","res://assets/sprites/not-installed-v3.png","user://unexpected.png","res://scripts/main.gd","res://assets/sprites/../unexpected.png"]:
			actor.setup_character({"archetype":kind,"visual":{"archetype":kind,"atlas":path,"tint":"ffffff"}},-1)
			_check(actor.get_sprite_geometry().path==Fighter.ATLAS_PATHS[kind],"missing/invalid override falls back to original species without external resource loads")
			_check(actor.facing==-1,"fallback preserves requested facing")
	actor.setup_character({"visual":{"archetype":0,"atlas":Fighter.ATLAS_PATHS[2],"tint":"abcdef"}})
	_check(actor.get_sprite_geometry().path==Fighter.ATLAS_PATHS[2],"explicit valid atlas overrides archetype asset")
	_check(actor.visual_tint==Color("abcdef"),"explicit custom tint API remains supported")
	actor.setup(0,Color.WHITE)
	_check(actor.get_sprite_geometry().path==Fighter.ATLAS_PATHS[0] and actor.visual_tint==Color.WHITE,"legacy setup clears override and tint")
	actor.free()

func _render() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1000,800)
	var host := SubViewportContainer.new()
	root.add_child(host)
	canvas = SubViewport.new()
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	host.add_child(canvas)
	for definition: Dictionary in installed:
		_start_canvas(Vector2i(1920,300))
		_label(str(definition.name).to_upper()+"  /  OCHO POSES",Vector2(20,10),22)
		for index in range(8):
			var actor = Fighter.new()
			scene.add_child(actor)
			actor.setup_character(definition)
			actor.set_process(false)
			actor._set_pose_frame(index)
			actor.position = Vector2(120+index*240,255)
			_label(Fighter.POSE_NAMES[index],Vector2(35+index*240,270),14)
		await _capture("poses-"+str(definition.id))
	_start_canvas(Vector2i(1360,80+310*ceili(installed.size()/5.0)))
	_label("BRASA  /  %d IDENTIDADES" % installed.size(),Vector2(28,18),25)
	for index in range(installed.size()):
		var definition: Dictionary = installed[index]
		var x: float = 136+(index%5)*272
		var y: float = 290+(index/5)*310
		var actor = Fighter.new()
		scene.add_child(actor)
		actor.setup_character(definition)
		actor.set_process(false)
		actor.position = Vector2(x,y)
		actor.scale = Vector2.ONE*1.18
		_label(str(definition.name),Vector2(x-60,y+18),22)
	await _capture("all-identities")
	for view: Vector2 in SIZES:
		_start_canvas(Vector2i(view))
		var r: Dictionary = Layout.calculate(view,true)
		var arena_script = load("res://scripts/arena_view.gd")
		var arena: Node2D = arena_script.new()
		scene.add_child(arena)
		arena.set_viewport_size(view)
		for index in range(mini(2,installed.size())):
			var definition: Dictionary = installed[-1] if index==1 else installed[maxi(0,installed.size()-3)]
			var actor = Fighter.new()
			arena.add_child(actor)
			actor.setup_character(definition,1 if index==0 else -1)
			actor.set_process(false)
			actor.scale = Vector2.ONE*float(r.actor_scale)
			actor.position = r.player_at if index==0 else r.rival_at
			_label(str(definition.name),Vector2(20 if index==0 else view.x-150,30),20)
		await _capture("battle-fit-%dx%d" % [int(view.x),int(view.y)])

func _start_canvas(size: Vector2i) -> void:
	if is_instance_valid(scene):
		canvas.remove_child(scene)
		scene.queue_free()
	canvas.size = size
	scene = Control.new()
	canvas.add_child(scene)
	var bg := ColorRect.new()
	bg.color = Color("102a30")
	bg.size = Vector2(size)
	scene.add_child(bg)

func _label(value: String, at: Vector2, font_size: int) -> void:
	var label := Label.new()
	label.text = value
	label.position = at
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("f5e7cf"))
	scene.add_child(label)

func _capture(filename: String) -> void:
	for _i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	canvas.get_texture().get_image().save_png(capture_dir.path_join(filename+".png"))
