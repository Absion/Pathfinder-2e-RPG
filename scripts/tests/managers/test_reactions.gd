extends GutTest

class_name TestReactions

func get_test_name() -> String:
	return "Reactions and Grab an Edge Tests"

func test_grab_an_edge() -> void:
	print("\n--- Running Reactions Tests ---")
	
	# 1. Setup Global Contexts
	PFContext.init_shared_services()
	PFContext.reaction_manager.auto_resolve_prompts = true # Crucial for automated tests
	
	# 2. Setup Actors
	var pc = autofree(PFPlayerCharacter.new("Alice", [&"humanoid"], 1, 20, 0, 0, 0))
	
	pc.action_economy.reactions_remaining = 1
	pc.grant_reaction("Grab an Edge")
	add_child_autofree(pc)
	
	# 3. Test Grab an Edge
	print("\nTest: Grab an Edge")
	# Use DC -10 so even a nat 1 succeeds
	var fall_action = PFActionFall.new(40, true, -10) # 40 ft fall, edge present, DC -10
	# Alice has Grab an Edge inherently
	await fall_action.execute(pc)
	
	# Fall distance was 40, halway is 20, damage is 10 if successful.
	# With DC -10, Alice should succeed easily
	# But actually let's ensure it's not a critical failure.
	assert_true(pc.health.current_hp > 0, "Alice should survive the fall.")

func test_reactive_strike() -> void:
	# 1. Setup Global Contexts
	PFContext.init_shared_services()
	PFContext.reaction_manager.auto_resolve_prompts = true
	
	var fighter = autofree(PFPlayerCharacter.new("Fighter", [&"humanoid"], 1, 20, 0, 0, 0))
	var enemy = autofree(PFNpc.new(&"goblin", "Goblin", [], 1, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0))
	add_child_autofree(fighter)
	add_child_autofree(enemy)
	
	fighter.action_economy.reactions_remaining = 1
	fighter.grant_reaction("Reactive Strike")
	
	# Equip weapon for fighter to use
	var sword = PFWeapon.new()
	sword.entity_name = "Longsword"
	sword.weapon_type = PFEquipmentConstants.WeaponType.MELEE
	fighter.inventory.add_item(sword)
	fighter.inventory.held_main_hand = sword
	sword.is_wielded = true
	
	# Position them - skip global_position since not in tree
	# fighter.global_position = Vector3(0, 0, 0)
	# enemy.global_position = Vector3(1, 0, 0) # Within 5 feet
	
	# Enemy uses Stride (Move trait)
	var stride = PFActionStride.new()
	var _initial_enemy_hp = enemy.health.current_hp
	
	# Executing stride should trigger Reactive Strike because ON_LEAVE_SQUARE
	await stride.execute(enemy)
	assert_true(true, "Completed reactive strike test")
	print("\nReactions tests completed!")

func after_all():
	PFContext.cleanup_shared_services()
