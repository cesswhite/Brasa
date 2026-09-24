class_name MoveCatalog
extends RefCounted
## Central definitions for both AI and presentation; no Signature is an AI choice.
const Balance = preload("res://scripts/balance.gd")
const UNLOCK_LEVELS: Array[int] = [1,1,5,12,20]
const MAX_TIER := 2
const UPGRADE_COST := 1
static var _move_cache: Dictionary = {}
static var _perk_cache: Dictionary = {}
const CONFIG := {"damage_per_tier":0.035,"accuracy_per_tier":0.008,"recovery_per_tier":0.012,
	"max_damage_multiplier":1.65,"max_accuracy_modifier":0.15,"max_priority":0.25,
	"max_armor_ignore":0.30,"max_guard_reduction":0.45,"max_counter_chance":0.55,
	"max_heal_fraction":0.06,"counter_speed_factor":0.003,"min_cadence":0.50,
	"repeat_weight":0.48,"finisher_ratio":0.25,"finisher_weight":2.1,
	"low_hp_ratio":0.36,"defense_weight":1.75,"status_refresh_weight":0.30,
	"guard_pressure_weight":1.6,"counter_windup":0.05,"counter_travel":0.08,"counter_recovery":0.15,
	"finisher_other_weight":0.70,"guard_healthy_weight":0.70,"existing_guard_weight":0.20,
	"existing_buff_weight":0.50,"slower_fast_weight":1.18,
	"signature_windup":0.34,"signature_travel":0.16,"signature_recovery":0.35}
