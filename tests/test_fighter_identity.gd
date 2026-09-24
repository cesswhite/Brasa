extends SceneTree
const Identity=preload("res://scripts/fighter_identity.gd")
const Cosmetics=preload("res://scripts/cosmetic_catalog.gd")
const Characters=preload("res://scripts/character_catalog.gd")
const League=preload("res://scripts/progression.gd")
const Story=preload("res://scripts/story_progression.gd")
const Battle=preload("res://scripts/combat_engine.gd")
class MemoryLeague extends "res://scripts/progression.gd":
 func save()->bool:
  last_save_ok=true
  return true
class MemoryStory extends "res://scripts/story_progression.gd":
 func save()->bool:
  last_save_ok=true
  return true
class FaultStore extends "res://scripts/fighter_identity.gd":
 var fail:String=""
 func _write(path:String,value:String)->bool:
  return false if fail=="write" else super._write(path,value)
 func _copy(from:String,to:String)->bool:
  return false if fail=="copy" else super._copy(from,to)
 func _rename(from:String,to:String)->bool:
  return false if fail=="rename" and not to.ends_with(".bak") else super._rename(from,to)
var checks:int=0
var failures:int=0
var folder:String
var sequence:int=0
func _init()->void:
 folder=ProjectSettings.globalize_path("res://../../work/identity/tests_%d_%d" % [OS.get_process_id(),Time.get_ticks_usec()])
 DirAccess.make_dir_recursive_absolute(folder)
 _names()
 _catalog()
 _migration()
 _transactions()
 _corruption()
 _rewards()
 _snapshots()
 print("FIGHTER IDENTITY: %d checks, %d failures" % [checks,failures])
 quit(0 if failures==0 else 1)
func check(value:bool,label:String)->void:
 checks+=1
 if not value:
  failures+=1
  push_error("FIGHTER IDENTITY: "+label)
func path(label:String)->String:
 return folder.path_join(label+".json")
func write(file:String,payload:Variant)->void:
 var handle:FileAccess=FileAccess.open(file,FileAccess.WRITE)
 handle.store_string(payload if payload is String else JSON.stringify(payload))
 handle.close()
func equal(a:Variant,b:Variant)->bool:
 return Identity._equivalent(a,b)
func _names()->void:
 for name_value:String in ["Águila 7","光の風","Жар 12","BLACK COMET","O'Connor","Sol-Luna","한별","a2","1234","abcdefghijklmnopqrstuvwx"]:
  check(bool(Identity.validate_name(name_value).ok),"Valid Unicode name: "+name_value)
 for name_value:String in ["","a","abcdefghijklmnopqrstuvwxy","--","  ","admin"," ADMIN ","Sistema","moderador","administrator/","Bad\nName","Bad\tName","Bad\rName","Bad\u007fName","A\u0085B","A\u200bB","🐰 Conejo","<script>","a/b","a\\b","a_b","O’Connor","Cafe\u0301","\u00a0Sol\u00a0","\u2000Sol\u2000"]:
  check(not bool(Identity.validate_name(name_value).ok),"Invalid or reserved name rejected")
 var name_value:Dictionary=Identity.validate_name("  ÁGUILA   de  Jade  ")
 check(name_value.display_name=="ÁGUILA de Jade" and name_value.normalized_name=="águila de jade","Whitespace collapsed and original casing preserved")
