extends GutTest

var combat_context: PFCombatContext
var master: PFActor
var minion: PFActor
var ActionCommandMinion = preload("res://scripts/actions/interaction/pf_action_command_minion.gd")

func before_each():
	combat_context = PFCombatContext.new()
	add_child(combat_context)
	combat_context.enter_context()
	
	master = PFActor.new("Master", [&"humanoid"], 1, 20)
	minion = PFMinion.new("Pet Wolf", master, [&"animal"], 1, 10)
	
	master.minions.append(minion)
	
	combat_context.turn_manager.add_combatant(master)
	combat_context.turn_manager.add_combatant(minion)

func after_each():
	combat_context.exit_context()
	combat_context.free()
	master.free()
	minion.free()

func test_minion_initiative_sharing():
	combat_context.turn_manager.roll_initiative()
	
	# Master and Minion should be placed consecutively
	var master_idx = -1
	var minion_idx = -1
	var combatants = combat_context.turn_manager.combatants
	
	for i in range(combatants.size()):
		if combatants[i].actor == master: master_idx = i
		if combatants[i].actor == minion: minion_idx = i
		
	assert_true(master_idx != -1, "Master should be in combatants.")
	assert_true(minion_idx != -1, "Minion should be in combatants.")
	
	# Minion should be placed right after master
	assert_eq(minion_idx, master_idx + 1, "Minion should follow master in initiative order.")

func test_minion_command_flow():
	combat_context.turn_manager.roll_initiative()
	combat_context.turn_manager.start_encounter()
	
	# Verify we are on Master's turn
	var current = combat_context.turn_manager.get_current_actor()
	assert_eq(current, master, "Master should take the first turn.")
	assert_eq(master.action_economy.actions_remaining, 3, "Master should have 3 actions.")
	
	# Verify minion has 0 actions at start
	assert_eq(minion.action_economy.actions_remaining, 0, "Minion should not start with any actions.")
	
	# Master uses Command an Animal
	var cmd = ActionCommandMinion.new()
	await master.use_action(cmd, minion)
	
	assert_eq(master.action_economy.actions_remaining, 2, "Master should have spent 1 action.")
	assert_eq(minion.action_economy.actions_remaining, 2, "Minion should have gained 2 actions.")
	
	# Sub-Turn should be active
	current = combat_context.turn_manager.get_current_actor()
	assert_eq(current, minion, "Minion should now be the active sub-turn actor.")
	
	# Minion ends sub-turn
	combat_context.turn_manager.pop_sub_turn()
	
	current = combat_context.turn_manager.get_current_actor()
	assert_eq(current, master, "Master should resume control after minion sub-turn.")
	
	# Master ends turn
	combat_context.turn_manager.next_turn()
	
	# Now it's the minion's actual turn in the initiative
	current = combat_context.turn_manager.get_current_actor()
	assert_eq(current, minion, "Minion's real turn should happen after master.")
	assert_eq(minion.action_economy.actions_remaining, 0, "Minion should start real turn with 0 actions because it was not commanded.")

func test_minion_independent_flow():
	minion.passive_features.append(&"independent")
	
	combat_context.turn_manager.roll_initiative()
	combat_context.turn_manager.start_encounter()
	
	var current = combat_context.turn_manager.get_current_actor()
	assert_eq(current, master, "Master should take the first turn.")
	
	# Master does NOT command minion. Master ends turn.
	combat_context.turn_manager.next_turn()
	
	current = combat_context.turn_manager.get_current_actor()
	assert_eq(current, minion, "Minion should take its turn.")
	
	assert_eq(minion.action_economy.actions_remaining, 1, "Minion should have 1 action from Independent feature.")
	
	combat_context.turn_manager.next_turn()
	
	# Round 2
	current = combat_context.turn_manager.get_current_actor()
	assert_eq(current, master, "Master should take the first turn in round 2.")
	
	# Master DOES command minion this time.
	var cmd = ActionCommandMinion.new()
	await master.use_action(cmd, minion)
	
	current = combat_context.turn_manager.get_current_actor()
	assert_eq(current, minion, "Minion should take sub-turn.")
	assert_eq(minion.action_economy.actions_remaining, 2, "Minion should have 2 actions from Command.")
	
	combat_context.turn_manager.pop_sub_turn()
	
	current = combat_context.turn_manager.get_current_actor()
	assert_eq(current, master, "Master should resume control.")
	
	combat_context.turn_manager.next_turn()
	
	current = combat_context.turn_manager.get_current_actor()
	assert_eq(current, minion, "Minion's real turn starts.")
	assert_eq(minion.action_economy.actions_remaining, 0, "Minion should have 0 actions because it was already commanded this round.")

