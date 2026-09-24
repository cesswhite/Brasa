extends SceneTree
## In-memory UI fixtures plus a unique, cleaned work/story adapter save; no real saves.
## Optional -- --capture-dir=/absolute/path renders native SubViewport PNGs.
const PanelScript = preload("res://scripts/ui/story_panel.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Story = preload("res://scripts/story_catalog.gd")
const RealStory = preload("res://scripts/story_progression.gd")
const SIZES: Array[Vector2i] = [Vector2i(1360,880),Vector2i(1224,792),Vector2i(1920,1080),Vector2i(768,1024),Vector2i(390,844),Vector2i(430,932),Vector2i(844,390)]

class MainThemeFixture:
	extends "res://scripts/main.gd"
	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_build_theme()
		set_process(false)

class MemoryStory:
	extends RefCounted
	var data: Dictionary = {}
	var roster: Dictionary = {}
	var save_blocked := false
	var last_save_ok := true
	var active_id := ""
	var load_notice := ""
	var cooldown_remaining := 0.0
	func choose(id: String) -> void:
		if not roster.has(id):
			var definition: Dictionary = Catalog.definition(id)
			var assigned: Dictionary = {}
			for entry: Dictionary in Story.allocations(): assigned[str(entry.key)] = 0
			roster[id] = {"name":definition.name,"character_id":id,"archetype":definition.archetype,"level":1,"xp":0,"points":3,"stats":definition.training_base.duplicate(true),"allocations":assigned,"chapter":1,"chapter_summaries":{},"current_stage":0,"completed":false,"attempts":{},"last_hint":"","defeated":[],"matches":0,"losses":0,"retries":0,"badge":"","total_xp":0}
		active_id = id
		data = roster[id]
	func current_stage() -> int: return int(data.get("current_stage",0))
	func current_chapter() -> int: return int(data.get("chapter",1))
	func is_complete() -> bool: return bool(data.get("completed",false))
	func can_start_next_chapter() -> bool: return is_complete() and current_chapter()==1
	func xp_needed() -> int: return 100
	func seconds_until_next_match() -> float: return cooldown_remaining
	func completion_summary(chapter: int=0) -> Dictionary:
		if chapter>0 and chapter!=current_chapter(): return data.get("chapter_summaries",{}).get(str(chapter),{}).duplicate(true)
		var base: Dictionary = data.duplicate(true)
		base.level = 1
		for key: String in base.allocations: base.allocations[key] = 0
		return {"completed":is_complete(),"name":data.name,"character_id":data.character_id,"level":data.level,"stats":Story.stats_for(data),"base_stats":Story.stats_for(base),"battles":data.matches,"defeats":data.losses,"retries":data.retries,"badge":"Guardián de los Faroles","allocations":data.allocations,"total_xp":data.total_xp,"unspent_points":data.points}

var checks := 0
var failures := 0
var panel
var model := MemoryStory.new()
var canvas: SubViewport
var selection := ""
var upgrades: Array[String] = []
var fights := 0
var closes := 0
var exits := 0
var chapter_requests := 0
var captures := ""

func _init() -> void: call_deferred("_run")

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("STORY PANEL FAIL: "+message)

func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1360,880)
	var holder := SubViewportContainer.new()
	root.add_child(holder)
	canvas = SubViewport.new()
	canvas.size = SIZES[0]
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	holder.add_child(canvas)
	var themed_parent := MainThemeFixture.new()
	canvas.add_child(themed_parent)
	panel = PanelScript.new()
	themed_parent.add_child(panel)
	panel.character_chosen.connect(func(id: String): selection=id)
	panel.upgrade_requested.connect(func(key: String): upgrades.append(key))
	panel.fight_requested.connect(func(): fights+=1)
	panel.closed.connect(func(): closes+=1)
	panel.league_requested.connect(func(): exits+=1)
	panel.next_chapter_requested.connect(func(): chapter_requests+=1)
	panel.configure(model)
	await _settle()
	_check(panel._active_tab == "companions","new Story opens roster selection")
	_check(panel._character_buttons.size() == Catalog.IDS.size(),"all campaigns available initially")
	panel._select_character(str(Catalog.IDS[8]))
	panel._primary_pressed()
	_check(selection == str(Catalog.IDS[8]),"selection emits selected character ID")
	_check(model.data.is_empty() and model.roster.is_empty(),"panel never creates or saves profiles itself")
	model.choose(selection)
	panel.refresh()
	_check(panel._active_tab == "route","controller-selected campaign opens route")
	_check(panel._heading.text.begins_with("Capítulo 1") and panel._subtitle.text.contains("Nivel 1"),"chapter heading and character level have distinct labels")
	_check(panel._stage_buttons.size() == 8,"route includes eight encounters")
	panel._select_stage(7)
	_check(panel._primary.disabled,"future Boss preview cannot launch out of order")
	panel._primary_pressed()
	_check(fights == 0,"locked stage emits no battle request")
	panel._select_stage(0)
	panel._primary_pressed()
	_check(fights == 1,"current encounter emits one battle request")
	_check(model.data.matches == 0,"fight request itself cannot mutate progression")
	model.cooldown_remaining = 3.2
	panel.refresh()
	_check(panel._primary.disabled and panel._primary.text == "Reintento en 4 s","surrender cooldown shows rounded-up time on disabled CTA")
	panel._primary_pressed()
	_check(fights == 1 and panel._active_tab == "route","cooldown never emits a battle request or dismisses the route")
	model.cooldown_remaining = 1.2
	panel._process(0.1)
	_check(panel._primary.text == "Reintento en 2 s","cooldown updates its label without rebuilding the panel")
	model.cooldown_remaining = 0.0
	panel._process(0.1)
	_check(not panel._primary.disabled and panel._primary.text == "Entrar al combate","expiry restores the normal battle action")
	panel._primary_pressed()
	_check(fights == 2,"expired cooldown emits one normal battle request")
	panel.show_tab("upgrades")
	_check(panel._upgrade_buttons.size() == 8,"eight direct stat choices are available")
	var key: String = str(Story.allocations()[0].key)
	panel._upgrade_buttons[key].pressed.emit()
	_check(upgrades == [key],"allocation emits stable stat key")
	_check(model.data.points == 3 and int(model.data.allocations[key]) == 0,"allocation UI never spends points itself")
	model.data.points = 0
	panel.refresh()
	for button: Button in panel._upgrade_buttons.values(): _check(button.disabled,"zero points disables all allocation controls")
	model.data.points = 5
	model.data.current_stage = 3
	model.data.level = 5
	model.data.xp = 28
	model.data.last_hint = "Tus ataques fallaron con frecuencia. Mejorar precisión puede ayudar."
	panel.refresh()
	panel.show_tab("route")
	_check(panel._selected_stage == 3,"advancing controller selects the new current encounter")
	_check(is_instance_valid(panel._last_hint),"post-defeat contextual hint appears from recorded data")
	model.data.last_hint = ""
	model.data.attempts[str(Story.stage(3).id)] = 1
	panel.refresh()
	_check(panel._primary.text == "Pelear otra vez","failed current encounter offers retry")
	var saved_first: Dictionary = model.data.duplicate(true)
	model.choose(str(Catalog.IDS[0]))
	panel.refresh()
	_check(model.roster[selection] == saved_first,"switching campaigns preserves previous profile")
	_check(panel._selected_stage == 0,"new campaign starts at its own first encounter")
	model.choose(selection)
	panel.refresh()
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			captures = argument.trim_prefix("--capture-dir=")
			DirAccess.make_dir_recursive_absolute(captures)
	var before: Dictionary = model.roster.duplicate(true)
	for view: Vector2i in SIZES:
		await _check_size(view)
	_check(model.roster == before,"all tab changes and resizes preserve every campaign")
	model.data.current_stage = 8
	model.data.completed = true
	model.data.level = 12
	model.data.matches = 15
	model.data.losses = 7
	model.data.retries = 7
	model.data.total_xp = 2400
	model.data.allocations[key] = 4
	panel.refresh()
	_check(panel._active_tab == "legacy","Boss victory opens completion presentation by default")
	_check(panel._primary.text=="Comenzar capítulo 2" and _find_label(panel._body,"CAPÍTULO 2 DESBLOQUEADO")!=null,"Ascua legacy explicitly offers unlocked second chapter")
	_check(chapter_requests==0 and model.current_chapter()==1,"completion never starts a chapter automatically")
	model.save_blocked = true
	panel.refresh()
	panel._primary_pressed()
	_check(panel._primary.disabled and chapter_requests==0,"protected save cannot emit a chapter-start request")
	model.save_blocked = false
	panel.refresh()
	for view: Vector2i in SIZES:
		canvas.size = view
		await _settle()
		_check(panel._primary.get_global_rect().end.y <= view.y+1,"completion CTA stays reachable")
		_check(panel._body.size.x <= panel._scroll.size.x+1,"completion stats never overflow horizontally")
		_check(_victory_fits(),"raised victory arm and hop stay inside portrait frame")
		await _capture("legacy",view)
	var completed_profile: Dictionary = model.data.duplicate(true)
	panel._primary_pressed()
	_check(chapter_requests==1 and model.data==completed_profile,"chapter CTA emits exactly one request without changing stats, XP or profile")
	await _check_second_chapter(completed_profile)
	panel._primary_pressed()
	_check(panel._active_tab == "companions","final chapter completion offers another independent campaign")
	panel._league.pressed.emit()
	panel._close.pressed.emit()
	_check(exits == 1 and closes == 1,"league and close emit distinct navigation signals")
	model.save_blocked = true
	panel.refresh()
	_check(panel._primary.disabled,"protected save disables campaign mutations")
	_check(panel._save_notice.visible,"protected save notice is visible above the Story overlay")
	model.save_blocked = false
	model.last_save_ok = false
	model.load_notice = "No se pudo escribir la partida de prueba."
	panel.refresh()
	await _settle()
	_check(panel._save_notice.visible and panel._save_notice.text.contains(model.load_notice),"failed save exposes the adapter reason inside the panel")
	_check(not panel._primary.disabled,"an ordinary I/O error does not block campaign interaction")
	_check(panel.get_global_rect().encloses(panel._save_notice.get_global_rect()) and panel._save_notice.size.y >= 14,"save failure is readable and inside viewport")
	await _capture("save-warning",canvas.size)
	canvas.size = Vector2i(390,844)
	await _settle()
	_check(panel.get_global_rect().encloses(panel._save_notice.get_global_rect()) and panel._save_notice.size.y >= 14,"phone keeps the save failure visible above scroll content")
	await _capture("save-warning",canvas.size)
	model.last_save_ok = true
	model.load_notice = ""
	panel.refresh()
	_check(not panel._save_notice.visible,"successful save removes the temporary warning")
	await _check_real_adapter()
	print("STORY PANEL: %d checks, %d failures across 7 native viewport sizes" % [checks,failures])
	quit(0 if failures == 0 else 1)

