extends SceneTree
const Editor=preload("res://scripts/ui/customization_panel.gd")
const Fixtures=preload("res://tests/test_customization_visuals.gd")
const Cosmetics=preload("res://scripts/cosmetic_catalog.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1;push_error(label)
func _init():run.call_deferred()
func run():
 var store=Fixtures.MemoryIdentity.new()
 var panel=Editor.new();root.add_child(panel);panel.configure(store,"onix",false)
 panel.set_process(false);panel._actor.set_process(false);panel.select_tab(3)
 var original=panel._draft.duplicate(true)
 check(panel._style_controls.visible and not panel._preview_actions.visible,"Style has contextual playback controls")
 for section:int in range(2):
  panel._select_style_section(section)
  var slot="intro_animation_id" if section==0 else "victory_pose_id"
  check(Cosmetics.items(slot).size()==4,"Four distinct examples per moment")
  for item:Dictionary in Cosmetics.items(slot):
   original=panel._draft.duplicate(true)
   panel._choose_item(slot,item.id)
   check(panel._actor.appearance[slot]==item.id,"Choice previews actual renderer appearance")
   if not str(item.inventory_id) in panel._owned:
    check(panel._draft==original and panel._confirm.disabled,"Unowned example neither equips nor modifies draft")
    panel._confirm_draft()
    check(panel._draft==original,"Confirm handler rejects locked example")
    panel._try_back.pressed.emit()
    check(panel._actor.appearance==original and not panel._confirm.disabled,"Return restores complete actual appearance")
   original=panel._draft.duplicate(true)
   panel._replay_style()
   check(panel._draft==original,"Replay never edits appearance")
 panel._select_style_section(0)
 panel._actor._process(6);panel._process(4.1)
 check(panel._actor._intro_elapsed==0,"Automatic replay restarts entrance")
 panel._style_auto_button.button_pressed=false;panel._toggle_style_auto()
 panel._actor._process(6);panel._process(4.1)
 check(panel._actor._intro_elapsed>=6,"Auto off leaves finished demonstration alone")
 panel._style_auto_button.button_pressed=true;panel._toggle_style_auto()
 panel._actor._process(6);panel._actor.reduced_motion=true;panel._process(5)
 check(panel._actor._intro_elapsed>=6,"Reduced motion suppresses automatic repetition")
 panel._actor.reduced_motion=false;panel._actor.motion_paused=true;panel._process(5)
 check(panel._actor._intro_elapsed>=6,"Pause suppresses automatic repetition")
 panel._actor.motion_paused=false
 panel._choose_item("intro_animation_id","reverencia")
 panel._actor.play_attack();panel._actor._process(.1)
 var mode=panel._actor._mode;var time=panel._actor._action_time
 panel._actor.play_intro()
 check(panel._actor._mode==mode and panel._actor._action_time==time,"Cosmetic intro cannot reset an attack or its timing")
 # Every body shares a stable camera throughout the new authored presentations.
 panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
 for extent:Vector2 in [Vector2(390,844),Vector2(1360,880)]:
  panel.size=extent;panel._layout()
  for body:Dictionary in Cosmetics.items("body_style_id"):
   panel._draft.body_style_id=body.id
   for style:String in ["reverencia","bruma","serena","festival"]:
    var slot="intro_animation_id" if style in ["reverencia","bruma"] else "victory_pose_id"
    panel._try_slot=slot;panel._try_id=style;panel._refresh_preview()
    panel._preview_action("Entrada" if slot=="intro_animation_id" else "Victoria")
    for tick:int in range(80):
     panel._actor._process(.03)
     check(panel._stage.get_global_rect().grow(.25).encloses(panel._actor.visible_sprite_bounds()),"New style stays inside camera: "+str(body.id)+" "+style)
 panel.free()
 print("COSMETIC STYLES: %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
