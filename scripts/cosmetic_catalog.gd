class_name CosmeticCatalog
extends RefCounted
## Cosmetic IDs only. Combat archetypes and power never depend on this catalog.
const Characters = preload("res://scripts/character_catalog.gd")
const Families = preload("res://scripts/character_families.gd")
const VERSION: int = 5
const NAME_POLICY: Dictionary = {"minimum_length":2,"maximum_length":24,"length_unit":"unicode_code_points","allowed_pattern":"^[\\p{L}\\p{N} '\\-]+$","required_pattern":"[\\p{L}\\p{N}]","collapse_spaces":true,"globally_unique":false,"reserved":["admin","sistema","moderador","administrador","system","moderator"]}
const SLOTS: Array[Dictionary] = [
	{"id":"body_style_id","category":"body_style","name":"Cuerpo","description":"Silueta visual; conserva el arquetipo de combate."},
	{"id":"palette_id","category":"palette","name":"Paleta","description":"Tinte sutil de la ilustración completa y colores de efectos."},
	{"id":"aura_id","category":"aura","name":"Aura","description":"Efecto ambiental alrededor del personaje."},
	{"id":"trail_id","category":"trail","name":"Estela","description":"Efecto breve durante los desplazamientos."},
	{"id":"victory_pose_id","category":"victory_pose","name":"Victoria","description":"Presentación de la pose de victoria existente."},
	{"id":"intro_animation_id","category":"intro_animation","name":"Entrada","description":"Presentación al comenzar el combate."},
]
const DEFAULTS: Dictionary = {"palette_id":"original","aura_id":"none","trail_id":"none","victory_pose_id":"classic","intro_animation_id":"classic"}
const BODY_ASSETS: Dictionary = {"nima":"lince-v2","luma":"ajolote-v2","mugo":"golem-v2","sira":"sira-v3","iria":"iria-v3","duna":"duna-v3","kiro":"kiro-v3","neris":"neris-v3","taro":"taro-v3","balam":"balam-v1","tepa":"tepa-v1","xuna":"xuna-v1","copal":"copal-v1","onix":"onix-v1","bruma":"bruma-v1"}
const OPTIONS: Dictionary = {
	"palette_id":[
		{"id":"original","name":"Original","description":"Conserva todos los colores de la ilustración.","tint":"ffffff","strength":0.0,"colors":{"primary":"d9934f","secondary":"2b3555","accent":"efcf80"}},
		{"id":"jade","name":"Jade","description":"Matiz verde suave y efectos de jade.","tint":"8bdbbb","strength":0.18,"colors":{"primary":"5ca98c","secondary":"274d56","accent":"d3e8a3"}},
		{"id":"ocaso","name":"Ocaso","description":"Luz cálida con acentos coral.","tint":"ffb999","strength":0.18,"colors":{"primary":"d78057","secondary":"5b3d62","accent":"f4ca77"}},
		{"id":"luna","name":"Luna","description":"Luz azul suave y reflejos claros.","tint":"a9bfff","strength":0.22,"colors":{"primary":"8dace7","secondary":"373f6b","accent":"dde9ff"},"unlock":{"kind":"level","threshold":10}},
		{"id":"tinta","name":"Tinta","description":"Matiz violeta oscuro con acentos claros.","tint":"9992bf","strength":0.26,"colors":{"primary":"82799e","secondary":"302f45","accent":"d4badc"},"unlock":{"kind":"league_wins","threshold":10}},
		{"id":"cempasuchil","name":"Cempasúchil","description":"Ámbar cálido, sombras terracota y luz dorada.","tint":"ffd28a","strength":0.30,"colors":{"primary":"eaaa40","secondary":"794631","accent":"ffe3a0"},"unlock":{"kind":"level","threshold":2}},
		{"id":"turquesa","name":"Turquesa","description":"Azules minerales con reflejos de agua clara.","tint":"83dce2","strength":0.30,"colors":{"primary":"37adb8","secondary":"254e68","accent":"b5f0db"},"unlock":{"kind":"level","threshold":3}},
		{"id":"grana","name":"Grana","description":"Rojo cochinilla con sombras ciruela y acentos rosados.","tint":"e594ab","strength":0.32,"colors":{"primary":"bb4961","secondary":"4e2948","accent":"f2b4ad"},"unlock":{"kind":"story_cleared","threshold":4}},
		{"id":"cacao","name":"Cacao","description":"Tonos de cacao, cuero oscuro y crema cálida.","tint":"d4b291","strength":0.30,"colors":{"primary":"986c4d","secondary":"42323a","accent":"e8c8a1"},"unlock":{"kind":"league_wins","threshold":3}},
		{"id":"marfil","name":"Marfil","description":"Luz de marfil con sombras azul gris y reflejos suaves.","tint":"e9e2cf","strength":0.34,"colors":{"primary":"d9d3bd","secondary":"626e80","accent":"fff1cb"},"unlock":{"kind":"level","threshold":6}},
		{"id":"cobre","name":"Cobre","description":"Cobre rojizo, azul petróleo y destellos de bronce.","tint":"e8b08c","strength":0.32,"colors":{"primary":"bd754f","secondary":"244b50","accent":"efc57f"},"unlock":{"kind":"story_cleared","threshold":12}},
		{"id":"amatista","name":"Amatista","description":"Violetas intensos con sombras índigo y reflejos lavanda.","tint":"c0a0ec","strength":0.32,"colors":{"primary":"9871bc","secondary":"3b365d","accent":"dfc7f1"},"unlock":{"kind":"league_wins","threshold":8}},
	],
	"aura_id":[
		{"id":"none","name":"Sin aura","description":"Silueta limpia sin partículas.","color":"ffffff","particles":0},
		{"id":"farol","name":"Farol","description":"Brasas suaves que ascienden junto al cuerpo.","color":"efbd63","particles":18,"shape":"spark","unlock":{"kind":"story_cleared","threshold":8}},
		{"id":"luciernagas","name":"Luciérnagas","description":"Pequeñas luces verdes alrededor del cuerpo.","color":"b6df8b","particles":16,"shape":"mote","unlock":{"kind":"story_cleared","threshold":50}},
		{"id":"corona","name":"Corona de faroles","description":"Motitas doradas acompañan al personaje y celebran la ruta completa.","color":"ffe7a1","particles":28,"shape":"crystal","unlock":{"kind":"story_cleared","threshold":100}},
		{"id":"petalos","name":"Pétalos de cempasúchil","description":"Pétalos dorados que caen y giran a ambos lados del cuerpo.","color":"ffc65b","particles":18,"shape":"petal","unlock":{"kind":"level","threshold":3}},
		{"id":"llovizna","name":"Llovizna lunar","description":"Trazos azules de lluvia con reflejos claros.","color":"9cdbff","particles":24,"shape":"rain","unlock":{"kind":"level","threshold":6}},
		{"id":"cenizas","name":"Ceniza viva","description":"Copos cálidos que flotan junto a la silueta.","color":"e7b994","particles":20,"shape":"ash","unlock":{"kind":"story_cleared","threshold":12}},
		{"id":"cristales","name":"Cristales de amatista","description":"Fragmentos violetas con pequeños reflejos luminosos.","color":"d4aaff","particles":14,"shape":"crystal","unlock":{"kind":"league_wins","threshold":6}},
	],
	"trail_id":[
		{"id":"none","name":"Sin estela","description":"Desplazamiento sin partículas.","color":"ffffff"},
		{"id":"brasa","name":"Brasa","description":"Puntos cálidos breves tras cada avance.","color":"ffad64","particles":20,"shape":"spark","unlock":{"kind":"story_cleared","threshold":20}},
		{"id":"estela","name":"Estela de jade","description":"Una estela verde breve acompaña los saltos.","color":"91f4cb","particles":18,"shape":"crystal","unlock":{"kind":"league_wins","threshold":25}},
		{"id":"cometa","name":"Cometa azul","description":"Un rastro de chispas azules que permanece tras el golpe.","color":"9fdfff","particles":24,"shape":"rain","unlock":{"kind":"story_cleared","threshold":30}},
		{"id":"hojas","name":"Hojas al viento","description":"Hojas verdes que se desprenden al avanzar.","color":"b9dc72","particles":16,"shape":"leaf","unlock":{"kind":"level","threshold":8}},
		{"id":"polvo","name":"Polvo de cobre","description":"Una nube breve de pigmento cálido acompaña el movimiento.","color":"e5b080","particles":22,"shape":"dust","unlock":{"kind":"league_wins","threshold":5}},
	],
	"victory_pose_id":[
		{"id":"classic","name":"Clásica","description":"Celebra con su pose habitual y un pequeño salto."},
		{"id":"saludo","name":"Saludo","description":"Hace una reverencia y luego muestra su pose de victoria."},
		{"id":"serena","name":"Serena","description":"Mantiene la pose de victoria con calma, sin saltos.","unlock":{"kind":"league_wins","threshold":4}},
		{"id":"festival","name":"Festival","description":"Celebra entre pétalos dorados que se desvanecen.","unlock":{"kind":"story_cleared","threshold":16}},
	],
	"intro_animation_id":[
		{"id":"classic","name":"Clásica","description":"Se presenta en guardia, sin efectos añadidos."},
		{"id":"pulso","name":"Pulso","description":"Una ráfaga de chispas anuncia su llegada."},
		{"id":"reverencia","name":"Reverencia","description":"Se inclina brevemente y recupera la guardia.","unlock":{"kind":"level","threshold":4}},
		{"id":"bruma","name":"Bruma","description":"Una nube suave aparece a sus pies y se disipa.","unlock":{"kind":"story_cleared","threshold":6}},
	],
}
const PRESETS: Array[Dictionary] = [
	{"id":"original","name":"Original","appearance":{"palette_id":"original","aura_id":"none","trail_id":"none","victory_pose_id":"classic","intro_animation_id":"classic"}},
	{"id":"jade","name":"Camino de jade","appearance":{"palette_id":"jade","aura_id":"none","trail_id":"none","victory_pose_id":"saludo","intro_animation_id":"pulso"}},
	{"id":"ocaso","name":"Hora del ocaso","appearance":{"palette_id":"ocaso","aura_id":"none","trail_id":"none","victory_pose_id":"classic","intro_animation_id":"pulso"}},
	{"id":"guardian","name":"Guardián lunar","appearance":{"palette_id":"luna","aura_id":"farol","trail_id":"none","victory_pose_id":"saludo","intro_animation_id":"pulso"}},
]

