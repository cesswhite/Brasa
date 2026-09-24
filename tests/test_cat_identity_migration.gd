extends SceneTree
const Identity=preload("res://scripts/fighter_identity.gd")
const Cosmetics=preload("res://scripts/cosmetic_catalog.gd")
const League=preload("res://scripts/progression.gd")
const Story=preload("res://scripts/story_progression.gd")
const FIXTURE="res://tests/fixtures/identity-before-cats-v1.json"
class FaultStore extends "res://scripts/fighter_identity.gd":
 var fail_final:bool=false
 func _rename(from:String,to:String)->bool:
  if fail_final and from.ends_with(".tmp") and not from.ends_with(".bak.tmp"):return false
  return super._rename(from,to)
var checks:int=0
var failures:int=0
var base:String
func check(value:bool,label:String)->void:
 checks+=1
 if not value:
  failures+=1
  push_error("CAT IDENTITY: "+label)
func _init()->void:
 base=ProjectSettings.globalize_path("res://../../work/cats/identity_%d" % Time.get_ticks_usec()).simplify_path()
 DirAccess.make_dir_recursive_absolute(base)
 _migrate()
 _corruption()
 _failure()
 print("CAT IDENTITY MIGRATION: %d checks, %d failures" % [checks,failures])
 quit(0 if failures==0 else 1)
func _write(path:String,value:Variant)->void:
 var f:FileAccess=FileAccess.open(path,FileAccess.WRITE)
 f.store_string(JSON.stringify(value,"\t") if value is Dictionary else str(value))
 f.close()
func _fixture(name:String)->String:
 var path:String=base.path_join(name+".json")
 DirAccess.copy_absolute(ProjectSettings.globalize_path(FIXTURE),path)
 return path
func _migrate()->void:
 var path:String=_fixture("migration")
 var original:String=FileAccess.get_file_as_string(path)
 var raw:Dictionary=JSON.parse_string(original)
 check(raw.version==1 and raw.inventory.size()==22 and raw.fighters.size()==13,"Portable fixture predates cats and contains thirteen identities")
 var store=Identity.new()
 store.load_save(path)
 check(not store.save_blocked and store.last_save_ok,"Old identity loads without reset or protection block")
 check(store.data.version==2 and store.owned_ids().size()==24,"Only identity sidecar advances to v2 with two new defaults")
 check(store.data.account_id==raw.account_id and store.data.created_at==raw.created_at and store.data.updated_at==raw.updated_at,"Account identity and original dates remain unchanged in memory")
 check(FileAccess.get_file_as_string(path)==original and not FileAccess.file_exists(path+".bak"),"Loading does not write primary or backup")
 for id:String in raw.fighters:check(Identity._equivalent(store.entry(id),raw.fighters[id]),"Original fighter ID, name, body and dates remain exact: "+id)
 for id:String in raw.inventory:check(Identity._equivalent(store.data.inventory[id],raw.inventory[id]),"Original inventory record is unchanged")
 check(store.entry("tepa").identity.display_name=="Conejita 🐾" and store.entry("tepa").identity.legacy_name,"Grandfathered legacy name survives migration")
 check(store.entry("sira").appearance.body_style_id=="luma" and store.entry("sira").identity.display_name=="Estrella antigua","Custom body and custom name survive migration")
 check(not store.owned("palette","luna") and not store.owned("aura","corona"),"Migration does not invent progression rewards")
 check(store.save(),"Explicit save persists migration even before any customization")
 var saved:String=FileAccess.get_file_as_string(path)
 check(JSON.parse_string(saved).version==2 and FileAccess.get_file_as_string(path+".bak")==original,"First save retains exact v1 bytes in backup")
 check(store.save() and FileAccess.get_file_as_string(path)==saved and FileAccess.get_file_as_string(path+".bak")==original,"Second save is a no-op and does not rotate backup")
 var restored=Identity.new()
 restored.load_save(path)
 check(not restored.save_blocked and Identity._equivalent(restored.data,store.data),"Migration reload retains stable IDs and inventory")
 var league_path:String=base.path_join("league.json")
 var story_path:String=base.path_join("story.json")
 DirAccess.copy_absolute(ProjectSettings.globalize_path("res://tests/fixtures/league-before-cats.json"),league_path)
 DirAccess.copy_absolute(ProjectSettings.globalize_path("res://tests/fixtures/story-before-cats.json"),story_path)
 var league_bytes:String=FileAccess.get_file_as_string(league_path)
 var story_bytes:String=FileAccess.get_file_as_string(story_path)
 var league=League.new()
 var story=Story.new()
 league.load_save(league_path)
 story.load_save(story_path)
 var old_league:Dictionary=league.roster.duplicate(true)
 var old_story:Dictionary=story.roster.duplicate(true)
 restored.migrate_legacy(league.roster,story.roster)
 for id:String in ["onix","bruma"]:
  check(restored.owned("body_style",id),"New cat body is owned: "+id)
  var appearance:Dictionary=Cosmetics.default_appearance(id)
  check(restored.update_fighter(id,"Gato "+id,appearance).ok,"New cat can equip its own body and save")
  var left:Dictionary=restored.decorate({"character_id":id,"mode":"league","level":7})
  var right:Dictionary=restored.decorate({"character_id":id,"mode":"story","level":12})
  check(left.fighter_id==right.fighter_id and left.appearance==right.appearance and left.identity==right.identity,"Both modes share stable cat identity and body")
  check(left.level==7 and right.level==12,"Decoration cannot reset either gameplay level")
  check(restored.update_fighter("sira","Estrella antigua",appearance).ok,"An old fighter can equip the new cosmetic body")
 check(Identity._equivalent(league.roster,old_league) and Identity._equivalent(story.roster,old_story),"Migration and customization leave all gameplay profiles intact")
 check(FileAccess.get_file_as_string(league_path)==league_bytes and FileAccess.get_file_as_string(story_path)==story_bytes,"Both gameplay files retain exact bytes")
 var final_store=Identity.new()
 final_store.load_save(path)
 check(not final_store.save_blocked and final_store.data.fighters.size()==15 and Identity._equivalent(final_store.data,restored.data),"Fifteen customized identities survive final reload")
