class_name StoryCatalog
extends RefCounted
## Campaign difficulty is public data. No campaign multiplier enters combat rules.
const Families = preload("res://scripts/character_families.gd")
const Catalog = preload("res://scripts/character_catalog.gd")
const Balance = preload("res://scripts/balance.gd")
const Campaign = preload("res://scripts/campaign_config.gd")
const Moves = preload("res://scripts/move_catalog.gd")
const CONFIG: Dictionary = {"initial_points": 3, "points_per_level": 3, "elite_points": 2, "surrender_xp": 8, "surrender_cooldown": 4, "allocation_cap": 30, "history_limit": 100, "badge": "Guardián de los Faroles"}
const CHAPTERS: Array[Dictionary] = Campaign.CHAPTERS
static var _generated_routes: Dictionary = {}
static var _allocation_cache: Dictionary = {}
const ALLOCATIONS: Array[Dictionary] = [
	{"key": "max_hp", "name": "Vida", "description": "+14 PV por punto. Soporta más daño antes de caer.", "increment": 14.0},
	{"key": "attack", "name": "Ataque", "description": "+0.9 de ataque por punto, antes de la defensa rival.", "increment": 0.9},
	{"key": "defense", "name": "Defensa", "description": "+5 de defensa por punto. Reduce el daño directo con rendimiento decreciente.", "increment": 5.0},
	{"key": "speed", "name": "Velocidad", "description": "+1.2 de velocidad por punto. Acorta el tiempo entre acciones.", "increment": 1.2},
	{"key": "accuracy", "name": "Precisión", "description": "+2.5 puntos porcentuales por punto. Se enfrenta a la evasión rival; acierto máximo 96%.", "increment": 0.025},
	{"key": "evasion", "name": "Evasión", "description": "+1.8 puntos porcentuales por punto, hasta 30%. Reduce el acierto rival.", "increment": 0.018},
	{"key": "crit_chance", "name": "Crítico", "description": "+3.5 puntos porcentuales por punto, hasta 32%. Se calcula al acertar.", "increment": 0.035},
	{"key": "resistance", "name": "Resistencia", "description": "+5.5 puntos porcentuales por punto, hasta 50%. Reduce aplicación y duración de estados.", "increment": 0.055},
]
const STAGES: Array[Dictionary] = [
	{"id": "river_gate", "title": "La puerta del río", "character_id": "luma", "level": 1, "kind": "normal", "profile": "Una guardiana equilibrada que pone a prueba tus primeros pasos.", "strength": "Puntería que aprende de los fallos.", "weakness": "Presión moderada y ninguna defensa especializada.", "xp_win": 120, "xp_loss": 40, "stat_overrides": {"max_hp": 250.0, "attack": 22.0, "defense": 20.0, "speed": 6.0, "accuracy": 0.96, "crit_chance": 0.12}},
	{"id": "wind_bridge", "title": "El puente del viento", "character_id": "nima", "level": 2, "kind": "normal", "profile": "Un corredor veloz que encadena ataques, pero acusa cada impacto.", "strength": "Velocidad alta y un golpe reforzado cada tres acciones.", "weakness": "Poca defensa y una reserva de vida contenida.", "xp_win": 140, "xp_loss": 45, "stat_overrides": {"max_hp": 235.0, "attack": 22.0, "defense": 12.0, "speed": 13.0, "accuracy": 0.94, "evasion": 0.14}},
	{"id": "ochre_wall", "title": "La muralla de ocre", "character_id": "duna", "level": 4, "kind": "normal", "profile": "Una centinela de piedra que resiste con armadura y escudos.", "strength": "Defensa muy alta y escudos periódicos.", "weakness": "Acciones lentas; sus escudos no bloquean el daño de estados.", "xp_win": 170, "xp_loss": 50, "stat_overrides": {"max_hp": 320.0, "attack": 25.0, "defense": 64.0, "speed": 3.0, "evasion": 0.05}},
	{"id": "glass_duel", "title": "Élite · El filo de cristal", "character_id": "sira", "level": 5, "kind": "elite", "profile": "Una duelista de gran puntería con críticos que atraviesan armadura.", "strength": "Críticos frecuentes y penetrantes; casi nunca desperdicia un golpe.", "weakness": "Defensa y resistencia bajas; los intercambios le cuestan vida.", "xp_win": 240, "xp_loss": 65, "stat_overrides": {"max_hp": 295.0, "attack": 31.0, "defense": 17.0, "speed": 9.0, "accuracy": 1.02, "crit_chance": 0.27}},
	{"id": "midnight_garden", "title": "El jardín de medianoche", "character_id": "iria", "level": 7, "kind": "normal", "profile": "Una botánica resistente que desgasta con veneno acumulable.", "strength": "Veneno persistente y buena resistencia a estados negativos.", "weakness": "Daño directo contenido; necesita varios impactos para preparar el veneno.", "xp_win": 190, "xp_loss": 60, "stat_overrides": {"max_hp": 395.0, "attack": 30.0, "defense": 27.0, "speed": 8.0, "resistance": 0.36}},
	{"id": "mirror_lake", "title": "El lago de los espejos", "character_id": "neris", "level": 8, "kind": "normal", "profile": "Una nadadora evasiva que guarda una única recuperación para el final.", "strength": "Evasión elevada y una remontada cuando su vida escasea.", "weakness": "Defensa moderada; solo puede curarse una vez.", "xp_win": 220, "xp_loss": 65, "stat_overrides": {"max_hp": 345.0, "attack": 32.0, "defense": 21.0, "speed": 10.0, "evasion": 0.25}},
	{"id": "jade_bell", "title": "Élite · La campana de jade", "character_id": "taro", "level": 9, "kind": "elite", "profile": "Un veterano de gran vida y armadura que responde a la agresión.", "strength": "Aguante alto y contraataques que castigan los intercambios.", "weakness": "Velocidad baja y respuestas que no están garantizadas.", "xp_win": 290, "xp_loss": 75, "stat_overrides": {"max_hp": 480.0, "attack": 33.0, "defense": 55.0, "speed": 5.0, "resistance": 0.32}},
	{"id": "last_lantern", "title": "Jefe · El último farol", "character_id": "mugo", "level": 12, "kind": "boss", "profile": "Ascua custodia el último farol. Su núcleo se aviva al perder vida.", "strength": "Ataque, armadura y resistencia sólidos; dos fases anuncian su presión creciente.", "weakness": "Velocidad inicial baja y evasión escasa. Nunca se cura ni se vuelve invulnerable.", "xp_win": 300, "xp_loss": 85, "stat_overrides": {"max_hp": 550.0, "attack": 38.0, "defense": 48.0, "speed": 6.0, "accuracy": 0.97, "evasion": 0.06, "crit_chance": 0.13, "crit_damage": 1.55, "resistance": 0.35}},
]


