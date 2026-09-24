extends SceneTree
## Presentation fixtures only: no loading, writing, or mutating real saves.
const PanelScript = preload("res://scripts/ui/story_panel.gd")
const Fixtures = preload("res://tests/test_story_panel.gd")
const Story = preload("res://scripts/story_catalog.gd")
const Moves = preload("res://scripts/move_catalog.gd")
const Visuals = preload("res://scripts/ui/game_visual_system.gd")
const SIZES: Array[Vector2i] = [Vector2i(1360,880),Vector2i(1224,792),Vector2i(1920,1080),Vector2i(768,1024),Vector2i(390,844),Vector2i(430,932),Vector2i(844,390)]

class CampaignMemory:
	extends Fixtures.MemoryStory
	func choose(id: String) -> void:
		super.choose(id)
		data.move_points = 0
		data.perk_points = 0
		data.perks = []
		data.move_upgrades = {}
		sync_moves()
	func sync_moves() -> void:
		data.unlocked_moves = []
		for move: Dictionary in Moves.unlocked_moves(str(data.character_id),int(data.level)): data.unlocked_moves.append(str(move.id))
	func can_start_next_chapter() -> bool:
		return is_complete() and not Story.chapter(current_chapter()+1).is_empty()
	func xp_needed() -> int: return 0 if int(data.get("level",1))>=50 else 100
	func completion_summary(chapter: int=0) -> Dictionary:
		var summary: Dictionary = super.completion_summary(chapter)
		if chapter==0 or chapter==current_chapter(): summary.badge=str(Story.chapter(current_chapter()).badge)
		return summary
	func completed_count() -> int:
		var result := current_stage()
		for number in range(1,current_chapter()): result += Story.stages(number).size()
		return result
	func global_level() -> int: return mini(100,completed_count()+1)
	func campaign_completion() -> Dictionary:
		var boss := 0
		var position := 0
		for chapter: Dictionary in Story.chapters():
			for stage: Dictionary in Story.stages(int(chapter.number)):
				position += 1
				if position>completed_count() and str(stage.kind)=="boss" and boss==0: boss=position
		var milestone := 0
		for number in range(completed_count()+1,101):
			if milestone==0 and (number in Story.Campaign.MOVE_TOKEN_LEVELS or number in Story.Campaign.PERK_LEVELS or number==boss): milestone=number
		return {"completed":completed_count()==100,"defeated":completed_count(),"total":100,"current_level":global_level(),"next_boss":boss,"next_milestone":milestone}
	func preview_opponent(global_index: int) -> Dictionary:
		var offset := 0
		for chapter: Dictionary in Story.chapters():
			var count := Story.stages(int(chapter.number)).size()
			if global_index<=offset+count: return Story.opponent(global_index-offset-1,int(chapter.number))
			offset += count
		return {}
	func can_replay(global_index: int) -> bool:
		return global_index>=1 and global_index<=completed_count()
	func can_upgrade_move(move_id: String) -> bool:
		return not save_blocked and move_id in data.unlocked_moves and int(data.move_points)>0 and int(data.move_upgrades.get(move_id,0))<Moves.MAX_TIER
	func available_perks() -> Array[Dictionary]:
		var result: Array[Dictionary] = []
		if int(data.perk_points)<=0 or data.perks.size()>=3: return result
		for perk: Dictionary in Moves.perks_for(str(data.character_id)):
			if not str(perk.id) in data.perks: result.append(perk)
		return result

var checks := 0
var failures := 0
var model := CampaignMemory.new()
var panel
var canvas: SubViewport
var upgraded: Array[String] = []
var chosen: Array[String] = []
var replays: Array[int] = []
var respecs := 0
var closes := 0
var captures := ""