static func _slot(value: String) -> String:
	return value if value.ends_with("_id") else value + "_id"

static func inventory_key(slot: String, id: String) -> String:
	return _slot(slot).trim_suffix("_id") + ":" + id

static func slots() -> Array[Dictionary]:
	return SLOTS.duplicate(true)

static func items(slot: String) -> Array[Dictionary]:
	var field: String = _slot(slot)
	var result: Array[Dictionary] = []
	if field == "body_style_id":
		for id: String in Characters.IDS:
			var character: Dictionary = Characters.definition(id)
			result.append(_complete({"id":id,"name":character.name,"description":"Apariencia de " + str(character.name) + "; conserva tus estadísticas y técnicas.","asset":"res://assets/sprites/"+str(BODY_ASSETS[id])+".png","metadata":"res://assets/sprites/"+str(BODY_ASSETS[id])+".json","palette_support":["tint"]},field))
		for individual: Dictionary in Families.individuals().values():
			if not bool(individual.get("player_available", false)): continue
			result.append(_complete({"id":individual.id,"name":individual.name,"description":individual.display_description,"species_id":individual.species_id,"category":"individual_appearance","asset":individual.asset,"metadata":str(individual.asset).get_basename()+".json","palette_support":["tint"],"unlock":individual.unlock,"npc_available":true,"player_available":true,"rarity":"veteran" if int(individual.visual_rank)>2 else "experienced"},field))
	elif OPTIONS.has(field):
		for option: Dictionary in OPTIONS[field]: result.append(_complete(option,field))
	return result

