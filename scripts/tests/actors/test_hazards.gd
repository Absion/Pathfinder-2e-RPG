extends GutTest

class_name TestHazards

func get_test_name() -> String:
	return "Hazards & Traps Subsystem Tests"

func test_hazards() -> void:
	print("\n--- Running Hazards Tests ---")
	
	PFContext.init_shared_services()
	
	# Create a Rogue PC
	var rogue = PFPlayerCharacter.new("Rogue", [&"humanoid"], 3, 30, 5, 5, 5)
	rogue.attributes.apply_free_boost(&"dex")
	rogue.attributes.apply_free_boost(&"dex")
	rogue.attributes.apply_free_boost(&"dex")
	rogue.attributes.apply_free_boost(&"dex")
	rogue.sheet.set_skill_rank(&"thievery", PFMathConstants.ProficiencyRank.EXPERT)
	rogue.sheet.set_skill_rank(&"perception", PFMathConstants.ProficiencyRank.EXPERT)
	
	# Create a Fighter PC (Low skills)
	var fighter = PFPlayerCharacter.new("Fighter", [&"humanoid"], 3, 40, 5, 5, 5)
	fighter.sheet.set_skill_rank(&"thievery", PFMathConstants.ProficiencyRank.UNTRAINED)
	fighter.sheet.set_skill_rank(&"perception", PFMathConstants.ProficiencyRank.TRAINED)
	
	# Create a Hazard: Scythe Blades
	var trap = PFHazard.new("Scythe Blades", [&"mechanical", &"trap"], 4, 20, 10)
	trap.stealth_dc = 22
	trap.stealth_min_proficiency = PFMathConstants.ProficiencyRank.EXPERT
	trap.disable_methods = [
		{"skill": &"thievery", "dc": 22, "successes_needed": 2, "successes_achieved": 0}
	]
	
	# We must add them to the "actors" group for Seek to find them automatically if target=null
	rogue.add_to_group("actors")
	fighter.add_to_group("actors")
	trap.add_to_group("actors")
	
	# Setup initial stealth state (Unnoticed)
	PFContext.detection_manager.set_detection_state(fighter, trap, PFCombatConstants.DetectionState.UNNOTICED)
	PFContext.detection_manager.set_detection_state(rogue, trap, PFCombatConstants.DetectionState.UNNOTICED)
	
	# TEST 1: Seek with insufficient proficiency
	print("\nTest 1: Fighter Seeks Trap (Insufficient Proficiency)")
	var seek_action = PFActionSeek.new()
	# Inject a Natural 20 for the fighter to prove proficiency blocks it
	var _old_perc = fighter.get_skill_bonus(&"perception")
	# Force success if DC was all that mattered: roll=20+bonus > 22
	# Actually PFActionSeek uses PFDice.roll inside, so we'll just execute it.
	# We expect them to fail because they are only TRAINED, and trap needs EXPERT.
	seek_action.execute(fighter, trap)
	
	var state = PFContext.detection_manager.get_detection_state(fighter, trap)
	assert_true(state >= PFCombatConstants.DetectionState.HIDDEN, "Fighter should NOT have observed the trap.")
	
	# TEST 2: Hardness reducing damage
	print("\nTest 2: Hardness Damage Reduction")
	# Trap has 20 HP, 10 Hardness
	trap.health.apply_damage(15, PFCombatConstants.DamageType.SLASHING)
	assert_true(trap.health.current_hp == 15, "Trap should have taken 5 damage (15 damage - 10 hardness).")
	
	trap.health.apply_damage(5, PFCombatConstants.DamageType.PIERCING)
	assert_true(trap.health.current_hp == 15, "Trap should have taken 0 damage (5 damage <= 10 hardness).")
	
	# TEST 3: Disable Device (Success Accumulation & Trigger on Crit Fail)
	print("\nTest 3: Disable Device (Accumulation & Trigger)")
	var disable_action = PFActionDisableDevice.new()
	disable_action.selected_skill = &"thievery"
	
	# Force a SUCCESS (+1)
	trap.attempt_disable(&"thievery", PFCombatConstants.DegreeOfSuccess.SUCCESS)
	assert_false(trap.is_disabled, "Trap should not be disabled yet (needs 2 successes).")
	assert_true(trap.disable_methods[0]["successes_achieved"] == 1, "Trap should have 1 success achieved.")
	
	# Force a CRIT FAILURE (Triggers trap)
	trap.attempt_disable(&"thievery", PFCombatConstants.DegreeOfSuccess.CRITICAL_FAILURE)
	assert_true(trap.is_triggered, "Trap should be triggered due to critical failure!")
	assert_false(trap.is_disabled, "Trap should not be disabled.")
	
	# Force a CRIT SUCCESS (+2)
	trap.attempt_disable(&"thievery", PFCombatConstants.DegreeOfSuccess.CRITICAL_SUCCESS)
	assert_true(trap.is_disabled, "Trap should now be disabled!")
	
	print("\nAll Hazard Tests Executed Successfully!")
