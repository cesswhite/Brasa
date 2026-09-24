extends SceneTree
const Catalog=preload("res://scripts/character_catalog.gd")
const Moves=preload("res://scripts/move_catalog.gd")
const Story=preload("res://scripts/story_catalog.gd")
const StoryProgress=preload("res://scripts/story_progression.gd")
const League=preload("res://scripts/progression.gd")
const Balance=preload("res://scripts/balance.gd")
const EngineModel=preload("res://scripts/combat_engine.gd")
const Effects=preload("res://scripts/status_effects.gd")
const NEW_IDS:Array[String]=["balam","tepa","xuna","copal"]
class MemoryStory extends "res://scripts/story_progression.gd":
 func save()->bool:
  last_save_ok=true
  return true
var checks:int=0
var failures:int=0
var directory:String
var serial:int=0
func _init()->void:
 directory=ProjectSettings.globalize_path("res://../../work/mexican/fixtures_%d" % Time.get_ticks_usec()).simplify_path()
 DirAccess.make_dir_recursive_absolute(directory)
 _legacy()
 _definitions()
 _saves()
 _combat()
 print("MEXICAN ROSTER: %d checks, %d failures" % [checks,failures])
 quit(0 if failures==0 else 1)
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:
  failures+=1
  push_error("MEXICAN ROSTER: "+label)
func _legacy()->void:
 var baseline:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/roster-before-mexican.json"))
 check(Catalog.IDS.size()>=13,"Original thirteen playable characters remain available")
 for index:int in range(9):
  var id:String=str(baseline.ids[index])
  check(Catalog.IDS[index]==id,"Existing character order retained")
  check(StoryProgress._equivalent(Catalog.definition(id),baseline.definitions[index]),"Existing character definition unchanged: "+id)
  check(StoryProgress._equivalent(Moves.moves_for(id),baseline.moves[id]),"Existing techniques unchanged: "+id)
  check(StoryProgress._equivalent(Moves.perks_for(id),baseline.perks[id]),"Existing perks unchanged: "+id)
 for index:int in range(4):check(Catalog.IDS[index+9]==NEW_IDS[index],"New identities appended without shifting indices")
 for level:int in range(1,101):
  var stage:Dictionary=Story.global_stage(level)
  check(StoryProgress._equivalent(stage.get("opponent_pool",[]),baseline.story_pools[str(level)]),"Existing campaign pools unchanged")
  if level<=16:check(StoryProgress._equivalent(stage,baseline.story_first16[level-1]),"Original first sixteen encounters unchanged")