func _catalog()->void:
 var exported:Dictionary=Cosmetics.export_catalog()
 var on_disk:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/cosmetic_catalog.json"))
 check(equal(exported,on_disk),"Portable backend JSON is exactly the live cosmetic catalog")
 check(exported.items.size()==Characters.IDS.size()+preload("res://scripts/character_families.gd").individuals().size()+34 and exported.slots.size()==6,"Six supported cosmetic slots, every base/family body and thirty-four other options")
 var keys:Array[String]=[]
 for slot:Dictionary in Cosmetics.slots():
  check(equal(Cosmetics.items(str(slot.id)),Cosmetics.items(str(slot.category))),"Slot aliases resolve identically")
  for item:Dictionary in Cosmetics.items_for_slot(str(slot.id)):
   check(not str(item.inventory_id) in keys,"Inventory IDs globally unique")
   keys.append(str(item.inventory_id))
   check(item.compatible_body_styles==["*"] and item.compatible_archetypes==["*"],"All current silhouettes compatible without gameplay restrictions")
 for id:String in Characters.IDS:
  var normal:Dictionary=Cosmetics.default_appearance(id)
  check(bool(Cosmetics.validate_appearance(normal,Cosmetics.default_owned(),id).ok),"Defaults owned for each archetype")
  var body:Dictionary=Cosmetics.body_definition(id)
  check(FileAccess.file_exists(str(body.visual.atlas)),"Body atlas resolved centrally")
  for seed_value:int in range(20):
   var random:Dictionary=Cosmetics.randomize_owned(id,Cosmetics.default_owned(),1000+seed_value)
   check(bool(Cosmetics.validate_appearance(random,Cosmetics.default_owned(),id).ok),"Randomization uses only owned compatible cosmetics")
   check(random==Cosmetics.randomize_owned(id,Cosmetics.default_owned(),1000+seed_value),"Seeded cosmetic randomization reproducible")
 for id:String in ["original","jade","ocaso","luna","tinta"]:
  var colors:Dictionary=Cosmetics.palette_colors(id)
  check(colors.tint is Color and float(colors.strength)>=0.0 and float(colors.strength)<=0.3,"Curated color configuration bounded")
 var good:Dictionary=Cosmetics.default_appearance("balam")
 for bad:Dictionary in [{"body_style_id":"ascua"},{"aura_id":"corona"},{"palette_id":"bogus"},{"shader":"raw-client-shader"},{"palette_id":42}]:
  var candidate:Dictionary=good.duplicate(true)
  candidate.merge(bad,true)
  check(not bool(Cosmetics.validate_appearance(candidate,Cosmetics.default_owned(),"balam").ok),"Unknown, unowned, raw, or invalid cosmetics rejected")
 check(Cosmetics.normalize_appearance({"palette_id":"bad"},"tepa")==Cosmetics.default_appearance("tepa"),"Renderer safely falls back for unknown IDs")
 var detached:Dictionary=Cosmetics.definition("palette","jade")
 detached.colors.primary="invalid"
 check(Cosmetics.definition("palette_id","jade").colors.primary!="invalid","Catalog consumers get deep copies")
 for preset:Dictionary in Cosmetics.presets():
  var candidate:Dictionary=Cosmetics.default_appearance("nima")
  candidate.merge(preset.appearance,true)
  check(bool(Cosmetics.validate_appearance(candidate,keys,"nima").ok),"Presets composed only from real compatible definitions")
func _migration()->void:
 var league_roster:Dictionary={"sira":League._new_profile("sira","Liga Antigua!"),"nima":League._new_profile("nima"),"tepa":League._new_profile("tepa","X")}
 var story_roster:Dictionary={"sira":Story._new_profile("sira","Historia distinta"),"nima":Story._new_profile("nima","Luz del monte"),"tepa":Story._new_profile("tepa","Story name")}
 write(path("league-unchanged"),league_roster)
 write(path("story-unchanged"),story_roster)
 var before_league:String=FileAccess.get_sha256(path("league-unchanged"))
 var before_story:String=FileAccess.get_sha256(path("story-unchanged"))
 var before_profiles:Dictionary={"league":league_roster.duplicate(true),"story":story_roster.duplicate(true)}
 var store=Identity.new()
 store.load_save(path("migration"))
 store.migrate_legacy(league_roster,story_roster)
 check(not FileAccess.file_exists(path("migration")),"Migration does not write sidecar")
 check(store.entry("sira").identity.display_name=="Liga Antigua!","Conflicting custom names prefer Liga")
 check(store.entry("nima").identity.display_name=="Luz del monte","Custom Story name beats default Liga name")
 check(store.entry("tepa").identity.display_name=="X","Grandfathered one-character name preserved exactly")
 check(equal(before_profiles,{"league":league_roster,"story":story_roster}),"Migration never mutates supplied progression dictionaries")
 var initial:Dictionary=store.entry("sira")
 var league:Dictionary=store.decorate(league_roster.sira)
 var story:Dictionary=store.decorate(story_roster.sira)
 check(league.fighter_id==story.fighter_id and league.identity==story.identity and league.appearance==story.appearance,"Same identity and appearance across both modes")
 check(store.save(),"Explicit save persists stable migrated IDs even grandfathered names")
 var original_bytes:String=FileAccess.get_file_as_string(path("migration"))
 var restored=Identity.new()
 restored.load_save(path("migration"))
 restored.migrate_legacy(league_roster,story_roster)
 check(equal(restored.entry("sira"),initial),"ID, creation date, legacy name survive reload")
 check(FileAccess.get_file_as_string(path("migration"))==original_bytes,"Valid load and repeat migration do not write")
 var cosmetic_only:Dictionary=restored.entry("sira").appearance
 cosmetic_only.palette_id="jade"
 check(bool(restored.update_fighter("sira","Liga Antigua!",cosmetic_only).ok),"Grandfathered name may retain appearance changes")
 check(not bool(restored.update_fighter("nima","New!",Cosmetics.default_appearance("nima")).ok),"New invalid names cannot use grandfathering")
 check(bool(restored.update_fighter("sira","Luz Nueva",cosmetic_only).ok),"Free rename with validation")
 check(restored.entry("sira").fighter_id==initial.fighter_id and restored.entry("sira").identity.created_at==initial.identity.created_at,"Rename never changes internal identity or creation time")
 check(bool(restored.update_fighter("nima","Luz Nueva",Cosmetics.default_appearance("nima")).ok),"Names intentionally need not be unique")
 check(not bool(restored.update_fighter("sira","Liga Antigua!",cosmetic_only).ok),"Legacy exception ends after a valid rename")
 check(FileAccess.get_sha256(path("league-unchanged"))==before_league and FileAccess.get_sha256(path("story-unchanged"))==before_story,"Both gameplay fixture files remain byte-identical")
 check(restored.entry("unknown").is_empty(),"Unknown archetype rejected")
 var copy:Dictionary=restored.entry("sira")
 copy.identity.display_name="MUTATION"
 copy.appearance.body_style_id="mugo"
 check(restored.entry("sira").identity.display_name=="Luz Nueva" and restored.entry("sira").appearance.body_style_id=="sira","Entry returns deep copy")
