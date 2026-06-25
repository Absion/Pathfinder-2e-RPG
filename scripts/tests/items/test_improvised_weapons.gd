extends GutTest

var attacker: PFActor
var target: PFActor

func before_each():
	attacker = PFPlayerCharacter.new("Scavenger", [&"humanoid"], 1, 20, 0, 0, 0)
	target = PFPlayerCharacter.new("Target", [&"humanoid"], 1, 20, 0, 0, 0)
	add_child(attacker)
	add_child(target)
	
	attacker.global_position = Vector3(0, 0, 0)
	target.global_position = Vector3(0, 0, 0)

func test_improvised_factory():
	var mug = PFItem.new("Wooden Mug", [&"wood"])
	var weapon = PFWeapon.create_improvised(mug, PFCombatConstants.DamageType.BLUDGEONING)
	
	assert_true(weapon.is_improvised)
	assert_eq(weapon.dice_amount, 1)
	assert_eq(weapon.die_faces, 4)
	assert_eq(weapon.active_damage_type, PFCombatConstants.DamageType.BLUDGEONING)

func test_scavenge_forest():
	var _action = PFActionScavenge.new([&"forest"])
	var success = _action.execute(attacker)
	
	assert_true(success)
	var inv = attacker.get(&"inventory") as PFInventory
	var held = inv.held_main_hand as PFWeapon
	assert_not_null(held)
	assert_eq(held.entity_name, "Improvised Sturdy Branch")
	assert_true(held.has_trait(&"wood"))

func test_scavenge_road():
	# Ensure hands are free again
	var inv = attacker.get(&"inventory") as PFInventory
	inv.held_main_hand = null
	
	var _action = PFActionScavenge.new([&"road"])
	var success = _action.execute(attacker)
	
	assert_true(success)
	var held = inv.held_main_hand as PFWeapon
	assert_not_null(held)
	assert_eq(held.entity_name, "Improvised Loose Rock")
	assert_true(held.has_trait(&"thrown"))
	assert_eq(held.range_increment, 10)
