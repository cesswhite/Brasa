extends SceneTree
const PanelScript=preload("res://scripts/ui/story_panel.gd")
const Progress=preload("res://scripts/story_progression.gd")
const Story=preload("res://scripts/story_catalog.gd")
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
 profile.chapter=4;profile.current_stage=9;profile.level=33;profile.points=2
 profile.allocations.max_hp=30;profile.allocations.attack=30;profile.allocations.speed=20;profile.allocations.crit_chance=6
 Progress._sync_campaign(profile)
 model.roster={"nima":profile};model.data=profile;model.active_id="nima"
 panel=PanelScript.new();canvas.add_child(panel);panel.configure(model)
 panel.upgrade_requested.connect(func(key:String):
  if model.upgrade(key):panel.refresh())
 for extent:Vector2i in Sizes.SIZES:
  profile.points=2;profile.allocations.defense=0
  canvas.size=extent;panel._upgrade_notice="";panel._upgrade_help_key="";panel.show_tab("upgrades");await settle()
  check(panel._upgrade_buttons.size()==8,"All eight attributes remain available")
  check(panel._upgrade_buttons.max_hp.disabled and panel._upgrade_buttons.max_hp.text=="Al máximo","Allocation cap has explicit label")
  check(panel._upgrade_buttons.speed.disabled,"Effective stat cap cannot waste points")
  check(panel._respec.size.x<=210,"Redistribution action stays compact")
  for label:Label in panel._body.find_children("*","Label",true,false):
   if "→" in label.text:
    var comparison=label.text.split("→")
    check(comparison[0].strip_edges()!=comparison[1].strip_edges(),"No misleading identical before and after comparisons")
  await capture("atributos",extent)
  var before=var_to_bytes(profile)
  panel._upgrade_help_buttons.max_hp.grab_focus();panel._upgrade_help_buttons.max_hp.pressed.emit();await settle()
  check(panel._upgrade_help_labels.max_hp.visible,"Help remains available on capped attribute")
  panel._upgrade_help_buttons.defense.pressed.emit();await settle()
  check(not panel._upgrade_help_labels.max_hp.visible and panel._upgrade_help_labels.defense.visible,"One explanation at a time")
  check(var_to_bytes(profile)==before,"Reading help does not spend points")
  panel._scroll.ensure_control_visible(panel._upgrade_help_labels.defense);await settle();await capture("ayuda",extent)
  panel._upgrade_buttons.defense.pressed.emit();await settle()
  check(profile.points==1 and profile.allocations.defense==1,"Upgrade spends exactly one point on its chosen attribute")
  check(panel._upgrade_buttons.defense.has_focus(),"Upgrade retains keyboard focus after refresh")
  check("Mejora aplicada" in panel._upgrade_notice_label.text,"Successful improvement shows feedback")
  await capture("mejorada",extent)
  panel._upgrade_buttons.defense.pressed.emit();await settle()
  check(profile.points==0 and profile.allocations.defense==2,"Last point spent once")
  check(panel._upgrade_help_buttons.defense.has_focus(),"Focus moves to help when upgrade becomes disabled")
  for button:Button in panel._upgrade_buttons.values():check(button.disabled,"No-points state prevents spending")
  panel._scroll.scroll_vertical=0;await settle();await capture("sin-puntos",extent)
  var no_points=var_to_bytes(profile)
  panel._request_upgrade("defense")
  check(var_to_bytes(profile)==no_points,"Disabled upgrade cannot emit a purchase")
  panel._respec.pressed.emit();await settle()
  check(is_instance_valid(panel._confirmation),"Redistribution still requires its concrete confirmation")
  await capture("redistribuir",extent)
  panel._confirmation_cancel.pressed.emit();await settle()
  check(var_to_bytes(profile)==no_points,"Cancelling redistribution preserves build")
  model.save_blocked=true;profile.points=2;panel.refresh();await settle()
  check(panel._respec.disabled,"Protected save prevents redistribution")
  for button:Button in panel._upgrade_buttons.values():check(button.disabled,"Protected save prevents all allocations")
  model.save_blocked=false;panel.refresh();await settle()
 panel.free();canvas.free()
 print("UPGRADES UI: %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func capture(state:String,extent:Vector2i):
 check(panel._body.size.x<=panel._scroll.size.x+1,"Content fits viewport")
 for button:Button in [panel._league,panel._primary]:
  check(Rect2(Vector2.ZERO,extent).grow(1).encloses(button.get_global_rect()),"Footer action stays inside viewport")
  check(button.size.x<=240 and button.size.y>=48,"Footer is compact and touch sized")
 for button:Button in panel._upgrade_buttons.values():check(button.size.y>=48,"Upgrade touch target")
 for label:Label in panel._body.find_children("*","Label",true,false):
  if label.is_visible_in_tree():check(label.size.y+1>=label.get_minimum_size().y,"Visible text fits its height")
 if output.is_empty():return
 RenderingServer.force_draw()
 check(canvas.get_texture().get_image().save_png(output.path_join("%s-%dx%d.png" % [state,extent.x,extent.y]))==OK,"Native capture saved")
