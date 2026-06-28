extends GutTest

func test_base_value():
	var stat = PFStat.new(10)
	assert_eq(stat.get_total(), 10)

func test_untyped_modifiers_stack():
	var stat = PFStat.new(10)
	stat.add_modifier(PFModifier.new(2, PFMathConstants.ModifierType.UNTYPED, "test1"))
	stat.add_modifier(PFModifier.new(3, PFMathConstants.ModifierType.UNTYPED, "test2"))
	stat.add_modifier(PFModifier.new(-1, PFMathConstants.ModifierType.UNTYPED, "test3"))
	assert_eq(stat.get_total(), 14)

func test_circumstance_bonus_stacking():
	var stat = PFStat.new(10)
	stat.add_modifier(PFModifier.new(1, PFMathConstants.ModifierType.CIRCUMSTANCE, "test1"))
	stat.add_modifier(PFModifier.new(3, PFMathConstants.ModifierType.CIRCUMSTANCE, "test2"))
	stat.add_modifier(PFModifier.new(2, PFMathConstants.ModifierType.CIRCUMSTANCE, "test3"))
	assert_eq(stat.get_total(), 13, "Only the highest circumstance bonus should apply")

func test_circumstance_penalty_stacking():
	var stat = PFStat.new(10)
	stat.add_modifier(PFModifier.new(-1, PFMathConstants.ModifierType.CIRCUMSTANCE, "test1"))
	stat.add_modifier(PFModifier.new(-3, PFMathConstants.ModifierType.CIRCUMSTANCE, "test2"))
	stat.add_modifier(PFModifier.new(-2, PFMathConstants.ModifierType.CIRCUMSTANCE, "test3"))
	assert_eq(stat.get_total(), 7, "Only the lowest circumstance penalty should apply")

func test_circumstance_bonus_and_penalty():
	var stat = PFStat.new(10)
	stat.add_modifier(PFModifier.new(2, PFMathConstants.ModifierType.CIRCUMSTANCE, "test1"))
	stat.add_modifier(PFModifier.new(-3, PFMathConstants.ModifierType.CIRCUMSTANCE, "test2"))
	assert_eq(stat.get_total(), 9, "Both the highest bonus and lowest penalty should apply")

func test_status_bonus_stacking():
	var stat = PFStat.new(10)
	stat.add_modifier(PFModifier.new(1, PFMathConstants.ModifierType.STATUS, "test1"))
	stat.add_modifier(PFModifier.new(4, PFMathConstants.ModifierType.STATUS, "test2"))
	assert_eq(stat.get_total(), 14)

func test_item_bonus_stacking():
	var stat = PFStat.new(10)
	stat.add_modifier(PFModifier.new(2, PFMathConstants.ModifierType.ITEM, "test1"))
	stat.add_modifier(PFModifier.new(5, PFMathConstants.ModifierType.ITEM, "test2"))
	assert_eq(stat.get_total(), 15)

func test_multiple_types_stacking():
	var stat = PFStat.new(10)
	stat.add_modifier(PFModifier.new(2, PFMathConstants.ModifierType.CIRCUMSTANCE, "test1"))
	stat.add_modifier(PFModifier.new(3, PFMathConstants.ModifierType.STATUS, "test2"))
	stat.add_modifier(PFModifier.new(1, PFMathConstants.ModifierType.ITEM, "test3"))
	stat.add_modifier(PFModifier.new(4, PFMathConstants.ModifierType.UNTYPED, "test4"))
	assert_eq(stat.get_total(), 20)

func test_remove_modifier():
	var stat = PFStat.new(10)
	stat.add_modifier(PFModifier.new(2, PFMathConstants.ModifierType.CIRCUMSTANCE, "test1"))
	stat.add_modifier(PFModifier.new(3, PFMathConstants.ModifierType.CIRCUMSTANCE, "test2"))
	assert_eq(stat.get_total(), 13)
	stat.remove_modifier_by_source("test2")
	assert_eq(stat.get_total(), 12)
