extends GutTest

func get_test_name() -> String:
	return "Currency and Wealth Tests"

func before_each():
	PFContext.init_shared_services()

func after_each():
	PFContext.cleanup_shared_services()

func test_add_and_consolidate_coins() -> void:
	var pc = autofree(PFPlayerCharacter.new("Banker", [&"humanoid"], 1, 10, 0, 0, 0))
	add_child_autofree(pc)
	
	# Add some basic coins (gold, silver, copper, platinum)
	pc.inventory.add_currency(5, 12, 105, 1) # 5 GP, 12 SP, 105 CP, 1 PP
	
	assert_eq(pc.inventory.platinum, 1, "Should have 1 PP")
	assert_eq(pc.inventory.gold, 5, "Should have 5 GP")
	assert_eq(pc.inventory.silver, 12, "Should have 12 SP")
	assert_eq(pc.inventory.copper, 105, "Should have 105 CP")
	
	# Total value in CP:
	# 1 PP = 1000 CP
	# 5 GP = 500 CP
	# 12 SP = 120 CP
	# 105 CP = 105 CP
	# Total = 1725 CP
	assert_eq(pc.inventory.get_total_coin_value_in_copper(), 1725, "Total wealth should equal 1725 cp")
	
	# Spend some money (Cost 500 CP = 5 GP)
	var success = pc.inventory.remove_coins_by_copper_value(500)
	assert_true(success, "Should be able to afford 500 CP")
	
	assert_eq(pc.inventory.get_total_coin_value_in_copper(), 1225, "Total wealth should equal 1225 cp")
	
	# Since it just subtracted from copper, it will trigger consolidation
	# Copper was 105, spent 500 => -395 CP
	# This means it will borrow 40 SP to cover 400 CP, leaving 5 CP
	# Then SP will borrow from GP
	# Let's just test that the math adds up!
	assert_true(pc.inventory.copper >= 0, "Copper shouldn't be negative")
	assert_true(pc.inventory.silver >= 0, "Silver shouldn't be negative")
	assert_true(pc.inventory.gold >= 0, "Gold shouldn't be negative")
	assert_true(pc.inventory.platinum >= 0, "Platinum shouldn't be negative")
	
	# Check bulk
	# 1225 CP total value, but how many physical coins?
	# Let's say we have 1 PP, 1 GP, 2 SP, 5 CP = 9 coins
	# Bulk should be 0 because 9 < 1000
	assert_eq(pc.inventory.get_coin_bulk(), 0, "9 coins should be 0 bulk")
	
	# Add 1000 copper coins
	pc.inventory.add_currency(0, 0, 1000, 0)
	
	# Should be 1 Bulk (10 units)
	assert_eq(pc.inventory.get_coin_bulk(), 10, "1009 coins should be 1 Bulk")

func test_container_wealth() -> void:
	var pc = autofree(PFPlayerCharacter.new("Banker", [&"humanoid"], 1, 10, 0, 0, 0))
	add_child_autofree(pc)
	
	var PFContainerClass = load("res://scripts/items/pf_container.gd")
	var backpack = PFContainerClass.new()
	backpack.entity_name = "Backpack"
	backpack.price_cp = 100 # Backpack costs 100 CP
	
	pc.inventory.add_item(backpack)
	pc.inventory.containers.append(backpack)
	
	assert_eq(pc.inventory.get_total_wealth_in_copper(), 100, "Wealth should be exactly 100 CP (no double counting)")
	
	var sword = PFWeapon.new("Sword", [&"martial"])
	sword.price_cp = 150
	
	backpack.add_item(sword)
	assert_eq(pc.inventory.get_total_wealth_in_copper(), 250, "Wealth should include items stored in containers")