static func items_for_slot(slot: String) -> Array[Dictionary]:
	return items(slot)

static func _complete(raw: Dictionary, slot: String) -> Dictionary:
	var item: Dictionary = raw.duplicate(true)
	item["slot"] = slot
	item["inventory_id"] = inventory_key(slot,str(item.id))
	item["compatible_body_styles"] = item.get("compatible_body_styles",["*"])
	item["compatible_archetypes"] = item.get("compatible_archetypes",["*"])
	item["unlock"] = item.get("unlock",{"kind":"default","threshold":0})
	item["default"] = str(item.unlock.kind) == "default"
	item["requirement"] = requirement_text(item.unlock)
	return item

static func definition(slot: String, id: String) -> Dictionary:
	for item: Dictionary in items(slot):
		if str(item.id) == id: return item
	return {}

static func definition_for_inventory(id: String) -> Dictionary:
	var parts: PackedStringArray = id.split(":")
	return definition(parts[0],parts[1]) if parts.size()==2 else {}

static func default_owned() -> Array[String]:
	var result: Array[String] = []
	for slot: Dictionary in SLOTS:
		for item: Dictionary in items(str(slot.id)):
			if bool(item.default): result.append(str(item.inventory_id))
	return result

static func default_appearance(archetype_id: String = "nima") -> Dictionary:
	var result: Dictionary = DEFAULTS.duplicate(true)
	result["body_style_id"] = archetype_id if archetype_id in Characters.IDS else "nima"
	return result

