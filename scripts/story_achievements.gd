extends RefCounted
## Retroactive, read-only milestones from persisted campaign evidence.
## No rewards, saves, counters, or ownership are written by this catalogue.
const Story = preload("res://scripts/story_catalog.gd")

static func snapshot(profile: Dictionary, summaries: Dictionary = {}) -> Dictionary:
	var current := int(profile.get("chapter",1))
	var cleared := 0 if profile.is_empty() else int(Story.chapter(current).start_level)-1+int(profile.get("current_stage",0))
	var wins := int(profile.get("wins",0))
	var records: Dictionary = summaries.duplicate(true)
	if profile.get("completion_snapshot",{}).has("summary"):
		records[str(current)] = profile.completion_snapshot.summary.duplicate(true)
	for key: String in profile.get("chapter_records",{}):
		records[key] = profile.chapter_records[key].get("summary",{}).duplicate(true)
	for key: String in records:
		if int(key)!=current: wins += int(records[key].get("wins",0))
	var entries: Array[Dictionary] = []
	var chapters := 0
	for chapter: Dictionary in Story.chapters():
		var number := int(chapter.number)
		var done := bool(records.get(str(number),{}).get("completed",false)) or (not profile.is_empty() and number==current and bool(profile.get("completed",false)))
		if done: chapters += 1
		var target := int(chapter.end_level)-int(chapter.start_level)+1
		var progress := target if done else clampi(cleared-int(chapter.start_level)+1,0,target)
		entries.append({"id":"chapter_%d" % number,"title":str(chapter.title),"description":"Completa el capítulo %d." % number,"current":progress,"target":target,"unit":"encuentros","done":done,"chapter":number,"reward":"Insignia · "+str(chapter.badge)})
	for milestone: Array in [["first_win","Primera victoria",1,"wins"],["ten_wins","Paso firme",10,"wins"],["fifty_wins","Veterano de la ruta",50,"wins"],["level_5","Aprendiz",5,"level"],["level_20","Maestría",20,"level"],["level_50","Todo tu potencial",50,"level"]]:
		var is_level: bool = str(milestone[3])=="level"
		var value := int(profile.get("level",0)) if is_level else wins
		var target := int(milestone[2])
		entries.append({"id":str(milestone[0]),"title":str(milestone[1]),"description":"Gana tu primer combate de la ruta." if not is_level and target==1 else (("Alcanza el nivel %d." if is_level else "Gana %d combates de la ruta.") % target),"current":mini(value,target),"target":target,"unit":"niveles" if is_level else "victorias","done":value>=target,"chapter":0,"reward":"Reconocimiento"})
	var earned := 0
	for item: Dictionary in entries:
		if item.done: earned += 1
	return {"entries":entries,"earned":earned,"total":entries.size(),"cleared":cleared,"wins":wins,"chapters":chapters,"records":records}