const STORM_STAGES: Array[Dictionary] = [
	{"id": "storm_red_pass", "title": "El desfiladero rojo", "character_id": "kiro", "level": 13, "kind": "normal", "profile": "Un pugilista que abre el paso con golpes fuertes y deja su guardia expuesta.", "strength": "Ataque alto y furia creciente cuando pierde vida.", "weakness": "Armadura ligera y poca tolerancia a estados.", "xp_win": 340, "xp_loss": 95, "stat_overrides": {"max_hp": 470.0, "attack": 41.0, "defense": 24.0, "speed": 11.0, "accuracy": 0.97, "evasion": 0.10, "crit_chance": 0.18}},
	{"id": "storm_bitter_rain", "title": "La lluvia amarga", "character_id": "iria", "level": 14, "kind": "normal", "profile": "La lluvia protege a una botánica que mezcla resistencia y desgaste continuo.", "strength": "Veneno acumulable, puntería firme y resistencia elevada.", "weakness": "Daño directo moderado; requiere varios golpes para acumular veneno.", "xp_win": 370, "xp_loss": 105, "stat_overrides": {"max_hp": 540.0, "attack": 37.0, "defense": 32.0, "speed": 11.0, "accuracy": 1.02, "resistance": 0.40}},
	{"id": "storm_iron_roots", "title": "Las raíces de hierro", "character_id": "mugo", "level": 16, "kind": "normal", "profile": "Un guardián de enorme aguante que espera el error del rival.", "strength": "Vida y defensa altas; reduce el daño adicional de los críticos.", "weakness": "Lento y casi incapaz de esquivar.", "xp_win": 400, "xp_loss": 115, "stat_overrides": {"max_hp": 720.0, "attack": 38.0, "defense": 76.0, "speed": 5.0, "accuracy": 0.99, "evasion": 0.04, "resistance": 0.40}},
	{"id": "storm_thunder_run", "title": "Élite · La carrera del trueno", "character_id": "nima", "level": 17, "kind": "elite", "profile": "Un corredor que atraviesa el vendaval con ráfagas de tres golpes.", "strength": "Velocidad muy alta, combos y evasión.", "weakness": "Defensa baja; su ritmo rápido también lo expone a respuestas.", "xp_win": 540, "xp_loss": 145, "stat_overrides": {"max_hp": 530.0, "attack": 46.0, "defense": 20.0, "speed": 22.0, "accuracy": 1.02, "evasion": 0.20, "crit_chance": 0.15}},
	{"id": "storm_jade_echo", "title": "El eco entre las piedras", "character_id": "taro", "level": 18, "kind": "normal", "profile": "Un maestro de la réplica que mantiene la guardia bajo la tormenta.", "strength": "Defensa sólida y contraataques que castigan los intercambios.", "weakness": "Velocidad contenida y respuestas que nunca están garantizadas.", "xp_win": 460, "xp_loss": 125, "stat_overrides": {"max_hp": 690.0, "attack": 43.0, "defense": 62.0, "speed": 10.0, "accuracy": 1.04, "evasion": 0.10, "crit_chance": 0.14}},
	{"id": "storm_sand_refuge", "title": "El refugio de arena", "character_id": "duna", "level": 20, "kind": "normal", "profile": "La centinela protege el último refugio con placas gruesas y escudos periódicos.", "strength": "Armadura muy alta y vida abundante.", "weakness": "Pocas acciones; el daño de estados atraviesa sus escudos.", "xp_win": 500, "xp_loss": 140, "stat_overrides": {"max_hp": 740.0, "attack": 43.0, "defense": 88.0, "speed": 7.0, "accuracy": 1.02, "evasion": 0.06, "resistance": 0.32}},
	{"id": "storm_lunar_edge", "title": "Élite · El filo de la luna", "character_id": "sira", "level": 21, "kind": "elite", "profile": "Una duelista que combina puntería, velocidad y críticos penetrantes.", "strength": "Críticos muy frecuentes que ignoran parte de la armadura.", "weakness": "Defensa ligera y baja resistencia a efectos negativos.", "xp_win": 620, "xp_loss": 165, "stat_overrides": {"max_hp": 590.0, "attack": 52.0, "defense": 24.0, "speed": 16.0, "accuracy": 1.10, "evasion": 0.14, "crit_chance": 0.30, "crit_damage": 1.85, "resistance": 0.10}},
	{"id": "storm_moon_wings", "title": "Jefa · Las alas de la tormenta", "character_id": "sira", "level": 23, "kind": "boss", "profile": "Véspera, polilla lunar, convierte el viento en un baile de ataques precisos.", "strength": "Velocidad, evasión y presión creciente en dos fases declaradas.", "weakness": "Armadura ligera. Sus alas no la vuelven invulnerable y nunca se cura.", "xp_win": 680, "xp_loss": 180, "stat_overrides": {"max_hp": 780.0, "attack": 52.0, "defense": 30.0, "speed": 20.0, "accuracy": 1.06, "evasion": 0.22, "crit_chance": 0.18, "crit_damage": 1.70, "resistance": 0.30}},
]