const TYPES := {
	"quick":{"damage_multiplier":0.84,"accuracy_modifier":0.04,"priority":0.15,"windup":0.07,"travel":0.08,"recovery":0.13,"weight":3.1,"cooldown":0},
	"dash":{"damage_multiplier":0.92,"accuracy_modifier":0.015,"priority":0.17,"windup":0.05,"travel":0.13,"recovery":0.17,"weight":1.65,"cooldown":1},
	"heavy":{"damage_multiplier":1.30,"accuracy_modifier":-0.055,"priority":-0.10,"windup":0.36,"travel":0.11,"recovery":0.30,"weight":1.7,"cooldown":1},
	"charge":{"damage_multiplier":1.40,"accuracy_modifier":-0.075,"priority":-0.16,"windup":0.40,"travel":0.15,"recovery":0.34,"weight":1.4,"cooldown":3},
	"jump":{"damage_multiplier":1.13,"accuracy_modifier":-0.045,"priority":-0.015,"windup":0.15,"travel":0.30,"recovery":0.23,"weight":1.45,"cooldown":2,"airborne_evasion":0.025,"critical_chance_modifier":0.035},
	"technique":{"damage_multiplier":0.90,"accuracy_modifier":0.01,"priority":0.0,"windup":0.18,"travel":0.12,"recovery":0.21,"weight":1.2,"cooldown":2},
	"guard":{"damage_multiplier":0.0,"accuracy_modifier":0.0,"priority":-0.05,"windup":0.12,"travel":0.0,"recovery":0.22,"weight":0.50,"cooldown":3},
	"counter":{"damage_multiplier":0.0,"accuracy_modifier":0.0,"priority":0.02,"windup":0.10,"travel":0.0,"recovery":0.18,"weight":0.65,"cooldown":3},
}
const MOVEMENT := {
	"quick":{"kind":"quick","retreat":0.0,"distance":28.0,"height":0.0},
	"dash":{"kind":"dash","retreat":0.0,"distance":82.0,"height":0.0},
	"heavy":{"kind":"heavy","retreat":12.0,"distance":42.0,"height":0.0},
	"charge":{"kind":"charge","retreat":30.0,"distance":96.0,"height":0.0},
	"jump":{"kind":"jump_forward","retreat":0.0,"distance":74.0,"height":65.0},
	"technique":{"kind":"technique","retreat":5.0,"distance":36.0,"height":0.0},
	"guard":{"kind":"guard","retreat":8.0,"distance":0.0,"height":0.0},
	"counter":{"kind":"counter","retreat":12.0,"distance":0.0,"height":0.0},
}
const DATA: Dictionary = {
	"nima": [
		[
			"zarpazo",
			"Zarpazo fugaz",
			"quick",
			"Remata con buena puntería y poca recuperación.",
			"Daño contenido.",
			{}
		],
		[
			"arena",
			"Paso de arena",
			"dash",
			"Cierra distancia antes que los golpes lentos.",
			"Menor daño por impacto.",
			{
				"priority": 0.2,
				"accuracy_modifier": 0.02
			}
		],
		[
			"salto",
			"Salto de duna",
			"jump",
			"Gana evasión durante el salto y busca un crítico.",
			"Pierde algo de puntería.",
			{
				"movement": {
					"kind": "jump_forward",
					"retreat": 0,
					"distance": 80,
					"height": 58
				},
				"airborne_evasion": 0.035,
				"critical_chance_modifier": 0.05
			}
		],
		[
			"acecho",
			"Acecho felino",
			"counter",
			"Espera una agresión y puede responder.",
			"Cede un ataque; respuesta incierta.",
			{
				"stance": {
					"reduction": 0.2,
					"chance": 0.38,
					"multiplier": 0.55,
					"duration": 1
				}
			}
		],
		[
			"cometa",
			"Cometa del desierto",
			"charge",
			"Carga con fuerza contra un rival protegido.",
			"Preparación larga y guardia abierta.",
			{
				"guard_bonus": 0.12,
				"damage_multiplier": 1.38,
				"self_status": {
					"type": "defense_down",
					"magnitude": 0.1,
					"duration": 1
				}
			}
		]
	],
	"luma": [
		[
			"palma",
			"Palma del río",
			"quick",
			"Golpe preciso para sostener la presión.",
			"Poco daño en un solo golpe.",
			{
				"accuracy_modifier": 0.05
			}
		],
		[
			"enfoque",
			"Ojo del remanso",
			"technique",
			"Ataca y mejora temporalmente su precisión.",
			"Golpe más suave.",
			{
				"damage_multiplier": 0.84,
				"self_status": {
					"type": "accuracy_up",
					"magnitude": 0.045,
					"duration": 2
				},
				"cooldown": 2
			}
		],
		[
			"ola",
			"Ola contenida",
			"heavy",
			"Puede debilitar el siguiente intercambio rival.",
			"Anticipación y puntería menor.",
			{
				"damage_multiplier": 1.23,
				"status": {
					"type": "attack_down",
					"magnitude": 0.12,
					"duration": 2
				},
				"status_chance": 0.55
			}
		],
		[
			"arco",
			"Arco del agua",
			"jump",
			"Salta hacia abajo y castiga una guardia defensiva.",
			"Acierto menos seguro.",
			{
				"guard_bonus": 0.16,
				"movement": {
					"kind": "jump_down",
					"retreat": 0,
					"distance": 60,
					"height": 76
				}
			}
		],
		[
			"remanso",
			"Remanso protector",
			"guard",
			"Se protege y recupera una pequeña porción de vida.",
			"Cede el ataque y tiene enfriamiento.",
			{
				"heal_fraction": 0.045,
				"cooldown": 4,
				"stance": {
					"reduction": 0.28,
					"chance": 0,
					"multiplier": 0,
					"duration": 1
				}
			}
		]
	],
	"mugo": [
		[
			"nudillo",
			"Nudillo de jade",
			"quick",
			"Golpe compacto y fiable.",
			"Prioridad más lenta que otros golpes rápidos.",
			{
				"damage_multiplier": 0.94,
				"priority": 0.06
			}
		],
		[
			"muro",
			"Muro paciente",
			"guard",
			"Refuerza la defensa hasta su siguiente acción.",
			"Cede la ofensiva.",
			{
				"stance": {
					"reduction": 0.3,
					"chance": 0,
					"multiplier": 0,
					"duration": 1
				},
				"cooldown": 3
			}
		],
		[
			"grieta",
			"Abrir la grieta",
			"heavy",
			"Golpe pesado que puede fracturar armadura.",
			"Preparación lenta.",
			{
				"status": {
					"type": "defense_down",
					"magnitude": 0.14,
					"duration": 2
				},
				"status_chance": 0.55
			}
		],
		[
			"montana",
			"Paso de montaña",
			"charge",
			"Embiste con daño fuerte y algo de penetración.",
			"Poca precisión y recuperación larga.",
			{
				"armor_ignore": 0.12,
				"damage_multiplier": 1.42,
				"accuracy_modifier": -0.07
			}
		],
		[
			"eco",
			"Eco de piedra",
			"counter",
			"Absorbe parte del golpe y puede devolverlo.",
			"No garantiza una respuesta.",
			{
				"stance": {
					"reduction": 0.3,
					"chance": 0.32,
					"multiplier": 0.62,
					"duration": 1
				}
			}
		]
	],
	"sira": [
		[
			"aguja",
			"Aguja de jade",
			"quick",
			"Golpe fino de alta precisión.",
			"Daño ligero.",
			{
				"accuracy_modifier": 0.06,
				"critical_chance_modifier": 0.015
			}
		],
		[
			"corte",
			"Corte rasante",
			"dash",
			"Se acerca de forma veloz con un corte certero.",
			"Presión moderada.",
			{
				"damage_multiplier": 0.92,
				"accuracy_modifier": 0.025
			}
		],
		[
			"vidrio",
			"Romper el vidrio",
			"heavy",
			"Parte de su golpe atraviesa la defensa.",
			"Menor puntería al cargar el corte.",
			{
				"armor_ignore": 0.18,
				"critical_chance_modifier": 0.03
			}
		],
		[
			"media_luna",
			"Media luna",
			"jump",
			"Golpe aéreo que prioriza los críticos.",
			"Acierto menos fiable.",
			{
				"critical_chance_modifier": 0.09,
				"critical_damage_modifier": 0.06,
				"movement": {
					"kind": "jump_over",
					"retreat": 0,
					"distance": 94,
					"height": 68
				}
			}
		],
		[
			"replica",
			"Réplica del filo",
			"counter",
			"Espera una abertura y puede contraatacar.",
			"Cede la iniciativa si nadie ataca.",
			{
				"stance": {
					"reduction": 0.18,
					"chance": 0.42,
					"multiplier": 0.58,
					"duration": 1
				}
			}
		]
	],
	"iria": [
		[
			"hoja",
			"Puño de hoja",
			"quick",
			"Mantiene presión y activa su veneno natural.",
			"Daño directo contenido.",
			{
				"damage_multiplier": 0.82,
				"accuracy_modifier": 0.045
			}
		],
		[
			"espora",
			"Espora amarga",
			"technique",
			"Puede añadir veneno que escala con su ataque.",
			"Golpe débil y efecto resistible.",
			{
				"damage_multiplier": 0.72,
				"status": {
					"type": "poison",
					"magnitude": 2,
					"duration": 2,
					"scaling_stat": "attack",
					"scaling_base": 19,
					"stacking": "refresh"
				},
				"status_chance": 0.5,
				"cooldown": 2
			}
		],
		[
			"bruma",
			"Salto de bruma",
			"jump",
			"Puede nublar la precisión del oponente.",
			"Aterrizaje menos preciso.",
			{
				"status": {
					"type": "accuracy_down",
					"magnitude": 0.055,
					"duration": 2
				},
				"status_chance": 0.5,
				"movement": {
					"kind": "jump_over",
					"retreat": 0,
					"distance": 86,
					"height": 70
				}
			}
		],
		[
			"raices",
			"Raíces firmes",
			"guard",
			"Se protege y enfoca su siguiente ofensiva.",
			"No causa daño.",
			{
				"self_status": {
					"type": "accuracy_up",
					"magnitude": 0.055,
					"duration": 2
				},
				"stance": {
					"reduction": 0.25,
					"chance": 0,
					"multiplier": 0,
					"duration": 1
				}
			}
		],
		[
			"savia",
			"Savia cortante",
			"heavy",
			"Puede reducir las curaciones enemigas.",
			"Preparación visible y efecto resistible.",
			{
				"damage_multiplier": 1.24,
				"status": {
					"type": "healing_down",
					"magnitude": 0.25,
					"duration": 3
				},
				"status_chance": 0.7
			}
		]
	],
	"duna": [
		[
			"placa",
			"Golpe de placa",
			"quick",
			"Golpe corto desde una guardia compacta.",
			"Poca prioridad.",
			{
				"damage_multiplier": 0.94,
				"priority": 0.04
			}
		],
		[
			"caparazon",
			"Cerrar caparazón",
			"guard",
			"Absorbe parte del daño con una postura protegida.",
			"Cede un ataque.",
			{
				"stance": {
					"reduction": 0.34,
					"chance": 0,
					"multiplier": 0,
					"duration": 1
				},
				"cooldown": 3
			}
		],
		[
			"rodar",
			"Rodar la duna",
			"charge",
			"Embiste y puede ralentizar al enemigo.",
			"Se expone mientras toma impulso.",
			{
				"status": {
					"type": "slow",
					"magnitude": 0.13,
					"duration": 2
				},
				"status_chance": 0.55,
				"self_status": {
					"type": "defense_down",
					"magnitude": 0.07,
					"duration": 1
				}
			}
		],
		[
			"cantera",
			"Martillo de cantera",
			"heavy",
			"Golpea con penetración contra armaduras.",
			"Es lento y menos preciso.",
			{
				"armor_ignore": 0.2,
				"damage_multiplier": 1.27
			}
		],
		[
			"retorno",
			"Retorno de arena",
			"counter",
			"Protege y puede responder a un impacto.",
			"Contraataque incierto.",
			{
				"stance": {
					"reduction": 0.32,
					"chance": 0.3,
					"multiplier": 0.66,
					"duration": 1
				}
			}
		]
	],
	"kiro": [
		[
			"colmillo",
			"Puño del colmillo",
			"quick",
			"Golpe veloz que remata enemigos debilitados.",
			"Daño ligero.",
			{
				"damage_multiplier": 0.86
			}
		],
		[
			"martillo",
			"Martillo cobrizo",
			"heavy",
			"Golpe fuerte con anticipación marcada.",
			"Menor precisión.",
			{
				"damage_multiplier": 1.36,
				"accuracy_modifier": -0.07
			}
		],
		[
			"ariete",
			"Ariete rojo",
			"charge",
			"Retrocede y embiste con gran fuerza.",
			"Abre su defensa durante la carga.",
			{
				"damage_multiplier": 1.46,
				"self_status": {
					"type": "defense_down",
					"magnitude": 0.13,
					"duration": 1
				}
			}
		],
		[
			"brasa",
			"Avivar la brasa",
			"technique",
			"Golpea y prepara un breve aumento de ataque.",
			"Daño inicial menor.",
			{
				"damage_multiplier": 0.78,
				"self_status": {
					"type": "attack_up",
					"magnitude": 0.1,
					"duration": 2
				},
				"cooldown": 3
			}
		],
		[
			"caida",
			"Caída del jabalí",
			"jump",
			"Ataque descendente más fuerte ante una guardia.",
			"Aterrizaje lento.",
			{
				"guard_bonus": 0.18,
				"movement": {
					"kind": "jump_down",
					"retreat": 12,
					"distance": 65,
					"height": 64
				},
				"recovery": 0.34
			}
		]
	],
	"neris": [
		[
			"ala",
			"Punta del ala",
			"quick",
			"Ataque ligero y preciso.",
			"Menor potencia.",
			{
				"accuracy_modifier": 0.055
			}
		],
		[
			"corriente",
			"Seguir la corriente",
			"dash",
			"Entra rápidamente y conserva la iniciativa.",
			"No atraviesa armadura.",
			{
				"priority": 0.21,
				"damage_multiplier": 0.9
			}
		],
		[
			"vuelo",
			"Vuelo sereno",
			"jump",
			"Gana evasión durante el desplazamiento aéreo.",
			"Ataque menos preciso.",
			{
				"airborne_evasion": 0.05,
				"movement": {
					"kind": "jump_over",
					"retreat": 0,
					"distance": 88,
					"height": 78
				}
			}
		],
		[
			"velo",
			"Velo del lago",
			"technique",
			"Puede reducir temporalmente la puntería rival.",
			"Daño moderado y efecto resistible.",
			{
				"damage_multiplier": 0.86,
				"status": {
					"type": "accuracy_down",
					"magnitude": 0.065,
					"duration": 2
				},
				"status_chance": 0.55
			}
		],
		[
			"refugio",
			"Refugio de plumas",
			"guard",
			"Postura defensiva que recupera poca vida.",
			"Enfriamiento largo; renuncia al ataque.",
			{
				"heal_fraction": 0.045,
				"cooldown": 5,
				"stance": {
					"reduction": 0.24,
					"chance": 0,
					"multiplier": 0,
					"duration": 1
				}
			}
		]
	],
	"taro": [
		[
			"puno",
			"Puño de tierra",
			"quick",
			"Golpe compacto y fiable.",
			"Potencia contenida.",
			{
				"damage_multiplier": 0.92,
				"priority": 0.06
			}
		],
		[
			"espera",
			"Espera del tejón",
			"counter",
			"Puede responder desde una postura defensiva.",
			"No garantiza contraataque.",
			{
				"stance": {
					"reduction": 0.25,
					"chance": 0.37,
					"multiplier": 0.6,
					"duration": 1
				}
			}
		],
		[
			"jade",
			"Guardia de jade",
			"guard",
			"Se protege y mejora brevemente su defensa.",
			"Cede un ataque.",
			{
				"self_status": {
					"type": "defense_up",
					"magnitude": 0.1,
					"duration": 2
				},
				"stance": {
					"reduction": 0.22,
					"chance": 0,
					"multiplier": 0,
					"duration": 1
				}
			}
		],
		[
			"cansancio",
			"Golpe de cansancio",
			"heavy",
			"Puede reducir la fuerza del rival.",
			"Precisión menor y ataque lento.",
			{
				"status": {
					"type": "attack_down",
					"magnitude": 0.13,
					"duration": 2
				},
				"status_chance": 0.55
			}
		],
		[
			"umbral",
			"Cruzar el umbral",
			"charge",
			"Embiste a los rivales que esperan en guardia.",
			"Preparación larga.",
			{
				"guard_bonus": 0.2,
				"damage_multiplier": 1.34
			}
		]
	],
	"ascua": [
		[
			"cobre",
			"Garra de cobre",
			"quick",
			"Ataque corto desde su armadura volcánica.",
			"Daño moderado.",
			{
				"damage_multiplier": 0.93,
				"priority": 0.07
			}
		],
		[
			"forja",
			"Puño de la forja",
			"heavy",
			"Golpe pesado y parcialmente penetrante.",
			"Lento y visible.",
			{
				"damage_multiplier": 1.32,
				"armor_ignore": 0.12
			}
		],
		[
			"brasero",
			"Carga del brasero",
			"charge",
			"Puede dejar una quemadura tras la embestida.",
			"Guardia abierta durante la carga.",
			{
				"status": {
					"type": "burn",
					"magnitude": 2.3,
					"duration": 2,
					"scaling_stat": "attack",
					"scaling_base": 38
				},
				"status_chance": 0.5,
				"self_status": {
					"type": "defense_down",
					"magnitude": 0.08,
					"duration": 1
				}
			}
		],
		[
			"obsidiana",
			"Obsidiana cerrada",
			"guard",
			"Reduce el siguiente intercambio enemigo.",
			"Cede un ataque.",
			{
				"stance": {
					"reduction": 0.28,
					"chance": 0,
					"multiplier": 0,
					"duration": 1
				}
			}
		],
		[
			"crater",
			"Golpe del cráter",
			"jump",
			"Caída pesada que castiga a rivales defensivos.",
			"Menor precisión y recuperación larga.",
			{
				"guard_bonus": 0.17,
				"movement": {
					"kind": "jump_down",
					"retreat": 8,
					"distance": 60,
					"height": 65
				},
				"recovery": 0.36
			}
		]
	],
	"vespera": [
		[
			"polvo",
			"Toque de polvo lunar",
			"quick",
			"Golpe veloz con buena precisión.",
			"Daño suave.",
			{
				"accuracy_modifier": 0.05
			}
		],
		[
			"vendaval",
			"Paso del vendaval",
			"dash",
			"Avanza con prioridad desde sus alas plegadas.",
			"Potencia limitada.",
			{
				"priority": 0.2,
				"damage_multiplier": 0.93
			}
		],
		[
			"orbita",
			"Órbita lunar",
			"jump",
			"Trayectoria aérea con más evasión y críticos.",
			"No garantiza el impacto.",
			{
				"airborne_evasion": 0.04,
				"critical_chance_modifier": 0.055,
				"movement": {
					"kind": "jump_over",
					"retreat": 0,
					"distance": 94,
					"height": 82
				}
			}
		],
		[
			"eclipse",
			"Velo del eclipse",
			"technique",
			"Puede reducir la precisión de quien la enfrenta.",
			"Efecto resistible y daño moderado.",
			{
				"damage_multiplier": 0.88,
				"status": {
					"type": "accuracy_down",
					"magnitude": 0.06,
					"duration": 2
				},
				"status_chance": 0.55
			}
		],
		[
			"luna",
			"Espera de la luna",
			"counter",
			"Espera y puede responder con sus antebrazos.",
			"Renuncia al golpe directo.",
			{
				"stance": {
					"reduction": 0.2,
					"chance": 0.39,
					"multiplier": 0.55,
					"duration": 1
				}
			}
		]
	],
	"balam": [
		[
			"garra",
			"Garra contenida",
			"quick",
			"Golpe corto y preciso para probar la guardia.",
			"Daño moderado.",
			{
				"damage_multiplier": 0.86,
				"accuracy_modifier": 0.04
			}
		],
		[
			"roca",
			"Peso del jaguar",
			"heavy",
			"Anticipa un golpe pesado que busca un crítico.",
			"Preparación visible y menor precisión.",
			{
				"damage_multiplier": 1.28,
				"critical_chance_modifier": 0.025,
				"recovery": 0.31
			}
		],
		[
			"emboscada",
			"Embestida del monte",
			"charge",
			"Retrocede, carga y golpea con ventaja contra guardias.",
			"Pierde defensa durante una acción tras cargar.",
			{
				"damage_multiplier": 1.39,
				"guard_bonus": 0.15,
				"self_status": {
					"type": "defense_down",
					"magnitude": 0.09,
					"duration": 1
				}
			}
		],
		[
			"acecho",
			"Acecho paciente",
			"technique",
			"Ataca con suavidad y prepara mejor puntería.",
			"Sacrifica daño inmediato.",
			{
				"damage_multiplier": 0.8,
				"self_status": {
					"type": "accuracy_up",
					"magnitude": 0.055,
					"duration": 2
				},
				"cooldown": 3
			}
		],
		[
			"salto",
			"Caída moteada",
			"jump",
			"Salta y cae buscando un crítico sobre la guardia.",
			"Trayectoria más lenta y precisión menor.",
			{
				"damage_multiplier": 1.16,
				"critical_chance_modifier": 0.065,
				"guard_bonus": 0.08,
				"movement": {
					"kind": "jump_down",
					"retreat": 6,
					"distance": 73,
					"height": 64
				},
				"recovery": 0.28
			}
		]
	],
	"tepa": [
		[
			"patita",
			"Patita fugaz",
			"quick",
			"Golpea antes con una recuperación muy breve.",
			"Potencia baja.",
			{
				"damage_multiplier": 0.8,
				"priority": 0.19,
				"recovery": 0.11
			}
		],
		[
			"zacaton",
			"Salto del zacatón",
			"jump",
			"Pasa por arriba y gana evasión mientras está en el aire.",
			"Menor puntería y un breve enfriamiento.",
			{
				"damage_multiplier": 1.07,
				"airborne_evasion": 0.05,
				"critical_chance_modifier": 0.015,
				"cooldown": 1,
				"movement": {
					"kind": "jump_over",
					"retreat": 0,
					"distance": 84,
					"height": 88
				}
			}
		],
		[
			"carrera",
			"Carrera cruzada",
			"dash",
			"Atraviesa un espacio corto con prioridad y buena puntería.",
			"No golpea tan fuerte como un ataque pesado.",
			{
				"damage_multiplier": 0.9,
				"priority": 0.2,
				"accuracy_modifier": 0.04
			}
		],
		[
			"volcan",
			"Brinco del volcán",
			"jump",
			"Cae de arriba y castiga a un rival en guardia.",
			"Requiere recuperar el equilibrio al aterrizar.",
			{
				"damage_multiplier": 1.18,
				"guard_bonus": 0.16,
				"airborne_evasion": 0.035,
				"cooldown": 3,
				"movement": {
					"kind": "jump_down",
					"retreat": 3,
					"distance": 68,
					"height": 76
				},
				"recovery": 0.29
			}
		],
		[
			"polvo",
			"Polvo del sendero",
			"technique",
			"Puede ralentizar al rival antes del próximo salto.",
			"Poco daño; la lentitud es resistible.",
			{
				"damage_multiplier": 0.79,
				"status": {
					"type": "slow",
					"magnitude": 0.14,
					"duration": 2
				},
				"status_chance": 0.5,
				"cooldown": 3
			}
		]
	],
	"xuna": [
		[
			"colmillo",
			"Colmillo sereno",
			"quick",
			"Ataque sencillo y certero para mantener presencia.",
			"Menor explosividad.",
			{
				"damage_multiplier": 0.89,
				"priority": 0.08,
				"accuracy_modifier": 0.04
			}
		],
		[
			"umbral",
			"Guardia del umbral",
			"guard",
			"Absorbe parte del siguiente intercambio y mantiene la posición.",
			"Renuncia a atacar y no provoca una réplica automática.",
			{
				"stance": {
					"reduction": 0.3,
					"chance": 0,
					"multiplier": 0,
					"duration": 1
				},
				"weight": 0.48
			}
		],
		[
			"brasa",
			"Brasa persistente",
			"technique",
			"Puede dejar una quemadura breve que escala con Ataque.",
			"El efecto puede resistirse.",
			{
				"damage_multiplier": 0.86,
				"status": {
					"type": "burn",
					"magnitude": 2.5,
					"duration": 2,
					"scaling_stat": "attack",
					"scaling_base": 19.5
				},
				"status_chance": 0.5,
				"cooldown": 2
			}
		],
		[
			"piedra",
			"Paso de piedra",
			"heavy",
			"Golpe pesado que ignora parte de la armadura.",
			"Velocidad menor y preparación visible.",
			{
				"damage_multiplier": 1.27,
				"armor_ignore": 0.1
			}
		],
		[
			"vigilia",
			"Carga de vigilia",
			"charge",
			"Prepara una carga que puede reducir el ataque enemigo.",
			"Menor precisión y recuperación larga.",
			{
				"damage_multiplier": 1.32,
				"status": {
					"type": "attack_down",
					"magnitude": 0.1,
					"duration": 2
				},
				"status_chance": 0.5,
				"recovery": 0.35
			}
		]
	],
	"copal": [
		[
			"finta",
			"Finta anillada",
			"quick",
			"Un golpe corto y preciso entre cambios de dirección.",
			"Daño contenido.",
			{
				"damage_multiplier": 0.83,
				"accuracy_modifier": 0.055
			}
		],
		[
			"rama",
			"Paso entre ramas",
			"dash",
			"Se adelanta con una carrera rápida y corta.",
			"Poca anticipación pero daño moderado.",
			{
				"damage_multiplier": 0.93,
				"priority": 0.18
			}
		],
		[
			"espera",
			"Espera del cacomixtle",
			"counter",
			"Toma una postura para reducir daño y quizá responder.",
			"Cede un ataque y la respuesta puede no ocurrir.",
			{
				"stance": {
					"reduction": 0.18,
					"chance": 0.38,
					"multiplier": 0.52,
					"duration": 1
				},
				"weight": 0.65
			}
		],
		[
			"distraccion",
			"Sombra inquieta",
			"technique",
			"Una finta puede reducir la precisión del rival.",
			"Sacrifica daño y el efecto es resistible.",
			{
				"damage_multiplier": 0.82,
				"status": {
					"type": "accuracy_down",
					"magnitude": 0.07,
					"duration": 2
				},
				"status_chance": 0.55
			}
		],
		[
			"rodeo",
			"Rodeo de la rama",
			"jump",
			"Pasa por arriba buscando un ángulo que ignore algo de armadura.",
			"Menor precisión durante el salto.",
			{
				"damage_multiplier": 1.07,
				"armor_ignore": 0.12,
				"critical_chance_modifier": 0.035,
				"movement": {
					"kind": "jump_over",
					"retreat": 0,
					"distance": 92,
					"height": 70
				}
			}
		]
	],
	"onix": [
		[
			"roce",
			"Roce de sombra",
			"quick",
			"Golpe corto con iniciativa alta.",
			"Potencia reducida por impacto.",
			{
				"damage_multiplier": 0.81,
				"priority": 0.2,
				"accuracy_modifier": 0.045
			}
		],
		[
			"alero",
			"Carrera del alero",
			"dash",
			"Cruza la distancia con pasos rápidos.",
			"Daño contenido y un turno de enfriamiento.",
			{
				"damage_multiplier": 0.9,
				"priority": 0.23,
				"movement": {
					"kind": "dash",
					"retreat": 0,
					"distance": 76,
					"height": 0
				}
			}
		],
		[
			"tejadillo",
			"Salto del tejadillo",
			"jump",
			"Gana evasión durante el salto y busca un ángulo crítico.",
			"Pierde puntería al despegar.",
			{
				"damage_multiplier": 1.08,
				"airborne_evasion": 0.045,
				"critical_chance_modifier": 0.045,
				"movement": {
					"kind": "jump_over",
					"retreat": 0,
					"distance": 88,
					"height": 62
				}
			}
		],
		[
			"parpadeo",
			"Parpadeo amarillo",
			"technique",
			"Una finta puede reducir la precisión rival.",
			"Golpe suave y efecto resistible.",
			{
				"damage_multiplier": 0.81,
				"status": {
					"type": "accuracy_down",
					"magnitude": 0.08,
					"duration": 2
				},
				"status_chance": 0.55
			}
		],
		[
			"azotea",
			"Caída de azotea",
			"heavy",
			"Un golpe más fuerte para cerrar una oportunidad.",
			"Preparación visible y acierto menos seguro.",
			{
				"damage_multiplier": 1.24,
				"accuracy_modifier": -0.045,
				"windup": 0.3,
				"recovery": 0.27
			}
		]
	],
	"bruma": [
		[
			"tacto",
			"Tacto certero",
			"quick",
			"Un golpe medido con buena puntería.",
			"Potencia contenida.",
			{
				"damage_multiplier": 0.88,
				"accuracy_modifier": 0.065,
				"priority": 0.12
			}
		],
		[
			"escucha",
			"Escucha paciente",
			"counter",
			"Reduce el daño de un intercambio y puede responder.",
			"Cede su ataque y la respuesta no está garantizada.",
			{
				"stance": {
					"reduction": 0.22,
					"chance": 0.42,
					"multiplier": 0.55,
					"duration": 1
				},
				"weight": 0.5
			}
		],
		[
			"peso",
			"Peso de la calma",
			"heavy",
			"Concentra un golpe firme sin perder tanta puntería.",
			"Preparación y recuperación más largas.",
			{
				"damage_multiplier": 1.25,
				"accuracy_modifier": -0.025
			}
		],
		[
			"ovillo",
			"Guardia de ovillo",
			"guard",
			"Se protege y recupera el 2.5% de su vida máxima.",
			"No ataca y debe esperar cuatro turnos para repetir.",
			{
				"heal_fraction": 0.025,
				"cooldown": 4,
				"stance": {
					"reduction": 0.32,
					"chance": 0,
					"multiplier": 0,
					"duration": 1
				},
				"weight": 0.48
			}
		],
		[
			"niebla",
			"Paso de niebla",
			"technique",
			"Puede reducir la potencia del siguiente intercambio rival.",
			"Menor daño directo y efecto resistible.",
			{
				"damage_multiplier": 0.87,
				"status": {
					"type": "attack_down",
					"magnitude": 0.12,
					"duration": 2
				},
				"status_chance": 0.5
			}
		]
	]
}

