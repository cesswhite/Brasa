extends SceneTree
const Story = preload("res://scripts/story_progression.gd")
const Catalog = preload("res://scripts/story_catalog.gd")
const Characters = preload("res://scripts/character_catalog.gd")
const Identity = preload("res://scripts/fighter_identity.gd")
const Model = preload("res://scripts/story_achievements.gd")
const PanelScript = preload("res://scripts/ui/story_panel.gd")
const Sizes = preload("res://tests/test_story_panel.gd")
var failures:=0
var checks:=0
var canvas:SubViewport
var output:=""
var panel
func _init():run.call_deferred()
func check(ok:bool,message:String):
 checks+=1
 if not ok:failures+=1;push_error(message)
func settle():
 for frame in range(4):await process_frame
func fixture(id:String,chapter:int,stage:int,level:int)->Dictionary:
 var profile=Story._new_profile(id)
 profile.chapter=chapter;profile.current_stage=stage;profile.level=level
 profile.completed=stage==Catalog.stages(chapter).size()
 profile.wins=stage;profile.matches=stage+2;profile.losses=2
 profile.badge=Catalog.chapter(chapter).badge if profile.completed else ""
 Story._sync_campaign(profile)
 if profile.completed:Story._capture_completion(profile,id)
 return profile
func run():
 for arg:String in OS.get_cmdline_user_args():
  if arg.begins_with("--capture-dir="):output=arg.trim_prefix("--capture-dir=");DirAccess.make_dir_recursive_absolute(output)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.size=Vector2i(360,240)
 canvas=SubViewport.new();canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(canvas)
 var story=Story.new()
 var nima=fixture("nima",4,10,33)
 for number in range(1,4):
  var old=fixture("nima",number,Catalog.stages(number).size(),number*8)
  nima.chapter_records[str(number)]={"profile":old,"summary":old.completion_snapshot.summary.duplicate(true)}
 nima.replay_wins=40
 var luma=fixture("luma",1,2,3)
 story.roster={"nima":nima,"luma":luma};story.active_id="nima";story.data=nima
 var snapshot=Model.snapshot(nima)
 check(snapshot.wins==30,"Victories aggregate archived chapters once, excluding practice")
 check(snapshot.cleared==30 and snapshot.chapters==4,"Chapter four progress is preserved")
 check(snapshot.records.size()==4,"Current completion snapshot and all archives available")
 check(Model.snapshot({}).earned==0,"No achievements fabricated for unstarted character")
 check(Model.snapshot(luma).cleared==2,"Independent character progress")
 var account=Identity.new()
 for id:String in Characters.IDS:account.entry(id)
 for id:String in ["aura:farol","palette:grana","aura:petalos"]:account.data.inventory[id]={"source":"fixture"}
 var original=var_to_bytes(story.roster)
 var original_account=var_to_bytes(account.data)
 panel=PanelScript.new();panel.identity_store=account;canvas.add_child(panel);panel.configure(story)
 var emitted:Array[String]=[]
 panel.character_chosen.connect(func(id:String):emitted.append(id))
 for extent:Vector2i in Sizes.SIZES:
  canvas.size=extent;panel._achievement_character="nima";panel._achievement_record=false;panel._achievement_filter="pending";panel.show_tab("legacy");await settle()
  check(panel._tab_buttons.legacy.text=="Logros","Tab gives understandable purpose")
  check(panel._primary.text=="Comenzar capítulo 5","Next action matches saved progress")
  check(not panel._backdrop.get_node("DecorativeMemories").visible,"Decorative props removed from reading screen")
  await capture("objetivos",extent)
  panel._achievement_filters.earned.pressed.emit();await settle()
  check(panel._achievement_filters.earned.has_focus(),"Filter preserves keyboard focus")
  check(panel._chapter_buttons.size()==4,"Four earned chapter memories can be opened")
  await capture("conseguidos",extent)
  panel._select_legacy(4);await settle()
  check(panel._achievement_record,"Chapter card opens saved memory")
  await capture("recuerdo",extent)
  panel._achievement_record=false;panel._achievement_filter="collection";panel._rebuild_body();await settle()
  var text=all_text(panel._body)
  check("Farol" in text and "Grana" in text and "Pétalos" in text,"Collection uses actual owned cosmetics")
  check(not "Luciérnagas" in text,"Unowned cosmetic is never claimed")
  await capture("coleccion",extent)
  panel._achievement_filter="pending"
  panel._achievement_picker.item_selected.emit(Characters.IDS.find("luma"));await settle()
  check(panel._achievement_snapshot.cleared==2 and story.active_id=="nima","Browsing another hero does not switch campaign")
  check(panel._primary.text=="Jugar con Luma","Explicit action offered for different character")
  panel._primary_pressed()
  check(emitted.back()=="luma" and story.active_id=="nima","Switch only emits user request")
  await capture("otro-personaje",extent)
  panel._achievement_picker.item_selected.emit(Characters.IDS.find("onix"));await settle()
  check(panel._achievement_snapshot.earned==0,"Unstarted character has no borrowed achievements")
  await capture("sin-campana",extent)
  story.save_blocked=true;panel._refresh_actions();var count=emitted.size();panel._primary_pressed()
  check(emitted.size()==count and panel._primary.disabled,"Protected save blocks campaign action")
  story.save_blocked=false
  check(var_to_bytes(story.roster)==original,"Read-only milestones never modify campaigns")
  check(var_to_bytes(account.data)==original_account,"Browsing never grants cosmetics")
 # All milestones can be reached without granting anything new.
 var final_profile=fixture("nima",11,10,50)
 for number in range(1,11):
  var old=fixture("nima",number,Catalog.stages(number).size(),mini(50,number*6))
  final_profile.chapter_records[str(number)]={"summary":old.completion_snapshot.summary}
 var final_snapshot=Model.snapshot(final_profile)
 check(final_snapshot.earned==17 and final_snapshot.wins==100,"Complete campaign earns all seventeen milestones exactly once")
 var empty=Story.new()
 panel.configure(empty);panel.show_tab("legacy");await settle()
 check(panel._active_tab=="legacy" and panel._achievement_snapshot.earned==0,"Logros works before any campaign has been created")
 check(panel._primary.text.begins_with("Jugar con"),"Empty state has an explicit start action")
 panel.free();canvas.free()
 print("ACHIEVEMENTS UI: %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func all_text(node:Node)->String:
 var text=""
 for label:Label in node.find_children("*","Label",true,false):text+=label.text+"\n"
 return text
func capture(state:String,extent:Vector2i):
 check(panel._body.size.x<=panel._scroll.size.x+1,"Content fits viewport: "+state+str(extent))
 check(Rect2(Vector2.ZERO,extent).grow(1).encloses(panel._primary.get_global_rect()),"Main action remains reachable")
 for label:Label in panel._body.find_children("*","Label",true,false):
  if label.is_visible_in_tree():check(label.size.y+1>=label.get_minimum_size().y,"Native text has readable height: "+label.text)
 if output.is_empty():return
 RenderingServer.force_draw()
 check(canvas.get_texture().get_image().save_png(output.path_join("%s-%dx%d.png" % [state,extent.x,extent.y]))==OK,"Capture saved")
