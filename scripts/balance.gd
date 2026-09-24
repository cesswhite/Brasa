class_name BrasaBalance
extends RefCounted
## Única configuración de números de combate y progresión.

const MAX_LEVEL: int = 50
const LEVEL_SOFT_CAP: int = 20
const GROWTH_AFTER_SOFT_CAP: float = 0.45
const TRAINING_CAP: int = 30
const INITIAL_POINTS: int = 3
const POINTS_PER_LEVEL: int = 2
const HISTORY_LIMIT: int = 100
const COMBAT: Dictionary = {
	"hit_min": 0.62, "hit_max": 0.96, "crit_min": 0.03, "crit_max": 0.32,
	"variance": 0.08, "defense_scale": 100.0, "interval_base": 2.4,
	"interval_speed_scale": 0.035, "max_duration": 60.0, "min_damage": 1,
	"level_damage_per_level": 0.004, "level_damage_min": 0.9, "level_damage_max": 1.1,
	"opening_min": 1.8, "opening_max": 2.3, "cadence_variance": 0.04,
}
const SIGNATURE: Dictionary = {"chance": 0.01, "damage_multiplier": 1.6, "min_multiplier": 1.4, "max_multiplier": 1.8, "min_turn": 2, "max_turn": 5}
const STATUS: Dictionary = {
	"max_duration": 5, "max_stacks": 3, "max_magnitude": 0.45,
	"max_dot_fraction": 0.04, "max_shield_fraction": 0.25,
	"resistance_duration_factor": 0.65, "resistance_chance_factor": 0.75,
}
const XP: Dictionary = {
	"first_level": 55, "per_level": 25, "win": 40, "loss": 25,
	"surrender": 8, "reward_growth": 0.16, "short_match_seconds": 8.0,
	"short_match_floor": 0.15, "repeat_surrender_decay": 0.55,
	"repeat_surrender_floor": 0.15, "repeat_opponent_threshold": 3,
	"repeat_opponent_decay": 0.20, "repeat_opponent_floor": 0.40,
	"surrender_cooldown": 4.0,
}
const MATCHMAKING: Dictionary = {
	"candidate_pool": 5, "distance_smoothing": 0.10, "npc_training_per_level": 1.4,
	"normal_offsets": [-1, 0, 0, 0, 1], "wide_gap_every": 11, "wide_gap": 2,
	"power_reference_evasion": 0.10,
}
const STAT_KEYS: Array[String] = ["max_hp", "attack", "defense", "speed", "accuracy", "evasion", "crit_chance", "crit_damage", "resistance"]
const STAT_BOUNDS: Dictionary = {
	"max_hp": [100.0, 2000.0], "attack": [5.0, 150.0], "defense": [0.0, 160.0],
	"speed": [1.0, 36.0], "accuracy": [0.65, 1.14], "evasion": [0.0, 0.30],
	"crit_chance": [0.03, 0.32], "crit_damage": [1.2, 2.1], "resistance": [0.0, 0.50],
}
const TRAINING_EFFECTS: Dictionary = {
	"life": {"max_hp": 20.0}, "strength": {"attack": 1.5},
	"agility": {"evasion": 0.007, "crit_chance": 0.008}, "speed": {"speed": 1.0},
}

static func xp_for_level(level: int) -> int:
	return int(XP.first_level) + (clampi(level, 1, MAX_LEVEL) - 1) * int(XP.per_level)

static func xp_needed(level: int) -> int:
	return xp_for_level(level)

static func growth_steps(level: int) -> float:
	var safe_level: int = clampi(level, 1, MAX_LEVEL)
	return float(mini(safe_level, LEVEL_SOFT_CAP) - 1) + float(maxi(0, safe_level - LEVEL_SOFT_CAP)) * GROWTH_AFTER_SOFT_CAP

static func interval_for(speed: float) -> float:
	var bounds: Array = STAT_BOUNDS.speed
	return float(COMBAT.interval_base) / (1.0 + clampf(speed, float(bounds[0]), float(bounds[1])) * float(COMBAT.interval_speed_scale))

static func reward_base(level: int, result: String) -> int:
	var amount: int = int(XP.get(result, XP.loss))
	return maxi(1, roundi(float(amount) * (1.0 + float(clampi(level, 1, MAX_LEVEL) - 1) * float(XP.reward_growth))))
