extends GutTest

var user: PFActor
var target: PFActor

func before_all():
	pass

func before_each():
	PFContext.init_shared_services()
	# The PFActionFlurry might check detection or reactions if it delegates to execute
	# So we null out detection manager to avoid mock issues
	PFContext.detection_manager = null

	user = autofree(PFPlayerCharacter.new("Monk", [], 1, 20, 0, 0, 0))
	target = autofree(PFPlayerCharacter.new("Dummy", [], 1, 20, 0, 0, 0))
	add_child_autofree(user)
	add_child_autofree(target)

func after_each():
	PFContext.cleanup_shared_services()

# --- HAPPY PATH TESTS ---

func test_flurry_of_blows_valid_unarmed():
	var unarmed = PFWeapon.new("Fist", [&"agile", &"finesse", &"nonlethal", &"unarmed"], 1, 0.0, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.UNARMED, PFEquipmentConstants.WeaponGroup.BRAWLING, 1, 4, PFCombatConstants.DamageType.BLUDGEONING)

	var flurry = PFActionFlurry.new(unarmed)
	var success = await flurry.execute(user, target)
	assert_true(success)

func test_flurry_of_blows_monk_weapon():
	var temple_sword = PFWeapon.new("Temple Sword", [&"monk"], 1, 1.0, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.MARTIAL, PFEquipmentConstants.WeaponGroup.SWORD, 1, 8, PFCombatConstants.DamageType.SLASHING)

	# Try with monastic weaponry
	var flurry_valid = PFActionFlurry.new(temple_sword, true)
	assert_true(await flurry_valid.execute(user, target))

func test_flurry_of_blows_archer_stance_shortbow():
	var shortbow = PFWeapon.new("Shortbow", [&"deadly d10"], 1, 1.0, PFEquipmentConstants.WeaponType.RANGED, PFEquipmentConstants.WeaponCategory.MARTIAL, PFEquipmentConstants.WeaponGroup.BOW, 1, 6, PFCombatConstants.DamageType.PIERCING)

	var flurry = PFActionFlurry.new(shortbow, false, true)
	assert_true(await flurry.execute(user, target))

func test_flurry_of_blows_archer_stance_longbow():
	var longbow = PFWeapon.new("Longbow", [&"deadly d10", &"volley 30"], 1, 1.0, PFEquipmentConstants.WeaponType.RANGED, PFEquipmentConstants.WeaponCategory.MARTIAL, PFEquipmentConstants.WeaponGroup.BOW, 1, 8, PFCombatConstants.DamageType.PIERCING)

	var flurry = PFActionFlurry.new(longbow, false, true)
	assert_true(await flurry.execute(user, target))

func test_flurry_of_blows_archer_stance_monk_bow():
	var monk_bow = PFWeapon.new("Custom Monk Bow", [&"monk"], 1, 1.0, PFEquipmentConstants.WeaponType.RANGED, PFEquipmentConstants.WeaponCategory.MARTIAL, PFEquipmentConstants.WeaponGroup.BOW, 1, 6, PFCombatConstants.DamageType.PIERCING)

	var flurry = PFActionFlurry.new(monk_bow, false, true)
	assert_true(await flurry.execute(user, target))

# --- ERROR PATH TESTS ---

func test_flurry_of_blows_null_target():
	var unarmed = PFWeapon.new("Fist", [&"unarmed"], 1, 0.0, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.UNARMED, PFEquipmentConstants.WeaponGroup.BRAWLING, 1, 4, PFCombatConstants.DamageType.BLUDGEONING)

	var flurry = PFActionFlurry.new(unarmed)
	# Should fail because target is null
	var success = await flurry.execute(user, null)
	assert_false(success)

func test_flurry_of_blows_invalid_sword():
	var sword = PFWeapon.new("Longsword", [&"versatile p"], 1, 1.0, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.MARTIAL, PFEquipmentConstants.WeaponGroup.SWORD, 1, 8, PFCombatConstants.DamageType.SLASHING)

	var flurry = PFActionFlurry.new(sword)
	var success = await flurry.execute(user, target)
	assert_false(success)

func test_flurry_of_blows_monk_weapon_no_feat():
	var temple_sword = PFWeapon.new("Temple Sword", [&"monk"], 1, 1.0, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.MARTIAL, PFEquipmentConstants.WeaponGroup.SWORD, 1, 8, PFCombatConstants.DamageType.SLASHING)

	# Try without monastic weaponry
	var flurry_invalid = PFActionFlurry.new(temple_sword, false)
	assert_false(await flurry_invalid.execute(user, target))

func test_flurry_of_blows_archer_stance_invalid_crossbow():
	var crossbow = PFWeapon.new("Crossbow", [], 1, 1.0, PFEquipmentConstants.WeaponType.RANGED, PFEquipmentConstants.WeaponCategory.SIMPLE, PFEquipmentConstants.WeaponGroup.CROSSBOW, 1, 8, PFCombatConstants.DamageType.PIERCING)

	var flurry = PFActionFlurry.new(crossbow, false, true)
	assert_false(await flurry.execute(user, target))

func test_flurry_of_blows_archer_stance_invalid_unarmed():
	var unarmed = PFWeapon.new("Fist", [&"unarmed"], 1, 0.0, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.UNARMED, PFEquipmentConstants.WeaponGroup.BRAWLING, 1, 4, PFCombatConstants.DamageType.BLUDGEONING)

	var flurry = PFActionFlurry.new(unarmed, false, true)
	assert_false(await flurry.execute(user, target))