func _init() -> void: call_deferred("_run")
func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CAMPAIGN UI: "+message)

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): captures=arg.trim_prefix("--capture-dir=")
	if not captures.is_empty(): DirAccess.make_dir_recursive_absolute(captures)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1360,880)
	var holder := SubViewportContainer.new()
	root.add_child(holder)
	canvas = SubViewport.new()
	canvas.size = SIZES[0]
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	holder.add_child(canvas)
	var theme_host := Fixtures.MainThemeFixture.new()
	canvas.add_child(theme_host)
	panel = PanelScript.new()
	theme_host.add_child(panel)
	panel.upgrade_move_requested.connect(func(id: String): upgraded.append(id))
	panel.perk_chosen.connect(func(id: String): chosen.append(id))
	panel.replay_requested.connect(func(level: int): replays.append(level))
	panel.respec_requested.connect(func(): respecs += 1)
	panel.closed.connect(func(): closes += 1)
	model.choose("nima")
	panel.configure(model)
	_check(_has_label(panel._body,"Próximo jefe: 08 · Hito 05: ficha de técnica"),"first move-token milestone is not falsely labelled a perk choice")
	panel.show_tab("moves")
	await _settle()
	_check(model.data.unlocked_moves.size()==2,"new character begins with two functional techniques")
	_check(panel._move_buttons.size()==5,"all five current and future moves are discoverable")
	_check(panel._perk_buttons.size()==6,"six choices support distinct three-perk builds")
	var first := str(Moves.moves_for("nima")[0].id)
	var last := str(Moves.moves_for("nima")[-1].id)
	_check(panel._move_buttons[first].disabled and panel._move_buttons[last].disabled,"no tokens and locked levels disable upgrades")
	model.data.move_points = 1
	panel.refresh()
	var unchanged: Dictionary = model.data.duplicate(true)
	panel._move_buttons[first].pressed.emit()
	_check(upgraded==[first] and model.data==unchanged,"upgrade emits stable ID without spending currency in presentation")
	panel._move_buttons[last].pressed.emit()
	_check(upgraded.size()==1,"locked move cannot emit even if button signal is invoked directly")
	model.data.move_upgrades[first] = Moves.MAX_TIER
	panel.refresh()
	_check(panel._move_buttons[first].disabled and panel._move_buttons[first].text=="Mejora máxima","tier cap remains visible and enforced")
	for level in [5,12,20]:
		model.data.level = level
		model.sync_moves()
		panel.refresh()
		_check(model.data.unlocked_moves.size()==3+[5,12,20].find(level),"character milestone unlocks one additional technique")
		_check(_has_label(panel._body,"RIESGO · "),"techniques explain risk rather than only damage numbers")
	model.data.perk_points = 1
	panel.refresh()
	var perk_id := str(Moves.perks_for("nima")[0].id)
	unchanged = model.data.duplicate(true)
	panel._perk_buttons[perk_id].pressed.emit()
	_check(chosen==[perk_id] and model.data==unchanged,"perk choice emits one ID without mutating profile")
	model.data.perks = [perk_id]
	model.data.perk_points = 0
	panel.refresh()
	_check(panel._perk_buttons[perk_id].disabled and panel._perk_buttons[perk_id].text=="Elegido","chosen perk cannot be selected twice")
	model.save_blocked = true
	model.data.perk_points = 1
	panel.refresh()
	for button: Button in panel._move_buttons.values(): _check(button.disabled,"protected save disables move upgrades")
	for button: Button in panel._perk_buttons.values(): _check(button.disabled,"protected save disables perk selections")
	model.save_blocked = false
	_check(Story.chapters().size()==11 and panel._total_encounters()==100,"campaign uses eleven bounded chapter pages for exactly one hundred encounters")
	var expected_starts := [1,9,17,21,31,41,51,61,71,81,91]
	for chapter in range(1,Story.chapters().size()+1):
		_check(panel._global_level(chapter,0)==expected_starts[chapter-1],"chapter %d retains correct global numbering" % chapter)
	model.data.current_stage = 8
	model.data.completed = true
	panel.refresh()
	panel._select_route_chapter(11)
	_check(panel._primary.disabled and panel._primary.text=="Capítulo bloqueado","future preview after a completed chapter cannot index a nonexistent current encounter")
	model.data.chapter = 4
	model.data.current_stage = 6
	model.data.completed = false
	model.data.level = 20
	model.sync_moves()
	panel.refresh()
	_check(panel._route_chapter==4 and panel._stage_buttons.size()==10,"current route renders only its ten encounters")
	_check(panel._campaign_status.text.contains("26 / 100"),"global progress reflects prior chapter victories")
	unchanged = model.data.duplicate(true)
	panel._select_route_chapter(11)
	_check(panel._route_chapter==11 and panel._stage_buttons.size()==10 and panel._primary.disabled,"future chapter preview does not unlock future battles")
	_check(model.data==unchanged,"chapter browsing never switches active progression")
	panel._select_route_chapter(1)
	panel._select_stage(2)
	_check(panel._primary.text=="Repetir encuentro 03","cleared battle offers explicit practice action")
	panel._primary_pressed()
	_check(replays==[3] and model.data==unchanged,"replay requests global level while preserving current route and XP")
	model.cooldown_remaining = 2.3
	panel._process(0.1)
	_check(panel._primary.disabled and panel._primary.text=="Reintento en 3 s","practice obeys surrender cooldown")
	panel._primary_pressed()
	_check(replays.size()==1,"practice cannot bypass cooldown")
	model.cooldown_remaining = 0
	panel._process(0.1)
	_check(not panel._primary.disabled,"practice re-enables when cooldown expires")
	await _check_respec()
	for view: Vector2i in SIZES: await _check_view(view)
	print("CAMPAIGN UI: %d checks, %d failures across seven viewport sizes" % [checks,failures])
	quit(0 if failures==0 else 1)

