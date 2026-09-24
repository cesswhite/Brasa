extends SceneTree
const Audit=preload("res://tests/simulate_campaign100.gd")
const Catalog=preload("res://scripts/character_catalog.gd")
const Progress=preload("res://scripts/story_progression.gd")
const Moves=preload("res://scripts/move_catalog.gd")
const Battle=preload("res://scripts/combat_engine.gd")
class MemoryCampaign extends "res://scripts/story_progression.gd":
 func save()->bool:
  last_save_ok=true
  return true
var count:int=0
func _init()->void:
 var report:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://reports/campaign100_balance.json"))
 var recoveries:Array[Dictionary]=[]
 for row:Dictionary in report.rows:
  for run:Dictionary in row.runs:
   if bool(run.completed): continue
   var hero_index:int=Catalog.IDS.find(str(row.character_id))
   var build_index:int=Audit.BUILDS.keys().find(str(row.build))
   var p=MemoryCampaign.new()
   p.select_character(str(row.character_id))
   p.data.run_seed=int(run.run_seed)
   var cursor:int=0
   var seed_base:int=951000000+hero_index*1000000+build_index*100000+int(run.repetition)*10000
   for index:int in range(int(run.fights)):
    if p.is_complete(): p.start_next_chapter()
    cursor=_spend(p,str(row.build),cursor)
    var reward:Dictionary=p.reward_match(_fight(p,seed_base+index))
    if not reward.accepted:
     push_error("Recovery reproduction reward rejected")
     quit(1)
     return
   var exact:bool=int(p.campaign_completion().defeated)==int(run.cleared) and Progress._equivalent(p.data.allocations,run.allocations)
   if not exact:
    push_error("Failed campaign did not reproduce exactly: %s / %s allocations %s / %s" % [p.campaign_completion().defeated,run.cleared,p.data.allocations,run.allocations])
    quit(1)
    return
   var before:Dictionary=p.data.duplicate(true)
   if not p.respec_build():
    push_error("Recovery respec rejected")
    quit(1)
    return
   var retained:bool=p.data.level==before.level and p.data.xp==before.xp and p.data.total_xp==before.total_xp and p.data.current_stage==before.current_stage and p.data.defeated==before.defeated
   cursor=_spend(p,"balanced",0)
   var retry:int=0
   while not p.campaign_completion().completed and retry<24:
    if p.is_complete(): p.start_next_chapter()
    var reward:Dictionary=p.reward_match(_fight(p,seed_base+int(run.fights)+retry))
    if not reward.accepted:
     push_error("Recovery result rejected")
     quit(1)
     return
    retry+=1
   recoveries.append({"character_id":row.character_id,"original_build":row.build,"repetition":run.repetition,"seed":run.run_seed,"failed_at":int(run.cleared)+1,"original_fights":run.fights,"exact_reproduction":exact,"respec_preserved_progress":retained,"new_build":"balanced","completed":bool(p.campaign_completion().completed),"additional_fights":retry,"final_allocations":p.data.allocations.duplicate(),"final_perks":p.data.perks.duplicate()})
 var file:FileAccess=FileAccess.open("res://reports/campaign100_recovery.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"matches":count,"recoveries":recoveries,"note":"Exact deterministic replay of every fixed-policy run stopped at 24 attempts; then an explicit legal respec into the declared balanced priority, no XP/build injection and no saved files opened."},"\t"))
 file.close()
 print("CAMPAIGN RECOVERY: ",recoveries)
 quit()
func _fight(p:RefCounted,seed_value:int)->Dictionary:
 var engine=Battle.new()
 engine.start(p.active_combatant(),p.make_rival(),seed_value)
 engine.advance(60.0)
 count+=1
 return engine.summary()
func _spend(p:RefCounted,build:String,cursor:int)->int:
 var priorities:Array=Audit.BUILDS[build]
 while int(p.data.points)>0:
  var spent:bool=false
  for trial:int in range(priorities.size()):
   var key:String=str(priorities[cursor%priorities.size()])
   cursor+=1
   if p.upgrade(key):
    spent=true
    break
  if not spent: break
 var perks:Array[Dictionary]=Moves.perks_for(str(p.active_id))
 for index:int in Audit.PERK_ORDER[build]:
  if int(p.data.perk_points)>0 and not str(perks[index].id) in p.data.perks: p.choose_perk(str(perks[index].id))
 for kind:String in Audit.MOVE_TYPES[build]:
  for move:Dictionary in Moves.unlocked_moves(str(p.active_id),int(p.data.level)):
   if str(move.type)==kind:
    while p.can_upgrade_move(str(move.id)): p.upgrade_move(str(move.id))
 return cursor
