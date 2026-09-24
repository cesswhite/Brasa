extends SceneTree
## Actual Main completion/rewards, isolated files, painted sprite bounds rather
## than ideal layout boxes. Initial HP selects test outcomes; never a balance sim.
const Base = preload("res://tests/test_identity_integration.gd")
const Progress = preload("res://scripts/progression.gd")
const Story = preload("res://scripts/story_progression.gd")
const Sizes = preload("res://tests/test_battle_layout.gd")

var checks := 0
var failures := 0
var screen
var canvas: SubViewport
var context := ""
var output_dir := ""
var captures := ""
var observations: Array[Dictionary] = []

func _init() -> void: _run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("RESULT VISIBILITY: "+message+" "+context)

func _run() -> void:
	create_timer(150,true,false,true).timeout.connect(func(): push_error("RESULT VISIBILITY timeout"); quit(1))
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): captures=argument.trim_prefix("--capture-dir=")
	output_dir = ProjectSettings.globalize_path("res://../../work/visual-system/result-visibility-qa").simplify_path()
	DirAccess.make_dir_recursive_absolute(output_dir.path_join("fixtures"))
	if not captures.is_empty(): DirAccess.make_dir_recursive_absolute(captures)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(360,240)
	canvas = SubViewport.new()
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	for view: Vector2 in Sizes.SIZES:
		canvas.size = Vector2i(view)
		for won: bool in [true,false]:
			context = "%dx%d/%s" % [view.x,view.y,"victory" if won else "defeat"]
			var path := output_dir.path_join("fixtures/result-%dx%d-%s-%d.json" % [view.x,view.y,str(won),Time.get_ticks_usec()])
			var seed_profile := Progress.new()
			seed_profile.load_save(path)
			check(seed_profile.select_character("mugo"),"Create isolated Mugo profile")
			var story_profile := Story.new()
			story_profile.load_save(path+".story.json")
			story_profile.select_character("mugo")
			var story_bytes := FileAccess.get_file_as_bytes(path+".story.json")
			screen = Base.Fixture.new()
			screen.fixture_path = path
			canvas.add_child(screen)
			screen.size = view
			screen._layout_interface(view)
			_freeze(screen)
			var rival_profile := Progress._new_profile("onix")
			rival_profile.name = "Nara"
			screen.rival = Progress._combatant(rival_profile)
			screen.rival["opponent_id"] = "npc_visibility_onix"
			screen._start_fight()
			check(screen.active_match,"Start real Main battle through existing action")
			var options := {"initial_hp":{"rival":1.0} if won else {"player":1.0},"opening_time":0.2,"disable_signatures":true,"battle_id":"visibility-"+context}
			screen.combat.start(screen._player_combatant(),screen.rival,852901 if won else 852902,options)
			var events: Array[Dictionary] = screen.combat.advance(120)
			check(screen.combat.winner==("player" if won else "rival"),"Seeded real engine yields intended fixture outcome")
			screen._dispatch_events(events)
			while screen.active_match: await process_frame
			check(screen.result_panel.visible and not screen.finishing,"Actual finish handler presents result")
			check(screen.progression.history.size()==1 and int(screen.progression.data.matches)==1,"One match grants rewards and records once")
			check(screen.player_view.get_sprite_geometry().path=="res://assets/sprites/golem-v2.png","Result still shows actual Mugo body")
			check(screen.rival_view.get_sprite_geometry().path=="res://assets/sprites/onix-v1.png","Result retains Onix/Nara body from completed fight")
			var immutable_events := var_to_bytes(screen.combat.event_log)
			var immutable_profile := var_to_bytes(screen.progression.data)
			var immutable_history := var_to_bytes(screen.progression.history)
			var saved := FileAccess.get_file_as_bytes(path)
			var terminal_time: float = screen.combat.elapsed
			# Manually settle presentation only. No engine tick, pose substitution or
			# physical transform override is used to make the geometry test pass.
			_advance_presentation(1.2)
			await create_timer(0.24,true,false,true).timeout
			await _settle()
			check(screen.result_panel.modulate.a>=0.999,"Result fade is settled")
			check(screen.player_view._mode==("victory" if won else "fall"),"Mugo keeps correct terminal animation")
			check(screen.rival_view._mode==("fall" if won else "victory"),"Onix keeps opposite terminal animation")
			for sample: int in range(3):
				_check_painted_visibility(view,won,1.2+sample*0.2)
				if sample<2: _advance_presentation(0.2)
			await _capture(view,won)
			check(screen.combat.elapsed==terminal_time and var_to_bytes(screen.combat.event_log)==immutable_events,"Visual settling never advances or rewrites authoritative combat")
			check(var_to_bytes(screen.progression.data)==immutable_profile and var_to_bytes(screen.progression.history)==immutable_history,"Settling cannot award again or change history")
			check(FileAccess.get_file_as_bytes(path)==saved,"Settling performs no extra profile save")
			# The old finish event and original result callbacks remain safe.
			screen._dispatch_events([events.back()])
			check(var_to_bytes(screen.progression.data)==immutable_profile and screen.progression.history.size()==1,"Repeated terminal dispatch does not repeat rewards")
			for pair: Array in [[screen.fight_button,"_primary_action"],[screen.summary_button,"_show_summary"],[screen.training_button,"_show_training"],[screen.roster_button,"_show_roster"]]:
				check(_has_callback(pair[0],pair[1]),"Original callback retained: "+str(pair[1]))
			screen.summary_button.pressed.emit()
			await _settle()
			check(is_instance_valid(screen.modal_body) and screen.modal_body.text.contains("XP"),"Summary action still opens actual reward explanation")
			screen._close_modal()
			await _settle()
			check(FileAccess.get_file_as_bytes(path)==saved and var_to_bytes(screen.progression.history)==immutable_history,"Summary navigation preserves result and rewards")
			check(FileAccess.get_file_as_bytes(path+".story.json")==story_bytes,"League result never writes separate Story profile")
			screen.free()
			await process_frame
	canvas.free()
	var report := FileAccess.open(output_dir.path_join("native-bounds.json" if DisplayServer.get_name()!="headless" else "headless-bounds.json"),FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"fixture":"Seeded actual engine with initial HP selected to produce both outcomes; no real user saves","presentation_seconds":[1.2,1.4,1.6]},"  "))
	report.close()
	print("VISUAL RESULT VISIBILITY: %d checks, %d failures across 7 sizes and 2 outcomes" % [checks,failures])
	quit(0 if failures==0 else 1)