func _settle() -> void:
	for _i in range(6): await process_frame

func _check_second_chapter(completed_profile: Dictionary) -> void:
	var first_legacy: Dictionary = model.completion_summary(1).duplicate(true)
	# Simulates the caller accepting the explicit request; presentation never
	# invokes progression mutations, even when the next route is unlocked.
	model.data.chapter_summaries["1"] = first_legacy.duplicate(true)
	model.data.chapter = 2
	model.data.current_stage = 0
	model.data.completed = false
	model.data.attempts = {}
	model.data.matches = 0
	model.data.losses = 0
	model.data.last_hint = ""
	panel.refresh()
	await _settle()
	_check(panel._active_tab=="route" and panel._selected_stage==0,"accepted chapter change opens new route at its first encounter")
	_check(panel._heading.text=="Capítulo 2 · "+str(Story.chapter(2).title),"second chapter heading comes from catalog metadata")
	for key: String in ["level","xp","points","allocations","stats"]:
		_check(model.data[key]==completed_profile[key],"chapter presentation preserves "+key)
	_check(panel._stage_buttons.size()==8,"chapter two has its own eight encounters")
	_check(_find_label(panel._body,str(Story.opponent(0,2).name))!=null,"route preview uses chapter-two opponent")
	panel._select_stage(7)
	_check(panel._primary.disabled and _find_label(panel._body,str(Story.opponent(7,2).name))!=null,"new chapter boss preview is visible but cannot launch early")
	panel._select_stage(0)
	panel.show_tab("legacy")
	_check(_find_label(panel._body,"Tu siguiente paso")!=null,"unfinished chapter has its own pending legacy")
	panel._select_legacy(1)
	_check(_find_label(panel._body,"CAPÍTULO 1 COMPLETADO · 8 / 8 ENCUENTROS")!=null,"first chapter legacy remains accessible after starting chapter two")
	_check(panel._heading.text.begins_with("Logros de") and _find_label(panel._body,"Así terminó este capítulo. Este recuerdo conserva tus resultados de entonces.")!=null,"archived legacy header identifies the old chapter instead of current route")
	_check(panel._primary.text=="Volver al capítulo 2","historical legacy returns to current route without restarting it")
	panel._primary_pressed()
	_check(panel._active_tab=="route" and chapter_requests==1,"returning from historical legacy never emits another start request")
	for view: Vector2i in SIZES:
		canvas.size = view
		panel.show_tab("route")
		await _settle()
		_check(panel._heading.size.y>=20 and _labels_have_height(panel._body),"chapter two title and preview remain readable at "+str(view))
		_check(panel._body.size.x<=panel._scroll.size.x+1,"chapter two route fits horizontal bounds at "+str(view))
		_check(Rect2(Vector2.ZERO,Vector2(view)).grow(1).encloses(panel._primary.get_global_rect()) and panel._primary.size.y>=48,"chapter two CTA remains reachable at "+str(view))
		await _capture("chapter2-route",view)
		panel.show_tab("legacy")
		panel._select_legacy(1)
		await _settle()
		_check(panel._body.size.x<=panel._scroll.size.x+1 and _victory_fits(),"archived legacy and victory figure fit at "+str(view))
		for button: Button in panel._chapter_buttons:
			_check(button.size.y>=48 and not button.disabled,"both legacy selectors are touch sized and accessible after chapter two starts")
		await _capture("chapter1-archived",view)
	_check(model.completion_summary(1)==first_legacy,"all chapter views and resizes preserve the archived first legacy")
	model.data.completed = true
	model.data.current_stage = 8
	model.data.level = 18
	model.data.matches = 11
	model.data.losses = 3
	panel.refresh()
	await _settle()
	_check(panel._active_tab=="legacy" and panel._legacy_chapter==2,"second boss victory opens its own completed legacy")
	panel._select_legacy(2)
	_check(_find_label(panel._body,"CAPÍTULO 2 COMPLETADO · 8 / 8 ENCUENTROS")!=null,"second legacy is labelled separately from archived chapter one")
	_check(panel._primary.text=="Elegir compañero" and not model.can_start_next_chapter(),"last available chapter does not advertise a nonexistent third chapter")
	_check(model.completion_summary(1)==first_legacy,"second completion never overwrites first-chapter statistics")
	await _capture("chapter2-legacy",canvas.size)

