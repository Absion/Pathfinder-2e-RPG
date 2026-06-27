extends GutTest


func test_get_dc_by_level():
	assert_eq(PFGameMath.get_dc_by_level(0), 14)
	assert_eq(PFGameMath.get_dc_by_level(1), 15)
	assert_eq(PFGameMath.get_dc_by_level(20), 40)
	assert_eq(PFGameMath.get_dc_by_level(25), 50)
	# test clamping
	assert_eq(PFGameMath.get_dc_by_level(-5), 14)
	assert_eq(PFGameMath.get_dc_by_level(100), 50)

func test_get_simple_dc():
	assert_eq(PFGameMath.get_simple_dc(PFMathConstants.ProficiencyRank.UNTRAINED), 10)
	assert_eq(PFGameMath.get_simple_dc(PFMathConstants.ProficiencyRank.TRAINED), 15)
	assert_eq(PFGameMath.get_simple_dc(PFMathConstants.ProficiencyRank.EXPERT), 20)
	assert_eq(PFGameMath.get_simple_dc(PFMathConstants.ProficiencyRank.MASTER), 30)
	assert_eq(PFGameMath.get_simple_dc(PFMathConstants.ProficiencyRank.LEGENDARY), 40)

func test_adjust_dc():
	assert_eq(PFGameMath.adjust_dc(15, &"incredibly_easy"), 5)
	assert_eq(PFGameMath.adjust_dc(15, &"hard"), 17)
	assert_eq(PFGameMath.adjust_dc(15, &"incredibly_hard"), 25)
	assert_eq(PFGameMath.adjust_dc(15, &"invalid_adj"), 15)

func test_degree_of_success():
	var dc = 15
	# Normal rolls
	assert_eq(PFGameMath.get_degree_of_success(25, dc), PFCombatConstants.DegreeOfSuccess.CRITICAL_SUCCESS)
	assert_eq(PFGameMath.get_degree_of_success(15, dc), PFCombatConstants.DegreeOfSuccess.SUCCESS)
	assert_eq(PFGameMath.get_degree_of_success(14, dc), PFCombatConstants.DegreeOfSuccess.FAILURE)
	assert_eq(PFGameMath.get_degree_of_success(5, dc), PFCombatConstants.DegreeOfSuccess.CRITICAL_FAILURE)
	
	# Nat 20 bumps
	assert_eq(PFGameMath.get_degree_of_success(25, dc, false, true), PFCombatConstants.DegreeOfSuccess.CRITICAL_SUCCESS) # Can't go higher
	assert_eq(PFGameMath.get_degree_of_success(15, dc, false, true), PFCombatConstants.DegreeOfSuccess.CRITICAL_SUCCESS) # S -> CS
	assert_eq(PFGameMath.get_degree_of_success(14, dc, false, true), PFCombatConstants.DegreeOfSuccess.SUCCESS) # F -> S
	assert_eq(PFGameMath.get_degree_of_success(5, dc, false, true), PFCombatConstants.DegreeOfSuccess.FAILURE) # CF -> F
	
	# Nat 1 bumps
	assert_eq(PFGameMath.get_degree_of_success(25, dc, true, false), PFCombatConstants.DegreeOfSuccess.SUCCESS) # CS -> S
	assert_eq(PFGameMath.get_degree_of_success(15, dc, true, false), PFCombatConstants.DegreeOfSuccess.FAILURE) # S -> F
	assert_eq(PFGameMath.get_degree_of_success(14, dc, true, false), PFCombatConstants.DegreeOfSuccess.CRITICAL_FAILURE) # F -> CF
	assert_eq(PFGameMath.get_degree_of_success(5, dc, true, false), PFCombatConstants.DegreeOfSuccess.CRITICAL_FAILURE) # Can't go lower

func test_keeley_rule():
	# 1 to 9 gets +10
	assert_eq(PFGameMath.apply_keeley_hero_point_reroll(1), 11)
	assert_eq(PFGameMath.apply_keeley_hero_point_reroll(8), 18)
	assert_eq(PFGameMath.apply_keeley_hero_point_reroll(9), 19)
	
	# Results 10-20 are unchanged
	assert_eq(PFGameMath.apply_keeley_hero_point_reroll(10), 10)
	assert_eq(PFGameMath.apply_keeley_hero_point_reroll(15), 15)
	assert_eq(PFGameMath.apply_keeley_hero_point_reroll(20), 20)

func test_falling_damage():
	# Standard falling: half distance
	assert_eq(PFGameMath.calculate_falling_damage(10), 5)
	assert_eq(PFGameMath.calculate_falling_damage(30), 15)
	assert_eq(PFGameMath.calculate_falling_damage(100), 50)
	
	# <= 5 feet is no damage
	assert_eq(PFGameMath.calculate_falling_damage(5), 0)
	assert_eq(PFGameMath.calculate_falling_damage(4), 0)
	
	# Max fall damage is capped at 1500ft / 2 = 750
	assert_eq(PFGameMath.calculate_falling_damage(2000), 750)
	assert_eq(PFGameMath.calculate_falling_damage(1500), 750)
	
	# Soft surface reduces distance by 20, limited to depth
	assert_eq(PFGameMath.calculate_falling_damage(50, false, 50), 15) # 50 - 20 = 30 / 2 = 15
	assert_eq(PFGameMath.calculate_falling_damage(50, false, 10), 20) # 50 - 10 = 40 / 2 = 20
	
	# Intentional dive reduces distance by 30, limited to depth
	assert_eq(PFGameMath.calculate_falling_damage(50, true, 50), 10) # 50 - 30 = 20 / 2 = 10
	assert_eq(PFGameMath.calculate_falling_damage(50, true, 20), 15) # 50 - 20 = 30 / 2 = 15

func test_environmental_damage_roll():
	# Test that environmental damage rolls fall within the expected bounds
	for i in range(10):
		var minor = PFGameMath.get_environmental_damage_roll(&"minor")
		assert_between(minor, 1, 12) # 1d6 (min 1) to 2d6 (max 12)
		
		var moderate = PFGameMath.get_environmental_damage_roll(&"moderate")
		assert_between(moderate, 4, 36) # 4d6 (min 4) to 6d6 (max 36)
		
		var major = PFGameMath.get_environmental_damage_roll(&"major")
		assert_between(major, 8, 72) # 8d6 (min 8) to 12d6 (max 72)
		
		var massive = PFGameMath.get_environmental_damage_roll(&"massive")
		assert_between(massive, 18, 144) # 18d6 (min 18) to 24d6 (max 144)