static func chapters() -> Array[Dictionary]:
	return CHAPTERS.duplicate(true)


static func chapter(number: int = 1) -> Dictionary:
	return CHAPTERS[number - 1].duplicate(true) if number >= 1 and number <= CHAPTERS.size() else {}


static func total_encounters() -> int:
	return Campaign.TOTAL_ENCOUNTERS


static func chapter_for_level(global_level: int) -> int:
	return Campaign.chapter_for_level(global_level)


static func global_stage(global_level: int) -> Dictionary:
	var number: int = chapter_for_level(global_level)
	if number == 0: return {}
	return stage(global_level - int(chapter(number).start_level), number)


static func stages(chapter_number: int = 1) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if chapter_number == 1: result = STAGES.duplicate(true)
	elif chapter_number == 2: result = STORM_STAGES.duplicate(true)
	else:
		if chapter(chapter_number).is_empty(): return result
		if not _generated_routes.has(chapter_number):
			var generated: Array[Dictionary] = []
			var meta: Dictionary = chapter(chapter_number)
			for global_level: int in range(int(meta.start_level), int(meta.end_level) + 1):
				generated.append(_generated_stage(global_level, chapter_number))
			_generated_routes[chapter_number] = generated
		result.assign(_generated_routes[chapter_number].duplicate(true))
	for index: int in range(result.size()):
		var global_level: int = int(chapter(chapter_number).start_level) + index
		result[index]["global_level"] = global_level
		result[index]["chapter"] = chapter_number
		if not result[index].has("rewards"):
			result[index]["rewards"] = {"xp_win": result[index].xp_win, "xp_loss": result[index].xp_loss,
				"move_points": 1 if global_level in Campaign.MOVE_TOKEN_LEVELS else 0,
				"perk_points": 1 if global_level in Campaign.PERK_LEVELS else 0,
				"stat_points": int(CONFIG.elite_points) if result[index].kind == "elite" else 0}
	return result


