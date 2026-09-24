extends SceneTree
const Base = preload("res://tests/test_identity_integration.gd")
const Online = preload("res://scripts/ui/online_panel.gd")
const Fixtures = preload("res://tests/test_online_ui.gd")
var checks := 0
var failures := 0
func _init() -> void: run.call_deferred()
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func settle() -> void:
	for i in range(6): await process_frame
func run() -> void:
	var canvas := SubViewport.new()
	root.add_child(canvas)
	for extent: Vector2i in [Vector2i(1360,880),Vector2i(390,844),Vector2i(844,390)]:
		canvas.size = extent
		var main := Base.Fixture.new()
		main.fixture_path = ProjectSettings.globalize_path("res://../../work/ux-review/fixture-%d.json" % Time.get_ticks_usec())
		var profile := Base.Progress.new()
		profile.load_save(main.fixture_path)
		profile.select_character("mugo","Prueba UI")
		canvas.add_child(main)
		main.size = Vector2(extent)
		main._layout_interface(main.size)
		var original: Dictionary = main.progression.data.duplicate(true)
		main._show_help()
		await settle()
		check(not main.modal_layer.manual_content,"Help uses native, scrollable topic sections")
		var reader: Control = main.modal_layer.content().get_child(0)
		var topics := 0
		for child: Node in reader.get_children():
			if child is Button:
				topics += 1
				var content: Control = reader.get_child(child.get_index()+1)
				check(not content.visible,"Help topic starts closed")
				child.button_pressed = true
				check(content.visible,"Tap or keyboard opens topic content")
				child.button_pressed = false
		check(topics>=8,"All detailed help topics remain accessible")
		main._close_modal()
		await settle()
		main._show_history()
		await settle()
		check(is_instance_valid(main.modal_accept),"Empty history offers return action")
		main.modal_accept.pressed.emit()
		check(not is_instance_valid(main.modal_layer),"Empty-state action returns to arena")
		check(main.progression.data==original,"Reading help and returning never mutate progress")
		main.free()
		await settle()
		var api := Fixtures.FixtureApi.new()
		canvas.add_child(api)
		var online := Online.new()
		canvas.add_child(online)
		online.configure(api)
		await settle()
		online._select_tab(2)
		await settle()
		for section in range(4):
			online._select_profile_section(section)
			await settle()
			check(online._profile_section==section,"Profile section changes locally")
			check(online._scroll.scroll_vertical==0,"New section starts at its heading")
			check(not online._eyebrow.visible,"Online header has no duplicate overlaid label")
			for button: Button in online._buttons:
				check(button.get_global_rect().end.x<=online._scroll.get_global_rect().end.x+1,"Online action stays within reading column")
		check(api.writes==0,"Browsing online sections never sends mutations")
		online.free()
		api.free()
		await settle()
	canvas.free()
	print("UX CLARITY: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
