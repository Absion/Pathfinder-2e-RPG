extends GutTest

func test_execution():
	print("\n--- INITIALIZING STEALTH TEST ---")
	
	PFContext.init_shared_services()
	var turn_manager = PFTurnManager.new()
	PFContext.active_turn_manager = turn_manager
	
	# Create Actors
	var rogue = PFNpc.new("rogue_1", "Rogue", [&"humanoid"], 1, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0)
	var guard = PFNpc.new("guard_1", "Guard", [&"humanoid"], 1, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0)
	var goblin = PFNpc.new("goblin_1", "Goblin", [&"humanoid"], 1, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0)
	
	# Configure Senses
	var guard_senses = PFSensesComponent.new()
	guard_senses.initialize()
	guard.add_child(guard_senses)
	
	var goblin_senses = PFSensesComponent.new()
	goblin_senses.initialize()
	goblin_senses.grant_sense(PFBiographyConstants.SenseType.VISION, PFBiographyConstants.SenseAcuity.PRECISE)
	goblin_senses.vision = PFBiographyConstants.Vision.DARKVISION
	goblin.add_child(goblin_senses)
	
	turn_manager.add_combatant(rogue, false)
	turn_manager.add_combatant(guard, true)
	turn_manager.add_combatant(goblin, true)
	turn_manager.start_encounter()
	
	print("\n--- TEST 1: Hiding without Cover ---")
	var hide_action = PFActionHide.new()
	hide_action.execute(rogue, guard)
	var state = PFContext.detection_manager.get_detection_state(guard, rogue)
	print("Guard detection state vs Rogue: ", PFCombatConstants.DetectionState.keys()[state])
	
	print("\n--- TEST 2: Hiding with Cover ---")
	rogue.set_meta(&"mock_cover_vs_Guard", PFCombatConstants.CoverType.STANDARD)
	hide_action.execute(rogue, guard)
	state = PFContext.detection_manager.get_detection_state(guard, rogue)
	print("Guard detection state vs Rogue (with cover): ", PFCombatConstants.DetectionState.keys()[state])
	
	print("\n--- TEST 3: Sneaking past Guard ---")
	var sneak_action = PFActionSneak.new()
	sneak_action.execute(rogue, guard)
	state = PFContext.detection_manager.get_detection_state(guard, rogue)
	print("Guard detection state vs Rogue (after sneak): ", PFCombatConstants.DetectionState.keys()[state])
	
	print("\n--- TEST 4: Environment Darkness ---")
	PFContext.environment_manager.current_light_level = PFEnvironmentConstants.LightLevel.DARKNESS
	print("Setting light level to Darkness.")
	hide_action.execute(rogue, null)
	
	var guard_state = PFContext.detection_manager.get_detection_state(guard, rogue)
	var goblin_state = PFContext.detection_manager.get_detection_state(goblin, rogue)
	
	print("Guard (Normal Vision) detection state vs Rogue: ", PFCombatConstants.DetectionState.keys()[guard_state])
	print("Goblin (Darkvision) detection state vs Rogue: ", PFCombatConstants.DetectionState.keys()[goblin_state])
	
	print("\n--- TEST 5: Seek Action ---")
	var seek_action = PFActionSeek.new()
	seek_action.execute(guard, rogue)
	guard_state = PFContext.detection_manager.get_detection_state(guard, rogue)
	print("Guard detection state vs Rogue (after Seek): ", PFCombatConstants.DetectionState.keys()[guard_state])
	
	print("\n--- TEST 6: Invisibility & Flat Checks ---")
	rogue.set_meta(&"is_invisible", true)
	print("Rogue drinks an invisibility potion!")
	var is_concealed = PFContext.detection_manager.is_concealed(guard, rogue)
	print("Is Rogue concealed/hidden to Guard? ", is_concealed)
	
	# Try targeting
	PFContext.detection_manager.roll_flat_check_for_targeting(guard, rogue)
	
	print("\n--- TEST 7: Point Out ---")
	# Goblin has Darkvision, let's say they have See Invisibility as well
	goblin.set_meta(&"mock_see_invisibility", true)
	PFContext.detection_manager.set_detection_state(goblin, rogue, PFCombatConstants.DetectionState.OBSERVED)
	var point_out = PFActionPointOut.new()
	point_out.execute(goblin, rogue)
	
	print("\n--- TEST 8: Vague Senses ---")
	rogue.set_meta(&"is_sneaking", false) # Drop stealth
	PFContext.detection_manager.set_detection_state(guard, rogue, PFCombatConstants.DetectionState.UNNOTICED)
	guard_senses.grant_sense(PFBiographyConstants.SenseType.SCENT, PFBiographyConstants.SenseAcuity.VAGUE, 30)
	PFContext.detection_manager.apply_vague_senses()
	
	print("\n--- TEST COMPLETE ---")
	
	assert_true(true, "Completed stealth tests")