const CHARACTER_PERKS: Dictionary = {
	"balam": [
		{
			"id": "balam_emboscada",
			"name": "Carga medida",
			"description": "Sus cargas ganan +7% al multiplicador y 1.5 puntos de prioridad.",
			"benefit": "Sus cargas ganan +7% al multiplicador y 1.5 puntos de prioridad.",
			"cost": 1,
			"types": [
				"charge"
			],
			"modifiers": {
				"damage_multiplier": 0.07,
				"priority": 0.015
			}
		},
		{
			"id": "balam_lectura",
			"name": "Lectura del monte",
			"description": "Sus ataques ganan 2.5 puntos de precisión.",
			"benefit": "Sus ataques ganan 2.5 puntos de precisión.",
			"cost": 1,
			"types": [],
			"modifiers": {
				"accuracy_modifier": 0.025
			}
		},
		{
			"id": "balam_colmillada",
			"name": "Instante moteado",
			"description": "Cargas y saltos ganan 3.5 puntos de probabilidad crítica.",
			"benefit": "Cargas y saltos ganan 3.5 puntos de probabilidad crítica.",
			"cost": 1,
			"types": [
				"charge",
				"jump"
			],
			"modifiers": {
				"critical_chance_modifier": 0.035
			}
		},
		{
			"id": "balam_sigilo",
			"name": "Acecho prolongado",
			"description": "El enfoque de Acecho paciente dura una acción adicional.",
			"benefit": "El enfoque de Acecho paciente dura una acción adicional.",
			"cost": 1,
			"types": [
				"technique"
			],
			"modifiers": {
				"status_duration": 1
			}
		},
		{
			"id": "balam_temple",
			"name": "Temple del jaguar",
			"description": "Reduce un 10% el daño adicional de los críticos recibidos.",
			"benefit": "Reduce un 10% el daño adicional de los críticos recibidos.",
			"cost": 1,
			"types": [],
			"modifiers": {},
			"runtime": {
				"critical_reduction": 0.1
			}
		},
		{
			"id": "balam_retirada",
			"name": "Retirada entre hojas",
			"description": "Bajo el 35% de vida gana 2.5 puntos de evasión.",
			"benefit": "Bajo el 35% de vida gana 2.5 puntos de evasión.",
			"cost": 1,
			"types": [],
			"modifiers": {},
			"below_hp": 0.35,
			"runtime": {
				"evasion": 0.025
			}
		}
	],
	"tepa": [
		{
			"id": "tepa_impulso",
			"name": "Impulso de la ladera",
			"description": "Sus saltos ganan +6% al multiplicador y 2 puntos de prioridad.",
			"benefit": "Sus saltos ganan +6% al multiplicador y 2 puntos de prioridad.",
			"cost": 1,
			"types": [
				"jump"
			],
			"modifiers": {
				"damage_multiplier": 0.06,
				"priority": 0.02
			}
		},
		{
			"id": "tepa_aterrizaje",
			"name": "Aterrizaje preciso",
			"description": "Sus saltos ganan 4 puntos de precisión.",
			"benefit": "Sus saltos ganan 4 puntos de precisión.",
			"cost": 1,
			"types": [
				"jump"
			],
			"modifiers": {
				"accuracy_modifier": 0.04
			}
		},
		{
			"id": "tepa_aire",
			"name": "Entre el zacatón",
			"description": "Gana 1.5 puntos adicionales de evasión durante sus saltos.",
			"benefit": "Gana 1.5 puntos adicionales de evasión durante sus saltos.",
			"cost": 1,
			"types": [
				"jump"
			],
			"modifiers": {
				"airborne_evasion": 0.015
			}
		},
		{
			"id": "tepa_carrera",
			"name": "Carrera de vuelta",
			"description": "Ataques rápidos y desplazamientos ganan 4 puntos de prioridad y recuperan 0.025 s antes.",
			"benefit": "Ataques rápidos y desplazamientos ganan 4 puntos de prioridad y recuperan 0.025 s antes.",
			"cost": 1,
			"types": [
				"quick",
				"dash"
			],
			"modifiers": {
				"priority": 0.04,
				"recovery": -0.025
			}
		},
		{
			"id": "tepa_firmeza",
			"name": "Pequeña firmeza",
			"description": "Reduce un 10% el daño adicional de los críticos recibidos.",
			"benefit": "Reduce un 10% el daño adicional de los críticos recibidos.",
			"cost": 1,
			"types": [],
			"modifiers": {},
			"runtime": {
				"critical_reduction": 0.1
			}
		},
		{
			"id": "tepa_refugio",
			"name": "Último refugio",
			"description": "Bajo el 35% de vida gana 2.5 puntos de evasión.",
			"benefit": "Bajo el 35% de vida gana 2.5 puntos de evasión.",
			"cost": 1,
			"types": [],
			"modifiers": {},
			"below_hp": 0.35,
			"runtime": {
				"evasion": 0.025
			}
		}
	],
	"xuna": [
		{
			"id": "xuna_ceniza",
			"name": "Brasas que perduran",
			"description": "Los efectos de sus técnicas y cargas duran una acción adicional.",
			"benefit": "Los efectos de sus técnicas y cargas duran una acción adicional.",
			"cost": 1,
			"types": [
				"technique",
				"charge"
			],
			"modifiers": {
				"status_duration": 1
			}
		},
		{
			"id": "xuna_colmillo",
			"name": "Colmillo certero",
			"description": "Ataques rápidos y pesados ganan 3.5 puntos de precisión.",
			"benefit": "Ataques rápidos y pesados ganan 3.5 puntos de precisión.",
			"cost": 1,
			"types": [
				"quick",
				"heavy"
			],
			"modifiers": {
				"accuracy_modifier": 0.035
			}
		},
		{
			"id": "xuna_vigilia",
			"name": "Vigilia serena",
			"description": "Su guardia gana 8 puntos de prioridad y recupera 0.04 s antes.",
			"benefit": "Su guardia gana 8 puntos de prioridad y recupera 0.04 s antes.",
			"cost": 1,
			"types": [
				"guard"
			],
			"modifiers": {
				"priority": 0.08,
				"recovery": -0.04
			}
		},
		{
			"id": "xuna_temple",
			"name": "Calma del camino",
			"description": "Reduce un 12% adicional del daño extra de los críticos recibidos.",
			"benefit": "Reduce un 12% adicional del daño extra de los críticos recibidos.",
			"cost": 1,
			"types": [],
			"modifiers": {},
			"runtime": {
				"critical_reduction": 0.12
			}
		},
		{
			"id": "xuna_refugio",
			"name": "Paso al refugio",
			"description": "Bajo el 35% de vida gana 2.5 puntos de evasión.",
			"benefit": "Bajo el 35% de vida gana 2.5 puntos de evasión.",
			"cost": 1,
			"types": [],
			"modifiers": {},
			"below_hp": 0.35,
			"runtime": {
				"evasion": 0.025
			}
		},
		{
			"id": "xuna_firmeza",
			"name": "Paso firme",
			"description": "Los golpes pesados ganan 5 puntos de prioridad y 1.5 puntos de precisión.",
			"benefit": "Los golpes pesados ganan 5 puntos de prioridad y 1.5 puntos de precisión.",
			"cost": 1,
			"types": [
				"heavy"
			],
			"modifiers": {
				"priority": 0.05,
				"accuracy_modifier": 0.015
			}
		}
	],
	"copal": [
		{
			"id": "copal_replica",
			"name": "Réplica medida",
			"description": "Sus posturas ganan 5.5 puntos de probabilidad de respuesta.",
			"benefit": "Sus posturas ganan 5.5 puntos de probabilidad de respuesta.",
			"cost": 1,
			"types": [
				"counter"
			],
			"modifiers": {
				"counter_chance": 0.055
			}
		},
		{
			"id": "copal_circulo",
			"name": "Círculo veloz",
			"description": "Sus desplazamientos ganan 3.5 puntos de precisión.",
			"benefit": "Sus desplazamientos ganan 3.5 puntos de precisión.",
			"cost": 1,
			"types": [
				"dash"
			],
			"modifiers": {
				"accuracy_modifier": 0.035
			}
		},
		{
			"id": "copal_respuesta",
			"name": "Respuesta anillada",
			"description": "Sus posturas ganan +6% al multiplicador de réplica y 2 puntos de prioridad.",
			"benefit": "Sus posturas ganan +6% al multiplicador de réplica y 2 puntos de prioridad.",
			"cost": 1,
			"types": [
				"counter"
			],
			"modifiers": {
				"damage_multiplier": 0.06,
				"priority": 0.02
			}
		},
		{
			"id": "copal_sombra",
			"name": "Sombra persistente",
			"description": "La reducción de precisión de sus técnicas dura una acción adicional.",
			"benefit": "La reducción de precisión de sus técnicas dura una acción adicional.",
			"cost": 1,
			"types": [
				"technique"
			],
			"modifiers": {
				"status_duration": 1
			}
		},
		{
			"id": "copal_ritmo",
			"name": "Dos pasos adelante",
			"description": "Sus ataques rápidos ganan 4 puntos de prioridad y recuperan 0.025 s antes.",
			"benefit": "Sus ataques rápidos ganan 4 puntos de prioridad y recuperan 0.025 s antes.",
			"cost": 1,
			"types": [
				"quick"
			],
			"modifiers": {
				"priority": 0.04,
				"recovery": -0.025
			}
		},
		{
			"id": "copal_refugio",
			"name": "Giro de regreso",
			"description": "Bajo el 35% de vida gana 2.5 puntos de evasión.",
			"benefit": "Bajo el 35% de vida gana 2.5 puntos de evasión.",
			"cost": 1,
			"types": [],
			"modifiers": {},
			"below_hp": 0.35,
			"runtime": {
				"evasion": 0.025
			}
		}
	],
	"onix": [
		{
			"id": "onix_ritmo",
			"name": "Pulso del tejado",
			"description": "Sus ataques rápidos ganan +6% al multiplicador y 2 puntos de prioridad.",
			"benefit": "Sus ataques rápidos ganan +6% al multiplicador y 2 puntos de prioridad.",
			"cost": 1,
			"types": [
				"quick"
			],
			"modifiers": {
				"damage_multiplier": 0.06,
				"priority": 0.02
			}
		},
		{
			"id": "onix_ligero",
			"name": "Paso ligero",
			"description": "Sus carreras y saltos ganan 3 puntos de prioridad y recuperan 0.025 s antes.",
			"benefit": "Sus carreras y saltos ganan 3 puntos de prioridad y recuperan 0.025 s antes.",
			"cost": 1,
			"types": [
				"dash",
				"jump"
			],
			"modifiers": {
				"priority": 0.03,
				"recovery": -0.025
			}
		},
		{
			"id": "onix_mirada",
			"name": "Ojos en la noche",
			"description": "Sus ataques ganan 2.5 puntos de precisión.",
			"benefit": "Sus ataques ganan 2.5 puntos de precisión.",
			"cost": 1,
			"types": [],
			"modifiers": {
				"accuracy_modifier": 0.025
			}
		},
		{
			"id": "onix_silencio",
			"name": "Salto silencioso",
			"description": "Sus saltos ganan 3.5 puntos de crítico y 1.5 puntos de evasión aérea.",
			"benefit": "Sus saltos ganan 3.5 puntos de crítico y 1.5 puntos de evasión aérea.",
			"cost": 1,
			"types": [
				"jump"
			],
			"modifiers": {
				"critical_chance_modifier": 0.035,
				"airborne_evasion": 0.015
			}
		},
		{
			"id": "onix_temple",
			"name": "Temple de ónix",
			"description": "Reduce un 10% del daño adicional de los críticos recibidos.",
			"benefit": "Reduce un 10% del daño adicional de los críticos recibidos.",
			"cost": 1,
			"types": [],
			"modifiers": {},
			"runtime": {
				"critical_reduction": 0.1
			}
		},
		{
			"id": "onix_ultima_sombra",
			"name": "Última sombra",
			"description": "Bajo el 35% de vida gana 2.5 puntos de evasión, dentro del límite.",
			"benefit": "Bajo el 35% de vida gana 2.5 puntos de evasión, dentro del límite.",
			"cost": 1,
			"types": [],
			"modifiers": {},
			"below_hp": 0.35,
			"runtime": {
				"evasion": 0.025
			}
		}
	],
	"bruma": [
		{
			"id": "bruma_respuesta",
			"name": "Réplica serena",
			"description": "Sus posturas de respuesta ganan 5 puntos de probabilidad de réplica.",
			"benefit": "Sus posturas de respuesta ganan 5 puntos de probabilidad de réplica.",
			"cost": 1,
			"types": [
				"counter"
			],
			"modifiers": {
				"counter_chance": 0.05
			}
		},
		{
			"id": "bruma_firme",
			"name": "Pata firme",
			"description": "Sus golpes pesados ganan +6% al multiplicador y 2 puntos de precisión.",
			"benefit": "Sus golpes pesados ganan +6% al multiplicador y 2 puntos de precisión.",
			"cost": 1,
			"types": [
				"heavy"
			],
			"modifiers": {
				"damage_multiplier": 0.06,
				"accuracy_modifier": 0.02
			}
		},
		{
			"id": "bruma_observacion",
			"name": "Observación verde",
			"description": "Sus ataques ganan 2.5 puntos de precisión.",
			"benefit": "Sus ataques ganan 2.5 puntos de precisión.",
			"cost": 1,
			"types": [],
			"modifiers": {
				"accuracy_modifier": 0.025
			}
		},
		{
			"id": "bruma_reposo",
			"name": "Reposo atento",
			"description": "Su guardia cura 1 punto porcentual adicional de vida y recupera 0.025 s antes.",
			"benefit": "Su guardia cura 1 punto porcentual adicional de vida y recupera 0.025 s antes.",
			"cost": 1,
			"types": [
				"guard"
			],
			"modifiers": {
				"heal_fraction": 0.01,
				"recovery": -0.025
			}
		},
		{
			"id": "bruma_temple",
			"name": "Temple de niebla",
			"description": "Reduce un 10% del daño adicional de los críticos recibidos.",
			"benefit": "Reduce un 10% del daño adicional de los críticos recibidos.",
			"cost": 1,
			"types": [],
			"modifiers": {},
			"runtime": {
				"critical_reduction": 0.1
			}
		},
		{
			"id": "bruma_eco",
			"name": "Eco apacible",
			"description": "El debilitamiento de su técnica dura una acción adicional, dentro del límite.",
			"benefit": "El debilitamiento de su técnica dura una acción adicional, dentro del límite.",
			"cost": 1,
			"types": [
				"technique"
			],
			"modifiers": {
				"status_duration": 1
			}
		}
	]
}

