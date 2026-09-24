extends SceneTree
const Catalog=preload("res://scripts/character_catalog.gd")
const Moves=preload("res://scripts/move_catalog.gd")
const Battle=preload("res://scripts/combat_engine.gd")
const Story=preload("res://scripts/story_catalog.gd")
const Config=preload("res://scripts/campaign_config.gd")
const Audit=preload("res://tests/simulate_campaign100.gd")
const IDS:Array[String]=["onix","bruma"]
class MemoryStory extends "res://scripts/story_progression.gd":
 func save()->bool:
  last_save_ok=true
  return true
var matches:int=0
var seconds:float=0.0
var signatures:int=0
var timeouts:int=0
var uses:Dictionary={}
var stages:Dictionary={}
func _init()->void:
 var quick:bool=OS.get_cmdline_user_args().has("--quick")
 var samples:int=8 if quick else 20
 var runs:int=0 if OS.get_cmdline_user_args().has("--league-only") else (1 if quick else 2)
 var output:String="res://reports/cat_roster_balance.json"
 for arg:String in OS.get_cmdline_user_args():
  if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
 var source_hashes:Dictionary={}
 for file:String in ["character_catalog.gd","move_catalog.gd","combat_engine.gd","story_catalog.gd","story_progression.gd","campaign_config.gd"]:source_hashes[file]=FileAccess.get_sha256("res://scripts/"+file)
 var started:int=Time.get_ticks_msec()
 var league:Array[Dictionary]=[]
 for hero_index:int in range(IDS.size()):
  var id:String=IDS[hero_index]
  for level:int in [1,10,25,50]:
   var wins:int=0
   var played:int=0
   var matchup:Array[Dictionary]=[]
   for foe_index:int in range(Catalog.IDS.size()):
    var foe:String=Catalog.IDS[foe_index]
    var versus_wins:int=0
    var player:Dictionary={"character_id":id,"level":level,"stats":Catalog.definition(id).training_base}
    var rival:Dictionary={"character_id":foe,"level":level,"stats":Catalog.definition(foe).training_base}
    for sample:int in range(samples):
     var seed_value:int=97100000+hero_index*1000000+level*10000+foe_index*100+sample
     if _fight(player,rival,seed_value).winner=="player":versus_wins+=1
     if _fight(rival,player,seed_value).winner=="rival":versus_wins+=1
    wins+=versus_wins
    played+=samples*2
    matchup.append({"opponent":foe,"wins":versus_wins,"matches":samples*2})
   league.append({"character_id":id,"level":level,"wins":wins,"matches":played,"win_rate":float(wins)/played,"matchups":matchup})
   print("CAT league %s L%d %.1f%%" % [id,level,100.0*wins/played])
 var campaigns:Array[Dictionary]=[]
 var completed:int=0
 for hero_index:int in range(IDS.size()):
  var id:String=IDS[hero_index]
  for build_index:int in range(Audit.BUILDS.size()):
   var build:String=str(Audit.BUILDS.keys()[build_index])
   var results:Array[Dictionary]=[]
   for repetition:int in range(runs):
    var p=MemoryStory.new()
    p.select_character(id)
    p.data.run_seed=26710000+hero_index*100000+build_index*1000+repetition
    var cursor:int=0
    var fights:int=0
    var encountered:Array[Dictionary]=[]
    while not p.campaign_completion().completed and fights<500:
     if p.is_complete():p.start_next_chapter()
     var global_level:int=p.global_level()
     var attempts:int=0
     var won:bool=false
     while not won and attempts<Config.MAX_STAGE_ATTEMPTS:
      cursor=_spend(p,build,cursor)
      var result:Dictionary=_fight(p.active_combatant(),p.make_rival(),883000000+hero_index*1000000+build_index*100000+repetition*10000+fights)
      won=result.winner=="player"
      var reward:Dictionary=p.reward_match(result)
      if not reward.accepted:
       push_error("New hero campaign result rejected")
       quit(1)
       return
      if not stages.has(str(global_level)):stages[str(global_level)]={"fights":0,"wins":0,"first_attempts":0,"first_wins":0,"hero_level_sum":0}
      var metric:Dictionary=stages[str(global_level)]
      metric.fights+=1
      metric.wins+=1 if won else 0
      metric.first_attempts+=1 if attempts==0 else 0
      metric.first_wins+=1 if attempts==0 and won else 0
      metric.hero_level_sum+=int(result.player.level)
      fights+=1
      attempts+=1
     encountered.append({"level":global_level,"won":won,"attempts":attempts,"hero_level":int(p.data.level)})
     if not won:break
    var done:bool=bool(p.campaign_completion().completed)
    if done:completed+=1
    results.append({"completed":done,"run_seed":p.data.run_seed,"repetition":repetition,"fights":fights,"cleared":int(p.campaign_completion().defeated),"hero_level":int(p.data.level),"allocations":p.data.allocations.duplicate(),"perks":p.data.perks.duplicate(),"move_upgrades":p.data.move_upgrades.duplicate(),"stages":encountered})
   var done:int=0
   var fights:int=0
   for result:Dictionary in results:
    if result.completed:done+=1
    fights+=int(result.fights)
   print("CAT story %s/%s %d/%d complete %.1f battles" % [id,build,done,runs,float(fights)/maxi(1,runs)])
   campaigns.append({"character_id":id,"build":build,"runs":results})
 var definitions:Dictionary={}
 for id:String in IDS:definitions[id]={"character":Catalog.definition(id),"moves":Moves.moves_for(id),"perks":Moves.perks_for(id)}
 var report:Dictionary={"matches":matches,"league_matches":IDS.size()*4*Catalog.IDS.size()*samples*2,"league":league,"campaigns":campaigns,"campaign_count":IDS.size()*Audit.BUILDS.size()*runs,"completed":completed,"stages":stages,"new_move_usage":uses,"mean_seconds":seconds/maxi(1,matches),"signatures":signatures,"signature_incidence":float(signatures)/maxi(1,matches*2),"timeouts":timeouts,"source_hashes":source_hashes,"definitions":definitions,"builds":Audit.BUILDS,"samples_per_league_matchup_side":samples,"elapsed_seconds":float(Time.get_ticks_msec()-started)/1000.0,"notes":"Only new heroes tuned. Equal-level league baselines with no training or perks, both sides and all15opponents. Natural100encounter campaigns use legal fixed priorities, actual XP/moves/perks, no respec and24attempt cutoff. Every save disabled; no real save opened."}
 var file:FileAccess=FileAccess.open(output,FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"\t"))
 file.close()
 print("CAT AUDIT %d/%d campaigns, %d battles: %s" % [completed,report.campaign_count,matches,output])
 quit()
func _fight(player:Dictionary,rival:Dictionary,seed_value:int)->Dictionary:
 var engine=Battle.new()
 engine.start(player,rival,seed_value)
 engine.advance(60.0)
 var result:Dictionary=engine.summary()
 matches+=1
 seconds+=float(result.duration)
 signatures+=int(result.metrics.player.signatures)+int(result.metrics.rival.signatures)
 if result.reason=="timeout":timeouts+=1
 for side:String in ["player","rival"]:
  if str(result[side].character_id) in IDS:
   for id:String in result.metrics[side].move_uses:uses[id]=int(uses.get(id,0))+int(result.metrics[side].move_uses[id])
 return result
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
  if not spent:break
 var perks:Array[Dictionary]=Moves.perks_for(str(p.active_id))
 for index:int in Audit.PERK_ORDER[build]:
  if int(p.data.perk_points)>0 and not str(perks[index].id) in p.data.perks:p.choose_perk(str(perks[index].id))
 for kind:String in Audit.MOVE_TYPES[build]:
  for move:Dictionary in Moves.unlocked_moves(str(p.active_id),int(p.data.level)):
   if str(move.type)==kind:
    while p.can_upgrade_move(str(move.id)):p.upgrade_move(str(move.id))
 return cursor