static func normalize_appearance(raw: Dictionary, fallback_body: String = "nima") -> Dictionary:
	var result: Dictionary = default_appearance(fallback_body)
	for slot: Dictionary in SLOTS:
		var field: String = str(slot.id)
		if raw.get(field) is String and not definition(field,str(raw[field])).is_empty(): result[field] = raw[field]
	return result

static func validate_appearance(raw: Dictionary, owned: Array[String], archetype_id: String = "nima") -> Dictionary:
	if not archetype_id in Characters.IDS: return {"ok":false,"error":"Arquetipo desconocido."}
	var appearance: Dictionary = default_appearance(archetype_id)
	for field: Variant in raw:
		if not field is String or not appearance.has(field) or not raw[field] is String:
			return {"ok":false,"error":"La apariencia contiene una categoría o un valor inválido."}
		appearance[field] = raw[field]
	var body: String = str(appearance.body_style_id)
	for field: String in appearance:
		var item: Dictionary = definition(field,str(appearance[field]))
		if item.is_empty(): return {"ok":false,"error":"Cosmético desconocido: " + str(appearance[field])}
		if not str(item.inventory_id) in owned: return {"ok":false,"error":"Todavía no tienes " + str(item.name) + "."}
		if not ("*" in item.compatible_body_styles or body in item.compatible_body_styles) or not ("*" in item.compatible_archetypes or archetype_id in item.compatible_archetypes):
			return {"ok":false,"error":"Esta combinación de apariencia no es compatible."}
	return {"ok":true,"error":"","appearance":appearance}

static func randomize_owned(archetype_id: String, owned: Array[String], seed_value: int = 0) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	if seed_value == 0: rng.randomize()
	else: rng.seed = seed_value
	var result: Dictionary = default_appearance(archetype_id)
	for slot: Dictionary in SLOTS:
		var allowed: Array[String] = []
		for item: Dictionary in items(str(slot.id)):
			var candidate: Dictionary = result.duplicate(true)
			candidate[str(slot.id)] = str(item.id)
			if str(item.inventory_id) in owned and bool(validate_appearance(candidate,owned,archetype_id).ok): allowed.append(str(item.id))
		if not allowed.is_empty(): result[str(slot.id)] = allowed[rng.randi_range(0,allowed.size()-1)]
	return result if bool(validate_appearance(result,owned,archetype_id).ok) else {}

static func presets() -> Array[Dictionary]:
	return PRESETS.duplicate(true)

static func body_definition(id: String) -> Dictionary:
	var base: String = Families.base_body(id)
	var result: Dictionary = Characters.definition(base if base in Characters.IDS else "nima")
	var individual: Dictionary = Families.individual(id)
	result.visual["atlas"] = str(individual.asset) if not individual.is_empty() else "res://assets/sprites/" + str(BODY_ASSETS[str(result.id)]) + ".png"
	if not individual.is_empty():
		result["individual_id"] = id
		result["species_id"] = individual.species_id
		result["individual_profile"] = individual.duplicate(true)
	return result


static func palette_colors(id: String) -> Dictionary:
	var palette: Dictionary = definition("palette",id)
	if palette.is_empty(): palette = definition("palette","original")
	return {"tint":Color(str(palette.tint)),"strength":float(palette.strength),"primary":Color(str(palette.colors.primary)),"secondary":Color(str(palette.colors.secondary)),"accent":Color(str(palette.colors.accent))}

static func resolve(raw: Dictionary) -> Dictionary:
	var appearance: Dictionary = normalize_appearance(raw)
	var result: Dictionary = {"appearance":appearance,"body_style":body_definition(str(appearance.body_style_id))}
	for slot: Dictionary in SLOTS:
		if str(slot.id) != "body_style_id": result[str(slot.category)] = definition(str(slot.id),str(appearance[str(slot.id)]))
	return result

static func requirement_text(requirement: Dictionary) -> String:
	match str(requirement.get("kind","default")):
		"level": return "Alcanza el nivel %d con un luchador." % int(requirement.threshold)
		"story_cleared": return "Supera el encuentro %d de Historia." % int(requirement.threshold)
		"league_wins": return "Gana %d combates de Liga con un luchador." % int(requirement.threshold)
	return "Disponible desde el principio."

static func export_catalog() -> Dictionary:
	var all_items: Array[Dictionary] = []
	for slot: Dictionary in SLOTS: all_items.append_array(items(str(slot.id)))
	return {"version":VERSION,"archetype_ids":Characters.IDS.duplicate(),"name_policy":NAME_POLICY.duplicate(true),"slots":slots(),"items":all_items,"starter_owned":default_owned(),"presets":presets()}
