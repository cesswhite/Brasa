extends SceneTree
const Roster=preload("res://scripts/ui/roster_panel.gd")
const Catalog=preload("res://scripts/character_catalog.gd")
const Progress=preload("res://scripts/progression.gd")
const Balance=preload("res://scripts/balance.gd")
const Sizes=preload("res://tests/test_roster_visual_system.gd")
var checks:=0
var failures:=0
var output:=""
var canvas:SubViewport
func _init():run.call_deferred()
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1;push_error(label)
func settle():
 for frame in range(4):await process_frame
func run():
 for arg:String in OS.get_cmdline_user_args():
  if arg.begins_with("--capture-dir="):output=arg.trim_prefix("--capture-dir=");DirAccess.make_dir_recursive_absolute(output)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.size=Vector2i(360,240)
 canvas=SubViewport.new();canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(canvas)
 var profiles={};var definitions=Catalog.all_definitions()
 for id:String in Catalog.IDS:
  var profile=Progress._new_profile(id)
  profile.level=6 if id=="nima" else (4 if id=="mugo" else 1)
  profile.xp=27 if id=="nima" else 0
  profiles[id]=profile
 var original=var_to_bytes(profiles)
 var panel=Roster.new();canvas.add_child(panel);panel.configure(definitions,profiles,"nima",false);panel.enable_customization(true)
 for extent:Vector2 in Sizes.SIZES:
  canvas.size=Vector2i(extent);panel._show_growth=false;panel._show_about=false;panel._select(0,false);panel._set_mobile_page(0);await settle()
  check(not panel._brand.visible and not panel._subtitle.visible and not panel._note.visible,"Redundant heading and footer copy removed")
  var common_scale:Vector2=panel._portraits[0].scale
  for index:int in range(panel._cards.size()):
   var card:Button=panel._cards[index];var portrait=card.get_meta("portrait");var actor=card.get_meta("actor")
   check(actor.scale.is_equal_approx(common_scale),"All roster bodies share one scale")
   check(portrait.get_global_rect().grow(1).encloses(actor.visible_sprite_bounds()),"Card silhouette fits reserved preview")
   var bars=card.find_children("*","ProgressBar",true,false)
   check(bars.size()==1 and bars[0].value==profiles[Catalog.IDS[index]].xp,"Each card shows its own exact XP")
  await capture("companeros",extent)
  panel._set_mobile_page(1);await settle()
  var preview=panel._detail.get_child(0)
  check(preview.size.y>=(200 if panel._short else (340 if panel._portrait else 430)),"Selected preview receives readable responsive space")
  check(preview.get_global_rect().grow(1).encloses(preview.actor().visible_sprite_bounds()),"Large preview silhouette stays inside camera")
  await capture("ficha",extent)
  var grid=panel._detail.find_child("Attributes",true,false)
  check(grid.get_child_count()==9,"All nine actual stats remain available")
  panel._detail_scroll.ensure_control_visible(grid);await settle();await capture("atributos",extent)
  panel._toggle_growth();await settle()
  grid=panel._detail.find_child("Attributes",true,false)
  check(grid.get_child(0).get_child(0).get_child_count()==3,"Growth exposes next-level delta only when requested")
  check(panel._detail.find_child("RosterGrowth",true,false).has_focus(),"Rebuilt growth toggle retains keyboard focus")
  panel._detail_scroll.ensure_control_visible(grid);await settle();await capture("crecimiento",extent)
  panel._toggle_about();await settle()
  var found=false
  for label:Label in panel._detail.find_children("*","Label",true,false):
   if label.text.begins_with("GOLPE FIRMA"):found=true
  check(found,"Expanded profile keeps signature and abilities accessible")
  panel._detail_scroll.scroll_vertical=10000;await settle();await capture("habilidades",extent)
  check(var_to_bytes(profiles)==original,"Browsing and expansion never mutate progression")
 panel.free();canvas.free()
 print("ROSTER UI REFRESH: %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func capture(label:String,extent:Vector2):
 if output.is_empty():return
 RenderingServer.force_draw()
 check(canvas.get_texture().get_image().save_png(output.path_join("%s-%dx%d.png" % [label,extent.x,extent.y]))==OK,"Native capture saved")