func _transactions()->void:
 var store=FaultStore.new()
 store.load_save(path("atomic"))
 check(bool(store.update_fighter("balam","Balam Propio",Cosmetics.default_appearance("balam")).ok),"Initial account commit")
 var before:Dictionary=store.data.duplicate(true)
 var bytes:String=FileAccess.get_file_as_string(path("atomic"))
 for fault:String in ["write","copy","rename"]:
  store.fail=fault
  check(not bool(store.update_fighter("balam","Cambio Fallido",{"body_style_id":"mugo","palette_id":"jade"}).ok),"Injected I/O failure rejects transaction")
  check(store.data==before and FileAccess.get_file_as_string(path("atomic"))==bytes,"I/O failure rolls back memory and primary bytes")
  check(not DirAccess.dir_exists_absolute(path("atomic")+".lock"),"Failed transaction releases filesystem lock")
 store.fail=""
 check(bool(store.update_fighter("balam","Cambio Válido",{"body_style_id":"copal","palette_id":"ocaso"}).ok),"Atomic update after failures recovers")
 check(FileAccess.get_file_as_string(path("atomic")+".bak")==bytes,"Backup preserves previous committed bytes")
 var other=Identity.new()
 other.load_save(path("atomic"))
 store.update_fighter("balam","Otra Ventana",store.entry("balam").appearance)
 var committed:String=FileAccess.get_file_as_string(path("atomic"))
 check(not bool(other.update_fighter("balam","Perdido",Cosmetics.default_appearance("balam")).ok) and other.save_blocked,"Stale writer cannot overwrite external valid changes")
 check(FileAccess.get_file_as_string(path("atomic"))==committed,"Stale writer leaves current file intact")
 var lock_store=Identity.new()
 lock_store.load_save(path("locked"))
 DirAccess.make_dir_absolute(path("locked")+".lock")
 check(not bool(lock_store.update_fighter("sira","Estrella",{}).ok) and not FileAccess.file_exists(path("locked")),"Concurrent transaction lock protects new sidecar")
 DirAccess.remove_absolute(path("locked")+".lock")