func _check_painted_visibility(view: Vector2, won: bool, visual_time: float) -> void:
	var result_rect: Rect2 = screen.result_panel.get_global_rect()
	var viewport := Rect2(Vector2.ZERO,view)
	var buttons: Array[Button] = [screen.fight_button,screen.training_button,screen.roster_button,screen.speed_button,screen.log_button,screen.summary_button,screen.surrender_button,screen.menu_button,screen.story_button]
	check(viewport.grow(1).encloses(result_rect),"Result fits viewport")
	for child: Control in [screen.result_title,screen.result_copy]:
		check(result_rect.grow(1).encloses(child.get_global_rect()),"Result text stays inside result area")
	for side: String in ["player","rival"]:
		var actor = screen.player_view if side=="player" else screen.rival_view
		var measured := _painted_boundary(actor)
		check(not measured.is_empty(),"Actual painted frame exists: "+side)
		if measured.is_empty(): continue
		var rect: Rect2 = measured.rect
		var conflicts: Array[String] = []
		check(viewport.grow(1).encloses(rect),"Painted "+side+" silhouette stays in viewport: "+str(rect))
		check(screen.result_veil.visible and screen.result_panel.get_index()>screen.result_veil.get_index(),"Centered result overlays the dimmed completed scene")

		# HUD has native labels/bars, not a painted container covering the entire
		# layout reservation. Check actual controls, excluding its empty padding.
		for item: Array in [[screen.player_name_label,"player_name"],[screen.rival_name_label,"rival_name"],[screen.player_level_label,"player_level"],[screen.rival_level_label,"rival_level"],[screen.player_bar,"player_hp_rail"],[screen.rival_bar,"rival_hp_rail"],[screen.player_hp_label,"player_hp"],[screen.rival_hp_label,"rival_hp"]]:
			var hud_control: Control = item[0]
			if not hud_control.is_visible_in_tree(): continue
			check(not rect.intersects(hud_control.get_global_rect()),"Painted "+side+" silhouette avoids visible HUD "+str(item[1]))
			if rect.intersects(hud_control.get_global_rect()): conflicts.append("hud_"+str(item[1]))
		for button: Button in buttons:
			if not button.is_visible_in_tree() or button == screen.fight_button: continue
			check(not rect.intersects(button.get_global_rect()),"Painted "+side+" silhouette avoids control "+button.text)
			if rect.intersects(button.get_global_rect()): conflicts.append(button.text)
		for label: Label in [screen.player_status_label,screen.rival_status_label]:
			if not label.is_visible_in_tree() or label.text.is_empty(): continue
			check(not rect.intersects(label.get_global_rect()),"Visible terminal status avoids painted "+side+" silhouette")
			if rect.intersects(label.get_global_rect()): conflicts.append("status_"+label.text)
		observations.append({"viewport":[view.x,view.y],"winner":"player" if won else "rival","side":side,"visual_time":visual_time,"painted_rect":_rect_json(rect),"result_rect":_rect_json(result_rect),"actor_position":[actor.position.x,actor.position.y],"scale":actor.scale.x,"mode":actor._mode,"frame":str(actor._current_frame().get("name","")),"conflicts":conflicts})

