extends GdUnitTestSuite

const TurnManager = preload("res://scripts/core/managers/pf_turn_manager.gd")

func test_initiative_sorting():
	var tm = auto_free(TurnManager.new())
	var a1 = auto_free(PFActor.new("Hero", [&"humanoid"], 1, 10))
	var a2 = auto_free(PFActor.new("Goblin", [&"humanoid"], 1, 10))
	var a3 = auto_free(PFActor.new("Boss", [&"humanoid"], 1, 10))
	
	tm.add_combatant(a1, false, &"perception")
	tm.add_combatant(a2, true, &"perception")
	tm.add_combatant(a3, true, &"stealth")
	
	# Manually rig the rolls for testing sorting
	tm.combatants[0].initiative_roll = 15
	tm.combatants[0].initiative_modifier = 2 # Hero
	
	tm.combatants[1].initiative_roll = 15
	tm.combatants[1].initiative_modifier = 4 # Goblin
	
	tm.combatants[2].initiative_roll = 15
	tm.combatants[2].initiative_modifier = 4 # Boss (tied with goblin, should sort randomly or enemies win ties, but both are enemies)
	
	tm.combatants.sort_custom(tm._compare_initiative)
	
	# Goblin/Boss should beat Hero due to higher modifier (4 vs 2)
	assert_bool(tm.combatants[0].actor.entity_name == "Goblin" or tm.combatants[0].actor.entity_name == "Boss").is_true()
	assert_str(tm.combatants[2].actor.entity_name).is_equal("Hero")
	
func test_turn_loop():
	var tm = auto_free(TurnManager.new())
	var a1 = auto_free(PFActor.new("Hero", [&"humanoid"], 1, 10))
	var a2 = auto_free(PFActor.new("Goblin", [&"humanoid"], 1, 10))
	
	tm.add_combatant(a1, false)
	tm.add_combatant(a2, true)
	
	# Rig rolls
	tm.combatants[0].initiative_roll = 20
	tm.combatants[1].initiative_roll = 10
	tm.combatants.sort_custom(tm._compare_initiative)
	
	tm.start_encounter()
	assert_int(tm.round_number).is_equal(1)
	assert_str(tm.get_current_actor().entity_name).is_equal("Hero")
	
	tm.next_turn()
	assert_str(tm.get_current_actor().entity_name).is_equal("Goblin")
	
	tm.next_turn()
	assert_int(tm.round_number).is_equal(2)
	assert_str(tm.get_current_actor().entity_name).is_equal("Hero")

func test_initiative_modifiers():
	var tm = auto_free(TurnManager.new())
	var Condition = preload("res://scripts/conditions/pf_condition.gd")
	
	var a1 = auto_free(PFActor.new("Hero", [&"humanoid"], 1, 10))
	var a2 = auto_free(PFActor.new("Goblin", [&"humanoid"], 1, 10))
	var a3 = auto_free(PFActor.new("Scout", [&"humanoid"], 1, 10))
	
	# Give the Scout an initiative modifier
	var scout_cond = Condition.create("scout_bonus", 1)
	scout_cond.modifier_type = "circumstance"
	scout_cond.target_stat = "initiative"
	scout_cond.multiplier = 2 # +2 circumstance bonus to initiative
	a3.apply_condition(scout_cond)
	
	# Give Hero force first
	a1.apply_condition(Condition.create("initiative_first", 1))
	
	tm.add_combatant(a1, false)
	tm.add_combatant(a2, true)
	tm.add_combatant(a3, false)
	
	# Run roll_initiative which populates modifiers and randomly rolls, then sorts.
	tm.roll_initiative()
	
	# Now rig the rolls for sorting test by finding the correct records:
	var hero_rec = null
	var goblin_rec = null
	var scout_rec = null
	
	for c in tm.combatants:
		if c.actor.entity_name == "Hero": hero_rec = c
		elif c.actor.entity_name == "Goblin": goblin_rec = c
		elif c.actor.entity_name == "Scout": scout_rec = c
		
	# Modifiers were calculated by roll_initiative, so scout should have +2
	assert_int(scout_rec.initiative_modifier).is_equal(2)
	
	hero_rec.initiative_roll = 5
	goblin_rec.initiative_roll = 25
	scout_rec.initiative_roll = 10
	
	# Re-sort with our rigged rolls
	tm.combatants.sort_custom(tm._compare_initiative)
	
	# Hero has initiative_first so Hero goes first despite rolling 5.
	assert_str(tm.combatants[0].actor.entity_name).is_equal("Hero")
	# Goblin rolled 25 vs Scout's 10, so Goblin is second
	assert_str(tm.combatants[1].actor.entity_name).is_equal("Goblin")
