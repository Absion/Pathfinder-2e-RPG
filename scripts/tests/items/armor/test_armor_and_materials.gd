extends GutTest



func test_armor_property_rune_limits():
	var armor = PFArmor.new("Steel Breastplate", [], 1, 0, PFEquipmentConstants.ArmorCategory.MEDIUM, PFEquipmentConstants.ArmorGroup.COMPOSITE, 4, 1, -2, -5, 16)
	
	# Try to add property rune before applying potency (potency_bonus is 0)
	var added = armor.add_property_rune(PFEquipmentConstants.PropertyRune.GHOST_TOUCH)
	assert_false(added)
	
	# Apply +2 potency
	armor.apply_fundamental_runes(PFEquipmentConstants.PotencyRune.PLUS_TWO, PFEquipmentConstants.ResilientRune.NONE)
	
	added = armor.add_property_rune(PFEquipmentConstants.PropertyRune.GHOST_TOUCH)
	assert_true(added)
	
	added = armor.add_property_rune(PFEquipmentConstants.PropertyRune.FROST)
	assert_true(added)
	
	# Try to add a 3rd rune. Should fail because potency is only +2.
	added = armor.add_property_rune(PFEquipmentConstants.PropertyRune.SHOCK)
	assert_false(added)

func test_mithral_material_stats():
	# Standard armor
	var std_armor = PFArmor.new("Breastplate", [], 1, 0, PFEquipmentConstants.ArmorCategory.MEDIUM, PFEquipmentConstants.ArmorGroup.COMPOSITE, 4, 1, -2, -5, 16, PFEquipmentConstants.ItemMaterial.STEEL)
	assert_eq(std_armor.check_penalty, -2)
	assert_eq(std_armor.speed_penalty, -5)
	
	# Mithral armor should reduce check penalty and speed penalty by 1 and 5 respectively (bringing them closer to 0)
	var mith_armor = PFArmor.new("Mithral Breastplate", [], 1, 0, PFEquipmentConstants.ArmorCategory.MEDIUM, PFEquipmentConstants.ArmorGroup.COMPOSITE, 4, 1, -2, -5, 16, PFEquipmentConstants.ItemMaterial.MITHRAL, 0, 0, PFEquipmentConstants.MaterialGrade.STANDARD)
	assert_eq(mith_armor.check_penalty, -1)
	assert_eq(mith_armor.speed_penalty, 0)

func test_armor_specialization_effects():
	var defender = autofree(PFPlayerCharacter.new("Defender", [], 5, 50, 0, 0, 0))
	defender.has_armor_specialization = true
	
	# Equip Plate Armor (+1 Potency) -> Plate Specialization grants 2 (heavy) + 1 (potency) = 3 Slashing Resistance
	var plate = PFArmor.new("Full Plate", [], 2, 0, PFEquipmentConstants.ArmorCategory.HEAVY, PFEquipmentConstants.ArmorGroup.PLATE)
	plate.apply_fundamental_runes(PFEquipmentConstants.PotencyRune.PLUS_ONE, PFEquipmentConstants.ResilientRune.NONE)
	defender.inventory.add_item(plate)
	defender.inventory.equip_item(plate)
	
	# Slashing attack of 10 damage should be reduced by 3
	defender.take_damage(10, PFCombatConstants.DamageType.SLASHING)
	assert_eq(defender.health.current_hp, 43)
	
	# Equip Chain Armor (Medium, +2 Potency) -> Chain Specialization grants 4 (medium) + 2 (potency) = 6 Resistance vs Critical Hits
	var chain = PFArmor.new("Chain Shirt", [], 2, 0, PFEquipmentConstants.ArmorCategory.MEDIUM, PFEquipmentConstants.ArmorGroup.CHAIN)
	chain.apply_fundamental_runes(PFEquipmentConstants.PotencyRune.PLUS_TWO, PFEquipmentConstants.ResilientRune.NONE)
	defender.inventory.worn_items.clear()
	defender.inventory.equip_item(chain)
	
	# Normal hit 10 damage should be taken fully
	defender.take_damage(10, PFCombatConstants.DamageType.SLASHING)
	assert_eq(defender.health.current_hp, 33)
	
	# Critical hit 10 damage should be reduced by 6
	var traits: Array[StringName] = [&"critical"]
	defender.take_damage(10, PFCombatConstants.DamageType.SLASHING, traits)
	assert_eq(defender.health.current_hp, 29) # 33 - 4 = 29
