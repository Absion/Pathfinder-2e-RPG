extends GutTest

var actor: PFActor
var sword: PFWeapon
var shield: PFShield
var potion: PFConsumable

func before_each():
	actor = PFPlayerCharacter.new("Fighter", [], 1, 15, 0, 0, 0)
	
	sword = PFWeapon.new("Longsword", [&"versatile-p"])
	sword.carry_state = PFEquipmentConstants.CarryState.STOWED
	
	shield = PFShield.new("Steel Shield")
	shield.carry_state = PFEquipmentConstants.CarryState.WORN
	
	potion = PFConsumable.new("mock_potion")
	potion.entity_name = "Health Potion"
	potion.consumable_type = "potion"
	potion.charges = 1
	potion.carry_state = PFEquipmentConstants.CarryState.DROPPED
	
	actor.inventory.add_item(sword)
	actor.inventory.add_item(shield)
	
	# Move shield to WORN
	actor.inventory.equip_item(shield)

func after_each():
	actor.queue_free()

func test_draw_weapon():
	var ActionInteract = load("res://scripts/actions/combat/pf_action_interact.gd")
	var action_draw = ActionInteract.new(ActionInteract.InteractType.DRAW, shield, true)
	
	assert_true(shield.carry_state == PFEquipmentConstants.CarryState.WORN, "Shield should start WORN")
	assert_true(action_draw.is_usable(actor), "Draw should be usable on a WORN item")
	
	await action_draw.execute(actor)
	assert_true(shield.carry_state == PFEquipmentConstants.CarryState.HELD, "Shield should be HELD after Draw")
	assert_eq(actor.inventory.held_main_hand, shield, "Shield should be in main hand")
	
func test_retrieve_weapon():
	var ActionInteract = load("res://scripts/actions/combat/pf_action_interact.gd")
	var action_retrieve = ActionInteract.new(ActionInteract.InteractType.RETRIEVE, sword, true)
	
	assert_true(sword.carry_state == PFEquipmentConstants.CarryState.STOWED, "Sword should start STOWED")
	assert_true(action_retrieve.is_usable(actor), "Retrieve should be usable on a STOWED item")
	assert_eq(action_retrieve.cost, PFCombatConstants.ActionCost.TWO_ACTIONS, "Retrieve should cost 2 actions")
	
	await action_retrieve.execute(actor)
	assert_true(sword.carry_state == PFEquipmentConstants.CarryState.HELD, "Sword should be HELD after Retrieve")
	assert_eq(actor.inventory.held_main_hand, sword, "Sword should be in main hand")

func test_stow_weapon():
	actor.inventory.hold_item(sword, true)
	
	var ActionInteract = load("res://scripts/actions/combat/pf_action_interact.gd")
	var action_stow = ActionInteract.new(ActionInteract.InteractType.STOW, sword, true)
	
	assert_true(sword.carry_state == PFEquipmentConstants.CarryState.HELD, "Sword should be HELD")
	assert_true(action_stow.is_usable(actor), "Stow should be usable on a HELD item")
	
	await action_stow.execute(actor)
	assert_true(sword.carry_state == PFEquipmentConstants.CarryState.WORN, "Sword should be WORN after Stow")
	assert_null(actor.inventory.held_main_hand, "Main hand should be empty")
	
func test_pick_up_and_release():
	var ActionInteract = load("res://scripts/actions/combat/pf_action_interact.gd")
	var action_pickup = ActionInteract.new(ActionInteract.InteractType.PICK_UP, potion, true)
	
	assert_true(potion.carry_state == PFEquipmentConstants.CarryState.DROPPED, "Potion should be DROPPED")
	assert_true(action_pickup.is_usable(actor), "Pick up should be usable on DROPPED item")
	
	await action_pickup.execute(actor)
	assert_true(potion.carry_state == PFEquipmentConstants.CarryState.HELD, "Potion should be HELD after Pick Up")
	
	var action_release = ActionInteract.new(ActionInteract.InteractType.RELEASE, potion, true)
	assert_true(action_release.is_usable(actor), "Release should be usable on HELD item")
	assert_eq(action_release.cost, PFCombatConstants.ActionCost.FREE, "Release should be free")
	
	await action_release.execute(actor)
	assert_true(potion.carry_state == PFEquipmentConstants.CarryState.DROPPED, "Potion should be DROPPED after Release")
	assert_null(actor.inventory.held_main_hand, "Main hand should be empty")

func test_swap_weapon():
	actor.inventory.hold_item(sword, true)
	var ActionInteract = load("res://scripts/actions/combat/pf_action_interact.gd")
	var action_swap = ActionInteract.new(ActionInteract.InteractType.SWAP, sword, true, shield)
	assert_true(action_swap.is_usable(actor), "Swap should be usable")
	
	await action_swap.execute(actor)
	assert_true(sword.carry_state == PFEquipmentConstants.CarryState.WORN, "Sword should be stowed (WORN)")
	assert_true(shield.carry_state == PFEquipmentConstants.CarryState.HELD, "Shield should be drawn (HELD)")
	assert_eq(actor.inventory.held_main_hand, shield, "Shield should be in main hand")

func test_pass_item():
	var ally = PFPlayerCharacter.new("Ally", [], 1, 15, 0, 0, 0)
	actor.inventory.hold_item(potion, true)
	var ActionInteract = load("res://scripts/actions/combat/pf_action_interact.gd")
	var action_pass = ActionInteract.new(ActionInteract.InteractType.PASS_OFF, potion, true)
	assert_true(action_pass.is_usable(actor), "Pass off should be usable")
	
	await action_pass.execute(actor, ally)
	assert_null(actor.inventory.held_main_hand, "Actor should not hold potion")
	assert_eq(ally.inventory.held_main_hand, potion, "Ally should hold potion")
	ally.queue_free()

func test_throw_item():
	var enemy = PFNpc.new("enemy_1", "Enemy", [&"humanoid"], 1, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0)
	actor.inventory.hold_item(potion, true)
	var ActionInteract = load("res://scripts/actions/combat/pf_action_interact.gd")
	var action_throw = ActionInteract.new(ActionInteract.InteractType.THROW, potion, true)
	assert_true(action_throw.is_usable(actor), "Throw should be usable")
	
	await action_throw.execute(actor, enemy)
	assert_null(actor.inventory.held_main_hand, "Actor should not hold potion")
	assert_eq(potion.current_hp, 0, "Consumable potion should shatter")
	enemy.queue_free()

func test_change_grip():
	actor.inventory.hold_item(sword, true)
	var ActionInteract = load("res://scripts/actions/combat/pf_action_interact.gd")
	var action_add_grip = ActionInteract.new(ActionInteract.InteractType.CHANGE_GRIP_ADD, sword, true)
	assert_true(action_add_grip.is_usable(actor), "Add Grip should be usable")
	
	await action_add_grip.execute(actor)
	assert_eq(actor.inventory.two_handed_item, sword, "Sword should be held in two hands")
	assert_null(actor.inventory.held_main_hand, "Main hand should be empty as it's now a 2H item")
	
	var action_remove_grip = ActionInteract.new(ActionInteract.InteractType.CHANGE_GRIP_REMOVE, sword, true)
	assert_true(action_remove_grip.is_usable(actor), "Remove Grip should be usable")
	await action_remove_grip.execute(actor)
	assert_eq(actor.inventory.held_main_hand, sword, "Sword should be back in main hand")
	assert_null(actor.inventory.two_handed_item, "2H slot should be empty")
