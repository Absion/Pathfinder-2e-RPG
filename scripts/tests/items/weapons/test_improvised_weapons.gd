extends GutTest

var attacker: PFActor
var target: PFActor

func before_each():
	PFContext.init_shared_services()
	attacker = autofree(PFPlayerCharacter.new("Scavenger", [&"humanoid"], 1, 20, 0, 0, 0))
	target = autofree(PFPlayerCharacter.new("Target", [&"humanoid"], 1, 20, 0, 0, 0))
	add_child_autofree(attacker)
	add_child_autofree(target)
	
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
	var inventory = attacker.get(&"inventory") as PFInventory
	var held = inventory.held_main_hand as PFWeapon
	assert_not_null(held)
	assert_eq(held.entity_name, "Improvised Sturdy Branch")
	assert_true(held.has_trait(&"wood"))

func test_scavenge_road():
	# Ensure hands are free again
	var inventory = attacker.get(&"inventory") as PFInventory
	inventory.held_main_hand = null
	
	var _action = PFActionScavenge.new([&"road"])
	var success = _action.execute(attacker)
	
	assert_true(success)
	var held = inventory.held_main_hand as PFWeapon
	assert_not_null(held)
	assert_eq(held.entity_name, "Improvised Loose Rock")
	assert_true(held.has_trait(&"thrown"))
	assert_eq(held.range_increment, 10)


func after_each():
	PFContext.cleanup_shared_services()
