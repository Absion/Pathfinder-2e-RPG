# pf_action_leap.gd
class_name PFActionLeap
extends PFAction

func _init():
	super._init("Leap", [&"move"], PFCombatConstants.ActionCost.ONE_ACTION)

func execute(user: PFActor, _target: PFActor = null) -> Variant:
	if await check_trait_triggers(user):
		print(" -> %s's Leap action was disrupted!" % user.entity_name)
		return false
		
	super.execute(user)
	
	# Emit leaving square to trigger any square-specific reactions
	if PFContext.reaction_manager:
		await PFContext.reaction_manager.notify_event(PFCombatConstants.ReactionTriggers.ON_LEAVE_SQUARE, user, {
			"trigger_type": PFCombatConstants.ReactionTriggers.ON_LEAVE_SQUARE,
			"from_position": user.global_position
		})
	
	print(" -> %s leaps horizontally or vertically." % user.entity_name)
	return true
