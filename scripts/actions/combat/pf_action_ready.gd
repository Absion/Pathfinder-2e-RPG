# pf_action_ready.gd
class_name PFActionReady
extends PFAction

var stored_action: PFAction

func _init(p_stored_action: PFAction):
	super._init("Ready", [&"concentrate"], PFCombatConstants.ActionCost.TWO_ACTIONS)
	stored_action = p_stored_action

func execute(user: PFActor, target: Variant = null) -> Variant:
	if stored_action == null:
		print(" -> %s failed to Ready: No action specified." % user.entity_name)
		return false
		
	if stored_action.cost != PFCombatConstants.ActionCost.ONE_ACTION and stored_action.cost != PFCombatConstants.ActionCost.FREE:
		print(" -> %s failed to Ready: Can only ready a single action or free action." % user.entity_name)
		return false

	if await check_trait_triggers(user):
		print(" -> %s's Ready action was disrupted!" % user.entity_name)
		return false
		
	super.execute(user, target)
	
	# We use a custom reaction trigger ON_ALLY_ACTION or something similar in tests,
	# but for a generic Ready action, the player defines the trigger. For simplicity in the engine right now,
	# we will listen to ON_MOVE and ON_MANIPULATE from any hostile as the trigger.
	
	var condition_lambda = func(trigger_actor: PFActor, _event_data: Dictionary) -> bool:
		# Trigger if the actor is hostile
		return trigger_actor != user # simplified hostility check
		
	var execute_lambda = func(trigger_actor: PFActor, event_data: Dictionary) -> Dictionary:
		print(" -> %s's Readied action triggers!" % user.entity_name)
		
		# Execute the stored action. Target is assumed to be the trigger_actor unless it was specified differently.
		await stored_action.execute(user, trigger_actor)
		
		# Reaction is spent, unregister
		PFContext.reaction_manager.unregister_listener(user, &"Ready")
		
		return event_data

	# Register on generic hostile actions
	PFContext.reaction_manager.register_listener(PFCombatConstants.ReactionTriggers.ON_MOVE, user, &"Ready", condition_lambda, execute_lambda)
	PFContext.reaction_manager.register_listener(PFCombatConstants.ReactionTriggers.ON_MANIPULATE, user, &"Ready", condition_lambda, execute_lambda)
	
	print(" -> %s readies an action: %s." % [user.entity_name, stored_action.entity_name])
	return true
