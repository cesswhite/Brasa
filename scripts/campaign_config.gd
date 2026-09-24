class_name CampaignConfig
extends RefCounted
## Public campaign budgets and milestones. These create ordinary combat stats;
## the engine never receives a secret story difficulty multiplier.
const TOTAL_ENCOUNTERS: int = 100
const MOVE_TOKEN_LEVELS: Array[int] = [5, 10, 20, 30, 40, 50, 60, 70, 80, 90]
const PERK_LEVELS: Array[int] = [10, 30, 50]
const MAX_PERKS: int = 3
const MAX_MOVE_TIER: int = 2
const REPLAY_XP: int = 0
const LOSS_XP_FLOOR: float = 0.35
const LOSS_XP_DECAY: float = 0.15
const MAX_STAGE_ATTEMPTS: int = 24
const CHAPTERS: Array[Dictionary] = [
	{"number": 1, "title": "El camino de los faroles", "badge": "Guardián de los Faroles", "background": "res://assets/arena-faroles-v2.png", "start_level": 1, "end_level": 8, "theme": "Primeros pasos"},
	{"number": 2, "title": "El paso de la tormenta", "badge": "Caminante de la Tormenta", "background": "res://assets/arena-tormenta-v3.png", "start_level": 9, "end_level": 16, "theme": "Estilos de combate"},
	{"number": 3, "title": "El juramento del puente", "badge": "Discípulo del Puente", "background": "res://assets/arena-faroles-v2.png", "start_level": 17, "end_level": 20, "theme": "Técnicas y respuestas"},
	{"number": 4, "title": "El jardín de los ecos", "badge": "Guardián del Jardín", "background": "res://assets/arena-faroles-v2.png", "start_level": 21, "end_level": 30, "theme": "Estados y resistencia"},
	{"number": 5, "title": "Las sendas entrelazadas", "badge": "Tejedor de Sendas", "background": "res://assets/arena-tormenta-v3.png", "start_level": 31, "end_level": 40, "theme": "Combinaciones de atributos"},
	{"number": 6, "title": "El horno del solsticio", "badge": "Corazón del Solsticio", "background": "res://assets/arena-faroles-v2.png", "start_level": 41, "end_level": 50, "theme": "La primera gran prueba"},
	{"number": 7, "title": "Los rostros del regreso", "badge": "Centinela del Regreso", "background": "res://assets/arena-tormenta-v3.png", "start_level": 51, "end_level": 60, "theme": "Identidades, otras estrategias"},
	{"number": 8, "title": "La escuela del relámpago", "badge": "Maestro del Relámpago", "background": "res://assets/arena-tormenta-v3.png", "start_level": 61, "end_level": 70, "theme": "Especialistas y sus debilidades"},
	{"number": 9, "title": "El círculo de los maestros", "badge": "Voz de los Maestros", "background": "res://assets/arena-faroles-v2.png", "start_level": 71, "end_level": 80, "theme": "Técnicas perfeccionadas"},
	{"number": 10, "title": "La víspera de las estrellas", "badge": "Filo de las Estrellas", "background": "res://assets/arena-tormenta-v3.png", "start_level": 81, "end_level": 90, "theme": "Sinergias de fin de viaje"},
	{"number": 11, "title": "El último eclipse", "badge": "Leyenda de los Cien Faroles", "background": "res://assets/arena-tormenta-v3.png", "start_level": 91, "end_level": 100, "theme": "La prueba final"},
]
# Allocation weights are intentionally different, including a visible weakness.
# The same total budget can produce a fast evasive duelist or a slow shield wall.
const VARIANTS: Dictionary = {
	"balanced": {"limits": {"speed": 18, "crit_chance": 3}, "name": "Guardia adaptable", "weights": {"max_hp": 5, "attack": 4, "defense": 3, "speed": 3, "accuracy": 2, "evasion": 2, "crit_chance": 1, "resistance": 1}, "pool": ["luma", "taro", "duna"], "strength": "Aguante y presión repartidos; técnicas de respuesta.", "weakness": "No maximiza velocidad ni crítico.", "types": ["quick", "counter", "guard"]},
	"tempo": {"limits": {"defense": 8, "resistance": 4, "max_hp": 28, "crit_chance": 5}, "name": "Paso fugaz", "weights": {"max_hp": 4, "attack": 4, "defense": 1, "speed": 6, "accuracy": 2, "evasion": 3, "crit_chance": 2, "resistance": 1}, "pool": ["nima", "neris", "luma"], "strength": "Muchas acciones, evasión y ataques de desplazamiento.", "weakness": "Armadura ligera; los golpes certeros importan.", "types": ["dash", "quick", "jump"]},
	"charged": {"limits": {"speed": 14, "evasion": 3, "resistance": 3, "accuracy": 6, "defense": 13}, "name": "Puño del horno", "weights": {"max_hp": 5, "attack": 7, "defense": 2, "speed": 2, "accuracy": 2, "evasion": 1, "crit_chance": 2, "resistance": 1}, "pool": ["kiro", "mugo", "sira"], "strength": "Ataque alto y técnicas pesadas con anticipación.", "weakness": "Recuperaciones largas y precisión contenida.", "types": ["charge", "heavy"]},
	"bulwark": {"limits": {"speed": 10, "evasion": 3, "crit_chance": 3, "attack": 26}, "name": "Baluarte paciente", "weights": {"max_hp": 7, "attack": 4, "defense": 6, "speed": 1, "accuracy": 2, "evasion": 1, "crit_chance": 1, "resistance": 2}, "pool": ["duna", "mugo", "taro"], "strength": "Mucha vida y defensa; guardias y contraataques.", "weakness": "Pocas acciones y poca evasión; el desgaste atraviesa la armadura.", "types": ["guard", "counter", "heavy"]},
	"venom": {"limits": {"crit_chance": 3, "evasion": 5, "attack": 26, "speed": 20, "defense": 20}, "name": "Jardín persistente", "weights": {"max_hp": 5, "attack": 4, "defense": 3, "speed": 3, "accuracy": 3, "evasion": 1, "crit_chance": 1, "resistance": 4}, "pool": ["iria", "neris", "luma"], "strength": "Resistencia y puntería para sostener efectos negativos.", "weakness": "Críticos escasos y daño explosivo contenido.", "types": ["technique", "quick", "guard"]},
	"critical": {"limits": {"max_hp": 26, "defense": 7, "resistance": 2, "evasion": 8}, "name": "Filo certero", "weights": {"max_hp": 4, "attack": 5, "defense": 1, "speed": 3, "accuracy": 4, "evasion": 2, "crit_chance": 4, "resistance": 1}, "pool": ["sira", "kiro", "nima"], "strength": "Puntería y críticos, con saltos y golpes de gran riesgo.", "weakness": "Vida, armadura y resistencia contenidas.", "types": ["jump", "heavy", "quick"]},
}
const CHAPTER_PATTERNS: Dictionary = {
	3: ["balanced", "tempo", "charged", "balanced"],
	4: ["venom", "tempo", "bulwark", "venom", "critical", "balanced", "venom", "charged", "bulwark", "venom"],
	5: ["tempo", "balanced", "critical", "bulwark", "charged", "venom", "tempo", "critical", "bulwark", "balanced"],
	6: ["charged", "venom", "tempo", "critical", "bulwark", "balanced", "charged", "tempo", "venom", "charged"],
	7: ["critical", "bulwark", "venom", "tempo", "balanced", "charged", "critical", "venom", "tempo", "bulwark"],
	8: ["tempo", "critical", "bulwark", "venom", "charged", "balanced", "tempo", "critical", "bulwark", "charged"],
	9: ["venom", "charged", "balanced", "critical", "tempo", "bulwark", "venom", "critical", "charged", "tempo"],
	10: ["bulwark", "tempo", "venom", "charged", "critical", "balanced", "bulwark", "tempo", "venom", "critical"],
	11: ["charged", "venom", "bulwark", "critical", "tempo", "balanced", "charged", "critical", "venom", "tempo"],
}
const BOSSES: Dictionary = {
	20: {"character_id": "taro", "name": "Taro · Juramento de jade", "variant": "balanced"},
	30: {"character_id": "iria", "name": "Iria · Jardín de ecos", "variant": "venom", "stats": {"attack": 57.0, "speed": 24.0}},
	40: {"character_id": "luma", "name": "Luma · Las nueve sendas", "variant": "balanced"},
	50: {"character_id": "mugo", "boss_id": "ascua", "name": "Ascua · Corazón del solsticio", "variant": "charged", "major": true, "strength": "Armadura de 120 y golpes fuertes; su núcleo anuncia dos fases de presión creciente.", "weakness": "Solo 5% de evasión; sus cargas tienen preparación y recuperación visibles.", "stats": {"max_hp": 1070.0, "attack": 76.0, "defense": 120.0, "speed": 23.0, "accuracy": 1.07, "evasion": 0.05, "crit_chance": 0.17, "resistance": 0.42}},
	60: {"character_id": "duna", "name": "Duna · Fortaleza del regreso", "variant": "bulwark", "stats": {"attack": 64.0, "speed": 23.0}},
	70: {"character_id": "kiro", "name": "Kiro · Rugido del relámpago", "variant": "charged", "stats": {"max_hp": 1000.0, "defense": 110.0}},
	80: {"character_id": "neris", "name": "Neris · Círculo de los maestros", "variant": "tempo", "stats": {"max_hp": 980.0, "attack": 73.0, "defense": 90.0}},
	90: {"character_id": "sira", "name": "Sira · Filo de las estrellas", "variant": "critical", "stats": {"max_hp": 850.0, "attack": 83.0, "defense": 75.0}},
	100: {"character_id": "sira", "boss_id": "vespera", "name": "Véspera · El último eclipse", "variant": "tempo", "major": true, "strength": "Gran velocidad y evasión, cinco técnicas y dos fases de presión creciente.", "weakness": "Resistencia al 28%, no se cura y sus golpes fuertes tienen preparación visible.", "stats": {"max_hp": 1020.0, "attack": 85.0, "defense": 100.0, "speed": 31.0, "accuracy": 1.12, "evasion": 0.28, "crit_chance": 0.26, "resistance": 0.28}},
}

