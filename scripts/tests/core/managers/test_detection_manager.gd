extends GutTest

var manager: PFDetectionManager
var rogue: PFActor
var guard_1: PFActor
var guard_2: PFActor

func before_all():
	# Mock database response to prevent initialization errors
	var database = PFDatabase.get_instance()
	if database == null:
		database = PFDatabase.new()
		add_child_autofree(database)

func after_all():
	pass
func before_each():
	PFContext.init_shared_services()
	manager = autofree(PFDetectionManager.new())
	add_child_autofree(manager)
	
	rogue = autofree(PFActor.new("Rogue", [], 1, 15))
	guard_1 = autofree(PFActor.new("Guard 1", [], 1, 20))
	guard_2 = autofree(PFActor.new("Guard 2", [], 1, 20))
	
	add_child_autofree(rogue)
	add_child_autofree(guard_1)
	add_child_autofree(guard_2)

func after_each():
	PFContext.cleanup_shared_services()

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

