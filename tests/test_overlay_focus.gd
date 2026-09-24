extends SceneTree
## Keyboard events and real native controls; memory identity fixture only.
const Focus = preload("res://scripts/ui/components/game_overlay_focus.gd")
const Editor = preload("res://scripts/ui/customization_panel.gd")
const Cosmetics = preload("res://scripts/cosmetic_catalog.gd")

class Scope extends Control:
	var closes := 0
	func _input(event: InputEvent) -> void:
		Focus.handle(event,self,func(): closes += 1)

class MemoryIdentity extends RefCounted:
	var data := {"identity":{"display_name":"Prueba foco"},"appearance":Cosmetics.default_appearance("mugo")}
	func entry(_id: String) -> Dictionary: return data.duplicate(true)
	func owned_ids() -> Array[String]: return Cosmetics.default_owned()

var checks := 0
var failures := 0
var cancelled := 0


func _init() -> void: _run.call_deferred()


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("OVERLAY FOCUS: "+message)


func _key(code: Key, shift: bool = false, echo: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	event.shift_pressed = shift
	event.echo = echo
	return event


func _settle() -> void:
	for frame in range(4): await process_frame


func _run() -> void:
	root.size = Vector2i(390,844)
	root.gui_embed_subwindows = true
	var hud := Button.new()
	hud.text = "Underlying HUD"
	root.add_child(hud)
	var scope := Scope.new()
	scope.size = Vector2(390,844)
	root.add_child(scope)
	var input := LineEdit.new()
	input.position = Vector2(20,20)
	input.size = Vector2(300,48)
	scope.add_child(input)
	var option := OptionButton.new()
	option.position = Vector2(20,80)
	option.size = Vector2(300,48)
	option.add_item("Primera")
	option.add_item("Bloqueada")
	option.set_item_disabled(1,true)
	option.add_item("Tercera")
	scope.add_child(option)
	var hidden := Button.new()
	scope.add_child(hidden)
	hidden.hide()
	var disabled := Button.new()
	disabled.disabled = true
	scope.add_child(disabled)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20,140)
	scroll.size = Vector2(300,160)
	scroll.focus_mode = Control.FOCUS_ALL
	scroll.follow_focus = true
	scope.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	var buttons: Array[Button] = []
	for index in range(7):
		var button := Button.new()
		button.text = "Acción %d" % index
		button.custom_minimum_size = Vector2(220,48)
		rows.add_child(button)
		buttons.append(button)
	await _settle()
	hud.grab_focus()
	root.push_input(_key(KEY_TAB),true)
	_check(root.gui_get_focus_owner()==input,"Tab enters overlay rather than HUD from outside focus")
	root.push_input(_key(KEY_TAB),true)
	_check(root.gui_get_focus_owner()==option,"LineEdit and OptionButton participate in Tab")
	root.push_input(_key(KEY_TAB),true)
	_check(root.gui_get_focus_owner()==scroll,"focusable ScrollContainer participates, hidden and disabled controls skipped")
	for button: Button in buttons:
		root.push_input(_key(KEY_TAB),true)
		_check(root.gui_get_focus_owner()==button,"every enabled scroll action participates")
	await _settle()
	_check(scroll.scroll_vertical>0 and scroll.get_global_rect().grow(1).encloses(buttons[-1].get_global_rect()),"offscreen last action is revealed on focus")
	buttons[-1].focus_next = buttons[-1].get_path_to(hud)
	root.push_input(_key(KEY_TAB),true)
	_check(root.gui_get_focus_owner()==input,"explicit focus link to HUD cannot leave overlay")
	root.push_input(_key(KEY_TAB,true),true)
	_check(root.gui_get_focus_owner()==buttons[-1],"Shift-Tab wraps inside overlay")
	input.grab_focus()
	var letter := _key(KEY_A)
	letter.unicode = 97
	root.push_input(letter,true)
	_check(input.text=="a","typing reaches native input unchanged")
	var popup := option.get_popup()
	popup.popup(Rect2i(20,130,300,160))
	await _settle()
	_check(popup.visible,"real OptionButton popup is open")
	for event: InputEventKey in [_key(KEY_TAB),_key(KEY_TAB,true),_key(KEY_ESCAPE)]:
		_check(not Focus.handle(event,scope,func(): scope.closes+=1),"overlay never intercepts open popup keys")
	popup.set_focused_item(0)
	root.push_input(_key(KEY_DOWN),true)
	_check(popup.get_focused_item()==2,"native popup navigation skips its disabled option")
	root.push_input(_key(KEY_ESCAPE),true)
	await _settle()
	_check(not popup.visible and scope.closes==0,"first Escape closes popup without closing overlay")
	root.push_input(_key(KEY_ESCAPE),true)
	root.push_input(_key(KEY_ESCAPE,false,true),true)
	_check(scope.closes==1,"one Escape press emits once, key repeat does not emit again")
	scope.hide()
	_check(not Focus.handle(_key(KEY_TAB),scope,func(): scope.closes+=1),"hidden overlay never captures input")
	scope.free()
	await _test_customization(hud)
	hud.free()
	print("OVERLAY FOCUS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)


func _test_customization(hud: Button) -> void:
	var store := MemoryIdentity.new()
	var original := var_to_bytes(store.data)
	var panel := Editor.new()
	root.add_child(panel)
	panel.configure(store,"mugo",true)
	panel.cancelled.connect(func(): cancelled+=1)
	await _settle()
	var visited: Array[Control] = []
	for index in range(40):
		root.push_input(_key(KEY_TAB),true)
		var focused := root.gui_get_focus_owner()
		_check(is_instance_valid(focused) and panel.is_ancestor_of(focused) and focused!=hud,"editor forward focus stays inside its real controls")
		if not focused in visited: visited.append(focused)
	_check(panel._name_input in visited and panel._archetype in visited and panel._presets in visited and panel._confirm in visited,"editor input/selectors/save remain keyboard reachable")
	for index in range(8):
		root.push_input(_key(KEY_TAB,true),true)
		_check(panel.is_ancestor_of(root.gui_get_focus_owner()),"editor reverse focus stays inside")
	var popup: PopupMenu = panel._presets.get_popup()
	popup.popup(Rect2i(20,100,300,200))
	await _settle()
	root.push_input(_key(KEY_ESCAPE),true)
	await _settle()
	_check(cancelled==0 and not popup.visible,"editor popup Escape is not draft cancellation")
	root.push_input(_key(KEY_ESCAPE),true)
	root.push_input(_key(KEY_ESCAPE,false,true),true)
	_check(cancelled==1,"editor Escape has one cancellation path")
	_check(var_to_bytes(store.data)==original,"keyboard and cancellation never mutate identity")
	panel.free()
