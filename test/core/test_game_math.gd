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
	assert_int(Math.apply_keeley_hero_point_reroll(5)).is_equal(15)
	assert_int(Math.apply_keeley_hero_point_reroll(9)).is_equal(19)
	
	# 10 and above remain unchanged
	assert_int(Math.apply_keeley_hero_point_reroll(10)).is_equal(10)
	assert_int(Math.apply_keeley_hero_point_reroll(11)).is_equal(11)
	assert_int(Math.apply_keeley_hero_point_reroll(20)).is_equal(20)
