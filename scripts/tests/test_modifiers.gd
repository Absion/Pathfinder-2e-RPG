extends SceneTree

class_name TestModifiers

func get_test_name() -> String:
	return "Bonus Stacking Rules Tests"

func _init() -> void:
	run_test()
	quit()

func run_test() -> void:
	print("\n--- Running Modifier Stacking Tests ---")
	
	var pc = PFPlayerCharacter.new("Test Actor", [&"humanoid"], 1, 10, 0, 0, 0)
	
	# The PFStat handles modifier stacking. We'll test with the DC modifiers.
	var dc_stat = pc.attributes.dc_modifiers
	
	# Initial base should be 0 since dc_modifiers has base 0
	assert_eq(dc_stat.get_total(), 0, "Base DC modifier should be 0")
	
	# Apply an Item Bonus
	var mod1 = PFModifier.new(1, PFMathConstants.ModifierType.ITEM, "item1")
	dc_stat.add_modifier(mod1)
	assert_eq(dc_stat.get_total(), 1, "DC modifier should be 1 after item bonus")
	
	# Apply a larger Item Bonus
	var mod2 = PFModifier.new(3, PFMathConstants.ModifierType.ITEM, "item2")
	dc_stat.add_modifier(mod2)
	assert_eq(dc_stat.get_total(), 3, "DC modifier should be 3 (higher item bonus overrides)")
	
	# Apply a smaller Item Bonus (should still be 3)
	var mod3 = PFModifier.new(2, PFMathConstants.ModifierType.ITEM, "item3")
	dc_stat.add_modifier(mod3)
	assert_eq(dc_stat.get_total(), 3, "DC modifier should still be 3")
	
	# Apply a Status Bonus
	var mod4 = PFModifier.new(2, PFMathConstants.ModifierType.STATUS, "status1")
	dc_stat.add_modifier(mod4)
	assert_eq(dc_stat.get_total(), 5, "DC modifier should be 5 (3 item + 2 status)")
	
	# Apply an untyped bonus
	var mod5 = PFModifier.new(1, PFMathConstants.ModifierType.UNTYPED, "untyped1")
	dc_stat.add_modifier(mod5)
	assert_eq(dc_stat.get_total(), 6, "DC modifier should be 6 (3 item + 2 status + 1 untyped)")
	
	# Test equipment adding modifiers
	var goggles = PFEquipment.new("goggles")
	goggles.entity_name = "Sniper Goggles"
	goggles.skill_bonus_data = {"attack": 2}
	
	pc.inventory.add_item(goggles)
	pc.inventory.equip_item(goggles)
	
	# Goggles give +2 item bonus to attack. Let's see if attack modifier is 2.
	assert_eq(pc.attributes.attack_modifiers.get_total(), 2, "Attack modifier should be 2 from goggles")
	
	# Unequip should remove it
	pc.inventory.unequip_item(goggles)
	assert_eq(pc.attributes.attack_modifiers.get_total(), 0, "Attack modifier should be 0 after unequipping goggles")
	
	print("Modifier stacking tests passed!")
