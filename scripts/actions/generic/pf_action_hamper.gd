# pf_action_hamper.gd
class_name PFActionHamper
extends PFAction

var weapon: PFWeapon

func _init(p_weapon: PFWeapon):
	weapon = p_weapon
	super._init("Hamper", [&"manipulate"], PFCombatConstants.ActionCost.ONE_ACTION, 1)

func execute(user: PFActor, _target: Variant = null) -> bool:
	if not weapon:
		return false
		
	if not weapon.has_trait(&"hampering"):
		print("    > [ERROR] This weapon does not have the hampering trait!")
		return false
		
	var inventory = user.get(&"inventory") as PFInventory
	if inventory:
		if inventory.held_main_hand != weapon and inventory.held_off_hand != weapon and inventory.two_handed_item != weapon:
			print("    > [ERROR] You must be holding the weapon to hamper!")
			return false
			
	user.set_meta(&"is_hampering", true)
	print("    > %s thrashes their %s to create difficult terrain!" % [user.entity_name, weapon.entity_name])
	return true

