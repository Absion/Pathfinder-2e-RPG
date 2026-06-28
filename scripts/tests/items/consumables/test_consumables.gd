extends GutTest

var actor: PFActor
var potion

func before_each():
	PFContext.init_shared_services()
	actor = PFPlayerCharacter.new("Fighter", [], 1, 15, 0, 0, 0)
	actor.health.current_hp = 1 # Nearly dead
	
	potion = PFConsumable.new("mock_potion")
	potion.entity_name = "Minor Healing Potion"
	potion.consumable_type = "potion"
	potion.charges = 1
	potion.carry_state = PFEquipmentConstants.CarryState.HELD
	actor.inventory.add_item(potion)
	actor.inventory.hold_item(potion, true)

func after_each():
	PFContext.cleanup_shared_services()
	if is_instance_valid(actor): actor.free()

func test_drink_potion():
	var ActionDrink = load("res://scripts/actions/combat/pf_action_drink.gd")
	var action_drink = ActionDrink.new(potion)
	
	assert_true(action_drink.is_usable(actor), "Drink should be usable when HELD")
	
	await action_drink.execute(actor)
	assert_true(potion.charges == 0 or potion not in actor.inventory.items, "Potion should be consumed")
	assert_null(actor.inventory.held_main_hand, "Hand should be empty after drinking")

func test_cannot_drink_stowed():
	potion.carry_state = PFEquipmentConstants.CarryState.STOWED
	actor.inventory.release_item(true)
	
	var ActionDrink = load("res://scripts/actions/combat/pf_action_drink.gd")
	var action_drink = ActionDrink.new(potion)
	assert_false(action_drink.is_usable(actor), "Cannot drink a STOWED potion")
