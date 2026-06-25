extends GutTest

var manager: PFDetectionManager
var rogue: PFActor
var guard_1: PFActor
var guard_2: PFActor

func before_all():
	# Mock database response to prevent initialization errors
	var db = PFDatabase.get_instance()
	if db == null:
		db = PFDatabase.new()
		add_child(db)

func after_all():
	pass
func before_each():
	manager = PFDetectionManager.new()
	add_child(manager)
	
	rogue = PFActor.new("Rogue", [], 1, 15)
	guard_1 = PFActor.new("Guard 1", [], 1, 20)
	guard_2 = PFActor.new("Guard 2", [], 1, 20)
	
	add_child(rogue)
	add_child(guard_1)
	add_child(guard_2)

func after_each():
	manager.queue_free()
	rogue.queue_free()
	guard_1.queue_free()
	guard_2.queue_free()

func test_default_detection_state():
	# By default, anyone should be observed to anyone else.
	var state = manager.get_detection_state(guard_1, rogue)
	assert_eq(state, PFCombatConstants.DetectionState.OBSERVED)

func test_relational_asymmetry():
	# Guard 1 is blind/unaware, Guard 2 sees the rogue perfectly
	manager.set_detection_state(guard_1, rogue, PFCombatConstants.DetectionState.UNDETECTED)
	manager.set_detection_state(guard_2, rogue, PFCombatConstants.DetectionState.OBSERVED)
	
	assert_eq(manager.get_detection_state(guard_1, rogue), PFCombatConstants.DetectionState.UNDETECTED)
	assert_eq(manager.get_detection_state(guard_2, rogue), PFCombatConstants.DetectionState.OBSERVED)
	
	# Verify that rogue seeing Guard 1 is completely independent
	assert_eq(manager.get_detection_state(rogue, guard_1), PFCombatConstants.DetectionState.OBSERVED)

func test_flat_check_unnoticed():
	# Cannot target unnoticed creatures at all
	manager.set_detection_state(guard_1, rogue, PFCombatConstants.DetectionState.UNNOTICED)
	var allowed = manager.roll_flat_check_for_targeting(guard_1, rogue)
	assert_false(allowed)

func test_remove_actor_cleanup():
	manager.set_detection_state(guard_1, rogue, PFCombatConstants.DetectionState.HIDDEN)
	assert_eq(manager.get_detection_state(guard_1, rogue), PFCombatConstants.DetectionState.HIDDEN)
	
	manager.remove_actor(rogue)
	# Should revert back to OBSERVED as it doesn't exist in the matrix anymore
	assert_eq(manager.get_detection_state(guard_1, rogue), PFCombatConstants.DetectionState.OBSERVED)
