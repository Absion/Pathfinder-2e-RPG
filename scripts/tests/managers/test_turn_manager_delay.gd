extends GutTest

var turn_manager: PFTurnManager
var actor_a: PFActor
var actor_b: PFActor
var actor_c: PFActor

func before_each():
	turn_manager = PFTurnManager.new()
	add_child(turn_manager)
	
	actor_a = PFActor.new("Alice", [], 1, 20)
	actor_b = PFActor.new("Bob", [], 1, 20)
	actor_c = PFActor.new("Charlie", [], 1, 20)
	
	add_child(actor_a)
	add_child(actor_b)
	add_child(actor_c)
	
	turn_manager.add_combatant(actor_a)
	turn_manager.add_combatant(actor_b)
	turn_manager.add_combatant(actor_c)
	
	# Force initiatives for testing predictability
	turn_manager.combatants[0].initiative_roll = 20 # Alice
	turn_manager.combatants[1].initiative_roll = 15 # Bob
	turn_manager.combatants[2].initiative_roll = 10 # Charlie

func after_each():
	turn_manager.queue_free()
	actor_a.queue_free()
	actor_b.queue_free()
	actor_c.queue_free()

func test_delay_turn():
	turn_manager.start_encounter()
	
	assert_eq(turn_manager.get_current_actor(), actor_a)
	
	# Alice delays
	var delayed = turn_manager.delay_current_turn()
	assert_true(delayed)
	
	# Bob should be active now
	assert_eq(turn_manager.get_current_actor(), actor_b)
	
	# Alice should be in delayed combatants
	assert_eq(turn_manager.delayed_combatants.size(), 1)
	assert_eq(turn_manager.delayed_combatants[0].actor, actor_a)
	
	# Bob ends his turn
	turn_manager.next_turn()
	
	# Alice resumes turn, right after Bob
	var resumed = turn_manager.resume_delayed_turn(actor_a)
	assert_true(resumed)
	
	# Alice is now the active turn
	assert_eq(turn_manager.get_current_actor(), actor_a)
	
	# Delayed array should be empty
	assert_eq(turn_manager.delayed_combatants.size(), 0)
	
	# Charlie should be next if Alice ends turn
	turn_manager.next_turn()
	assert_eq(turn_manager.get_current_actor(), actor_c)
