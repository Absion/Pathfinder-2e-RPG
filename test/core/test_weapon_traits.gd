extends GdUnitTestSuite

var attacker: PFActor
var defender: PFActor
var reach_weapon: PFWeapon
var versatile_weapon: PFWeapon
var nonlethal_weapon: PFWeapon
var parry_weapon: PFWeapon

func before_test():
	attacker = PFPlayerCharacter.new("Attacker", [&"humanoid"], 1, 20, 0, 0, 0)
	defender = PFPlayerCharacter.new("Defender", [&"humanoid"], 1, 20, 0, 0, 0)
	auto_free(attacker)
	auto_free(defender)
	add_child(attacker)
	add_child(defender)
	
	reach_weapon = PFWeapon.new("Halberd", [&"reach"], 1, 1.0, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.MARTIAL, PFEquipmentConstants.WeaponGroup.POLEARM, 1, 10, PFCombatConstants.DamageType.PIERCING)
	versatile_weapon = PFWeapon.new("Longsword", [&"versatile p"], 1, 1.0, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.MARTIAL, PFEquipmentConstants.WeaponGroup.SWORD, 1, 8, PFCombatConstants.DamageType.SLASHING)
	nonlethal_weapon = PFWeapon.new("Sap", [&"nonlethal", &"agile"], 1, 0.1, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.SIMPLE, PFEquipmentConstants.WeaponGroup.CLUB, 1, 6, PFCombatConstants.DamageType.BLUDGEONING)
	parry_weapon = PFWeapon.new("Main-gauche", [&"parry", &"finesse", &"agile"], 1, 0.5, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.MARTIAL, PFEquipmentConstants.WeaponGroup.KNIFE, 1, 4, PFCombatConstants.DamageType.PIERCING)
	
	auto_free(reach_weapon)
	auto_free(versatile_weapon)
	auto_free(nonlethal_weapon)
	auto_free(parry_weapon)
	
	attacker.global_position = Vector3(0, 0, 0)
	defender.global_position = Vector3(0, 0, 0)

func test_reach_trait():
	defender.global_position = Vector3(10, 0, 0) # 10 feet away
	
	# Normal weapon should fail
	attacker.inventory.add_item(versatile_weapon)
	attacker.inventory.equip_weapon(versatile_weapon, 1)
	var strike = PFActionStrike.new(versatile_weapon)
	auto_free(strike)
	var success = await strike.execute(attacker, defender)
	assert_bool(success).is_false()
	
	# Reach weapon should succeed
	attacker.inventory.add_item(reach_weapon)
	attacker.inventory.equip_weapon(reach_weapon, 2)
	var reach_strike = PFActionStrike.new(reach_weapon)
	auto_free(reach_strike)
	var reach_success = await reach_strike.execute(attacker, defender)
	assert_bool(reach_success).is_true()

func test_versatile_trait():
	attacker.inventory.add_item(versatile_weapon)
	attacker.inventory.equip_weapon(versatile_weapon, 1)
	var strike = PFActionStrike.new(versatile_weapon, false, PFCombatConstants.DamageType.PIERCING)
	auto_free(strike)
	await strike.execute(attacker, defender)
	# Longsword should deal piercing damage now due to versatile p
	assert_int(versatile_weapon.active_damage_type).is_equal(PFCombatConstants.DamageType.SLASHING) # Base type shouldn't change
	
	var strike2 = PFActionStrike.new(versatile_weapon)
	auto_free(strike2)
	# By default it's slashing

func test_nonlethal_trait():
	var _initial_hp = defender.health.current_hp
	
	# Lethal attack with nonlethal weapon (-2 penalty)
	attacker.inventory.add_item(nonlethal_weapon)
	attacker.inventory.equip_weapon(nonlethal_weapon, 1)
	var strike = PFActionStrike.new(nonlethal_weapon, false)
	auto_free(strike)
	await strike.execute(attacker, defender)
	
	# Nonlethal attack with nonlethal weapon (no penalty)
	var strike2 = PFActionStrike.new(nonlethal_weapon, true)
	auto_free(strike2)
	await strike2.execute(attacker, defender)

func test_parry_action():
	attacker.inventory.add_item(parry_weapon)
	attacker.inventory.equip_weapon(parry_weapon, 1)
	var initial_ac = attacker.get_ac()
	var parry_action = PFActionParry.new(parry_weapon)
	auto_free(parry_action)
	
	var success = await parry_action.execute(attacker)
	assert_bool(success).is_true()
	
	var new_ac = attacker.get_ac()
	assert_int(new_ac).is_equal(initial_ac + 1)
