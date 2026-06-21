# pf_game_math.gd
## A stateless utility class containing the core mathematical tables for Pathfinder 2e.
class_name PFGameMath
extends RefCounted

const DCS_BY_LEVEL: Dictionary = {
	0: 14, 1: 15, 2: 16, 3: 18, 4: 19, 5: 20,
	6: 22, 7: 23, 8: 24, 9: 26, 10: 27, 11: 28,
	12: 30, 13: 31, 14: 32, 15: 34, 16: 35, 17: 36,
	18: 38, 19: 39, 20: 40, 21: 42, 22: 44, 23: 46,
	24: 48, 25: 50
}

const DC_ADJUSTMENTS: Dictionary = {
	&"incredibly_easy": -10,
	&"very_easy": -5,
	&"easy": -2,
	&"hard": 2,
	&"very_hard": 5,
	&"incredibly_hard": 10
}

const DAMAGE_BY_LEVEL: Dictionary = {
	-1: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [1, 4], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [1, 6], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [2, 6], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [4, 6] },
	0: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [1, 4], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [1, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [2, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [4, 8] },
	1: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [1, 6], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [2, 6], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [3, 6], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [4, 6] },
	2: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [1, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [2, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [3, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [4, 8] },
	3: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [1, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [2, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [4, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [5, 10] },
	4: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [2, 6], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [3, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [5, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [6, 8] },
	5: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [2, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [4, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [6, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [7, 8] },
	6: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [2, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [5, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [7, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [8, 8] },
	7: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [2, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [5, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [7, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [9, 10] },
	8: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [3, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [6, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [8, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [10, 8] },
	9: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [3, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [6, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [9, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [11, 10] },
	10: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [4, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [7, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [10, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [12, 8] },
	11: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [4, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [7, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [11, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [14, 10] },
	12: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [5, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [8, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [12, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [15, 8] },
	13: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [5, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [9, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [13, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [16, 10] },
	14: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [6, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [10, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [14, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [18, 8] },
	15: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [6, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [11, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [15, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [19, 10] },
	16: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [7, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [12, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [16, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [20, 8] },
	17: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [7, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [13, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [18, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [22, 10] },
	18: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [8, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [14, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [19, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [24, 8] },
	19: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [8, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [15, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [20, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [26, 10] },
	20: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [9, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [16, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [22, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [28, 8] },
	21: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [9, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [17, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [23, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [30, 10] },
	22: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [10, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [18, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [25, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [32, 8] },
	23: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [10, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [19, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [26, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [34, 10] },
	24: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [11, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [20, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [28, 8], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [36, 8] },
	25: { PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR: [11, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE: [21, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR: [30, 10], PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE: [38, 10] }
}

## Returns the standard DC for a given level. Clamps between 0 and 25.
static func get_dc_by_level(level: int) -> int:
	var clamped_level = clampi(level, 0, 25)
	return DCS_BY_LEVEL[clamped_level]

## Returns the Simple DC for a given proficiency rank.
static func get_simple_dc(proficiency: PFMathConstants.ProficiencyRank) -> int:
	match proficiency:
		PFMathConstants.ProficiencyRank.UNTRAINED: return 10
		PFMathConstants.ProficiencyRank.TRAINED: return 15
		PFMathConstants.ProficiencyRank.EXPERT: return 20
		PFMathConstants.ProficiencyRank.MASTER: return 30
		PFMathConstants.ProficiencyRank.LEGENDARY: return 40
	return 10

## Modifies a base DC based on standard Pathfinder 2e adjustments.
static func adjust_dc(base_dc: int, adjustment_type: StringName) -> int:
	if DC_ADJUSTMENTS.has(adjustment_type):
		return base_dc + DC_ADJUSTMENTS[adjustment_type]
	return base_dc

## Returns the appropriate amount of damage for a Hazard or Environment based on the level and severity.
static func get_environmental_damage(level: int, severity: PFEnvironmentConstants.EnvironmentDamageSeverity) -> PFDice.RollResult:
	var clamped_level = clampi(level, -1, 25)
	var damage_def = DAMAGE_BY_LEVEL[clamped_level][severity]
	return PFDice.roll(damage_def[0], damage_def[1])

## Evaluates a d20 roll against a DC to determine the Degree of Success.
## Automatically handles Natural 1s (-1 degree) and Natural 20s (+1 degree).
static func get_degree_of_success(roll_total: int, dc: int, is_nat_1: bool = false, is_nat_20: bool = false) -> PFCombatConstants.DegreeOfSuccess:
	var base_degree: PFCombatConstants.DegreeOfSuccess
	
	if roll_total >= dc + 10:
		base_degree = PFCombatConstants.DegreeOfSuccess.CRITICAL_SUCCESS
	elif roll_total >= dc:
		base_degree = PFCombatConstants.DegreeOfSuccess.SUCCESS
	elif roll_total <= dc - 10:
		base_degree = PFCombatConstants.DegreeOfSuccess.CRITICAL_FAILURE
	else:
		base_degree = PFCombatConstants.DegreeOfSuccess.FAILURE
		
	# Adjust for natural 20
	if is_nat_20:
		match base_degree:
			PFCombatConstants.DegreeOfSuccess.CRITICAL_FAILURE: return PFCombatConstants.DegreeOfSuccess.FAILURE
			PFCombatConstants.DegreeOfSuccess.FAILURE: return PFCombatConstants.DegreeOfSuccess.SUCCESS
			PFCombatConstants.DegreeOfSuccess.SUCCESS: return PFCombatConstants.DegreeOfSuccess.CRITICAL_SUCCESS
			PFCombatConstants.DegreeOfSuccess.CRITICAL_SUCCESS: return PFCombatConstants.DegreeOfSuccess.CRITICAL_SUCCESS
			
	# Adjust for natural 1
	if is_nat_1:
		match base_degree:
			PFCombatConstants.DegreeOfSuccess.CRITICAL_SUCCESS: return PFCombatConstants.DegreeOfSuccess.SUCCESS
			PFCombatConstants.DegreeOfSuccess.SUCCESS: return PFCombatConstants.DegreeOfSuccess.FAILURE
			PFCombatConstants.DegreeOfSuccess.FAILURE: return PFCombatConstants.DegreeOfSuccess.CRITICAL_FAILURE
			PFCombatConstants.DegreeOfSuccess.CRITICAL_FAILURE: return PFCombatConstants.DegreeOfSuccess.CRITICAL_FAILURE
			
	return base_degree

## Applies the popular "Keeley Rule" house rule for Hero Point rerolls.
## If the new d20 roll is between 1 and 9, it adds 10 to the result (making it 11-19).
static func apply_keeley_hero_point_reroll(d20_roll: int) -> int:
	if d20_roll >= 1 and d20_roll <= 9:
		return d20_roll + 10
	return d20_roll

## Calculates falling damage based on Pathfinder 2e rules.
## Damage is bludgeoning, equal to half the distance fallen (max 1500 ft / 750 damage).
## Soft surfaces reduce the effective fall distance by 20 feet (or 30 if diving intentionally),
## up to a maximum reduction equal to the depth of the soft surface.
static func calculate_falling_damage(distance: int, is_intentional_dive: bool = false, soft_surface_depth: int = 0) -> int:
	var effective_distance = clampi(distance, 0, 1500)
	
	var reduction = 0
	if soft_surface_depth > 0:
		reduction = 30 if is_intentional_dive else 20
		reduction = mini(reduction, soft_surface_depth)
		
	effective_distance = maxi(0, effective_distance - reduction)
	
	# Only take damage if falling more than 5 feet (effectively)
	if effective_distance <= 5:
		return 0
		
	@warning_ignore("integer_division")
	return effective_distance / 2

## Determines a generic environmental damage roll using standard GM guidelines.
## Minor: 1d6 to 2d6
## Moderate: 4d6 to 6d6
## Major: 8d6 to 12d6
## Massive: 18d6 to 24d6
static func get_environmental_damage_roll(category: StringName) -> int:
	match category:
		&"minor":
			return PFDice.roll(randi_range(1, 2), 6).total
		&"moderate":
			return PFDice.roll(randi_range(4, 6), 6).total
		&"major":
			return PFDice.roll(randi_range(8, 12), 6).total
		&"massive":
			return PFDice.roll(randi_range(18, 24), 6).total
	return 0