func _check_size(view: Vector2i) -> void:
	canvas.size = view
	await _settle()
	var boundary := Rect2(Vector2.ZERO,Vector2(view))
	var prefix := "%dx%d: " % [view.x,view.y]
	_check(panel.size.is_equal_approx(Vector2(view)),prefix+"panel fills actual viewport")
	for button: Button in [panel._primary,panel._league,panel._close]:
		_check(boundary.grow(1).encloses(button.get_global_rect()),prefix+"fixed navigation remains onscreen")
		_check(button.size.y >= 48,prefix+"fixed navigation is a 48px touch target")
	_check(not panel._primary.get_global_rect().intersects(panel._league.get_global_rect()),prefix+"footer buttons never overlap")
	for tab: String in ["route","upgrades","companions"]:
		panel.show_tab(tab)
		await _settle()
		_check(panel._scroll.size.y >= 110,prefix+tab+" has a usable scroll area")
		_check(panel._body.size.x <= panel._scroll.size.x+1,prefix+tab+" has no horizontal overflow")
		_check(_labels_have_height(panel._body),prefix+tab+" wraps visible body text with readable line height")
		for button: Button in panel._tab_buttons.values():
			_check(boundary.grow(1).encloses(button.get_global_rect()) and button.size.y >= 48,prefix+"tabs are accessible")
		for grid: GridContainer in panel._content_grids:
			_check(grid.size.x <= panel._scroll.size.x+1,prefix+tab+" grid fits available width")
		if tab == "companions":
			_check(panel._character_buttons.size() == Catalog.IDS.size(),prefix+"all campaign choices remain present")
			panel._scroll.ensure_control_visible(panel._character_buttons[-1])
			await _settle()
			_check(panel._scroll.get_global_rect().intersects(panel._character_buttons[-1].get_global_rect()),prefix+"ninth campaign reachable by scroll")
		if tab == "upgrades":
			for button: Button in panel._upgrade_buttons.values(): _check(button.size.y >= 48,prefix+"allocation controls are touch sized")
		panel._scroll.scroll_vertical = 0
		await _settle()
		await _capture(tab,view)

