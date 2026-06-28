# pf_action_refocus.gd
## Exploration activity to regain a focus point.
class_name PFActionRefocus
extends PFAction

func _init():
	super._init("Refocus", [&"concentrate", &"exploration"], PFCombatConstants.ActionCost.FREE, 0)

func execute(user: PFActor, _target: Variant = null) -> Variant:
	print("    > %s spends 10 minutes Refocusing..." % user.entity_name)
	
	var time_manager = PFTimeManager.get_instance()
	if time_manager:
		time_manager.advance_minutes(10)
		
	if user.spellbook:
		user.spellbook.refocus()
	else:
		print("    > %s does not have a spellbook to refocus." % user.entity_name)
		
	return true