static func stage(index: int, chapter_number: int = 1) -> Dictionary:
	var route: Array[Dictionary] = stages(chapter_number)
	return route[index] if index >= 0 and index < route.size() else {}


static func _generated_stage(global_level: int, chapter_number: int) -> Dictionary:
	var meta: Dictionary = chapter(chapter_number)
	var local_index: int = global_level - int(meta.start_level)
	var kind: String = "boss" if global_level == int(meta.end_level) else "elite" if local_index in [3, 6] or (chapter_number == 3 and local_index == 2) else "normal"
	var variant_id: String = str(Campaign.CHAPTER_PATTERNS[chapter_number][local_index])
	var variant: Dictionary = Campaign.VARIANTS[variant_id]
	var pool: Array = variant.pool.duplicate()
	var character_id: String = str(pool[(global_level + chapter_number) % pool.size()])
	if kind == "boss": character_id = str(Campaign.BOSSES[global_level].character_id)
	var level: int = Campaign.opponent_level(global_level)
	var budget: int = Campaign.stat_budget(global_level, kind)
	var invested: Dictionary = _variant_allocations(variant_id, budget, character_id, level)
	var rewards: Dictionary = Campaign.rewards(global_level, kind)
	var declared_stats: Dictionary = stats_for({"character_id": character_id, "level": level, "allocations": invested})
	if kind == "boss": declared_stats.merge(Campaign.BOSSES[global_level].get("stats", {}), true)
	return {"id": "journey_%03d" % global_level, "title": ("Jefe · " if kind == "boss" else "Élite · " if kind == "elite" else "") + str(Campaign.BOSSES[global_level].name if kind == "boss" else variant.name),
		"character_id": character_id, "level": level, "kind": kind, "profile": str(meta.theme) + ": " + str(variant.name) + ".",
		"strength": str(Campaign.BOSSES[global_level].get("strength", variant.strength)) if kind == "boss" else str(variant.strength), "weakness": str(Campaign.BOSSES[global_level].get("weakness", variant.weakness)) if kind == "boss" else str(variant.weakness), "variant": variant_id,
		"opponent_pool": [character_id] if kind == "boss" else pool, "stat_budget": budget, "stat_allocations": invested,
		"stat_overrides": declared_stats,
		"xp_win": rewards.xp_win, "xp_loss": rewards.xp_loss, "rewards": rewards, "major": global_level in [50, 100]}


static func _variant_allocations(variant_id: String, budget: int, character_id: String, hero_level: int) -> Dictionary:
	var cache_key: String = "%s:%d:%s:%d" % [variant_id,budget,character_id,hero_level]
	if _allocation_cache.has(cache_key): return _allocation_cache[cache_key].duplicate()
	var weights: Dictionary = Campaign.VARIANTS[variant_id].weights
	var result: Dictionary = {}
	var sequence: Array[String] = []
	for option: Dictionary in ALLOCATIONS:
		result[option.key] = 0
		for count: int in range(int(weights.get(option.key, 1))): sequence.append(str(option.key))
	var cursor: int = 0
	var limits: Dictionary = Campaign.VARIANTS[variant_id].get("limits", {})
	var current: Dictionary = stats_for({"character_id": character_id, "level": hero_level, "allocations": result})
	for point: int in range(budget):
		for attempt: int in range(sequence.size()):
			var key: String = sequence[cursor % sequence.size()]
			cursor += 1
			if int(result[key]) < int(limits.get(key, CONFIG.allocation_cap)):
				var candidate: Dictionary = result.duplicate()
				candidate[key] = int(candidate[key]) + 1
				var after: Dictionary = stats_for({"character_id": character_id, "level": hero_level, "allocations": candidate})
				if float(after[key]) > float(current[key]) + 0.000001:
					result = candidate
					current = after
					break
	_allocation_cache[cache_key] = result.duplicate()
	return result


