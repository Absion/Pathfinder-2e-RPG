# pf_action_parry.gd
## Allows a character to use a weapon with the parry trait to defend themselves.
class_name PFActionParry
extends PFAction

var weapon: PFWeapon

func _init(p_weapon: PFWeapon):
	var initial_traits: Array[StringName] = []
	weapon = p_weapon
	super._init("Parry with " + p_weapon.entity_name, initial_traits, PFCombatConstants.ActionCost.ONE_ACTION, 1)

func execute(user: PFActor, _target: PFActor = null) -> bool:
	var inv = user.get(&"inventory") as PFInventory
	if inv:
		if weapon.hands_required == 2 and inv.two_handed_item != weapon:
			print("    > [ERROR] %s requires two hands, but is not being held with two hands!" % weapon.entity_name)
			return false
		elif weapon.hands_required == 1 and inv.held_main_hand != weapon and inv.held_off_hand != weapon and inv.two_handed_item != weapon:
			print("    > [ERROR] %s must be held to parry!" % weapon.entity_name)
			return false
			
	if not weapon.has_trait(&"parry"):
		print("    > [ERROR] %s does not have the parry trait!" % weapon.entity_name)
		return false
		
	var parry_condition = PFCondition.create(&"parry")
	user.apply_condition(parry_condition)
	print("\n>>> %s parries with %s! (+1 circumstance bonus to AC until start of next turn)" % [user.entity_name, weapon.entity_name])
	
	return true
