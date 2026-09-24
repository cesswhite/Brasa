extends SceneTree
const PanelScript=preload("res://scripts/ui/story_panel.gd")
const Progress=preload("res://scripts/story_progression.gd")
const Story=preload("res://scripts/story_catalog.gd")
const Sizes=preload("res://tests/test_story_panel.gd")
var checks:=0
var failures:=0
var output:=""
var canvas:SubViewport
var panel
var starts:=0
var replays:Array[int]=[]
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
 var model=Progress.new()
 var profile=Progress._new_profile("nima")
 profile.chapter=4;profile.current_stage=9;profile.level=33;profile.wins=9;profile.matches=11;profile.losses=2
 Progress._sync_campaign(profile)
 model.roster={"nima":profile};model.data=profile;model.active_id="nima"
 panel=PanelScript.new();canvas.add_child(panel);panel.configure(model)
 panel.next_chapter_requested.connect(func():starts+=1)
 panel.replay_requested.connect(func(level:int):replays.append(level))
 for extent:Vector2i in Sizes.SIZES:
  profile.completed=false;profile.current_stage=9;profile.completion_snapshot={};Progress._sync_campaign(profile)
  canvas.size=extent;panel.refresh();panel._select_route_chapter(4,true);await settle()
  var original=var_to_bytes(profile)
  check(not panel._route_continue.visible,"Current battle has one action")
  check(not panel._route_detail_content.visible,"Optional detail begins collapsed")
  check(panel._primary.text=="Entrar al combate","Current match action remains correct")
  await capture("actual",extent)
  panel._route_help.grab_focus();panel._route_help.button_pressed=true;await settle()
  check(panel._route_detail_content.visible and panel._route_help.has_focus(),"Help opens without losing focus")
  check(panel._route_detail_content.find_children("*","Label",true,false).size()>4,"Strengths, ability and known moves remain accessible")
  panel._scroll.ensure_control_visible(panel._route_detail_content);await settle()
  await capture("detalles",extent)
  panel._select_stage(0);await settle()
  check(not panel._route_detail_content.visible and panel._route_continue.visible,"Practice offers separate continue action")
  check(panel._primary.text.begins_with("Repetir"),"Practice is explicitly named")
  panel._route_continue.pressed.emit();await settle()
  check(panel._selected_stage==9 and panel._route_chapter==4,"Continue returns to actual next encounter")
  panel._select_route_chapter(5);await settle()
  check(panel._primary.disabled and panel._primary.text=="Bloqueado","Future fight is blocked")
  check(panel._route_continue.visible,"Future preview offers return to current route")
  await capture("bloqueado",extent)
  check(var_to_bytes(profile)==original,"Inspecting encounters never changes progress")
  profile.completed=true;profile.current_stage=10;profile.badge=Story.chapter(4).badge;Progress._sync_campaign(profile);Progress._capture_completion(profile,"nima")
  panel.refresh();panel._select_route_chapter(4,true);await settle()
  var complete=var_to_bytes(profile)
  check(panel._primary.text.begins_with("Repetir") and panel._route_continue.visible,"Finished chapter offers repeat and continue distinctly")
  await capture("superado",extent)
  panel._primary_pressed()
  check(replays.back()==30,"Repeat dispatches selected encounter, not chapter continuation")
  var before=starts;panel._route_continue.pressed.emit()
  check(starts==before+1 and model.current_chapter()==4,"Continue emits once without starting a chapter by itself")
  model.save_blocked=true;panel._refresh_actions();before=starts;panel._continue_route()
  check(panel._route_continue.disabled and starts==before,"Protected save prevents chapter start")
  model.save_blocked=false;panel._refresh_actions()
  check(var_to_bytes(profile)==complete,"Practice and continuation controls do not edit completed snapshot")
 panel.free();canvas.free()
 print("ROUTE UI: %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func capture(state:String,extent:Vector2i):
 check(panel._body.size.x<=panel._scroll.size.x+1,"Content fits: "+state+str(extent))
 var buttons:Array[Control]=[panel._league,panel._primary]
 if panel._route_continue.visible:buttons.append(panel._route_continue)
 for index:int in range(buttons.size()):
  var button=buttons[index]
  check(Rect2(Vector2.ZERO,extent).grow(1).encloses(button.get_global_rect()),"Action inside viewport")
  check(button.size.y>=48,"Action remains touch sized")
  check(button.size.x<=240,"Route actions stay compact")
  for next:int in range(index+1,buttons.size()):check(not button.get_global_rect().intersects(buttons[next].get_global_rect()),"Actions do not overlap")
 for label:Label in panel._body.find_children("*","Label",true,false):
  if label.is_visible_in_tree():check(label.size.y+1>=label.get_minimum_size().y or label.clip_text,"Visible text has enough height")
 if output.is_empty():return
 RenderingServer.force_draw()
 check(canvas.get_texture().get_image().save_png(output.path_join("%s-%dx%d.png" % [state,extent.x,extent.y]))==OK,"Native screenshot saved")
