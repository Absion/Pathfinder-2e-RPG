# pf_dice.gd
# A global utility class for handling randomness and PF2e's degree of success math.
class_name PFDice
extends RefCounted

# PF2e Degrees of Success. 
enum Degree { CRIT_FAIL = 0, FAIL = 1, SUCCESS = 2, CRIT_SUCCESS = 3 }

# --- NEW: Inner Class ---
# This object holds both the final math and the individual dice data.
class RollResult extends RefCounted:
	var total: int
	var faces: Array[int]
	
	func _init(p_total: int, p_faces: Array[int]):
		total = p_total
		faces = p_faces

# Rolls a given amount of dice and returns our rich RollResult object.
static func roll(amount: int, sides: int) -> RollResult:
	var total = 0
	var faces: Array[int] = []
	
	for i in range(amount):
		var r = randi_range(1, sides)
		faces.append(r)
		total += r
		
	return RollResult.new(total, faces)

# Helper function for d20s. We extract just the .total here to keep attack roll math clean.
static func roll_d20() -> int:
	return roll(1, 20).total

# The core PF2e Success Logic (+10 is Crit, -10 is Crit Fail)
static func determine_success(roll_total: int, target_dc: int, natural_roll: int) -> Degree:
	var degree: int
	
	# 1. Determine base success purely off the math
	if roll_total >= target_dc + 10:
		degree = Degree.CRIT_SUCCESS
	elif roll_total >= target_dc:
		degree = Degree.SUCCESS
	elif roll_total <= target_dc - 10:
		degree = Degree.CRIT_FAIL
	else:
		degree = Degree.FAIL
		
	# 2. Apply Natural 20 and Natural 1 bumps
	if natural_roll == 20:
		degree = clampi(degree + 1, Degree.CRIT_FAIL, Degree.CRIT_SUCCESS) as Degree
	elif natural_roll == 1:
		degree = clampi(degree - 1, Degree.CRIT_FAIL, Degree.CRIT_SUCCESS) as Degree
		
	return degree
