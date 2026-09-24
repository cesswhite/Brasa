extends SceneTree
## Freeform document/training fixtures only. No Main scene, callbacks or saves.

const Modal = preload("res://scripts/ui/components/game_modal.gd")
const Visuals = preload("res://scripts/ui/game_visual_system.gd")
const SIZES: Array[Vector2] = [Vector2(1360,880),Vector2(390,844),Vector2(844,390)]
var checks := 0
var failures := 0
var accepts := 0
var closes := 0


func _init() -> void:
	_run.call_deferred()


func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("GAME MODAL CANVAS FAIL: " + message)


func _settle() -> void:
	for frame in range(6): await process_frame


func _inside(outer: Control, inner: Control) -> bool:
	return outer.get_global_rect().grow(1).encloses(inner.get_global_rect())


func _run() -> void:
	root.size = Vector2i(1360,880)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var host := Control.new()
	host.size = SIZES[0]
	root.add_child(host)
	var opener := Button.new()
	opener.text = "Abrir documento"
	host.add_child(opener)
	var modal := Modal.new()
	modal.max_width = 920
	modal.preferred_height = 740
	modal.configure("¿Rendirse en este encuentro?", "Conservas a tu compañero, sus mejoras y la ruta. · En pausa", "Esc para cerrar · Desplázate para leer más")
	var canvas := modal.canvas_content()
	var parts := modal.parts()
	var body := RichTextLabel.new()
	body.name = "LegacyBody"
	body.selection_enabled = true
	body.bbcode_enabled = false
	body.focus_mode = Control.FOCUS_ALL
	body.add_theme_font_size_override("normal_font_size",Visuals.font_size("body"))
	body.add_theme_color_override("default_color",Visuals.color("text_primary"))
	for index in range(40): body.text += "Línea %d · Conservas tu nivel, experiencia y compañero.\n\n" % index
	canvas.add_child(body)
	var cancel := Button.new()
	cancel.text = "Seguir peleando"
	cancel.clip_text = true
	cancel.custom_minimum_size.y = 48
	Visuals.apply_button(cancel,"primary")
	canvas.add_child(cancel)
	var accept := Button.new()
	accept.text = "Rendirme"
	accept.custom_minimum_size.y = 48
	Visuals.apply_button(accept,"secondary")
	canvas.add_child(accept)
	accept.pressed.connect(func(): accepts += 1)
	cancel.pressed.connect(modal.close)
	modal.closed.connect(func(): closes += 1)
	var layout := func():
		var width: float = canvas.size.x
		var height: float = canvas.size.y
		body.position = Vector2.ZERO
		body.size = Vector2(width,maxf(0,height-60))
		cancel.position = Vector2(0,maxf(0,height-48))
		cancel.size = Vector2(maxf(0,(width-12)/2),48)
		accept.position = Vector2(cancel.size.x+12,cancel.position.y)
		accept.size = cancel.size
	canvas.resized.connect(layout)
	host.add_child(modal)
	_check(parts.heading is Label and parts.subtitle is Label and parts.close is Button and parts.hint is Label,"legacy aliases retain exact node types")
	_check(parts.panel is PanelContainer and parts.scroll is ScrollContainer,"shell exposes existing panel and scroll without duplication")
	_check(canvas == modal.canvas_content() and parts.heading == modal.parts().heading,"repeated access preserves content and chrome nodes")
	for extent: Vector2 in SIZES:
		host.size = extent
		opener.grab_focus()
		modal.open(opener)
		await _settle()
		layout.call()
		await _settle()
		_check(modal.manual_content and canvas.visible and not modal.content().visible,"manual mode only shows chosen content")
		_check(_inside(host,parts.panel),"shell fits "+str(extent))
		_check(_inside(parts.panel,parts.heading) and _inside(parts.panel,parts.subtitle),"title and subtitle remain in panel "+str(extent))
		_check(_inside(parts.panel,parts.close) and parts.close.size.y>=48,"close remains accessible "+str(extent))
		_check(_inside(parts.scroll,canvas),"canvas fills its viewport without external overflow "+str(extent))
		_check(canvas.size.x>100 and canvas.size.y>100,"freeform receives useful resized area "+str(extent))
		_check(absf(canvas.size.y-parts.scroll.size.y)<2,"zero minimum uses exactly current scroll viewport height "+str(extent))
		_check(body.size.y>=60 and _inside(canvas,body),"RichText remains readable "+str(extent))
		_check(body.get_v_scroll_bar().max_value>body.size.y,"long RichText scrolls internally "+str(extent))
		_check(not parts.scroll.get_v_scroll_bar().visible,"document has no second nested scrollbar "+str(extent))
		_check(_inside(canvas,cancel) and _inside(canvas,accept) and cancel.size.y>=48 and accept.size.y>=48,"both legacy action targets fit "+str(extent))
		_check(not body.get_rect().intersects(cancel.get_rect()) and not body.get_rect().intersects(accept.get_rect()) and not cancel.get_rect().intersects(accept.get_rect()),"body and actions never overlap "+str(extent))
		_check(not parts.subtitle.get_global_rect().intersects(body.get_global_rect()) and not parts.hint.get_global_rect().intersects(accept.get_global_rect()),"shell text stays separate from manual content "+str(extent))
		body.scroll_to_line(body.get_line_count()-1)
		await _settle()
		_check(body.get_v_scroll_bar().value>0,"legacy scroll_to_line still works "+str(extent))
		for step in range(6):
			var tab := InputEventKey.new()
			tab.keycode = KEY_TAB
			tab.pressed = true
			modal._input(tab)
			_check(modal.is_ancestor_of(root.gui_get_focus_owner()),"manual focus remains inside shell "+str(extent))
		accept.pressed.emit()
		_check(modal.visible,"accept callback is caller-controlled, not auto-close")
		cancel.pressed.emit()
		_check(not modal.visible and root.gui_get_focus_owner()==opener,"legacy cancel callback closes and restores focus")
	_check(accepts==SIZES.size() and closes==SIZES.size(),"callbacks run exactly once without replacement")
	# A tall training canvas opts into exterior scroll. Reparenting its content
	# back to a caller before closing retains the same node and signal bindings.
	canvas.resized.disconnect(layout)
	body.hide()
	cancel.hide()
	accept.hide()
	var training := Control.new()
	training.custom_minimum_size = Vector2(0,600)
	canvas.add_child(training)
	var train_action := Button.new()
	train_action.text = "Entrenar"
	train_action.position = Vector2(0,548)
	train_action.size = Vector2(144,48)
	training.add_child(train_action)
	modal.set_canvas_minimum_height(620)
	host.size = Vector2(844,390)
	modal.open(opener)
	await _settle()
	_check(canvas.size.y>=620 and parts.scroll.get_v_scroll_bar().visible,"training has exterior scroll only when explicitly requested")
	parts.scroll.ensure_control_visible(train_action)
	await _settle()
	_check(_inside(parts.scroll,train_action),"lowest training action can be scrolled fully into view")
	training.reparent(host)
	modal.close()
	_check(training.get_parent()==host and is_instance_valid(train_action),"caller can recover training nodes before freeing shell")
	modal.set_canvas_minimum_height(0)
	modal.manual_content = false
	var default_line := Label.new()
	default_line.text = "Contenido automático"
	modal.content().add_child(default_line)
	modal.open(opener)
	await _settle()
	_check(modal.content().visible and not canvas.visible and is_instance_valid(body),"switching mode preserves hidden caller content")
	modal.set_canvas_minimum_height(NAN)
	_check(canvas.custom_minimum_size.y==0,"invalid height cannot corrupt layout")
	modal.close()
	# Full-screen location mode changes only the shell geometry/material. The
	# same manual nodes, callbacks, focus helper and scroll contract still apply.
	var visual_state := {"character_id":"mugo","story_cleared":0,"owned_cosmetics":[]}
	var state_before := var_to_bytes(visual_state)
	modal.set_environment("fighter",visual_state)
	modal.use_location_layout()
	_check(modal.canvas_content()==canvas and modal.parts().heading==parts.heading,"location keeps existing content and chrome aliases")
	body.show()
	cancel.show()
	accept.show()
	canvas.resized.connect(layout)
	for extent: Vector2 in SIZES:
		host.size = extent
		modal.open(opener)
		await _settle()
		layout.call()
		_check(_inside(host,parts.panel),"full-screen location fits "+str(extent))
		_check(parts.panel.size.x>=extent.x-64,"location uses screen width instead of the modal max-width")
		_check(_inside(canvas,body) and _inside(canvas,accept) and _inside(canvas,cancel),"manual document and actions remain fitted in location mode")
		_check(parts.panel.get_theme_stylebox("panel") is StyleBoxEmpty,"location preserves open Story composition")
		cancel.pressed.emit()
		_check(root.gui_get_focus_owner()==opener,"location mode restores opener through shared close")
	modal.set_environment("upgrades",visual_state)
	await _settle()
	var environments := modal.find_children("GameEnvironment","Control",false,false)
	_check(environments.size()==1,"changing location replaces rather than stacks backgrounds")
	if environments.size()==1:
		var paths: Array[String] = environments[0].loaded_background_paths()
		_check(paths.size()==1 and paths[0].ends_with("workshop-v1.png"),"location loads only its current workshop background")
	_check(var_to_bytes(visual_state)==state_before,"location decoration never mutates caller state")
	host.free()
	print("GAME MODAL CANVAS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
