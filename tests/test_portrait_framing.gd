extends SceneTree
## Explicit shared cameras: all bodies fit, keep proportions and never zoom mid-action.
const Editor=preload("res://scripts/ui/customization_panel.gd")
const Profiles=preload("res://scripts/character_visual_profile.gd")
const Characters=preload("res://scripts/character_catalog.gd")
const Cosmetics=preload("res://scripts/cosmetic_catalog.gd")
const Fixtures=preload("res://tests/test_customization_visuals.gd")
var checks:=0
var failures:=0
var output:=""
var rows:Array[Dictionary]=[]
func _init():_run.call_deferred()
func check(ok:bool,message:String):
 checks+=1
 if not ok:failures+=1;push_error("PORTRAIT: "+message)
func _run():
 for arg:String in OS.get_cmdline_user_args():
  if arg.begins_with("--capture-dir="):output=arg.trim_prefix("--capture-dir=")
 if not output.is_empty():
  check(output.is_absolute_path() and DisplayServer.get_name()!="headless","captures use native renderer and explicit destination")
  if failures:quit(1);return
  DirAccess.make_dir_recursive_absolute(output)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
 root.content_scale_size=Vector2i.ZERO
 root.size=Vector2i(360,240)
 var store=Fixtures.MemoryIdentity.new()
 for item:Dictionary in Cosmetics.items("body_style_id"):
  if not str(item.inventory_id) in store.inventory:store.inventory.append(str(item.inventory_id))
 for viewport_size:Vector2i in [Vector2i(390,844),Vector2i(1360,880),Vector2i(1920,1080)]:
  var canvas:=SubViewport.new();canvas.size=viewport_size;canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(canvas)
  var panel=Editor.new();canvas.add_child(panel)
  var shared:Dictionary={}
  for item:Dictionary in Cosmetics.items("body_style_id"):
   var body:String=str(item.id)
   panel.configure(store,str(Cosmetics.body_definition(body).id),false)
   panel._choose_item("body_style_id",body)
   await process_frame
   await process_frame
   panel._actor.set_process(false)
   panel._actor._process(.01)
   for action:String in ["Reposo","Golpe","Entrada","Victoria"]:
    if action=="Reposo":panel._refresh_preview()
    else:panel._preview_action(action)
    var camera_scale:Vector2=panel._actor.scale
    var camera_root:Vector2=panel._actor.position
    var key:=action
    if not shared.has(key):shared[key]=camera_scale
    check(shared[key].is_equal_approx(camera_scale),"all bodies use the same "+action+" camera")
    for tick:int in range(121):
     panel._actor._process(.025)
     check(panel._actor.scale.is_equal_approx(camera_scale) and panel._actor.position.is_equal_approx(camera_root),"camera holds through "+body+" "+action)
     check(panel._stage.get_global_rect().grow(.25).encloses(panel._actor.visible_sprite_bounds()),"no silhouette clipped: "+body+" "+action+" "+str(tick))
    if body in ["nima","onix","mugo","tepa"]:
     var bounds:Rect2=panel._actor.visible_sprite_bounds()
     rows.append({"viewport":[viewport_size.x,viewport_size.y],"body":body,"action":action,"camera_scale":camera_scale.x,"visible_height":bounds.size.y,"stage_size":[panel._stage.size.x,panel._stage.size.y]})
     if action=="Reposo" and viewport_size.x==390:check(bounds.size.y>=125,"Nima is readable at >=125px in mobile resting preview")
     if not output.is_empty():
      # Capture within the real action, not only the held endpoint.
      if action!="Reposo":panel._preview_action(action);panel._actor._process(.17 if action=="Golpe" else .8)
      await RenderingServer.frame_post_draw
      check(canvas.get_texture().get_image().save_png(output.path_join("companion-%s-%s-%dx%d.png" % [body,action.to_lower(),viewport_size.x,viewport_size.y]))==OK,"native preview captured")
  canvas.free()
  await process_frame
 if not output.is_empty():
  var f:=FileAccess.open(output.path_join("portrait-metrics.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"samples":rows,"fixture":"memory-only; no player saves or network"},"\t"));f.close()
 print("PORTRAIT FRAMING: %d checks, %d failures; %s" % [checks,failures,JSON.stringify(rows)])
 quit(0 if failures==0 else 1)
