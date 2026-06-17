# pf_reaction_grab_edge.gd
## Grab an Edge is a reaction triggered when you fall from or past an edge or handhold.
class_name PFReactionGrabEdge
extends RefCounted

## Registers the reaction with the ReactionManager for a specific actor.
static func register(actor: PFActor) -> void:
	if PFContext.reaction_manager:
		var cond = Callable(PFReactionGrabEdge, "condition").bind(actor)
		var exec = Callable(PFReactionGrabEdge, "execute").bind(actor)
		PFContext.reaction_manager.register_listener(PFCombatConstants.ReactionTriggers.ON_FALL, actor, &"Grab an Edge", cond, exec)

static func condition(listener: PFActor, _trigger_actor: PFActor, event_data: Dictionary) -> bool:
	# You can only grab an edge if YOU are the one falling
	if event_data.get("falling_actor") != listener:
		return false
		
	# You must have at least one hand free
	var inv = listener.get("inventory") as PFInventory
	if inv:
		if inv.held_main_hand != null and inv.held_off_hand != null:
			return false
			
	# There must be an edge to grab (usually passed in event_data)
	if not event_data.get("has_edge", false):
		return false
		
	return true

static func execute(listener: PFActor, _trigger_actor: PFActor, event_data: Dictionary) -> Dictionary:
	print("    > [REACTION] %s attempts to Grab an Edge!" % listener.entity_name)
	
	var edge_dc = event_data.get("edge_dc", 15) # Default DC if not provided
	
	var reflex_mod = listener.get_save_bonus(&"reflex")
	var roll = PFDice.roll(1, 20).total + reflex_mod
	
	print("    > Reflex Save: %d vs DC %d" % [roll, edge_dc])
	
	var degree = PFGameMath.get_degree_of_success(roll, edge_dc)
	
	if degree >= PFCombatConstants.DegreeOfSuccess.SUCCESS:
		print("    > Success! %s grabs the edge and stops falling." % listener.entity_name)
		event_data["fall_halted"] = true
		
		if degree == PFCombatConstants.DegreeOfSuccess.CRITICAL_SUCCESS:
			print("    > Critical Success! You don't take any damage from the fall.")
			event_data["fall_damage_multiplier"] = 0.0
		else:
			print("    > Success! You take damage as if you had fallen the distance you fell so far.")
			event_data["fall_damage_multiplier"] = 1.0 # This usually indicates normal fall damage for distance fallen so far
	else:
		print("    > Failure! %s fails to grab the edge and continues falling." % listener.entity_name)
		event_data["fall_halted"] = false
		if degree == PFCombatConstants.DegreeOfSuccess.CRITICAL_FAILURE:
			print("    > Critical Failure! You continue falling and take damage as normal.")
			
	return event_data
