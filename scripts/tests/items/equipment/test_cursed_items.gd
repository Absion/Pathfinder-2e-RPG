extends "res://addons/gut/test.gd"

func test_inventory_cursed_item():
	var actor = autofree(PFPlayerCharacter.new("Actor", [], 1, 10, 0, 0, 0))
	actor.inventory = PFInventory.new(actor)
	
	var cursed_ring = PFItem.new("Cursed Ring of DOOM", [&"cursed"])
	actor.inventory.add_item(cursed_ring)
	actor.inventory.equip_item(cursed_ring)
	
	actor.inventory.unequip_item(cursed_ring)
	assert_true(actor.inventory.worn_items.has(cursed_ring), "Cursed item should refuse to be unequipped")
