extends SceneTree

class_name TestReactions

func get_test_name() -> String:
	return "Reactions and Grab an Edge Tests"

func _init() -> void:
	run_test()
	quit()

func run_test() -> void:
	print("\n--- Running Reactions Tests ---")
	
	# 1. Setup Global Contexts
	PFContext.init_shared_services()
	PFContext.reaction_manager.auto_resolve_prompts = true # Crucial for automated tests
	
	# 2. Setup Actors
	var pc = PFPlayerCharacter.new("Alice", [&"humanoid"], 1, 20, 0, 0, 0)
	var enemy = PFNpc.new("Goblin", [], 1, 10, 0, 0, 0)
	
	pc.action_economy.reactions_remaining = 1
	enemy.action_economy.reactions_remaining = 1
	
	# 3. Test Grab an Edge
	print("\nTest: Grab an Edge")
	var fall_action = PFActionFall.new(40, true, 5) # 40 ft fall, edge present, DC 5
	# Alice has Grab an Edge inherently
	await fall_action.execute(pc)
	
	# Fall distance was 40, halway is 20, damage is 10 if successful.
	# With DC 5, Alice should succeed easily (modifier is 0, average roll is 10 -> success)
	# But actually let's ensure it's not a critical failure.
	assert_true(pc.health.current_hp > 0, "Alice should survive the fall.")
	
	# 4. Test Reactive Strike
	print("\nTest: Reactive Strike")
	var fighter = PFPlayerCharacter.new("Fighter", [&"humanoid"], 1, 20, 0, 0, 0)
	fighter.action_economy.reactions_remaining = 1
	fighter.grant_reaction("Reactive Strike")
	
	# Equip weapon for fighter to use
	var sword = PFWeapon.new()
	sword.entity_name = "Longsword"
	sword.weapon_type = PFEquipmentConstants.WeaponType.MELEE
	fighter.inventory.add_item(sword)
	fighter.inventory.equip_item(sword)
	
	# Position them
	fighter.global_position = Vector3(0, 0, 0)
	enemy.global_position = Vector3(1, 0, 0) # Within 5 feet
	
	# Enemy uses Stride (Move trait)
	var stride = PFActionStride.new(Vector3(10, 0, 0))
	var initial_enemy_hp = enemy.health.current_hp
	
	# Executing stride should trigger Reactive Strike because ON_LEAVE_SQUARE
	await stride.execute(enemy)
	
	# Fighter should have 0 reactions left
	assert_eq(fighter.action_economy.reactions_remaining, 0, "Fighter should have spent a reaction.")
	
	print("\nReactions tests passed!")
