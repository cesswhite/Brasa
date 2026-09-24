class_name CharacterCatalog
extends RefCounted
## Definiciones originales: toda diferencia de combate nace de estos datos.
const Balance = preload("res://scripts/balance.gd")
const IDS: Array[String] = ["nima", "luma", "mugo", "sira", "iria", "duna", "kiro", "neris", "taro", "balam", "tepa", "xuna", "copal", "onix", "bruma"]
const STAT_HELP: Dictionary = {
	"max_hp": {"name": "Vida", "description": "Daño que puedes soportar. Entrenar Vida añade 20 PV por punto.", "range": "100–2000 PV", "format": "integer"},
	"attack": {"name": "Ataque", "description": "Potencia antes de defensa, habilidades y variación de ±8%. Fuerza añade 1.5 por punto.", "range": "5–150", "format": "decimal"},
	"defense": {"name": "Defensa", "description": "Reduce daño con rendimiento decreciente: daño × 100 / (100 + defensa).", "range": "0–160", "format": "decimal"},
	"speed": {"name": "Velocidad", "description": "Reduce el intervalo entre ataques: 2.4 / (1 + velocidad × 0.035) segundos.", "range": "1–36", "format": "decimal"},
	"accuracy": {"name": "Precisión", "description": "Se enfrenta a la evasión rival. La probabilidad final de acertar queda entre 62% y 96%.", "range": "65–114%; acierto máximo 96%", "format": "percent"},
	"evasion": {"name": "Evasión", "description": "Reduce la probabilidad de que el rival conecte. Agilidad añade 0.7 puntos porcentuales por punto.", "range": "0–30%", "format": "percent"},
	"crit_chance": {"name": "Crítico", "description": "Probabilidad de crítico al acertar. Agilidad añade 0.8 puntos porcentuales por punto.", "range": "3–32%", "format": "percent"},
	"crit_damage": {"name": "Daño crítico", "description": "Multiplicador de los golpes críticos. No se combina con el Golpe de Firma.", "range": "×1.2–×2.1", "format": "multiplier"},
	"resistance": {"name": "Resistencia", "description": "Reduce aplicación o duración de estados negativos. La Firma siempre aplica al menos un turno.", "range": "0–50%", "format": "percent"},
}
const DEFINITIONS: Array[Dictionary] = [
	{
		"id": "nima", "name": "Nima", "archetype": 0, "role": "Velocidad · combos",
		"personality": "Impaciente y leal; siempre llega antes que la tormenta.",
		"strengths": "Ataca seguido y encadena golpes más fuertes.", "weaknesses": "Poca defensa; sufre ante contraataques.",
		"base_stats": {"max_hp": 238.0, "attack": 20.0, "defense": 16.0, "speed": 9.0, "accuracy": 0.94, "evasion": 0.13, "crit_chance": 0.10, "crit_damage": 1.5, "resistance": 0.08},
		"growth": {"max_hp": 7.0, "attack": 0.65, "defense": 0.5, "speed": 0.15, "accuracy": 0.0008, "evasion": 0.0008, "crit_chance": 0.0008, "crit_damage": 0.003, "resistance": 0.001},
		"training_base": {"life": 6, "strength": 6, "agility": 4, "speed": 8},
		"ability": {"id": "combo", "name": "Paso de tres", "description": "Cada tercer ataque hace ×1.3 de daño si conecta.", "every": 3, "multiplier": 1.3},
		"signature": {"name": "Cometa de arena", "effect": "slow", "magnitude": 0.22, "duration": 3, "damage_multiplier": 1.6, "description": "Golpe certero ×1.6 y velocidad rival −22% durante 3 turnos."},
		"visual": {"archetype": 0, "tint": "ffffff"},
	},
	{
		"id": "luma", "name": "Luma", "archetype": 1, "role": "Equilibrio · adaptación",
		"personality": "Curiosa y serena: cada error le enseña otra manera.",
		"strengths": "Estadísticas equilibradas y puntería que se adapta.", "weaknesses": "Sin una especialidad explosiva; cede ante presión constante.",
		"base_stats": {"max_hp": 250.0, "attack": 22.0, "defense": 20.0, "speed": 6.0, "accuracy": 0.96, "evasion": 0.10, "crit_chance": 0.12, "crit_damage": 1.55, "resistance": 0.12},
		"growth": {"max_hp": 8.0, "attack": 0.65, "defense": 0.65, "speed": 0.10, "accuracy": 0.001, "evasion": 0.0006, "crit_chance": 0.0008, "crit_damage": 0.003, "resistance": 0.0015},
		"training_base": {"life": 6, "strength": 6, "agility": 6, "speed": 6},
		"ability": {"id": "adapt", "name": "Aprender del río", "description": "Tras fallar, gana 10 puntos de precisión durante 2 turnos.", "accuracy_bonus": 0.10, "duration": 2},
		"signature": {"name": "Marea de luna", "effect": "accuracy_down", "magnitude": 0.15, "duration": 3, "damage_multiplier": 1.6, "description": "Golpe certero ×1.6 y precisión rival −15 puntos durante 3 turnos."},
		"visual": {"archetype": 1, "tint": "ffffff"},
	},
	{
		"id": "mugo", "name": "Mugo", "archetype": 2, "role": "Tanque · resistencia",
		"personality": "Un gigante paciente que colecciona pequeñas flores.",
		"strengths": "Mucha vida, defensa y resistencia a estados y críticos.", "weaknesses": "Lento, poco evasivo y de ataques modestos.",
		"base_stats": {"max_hp": 315.0, "attack": 20.0, "defense": 34.0, "speed": 3.0, "accuracy": 0.90, "evasion": 0.04, "crit_chance": 0.06, "crit_damage": 1.45, "resistance": 0.27},
		"growth": {"max_hp": 11.0, "attack": 0.57, "defense": 0.9, "speed": 0.06, "accuracy": 0.001, "evasion": 0.0003, "crit_chance": 0.0005, "crit_damage": 0.002, "resistance": 0.002},
		"training_base": {"life": 8, "strength": 5, "agility": 4, "speed": 5},
		"ability": {"id": "fortify", "name": "Corazón de cantera", "description": "Reduce un 45% el daño adicional de los críticos recibidos.", "critical_reduction": 0.45},
		"signature": {"name": "Abrazo de montaña", "effect": "attack_down", "magnitude": 0.20, "duration": 3, "damage_multiplier": 1.6, "description": "Golpe certero ×1.6 y ataque rival −20% durante 3 turnos."},
		"visual": {"archetype": 2, "tint": "ffffff"},
	},
	{
		"id": "sira", "name": "Sira", "archetype": 0, "role": "Críticos · filo de cristal",
		"personality": "Elegante y competitiva; apuesta todo a un instante perfecto.",
		"strengths": "Críticos frecuentes y profundos que atraviesan defensa.", "weaknesses": "Poca vida y resistencia; vulnerable si la pelea se alarga.",
		"base_stats": {"max_hp": 205.0, "attack": 24.0, "defense": 10.0, "speed": 7.0, "accuracy": 0.96, "evasion": 0.10, "crit_chance": 0.23, "crit_damage": 1.8, "resistance": 0.05},
		"growth": {"max_hp": 6.0, "attack": 0.85, "defense": 0.4, "speed": 0.10, "accuracy": 0.0008, "evasion": 0.0006, "crit_chance": 0.001, "crit_damage": 0.004, "resistance": 0.001},
		"training_base": {"life": 5, "strength": 8, "agility": 7, "speed": 6},
		"ability": {"id": "precision", "name": "Grieta perfecta", "description": "Sus críticos ignoran el 45% de la defensa rival.", "armor_ignore": 0.45},
		"signature": {"name": "Destello de obsidiana", "effect": "defense_down", "magnitude": 0.25, "duration": 3, "damage_multiplier": 1.6, "description": "Golpe certero ×1.6 y defensa rival −25% durante 3 turnos."},
		"visual": {"archetype": 0, "tint": "ffffff", "atlas": "res://assets/sprites/sira-v3.png"},
	},
	{
		"id": "iria", "name": "Iria", "archetype": 1, "role": "Estados · veneno",
		"personality": "Botánica traviesa; conoce el secreto de cada hoja.",
		"strengths": "Desgasta con veneno acumulable y tolera los estados.", "weaknesses": "Daño directo bajo; necesita tiempo para preparar su ventaja.",
		"base_stats": {"max_hp": 255.0, "attack": 19.0, "defense": 18.0, "speed": 6.0, "accuracy": 0.94, "evasion": 0.11, "crit_chance": 0.08, "crit_damage": 1.5, "resistance": 0.24},
		"growth": {"max_hp": 8.0, "attack": 0.58, "defense": 0.65, "speed": 0.09, "accuracy": 0.001, "evasion": 0.0007, "crit_chance": 0.0005, "crit_damage": 0.002, "resistance": 0.002},
		"training_base": {"life": 7, "strength": 4, "agility": 7, "speed": 6},
		"ability": {"id": "poison", "name": "Jardín secreto", "description": "35% al conectar de envenenar: 3 × Ataque / 19 PV durante 3 turnos, hasta 2 cargas.", "chance": 0.35, "magnitude": 3.0, "duration": 3, "stacking": "intensity", "max_stacks": 2, "scaling_stat": "attack", "scaling_base": 19.0},
		"signature": {"name": "Flor de medianoche", "effect": "healing_down", "magnitude": 0.40, "duration": 4, "damage_multiplier": 1.6, "description": "Golpe certero ×1.6 y curación rival −40% durante 4 turnos."},
		"visual": {"archetype": 1, "tint": "ffffff", "atlas": "res://assets/sprites/iria-v3.png"},
	},
	{
		"id": "duna", "name": "Duna", "archetype": 2, "role": "Defensa · escudos",
		"personality": "Protectora del mercado; nunca deja atrás a un amigo.",
		"strengths": "Levanta escudos periódicos y aguanta el daño sostenido.", "weaknesses": "Lenta y poco amenazante al principio de una pelea.",
		"base_stats": {"max_hp": 260.0, "attack": 18.5, "defense": 28.0, "speed": 4.5, "accuracy": 0.95, "evasion": 0.07, "crit_chance": 0.08, "crit_damage": 1.5, "resistance": 0.20},
		"growth": {"max_hp": 9.0, "attack": 0.61, "defense": 0.85, "speed": 0.07, "accuracy": 0.0008, "evasion": 0.0004, "crit_chance": 0.0006, "crit_damage": 0.002, "resistance": 0.0015},
		"training_base": {"life": 8, "strength": 5, "agility": 5, "speed": 5},
		"ability": {"id": "shield", "name": "Muralla del patio", "description": "Cada 4 turnos obtiene un escudo de 12 PV que dura hasta 3 turnos.", "every": 4, "magnitude": 12.0, "duration": 3},
		"signature": {"name": "Sello del guardián", "effect": "slow", "magnitude": 0.25, "duration": 3, "damage_multiplier": 1.6, "description": "Golpe certero ×1.6 y velocidad rival −25% durante 3 turnos."},
		"visual": {"archetype": 2, "tint": "ffffff", "atlas": "res://assets/sprites/duna-v3.png"},
	},
	{
		"id": "kiro", "name": "Kiro", "archetype": 0, "role": "Riesgo · furia",
		"personality": "Temerario, generoso y un poco incapaz de retroceder.",
		"strengths": "Gana ataque conforme pierde vida; presión y críticos fuertes.", "weaknesses": "Poca defensa, resistencia y precisión: su apuesta puede fallar.",
		"base_stats": {"max_hp": 242.0, "attack": 21.0, "defense": 12.0, "speed": 7.0, "accuracy": 0.89, "evasion": 0.10, "crit_chance": 0.16, "crit_damage": 1.65, "resistance": 0.04},
		"growth": {"max_hp": 7.5, "attack": 0.72, "defense": 0.4, "speed": 0.12, "accuracy": 0.001, "evasion": 0.0005, "crit_chance": 0.0008, "crit_damage": 0.003, "resistance": 0.001},
		"training_base": {"life": 6, "strength": 8, "agility": 4, "speed": 7},
		"ability": {"id": "berserk", "name": "Última brasa", "description": "Su daño aumenta según la vida perdida, hasta un 40% adicional.", "missing_hp_bonus": 0.40},
		"signature": {"name": "Rugido del horno", "effect": "burn", "magnitude": 4.0, "duration": 3, "damage_multiplier": 1.6, "description": "Golpe certero ×1.6 y quemadura de 4 PV durante 3 turnos."},
		"visual": {"archetype": 0, "tint": "ffffff", "atlas": "res://assets/sprites/kiro-v3.png"},
	},
	{
		"id": "neris", "name": "Neris", "archetype": 1, "role": "Remontada · curación",
		"personality": "Optimista obstinada: incluso el charco más pequeño refleja la luna.",
		"strengths": "Una recuperación decisiva cuando parece derrotada.", "weaknesses": "Ataque moderado; la curación solo ocurre una vez y puede debilitarse.",
		"base_stats": {"max_hp": 245.0, "attack": 20.0, "defense": 18.0, "speed": 6.0, "accuracy": 0.97, "evasion": 0.12, "crit_chance": 0.08, "crit_damage": 1.5, "resistance": 0.17},
		"growth": {"max_hp": 8.0, "attack": 0.58, "defense": 0.65, "speed": 0.09, "accuracy": 0.001, "evasion": 0.0007, "crit_chance": 0.0006, "crit_damage": 0.002, "resistance": 0.0015},
		"training_base": {"life": 7, "strength": 5, "agility": 6, "speed": 6},
		"ability": {"id": "comeback", "name": "Otra primavera", "description": "Una vez por combate, al bajar de 35% de vida cura un 16% de su vida máxima.", "threshold": 0.35, "heal_fraction": 0.16},
		"signature": {"name": "Eclipse del río", "effect": "attack_down", "magnitude": 0.22, "duration": 3, "damage_multiplier": 1.6, "description": "Golpe certero ×1.6 y ataque rival −22% durante 3 turnos."},
		"visual": {"archetype": 1, "tint": "ffffff", "atlas": "res://assets/sprites/neris-v3.png"},
	},
	{
		"id": "taro", "name": "Taro", "archetype": 2, "role": "Respuesta · contraataques",
		"personality": "Callado y observador; escucha al rival antes de contestar.",
		"strengths": "Castiga la agresión con réplicas y una defensa sólida.", "weaknesses": "Sus réplicas son inciertas; presión ofensiva propia moderada.",
		"base_stats": {"max_hp": 250.0, "attack": 20.5, "defense": 24.0, "speed": 5.0, "accuracy": 0.95, "evasion": 0.08, "crit_chance": 0.10, "crit_damage": 1.55, "resistance": 0.17},
		"growth": {"max_hp": 8.0, "attack": 0.62, "defense": 0.8, "speed": 0.09, "accuracy": 0.001, "evasion": 0.0006, "crit_chance": 0.0007, "crit_damage": 0.003, "resistance": 0.0015},
		"training_base": {"life": 7, "strength": 6, "agility": 5, "speed": 5},
		"ability": {"id": "counter", "name": "Eco de jade", "description": "24% de responder a un golpe recibido con un contraataque de ×0.45 de daño.", "chance": 0.24, "multiplier": 0.45},
		"signature": {"name": "Campana del cañón", "effect": "bleed", "magnitude": 4.0, "duration": 3, "damage_multiplier": 1.6, "description": "Golpe certero ×1.6 y sangrado de 4 PV durante 3 turnos."},
		"visual": {"archetype": 2, "tint": "ffffff", "atlas": "res://assets/sprites/taro-v3.png"},
	},
	{
		"id": "balam",
		"name": "Balam",
		"full_name": "Balam · Jaguar",
		"species": "Jaguar",
		"breed": "",
		"biography": "Balam es un jaguar de pasos silenciosos y mirada atenta. Prefiere preparar una embestida certera antes que apresurar cada intercambio.",
		"archetype": 0,
		"role": "Acecho · cargas y críticos",
		"personality": "Jaguar paciente; observa el camino y elige un instante para saltar.",
		"strengths": "Ataque y críticos sólidos; prepara la puntería y castiga guardias con cargas.",
		"weaknesses": "Resistencia baja y cargas expuestas; no puede esquivar todos los intercambios.",
		"base_stats": {
			"max_hp": 238,
			"attack": 22.0,
			"defense": 18,
			"speed": 6.5,
			"accuracy": 0.94,
			"evasion": 0.1,
			"crit_chance": 0.18,
			"crit_damage": 1.7,
			"resistance": 0.08
		},
		"growth": {
			"max_hp": 7.5,
			"attack": 0.69,
			"defense": 0.5,
			"speed": 0.1,
			"accuracy": 0.0009,
			"evasion": 0.0006,
			"crit_chance": 0.0008,
			"crit_damage": 0.003,
			"resistance": 0.001
		},
		"training_base": {
			"life": 7,
			"strength": 8,
			"agility": 6,
			"speed": 5
		},
		"ability": {
			"id": "precision",
			"name": "Mirada entre las hojas",
			"description": "Sus críticos ignoran el 30% de la defensa rival.",
			"armor_ignore": 0.3
		},
		"signature": {
			"name": "Noche moteada",
			"effect": "defense_down",
			"magnitude": 0.2,
			"duration": 3,
			"damage_multiplier": 1.65,
			"description": "1% por combate, una sola vez: golpe certero ×1.65 y defensa rival −20% durante 3 acciones del objetivo."
		},
		"visual": {
			"archetype": 0,
			"tint": "ffffff",
			"atlas": "res://assets/sprites/balam-v1.png"
		}
	},
	{
		"id": "tepa",
		"name": "Tepa",
		"full_name": "Tepa · Teporingo",
		"species": "Teporingo",
		"breed": "",
		"biography": "Tepa es una pequeña teporingo de gran iniciativa. Sus saltos cambian de trayectoria y sus carreras breves abren espacio para volver a despegar.",
		"archetype": 0,
		"role": "Saltos · velocidad y evasión",
		"personality": "Teporingo inquieta y tenaz; convierte cada piedra en un punto de despegue.",
		"strengths": "Velocidad y evasión altas; saltos de trayectorias distintas y un golpe reforzado cada cuatro ataques.",
		"weaknesses": "Poca vida y armadura; sus saltos reducen algo la precisión.",
		"base_stats": {
			"max_hp": 220,
			"attack": 19.5,
			"defense": 13,
			"speed": 11,
			"accuracy": 0.94,
			"evasion": 0.18,
			"crit_chance": 0.13,
			"crit_damage": 1.5,
			"resistance": 0.09
		},
		"growth": {
			"max_hp": 6.8,
			"attack": 0.64,
			"defense": 0.42,
			"speed": 0.17,
			"accuracy": 0.0009,
			"evasion": 0.0009,
			"crit_chance": 0.0007,
			"crit_damage": 0.0025,
			"resistance": 0.001
		},
		"training_base": {
			"life": 5,
			"strength": 5,
			"agility": 8,
			"speed": 8
		},
		"ability": {
			"id": "combo",
			"name": "Cuatro brincos",
			"description": "Cada cuarto intento de ataque hace ×1.3 de daño si conecta.",
			"every": 4,
			"multiplier": 1.3
		},
		"signature": {
			"name": "Salto del sol",
			"effect": "slow",
			"magnitude": 0.22,
			"duration": 3,
			"damage_multiplier": 1.55,
			"description": "1% por combate, una sola vez: golpe certero ×1.55 y velocidad rival −22% durante 3 acciones del objetivo."
		},
		"visual": {
			"archetype": 0,
			"tint": "ffffff",
			"atlas": "res://assets/sprites/tepa-v1.png"
		}
	},
	{
		"id": "xuna",
		"name": "Xuna",
		"full_name": "Xuna · Xoloitzcuintle",
		"species": "Xoloitzcuintle",
		"breed": "Xoloitzcuintle",
		"biography": "Xuna es una xoloitzcuintle de guardia firme y orejas siempre atentas. Resiste los intercambios y usa brasas breves para desgastar a quien se precipita.",
		"archetype": 2,
		"role": "Guardia · resistencia y desgaste",
		"personality": "Xoloitzcuintle serena; guarda el paso y mantiene la calma cuando cae la noche.",
		"strengths": "Vida, defensa y resistencia sólidas; reduce críticos y combina guardias con quemaduras.",
		"weaknesses": "Velocidad y evasión bajas; ceder una acción de ataque tiene un coste.",
		"base_stats": {
			"max_hp": 300,
			"attack": 21.4,
			"defense": 30,
			"speed": 4.8,
			"accuracy": 0.93,
			"evasion": 0.06,
			"crit_chance": 0.08,
			"crit_damage": 1.5,
			"resistance": 0.32
		},
		"growth": {
			"max_hp": 9.2,
			"attack": 0.55,
			"defense": 0.8,
			"speed": 0.07,
			"accuracy": 0.001,
			"evasion": 0.0004,
			"crit_chance": 0.0006,
			"crit_damage": 0.002,
			"resistance": 0.0018
		},
		"training_base": {
			"life": 8,
			"strength": 5,
			"agility": 5,
			"speed": 5
		},
		"ability": {
			"id": "fortify",
			"name": "Serenidad del camino",
			"description": "Reduce un 30% el daño adicional de los críticos recibidos.",
			"critical_reduction": 0.3
		},
		"signature": {
			"name": "Faro del camino",
			"effect": "healing_down",
			"magnitude": 0.35,
			"duration": 4,
			"damage_multiplier": 1.6,
			"description": "1% por combate, una sola vez: golpe certero ×1.6 y curación rival −35% durante 4 acciones del objetivo."
		},
		"visual": {
			"archetype": 2,
			"tint": "ffffff",
			"atlas": "res://assets/sprites/xuna-v1.png"
		}
	},
	{
		"id": "copal",
		"name": "Copal",
		"full_name": "Copal · Cacomixtle",
		"species": "Cacomixtle",
		"breed": "",
		"biography": "Copal es un cacomixtle de cola anillada y reflejos rápidos. Alterna fintas, carreras cortas y esperas para provocar un ataque y responder.",
		"archetype": 0,
		"role": "Fintas · desplazamientos y réplicas",
		"personality": "Cacomixtle curioso; cambia de dirección justo cuando el rival cree haberlo leído.",
		"strengths": "Puntería, movilidad y evasión; sus fintas pueden abrir una oportunidad de respuesta.",
		"weaknesses": "Poca armadura y resistencia; los contraataques nunca están garantizados.",
		"base_stats": {
			"max_hp": 220,
			"attack": 19.8,
			"defense": 16,
			"speed": 9.2,
			"accuracy": 0.96,
			"evasion": 0.16,
			"crit_chance": 0.14,
			"crit_damage": 1.6,
			"resistance": 0.1
		},
		"growth": {
			"max_hp": 7.7,
			"attack": 0.72,
			"defense": 0.45,
			"speed": 0.12,
			"accuracy": 0.001,
			"evasion": 0.0008,
			"crit_chance": 0.0007,
			"crit_damage": 0.003,
			"resistance": 0.001
		},
		"training_base": {
			"life": 6,
			"strength": 6,
			"agility": 8,
			"speed": 7
		},
		"ability": {
			"id": "counter",
			"name": "Respuesta entre ramas",
			"description": "20% de responder a un golpe recibido con un contraataque de ×0.4 de daño.",
			"chance": 0.2,
			"multiplier": 0.4
		},
		"signature": {
			"name": "Ronda de la luna",
			"effect": "accuracy_down",
			"magnitude": 0.14,
			"duration": 3,
			"damage_multiplier": 1.6,
			"description": "1% por combate, una sola vez: golpe certero ×1.6 y precisión rival −14 puntos durante 3 acciones del objetivo."
		},
		"visual": {
			"archetype": 0,
			"tint": "ffffff",
			"atlas": "res://assets/sprites/copal-v1.png"
		}
	},
	{
		"id": "onix",
		"name": "Ónix",
		"full_name": "Ónix · Gato doméstico",
		"species": "Gato doméstico",
		"breed": "",
		"coat": "Negro",
		"eye_color": "Amarillos",
		"biography": "Ónix es un gato doméstico negro de ojos amarillos. Curioso y ligero, recorre los tejados en silencio y encadena golpes cortos antes de apartarse.",
		"archetype": 0,
		"role": "Agilidad · ritmo y evasión",
		"personality": "Ónix es un gato doméstico negro de ojos amarillos. Curioso y ligero, recorre los tejados en silencio y encadena golpes cortos antes de apartarse.",
		"strengths": "Velocidad y evasión altas; enlaza ataques rápidos y cambios de dirección.",
		"weaknesses": "Vida y defensa bajas; cada golpe recibido pesa y los estados lo desgastan.",
		"base_stats": {
			"max_hp": 212,
			"attack": 19,
			"defense": 11,
			"speed": 12,
			"accuracy": 0.94,
			"evasion": 0.2,
			"crit_chance": 0.13,
			"crit_damage": 1.5,
			"resistance": 0.06
		},
		"growth": {
			"max_hp": 6.8,
			"attack": 0.64,
			"defense": 0.42,
			"speed": 0.14,
			"accuracy": 0.0008,
			"evasion": 0.0007,
			"crit_chance": 0.0007,
			"crit_damage": 0.0025,
			"resistance": 0.001
		},
		"training_base": {
			"life": 5,
			"strength": 6,
			"agility": 8,
			"speed": 9
		},
		"ability": {
			"id": "combo",
			"name": "Tres pasos de sombra",
			"description": "Cada tercer intento de ataque hace ×1.22 de daño si conecta.",
			"every": 3,
			"multiplier": 1.22
		},
		"signature": {
			"name": "Medianoche amarilla",
			"effect": "accuracy_down",
			"magnitude": 0.16,
			"duration": 3,
			"damage_multiplier": 1.6,
			"description": "1% por combate, una sola vez: golpe certero ×1.6 y precisión rival −16 puntos durante 3 acciones del objetivo."
		},
		"visual": {
			"archetype": 0,
			"tint": "ffffff",
			"atlas": "res://assets/sprites/onix-v1.png"
		}
	},
	{
		"id": "bruma",
		"name": "Bruma",
		"full_name": "Bruma · Gato doméstico",
		"species": "Gato doméstico",
		"breed": "",
		"coat": "Gris",
		"eye_color": "Verdosos",
		"biography": "Bruma es un gato doméstico gris de ojos verdosos. Sereno y observador, escucha el movimiento del rival y responde con una pata firme cuando aparece una abertura.",
		"archetype": 1,
		"role": "Precisión · guardia y respuestas",
		"personality": "Bruma es un gato doméstico gris de ojos verdosos. Sereno y observador, escucha el movimiento del rival y responde con una pata firme cuando aparece una abertura.",
		"strengths": "Buena precisión y defensa equilibrada; combina guardias con respuestas medidas.",
		"weaknesses": "Velocidad moderada y réplicas inciertas; las posturas ceden una oportunidad de atacar.",
		"base_stats": {
			"max_hp": 255,
			"attack": 20,
			"defense": 23,
			"speed": 5.8,
			"accuracy": 1.01,
			"evasion": 0.1,
			"crit_chance": 0.11,
			"crit_damage": 1.55,
			"resistance": 0.18
		},
		"growth": {
			"max_hp": 8,
			"attack": 0.62,
			"defense": 0.75,
			"speed": 0.09,
			"accuracy": 0.001,
			"evasion": 0.0005,
			"crit_chance": 0.0007,
			"crit_damage": 0.0025,
			"resistance": 0.0015
		},
		"training_base": {
			"life": 7,
			"strength": 6,
			"agility": 5,
			"speed": 6
		},
		"ability": {
			"id": "counter",
			"name": "Respuesta del silencio",
			"description": "20% de responder a un golpe recibido con un contraataque de ×0.42 de daño.",
			"chance": 0.2,
			"multiplier": 0.42
		},
		"signature": {
			"name": "Quietud de niebla",
			"effect": "attack_down",
			"magnitude": 0.2,
			"duration": 3,
			"damage_multiplier": 1.6,
			"description": "1% por combate, una sola vez: golpe certero ×1.6 y ataque rival −20% durante 3 acciones del objetivo."
		},
		"visual": {
			"archetype": 1,
			"tint": "ffffff",
			"atlas": "res://assets/sprites/bruma-v1.png"
		}
	},
]