func _definitions()->void:
 var move_ids:Array[String]=[]
 var perk_ids:Array[String]=[]
 for id:String in NEW_IDS:
  var d:Dictionary=Catalog.definition(id)
  check(not str(d.species).is_empty() and not str(d.biography).is_empty() and str(d.personality).to_lower().contains(str(d.species).to_lower()),"Species and biography visible in metadata")
  check(str(d.visual.atlas)=="res://assets/sprites/%s-v1.png" % id,"Unique atlas assigned")
  check(d.signature.damage_multiplier>=1.4 and d.signature.damage_multiplier<=1.8 and Effects.NAMES.has(str(d.signature.effect)),"Signature uses existing bounded rules")
  check(Moves.moves_for(id).size()==5 and Moves.perks_for(id).size()==6,"Five techniques and six own perks")
  check(Moves.unlocked_moves(id,1).size()==2 and Moves.unlocked_moves(id,5).size()==3 and Moves.unlocked_moves(id,12).size()==4 and Moves.unlocked_moves(id,20).size()==5,"Standard unlock progression")
  for level:int in [1,10,25,50]:
   var stats:Dictionary=Catalog.stats_for({"character_id":id,"level":level,"stats":d.training_base})
   for key:String in Balance.STAT_BOUNDS:
    check(float(stats[key])>=float(Balance.STAT_BOUNDS[key][0]) and float(stats[key])<=float(Balance.STAT_BOUNDS[key][1]),"New character respects global stat bounds")
  for move:Dictionary in Moves.moves_for(id):
   check(not str(move.id) in move_ids,"Every new technique has a unique ID")
   move_ids.append(str(move.id))
   check(not str(move.purpose).is_empty() and not str(move.risk).is_empty(),"Move purpose and tradeoff described")
   for field:String in ["status","self_status"]:
    if not move[field].is_empty():check(Effects.NAMES.has(str(move[field].type)),"Move uses an implemented status")
   var improved:Dictionary=Moves.resolve_move(id,str(move.id),2)
   check(improved.tier==2 and improved==Moves.resolve_move(id,str(move.id),999),"Move upgrades capped at tier two")
   var changed:Dictionary=move.duplicate(true)
   changed.damage_multiplier=99.0
   check(Moves.resolve_move(id,str(move.id)).damage_multiplier!=99.0,"Returned definitions cannot corrupt catalog")
  for perk:Dictionary in Moves.perks_for(id):
   check(not str(perk.id) in perk_ids and str(perk.id).begins_with(id+"_"),"Perk identity belongs to character")
   perk_ids.append(str(perk.id))
   var useful:bool=not Moves.passive_bonuses(id,[str(perk.id)],0.2)==Moves.passive_bonuses(id,[],0.2)
   for move:Dictionary in Moves.moves_for(id):
    if Moves.resolve_move(id,str(move.id),0,[str(perk.id)])!=Moves.resolve_move(id,str(move.id)):useful=true
   check(useful,"Every perk changes an implemented move or passive")
func _story_summary(p:RefCounted)->Dictionary:
 serial+=1
 return {"battle_id":"mexican_%d" % serial,"winner":"player","reason":"normal","duration":30.0,"player":p.active_combatant(),"rival":p.make_rival(),"metrics":{}}
func _saves()->void:
 var league_path:String=directory.path_join("old_league.json")
 var story_path:String=directory.path_join("old_story_v3.json")
 var old_league=League.new()
 old_league.load_save(league_path)
 old_league.select_character("sira")
 old_league.upgrade("life")
 old_league.reward(true)
 var old_story=StoryProgress.new()
 old_story.load_save(story_path)
 old_story.select_character("sira")
 old_story.upgrade("attack")
 for index:int in range(8):old_story.reward_match(_story_summary(old_story))
 var legacy:Dictionary=old_story.completion_summary()
 old_story.start_next_chapter()
 var league_before:Dictionary=old_league.data.duplicate(true)
 var story_before:Dictionary=old_story.data.duplicate(true)
 var league_bytes:String=FileAccess.get_file_as_string(league_path)
 var story_bytes:String=FileAccess.get_file_as_string(story_path)
 var league=League.new()
 var story=StoryProgress.new()
 league.load_save(league_path)
 story.load_save(story_path)
 check(not league.save_blocked and not story.save_blocked,"Existing league v2 and story v3 load")
 check(FileAccess.get_file_as_string(league_path)==league_bytes and FileAccess.get_file_as_string(story_path)==story_bytes,"Loading old saves writes neither file")
 for id:String in NEW_IDS:
  check(league.select_character(id) and story.select_character(id),"New character selectable in both modes")
  check(league.data.level==1 and story.data.level==1 and story.data.points==3,"Independent normal starting progression")
  check(league.upgrade("strength") and story.upgrade("defense"),"Both stat progression systems work")
  check(league.reward(true).xp_gained>0 and story.reward_match(_story_summary(story)).accepted,"Both modes accept progress")
  check(league.last_save_ok and story.last_save_ok,"New profiles save validly")
  var reloaded_league=League.new()
  var reloaded_story=StoryProgress.new()
  reloaded_league.load_save(league_path)
  reloaded_story.load_save(story_path)
  check(StoryProgress._equivalent(reloaded_league.data,league.data) and StoryProgress._equivalent(reloaded_story.data,story.data),"Both new profiles survive reload")
  check(league._opponent_candidate(id,1,0).profile.character_id==id,"New character eligible for league opponents")
 league.select_character("sira")
 story.select_character("sira")
 check(StoryProgress._equivalent(league.data,league_before),"Old league progress unchanged when returning")
 check(StoryProgress._equivalent(story.data,story_before) and StoryProgress._equivalent(story.completion_summary(1),legacy),"Old story and frozen legacy unchanged")
 check(league.roster.size()==5 and story.roster.size()==5,"Existing profile and four new profiles coexist")
 for id:String in NEW_IDS:
  var p=MemoryStory.new()
  p.select_character(id)
  for level:int in range(1,11):
   if p.is_complete():p.start_next_chapter()
   p.reward_match(_story_summary(p))
  check(p.data.move_points==2 and p.data.perk_points==1,"Standard milestone currencies apply")
  check(p.upgrade_move(str(p.data.unlocked_moves[0])) and p.choose_perk(str(p.available_perks()[0].id)),"New move upgrades and perks selectable")
  var before:Dictionary=p.data.duplicate(true)
  check(p.respec_build() and p.data.total_xp==before.total_xp and p.data.current_stage==before.current_stage,"New characters can redistribute without losing progress")
