extends SceneTree
const Base=preload("res://tests/test_identity_integration.gd")
const Progress=preload("res://scripts/progression.gd")
const Replay=preload("res://scripts/ui/battle_replay_panel.gd")
const Records=preload("res://scripts/battle_identity.gd")
const Sizes=preload("res://tests/test_battle_layout.gd")
var checks:=0
var failures:=0
var output:=""
var canvas:SubViewport
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1;push_error(label)
func _init():run.call_deferred()
func run():
 for arg:String in OS.get_cmdline_user_args():
  if arg.begins_with("--capture-dir="):output=arg.trim_prefix("--capture-dir=");DirAccess.make_dir_recursive_absolute(output)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.size=Vector2i(360,240)
 canvas=SubViewport.new();canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(canvas)
 var folder=ProjectSettings.globalize_path("res://../../work/battle-ui/fixtures");DirAccess.make_dir_recursive_absolute(folder)
 for extent:Vector2 in Sizes.SIZES:
  canvas.size=Vector2i(extent)
  var path=folder.path_join("battle-%d.json" % Time.get_ticks_usec())
  var profile=Progress.new();profile.load_save(path);profile.select_character("nima","Cess")
  var screen=Base.Fixture.new();screen.fixture_path=path;canvas.add_child(screen);screen.size=extent
  screen.reduced_motion=true;screen._layout_interface(extent)
  for mode:String in ["arena","historia"]:
   if mode=="historia":screen._enter_story("nima");screen._close_story_panel()
   screen._start_fight();screen._layout_interface(extent)
   check(screen.active_match,"Actual battle starts in "+mode)
   check(not screen.fight_button.visible,"Ongoing auto combat does not show a disabled primary action")
   check(not screen.brand_label.visible and not screen.story_button.visible and not screen.progress_label.visible,"Battle hides removed texts and Story shortcut")
   check(is_equal_approx(screen.menu_button.get_rect().get_center().x,extent.x/2),"Menu is centered")
   for hud:Panel in [screen.player_hud,screen.rival_hud]:
    for control:Control in [hud.name_label,hud.level_label,hud.bar,hud.hp_label]:
     check(hud.get_global_rect().encloses(control.get_global_rect()),"HUD children fit painted frame")
    var rows=[hud.name_label,hud.level_label,hud.bar,hud.hp_label]
    for index:int in range(rows.size()-1):check(not rows[index].get_rect().intersects(rows[index+1].get_rect()),"HUD text and life rows do not overlap")
   await capture(mode+"-combate",extent)
   screen.combat.start(screen._player_combatant(),screen.rival,42,{"initial_hp":{"rival":1.0},"disable_signatures":true})
   var events=screen.combat.advance(120);screen._dispatch_events(events)
   while screen.active_match:await process_frame
   for actor:Node2D in [screen.player_view,screen.rival_view]:actor._process(1)
   screen._layout_interface(extent)
   check(screen.result_panel.visible and screen.result_veil.visible,"Result overlays completed scene")
   if extent.x < 640:
    check(screen.fight_button.get_rect().end.y <= screen.player_view.position.y-166*screen.player_view.scale.y-8,"Phone outcome and action clear the fighter footprint")
   else:
    check(is_equal_approx((screen.result_panel.position.y+screen.fight_button.get_rect().end.y)/2,extent.y/2),"Desktop outcome and continuation vertically centered")
   check(not screen.result_panel.get_rect().intersects(screen.fight_button.get_rect()),"Outcome and action have clear separation")
   await capture(mode+"-victoria",extent)
   if mode=="arena":
    screen.menu_button.pressed.emit()
    check(is_instance_valid(screen.modal_layer) and screen.modal_layer.get_index()>screen.fight_button.get_index(),"Menu layers above result actions")
    screen._close_modal()
  var record={"winner":screen.last_battle_summary.winner,"reason":screen.last_battle_summary.reason,"duration":screen.last_battle_summary.duration}
  Records.attach(record,screen.last_battle_summary)
  var bytes=var_to_bytes(record)
  screen.free();await process_frame
  var replay=Replay.new();replay.playback_mode="online";replay.viewing_side="rival";canvas.add_child(replay);replay.configure([record]);replay.set_process(false)
  check(replay._close.text=="Menú" and not replay._picker.visible,"Online has centered menu without replay picker")
  replay._toggle();replay._process(.05)
  await capture("online-combate",extent)
  replay._process(float(replay.snapshot.duration)+1)
  for tick:int in range(30):
   for actor:Node2D in replay.actors.values():actor._process(1.0/30.0)
  check(replay._result.visible and replay._continue.visible and not replay._play.visible,"Online terminal result has continuation action")
  check(replay._result.title_label.text==("¡VICTORIA!" if record.winner=="rival" else "DERROTA"),"Online outcome uses viewer side")
  check(var_to_bytes(record)==bytes,"Presentation leaves authoritative record unchanged")
  await capture("online-resultado",extent)
  var closed=[false];replay.closed.connect(func():closed[0]=true);replay._continue.pressed.emit();check(closed[0],"Online continuation returns through existing close callback")
  replay.viewing_side="player";replay.restart();replay._toggle();replay._process(float(replay.snapshot.duration)+1)
  for tick:int in range(30):
   for actor:Node2D in replay.actors.values():actor._process(1.0/30.0)
  check(replay._result.title_label.text==("¡VICTORIA!" if record.winner=="player" else "DERROTA"),"Online outcome also matches opposite viewer")
  check(var_to_bytes(record)==bytes,"Switching viewer never rewrites record")
  await capture("online-victoria",extent)
  replay.free();await process_frame
 canvas.free()
 print("BATTLE UI REFRESH: %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func capture(label:String,extent:Vector2):
 await process_frame;await process_frame
 if output.is_empty():return
 RenderingServer.force_draw()
 check(canvas.get_texture().get_image().save_png(output.path_join("%s-%dx%d.png" % [label,extent.x,extent.y]))==OK,"Native capture saved")
