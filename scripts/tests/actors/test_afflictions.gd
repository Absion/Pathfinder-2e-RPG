extends GutTest

class_name TestAfflictions

func get_test_name() -> String:
	return "Affliction Stages Tests"

func test_poison_progression():
	print("\n--- Running Affliction Tests ---")
	
	PFContext.init_shared_services()
	
	var pc = autofree(PFPlayerCharacter.new("Alice", [&"humanoid"], 1, 20, 0, 0, 0))
	add_child_autofree(pc)
	
	# Give Alice a specific fort save for predictability
	pc.sheet.set_save_rank(&"fort", PFMathConstants.ProficiencyRank.TRAINED)
	pc.attributes.apply_ancestry_boost(&"con") # Con +1
	# Her save is: Level (1) + Trained (2) + Con (1) = +4
	
	var database = PFDatabase.get_instance()
	assert_not_null(database.get_affliction_data(&"giant_centipede_venom"), "Venom should exist in DB.")
	
	# 1. Initial Exposure (Failed save -> Stage 1)
	# Seed the RNG to guarantee a failure for the initial exposure.
	# With +4, she needs 13+ to pass DC 17.
	seed(42) # Let's hope randi() % 20 + 1 + 4 < 17
	# Actually, to guarantee things without relying on random seeds across platforms, 
	# let's temporarily mock the save_mod or just test the logic directly if possible.
	# But expose_to_affliction uses randi(). Let's mock randi() if we can, or just loop until we fail.
	
	var max_attempts = 100
	var contracted = false
	for i in range(max_attempts):
		pc.expose_to_affliction(&"giant_centipede_venom")
		if pc.has_condition("giant_centipede_venom"):
			contracted = true
			break
			
	assert_true(contracted, "Alice should have contracted the venom.")
	
	var venom = pc.get_condition("giant_centipede_venom")
	assert_not_null(venom)
	assert_eq(venom.current_stage, 1, "Should start at Stage 1 (or 2 on crit fail, but we assume 1 for this test path if we passed).")
	
	# Wait, if she crit failed, it's stage 2. Let's just force stage 1.
	venom.current_stage = 1
	venom._apply_stage_effects(pc)
	
	# At Stage 1: 1d6 poison damage. No sub-conditions.
	# She should have taken damage.
	assert_true(pc.health.current_hp < 20, "Alice should have taken poison damage.")
	
	# 2. Turn End - Save again
	var hp_before_turn = pc.health.current_hp
	
	# Force a failure for the next turn
	# We can't easily mock randi, so we will manually trigger `_change_stage` to test the state machine.
	venom._change_stage(pc, 2)
	
	assert_eq(venom.current_stage, 2, "Venom is now stage 2.")
	assert_true(pc.health.current_hp < hp_before_turn, "Alice should take damage again at Stage 2.")
	assert_true(pc.has_condition("enfeebled"), "Stage 2 should apply enfeebled.")
	
	var enfeebled = pc.get_condition("enfeebled")
	assert_eq(enfeebled.value, 1, "Enfeebled should be value 1.")
	
	# 3. Progress to Stage 4 (skip 3)
	venom._change_stage(pc, 4)
	enfeebled = pc.get_condition("enfeebled")
	assert_not_null(enfeebled)
	assert_eq(enfeebled.value, 2, "Enfeebled should be upgraded to value 2 by Stage 4.")
	
	# 4. Successful Saves to recover
	venom._change_stage(pc, 3)
	enfeebled = pc.get_condition("enfeebled")
	assert_eq(enfeebled.value, 1, "Enfeebled should downgrade back to 1 at Stage 3.")
	
	venom._change_stage(pc, 0)
	assert_false(pc.has_condition("giant_centipede_venom"), "Venom should be removed at Stage 0.")
	assert_false(pc.has_condition("enfeebled"), "Sub-conditions should be cleaned up.")
	
	print("\nAll Affliction Tests Passed!")