static func points_for_level(hero_level: int) -> int:
	return Campaign.points_for_level(hero_level)


static func allocations() -> Array[Dictionary]:
	return ALLOCATIONS.duplicate(true)


static func stats_for(profile: Dictionary) -> Dictionary:
	var definition: Dictionary = Catalog.definition(str(profile.get("character_id", "nima")))
	if definition.is_empty():
		definition = Catalog.definition("nima")
	# Campaign allocations are independent of the four league training attributes.
	var base_profile: Dictionary = {"character_id": definition.id, "level": clampi(int(profile.get("level", 1)), 1, Balance.MAX_LEVEL), "stats": definition.training_base.duplicate(true)}
	var result: Dictionary = Catalog.stats_for(base_profile)
	var invested: Dictionary = profile.get("allocations", {}) if profile.get("allocations", {}) is Dictionary else {}
	for choice: Dictionary in ALLOCATIONS:
		var candidate: Variant = invested.get(choice.key, 0)
		var points: int = 0
		if (candidate is int or candidate is float) and is_finite(float(candidate)):
			points = clampi(int(candidate), 0, int(CONFIG.allocation_cap))
		var limits: Array = Balance.STAT_BOUNDS[choice.key]
		result[choice.key] = clampf(float(result[choice.key]) + float(points) * float(choice.increment), float(limits[0]), float(limits[1]))
	result["interval"] = Balance.interval_for(float(result.speed))
	return result


static func opponent(index: int, chapter_number: int = 1, run_seed: int = 0, hero_id: String = "") -> Dictionary:
	var encounter: Dictionary = stage(index, chapter_number)
	if encounter.is_empty():
		return {}
	if encounter.has("opponent_pool") and encounter.kind != "boss" and run_seed != 0:
		var pool: Array = encounter.opponent_pool
		var selected: int = posmod((str(run_seed) + ":" + hero_id + ":" + str(encounter.id)).hash(), pool.size())
		encounter.character_id = str(pool[selected])
		encounter.stat_allocations = _variant_allocations(str(encounter.variant), int(encounter.stat_budget), str(encounter.character_id), int(encounter.level))
		encounter.stat_overrides = stats_for({"character_id": encounter.character_id, "level": encounter.level, "allocations": encounter.stat_allocations})
	var definition: Dictionary = boss_definition(chapter_number) if encounter.kind == "boss" else Catalog.definition(str(encounter.character_id))
	var result: Dictionary = {"character_id": encounter.character_id, "name": definition.name, "archetype": definition.archetype, "level": encounter.level, "stats": definition.training_base.duplicate(true), "ability": definition.ability.duplicate(true), "signature": definition.signature.duplicate(true), "visual": definition.visual.duplicate(true), "mode": "story", "story_stage_id": encounter.id, "story_stage_index": index, "opponent_id": "story_" + str(encounter.id), "title": encounter.title}
	var combat: Dictionary = Catalog.stats_for(result)
	combat.merge(encounter.stat_overrides, true)
	if int(encounter.global_level) in Campaign.BOSSES:
		combat.merge(Campaign.BOSSES[int(encounter.global_level)].get("stats", {}), true)
	combat["interval"] = Balance.interval_for(float(combat.speed))
	result["combat_stats"] = combat
	result["story_chapter_id"] = chapter_number
	result["story_level"] = int(encounter.global_level)
	result["story_variant"] = str(encounter.get("variant", "legacy"))
	var move_owner: String = str(definition.id)
	var available: Array[Dictionary] = Moves.moves_for(move_owner) if encounter.kind == "boss" else Moves.unlocked_moves(move_owner, int(encounter.level))
	result["moves"] = []
	result["unlocked_moves"] = []
	result["move_upgrades"] = {}
	result["perks"] = []
	if int(encounter.global_level) >= 31:
		var options: Array[Dictionary] = Moves.perks_for(move_owner)
		var count: int = mini(options.size(), 1 if int(encounter.global_level) < 61 else 2 if int(encounter.global_level) < 91 else 3)
		for perk_index: int in range(count): result.perks.append(str(options[(perk_index + int(encounter.global_level)) % options.size()].id))
	for move: Dictionary in available:
		var tier: int = Campaign.move_tier(int(encounter.global_level), str(encounter.kind)) if int(encounter.global_level) > 16 else 0
		result.unlocked_moves.append(str(move.id))
		result.move_upgrades[str(move.id)] = tier
		var resolved: Dictionary = Moves.resolve_move(move_owner, str(move.id), tier, result.perks)
		if encounter.has("variant") and str(resolved.type) in Campaign.VARIANTS[str(encounter.variant)].types:
			resolved["weight"] = float(resolved.get("weight", 1.0)) * 1.3
		result.moves.append(resolved)
	if encounter.kind == "boss":
		result["story_boss_id"] = definition.id
	var individual: Dictionary = Families.story_individual(str(encounter.character_id), int(encounter.global_level), encounter.kind == "boss")
	if not individual.is_empty():
		result["name"] = str(individual.name)
		result["individual_id"] = str(individual.id)
		result["species_id"] = str(individual.species_id)
		result["individual_profile"] = individual.duplicate(true)
		result.visual["atlas"] = str(individual.asset)
		result["appearance"] = {"body_style_id":individual.id,"palette_id":"original","aura_id":"none","trail_id":"none","victory_pose_id":"classic","intro_animation_id":"classic"}
	return result


