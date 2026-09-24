extends SceneTree
const PanelScript=preload("res://scripts/ui/story_panel.gd")
const Progress=preload("res://scripts/story_progression.gd")
const Moves=preload("res://scripts/move_catalog.gd")
const Sizes=preload("res://tests/test_story_panel.gd")
class MemoryStory:
 extends "res://scripts/story_progression.gd"
 func save()->bool:return true
var checks:=0
var failures:=0
var output:=""
var canvas:SubViewport
var panel
func _init():run.call_deferred()
func check(ok:bool,message:String):
 checks+=1
 if not ok:failures+=1;push_error(message)
func settle():
 for frame in range(4):await process_frame
func run():
 for arg:String in OS.get_cmdline_user_args():
  if arg.begins_with("--capture-dir="):output=arg.trim_prefix("--capture-dir=");DirAccess.make_dir_recursive_absolute(output)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.size=Vector2i(360,240)
 canvas=SubViewport.new();canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(canvas)
 var model=MemoryStory.new()
 var profile=Progress._new_profile("nima")
 profile.chapter=4;profile.current_stage=9;profile.level=33
 Progress._sync_campaign(profile)
 model.roster={"nima":profile};model.data=profile;model.active_id="nima"
 panel=PanelScript.new();canvas.add_child(panel);panel.configure(model)
 panel.upgrade_move_requested.connect(func(key:String):
  if model.upgrade_move(key):panel.refresh())
 panel.perk_chosen.connect(func(key:String):
  if model.choose_perk(key):panel.refresh())
 for extent:Vector2i in Sizes.SIZES:
  profile.level=33;profile.move_points=4;profile.perk_points=2;profile.perks=[];profile.move_upgrades={};profile.unlocked_moves=[]
  for move:Dictionary in Moves.unlocked_moves("nima",33):profile.unlocked_moves.append(str(move.id))
  canvas.size=extent;panel._moves_notice="";panel._moves_detail_key="";panel._moves_section="techniques";panel.show_tab("moves");await settle()
  check(panel._move_buttons.size()==5 and panel._perk_buttons.size()==6,"All techniques and talents remain present")
  check(panel._moves_sections.techniques.visible and not panel._moves_sections.perks.visible,"Only selected section is shown")
  await capture("tecnicas",extent)
  var first:String=profile.unlocked_moves[0]
  var before=var_to_bytes(profile)
  panel._moves_help_buttons[first].pressed.emit();await settle()
  check(panel._moves_details[first].visible,"Technique details are optional")
  check(var_to_bytes(profile)==before,"Reading mechanics preserves build")
  panel._scroll.ensure_control_visible(panel._moves_details[first]);await settle();await capture("detalles",extent)
  panel._move_buttons[first].pressed.emit();await settle()
  check(profile.move_points==3 and profile.move_upgrades[first]==1,"Upgrade spends exactly one token")
  check(panel._move_buttons[first].has_focus(),"Keyboard focus restored after upgrade")
  panel._move_buttons[first].pressed.emit();await settle()
  check(profile.move_points==2 and profile.move_upgrades[first]==2,"Second tier applies once")
  check(panel._move_buttons[first].disabled and panel._move_buttons[first].text=="Al máximo","Tier cap explicit")
  check(panel._moves_help_buttons[first].has_focus(),"Focus preserved at tier cap")
  before=var_to_bytes(profile);panel._request_move_upgrade(first);check(before==var_to_bytes(profile),"Cannot spend at cap")
  panel._moves_filters.perks.pressed.emit();await settle()
  check(panel._moves_sections.perks.visible and not panel._moves_sections.techniques.visible,"Talent section independent")
  await capture("talentos",extent)
  var perk:String=str(Moves.perks_for("nima")[0].id)
  panel._perk_buttons[perk].pressed.emit();await settle()
  check(profile.perks==[perk] and profile.perk_points==1,"Choosing consumes one choice")
  check(panel._perk_buttons[perk].disabled and panel._moves_help_buttons[perk].has_focus(),"Chosen talent disabled with available focused help")
  check(panel._moves_notice_label.text.begins_with("Talento activo"),"Success is explicit")
  panel._moves_help_buttons[perk].pressed.emit();await settle();await capture("elegido",extent)
  before=var_to_bytes(profile);panel._request_perk(perk);check(before==var_to_bytes(profile),"No duplicate choices")
  profile.perk_points=0;profile.move_points=0;panel.refresh();await settle()
  for button:Button in panel._perk_buttons.values():check(button.disabled,"No choices prevents purchase")
  for button:Button in panel._move_buttons.values():check(button.disabled,"No tokens prevents upgrade")
  panel._moves_detail_key="";panel._moves_notice="";panel._select_moves_section("techniques");panel.refresh();await settle();await capture("sin-fichas",extent)
  profile.level=1;profile.unlocked_moves=[];profile.move_upgrades={};profile.perks=[]
  for move:Dictionary in Moves.unlocked_moves("nima",1):profile.unlocked_moves.append(str(move.id))
  panel.refresh();await settle();await capture("inicio",extent)
  for move:Dictionary in Moves.moves_for("nima"):
   if int(move.unlock_level)>1:check(panel._move_buttons[str(move.id)].text=="Bloqueada","Level locks remain explicit")
  model.save_blocked=true;profile.move_points=4;profile.perk_points=2;panel.refresh();await settle()
  for button:Button in panel._perk_buttons.values():check(button.disabled,"Protected save blocks talents")
  for button:Button in panel._move_buttons.values():check(button.disabled,"Protected save blocks techniques")
  model.save_blocked=false;panel.refresh();await settle()
 panel.free();canvas.free()
 print("MOVES UI: %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func capture(state:String,extent:Vector2i):
 check(panel._body.size.x<=panel._scroll.size.x+1,"Content fits viewport width")
 for button:Button in [panel._league,panel._primary]:
  check(Rect2(Vector2.ZERO,extent).grow(1).encloses(button.get_global_rect()),"Footer inside viewport")
  check(button.size.x<=240 and button.size.y>=48,"Footer is compact and touch sized")
 for button:Button in panel._move_buttons.values():
  check(button.size.y>=48 and button.size.x<=220,"Technique action compact and touch sized")
 for label:Label in panel._body.find_children("*","Label",true,false):
  if label.is_visible_in_tree():check(label.size.y+1>=label.get_minimum_size().y,"Visible text fits height")
 if output.is_empty():return
 RenderingServer.force_draw()
 check(canvas.get_texture().get_image().save_png(output.path_join("%s-%dx%d.png" % [state,extent.x,extent.y]))==OK,"Native capture saved")