func _painted_boundary(actor) -> Dictionary:
	var sprite: Sprite2D = actor.get("_sprite")
	if not is_instance_valid(sprite) or sprite.texture==null: return {}
	var current: Dictionary = actor._current_frame()
	var local := Rect2(Vector2(current.bounds.position)-Vector2(current.anchor),Vector2(current.bounds.size))
	var transform: Transform2D = sprite.get_global_transform()
	var corners: Array[Vector2] = [transform*local.position,transform*Vector2(local.end.x,local.position.y),transform*local.end,transform*Vector2(local.position.x,local.end.y)]
	var rectangle := Rect2(corners[0],Vector2.ZERO)
	for point: Vector2 in corners: rectangle=rectangle.expand(point)
	return {"rect":rectangle}

func _advance_presentation(seconds: float) -> void:
	var steps := ceili(seconds*60.0)
	for index in range(steps):
		for actor: Node2D in [screen.player_view,screen.rival_view]: actor._process(seconds/steps)
		screen.combat_fx._process(seconds/steps)

func _freeze(node: Node) -> void:
	if node is Node2D: node.set_process(false)
	for child: Node in node.get_children(): _freeze(child)

func _has_callback(button: Button, method: String) -> bool:
	for connection: Dictionary in button.pressed.get_connections():
		var action: Callable = connection.callable
		if action.get_object()==screen and str(action.get_method())==method: return true
	return false

func _rect_json(rect: Rect2) -> Array:
	return [rect.position.x,rect.position.y,rect.size.x,rect.size.y]

func _settle() -> void:
	for i in range(3): await process_frame

func _capture(view: Vector2, won: bool) -> void:
	if captures.is_empty() or DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	check(canvas.get_texture().get_image().save_png(captures.path_join("result-%s-%dx%d.png" % ["victory" if won else "defeat",view.x,view.y]))==OK,"Capture actual settled outcome")