func _check_respec() -> void:
	panel.show_tab("upgrades")
	var unchanged: Dictionary = model.data.duplicate(true)
	panel._respec.pressed.emit()
	await _settle()
	_check(is_instance_valid(panel._confirmation) and respecs==0 and model.data==unchanged,"redistribution first opens a confirmation without changing the build")
	_check(_has_label(panel._confirmation,"Recuperarás") and _has_label(panel._confirmation,"Conservas tu nivel, XP"),"confirmation explains refunds and preserved progression")
	_check(canvas.gui_get_focus_owner()==panel._confirmation_cancel,"shared modal starts on the safe Cancel action")
	var close_button: Button = panel._confirmation.parts().close
	var targets: Array[Control] = [close_button,panel._confirmation_cancel,panel._confirmation_accept]
	var visited: Array[Control] = []
	for index in range(3):
		var tab := InputEventKey.new()
		tab.pressed = true
		tab.keycode = KEY_TAB
		canvas.push_input(tab,true)
		await process_frame
		var focused := canvas.gui_get_focus_owner()
		_check(focused in targets,"real Tab stays inside the confirmation instead of reaching underlying upgrades")
		visited.append(focused)
	_check(visited.has(close_button) and visited.has(panel._confirmation_cancel) and visited.has(panel._confirmation_accept),"real Tab includes close, safe action and confirmation")
	_check(canvas.gui_get_focus_owner()==panel._confirmation_cancel,"three controls form a complete focus cycle")
	var reverse := InputEventKey.new()
	reverse.pressed = true
	reverse.keycode = KEY_TAB
	reverse.shift_pressed = true
	canvas.push_input(reverse,true)
	await process_frame
	_check(canvas.gui_get_focus_owner()==close_button,"Shift-Tab reaches the shared close within the modal")
	close_button.pressed.emit()
	_check(not is_instance_valid(panel._confirmation) and respecs==0 and closes==0,"shared close dismisses only the confirmation without redistribution")
	_check(canvas.gui_get_focus_owner()==panel._respec,"shared close restores focus to the opening action")
	panel._respec.pressed.emit()
	await _settle()
	panel._confirmation_cancel.pressed.emit()
	_check(not is_instance_valid(panel._confirmation) and respecs==0,"cancel never requests redistribution")
	_check(canvas.gui_get_focus_owner()==panel._respec,"Cancel also restores the initiating action")
	panel._respec.pressed.emit()
	var escape := InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE
	canvas.push_input(escape,true)
	await process_frame
	_check(not is_instance_valid(panel._confirmation) and closes==0,"escape closes confirmation before the surrounding story panel")
	panel._respec.pressed.emit()
	panel._confirmation_accept.pressed.emit()
	_check(respecs==1 and model.data==unchanged and not is_instance_valid(panel._confirmation),"explicit confirmation emits once without mutating progression in the view")
	panel._confirm_respec()
	_check(respecs==1,"repeating confirmation without a live dialog cannot emit again")
	panel._respec.pressed.emit()
	model.save_blocked = true
	panel._confirmation_accept.pressed.emit()
	_check(respecs==1,"protection activated during a confirmation is rechecked before emitting")
	panel.refresh()
	_check(panel._respec.disabled,"protected save disables redistribution")
	model.save_blocked = false
	var original_allocations: Dictionary = model.data.allocations.duplicate(true)
	var original_moves: Dictionary = model.data.move_upgrades.duplicate(true)
	var original_perks: Array = model.data.perks.duplicate()
	for key: String in model.data.allocations: model.data.allocations[key] = 0
	model.data.move_upgrades = {}
	model.data.perks = []
	panel.refresh()
	panel._respec.pressed.emit()
	_check(panel._respec.disabled and not is_instance_valid(panel._confirmation),"unspent build has nothing to refund")
	model.data.allocations = original_allocations
	model.data.move_upgrades = original_moves
	model.data.perks = original_perks
	panel.refresh()