func _corruption()->void:
 var store=Identity.new()
 store.load_save(path("valid"))
 store.update_fighter("tepa","Tepa Propia",Cosmetics.default_appearance("tepa"))
 var valid:Dictionary=store.data.duplicate(true)
 var bad_versions:Array[Variant]=[0,Identity.VERSION+1,-1,1.5,"1"]
 for version:Variant in bad_versions:
  var corrupted:Dictionary=valid.duplicate(true)
  corrupted.version=version
  _reject_payload(corrupted,valid,"Unknown or invalid schema version")
 for change:String in ["owned","raw","duplicate","date","source","fields","reserved","unclean","partial","inventory"]:
  var corrupted:Dictionary=valid.duplicate(true)
  match change:
   "owned": corrupted.fighters.tepa.appearance.aura_id="corona"
   "raw": corrupted.fighters.tepa.appearance.shader={"code":"arbitrary"}
   "duplicate":
    corrupted.fighters.sira=corrupted.fighters.tepa.duplicate(true)
    corrupted.fighters.sira.archetype_id="sira"
   "date": corrupted.fighters.tepa.identity.created_at=-1
   "source": corrupted.inventory["palette:original"].source="purchased"
   "fields": corrupted.fighters.tepa.identity.extra="surprise"
   "reserved":
    corrupted.fighters.tepa.identity.display_name="Admin"
    corrupted.fighters.tepa.identity.normalized_name="admin"
   "unclean":
    corrupted.fighters.tepa.identity.display_name="  Tepa   Propia  "
    corrupted.fighters.tepa.identity.normalized_name="tepa propia"
   "partial": corrupted.fighters.tepa.appearance.erase("palette_id")
   "inventory": corrupted.inventory.erase("body_style:balam")
  _reject_payload(corrupted,valid,"Malformed cosmetic state: "+change)
 _reject_payload("{broken-json",valid,"Corrupt JSON preserved")
 var large:String="a".repeat(Identity.MAX_BYTES+1)
 _reject_payload(large,valid,"Oversized sidecar rejected")
func _reject_payload(payload:Variant,backup:Dictionary,label:String)->void:
 sequence+=1
 var file:String=path("invalid_%d" % sequence)
 write(file,payload)
 write(file+".bak",backup)
 var bytes:String=FileAccess.get_file_as_string(file)
 var backup_bytes:String=FileAccess.get_file_as_string(file+".bak")
 var store=Identity.new()
 store.load_save(file)
 check(store.save_blocked and not store.last_save_ok,label)
 check(not store.save() and not bool(store.update_fighter("tepa","Nuevo",{}).ok),"Invalid sidecar remains fail-closed even with backup")
 check(FileAccess.get_file_as_string(file)==bytes and FileAccess.get_file_as_string(file+".bak")==backup_bytes,"Original and valid backup preserved without automatic recovery writes")
func _reward_summary(p:RefCounted)->Dictionary:
 sequence+=1
 return {"battle_id":"identity_reward_%d" % sequence,"winner":"player","reason":"normal","duration":30.0,"player":p.active_combatant(),"rival":p.make_rival(),"metrics":{}}
