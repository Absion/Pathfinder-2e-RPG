extends GutTest

class_name TestBulk

func get_test_name() -> String:
	return "Bulk System and Encumbrance Tests"

func test_main() -> void:
	print("\n--- Running Bulk System Tests ---")
	
	# Setup mock actor
	var pc = autofree(PFPlayerCharacter.new("Test Actor", [&"humanoid"], 1, 10, 0, 0, 0))
	# Max bulk before encumbered is 5 + STR mod.
	# Let's say STR mod is 0, so limit is 5.
	var limit = pc.inventory.get_encumbered_limit()
	assert_eq(limit, 50, "Base encumbered limit should be 50")
	
	# Create some items with bulk
	var item1 = PFItem.new()
	item1.entity_name = "Heavy Rock"
	item1.bulk_value = 40
	
	var item2 = PFItem.new()
	item2.entity_name = "Another Rock"
	item2.bulk_value = 20
	
	# Add item1
	pc.inventory.add_item(item1)
	assert_eq(pc.inventory.get_total_bulk(), 40, "Total bulk should be 40")
	assert_false(pc.has_condition("encumbered"), "Actor should not be encumbered yet")
	
	# Add item2, pushing bulk to 60 (Limit is 50)
	pc.inventory.add_item(item2)
	assert_eq(pc.inventory.get_total_bulk(), 60, "Total bulk should be 60")
	assert_true(pc.has_condition("encumbered"), "Actor should be encumbered")
	
	# Verify encumbered penalties
	assert_true(pc.has_condition("clumsy"), "Encumbered should apply clumsy")
	var speed = pc.get_speed_land()
	# Base speed is 25. Encumbered applies -10.
	assert_eq(speed, 15, "Speed should be reduced by 10")
	
	# Drop item2
	pc.inventory.items.erase(item2)
	pc.inventory._emit_inventory_update() # Simulate the drop update
	
	assert_eq(pc.inventory.get_total_bulk(), 40, "Total bulk should be 40 again")
	assert_false(pc.has_condition("encumbered"), "Actor should no longer be encumbered")
	assert_false(pc.has_condition("clumsy"), "Clumsy should be removed when encumbered is removed")
	assert_eq(pc.get_speed_land(), 25, "Speed should return to normal")
	
	print("Bulk System tests passed!")

func test_creature_size_bulk() -> void:
	print("\n--- Running Creature Size Bulk Tests ---")
	var db = PFDatabase.get_instance()
	if db == null:
		db = PFDatabase.new()
		add_child_autofree(db)
		db._ready()
		
	var pc_medium = autofree(PFPlayerCharacter.new("Medium Actor", [&"humanoid"], 1, 10, 0, 0, 0))
	pc_medium.size_id = &"medium"
	
	var pc_large = autofree(PFPlayerCharacter.new("Large Actor", [&"humanoid"], 1, 10, 0, 0, 0))
	pc_large.size_id = &"large"
	
	var pc_tiny = autofree(PFPlayerCharacter.new("Tiny Actor", [&"humanoid"], 1, 10, 0, 0, 0))
	pc_tiny.size_id = &"tiny"
	
	var item_medium = PFItem.new()
	item_medium.entity_name = "Medium Rock"
	item_medium.bulk_value = 10 # 1 Bulk
	item_medium.size_id = &"medium"
	
	var item_large = PFItem.new()
	item_large.entity_name = "Large Rock"
	item_large.bulk_value = 10 # 1 Bulk base for Large size
	item_large.size_id = &"large"
	
	# Medium creature carrying medium item: 1 Bulk
	assert_eq(pc_medium.inventory.get_perceived_bulk(item_medium), 10, "Medium creature carrying medium item (10)")
	
	# Medium creature carrying large item: Double bulk (2 Bulk = 20)
	assert_eq(pc_medium.inventory.get_perceived_bulk(item_large), 20, "Medium creature carrying large item (20)")
	
	# Large creature carrying medium item: 1/10 bulk (Light Bulk = 1)
	assert_eq(pc_large.inventory.get_perceived_bulk(item_medium), 1, "Large creature carrying medium item (1)")
	
	# Large creature carrying large item: 1 Bulk
	assert_eq(pc_large.inventory.get_perceived_bulk(item_large), 10, "Large creature carrying large item (10)")
	
	# Tiny creature carrying medium item: Double bulk
	assert_eq(pc_tiny.inventory.get_perceived_bulk(item_medium), 20, "Tiny creature carrying medium item (20)")
