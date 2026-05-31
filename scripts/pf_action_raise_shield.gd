# pf_action_raise_shield.gd
class_name PFActionRaiseShield
extends PFAction

func _init():
	super._init("Raise a Shield", [], CostType.ONE, 0)

func execute(user: PFActor, target: PFActor = null) -> bool:
	if user.equipped_shield == null:
		print("    > %s tries to raise a shield, but doesn't have one equipped!" % user.entity_name)
		return false
		
	if user.equipped_shield.is_destroyed():
		print("    > %s tries to raise their shield, but it is destroyed!" % user.entity_name)
		return false
		
	var condition = PFConditionRaisedShield.new(user.equipped_shield)
	user.apply_condition(condition)
	return true
