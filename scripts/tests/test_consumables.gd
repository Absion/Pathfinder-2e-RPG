extends SceneTree

class_name TestConsumables

func get_test_name() -> String:
	return "Consumables and Activation Tests"

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
	print("\n--- Running Consumables Tests ---")
	
	var pc = PFPlayerCharacter.new("Test Actor", [&"humanoid"], 1, 10, 0, 0, 0)
	
	# Test Consumable
	var potion = PFConsumable.new("potion_of_healing")
	potion.entity_name = "Potion of Minor Healing"
	potion.charges = 1
	potion.consumable_type = "potion"
	potion.add_trait(&"healing")
	
	pc.inventory.add_item(potion)
	assert_true(pc.inventory.items.has(potion), "Potion should be in inventory")
	
	var action = PFActionConsume.new(potion)
	action.execute(pc)
	
	assert_eq(potion.charges, 0, "Potion charges should be 0")
	assert_false(pc.inventory.items.has(potion), "Potion should be removed from inventory after consumption")
	
	# Test Equipment Activation
	var ring = PFEquipment.new("ring_of_fire")
	ring.entity_name = "Ring of Fire"
	ring.requires_investment = true
	
	pc.inventory.add_item(ring)
	pc.inventory.equip_item(ring) # Fails investment
	assert_false(pc.inventory.worn_items.has(ring), "Should not equip uninvested ring")
	
	pc.inventory.invest_item(ring)
	pc.inventory.equip_item(ring)
	assert_true(pc.inventory.worn_items.has(ring), "Should equip invested ring")
	
	var act_action = PFActionActivateItem.new(ring)
	var success = await act_action.execute(pc)
	assert_true(success, "Should successfully activate the invested item")
	
	print("Consumables tests passed!")
