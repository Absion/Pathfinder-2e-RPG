# pf_action_aid.gd
class_name PFActionAid
extends PFAction

func _init():
	super._init("Aid", [], PFCombatConstants.ActionCost.ONE_ACTION)

func execute(user: PFActor, target: PFActor = null) -> Variant:
	if target == null or target == user:
		print(" -> %s must target an ally to Aid." % user.entity_name)
		return false

	if await check_trait_triggers(user):
		print(" -> %s's Aid action was disrupted!" % user.entity_name)
		return false
		
	super.execute(user, target)
	
	# Setting up Aid registers a custom reaction listener for ON_ALLY_ACTION
	var condition_lambda = func(trigger_actor: PFActor, event_data: Dictionary) -> bool:
		return trigger_actor == target
		
	var execute_lambda = func(trigger_actor: PFActor, event_data: Dictionary) -> Dictionary:
		print(" -> %s uses their reaction to Aid %s!" % [user.entity_name, trigger_actor.entity_name])
		
		# Simplification: In a full implementation, we would roll a skill check DC 15 to determine the bonus
		# For now, we will simulate a success (+1 circumstance bonus). A critical success could be +2, +3, or +4.
		# Apply a one-time bonus to the ally's roll or AC
		if event_data.has(&"roll_bonus"):
			event_data["roll_bonus"] += 1
			
		# Aid reaction is spent, unregister it
		PFContext.reaction_manager.unregister_listener(user, &"Aid")
		
		return event_data

	PFContext.reaction_manager.register_listener(PFCombatConstants.ReactionTriggers.ON_ALLY_ACTION, user, &"Aid", condition_lambda, execute_lambda)
	
	print(" -> %s prepares to Aid %s." % [user.entity_name, target.entity_name])
	return true
