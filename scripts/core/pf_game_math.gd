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
