extends GutTest



func test_rest_healing():
	# Player level 2, CON modifier +2, max hp 30.
	var player = PFPlayerCharacter.new("Valeros", [&"human", &"humanoid"], 2, 30, 0, 0, 0)
	player.attributes.apply_background_boost(&"con")
	player.attributes.apply_class_boost(&"con")
	# CON mod should be +2
	
	# Damage the player
	player.take_damage(10)
	assert_eq(player.health.current_hp, 20)
	
	# Trigger rest. Should heal Level (2) * Con Mod (2) = 4 HP.
	player._on_rested_for_night()
	
	assert_eq(player.health.current_hp, 24)

func test_rest_condition_decay():
	var player = PFPlayerCharacter.new("Valeros", [&"human", &"humanoid"], 1, 30, 0, 0, 0)
	player.attributes.con_mod = 1
	
	player.apply_condition(PFCondition.create("doomed", 2))
	player.apply_condition(PFCondition.create("drained", 1))
	player.apply_condition(PFCondition.create("fatigued", 1))
	
	player._on_rested_for_night()
	
	# Doomed should drop from 2 to 1
	assert_true(player.has_condition("doomed"))
	assert_eq(player.get_condition("doomed").value, 1)
	
	# Drained should drop from 1 to 0 (removed)
	assert_false(player.has_condition("drained"))
	
	# Fatigued should be completely removed
	assert_false(player.has_condition("fatigued"))

func test_rest_minimum_healing():
	# CON modifier -1, level 5
	var player = PFPlayerCharacter.new("Ezren", [&"human", &"humanoid"], 5, 30, 0, 0, 0)
	player.attributes.apply_voluntary_flaw(&"con") 
	# CON mod should be -1 
	
	player.take_damage(10)
	assert_eq(player.health.current_hp, 20)
	
	# Con mod (-1) acts as minimum 1. 1 * Level (5) = 5.
	player._on_rested_for_night()
	
	# Minimum healing logic: Level 5 * max(1, -1) = 5
	assert_eq(player.health.current_hp, 25)

func test_rest_sleeping_in_armor():
	var player = PFPlayerCharacter.new("Kyra", [&"human", &"humanoid"], 1, 30, 0, 0, 0)
	
	# 1. Unarmored -> NO FATIGUE
	player._on_rested_for_night()
	assert_false(player.has_condition("fatigued"))
	
	# 2. Light Armor -> NO FATIGUE
	var leather = PFArmor.new("Leather Armor", [], 1, 0, PFEquipmentConstants.ArmorCategory.LIGHT, PFEquipmentConstants.ArmorGroup.LEATHER)
	player.inventory.equip_item(leather)
	player._on_rested_for_night()
	assert_false(player.has_condition("fatigued"))
	
	# 3. Medium Armor -> FATIGUE
	player.inventory.worn_items.clear()
	var chain = PFArmor.new("Chain Shirt", [], 2, 0, PFEquipmentConstants.ArmorCategory.MEDIUM, PFEquipmentConstants.ArmorGroup.CHAIN)
	player.inventory.equip_item(chain)
	player._on_rested_for_night()
	assert_true(player.has_condition("fatigued"))
	
	# 4. Remove fatigue, test comfort trait on Medium Armor
	player.remove_condition("fatigued")
	player.inventory.worn_items.clear()
	var chain_comfort = PFArmor.new("Comfort Chain", [&"comfort"], 2, 0, PFEquipmentConstants.ArmorCategory.MEDIUM, PFEquipmentConstants.ArmorGroup.CHAIN)
	player.inventory.equip_item(chain_comfort)
	player._on_rested_for_night()
	assert_false(player.has_condition("fatigued"))
