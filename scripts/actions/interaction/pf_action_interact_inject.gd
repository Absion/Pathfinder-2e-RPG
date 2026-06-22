# pf_action_interact_inject.gd
class_name PFActionInteractInject
extends PFAction

var weapon: PFWeapon
var item_to_load: PFItem

func _init(p_weapon: PFWeapon, p_item: PFItem):
	weapon = p_weapon
	item_to_load = p_item
	super._init("Interact (Load Injection Payload)", [&"manipulate"], PFCombatConstants.ActionCost.ONE_ACTION, 1)

func execute(user: PFActor, _target: PFActor = null) -> bool:
	if not weapon:
		return false
		
	if not weapon.has_trait(&"injection"):
		print("    > [ERROR] This weapon does not have the injection trait!")
		return false
		
	if weapon.injection_payload != null:
		print("    > [ERROR] The weapon is already loaded with a payload!")
		return false
		
	var inv = user.get(&"inventory") as PFInventory
	if inv:
		if inv.held_main_hand != weapon and inv.held_off_hand != weapon and inv.two_handed_item != weapon:
			print("    > [ERROR] You must be holding the weapon to load it!")
			return false
			
		if not inv.items.has(item_to_load):
			print("    > [ERROR] You do not have that item in your inventory!")
			return false
			
	# In a full system, verify item_to_load is a valid poison or potion
	weapon.injection_payload = item_to_load
	if inv:
		inv.items.erase(item_to_load) # It is now stored in the weapon
		
	print("    > Loaded %s into %s!" % [item_to_load.entity_name, weapon.entity_name])
	return true