static func chapter_for_level(global_level: int) -> int:
	for entry: Dictionary in CHAPTERS:
		if global_level >= int(entry.start_level) and global_level <= int(entry.end_level): return int(entry.number)
	return 0

static func opponent_level(global_level: int) -> int:
	return clampi(23 + roundi(float(global_level - 17) * 0.49), 23, 50)

static func stat_budget(global_level: int, kind: String) -> int:
	var budget: float = 57.0 + float(global_level - 17) * 1.10
	return roundi(budget + (16.0 if kind == "boss" else 4.0 if kind == "elite" else -3.0))

static func move_tier(global_level: int, kind: String) -> int:
	return 2 if global_level >= 71 or (kind == "boss" and global_level >= 50) else 1 if global_level >= 31 or kind == "boss" else 0

static func rewards(global_level: int, kind: String) -> Dictionary:
	var base: int = roundi(400.0 + float(global_level - 17) * 3.5)
	var xp_win: int = base + (180 if kind == "boss" else 90 if kind == "elite" else 0)
	return {"xp_win": xp_win, "xp_loss": roundi(float(base) * 0.22), "move_points": 1 if global_level in MOVE_TOKEN_LEVELS else 0, "perk_points": 1 if global_level in PERK_LEVELS else 0, "stat_points": elite_points(global_level) if kind == "elite" else 0}

static func earned_tokens(cleared: int, milestones: Array[int]) -> int:
	var amount: int = 0
	for milestone: int in milestones:
		if cleared >= milestone: amount += 1
	return amount

static func points_for_level(hero_level: int) -> int:
	return 0 if hero_level <= 1 or hero_level > 50 else 3 if hero_level <= 20 else 2

static func elite_points(global_level: int) -> int:
	return 2 if global_level <= 16 else 0
