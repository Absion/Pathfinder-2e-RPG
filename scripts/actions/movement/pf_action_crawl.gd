# pf_action_crawl.gd
class_name PFActionCrawl
extends PFAction

func _init():
	super._init("Crawl", [&"move"], PFCombatConstants.ActionCost.ONE_ACTION)

func execute(user: PFActor, _target: Variant = null) -> Variant:
	if not user.has_condition("prone"):
		print(" -> %s cannot Crawl because they are not Prone." % user.entity_name)
		return false

	if await check_trait_triggers(user):
		print(" -> %s's Crawl action was disrupted!" % user.entity_name)
		return false
		
	super.execute(user)
	
	# Emit leaving square to trigger any square-specific reactions
	await PFContext.reaction_manager.notify_event(PFCombatConstants.ReactionTriggers.ON_LEAVE_SQUARE, user, {
			"trigger_type": PFCombatConstants.ReactionTriggers.ON_LEAVE_SQUARE,
			"from_position": user.global_position
		})
	
	print(" -> %s crawls along the ground." % user.entity_name)
	return true