static func all_definitions() -> Array[Dictionary]:
	return DEFINITIONS.duplicate(true)

static func definition(id: String) -> Dictionary:
	for entry in DEFINITIONS:
		if str(entry.id) == id:
			return entry.duplicate(true)
	return {}

static func id_for_archetype(archetype: int) -> String:
	return IDS[clampi(archetype, 0, 2)]

static func stats_for(profile: Dictionary) -> Dictionary:
	var id: String = str(profile.get("character_id", id_for_archetype(int(profile.get("archetype", 0)))))
	var entry: Dictionary = definition(id)
	if entry.is_empty():
		entry = definition("nima")
	var steps: float = Balance.growth_steps(int(profile.get("level", 1)))
	var result: Dictionary = {}
	var training: Dictionary = profile.get("stats", entry.training_base)
	for stat: String in Balance.STAT_KEYS:
		var value: float = float(entry.base_stats[stat]) + float(entry.growth[stat]) * steps
		for training_key: String in Balance.TRAINING_EFFECTS:
			var effects: Dictionary = Balance.TRAINING_EFFECTS[training_key]
			if effects.has(stat):
				var amount: int = clampi(int(training.get(training_key, entry.training_base[training_key])), 1, Balance.TRAINING_CAP)
				value += float(amount - int(entry.training_base[training_key])) * float(effects[stat])
		var bounds: Array = Balance.STAT_BOUNDS[stat]
		result[stat] = clampf(value, float(bounds[0]), float(bounds[1]))
	result["interval"] = Balance.interval_for(float(result.speed))
	return result

static func power(stats: Dictionary) -> float:
	# Solo emparejamiento: nunca se usa como multiplicador de daño.
	var hp: float = float(stats.get("max_hp", 250.0))
	var defense: float = float(stats.get("defense", 20.0))
	var damage: float = float(stats.get("attack", 22.0))
	var critical: float = 1.0 + float(stats.get("crit_chance", 0.1)) * (float(stats.get("crit_damage", 1.5)) - 1.0)
	var accuracy: float = clampf(float(stats.get("accuracy", 0.96)) - float(Balance.MATCHMAKING.power_reference_evasion), float(Balance.COMBAT.hit_min), float(Balance.COMBAT.hit_max))
	var interval: float = maxf(0.5, float(stats.get("interval", Balance.interval_for(float(stats.get("speed", 6.0))))))
	var durability: float = hp * (1.0 + defense / float(Balance.COMBAT.defense_scale)) / maxf(0.65, 1.0 - float(stats.get("evasion", 0.1)))
	return sqrt(maxf(1.0, durability * damage * critical * accuracy / interval))
