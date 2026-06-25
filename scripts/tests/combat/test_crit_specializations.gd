extends GutTest

var attacker: PFActor
var target: PFActor

func before_each():
	attacker = PFPlayerCharacter.new("Attacker", [&"humanoid"], 1, 20, 0, 0, 0)
	target = PFPlayerCharacter.new("Target", [&"humanoid"], 1, 20, 0, 0, 0)
	add_child(attacker)
	add_child(target)
	
	# Stub method for has_critical_specialization
	attacker.set_meta(&"has_crit_spec", true)

func _has_crit_spec(_group) -> bool:
	return true

func test_flail_crit_spec():
	var flail = PFWeapon.new("Flail", [], 1, 1.0, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.MARTIAL, PFEquipmentConstants.WeaponGroup.FLAIL, 1, 6, PFCombatConstants.DamageType.BLUDGEONING)
	
	var strike = PFActionStrike.new(flail)
	
	# We just test the isolated method directly to ensure the logic runs correctly without forcing a natural 20
	strike.weapon = flail
	strike._apply_critical_specialization(attacker, target)
	
	assert_true(target.has_condition(&"prone"))

func test_pick_crit_spec():
	var pick = PFWeapon.new("Pick", [], 1, 1.0, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.MARTIAL, PFEquipmentConstants.WeaponGroup.PICK, 1, 6, PFCombatConstants.DamageType.PIERCING)
	
	var initial_hp = target.health.current_hp
	
	var strike = PFActionStrike.new(pick)
	
	strike.weapon = pick
	strike._apply_critical_specialization(attacker, target)
	
	# Should deal 2 * dice_amount (1) = 2 damage directly
	assert_eq(target.health.current_hp, initial_hp - 2)

func test_knife_crit_spec():
	var knife = PFWeapon.new("Dagger", [], 1, 0.1, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.SIMPLE, PFEquipmentConstants.WeaponGroup.KNIFE, 2, 4, PFCombatConstants.DamageType.PIERCING)
	
	var strike = PFActionStrike.new(knife)
	
	strike.weapon = knife
	strike._apply_critical_specialization(attacker, target)
	
	assert_true(target.has_condition(&"persistent_damage"))
	var pd = target.get_condition(&"persistent_damage")
	assert_eq(pd.value, 2) # weapon has 2 dice
	assert_eq(pd.target_stat, "bleed")
