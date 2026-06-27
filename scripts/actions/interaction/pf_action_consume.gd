# pf_action_consume.gd
## Action to consume a potion, elixir, or similar consumable item.
class_name PFActionConsume
extends PFAction

var item: PFConsumable

func _init(p_item: PFConsumable):
	# Using an item is generally 1 action (Interact) with the manipulate trait.
	super._init("Consume " + p_item.entity_name, [&"manipulate"], PFCombatConstants.ActionCost.ONE_ACTION)
	item = p_item

func execute(user: PFActor, _target: Variant = null) -> Variant:
	# 1. Check for Reactive Strikes against manipulate
	if await check_trait_triggers(user):
		print("    > [DISRUPTED] %s's attempt to consume %s was disrupted!" % [user.entity_name, item.entity_name])
		return false
		
	# 2. Consume the item
	var success = item.on_consume(user)
	if success:
		if item.charges <= 0:
			# Remove from inventory if empty
			if user.inventory.items.has(item):
				user.inventory.items.erase(item)
			elif user.inventory.held_main_hand == item:
				user.inventory.release_item(true)
			elif user.inventory.held_off_hand == item:
				user.inventory.release_item(false)
			user.inventory._emit_inventory_update()
			print("    > %s has been fully consumed." % item.entity_name)
		return true
		
	return false
