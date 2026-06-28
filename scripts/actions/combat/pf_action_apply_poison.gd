# pf_action_apply_poison.gd
class_name PFActionApplyPoison
extends PFAction

var poison: PFConsumable
var weapon: PFWeapon

func _init(p_poison: PFConsumable, p_weapon: PFWeapon):
	super._init("Apply Poison", [&"manipulate", &"alchemical"] as Array[StringName], PFCombatConstants.ActionCost.TWO_ACTIONS, 0)
	poison = p_poison
	weapon = p_weapon

func execute(user: PFActor, target: Variant = null) -> Variant:
	if not super.execute(user, target):
		return false
		
	if not "poison_method" in poison or poison.poison_method != "injury":
		print("    > %s cannot be applied to a weapon!" % poison.entity_name)
		return false
		
	if not user.inventory.items.has(poison):
		print("    > You don't have %s to apply." % poison.entity_name)
		return false
		
	print("    > %s carefully applies %s to their %s." % [user.entity_name, poison.entity_name, weapon.entity_name])
	weapon.injection_payload = poison
	
	# The poison is used up when applied.
	poison.charges -= 1
	if poison.charges <= 0:
		user.inventory.unequip_item(poison)
		user.inventory.items.erase(poison)
		
	return true
