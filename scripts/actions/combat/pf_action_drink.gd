# pf_action_drink.gd
## Allows actors to drink a potion, elixir, or mutagen.
class_name PFActionDrink
extends PFAction

var target_item: PFConsumable

func _init(p_item: PFConsumable):
	super._init("Drink", [&"manipulate"], PFCombatConstants.ActionCost.ONE_ACTION)
	target_item = p_item

func is_usable(user: PFActor) -> bool:
	if not user.inventory:
		return false
		
	if target_item == null:
		return false
		
	# Consumables must be HELD to be drunk (assuming 1 hand). 
	# A creature cannot drink a STOWED or WORN consumable without drawing it first (Interact).
	if target_item.carry_state != PFEquipmentConstants.CarryState.HELD:
		print("    > %s must be HELD in a hand to Drink it." % target_item.entity_name)
		return false
	
	if target_item.consumable_type != "potion" and target_item.consumable_type != "elixir":
		print("    > %s is not a drinkable consumable." % target_item.entity_name)
		return false
		
	return true

func execute(user: PFActor, _target: PFActor = null) -> Variant:
	if await check_trait_triggers(user):
		return false # Disrupted
		
	print("%s uses %s on %s!" % [user.entity_name, entity_name, target_item.entity_name])
	
	# Activate the consumable effect
	var success = target_item.on_consume(user)
	if not success:
		return false
	
	# Remove the consumable from the inventory
	user.inventory.items.erase(target_item)
	user.inventory.worn_items.erase(target_item)
	if user.inventory.held_main_hand == target_item:
		user.inventory.release_item(true)
	elif user.inventory.held_off_hand == target_item:
		user.inventory.release_item(false)
		
	print("    > %s was consumed and removed from inventory." % target_item.entity_name)
	return true
