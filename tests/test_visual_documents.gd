extends SceneTree
## Migrated League profile/training: real controls against disposable saves only.
const Base = preload("res://tests/test_identity_integration.gd")
const Progress = preload("res://scripts/progression.gd")
const Story = preload("res://scripts/story_progression.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Views = preload("res://tests/test_battle_layout.gd")
var checks := 0
var failures := 0
var screen
var canvas: SubViewport
var capture_dir := ""

func _init() -> void: _run.call_deferred()
func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("VISUAL DOCUMENTS: "+description)

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): capture_dir = arg.trim_prefix("--capture-dir=")
	if not capture_dir.is_empty(): DirAccess.make_dir_recursive_absolute(capture_dir)
	create_timer(90,true,false,true).timeout.connect(func(): push_error("VISUAL DOCUMENTS timeout"); quit(1))
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(360,240)
	canvas = SubViewport.new()
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	var directory := ProjectSettings.globalize_path("res://../../work/visual-system/fixtures").simplify_path()
	DirAccess.make_dir_recursive_absolute(directory)
	for view: Vector2 in Views.SIZES:
		canvas.size = Vector2i(view)
		var path := directory.path_join("documents-%dx%d-%d.json" % [view.x,view.y,Time.get_ticks_usec()])
		var league := Progress.new()
		league.load_save(path)
		league.select_character("onix")
		var campaign := Story.new()
		campaign.load_save(path+".story.json")
		campaign.select_character("mugo")
		var before_file := FileAccess.get_file_as_string(path)
		var story_file := FileAccess.get_file_as_string(path+".story.json")
		screen = Base.Fixture.new()
		screen.fixture_path = path
		canvas.add_child(screen)
		screen.size = view
		screen._layout_interface(view)
		screen._show_training()
		await _settle()
		check(screen.modal_kind=="training" and screen.stat_buttons.size()==4,"Four real League improvements at "+str(view))
		check(screen.training_content.custom_minimum_size.x==0,"No retained 800px minimum at "+str(view))
		check(screen.training_content.size.x<=screen.training_scroll.size.x+1,"Training content fits scroll width at "+str(view))
		check(screen.training_scroll.size.y>=48,"Training has usable vertical viewport at "+str(view))
		check(screen.modal_canvas.get_global_rect().grow(1).encloses(screen.training_scroll.get_global_rect()),"Training scroll stays inside document canvas at "+str(view))
		for i in range(4):
			var button: Button = screen.stat_buttons[i]
			var card: Control = screen.stat_cards[i]
			check(button.size.x>=48 and button.size.y>=48,"Training touch size "+str(i)+" "+str(view))
			check(not button.disabled,"Initial points allow improvement "+str(i))
			check(card.get_global_rect().grow(1).encloses(button.get_global_rect()),"Button belongs to its card "+str(i))
			check(card.position.x>=0 and card.position.x+card.size.x<=screen.training_content.size.x+1,"Both training columns fit "+str(i)+" "+str(view))
			for label: Label in [screen.stat_titles[i],screen.stat_values[i],screen.stat_effects[i]]:
				check(not label.text.is_empty(),"Training label is populated "+str(i))
				check(card.get_global_rect().grow(1).encloses(label.get_global_rect()),"Training label is inside its card "+str(i))
				check(_text_fits(label),"Training label reads in full: "+label.text.replace("\n"," / ")+" "+str(view))
			button.grab_focus()
			await _settle()
			check(screen.training_scroll.get_global_rect().grow(1).encloses(button.get_global_rect()),"Scroll reveals complete focused improvement "+str(i)+" "+str(view))
		await _capture("ready",view)
		var before_help: Dictionary = screen.progression.data.duplicate(true)
		for i in [0,3]:
			screen.stat_help_buttons[i].pressed.emit()
			await _settle()
			check(screen.stat_descriptions[i].visible,"Help opens inline for selected attribute")
			check(screen.stat_cards[i].get_global_rect().grow(1).encloses(screen.stat_descriptions[i].get_global_rect()),"Inline description fits its card")
			check(screen.training_scroll.get_global_rect().grow(1).encloses(screen.stat_descriptions[i].get_global_rect()),"Touch help scrolls into view")
			check(screen.stat_help_buttons[i].size.x>=48 and screen.stat_help_buttons[i].size.y>=48,"Help has a touch-sized target")
		check(not screen.stat_descriptions[0].visible,"Only one explanation remains open")
		await _capture("help",view)
		screen.stat_help_buttons[3].pressed.emit()
		await _settle()
		check(not screen.stat_descriptions[3].visible,"Help can be collapsed")
		check(screen.progression.data==before_help,"Reading explanations does not spend points")
		check(FileAccess.get_file_as_string(path)==before_file,"Reading training does not save")
		var profile: Dictionary = screen.progression.data.duplicate(true)
		screen.stat_buttons[0].pressed.emit()
		await _settle()
		check(int(screen.progression.data.points)==int(profile.points)-1,"One button consumes exactly one point")
		check(int(screen.progression.data.stats.life)==int(profile.stats.life)+1,"One button improves its actual attribute")
		for key: String in ["strength","agility","speed"]:
			check(screen.progression.data.stats[key]==profile.stats[key],"Unselected attribute unchanged: "+key)
		for key: String in ["level","xp","wins","losses","matches"]:
			check(screen.progression.data.get(key)==profile.get(key),"Training preserves progression field: "+key)
		var reloaded := Progress.new()
		reloaded.load_save(path)
		check(reloaded.data==screen.progression.data,"Upgrade persists in disposable League file")
		check(screen.stat_values[0].text==str(screen.progression.data.stats.life),"Visible number updates after upgrade")
		check("Vida mejorada" in screen.training_notice.text,"Upgrade gives visible success feedback")
		await _capture("upgraded",view)
		var saved_points: int = screen.progression.data.points
		screen.progression.data.points = 0
		screen._refresh_manager()
		check("experiencia" in screen.training_notice.text,"No-points state explains how to get more")
		for i in range(4):
			check(screen.stat_buttons[i].disabled and not screen.stat_help_buttons[i].disabled,"Help remains available without points")
		await _capture("no-points",view)
		screen.progression.data.points = saved_points
		screen._refresh_manager()
		screen._close_modal()
		await _settle()
		screen._show_fighter_details()
		await _settle()
		check(screen.modal_kind=="document" and is_instance_valid(screen.document_preview),"Profile uses shared document and actual fighter")
		check(screen.modal_body.size.x>=140 and screen.modal_body.size.y>=48,"Profile retains readable text area at "+str(view))
		check(screen.modal_canvas.get_global_rect().grow(1).encloses(screen.modal_body.get_global_rect()),"Profile text fits document canvas at "+str(view))
		check(not screen.document_preview.get_global_rect().intersects(screen.modal_body.get_global_rect()),"Profile and fighter columns do not overlap")
		var details = screen.profile_details
		var unchanged := var_to_bytes(screen.progression.data)
		check(details.attributes.get_child_count()==9,"Nine attributes stay available")
		check(not details.profile_content.visible and not details.rules_label.visible,"Long explanations start collapsed")
		check(not details.help_panel.visible,"Formula starts collapsed")
		check(screen.modal_canvas.get_global_rect().grow(1).encloses(details.get_global_rect()),"New profile fits document canvas")
		check(details.content.size.x<=details.size.x+1,"Profile never overflows horizontally")
		await _profile_capture("resumen",view)
		for i in range(details.rows.size()):
			var row: Dictionary = details.rows[i]
			check(row.value==screen._stat_value(row.key,screen._current_stats(screen.progression.data)[row.key]),"Visible stat uses actual profile: "+str(row.key))
			check(details.stat_buttons[i].size.y>=44,"Attribute has touch target")
			for label: Label in details.stat_buttons[i].find_children("*","Label",true,false):
				if label.visible: check(details.stat_buttons[i].get_global_rect().grow(1).encloses(label.get_global_rect()),"Stat label fits card")
			details.stat_buttons[i].grab_focus()
			await _settle()
			check(details.get_global_rect().grow(1).encloses(details.stat_buttons[i].get_global_rect()),"Keyboard reveals full attribute")
			details.stat_buttons[i].pressed.emit()
			await _settle()
			check(details.help_panel.visible and str(row.description) in details.help_label.text,"Selecting reveals actual formula")
			check(details.content.get_global_rect().grow(1).encloses(details.help_label.get_global_rect()),"Explanation fits content")
		await _profile_capture("detalle",view)
		details.stat_buttons[8].pressed.emit()
		details.growth_button.button_pressed = true
		await _settle()
		for label: Label in details.growth_labels: check(label.visible,"Growth shown only on request")
		details.scroll_vertical = 0
		await _profile_capture("crecimiento",view)
		details.profile_button.button_pressed = true
		details.rules_button.button_pressed = true
		await _settle()
		check(details.profile_content.visible and details.rules_label.visible,"Optional biography and progression are accessible")
		details.scroll_vertical = 10000
		await _profile_capture("perfil",view)
		check(var_to_bytes(screen.progression.data)==unchanged,"All reading controls leave profile unchanged")

		screen._close_modal()
		await _settle()
		check(FileAccess.get_file_as_string(path+".story.json")==story_file,"Training never modifies separate Story save")
		check(screen.session_save_path==path,"Fixture path remains explicit")
		screen.free()
		await process_frame
	canvas.free()
	await process_frame
	print("VISUAL DOCUMENTS: %d checks, %d failures across 7 sizes" % [checks,failures])
	quit(0 if failures==0 else 1)

func _settle() -> void:
	for frame in range(4): await process_frame

func _text_fits(label: Label) -> bool:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var lines := label.text.split("\n")
	for line: String in lines:
		if font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>label.size.x+1: return false
	return font.get_height(font_size)*lines.size()<=label.size.y+1

func _capture(state: String, view: Vector2) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name()=="headless" or int(view.x) not in [1360,390]: return
	screen.training_scroll.scroll_vertical = 0
	await _settle()
	if state=="help": screen.training_scroll.ensure_control_visible(screen.stat_descriptions[3])
	await _settle()
	await create_timer(0.3).timeout
	RenderingServer.force_draw()
	canvas.get_texture().get_image().save_png(capture_dir.path_join("%s-%dx%d.png" % [state,int(view.x),int(view.y)]))

func _profile_capture(state: String, view: Vector2) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name()=="headless": return
	await _settle()
	RenderingServer.force_draw()
	check(canvas.get_texture().get_image().save_png(capture_dir.path_join("ficha-%s-%dx%d.png" % [state,view.x,view.y]))==OK,"Native profile capture")
