extends SceneTree
## Native render fixture. No saves, accounts, server, unlock grants or combat RNG.
const Fighter = preload("res://scripts/fighter_view.gd")
const Cosmetics = preload("res://scripts/cosmetic_catalog.gd")
const Families = preload("res://scripts/character_families.gd")
const Damage = preload("res://scripts/visual_damage_state.gd")
const Story = preload("res://scripts/story_catalog.gd")
var output := ""
var canvas: SubViewport
var stage: Node2D
var actors: Array = []
func _init() -> void: run.call_deferred()
func label(text: String, at: Vector2, font_size: int = 22) -> void:
	var node := Label.new();node.text=text;node.position=at;node.add_theme_font_size_override("font_size",font_size);node.modulate=Color("f5e7cf");stage.add_child(node)
func definition(body: String) -> Dictionary:
	if body == "ascua": return Story.boss_definition(1)
	if body == "vespera": return Story.boss_definition(2)
	return Cosmetics.body_definition(body)
func actor(body: String, at: Vector2, health: float, zoom: float = 1.42) -> Node2D:
	var node := Fighter.new();stage.add_child(node);node.setup_character(definition(body));node.set_process(false);node.position=at;node.scale=Vector2.ONE*zoom;node.set_health_ratio(health);node._process(1);actors.append(node);return node
func clear_stage() -> void:
	actors.clear()
	for node: Node in stage.get_children(): node.free()
func capture(name: String) -> void:
	await process_frame;await process_frame
	await RenderingServer.frame_post_draw
	canvas.get_texture().get_image().save_png(output.path_join(name+".png"))
func run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): output=arg.trim_prefix("--capture-dir=")
	if output.is_empty(): output=ProjectSettings.globalize_path("res://../../work/damage-families/native")
	DirAccess.make_dir_recursive_absolute(output)
	canvas=SubViewport.new();canvas.size=Vector2i(1360,780);canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(canvas)
	var background := ColorRect.new();background.color=Color("162821");background.size=Vector2(1360,780);canvas.add_child(background)
	stage=Node2D.new();canvas.add_child(stage)
	for body: String in Damage.catalog().profiles:
		clear_stage();label("BRASA · desgaste de combate · "+body,Vector2(40,30));label("Fixture visual · misma escala, daño temporal; sin modificar perfiles",Vector2(40,70),16)
		for index: int in range(4):
			actor(body,Vector2(190+index*325,615),[1.0,0.65,0.39,0.15][index])
			label(["Preparado","Desgastado","Dañado","Crítico"][index],Vector2(80+index*330,680))
		await capture("damage-"+body)
	for base: String in ["taro","duna","bruma"]:
		clear_stage();label("BRASA · familia "+base,Vector2(40,30));var ids: Array[String]=[base]
		for id: String in Families.individuals():
			if Families.base_body(id)==base:ids.append(id)
		for index: int in range(ids.size()):
			actor(ids[index],Vector2(230+index*440,615),1.0,1.85)
			label(str(Families.individual(ids[index]).get("name",base.capitalize())),Vector2(130+index*440,680))
		await capture("family-"+base)
	clear_stage();label("Ascua · daño crítico + carga + transformación + KO",Vector2(40,30))
	var moves := [{"id":"fixture-charge","animation":"charge","windup":0.35,"travel":0.22,"recovery":0.4}]
	var a=actor("ascua",Vector2(195,615),0.1,1.2);a.play_move(moves[0]);a._process(0.24)
	var b=actor("ascua",Vector2(520,615),0.1,1.2);b.play_transformation();b._process(0.8)
	var c=actor("ascua",Vector2(850,615),0.1,1.2);c.resolve_battle(true);c._process(1)
	var d=actor("ascua",Vector2(1170,615),0.0,1.2);d.fall();d._process(1)
	await capture("ascua-critical-continuity")
	print("DAMAGE FAMILY SHOWCASE: native captures complete");quit()
