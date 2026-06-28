extends GutTest

func get_test_name() -> String:
	return "Investiture Tests"

func test_investiture_limit() -> void:
	var pc = autofree(PFPlayerCharacter.new("Wizard", [&"humanoid"], 1, 10, 0, 0, 0))
	add_child_autofree(pc)
	
	# Try to invest 11 items
	for i in range(12):
		var item = PFItem.new()
		item.requires_investment = true
		item.entity_name = "Magic Ring " + str(i)
		pc.inventory.add_item(item)
		pc.inventory.invest_item(item)
	
	assert_eq(pc.inventory.invested_items.size(), 10, "Should cap at 10 invested items")
	
	# Test uninvesting
	var first_ring = pc.inventory.invested_items[0]
	pc.inventory.uninvest_item(first_ring)
	assert_eq(pc.inventory.invested_items.size(), 9, "Should drop to 9 invested items")
	
	# Test investing 11th item now that there is space
	var item11 = pc.inventory.items[10]
	pc.inventory.invest_item(item11)
	assert_eq(pc.inventory.invested_items.size(), 10, "Should go back to 10 invested items")