static func boss_definition(chapter_number: int = 1) -> Dictionary:
	if chapter_number >= 3:
		var meta: Dictionary = chapter(chapter_number)
		if meta.is_empty(): return {}
		var global_level: int = int(meta.end_level)
		var boss: Dictionary = Campaign.BOSSES[global_level]
		var encounter: Dictionary = stage(global_level - int(meta.start_level), chapter_number)
		var definition: Dictionary = boss_definition(1 if str(boss.get("boss_id", "")) == "ascua" else 2) if boss.has("boss_id") else Catalog.definition(str(boss.character_id))
		definition.name = str(boss.name)
		definition.role = str(meta.theme)
		definition.base_stats = encounter.stat_overrides.duplicate(true)
		definition.strengths = encounter.strength
		definition.weaknesses = encounter.weakness
		return definition
	if chapter_number == 2:
		var moth: Dictionary = Catalog.definition("sira")
		moth.merge({"id": "vespera", "name": "Véspera", "role": "Guardiana de la tormenta", "personality": "Lee el viento como otros leen las estrellas.", "base_stats": STORM_STAGES[7].stat_overrides.duplicate(true), "strengths": STORM_STAGES[7].strength, "weaknesses": STORM_STAGES[7].weakness, "visual": {"archetype": 0, "tint": "ffffff", "atlas": "res://assets/sprites/vespera-v3.png"}}, true)
		moth["ability"] = {"id": "phase_shift", "name": "Danza del vendaval", "description": "Por encima del 60% de vida: combate normal. Al 60%: velocidad +10%. Al 30%: conserva esa velocidad y ataque +8%. Sin curación ni invulnerabilidad.", "phases": [
			{"below_hp": 1.0, "name": "Brisa lunar", "modifiers": {}, "description": "Estadísticas iniciales."},
			{"below_hp": 0.60, "name": "Alas del vendaval", "modifiers": {"speed": 1.10}, "description": "Velocidad +10%."},
			{"below_hp": 0.30, "name": "Ojo de la tormenta", "modifiers": {"speed": 1.10, "attack": 1.08}, "description": "Velocidad +10% y ataque +8%."},
		]}
		moth["signature"] = {"name": "Polvo de eclipse", "effect": "accuracy_down", "magnitude": 0.12, "duration": 4, "damage_multiplier": 1.65, "description": "1% por combate, una sola vez: golpe certero ×1.65 y precisión rival −12 puntos durante 4 acciones propias; la resistencia puede acortar su duración."}
		return moth
	if chapter_number != 1: return {}
	var definition: Dictionary = Catalog.definition("mugo")
	definition["id"] = "ascua"
	definition["name"] = "Ascua"
	definition["role"] = "Custodio del último farol"
	definition["personality"] = "Paciente y firme: mantiene encendida la luz cuando cae la noche."
	definition["base_stats"] = STAGES[7].stat_overrides.duplicate(true)
	definition["strengths"] = STAGES[7].strength
	definition["weaknesses"] = STAGES[7].weakness
	definition["visual"] = {"archetype": 2, "tint": "ffffff", "atlas": "res://assets/sprites/ascua-v3.png"}
	definition["ability"] = {"id": "phase_shift", "name": "Núcleo del farol", "description": "Por encima del 60% de vida: combate normal. Al 60%: ataque +8%. Al 30%: conserva ese ataque y velocidad +15%. Sin curación ni invulnerabilidad.", "phases": [
		{"below_hp": 1.0, "name": "Brasa serena", "modifiers": {}, "description": "Estadísticas iniciales."},
		{"below_hp": 0.60, "name": "Horno vivo", "modifiers": {"attack": 1.08}, "description": "Ataque +8%."},
		{"below_hp": 0.30, "name": "Última ascua", "modifiers": {"attack": 1.08, "speed": 1.15}, "description": "Ataque +8% y velocidad +15%."},
	]}
	definition["signature"] = {"name": "La noche encendida", "effect": "attack_down", "magnitude": 0.18, "duration": 3, "damage_multiplier": 1.7, "description": "1% por combate, una sola vez: golpe certero ×1.7 y ataque rival −18% durante 3 acciones propias del objetivo."}
	return definition