static func moves_for(character_id: String) -> Array[Dictionary]:
	if _move_cache.has(character_id):
		var copy: Array[Dictionary] = []
		copy.assign(_move_cache[character_id].duplicate(true))
		return copy
	var result: Array[Dictionary] = []
	var rows: Array = DATA.get(character_id,[])
	for index in range(rows.size()):
		var row: Array = rows[index]
		var move: Dictionary = {
			"id":character_id+"_"+str(row[0]),"name":str(row[1]),"type":str(row[2]),
			"description":str(row[3])+" "+str(row[4]),"purpose":str(row[3]),"risk":str(row[4]),
			"unlock_level":UNLOCK_LEVELS[index],"max_tier":MAX_TIER,"cost":UPGRADE_COST,
			"upgrade_description":"+3.5% al multiplicador, +0.8 puntos de precisión y recuperación 0.012 s menor por grado.",
			"base_damage":0.0,"critical_chance_modifier":0.0,"critical_damage_modifier":0.0,
			"armor_ignore":0.0,"guard_bonus":0.0,"airborne_evasion":0.0,"heal_fraction":0.0,
			"status":{},"self_status":{},"status_chance":0.0,"stance":{},
			"animation_type":str(row[2]),"movement":MOVEMENT[str(row[2])].duplicate(true),"tier":0}
		move.merge(TYPES[str(row[2])],true)
		move.merge(row[5],true)
		if str(move.type) in ["guard","counter"]:
			move.upgrade_description = "+1 punto de reducción de daño, +2% al multiplicador de réplica si la tiene y recuperación 0.012 s menor por grado."
		result.append(bound_move(move))
	_move_cache[character_id] = result.duplicate(true)
	return result

