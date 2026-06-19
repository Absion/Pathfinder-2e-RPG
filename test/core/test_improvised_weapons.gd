extends GdUnitTestSuite

var attacker: PFActor
var target: PFActor

func before_test():
	attacker = PFPlayerCharacter.new("Scavenger", [&"humanoid"], 1, 20, 0, 0, 0)
	target = PFPlayerCharacter.new("Target", [&"humanoid"], 1, 20, 0, 0, 0)
	auto_free(attacker)
	auto_free(target)
	add_child(attacker)
	add_child(target)
	
	attacker.global_position = Vector3(0, 0, 0)
	target.global_position = Vector3(0, 0, 0)

func test_improvised_factory():
	var mug = PFItem.new("Wooden Mug", [&"wood"])
	auto_free(mug)
	var weapon = PFWeapon.create_improvised(mug, PFCombatConstants.DamageType.BLUDGEONING)
	auto_free(weapon)
	
	assert_bool(weapon.is_improvised).is_true()
	assert_int(weapon.dice_amount).is_equal(1)
	assert_int(weapon.die_faces).is_equal(4)
	assert_int(weapon.active_damage_type).is_equal(PFCombatConstants.DamageType.BLUDGEONING)

func test_scavenge_forest():
	var action = PFActionScavenge.new([&"forest"])
	auto_free(action)
	var success = await action.execute(attacker)
	
	assert_bool(success).is_true()
	var inv = attacker.get(&"inventory") as PFInventory
	var held = inv.held_main_hand as PFWeapon
	assert_object(held).is_not_null()
	assert_str(held.entity_name).is_equal("Improvised Sturdy Branch")
	assert_bool(held.has_trait(&"wood")).is_true()

func test_scavenge_road():
	# Ensure hands are free again
	var inv = attacker.get(&"inventory") as PFInventory
	inv.held_main_hand = null
	
	var action = PFActionScavenge.new([&"road"])
	auto_free(action)
	var success = await action.execute(attacker)
	
	assert_bool(success).is_true()
	var held = inv.held_main_hand as PFWeapon
	assert_object(held).is_not_null()
	assert_str(held.entity_name).is_equal("Improvised Loose Rock")
	assert_bool(held.has_trait(&"thrown")).is_true()
	assert_int(held.range_increment).is_equal(10)
