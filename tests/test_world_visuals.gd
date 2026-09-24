extends SceneTree
## Isolated visual state; no progression, account, network or filesystem mutations.
const Visuals = preload("res://scripts/ui/world_visuals.gd")
const Backdrop = preload("res://scripts/ui/world_backdrop.gd")
const SIZES: Array[Vector2] = [Vector2(1360,880),Vector2(1224,792),Vector2(1920,1080),Vector2(768,1024),Vector2(390,844),Vector2(430,932),Vector2(844,390)]
var checks := 0
var failures := 0

func _init() -> void: call_deferred("_run")

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("WORLD VISUALS FAIL: " + message)

func _ids(definitions: Array[Dictionary]) -> Array[String]:
	var result: Array[String] = []
	for entry: Dictionary in definitions: result.append(str(entry.id))
	return result

func _run() -> void:
	_test_manifest_and_styles()
	_test_decoration_conditions()
	await _test_backdrops()
	print("WORLD VISUALS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func _test_manifest_and_styles() -> void:
	var registry := Visuals.manifest()
	_check(int(registry.version) == 2,"manifest version includes shared screen contexts")
	_check(Visuals.context_id("route",1) == "route_journey","first chapter journey")
	_check(Visuals.context_id("route",2) == "route_storm","second chapter storm")
	_check(Visuals.context_id("route",8) == "route_late","later route distinct context")
	_check(Visuals.context_id("route",1,true) == "route_boss_journey","boss composition retains first chapter identity")
	_check(Visuals.context_id("upgrades") == "workshop" and Visuals.context_id("moves") == "moves","training contexts share workshop without losing state identity")
	_check(Visuals.context_id("route",2,true) == "route_boss_storm","second boss has storm identity")
	_check(Visuals.context_id("route",7,true) == "route_boss_late","late boss has distinct context")
	_check(Visuals.context("route_boss_journey").background != Visuals.context("route_boss_storm").background,"boss chapters keep their own environment")
	_check(Visuals.context("unknown").id == "route_journey","unknown context safe fallback")
	for id: String in registry.assets:
		var texture: Texture2D = Visuals.texture(id)
		_check(texture != null,"final artwork exists: " + id)
		var path := Visuals.asset_path(id)
		var allowed := path.begins_with("res://assets/ui/") or path in ["res://assets/arena-faroles-v2.png", "res://assets/arena-tormenta-v3.png"]
		_check(allowed and not ".." in path.split("/"),"registry uses UI artwork or the two existing Arena backgrounds")
	_check(Visuals.texture("../../other") == null,"unknown image safely omitted")
	var original_assets: Dictionary = Visuals._manifest.assets.duplicate(true)
	for path: String in ["res://assets/ui/../icon.svg", "res://assets/../scripts/main.gd", "res://assets/ui/../../other.png", "res://assets/ui/..", "res://assets/ui\\..\\..\\other.png", "user://other.png", "/tmp/other.png"]:
		Visuals._manifest.assets["invalid_fixture"] = {"path":path,"shared":false}
		_check(Visuals.asset_path("invalid_fixture").is_empty(),"registry rejects traversal or outside path: "+path)
	Visuals._manifest.assets = original_assets
	for id: String in registry.surfaces:
		var definition: Dictionary = registry.surfaces[id]
		var texture: Texture2D = Visuals.illustration(id)
		_check(texture is AtlasTexture,"illustration stays in shared atlas: " + id)
		_check(texture.get_width()>0 and texture.get_height()>0,"nonempty atlas illustration")
		var fractions: Array = definition.region
		_check(float(fractions[0])>=0 and float(fractions[1])>=0 and float(fractions[0])+float(fractions[2])<=1 and float(fractions[1])+float(fractions[3])<=1,"surface region in source")
	for role: String in ["primary","secondary","navigation","navigation_active","danger"]:
		var button := Button.new()
		button.text = "Ruta" if role.begins_with("navigation") else "Continuar"
		Visuals.apply_button(button,role)
		_check(button.custom_minimum_size.y>=44,"touch height maintained")
		_check(button.focus_mode == Control.FOCUS_ALL,"native keyboard input retained")
		for state: String in ["normal","hover","pressed","disabled"]:
			var box := button.get_theme_stylebox(state)
			_check(box is StyleBoxTexture,"illustrated button state: " + role+"/"+state)
			_check(box.get_minimum_size().y<=44,"ninepatch caps fit small controls")
			_check(box.get_minimum_size().x<=64,"ninepatch caps fit compact navigation")
			if box is StyleBoxTexture:
				_check(box.texture != null and box.region_rect.has_area(),"style source stays valid")
		_check(button.get_theme_stylebox("focus") != button.get_theme_stylebox("normal"),"focus remains a separate visible ring")
		if role.begins_with("navigation"):
			_check(button.get_minimum_size().x<=64,"four letter nav label fits64px")
		var normal := button.get_theme_stylebox("normal") as StyleBoxTexture
		var disabled := button.get_theme_stylebox("disabled") as StyleBoxTexture
		_check(normal.modulate_color != disabled.modulate_color,"disabled treatment distinguishable")
		button.free()
	for title: String in ["Ruta","Mejora","Golpes","Equipo","Legado"]:
		var compact := Button.new()
		compact.text = title
		compact.add_theme_font_size_override("font_size",13)
		Visuals.apply_button(compact,"navigation")
		_check(compact.get_minimum_size().x<=64,"all mobile navigation labels fit64px: "+title)
		var cap := compact.get_theme_stylebox("normal") as StyleBoxTexture
		var label_width := compact.get_theme_font("font").get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
		_check(label_width<=64-cap.get_texture_margin(SIDE_LEFT)-cap.get_texture_margin(SIDE_RIGHT),"compact label stays on central cloth: "+title)
		compact.free()
	for role: String in ["panel","boss_panel","reward","dialog"]:
		var card := PanelContainer.new()
		Visuals.apply_card(card,role)
		_check(card.get_theme_stylebox("panel") is StyleBoxTexture,"scalable frame for "+role)
		card.free()
	var original := Visuals.manifest()
	registry.contexts.route_journey.accent = "ff0000"
	_check(Visuals.manifest() == original,"callers cannot mutate shared registry")
	# Simulate a missing essential surface in memory, leaving all on-disk artwork intact.
	var previous: Dictionary = Visuals._manifest
	var cached: Dictionary = Visuals._shared_textures
	Visuals._manifest = previous.duplicate(true)
	Visuals._manifest.assets.surfaces.path = "res://assets/ui/missing-surface-test.png"
	Visuals._shared_textures = {}
	_check(Visuals.surface("primary") is StyleBoxFlat,"missing essential surface gets functional native fallback")
	Visuals._manifest = previous
	Visuals._shared_textures = cached

func _test_decoration_conditions() -> void:
	_check(Visuals.props_resolved("camp",{}).is_empty(),"new player has no invented trophies")
	_check("tepa_cloth" in _ids(Visuals.props_resolved("camp",{"character_id":"tepa"})),"personal cloth follows Tepa")
	_check(not "tepa_cloth" in _ids(Visuals.props_resolved("camp",{"character_id":"balam"})),"different hero does not inherit Tepa belongings")
	_check("balam_bandages" in _ids(Visuals.props_resolved("camp",{"character_id":"balam"})),"Balam receives his own belongings")
	var disguised := {"character_id":"tepa","appearance":{"body_style_id":"balam"}}
	var personal_props := _ids(Visuals.props_resolved("camp",disguised))
	_check("balam_bandages" in personal_props and not "tepa_cloth" in personal_props,"personal objects follow equipped cosmetic body")
	_check(not "ascua_brazier" in _ids(Visuals.props_resolved("legacy",{"story_cleared":7})),"boss trophy locked before clear")
	_check("ascua_brazier" in _ids(Visuals.props_resolved("legacy",{"story_cleared":8})),"boss trophy appears at exact threshold")
	_check(not "storm_relic" in _ids(Visuals.props_resolved("legacy",{"story_cleared":16})),"owned cosmetic condition required")
	_check("storm_relic" in _ids(Visuals.props_resolved("legacy",{"story_cleared":16,"owned_cosmetics":["palette:luna"]})),"owned item and completed chapter condition compose")
	_check(not "equipped_farol" in _ids(Visuals.props_resolved("camp",{"owned_cosmetics":["aura:farol"]})),"owned alone does not imply equipped")
	_check("equipped_farol" in _ids(Visuals.props_resolved("camp",{"owned_cosmetics":["aura:farol"],"appearance":{"aura_id":"farol"}})),"equipped owned farol gets environmental echo")
	_check(not "arena_medallion" in _ids(Visuals.props_resolved("camp",{"arena_wins":9})),"arena memento threshold respected")
	_check("arena_medallion" in _ids(Visuals.props_resolved("camp",{"arena_wins":10})),"arena wins decorate camp")
	var state := {"character_id":"tepa","story_cleared":100,"arena_wins":50,"owned_cosmetics":["palette:luna","aura:farol"],"appearance":{"aura_id":"farol","palette_id":"jade"}}
	var before := state.duplicate(true)
	for context_id: String in Visuals.manifest().contexts:
		var result := Visuals.props_resolved(context_id,state)
		_check(result.size()<=3,"decorative clutter limit")
		_check(result == Visuals.props_resolved(context_id,state),"selection deterministic without consuming combat RNG")
		var anchors: Array[String] = []
		for prop: Dictionary in result:
			_check(not str(prop.anchor) in anchors,"one prop per anchor")
			anchors.append(str(prop.anchor))
		for screen_size: Vector2 in SIZES:
			var bounds: Array[Rect2] = []
			for prop: Dictionary in result:
				var rect := Visuals.prop_rect(prop,screen_size)
				_check(Rect2(Vector2.ZERO,screen_size).encloses(rect),"prop remains inside responsive viewport")
				for previous: Rect2 in bounds: _check(not rect.intersects(previous),"decorative anchors do not overlap")
				bounds.append(rect)
	_check(state == before,"visual resolution leaves gameplay-shaped input untouched")

func _test_backdrops() -> void:
	var host := Control.new()
	host.size = SIZES[0]
	root.add_child(host)
	var backdrop := Backdrop.new()
	host.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var state := {"character_id":"tepa","story_cleared":100,"arena_wins":50,"owned_cosmetics":["palette:luna","aura:farol"],"appearance":{"aura_id":"farol"}}
	var previous_ref: WeakRef
	var previous_path := ""
	for context_id: String in Visuals.manifest().contexts:
		backdrop.set_context(context_id,state)
		await process_frame
		var paths: Array[String] = backdrop.loaded_background_paths()
		_check(paths.size() == 1,"exactly one environment retained")
		_check(paths[0] == Visuals.asset_path(str(Visuals.context(context_id).background)),"active context matches displayed environment")
		if previous_ref != null and previous_path != paths[0]:
			_check(previous_ref.get_ref() == null,"previous large background resource released")
		previous_ref = weakref(backdrop._background.texture)
		previous_path = paths[0]
		_check(backdrop._background.modulate.a == 1,"illustration remains opaque")
		_check(backdrop.visible_prop_ids().size()<=3,"render layer respects prop cap")
		_no_input(backdrop)
		for screen_size: Vector2 in SIZES:
			host.size = screen_size
			await process_frame
			_check(backdrop.size == screen_size,"backdrop follows parent anchors")
			for item: Dictionary in backdrop._props:
				_check(Rect2(Vector2.ZERO,screen_size).encloses(item.node.get_rect()),"rendered prop remains within viewport")
	for id: String in Visuals.shared_texture_ids():
		_check(bool(Visuals.asset_definition(id).shared),"only shared atlases enter static cache")
		_check(not id in ["journey","storm","workshop","camp","archive"],"large environments never accumulate in static cache")
	var before_count := backdrop.get_child_count()
	for repeat: int in range(20): backdrop.set_context("camp",state)
	await process_frame
	_check(backdrop.get_child_count() == before_count,"refresh does not accumulate backdrop layers")
	_check(backdrop._props_layer.get_child_count()<=3,"refresh replaces decorations")
	host.queue_free()
	await process_frame
	_check(previous_ref.get_ref() == null,"closing view releases final environment")

func _no_input(node: Node) -> void:
	if node is Control:
		_check(node.mouse_filter == Control.MOUSE_FILTER_IGNORE,"decorative control ignores pointer: "+str(node.name))
		_check(node.focus_mode == Control.FOCUS_NONE,"decoration never enters keyboard focus")
	for child: Node in node.get_children(): _no_input(child)
