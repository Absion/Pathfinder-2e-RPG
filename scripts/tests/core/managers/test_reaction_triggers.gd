extends GutTest

var turn_manager: PFTurnManager
var reaction_manager: PFReactionManager
var actor_a: PFActor
var actor_b: PFActor
var database: PFDatabase

func before_all() -> void:
	if not Engine.get_main_loop().root.has_node("PFDatabase"):
		database = PFDatabase.new()
		database.name = "PFDatabase"
		Engine.get_main_loop().root.add_child(database)
		database._ready()
	else:
		database = PFDatabase.get_instance()

func before_each():
	PFContext.init_shared_services()
	turn_manager = autofree(PFTurnManager.new())
	add_child_autofree(turn_manager)
	
	reaction_manager = autofree(PFReactionManager.new())
	add_child_autofree(reaction_manager)
	PFContext.reaction_manager = reaction_manager
	
	actor_a = autofree(PFPlayerCharacter.new("Alice", [], 1, 20, 0, 0, 0))
	actor_b = autofree(PFPlayerCharacter.new("Bob", [], 1, 20, 0, 0, 0))
	actor_a.set_meta(&"is_ai", true) # auto resolve reactions
	actor_b.set_meta(&"is_ai", true) # auto resolve reactions
	
	add_child_autofree(actor_a)
	add_child_autofree(actor_b)
	
	turn_manager.add_combatant(actor_a)
	turn_manager.add_combatant(actor_b)

func after_each():
	PFContext.cleanup_shared_services()
	PFContext.reaction_manager = null

func test_action_trigger_disruption():
	# Alice attempts to cast a spell with manipulate trait
	var item = PFItem.new()
	var interact = PFActionInteract.new(PFActionInteract.InteractType.DRAW, item, true)
	# Bob has a reactive strike that automatically disrupts manipulate actions on success
	var condition_lambda = func(_trigger_actor: PFActor, _event_data: Dictionary) -> bool:
		return _trigger_actor == actor_a
		
	var execute_lambda = func(_trigger_actor: PFActor, event_data: Dictionary) -> Dictionary:
		event_data["disrupted"] = true
		return event_data
		
	PFContext.reaction_manager.register_listener(PFCombatConstants.ReactionTriggers.ON_MANIPULATE, actor_b, &"Reactive Strike", condition_lambda, execute_lambda)
	
	# Execute should return false because it was disrupted
	var success = await interact.execute(actor_a)
	assert_false(success)
	
func test_move_trait_trigger():
	# Alice attempts to stand up
	var cond = PFCondition.create(&"prone")
	actor_a.apply_condition(cond)
	
	var stand = PFActionToggleCondition.new(&"stand")
	
	var reacted = [false]
	
	var condition_lambda = func(_trigger_actor: PFActor, _event_data: Dictionary) -> bool:
		return _trigger_actor == actor_a
		
	var execute_lambda = func(_trigger_actor: PFActor, event_data: Dictionary) -> Dictionary:
		reacted[0] = true
		return event_data
		
	# Reactive strike triggers on move trait
	PFContext.reaction_manager.register_listener(PFCombatConstants.ReactionTriggers.ON_MOVE, actor_b, &"Reactive Strike", condition_lambda, execute_lambda)
	
	var success = await stand.execute(actor_a)
	
	# She should have successfully stood up, but Bob also reacted
	assert_true(success)
	assert_true(reacted[0])


