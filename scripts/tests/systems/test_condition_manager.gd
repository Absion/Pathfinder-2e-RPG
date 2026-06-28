extends GutTest

var condition_manager: PFConditionManager
var turn_manager: PFTurnManager
var actor: PFPlayerCharacter

func before_each() -> void:
	PFContext.init_shared_services()
	condition_manager = PFContext.condition_manager
	turn_manager = autofree(PFTurnManager.new())
	turn_manager.name = "PFTurnManager"
	add_child_autofree(turn_manager)
	
	actor = autofree(PFPlayerCharacter.new("Test Actor", [], 1, 20, 0, 0, 0))
	add_child_autofree(actor)

func after_each() -> void:
	PFContext.cleanup_shared_services()

func test_apply_and_remove_condition() -> void:
	var condition = PFCondition.new(&"test_condition", 1)
	actor.apply_condition(condition)
	
	assert_true(actor.has_condition("test_condition"))
	assert_not_null(actor.get_condition("test_condition"))
	
	actor.remove_condition("test_condition")
	assert_false(actor.has_condition("test_condition"))

func test_condition_max_stacking() -> void:
	var c1 = PFCondition.new(&"frightened", 1)
	var c2 = PFCondition.new(&"frightened", 2)
	
	actor.apply_condition(c1)
	assert_eq(actor.get_condition("frightened").value, 1)
	
	actor.apply_condition(c2)
	assert_eq(actor.get_condition("frightened").value, 2, "Should stack to highest value")
	
	var c3 = PFCondition.new(&"frightened", 1)
	actor.apply_condition(c3)
	assert_eq(actor.get_condition("frightened").value, 2, "Should not decrease if a lower value is applied")

func test_condition_duration_expiration() -> void:
	# Create a condition that lasts for 2 turns
	var temp_condition = PFCondition.new(&"stupefied", 1, 0, 2)
	actor.apply_condition(temp_condition)
	
	assert_true(actor.has_condition("stupefied"))
	assert_eq(actor.get_condition("stupefied").duration_turns, 2)
	
	# Turn 1 Starts -> Duration drops to 1
	condition_manager.tick_turn_started(actor)
	assert_true(actor.has_condition("stupefied"))
	assert_eq(actor.get_condition("stupefied").duration_turns, 1)
	
	# Turn 1 Ends
	condition_manager.tick_turn_ended(actor)
	
	# Turn 2 Starts -> Duration drops to 0, condition expires
	condition_manager.tick_turn_started(actor)
	assert_false(actor.has_condition("stupefied"), "Condition should expire after duration reaches 0")

func test_condition_modifier_calculation() -> void:
	# Add a status penalty (-1) and a circumstance penalty (-2)
	var status_penalty = PFCondition.new(&"status_penalty", 1)
	status_penalty.modifier_type = "status"
	status_penalty.target_stat = "ac"
	status_penalty.multiplier = -1
	
	var circ_penalty = PFCondition.new(&"circ_penalty", 2)
	circ_penalty.modifier_type = "circumstance"
	circ_penalty.target_stat = "ac"
	circ_penalty.multiplier = -1
	
	# Add a weaker status penalty (-2, wait -1 is weaker than -2)
	var weak_status_penalty = PFCondition.new(&"weak_status", 2)
	weak_status_penalty.modifier_type = "status"
	weak_status_penalty.target_stat = "ac"
	weak_status_penalty.multiplier = -1
	
	actor.apply_condition(status_penalty)
	actor.apply_condition(circ_penalty)
	actor.apply_condition(weak_status_penalty)
	
	# Expected: -2 (highest status) + -2 (highest circ) = -4
	var modifier = actor.get_condition_modifier(&"ac")
	assert_eq(modifier, -4, "Modifiers of the same type should not stack, only the highest applies")
