extends GutTest

var db: PFDatabase

func before_all() -> void:
	PFContext.init_shared_services()
	db = PFDatabase.get_instance()
	
	db._conditions_cache[&"scout_bonus"] = {
		"name": "Scout Bonus", "modifier_type": "circumstance", "target_stat": "initiative", "multiplier": 2, "script_path": ""
	}
	db._conditions_cache[&"initiative_first"] = {
		"name": "Initiative First", "modifier_type": "", "target_stat": "", "multiplier": 0, "script_path": ""
	}
func test_initiative_sorting():
	var tm = PFTurnManager.new()
	var a1 = PFActor.new("Hero", [&"humanoid"], 1, 10)
	var a2 = PFActor.new("Goblin", [&"humanoid"], 1, 10)
	var a3 = PFActor.new("Boss", [&"humanoid"], 1, 10)
	
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
	assert_true(tm.combatants[0].actor.entity_name == "Goblin" or tm.combatants[0].actor.entity_name == "Boss")
	assert_eq(tm.combatants[2].actor.entity_name, "Hero")
	
func test_turn_loop():
	var tm = PFTurnManager.new()
	var a1 = PFActor.new("Hero", [&"humanoid"], 1, 10)
	var a2 = PFActor.new("Goblin", [&"humanoid"], 1, 10)
	
	tm.add_combatant(a1, false)
	tm.add_combatant(a2, true)
	
	# Rig rolls
	tm.combatants[0].initiative_roll = 20
	tm.combatants[1].initiative_roll = 10
	tm.combatants.sort_custom(tm._compare_initiative)
	
	tm.start_encounter()
	assert_eq(tm.round_number, 1)
	assert_eq(tm.get_current_actor().entity_name, "Hero")
	
	tm.next_turn()
	assert_eq(tm.get_current_actor().entity_name, "Goblin")
	
	tm.next_turn()
	assert_eq(tm.round_number, 2)
	assert_eq(tm.get_current_actor().entity_name, "Hero")

func test_initiative_modifiers():
	var tm = PFTurnManager.new()

	
	var a1 = PFActor.new("Hero", [&"humanoid"], 1, 10)
	var a2 = PFActor.new("Goblin", [&"humanoid"], 1, 10)
	var a3 = PFActor.new("Scout", [&"humanoid"], 1, 10)
	
	# Give the Scout an initiative modifier
	var scout_cond = PFCondition.create("scout_bonus", 1)
	scout_cond.modifier_type = "circumstance"
	scout_cond.target_stat = "initiative"
	scout_cond.multiplier = 2 # +2 circumstance bonus to initiative
	a3.apply_condition(scout_cond)
	
	# Give Hero force first
	a1.apply_condition(PFCondition.create("initiative_first", 1))
	
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
	assert_eq(scout_rec.initiative_modifier, 2)
	
	hero_rec.initiative_roll = 5
	goblin_rec.initiative_roll = 25
	scout_rec.initiative_roll = 10
	
	# Re-sort with our rigged rolls
	tm.combatants.sort_custom(tm._compare_initiative)
	
	# Hero has initiative_first so Hero goes first despite rolling 5.
	assert_eq(tm.combatants[0].actor.entity_name, "Hero")
	# Goblin rolled 25 vs Scout's 10, so Goblin is second
	assert_eq(tm.combatants[1].actor.entity_name, "Goblin")
