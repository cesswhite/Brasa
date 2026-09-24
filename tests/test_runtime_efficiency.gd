extends SceneTree
## Behavioral guards for optimization boundaries; no timing-dependent pass/fail.
const Visuals = preload("res://scripts/ui/game_visual_system.gd")
const Preview = preload("res://scripts/ui/components/game_fighter_preview.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Damage = preload("res://scripts/damage_art.gd")
const Base = preload("res://tests/test_identity_integration.gd")
var checks := 0
var failures := 0
func _init(): run.call_deferred()
func check(ok: bool, message: String):
	checks += 1
	if not ok: failures += 1; push_error(message)
func run():
	var tokens := Visuals.tokens();tokens.colors.text_primary="000000"
	check(Visuals.color("text_primary")==Visuals.CREAM,"Public token edits cannot mutate shared styling")
	var registry := Visuals.World.manifest();registry.clear()
	check(not Visuals.World.manifest().is_empty(),"Public manifest remains a defensive copy")
	for type: String in ["Button","OptionButton","CheckBox","CheckButton","LineEdit","TextEdit","Tree","ItemList"]:
		var focus := Visuals.theme().get_stylebox("focus",type) as StyleBoxFlat
		check(focus != null and focus.bg_color.a>0,"Visible keyboard focus: "+type)
		check(focus.get_border_width_min()==0 and focus.get_expand_margin(SIDE_LEFT)<0,"No external focus border: "+type)
	var a := Damage.bank("nima","base")
	a.frames.idle.damage_variant="mutated"
	check(Damage.bank("nima","base").frames.idle.damage_variant=="illustrated","Public damage bank edits cannot corrupt rendered frames")
	var canvas := SubViewport.new();canvas.size=Vector2i(600,400);root.add_child(canvas)
	var scroll := ScrollContainer.new();scroll.size=Vector2(300,160);canvas.add_child(scroll)
	var list := VBoxContainer.new();scroll.add_child(list)
	var first: Control;var last: Control
	for i in range(4):
		var portrait := Preview.new();portrait.custom_minimum_size=Vector2(250,160);list.add_child(portrait)
		portrait.configure({},Catalog.definition("nima"))
		if i==0:first=portrait
		last=portrait
	for i in range(4):await process_frame
	first._sync_motion();last._sync_motion()
	check(first.actor().is_processing(),"Visible portrait keeps animating")
	check(not last.actor().is_processing(),"Clipped offscreen portrait stops animation")
	scroll.scroll_vertical=10000
	for i in range(3):await process_frame
	check(last.actor().is_processing() and not first.actor().is_processing(),"Scrolling resumes the entering portrait and suspends the outgoing one")
	last.set_motion(true,false)
	check(not last.actor().is_processing(),"Explicit pause survives viewport visibility")
	last.set_motion(false,true)
	check(last.actor().is_processing() and last.actor().reduced_motion,"Reduced motion preference survives resume")
	canvas.free()
	var folder := ProjectSettings.globalize_path("res://../../work/performance-ui/fixtures")
	DirAccess.make_dir_recursive_absolute(folder)
	var screen := Base.Fixture.new();screen.fixture_path=folder.path_join("runtime-%d.json" % Time.get_ticks_usec())
	var profile := Base.Progress.new();profile.load_save(screen.fixture_path);profile.select_character("nima","Prueba")
	root.add_child(screen);screen.size=Vector2(1360,880);screen._show_menu()
	for i in range(4):await process_frame
	screen.modal_layer.modulate.a=1;screen._process(0)
	check(not screen.arena.visible and screen.arena.process_mode==Node.PROCESS_MODE_DISABLED,"Opaque menu suspends underlying arena")
	screen._close_modal();screen._process(0)
	check(screen.arena.visible and screen.arena.process_mode==Node.PROCESS_MODE_INHERIT,"Closing menu restores arena")
	screen.free()
	print("RUNTIME EFFICIENCY: %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
