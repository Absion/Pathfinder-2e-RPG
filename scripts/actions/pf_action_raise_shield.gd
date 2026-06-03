# pf_action_raise_shield.gd
class_name PFActionRaiseShield
extends PFAction

func _init():
	super._init("Raise a Shield", [], CostType.ONE, 0)

func execute(user: PFActor, target: PFActor = null) -> bool:
	# 1. Find a shield that is being wielded
	# We look at held_main_hand, held_off_hand, and two_handed_item
	var shield: PFShield = null
	
	if user.inventory.held_main_hand is PFShield and user.inventory.held_main_hand.is_wielded:
		shield = user.inventory.held_main_hand
	elif user.inventory.held_off_hand is PFShield and user.inventory.held_off_hand.is_wielded:
		shield = user.inventory.held_off_hand
	elif user.inventory.two_handed_item is PFShield and user.inventory.two_handed_item.is_wielded:
		shield = user.inventory.two_handed_item
		
	# 2. Check if we found a valid shield
	if shield == null:
		print("    > %s tries to raise a shield, but doesn't have one wielded!" % user.entity_name)
		return false
		
	if shield.is_destroyed():
		print("    > %s tries to raise their shield, but it is destroyed!" % user.entity_name)
		return false

	# 3. Use our new Inventory check for Buckler/Hand constraints
	if not user.inventory.can_raise_shield(shield):
		print("    > [!] %s cannot raise their shield: hand is occupied by a weapon or heavy object!" % user.entity_name)
		return false
		
	# 4. Action successful!
	var condition = PFConditionRaisedShield.new(shield)
	user.apply_condition(condition)
	return true
