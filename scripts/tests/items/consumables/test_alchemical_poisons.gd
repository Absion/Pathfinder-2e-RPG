extends GutTest

var actor1: PFActor
var actor2: PFActor

func before_each():
	actor1 = autofree(PFPlayerCharacter.new("Alchemist", [&"humanoid"] as Array[StringName], 1, 15, 10, 10, 10))
	actor2 = autofree(PFPlayerCharacter.new("Goblin", [&"humanoid", &"goblin"] as Array[StringName], 1, 15, 10, 10, 10))
	add_child_autofree(actor1)
	add_child_autofree(actor2)

func test_apply_and_deliver_poison():
	var poison = autofree(load("res://scripts/items/consumables/pf_alchemical_poison.gd").new("giant_centipede_venom", "Giant Centipede Venom", 1, "injury", &"giant_centipede_venom_affliction"))
	var dagger = autofree(PFWeapon.new("Dagger", [&"agile", &"finesse", &"thrown"] as Array[StringName], 1, 0, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.SIMPLE, PFEquipmentConstants.WeaponGroup.KNIFE, 1, 4, PFCombatConstants.DamageType.PIERCING))
	
	actor1.inventory.add_item(poison)
	actor1.inventory.add_item(dagger)
	
	var apply_action = load("res://scripts/actions/combat/pf_action_apply_poison.gd").new(poison, dagger)
	assert_true(await apply_action.execute(actor1))
	
	# Poison is applied and removed from inventory
	assert_false(poison in actor1.inventory.items)
	assert_not_null(dagger.injection_payload)
	
	actor1.inventory.equip_weapon(dagger)
	var strike = PFActionStrike.new(dagger)
	actor1.attributes.attack_modifiers.add_modifier(PFModifier.new(100, PFMathConstants.ModifierType.UNTYPED, "force_hit"))
	
	# Mock the apply_affliction method on actor2 to detect payload delivery
	actor2.set_meta(&"test_affliction", false)
	
	assert_true(await strike.execute(actor1, actor2))
	assert_null(dagger.injection_payload, "Payload should be cleared after hit.")
	
	# Dagger should be in target's inventory now with carry state DROPPED
	assert_true(dagger in actor2.inventory.items, "Thrown dagger should be passed to target inventory")
	assert_eq(dagger.carry_state, PFEquipmentConstants.CarryState.DROPPED, "Dagger carry state should be DROPPED")

func test_returning_rune():
	var dagger = PFWeapon.new("Dagger", [&"agile", &"finesse", &"thrown", &"returning"] as Array[StringName], 1, 0, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.SIMPLE, PFEquipmentConstants.WeaponGroup.KNIFE, 1, 4, PFCombatConstants.DamageType.PIERCING)
	actor1.inventory.add_item(dagger)
	
	actor1.inventory.equip_weapon(dagger)
	var strike = PFActionStrike.new(dagger)
	actor1.attributes.attack_modifiers.add_modifier(PFModifier.new(100, PFMathConstants.ModifierType.UNTYPED, "force_hit")) # Hit
	assert_true(await strike.execute(actor1, actor2))
	
	# Dagger should NOT be removed because it has returning
	assert_true(dagger in actor1.inventory.items)
