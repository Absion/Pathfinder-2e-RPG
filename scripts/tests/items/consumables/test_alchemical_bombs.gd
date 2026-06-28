extends GutTest

var actor1: PFActor
var actor2: PFActor

func before_each():
	actor1 = autofree(PFPlayerCharacter.new("Alchemist", [&"humanoid"] as Array[StringName], 1, 15, 10, 10, 10))
	actor2 = autofree(PFPlayerCharacter.new("Goblin", [&"humanoid", &"goblin"] as Array[StringName], 1, 15, 10, 10, 10))
	add_child_autofree(actor1)
	add_child_autofree(actor2)

func test_bomb_splash_damage_on_hit():
	var bomb = autofree(PFAlchemicalBomb.new("alchemists_fire", "Alchemist's Fire", [&"alchemical", &"bomb", &"consumable", &"splash", &"fire", &"thrown"] as Array[StringName], 1, 3.0, PFCombatConstants.DamageType.FIRE))
	bomb.splash_damage = 2
	bomb.dice_amount = 1
	actor1.inventory.add_item(bomb)
	
	var strike_action = PFActionStrike.new(bomb)
	
	# Force a hit by granting a massive attack bonus
	actor1.attributes.attack_modifiers.add_modifier(PFModifier.new(100, PFMathConstants.ModifierType.UNTYPED, "force_hit"))
	
	actor1.inventory.equip_weapon(bomb)
	var initial_hp = actor2.health.current_hp
	assert_true(await strike_action.execute(actor1, actor2))
	
	# The bomb should be gone
	assert_false(bomb in actor1.inventory.items, "Bomb should be consumed after throwing.")
	
	# Target should have taken at least the splash damage plus base damage
	var hp_loss = initial_hp - actor2.health.current_hp
	assert_true(hp_loss >= 3, "Target should take base damage plus splash damage.")

func test_bomb_consumed_on_miss():
	var bomb = PFAlchemicalBomb.new("alchemists_fire", "Alchemist's Fire", [&"alchemical", &"bomb", &"consumable", &"splash", &"fire", &"thrown"] as Array[StringName], 1, 3.0, PFCombatConstants.DamageType.FIRE)
	bomb.splash_damage = 2
	bomb.dice_amount = 1
	actor1.inventory.add_item(bomb)
	
	var strike_action = PFActionStrike.new(bomb)
	
	# Don't modify attack — just let the random roll happen.
	# With attack bonus of -2 vs AC 10, most rolls will miss.
	# We test the bomb is consumed regardless of hit/miss.
	
	actor1.inventory.equip_weapon(bomb)
	assert_true(await strike_action.execute(actor1, actor2))
	
	# The bomb should be gone regardless of hit or miss
	assert_false(bomb in actor1.inventory.items, "Bomb should always be consumed when thrown.")