func _combat()->void:
 var used:Dictionary={}
 for id:String in NEW_IDS:
  var d:Dictionary=Catalog.definition(id)
  var descriptor:Dictionary={"character_id":id,"level":25,"stats":d.training_base,"name":d.name}
  for seed_value:int in range(20):
   var fast=EngineModel.new()
   var slow=EngineModel.new()
   fast.start(descriptor,Story.opponent(7,2),612000+seed_value)
   slow.start(descriptor,Story.opponent(7,2),612000+seed_value)
   fast.advance(60.0)
   while slow.running:slow.advance(0.137)
   check(fast.summary()==slow.summary(),"New moves remain deterministic across delta partitions")
   for key:String in fast.summary().metrics.player.move_uses:used[key]=true
  for move:Dictionary in Moves.moves_for(id):check(used.has(str(move.id)),"Every new move is selected by normal AI")
  var engine=EngineModel.new()
  engine.start(descriptor,Story.opponent(7,2),412,{"force_signature":"player","signature_turn":2,"initial_hp":{"rival":1.0}})
  engine.advance(60.0)
  check(not engine.running and engine.summary().metrics.player.signatures<=1,"Signature cannot repeat after terminal victory")
  var armed=EngineModel.new()
  armed.start(descriptor,Story.opponent(7,2),8172,{"force_signature":"player","signature_turn":1})
  armed.advance(60.0)
  var signature_hits:int=0
  var effect_applied:bool=false
  for event:Dictionary in armed.summary().events:
   if str(event.type)=="attack" and str(event.side)=="player" and bool(event.get("signature",false)):
    signature_hits+=1
    check(str(event.result)=="signature" and int(event.damage)>0,"Own Signature always connects without critical stacking")
   if str(event.type)=="status_applied" and str(event.source)=="player" and str(event.effect)==str(d.signature.effect):effect_applied=true
  check(signature_hits==1 and armed.summary().metrics.player.signatures==1 and effect_applied,"Each own Signature fires once and applies its declared debuff")
  var finished:Dictionary=armed.summary()
  armed.advance(60.0)
  check(armed.summary()==finished,"Advancing after new Signature battle ends changes nothing")
  for seed_value:int in range(50):
   var original=EngineModel.new()
   var added=EngineModel.new()
   original.start({"character_id":"nima","level":1}, {"character_id":"luma","level":1},77100+seed_value)
   added.start(descriptor,{"character_id":"luma","level":1},77100+seed_value)
   check(original._fighters.player.signature_armed==added._fighters.player.signature_armed,"Added moves do not alter match-level signature roll")