static func unlocked_moves(character_id: String, level: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for move: Dictionary in moves_for(character_id):
		if int(move.unlock_level)<=level: result.append(move)
	return result

static func perks_for(character_id: String) -> Array[Dictionary]:
	if _perk_cache.has(character_id):
		var copy: Array[Dictionary] = []
		copy.assign(_perk_cache[character_id].duplicate(true))
		return copy
	if not DATA.has(character_id): return []
	if CHARACTER_PERKS.has(character_id):
		var themed: Array[Dictionary] = []
		themed.assign(CHARACTER_PERKS[character_id].duplicate(true))
		_perk_cache[character_id] = themed.duplicate(true)
		return themed
	var specialist: String = {"nima":"dash","luma":"technique","mugo":"heavy","sira":"jump","iria":"technique","duna":"charge","kiro":"charge","neris":"jump","taro":"counter","ascua":"heavy","vespera":"jump"}.get(character_id,"quick")
	var label: String = {"quick":"golpes rápidos","dash":"desplazamientos","heavy":"golpes pesados","charge":"cargas","jump":"saltos","technique":"técnicas","guard":"guardias","counter":"contraataques"}.get(specialist,specialist)
	var identity: String = character_id.capitalize()
	var mastery: Dictionary = {"id":character_id+"_mastery","name":"Instinto de "+identity,"cost":1,"types":[specialist],"modifiers":{"critical_chance_modifier":0.035},"description":"Sus "+label+" ganan 3.5 puntos de probabilidad crítica, dentro del límite.","benefit":"+3.5 puntos de crítico en "+label}
	if specialist=="counter":
		mastery.merge({"modifiers":{"counter_chance":0.055},"description":"Sus posturas ganan 5.5 puntos de probabilidad de respuesta, dentro del límite.","benefit":"+5.5 puntos de respuesta"},true)
	elif character_id in ["iria","luma"]:
		mastery.merge({"modifiers":{"status_duration":1},"description":"Los efectos de sus técnicas duran una acción adicional; la resistencia y el límite siguen vigentes.","benefit":"+1 acción a efectos de técnicas"},true)
	var result: Array[Dictionary] = [
		{"id":character_id+"_momentum","name":"Ritmo de "+identity,"description":"Refuerza sus "+label+" con +6% al multiplicador y +2 puntos de prioridad.","benefit":"+6% al multiplicador y +2 puntos de prioridad","cost":1,"types":[specialist],"modifiers":{"damage_multiplier":0.06,"priority":0.02}},
		{"id":character_id+"_focus","name":"Lectura de "+identity,"description":"Sus ataques ganan 2.5 puntos de precisión; mantiene los límites normales.","benefit":"+2.5 puntos de precisión","cost":1,"types":[],"modifiers":{"accuracy_modifier":0.025}},
		mastery,
		{"id":character_id+"_tempo","name":"Paso de "+identity,"description":"Sus ataques rápidos ganan 5 puntos de prioridad y recuperan 0.025 s antes.","benefit":"Más iniciativa en ataques rápidos","cost":1,"types":["quick","dash"],"modifiers":{"priority":0.05,"recovery":-0.025}},
		{"id":character_id+"_resilience","name":"Temple de "+identity,"description":"Reduce un 10% del daño adicional de los críticos recibidos. No reduce el golpe normal.","benefit":"−10% del extra crítico recibido","cost":1,"types":[],"modifiers":{},"runtime":{"critical_reduction":0.10}},
		{"id":character_id+"_instinct","name":"Instinto de supervivencia","description":"Bajo el 35% de vida gana 2.5 puntos de evasión, respetando el límite normal.","benefit":"+2.5 puntos de evasión bajo 35% de vida","cost":1,"types":[],"modifiers":{},"below_hp":0.35,"runtime":{"evasion":0.025}}]
	_perk_cache[character_id] = result.duplicate(true)
	return result

static func passive_bonuses(character_id: String, selected: Array, hp_ratio: float) -> Dictionary:
	var result: Dictionary = {"evasion":0.0,"critical_reduction":0.0}
	var used := 0
	for perk: Dictionary in perks_for(character_id):
		if not str(perk.id) in selected: continue
		used += 1
		if used>3 or hp_ratio>float(perk.get("below_hp",1.0)): continue
		for key: String in perk.get("runtime",{}):
			result[key] = float(result.get(key,0.0))+float(perk.runtime[key])
	return result

static func resolve_move(character_id: String, move_id: String, tier: int = 0, perks: Array = []) -> Dictionary:
	for move: Dictionary in moves_for(character_id):
		if str(move.id)==move_id: return improve_move(character_id,move,tier,perks)
	return {}

static func improve_move(character_id: String, definition: Dictionary, tier: int = 0, perks: Array = []) -> Dictionary:
	var result: Dictionary = definition.duplicate(true)
	var safe_tier: int = clampi(tier,0,MAX_TIER)
	result["tier"] = safe_tier
	if float(result.get("damage_multiplier",0.0))>0:
		result["damage_multiplier"] = float(result.damage_multiplier)+float(CONFIG.damage_per_tier)*safe_tier
	if not result.get("stance",{}).is_empty():
		result.stance["reduction"] = float(result.stance.get("reduction",0.0))+0.01*safe_tier
		if float(result.stance.get("multiplier",0.0))>0:
			result.stance["multiplier"] = float(result.stance.multiplier)+0.02*safe_tier
	result["accuracy_modifier"] = float(result.get("accuracy_modifier",0.0))+float(CONFIG.accuracy_per_tier)*safe_tier
	result["recovery"] = float(result.get("recovery",0.2))-float(CONFIG.recovery_per_tier)*safe_tier
	var perk_count := 0
	for perk: Dictionary in perks_for(character_id):
		if not str(perk.id) in perks: continue
		perk_count += 1
		if perk_count>3: continue
		if not perk.types.is_empty() and not str(result.type) in perk.types: continue
		for key: String in perk.modifiers:
			var amount: float = float(perk.modifiers[key])
			if key=="status_duration":
				for effect_key: String in ["status","self_status"]:
					if not result.get(effect_key,{}).is_empty():
						result[effect_key]["duration"] = int(result[effect_key].get("duration",1))+int(amount)
			elif key=="counter_chance":
				if not result.get("stance",{}).is_empty():
					result.stance["chance"] = float(result.stance.get("chance",0.0))+amount
			elif key=="damage_multiplier" and str(result.type)=="counter":
				result.stance["multiplier"] = float(result.stance.get("multiplier",0.0))+amount
			elif key!="damage_multiplier" or float(result.get("damage_multiplier",0.0))>0:
				result[key] = float(result.get(key,0.0))+amount
	return bound_move(result)

static func bound_move(raw: Dictionary) -> Dictionary:
	var result: Dictionary = raw.duplicate(true)
	for key: String in ["damage_multiplier","base_damage","accuracy_modifier","priority","critical_chance_modifier","critical_damage_modifier","armor_ignore","guard_bonus","airborne_evasion","heal_fraction","status_chance","windup","travel","recovery","weight"]:
		var value: Variant = result.get(key,0.0)
		result[key] = float(value) if (value is int or value is float) and is_finite(float(value)) else 0.0
	result["damage_multiplier"] = clampf(result.damage_multiplier,0.0,float(CONFIG.max_damage_multiplier))
	result["base_damage"] = clampf(result.base_damage,0.0,8.0)
	result["accuracy_modifier"] = clampf(result.accuracy_modifier,-0.15,float(CONFIG.max_accuracy_modifier))
	result["priority"] = clampf(result.priority,-float(CONFIG.max_priority),float(CONFIG.max_priority))
	result["critical_chance_modifier"] = clampf(result.critical_chance_modifier,-0.10,0.12)
	result["critical_damage_modifier"] = clampf(result.critical_damage_modifier,-0.10,0.20)
	result["armor_ignore"] = clampf(result.armor_ignore,0.0,float(CONFIG.max_armor_ignore))
	result["guard_bonus"] = clampf(result.guard_bonus,0.0,0.20)
	result["airborne_evasion"] = clampf(result.airborne_evasion,0.0,0.07)
	result["heal_fraction"] = clampf(result.heal_fraction,0.0,float(CONFIG.max_heal_fraction))
	result["status_chance"] = clampf(result.status_chance,0.0,1.0)
	result["windup"] = clampf(result.windup,0.035,0.65)
	result["travel"] = clampf(result.travel,0.0,0.40)
	result["recovery"] = clampf(result.recovery,0.06,0.45)
	result["weight"] = clampf(result.weight,0.01,8.0)
	result["cooldown"] = clampi(int(result.get("cooldown",0)),0,6)
	result["impact_delay"] = float(result.windup)+float(result.travel)
	result["duration"] = float(result.impact_delay)+float(result.recovery)
	for key: String in ["stance","status","self_status"]:
		result[key] = result.get(key,{}) if result.get(key,{}) is Dictionary else {}
	result["movement"] = result.get("movement",MOVEMENT.quick) if result.get("movement",{}) is Dictionary else MOVEMENT.quick.duplicate(true)
	result["status_duration"] = int(result.get("status",{}).get("duration",0))
	if not result.stance.is_empty():
		result.stance["reduction"] = clampf(float(result.stance.get("reduction",0.0)),0.0,float(CONFIG.max_guard_reduction))
		result.stance["chance"] = clampf(float(result.stance.get("chance",0.0)),0.0,float(CONFIG.max_counter_chance))
		result.stance["multiplier"] = clampf(float(result.stance.get("multiplier",0.0)),0.0,0.80)
		result.stance["duration"] = clampi(int(result.stance.get("duration",1)),1,2)
	return result