static func defeat_hint(summary: Dictionary) -> String:
	if summary.is_empty() or str(summary.get("winner", "")) != "rival":
		return ""
	if str(summary.get("reason", "")) == "surrender":
		return "Puedes volver cuando quieras; tu progreso se conserva."
	var metrics: Dictionary = summary.get("metrics", {})
	var player: Dictionary = metrics.get("player", {})
	var rival: Dictionary = metrics.get("rival", {})
	var attacks: int = int(player.get("attacks", 0))
	var misses: int = int(player.get("misses", 0))
	if attacks >= 5 and float(misses) / float(attacks) >= 0.25:
		return "Fallaste %d de %d ataques. Más precisión podría ayudarte." % [misses, attacks]
	var dot_damage: int = 0
	for event: Dictionary in summary.get("events", []):
		if str(event.get("type", "")) == "status_tick" and str(event.get("target", event.get("side", ""))) == "player":
			dot_damage += int(event.get("damage", 0))
	if dot_damage >= 30 and float(dot_damage) >= float(player.get("damage_taken", 0)) * 0.15:
		return "Los estados te quitaron %d PV. Más resistencia podría reducir su impacto." % dot_damage
	if int(rival.get("status_turns_resisted", 0)) >= 2 or int(rival.get("statuses_prevented", 0)) >= 2:
		return "El rival redujo tus efectos negativos. Combinar otras fuentes de daño podría ayudar."
	var own_actions: int = int(player.get("turns_survived", attacks))
	var rival_actions: int = int(rival.get("turns_survived", rival.get("attacks", 0)))
	if own_actions >= 4 and rival_actions >= own_actions + 3 and float(rival_actions) / float(own_actions) >= 1.2:
		return "El rival actuó %d veces frente a tus %d. Más velocidad podría cambiar el ritmo." % [rival_actions, own_actions]
	var source: Dictionary = summary.get("player", {})
	var stats: Dictionary = source.get("combat_stats", {})
	var hp: float = float(stats.get("max_hp", 250.0))
	if int(rival.get("hits", 0)) > 0 and float(player.get("damage_taken", 0)) / float(rival.hits) >= hp * 0.10:
		return "Cada impacto te costó mucha vida. Más defensa o vida podría darte margen."
	if str(summary.get("reason", "")) == "timeout":
		return "El rival conservó más vida al límite de tiempo. Tu daño sostenido podría marcar la diferencia."
	return "El combate agotó tu vida antes. Revisa el resumen y combina aguante con presión."
