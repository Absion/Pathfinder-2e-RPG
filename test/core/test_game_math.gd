extends GdUnitTestSuite

const Math = preload("res://scripts/core/pf_game_math.gd")
const Consts = preload("res://scripts/combat/constants/pf_combat_constants.gd")
const MathConsts = preload("res://scripts/core/constants/pf_math_constants.gd")

func test_get_dc_by_level():
	assert_int(Math.get_dc_by_level(0)).is_equal(14)
	assert_int(Math.get_dc_by_level(1)).is_equal(15)
	assert_int(Math.get_dc_by_level(20)).is_equal(40)
	assert_int(Math.get_dc_by_level(25)).is_equal(50)
	# test clamping
	assert_int(Math.get_dc_by_level(-5)).is_equal(14)
	assert_int(Math.get_dc_by_level(100)).is_equal(50)

func test_get_simple_dc():
	assert_int(Math.get_simple_dc(MathConsts.ProficiencyRank.UNTRAINED)).is_equal(10)
	assert_int(Math.get_simple_dc(MathConsts.ProficiencyRank.TRAINED)).is_equal(15)
	assert_int(Math.get_simple_dc(MathConsts.ProficiencyRank.EXPERT)).is_equal(20)
	assert_int(Math.get_simple_dc(MathConsts.ProficiencyRank.MASTER)).is_equal(30)
	assert_int(Math.get_simple_dc(MathConsts.ProficiencyRank.LEGENDARY)).is_equal(40)

func test_adjust_dc():
	assert_int(Math.adjust_dc(15, &"incredibly_easy")).is_equal(5)
	assert_int(Math.adjust_dc(15, &"hard")).is_equal(17)
	assert_int(Math.adjust_dc(15, &"incredibly_hard")).is_equal(25)
	assert_int(Math.adjust_dc(15, &"invalid_adj")).is_equal(15)

func test_degree_of_success():
	var dc = 15
	# Normal rolls
	assert_int(Math.get_degree_of_success(25, dc)).is_equal(Consts.DegreeOfSuccess.CRITICAL_SUCCESS)
	assert_int(Math.get_degree_of_success(15, dc)).is_equal(Consts.DegreeOfSuccess.SUCCESS)
	assert_int(Math.get_degree_of_success(14, dc)).is_equal(Consts.DegreeOfSuccess.FAILURE)
	assert_int(Math.get_degree_of_success(5, dc)).is_equal(Consts.DegreeOfSuccess.CRITICAL_FAILURE)
	
	# Nat 20 bumps
	assert_int(Math.get_degree_of_success(25, dc, false, true)).is_equal(Consts.DegreeOfSuccess.CRITICAL_SUCCESS) # Can't go higher
	assert_int(Math.get_degree_of_success(15, dc, false, true)).is_equal(Consts.DegreeOfSuccess.CRITICAL_SUCCESS) # S -> CS
	assert_int(Math.get_degree_of_success(14, dc, false, true)).is_equal(Consts.DegreeOfSuccess.SUCCESS) # F -> S
	assert_int(Math.get_degree_of_success(5, dc, false, true)).is_equal(Consts.DegreeOfSuccess.FAILURE) # CF -> F
	
	# Nat 1 bumps
	assert_int(Math.get_degree_of_success(25, dc, true, false)).is_equal(Consts.DegreeOfSuccess.SUCCESS) # CS -> S
	assert_int(Math.get_degree_of_success(15, dc, true, false)).is_equal(Consts.DegreeOfSuccess.FAILURE) # S -> F
	assert_int(Math.get_degree_of_success(14, dc, true, false)).is_equal(Consts.DegreeOfSuccess.CRITICAL_FAILURE) # F -> CF
	assert_int(Math.get_degree_of_success(5, dc, true, false)).is_equal(Consts.DegreeOfSuccess.CRITICAL_FAILURE) # Can't go lower

func test_keeley_rule():
	# 1 to 9 gets +10
	assert_int(Math.apply_keeley_hero_point_reroll(1)).is_equal(11)
	assert_int(Math.apply_keeley_hero_point_reroll(8)).is_equal(18)
	assert_int(Math.apply_keeley_hero_point_reroll(9)).is_equal(19)
	
	# Results 10-20 are unchanged
	assert_int(Math.apply_keeley_hero_point_reroll(10)).is_equal(10)
	assert_int(Math.apply_keeley_hero_point_reroll(15)).is_equal(15)
	assert_int(Math.apply_keeley_hero_point_reroll(20)).is_equal(20)

func test_falling_damage():
	# Standard falling: half distance
	assert_int(Math.calculate_falling_damage(10)).is_equal(5)
	assert_int(Math.calculate_falling_damage(30)).is_equal(15)
	assert_int(Math.calculate_falling_damage(100)).is_equal(50)
	
	# <= 5 feet is no damage
	assert_int(Math.calculate_falling_damage(5)).is_equal(0)
	assert_int(Math.calculate_falling_damage(4)).is_equal(0)
	
	# Max fall damage is capped at 1500ft / 2 = 750
	assert_int(Math.calculate_falling_damage(2000)).is_equal(750)
	assert_int(Math.calculate_falling_damage(1500)).is_equal(750)
	
	# Soft surface reduces distance by 20, limited to depth
	assert_int(Math.calculate_falling_damage(50, false, 50)).is_equal(15) # 50 - 20 = 30 / 2 = 15
	assert_int(Math.calculate_falling_damage(50, false, 10)).is_equal(20) # 50 - 10 = 40 / 2 = 20
	
	# Intentional dive reduces distance by 30, limited to depth
	assert_int(Math.calculate_falling_damage(50, true, 50)).is_equal(10) # 50 - 30 = 20 / 2 = 10
	assert_int(Math.calculate_falling_damage(50, true, 20)).is_equal(15) # 50 - 20 = 30 / 2 = 15

func test_environmental_damage_roll():
	# Test that environmental damage rolls fall within the expected bounds
	for i in range(10):
		var minor = Math.get_environmental_damage_roll(&"minor")
		assert_int(minor).is_between(1, 12) # 1d6 (min 1) to 2d6 (max 12)
		
		var moderate = Math.get_environmental_damage_roll(&"moderate")
		assert_int(moderate).is_between(4, 36) # 4d6 (min 4) to 6d6 (max 36)
		
		var major = Math.get_environmental_damage_roll(&"major")
		assert_int(major).is_between(8, 72) # 8d6 (min 8) to 12d6 (max 72)
		
		var massive = Math.get_environmental_damage_roll(&"massive")
		assert_int(massive).is_between(18, 144) # 18d6 (min 18) to 24d6 (max 144)
