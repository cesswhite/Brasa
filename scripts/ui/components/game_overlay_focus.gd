extends RefCounted
class_name GameOverlayFocus
## Keyboard containment for a visible fullscreen overlay. No data or styling.


static func handle(event: InputEvent, overlay: Control, on_close: Callable) -> bool:
	if not is_instance_valid(overlay) or not overlay.is_visible_in_tree() or not event is InputEventKey:
		return false
	if not event.pressed or event.echo or event.alt_pressed or event.ctrl_pressed or event.meta_pressed:
		return false
	if event.keycode not in [KEY_TAB, KEY_ESCAPE]: return false
	# OptionButton and text context menus are internal Window children. Their
	# arrows, Tab and Escape must reach that popup before the enclosing overlay.
	if _has_popup(overlay): return false
	if event.keycode == KEY_ESCAPE:
		if not on_close.is_valid(): return false
		overlay.get_viewport().set_input_as_handled()
		on_close.call()
		return true
	var candidates: Array[Control] = []
	_collect(overlay, candidates)
	overlay.get_viewport().set_input_as_handled()
	if candidates.is_empty(): return true
	var focused := overlay.get_viewport().gui_get_focus_owner()
	var current := candidates.find(focused)
	var step := -1 if event.shift_pressed else 1
	var index := posmod(current + step, candidates.size())
	if current < 0: index = candidates.size()-1 if event.shift_pressed else 0
	var target := candidates[index]
	# Honour explicit links only when they remain inside this focus scope.
	if is_instance_valid(focused) and current >= 0:
		var path := focused.focus_previous if event.shift_pressed else focused.focus_next
		var linked := focused.get_node_or_null(path) as Control if not path.is_empty() else null
		if linked in candidates: target = linked
	target.grab_focus()
	var ancestor := target.get_parent()
	while ancestor != null and ancestor != overlay:
		if ancestor is ScrollContainer: ancestor.ensure_control_visible(target)
		ancestor = ancestor.get_parent()
	return true


static func _collect(node: Node, candidates: Array[Control]) -> void:
	for child: Node in node.get_children(true):
		if child is Window: continue
		if child is Control:
			if not child.is_visible_in_tree(): continue
			if child.focus_mode == Control.FOCUS_ALL and not (child is BaseButton and child.disabled):
				candidates.append(child)
		_collect(child, candidates)


static func _has_popup(node: Node) -> bool:
	for child: Node in node.get_children(true):
		if child is Popup and child.visible: return true
		if _has_popup(child): return true
	return false
