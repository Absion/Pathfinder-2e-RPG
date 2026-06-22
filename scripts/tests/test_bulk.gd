extends SceneTree

class_name TestBulk

func get_test_name() -> String:
	return "Bulk System and Encumbrance Tests"

func _init() -> void:
	run_test()
	quit()

func assert_eq(a: Variant, b: Variant, msg: String = "") -> void:
	if a != b: push_error("ASSERT EQ FAILED: %s (Expected %s, Got %s)" % [msg, str(b), str(a)])

func assert_true(a: bool, msg: String = "") -> void:
	if not a: push_error("ASSERT TRUE FAILED: %s" % msg)

func assert_false(a: bool, msg: String = "") -> void:
	if a: push_error("ASSERT FALSE FAILED: %s" % msg)

func run_test() -> void:
	print("\n--- Running Bulk System Tests ---")
	
	# Setup mock actor
	var pc = PFPlayerCharacter.new("Test Actor", [&"humanoid"], 1, 10, 0, 0, 0)
	# Max bulk before encumbered is 5 + STR mod.
	# Let's say STR mod is 0, so limit is 5.
	var limit = pc.inventory.get_encumbered_limit()
	assert_eq(limit, 5, "Base encumbered limit should be 5")
	
	# Create some items with bulk
	var item1 = PFItem.new()
	item1.entity_name = "Heavy Rock"
	item1.bulk_value = 4
	
	var item2 = PFItem.new()
	item2.entity_name = "Another Rock"
	item2.bulk_value = 2
	
	# Add item1
	pc.inventory.add_item(item1)
	assert_eq(pc.inventory.get_total_bulk(), 4, "Total bulk should be 4")
	assert_false(pc.has_condition("encumbered"), "Actor should not be encumbered yet")
	
	# Add item2, pushing bulk to 6 (Limit is 5)
	pc.inventory.add_item(item2)
	assert_eq(pc.inventory.get_total_bulk(), 6, "Total bulk should be 6")
	assert_true(pc.has_condition("encumbered"), "Actor should be encumbered")
	
	# Verify encumbered penalties
	assert_true(pc.has_condition("clumsy"), "Encumbered should apply clumsy")
	var speed = pc.get_speed_land()
	# Base speed is 25. Encumbered applies -10.
	assert_eq(speed, 15, "Speed should be reduced by 10")
	
	# Drop item2
	pc.inventory.items.erase(item2)
	pc.inventory._emit_inventory_update() # Simulate the drop update
	
	assert_eq(pc.inventory.get_total_bulk(), 4, "Total bulk should be 4 again")
	assert_false(pc.has_condition("encumbered"), "Actor should no longer be encumbered")
	assert_false(pc.has_condition("clumsy"), "Clumsy should be removed when encumbered is removed")
	assert_eq(pc.get_speed_land(), 25, "Speed should return to normal")
	
	print("Bulk System tests passed!")