func _capture(tab: String, view: Vector2i) -> void:
	if captures.is_empty(): return
	await RenderingServer.frame_post_draw
	canvas.get_texture().get_image().save_png(captures.path_join("%s-%dx%d.png" % [tab,view.x,view.y]))

func _labels_have_height(node: Node) -> bool:
	for child: Node in node.get_children():
		if child is Label and not child.text.is_empty() and child.size.y < 12:
			print("Unreadable height ",child.size,": ",child.text)
			return false
		if not _labels_have_height(child): return false
	return true

func _check_real_adapter() -> void:
	var folder := ProjectSettings.globalize_path("res://../../work/story/ui-fixtures").simplify_path()
	DirAccess.make_dir_recursive_absolute(folder)
	var path := folder.path_join("panel_%d.json" % Time.get_ticks_usec())
	var real := RealStory.new()
	real.load_save(path)
	real.select_character(str(Catalog.IDS[1]))
	canvas.size = Vector2i(390,844)
	panel.configure(real)
	await _settle()
	_check(real.last_save_ok,"real Story adapter fixture persists only in work/story/ui-fixtures")
	_check(_labels_have_height(panel._body),"real adapter and Main theme retain readable route preview")
	var rival_name := str(Story.opponent(0).name)
	var preview := _find_label(panel._body,rival_name)
	_check(preview != null and preview.get_global_rect().intersects(panel._scroll.get_global_rect()),"phone opens with opponent name visible before map")
	panel.show_tab("upgrades")
	await _settle()
	_check(_labels_have_height(panel._body) and panel._upgrade_buttons.size()==8,"real adapter upgrades show eight readable impact previews")
	real.data.completed = true
	real.data.current_stage = Story.stages().size()
	panel.refresh()
	await _settle()
	_check(panel._active_tab=="legacy" and _labels_have_height(panel._body),"real adapter completion has readable statistics with inherited Main theme")
	for suffix: String in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)

func _find_label(node: Node, exact_text: String) -> Label:
	for child: Node in node.get_children():
		if child is Label and child.text == exact_text: return child
		var found := _find_label(child,exact_text)
		if found != null: return found
	return null

func _victory_fits() -> bool:
	if panel._portraits.is_empty(): return panel._active_tab=="legacy" and (panel._phone or panel._short)
	var actor: Node2D = panel._portraits[0]
	actor.preview_victory()
	actor._process(PI/8.0)
	var sprite: Sprite2D = actor.get("_sprite")
	var actual: Rect2 = actor.visible_sprite_bounds()
	var holder: Control = actor.get_parent()
	return holder.get_global_rect().grow(1).encloses(actual)