func _check_view(view: Vector2i) -> void:
	canvas.size = view
	model.data.chapter = 11
	model.data.current_stage = 9
	model.data.completed = false
	model.data.level = 50
	model.data.total_xp = 58000
	model.data.matches = 13
	model.data.losses = 4
	model.data.retries = 4
	model.data.move_points = 4
	model.data.perk_points = 1
	model.sync_moves()
	panel.refresh()
	panel._select_route_chapter(11,true)
	await _settle()
	_check(panel._stage_buttons.size()==10 and panel._campaign_status.text.contains("99 / 100"),"final page shows position before level one hundred")
	_check(panel._subtitle.text.contains("XP total") and not panel._subtitle.text.contains("/ 0 XP"),"maximum character level shows cumulative XP instead of an empty denominator")
	_check(_has_label(panel._body,"ENCUENTRO 100 / 100"),"final boss preview carries global hundredth encounter number")
	_check(_has_label(panel._body,"TÉCNICAS CONOCIDAS"),"prebattle includes known techniques")
	if view.y<540:
		var opponent_name := str(model.preview_opponent(100).name)
		var visible_name := _find_label(panel._body,opponent_name)
		_check(visible_name!=null and visible_name.get_global_rect().intersects(panel._scroll.get_global_rect()),"short landscape opens on the opponent before map controls")
	_check_layout(view,"route-100")
	await _capture("route-100",view)
	panel.show_tab("moves")
	await _settle()
	_check(panel._move_buttons.size()==5 and panel._perk_buttons.size()==6,"late campaign retains bounded technique and perk pools")
	_check(_has_label(panel._body,"ELIGE UN TALENTO"),"pending milestone has visible choice prompt")
	_check_layout(view,"moves-pending")
	for button: Button in panel._move_buttons.values(): _check(button.size.y>=48,"move upgrade remains touch sized")
	for button: Button in panel._perk_buttons.values(): _check(button.size.y>=48,"perk choice remains touch sized")
	panel._scroll.ensure_control_visible(panel._move_buttons.values()[-1])
	await _settle()
	_check(panel._scroll.get_global_rect().intersects(panel._move_buttons.values()[-1].get_global_rect()),"last move upgrade is reachable by scrolling")
	panel._scroll.scroll_vertical = 0
	await _settle()
	await _capture("moves-pending",view)
	model.data.perk_points = 0
	panel.refresh()
	await _settle()
	_check_layout(view,"moves-unlocked")
	await _capture("moves-unlocked",view)
	model.data.current_stage = 10
	model.data.completed = true
	model.data.matches = 14
	panel.refresh()
	await _settle()
	_check(panel._legacy_chapter==11 and panel._primary.text=="Elegir compañero","hundredth victory ends current campaign without a phantom next chapter")
	_check(panel._legacy_picker.item_count==11,"all chapter legacies remain reachable through bounded selector")
	_check_layout(view,"legacy-100")
	await _capture("legacy-100",view)
	panel.show_tab("upgrades")
	await _settle()
	_check(not panel._respec.disabled and panel._respec.size.y>=48,"redistribution remains a reachable touch-sized action at campaign completion")
	panel._respec.pressed.emit()
	await _settle()
	var bounds := Rect2(Vector2.ZERO,Vector2(view)).grow(1)
	_check(bounds.encloses(panel._confirmation_card.get_global_rect()),"redistribution confirmation fits viewport")
	for button: Button in [panel._confirmation_accept,panel._confirmation_cancel]:
		_check(bounds.encloses(button.get_global_rect()) and button.size.y>=48,"confirmation choices remain visible and touch sized")
	_check(_readable(panel._confirmation),"refund and preservation explanation has visible line heights")
	await _capture("respec-confirmation",view)
	panel._confirmation_cancel.pressed.emit()
	panel.show_tab("route")
	model.cooldown_remaining = 1
	panel._process(0.1)
	_check(panel._primary.disabled,"completed-campaign practice also observes cooldown")
	model.cooldown_remaining = 0
	panel._process(0.1)
	_check(not panel._primary.disabled,"completed-campaign practice cooldown updates without reopening panel")

