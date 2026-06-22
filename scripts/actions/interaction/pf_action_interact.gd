# pf_action_interact.gd
class_name PFActionInteract
extends PFAction

func _init():
	super._init("Interact", [&"manipulate"], PFCombatConstants.ActionCost.ONE_ACTION)

func execute(user: PFActor, target: PFActor = null) -> Variant:
	if await check_trait_triggers(user):
		print(" -> %s's Interact action was disrupted!" % user.entity_name)
		return false
		
	super.execute(user, target)
	print(" -> %s interacts with the environment." % user.entity_name)
	return true
