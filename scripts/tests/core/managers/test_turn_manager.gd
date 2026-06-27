extends GutTest

var database: PFDatabase

func before_all() -> void:
	PFContext.init_shared_services()
	database = PFDatabase.get_instance()
	
	database._conditions_cache[&"scout_bonus"] = {
		"name": "Scout Bonus", "modifier_type": "circumstance", "target_stat": "initiative", "multiplier": 2, "script_path": ""
	}
	database._conditions_cache[&"initiative_first"] = {
		"name": "Initiative First", "modifier_type": "", "target_stat": "", "multiplier": 0, "script_path": ""
	}
func test_initiative_sorting():
	var time_manager = autofree(PFTurnManager.new())
	var a1 = autofree(PFActor.new("Hero", [&"humanoid"], 1, 10))
	var a2 = autofree(PFActor.new("Goblin", [&"humanoid"], 1, 10))
	var a3 = autofree(PFActor.new("Boss", [&"humanoid"], 1, 10))
	
	time_manager.add_combatant(a1, false, &"perception")
	time_manager.add_combatant(a2, true, &"perception")
	time_manager.add_combatant(a3, true, &"stealth")
	
	# Manually rig the rolls for testing sorting
	time_manager.combatants[0].initiative_roll = 15
	time_manager.combatants[0].initiative_modifier = 2 # Hero
	
	time_manager.combatants[1].initiative_roll = 15
	time_manager.combatants[1].initiative_modifier = 4 # Goblin
	
	time_manager.combatants[2].initiative_roll = 15
	time_manager.combatants[2].initiative_modifier = 4 # Boss (tied with goblin, should sort randomly or enemies win ties, but both are enemies)
	
	time_manager.combatants.sort_custom(time_manager._compare_initiative)
	
	# Goblin/Boss should beat Hero due to higher modifier (4 vs 2)
	assert_true(time_manager.combatants[0].actor.entity_name == "Goblin" or time_manager.combatants[0].actor.entity_name == "Boss")
	assert_eq(time_manager.combatants[2].actor.entity_name, "Hero")
	
func test_turn_loop():
	var time_manager = autofree(PFTurnManager.new())
	var a1 = autofree(PFActor.new("Hero", [&"humanoid"], 1, 10))
	var a2 = autofree(PFActor.new("Goblin", [&"humanoid"], 1, 10))
	
	time_manager.add_combatant(a1, false)
	time_manager.add_combatant(a2, true)
	
	# Rig rolls
	time_manager.combatants[0].initiative_roll = 20
	time_manager.combatants[1].initiative_roll = 10
	time_manager.combatants.sort_custom(time_manager._compare_initiative)
	
	time_manager.start_encounter()
	assert_eq(time_manager.round_number, 1)
	assert_eq(time_manager.get_current_actor().entity_name, "Hero")
	
	time_manager.next_turn()
	assert_eq(time_manager.get_current_actor().entity_name, "Goblin")
	
	time_manager.next_turn()
	assert_eq(time_manager.round_number, 2)
	assert_eq(time_manager.get_current_actor().entity_name, "Hero")

func test_initiative_modifiers():
	var time_manager = autofree(PFTurnManager.new())

	
	var a1 = autofree(PFActor.new("Hero", [&"humanoid"], 1, 10))
	var a2 = autofree(PFActor.new("Goblin", [&"humanoid"], 1, 10))
	var a3 = autofree(PFActor.new("Scout", [&"humanoid"], 1, 10))
	
	# Give the Scout an initiative modifier
	var scout_cond = PFCondition.create("scout_bonus", 1)
	scout_cond.modifier_type = "circumstance"
	scout_cond.target_stat = "initiative"
	scout_cond.multiplier = 2 # +2 circumstance bonus to initiative
	a3.apply_condition(scout_cond)
	
	# Give Hero force first
	a1.apply_condition(PFCondition.create("initiative_first", 1))
	
	time_manager.add_combatant(a1, false)
	time_manager.add_combatant(a2, true)
	time_manager.add_combatant(a3, false)
	
	# Run roll_initiative which populates modifiers and randomly rolls, then sorts.
	time_manager.roll_initiative()
	
	# Now rig the rolls for sorting test by finding the correct records:
	var hero_rec = null
	var goblin_rec = null
	var scout_rec = null
	
	for c in time_manager.combatants:
		if c.actor.entity_name == "Hero": hero_rec = c
		elif c.actor.entity_name == "Goblin": goblin_rec = c
		elif c.actor.entity_name == "Scout": scout_rec = c
		
	# Modifiers were calculated by roll_initiative, so scout should have +2
	assert_eq(scout_rec.initiative_modifier, 2)
	
	hero_rec.initiative_roll = 5
	goblin_rec.initiative_roll = 25
	scout_rec.initiative_roll = 10
	
	# Re-sort with our rigged rolls
	time_manager.combatants.sort_custom(time_manager._compare_initiative)
	
	# Hero has initiative_first so Hero goes first despite rolling 5.
	assert_eq(time_manager.combatants[0].actor.entity_name, "Hero")
	# Goblin rolled 25 vs Scout's 10, so Goblin is second
	assert_eq(time_manager.combatants[1].actor.entity_name, "Goblin")

func after_all():
	PFContext.cleanup_shared_services()