func _check_layout(view: Vector2i, state: String) -> void:
	var bounds := Rect2(Vector2.ZERO,Vector2(view))
	_check(panel.theme == Visuals.theme(),state+" inherits the shared Story theme")
	for button: Button in panel._tab_buttons.values():
		_check(button.get_theme_font_size("font_size") == (13 if view.x < 600 else 15),state+" navigation preserves mobile typography after refresh")
	for picker: OptionButton in [panel._route_picker,panel._legacy_picker]:
		if is_instance_valid(picker): _check(picker.get_popup().theme == Visuals.theme(),state+" chapter popup inherits the shared theme")
	_check(panel._body.size.x<=panel._scroll.size.x+1,state+" has no horizontal content overflow")
	_check(panel._scroll.size.y>=100,state+" retains usable scroll area")
	for button: Button in [panel._primary,panel._league,panel._close]:
		_check(bounds.grow(1).encloses(button.get_global_rect()) and button.size.y>=48,state+" fixed action is reachable")
	for button: Button in panel._tab_buttons.values():
		_check(bounds.grow(1).encloses(button.get_global_rect()) and button.size.y>=48,state+" all five navigation targets fit")
	_check(_readable(panel._body),state+" nonempty labels retain line height")

func _readable(node: Node) -> bool:
	for child: Node in node.get_children():
		if child is Label and not child.text.is_empty() and child.size.y<12: return false
		if not _readable(child): return false
	return true

func _has_label(node: Node, prefix: String) -> bool:
	for child: Node in node.get_children():
		if child is Label and child.text.begins_with(prefix): return true
		if _has_label(child,prefix): return true
	return false

func _find_label(node: Node, text: String) -> Label:
	for child: Node in node.get_children():
		if child is Label and child.text==text: return child
		var found := _find_label(child,text)
		if found!=null: return found
	return null

func _settle() -> void:
	for _frame in range(6): await process_frame

func _capture(label: String, view: Vector2i) -> void:
	if captures.is_empty(): return
	RenderingServer.force_draw(false)
	canvas.get_texture().get_image().save_png(captures.path_join("%s-%dx%d.png" % [label,view.x,view.y]))
