extends SceneTree
const PanelScript=preload("res://scripts/ui/story_panel.gd")
const Progress=preload("res://scripts/story_progression.gd")
const Characters=preload("res://scripts/character_catalog.gd")
const Identity=preload("res://scripts/fighter_identity.gd")
const Sizes=preload("res://tests/test_story_panel.gd")
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
 for frame in range(5):await process_frame
func run():
 for arg:String in OS.get_cmdline_user_args():
  if arg.begins_with("--capture-dir="):output=arg.trim_prefix("--capture-dir=");DirAccess.make_dir_recursive_absolute(output)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.size=Vector2i(360,240)
 canvas=SubViewport.new();canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(canvas)
 var model=Progress.new()
 var nima=Progress._new_profile("nima")
 nima.chapter=4;nima.current_stage=10;nima.level=33;nima.xp=52;nima.completed=true
 var sira=Progress._new_profile("sira")
 sira.chapter=2;sira.current_stage=2;sira.level=15;sira.xp=40
 var luma=Progress._new_profile("luma")
 model.roster={"nima":nima,"sira":sira,"luma":luma};model.data=nima;model.active_id="nima"
 var account=Identity.new()
 for id:String in Characters.IDS:account.entry(id)
 var before=var_to_bytes(model.roster)
 var identity_before=var_to_bytes(account.data)
 panel=PanelScript.new();panel.identity_store=account;canvas.add_child(panel);panel.configure(model)
 var emitted:Array[String]=[]
 var customized:Array[String]=[]
 panel.character_chosen.connect(func(id:String):emitted.append(id))
 panel.customize_requested.connect(func(id:String):customized.append(id))
 for extent:Vector2i in Sizes.SIZES:
  canvas.size=extent;panel._selected_id="nima";panel._companion_details_open=false;panel.show_tab("companions");await settle()
  check(panel._character_buttons.size()==Characters.IDS.size(),"Every companion remains available")
  check(panel._primary.text=="Continuar historia","Continuing label follows selected character")
  check(panel._companion_progress_label.text=="Capítulo 4 completado","Completed chapter is explicit")
  check(panel._companion_cleared(nima)==30,"Completion count accurate")
  check(panel._companion_xp_label.text.begins_with("52 /"),"XP belongs to selected character")
  await capture("seleccion",extent)
  panel._companion_help.pressed.emit();await settle();check(panel._companion_details.visible,"Details open optionally")
  panel._scroll.ensure_control_visible(panel._companion_details);await settle();await capture("detalles",extent)
  panel._companion_help.pressed.emit();await settle()
  panel._scroll.ensure_control_visible(panel._character_buttons[2]);await settle();await capture("coleccion",extent)
  var previous_emissions=emitted.size()
  panel._select_character("mugo");await settle()
  check(emitted.size()==previous_emissions and model.active_id=="nima","Browsing does not change active campaign")
  check(panel._primary.text=="Empezar historia","Unstarted campaign label")
  check(panel._companion_help.has_focus(),"Selection restores keyboard focus to details")
  check(panel._companion_progress_label.text=="Historia sin empezar","Empty profile understandable")
  await capture("nueva-historia",extent)
  panel._primary.pressed.emit();check(emitted.back()=="mugo","Confirm emits selected campaign")
  panel._companion_custom.pressed.emit();check(customized.back()=="mugo","Customization targets previewed identity")
  panel._select_character("luma");await settle()
  check(panel._primary.text=="Empezar historia","Existing untouched profile is still new")
  panel._select_character("sira");await settle()
  check(panel._companion_progress_label.text=="Capítulo 2 · Encuentro 11","Another character uses its own chapter and global encounter")
  check(panel._companion_xp_label.text.begins_with("40 /"),"Another character XP is independent")
  await capture("otra-campana",extent)
  panel._scroll.ensure_control_visible(panel._character_buttons[-1]);await settle();await capture("ultimos",extent)
  check(panel._scroll.get_global_rect().intersects(panel._character_buttons[-1].get_global_rect()),"Last companion reachable")
  check(before==var_to_bytes(model.roster) and identity_before==var_to_bytes(account.data),"Browsing preserves all progress and identities")
  model.save_blocked=true;panel.refresh();await settle();check(panel._primary.disabled,"Protected save blocks campaign activation")
  model.save_blocked=false;panel.refresh();await settle()
 account.data.fighters.nima.identity.display_name="Guardián de los faroles"
 canvas.size=Vector2i(390,844);panel.show_tab("companions");await settle()
 panel._scroll.ensure_control_visible(panel._character_buttons[0]);await settle();await capture("nombre-largo",Vector2i(390,844))
 var completed=Progress._new_profile("nima")
 completed.chapter=11;completed.completed=true
 check(panel._companion_status(completed)=="Historia completada" and panel._companion_cleared(completed)==100,"Final campaign completion counted correctly")
 panel.free();canvas.free()
 print("STORY COMPANIONS UI: %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func capture(state:String,extent:Vector2i):
 check(panel._body.size.x<=panel._scroll.size.x+1,"Body fits viewport width")
 for button:Button in [panel._league,panel._primary]:
  check(Rect2(Vector2.ZERO,extent).grow(1).encloses(button.get_global_rect()),"Footer inside viewport")
  check(button.size.x<=240 and button.size.y>=48,"Footer compact and touch sized")
 for button:Button in panel._character_buttons:
  for label:Label in button.find_children("*","Label",true,false):check(button.get_global_rect().grow(1).encloses(label.get_global_rect()),"Card contains all text")
 var camera:float=panel._companion_previews[0].actor().scale.x
 for preview:Control in panel._companion_previews:
  check(is_equal_approx(preview.actor().scale.x,camera),"Collection preserves common camera scale")
  check(Rect2(Vector2.ZERO,preview.size).grow(1).encloses(preview.visual_bounds()),"Portrait footprint fits frame")
 for label:Label in panel._body.find_children("*","Label",true,false):
  if label.is_visible_in_tree():check(label.size.y+1>=label.get_minimum_size().y,"Visible text fits height")
 if output.is_empty():return
 RenderingServer.force_draw()
 check(canvas.get_texture().get_image().save_png(output.path_join("%s-%dx%d.png" % [state,extent.x,extent.y]))==OK,"Native capture saved")