func _corruption()->void:
 var original:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
 var expanded:Dictionary=Identity._decode(original)
 for fault:String in ["old_default","reward","unknown","future","new_missing","equipped_missing","record","name","version_string"]:
  var raw:Dictionary=original.duplicate(true)
  match fault:
   "old_default":raw.inventory.erase("body_style:balam")
   "reward":raw.fighters.sira.appearance.aura_id="corona"
   "unknown":raw.inventory["body_style:fake"]={"source":"default","unlocked_at":raw.created_at,"requirement":{"kind":"default","threshold":0}}
   "future":raw.version=Identity.VERSION+1
   "new_missing":raw=expanded.duplicate(true);raw.inventory.erase("body_style:onix")
   "equipped_missing":raw.fighters.sira.appearance.body_style_id="onix"
   "record":raw.inventory["body_style:onix"]={"source":"reward","unlocked_at":raw.created_at,"requirement":{"kind":"default","threshold":0}}
   "name":raw.fighters.sira.identity.display_name="Admin";raw.fighters.sira.identity.normalized_name="admin"
   "version_string":raw.version="1"
  var before:Dictionary=raw.duplicate(true)
  check(Identity._decode(raw).is_empty() and Identity._equivalent(raw,before),"Migration neither masks corruption nor mutates source: "+fault)
  var path:String=base.path_join("bad_"+fault+".json")
  _write(path,raw)
  _write(path+".bak",original)
  var bytes:String=FileAccess.get_file_as_string(path)
  var backup:String=FileAccess.get_file_as_string(path+".bak")
  var store=Identity.new()
  store.load_save(path)
  check(store.save_blocked and not store.save(),"Corrupt identity remains fail-closed: "+fault)
  check(FileAccess.get_file_as_string(path)==bytes and FileAccess.get_file_as_string(path+".bak")==backup,"Corrupt original and valid old backup preserved")
 var partial:Dictionary=original.duplicate(true)
 partial.inventory["body_style:onix"]=expanded.inventory["body_style:onix"].duplicate(true)
 var normalized:Dictionary=Identity._decode(partial)
 check(not normalized.is_empty() and normalized.inventory.size()==24 and Identity._equivalent(normalized.inventory["body_style:onix"],partial.inventory["body_style:onix"]),"Partially introduced legitimate defaults are not granted twice")
 var all_v1:Dictionary=expanded.duplicate(true)
 all_v1.version=1
 check(Identity._equivalent(Identity._decode(all_v1),expanded),"Intermediate v1 with both cat defaults upgrades without changing records")
func _failure()->void:
 var path:String=_fixture("failure")
 var bytes:String=FileAccess.get_file_as_string(path)
 var store=FaultStore.new()
 store.load_save(path)
 var before:Dictionary=store.data.duplicate(true)
 store.fail_final=true
 check(not store.save() and not store.last_save_ok,"Injected rename failure rejects migration commit")
 check(Identity._equivalent(store.data,before) and FileAccess.get_file_as_string(path)==bytes,"Failure keeps migrated memory and original v1 file exact")
 check(FileAccess.get_file_as_string(path+".bak")==bytes and not DirAccess.dir_exists_absolute(path+".lock"),"Failure preserves backup and releases transaction lock")
 store.fail_final=false
 check(store.save(),"Migration can be retried after transient failure")
 var stale=Identity.new()
 stale.load_save(path)
 store.update_fighter("sira","Cambio concurrente",store.entry("sira").appearance)
 var committed:String=FileAccess.get_file_as_string(path)
 check(not stale.update_fighter("bruma","No sobrescribir",{}).ok and stale.save_blocked,"Stale migration writer cannot overwrite another saved identity")
 check(FileAccess.get_file_as_string(path)==committed,"Concurrent successful save survives stale retry")
