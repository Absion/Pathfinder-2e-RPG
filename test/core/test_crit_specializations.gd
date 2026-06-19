extends GdUnitTestSuite

var attacker: PFActor
var target: PFActor

func before_test():
	attacker = PFPlayerCharacter.new("Attacker", [&"humanoid"], 1, 20, 0, 0, 0)
	target = PFPlayerCharacter.new("Target", [&"humanoid"], 1, 20, 0, 0, 0)
	auto_free(attacker)
	auto_free(target)
	add_child(attacker)
	add_child(target)
	
	# Stub method for has_critical_specialization
	attacker.set_meta(&"has_crit_spec", true)

func _has_crit_spec(_group) -> bool:
	return true

func test_flail_crit_spec():
	var flail = PFWeapon.new("Flail", [], 1, 1.0, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.MARTIAL, PFEquipmentConstants.WeaponGroup.FLAIL, 1, 6, PFCombatConstants.DamageType.BLUDGEONING)
	auto_free(flail)
	
	var strike = PFActionStrike.new(flail)
	auto_free(strike)
	
	# We just test the isolated method directly to ensure the logic runs correctly without forcing a natural 20
	strike.weapon = flail
	strike._apply_critical_specialization(attacker, target)
	
	assert_bool(target.has_condition(&"prone")).is_true()

func test_pick_crit_spec():
	var pick = PFWeapon.new("Pick", [], 1, 1.0, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.MARTIAL, PFEquipmentConstants.WeaponGroup.PICK, 1, 6, PFCombatConstants.DamageType.PIERCING)
	auto_free(pick)
	
	var initial_hp = target.health.current_hp
	
	var strike = PFActionStrike.new(pick)
	auto_free(strike)
	
	strike.weapon = pick
	strike._apply_critical_specialization(attacker, target)
	
	# Should deal 2 * dice_amount (1) = 2 damage directly
	assert_int(target.health.current_hp).is_equal(initial_hp - 2)

func test_knife_crit_spec():
	var knife = PFWeapon.new("Dagger", [], 1, 0.1, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.SIMPLE, PFEquipmentConstants.WeaponGroup.KNIFE, 2, 4, PFCombatConstants.DamageType.PIERCING)
	auto_free(knife)
	
	var strike = PFActionStrike.new(knife)
	auto_free(strike)
	
	strike.weapon = knife
	strike._apply_critical_specialization(attacker, target)
	
	assert_bool(target.has_condition(&"persistent_damage")).is_true()
	var pd = target.get_condition(&"persistent_damage")
	assert_int(pd.value).is_equal(2) # weapon has 2 dice
	assert_str(pd.target_stat).is_equal("bleed")