func _rewards()->void:
 var store=FaultStore.new()
 store.load_save(path("rewards"))
 store.entry("nima")
 check(store.grant_from_progress({"nima":{"character_id":"nima","level":50,"wins":100}},{}).is_empty(),"Incomplete forged progress grants nothing")
 var fake:Dictionary=League._new_profile("nima")
 fake.level=50
 fake.total_xp=999999
 check(store.grant_from_progress({"nima":fake},{}).is_empty(),"Impossible level claim without earned XP or matches grants nothing")
 var league=MemoryLeague.new()
 league.select_character("balam")
 for i:int in range(10): league.reward(true)
 var initial:Dictionary=store.data.duplicate(true)
 store.fail="write"
 check(store.grant_from_progress(league.roster,{}).is_empty() and not store.last_save_ok,"Failed reward persistence returns no granted IDs")
 check(store.data==initial,"Failed reward preserves inventory and stable IDs")
 store.fail=""
 var league_colors:Array[String]=store.grant_from_progress(league.roster,{})
 check(league_colors.has("palette:tinta") and league_colors.has("palette:cacao") and league_colors.has("palette:amatista"),"Ten legitimate Liga wins unlock Tinta and the earlier Cacao/Amatista rewards")
 var bytes:String=FileAccess.get_file_as_string(path("rewards"))
 check(store.grant_from_progress(league.roster,{}).is_empty() and store.last_save_ok,"Duplicate rewards are idempotent")
 check(FileAccess.get_file_as_string(path("rewards"))==bytes,"No-op reward does not write")
 for i:int in range(15): league.reward(true)
 check(store.grant_from_progress(league.roster,{}).has("trail:estela"),"Twenty-five legitimate wins unlock account estela")
 while int(league.data.level)<10: league.reward(true)
 check(store.grant_from_progress(league.roster,{}).has("palette:luna"),"Level ten unlocks Luna")
 var story=MemoryStory.new()
 story.select_character("tepa")
 var expected:Dictionary={4:"palette:grana",8:"aura:farol",12:"palette:cobre",20:"trail:brasa",21:"body_style:taro_roque",22:"body_style:duna_cora",23:"body_style:bruma_ambar",50:"aura:luciernagas",61:"body_style:taro_sabio",62:"body_style:duna_pedernal",63:"body_style:bruma_nieve",100:"aura:corona"}
 for level:int in range(1,101):
  if story.is_complete(): story.start_next_chapter()
  check(bool(story.reward_match(_reward_summary(story)).accepted),"Legitimate Story fixture result accepted")
  if expected.has(level):
   var grants:Array[String]=store.grant_from_progress(league.roster,story.roster)
   check(expected[level] in grants,"Exact Story milestone grants the cosmetic")
   check(store.grant_from_progress(league.roster,story.roster).is_empty(),"Chapter milestone cannot be claimed twice")
  if expected.has(level+1):
   store.grant_from_progress(league.roster,story.roster)
   check(not expected[level+1] in store.owned_ids(),"Milestone cosmetic not granted one encounter early")
 check(store.owned_ids().size()==Cosmetics.export_catalog().items.size(),"All declared milestones grant every declared cosmetic ID")
 var new_fighter:Dictionary=store.entry("xuna")
 new_fighter.appearance.aura_id="corona"
 new_fighter.appearance.palette_id="luna"
 check(bool(store.update_fighter("xuna","Otra Identidad",new_fighter.appearance).ok),"Account rewards may be equipped by another archetype")
 var restored=Identity.new()
 restored.load_save(path("rewards"))
 check(not restored.save_blocked and equal(restored.data,store.data),"Reward provenance and equipped ownership survive reload")
 var invalid_story:Dictionary=story.data.duplicate(true)
 invalid_story.current_stage=999
 var empty=Identity.new()
 empty.load_save(path("fake-story"))
 check(empty.grant_from_progress({}, {"tepa":invalid_story}).is_empty(),"Invalid Story route cannot grant crown")
 check(not FileAccess.file_exists(path("fake-story")),"Rejected or empty progress creates no sidecar")
func _snapshots()->void:
 var store=Identity.new()
 store.load_save(path("snapshot"))
 var profile:Dictionary=League._new_profile("sira")
 var mechanics:Dictionary=profile.duplicate(true)
 var appearance:Dictionary=Cosmetics.default_appearance("sira")
 appearance.body_style_id="mugo"
 appearance.palette_id="jade"
 appearance.victory_pose_id="saludo"
 check(bool(store.update_fighter("sira","Cometa Propio",appearance).ok),"Gameplay Sira can use Mugo silhouette")
 var frozen:Dictionary=store.decorate(profile)
 check(frozen.character_id=="sira" and equal(frozen.stats,mechanics.stats) and frozen.appearance.body_style_id=="mugo","Cosmetic body never substitutes gameplay archetype or stats")
 check(profile==mechanics,"Decoration never mutates gameplay input")
 var old:Dictionary=frozen.duplicate(true)
 store.update_fighter("sira","Nombre Nuevo",Cosmetics.default_appearance("sira"))
 check(frozen==old and store.decorate(frozen)==old,"Old display name and appearance remain immutable snapshots")
 check(store.decorate(profile).fighter_id==frozen.fighter_id,"Rename preserves battle identity reference")
 var rival:Dictionary={"character_id":"mugo","level":1}
 for seed_value:int in range(15):
  var plain=Battle.new()
  var cosmetic=Battle.new()
  plain.start(mechanics,rival,51400+seed_value)
  cosmetic.start(frozen,rival,51400+seed_value)
  plain.advance(60.0)
  cosmetic.advance(60.0)
  var a:Dictionary=plain.summary()
  var b:Dictionary=cosmetic.summary()
  check(a.winner==b.winner and a.duration==b.duration and a.metrics==b.metrics,"Cosmetics never change seeded damage, winner, timing, moves or Signature")
