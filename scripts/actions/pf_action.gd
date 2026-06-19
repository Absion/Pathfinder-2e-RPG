# pf_action.gd
# Represents any action a character can take. Inherits from PFEntity so it has traits!
# Now includes 'map_weight' to control exactly how many MAP stacks an action generates.
## Base class representing a single discrete action an actor can take in combat.
class_name PFAction
extends PFEntity

var cost: PFCombatConstants.ActionCost
var map_weight: int = 0 # How many MAP stacks this action adds when completed

# Constructor
func _init(p_name: String, p_traits: Array[StringName], p_cost: PFCombatConstants.ActionCost, p_map_weight: int = 0):
	# Pass the name and traits up to PFEntity
	super._init(p_name, p_traits)
	
	cost = p_cost
	map_weight = p_map_weight

func execute(user: PFActor, _target: PFActor = null) -> Variant:
	print("%s performs %s!" % [user.entity_name, entity_name])
	return true

## Checks trait-based triggers like ON_MANIPULATE or ON_MOVE.
## Subclasses should `await` this at the start of their execute() function.
## Returns `true` if the action was disrupted (e.g., by a critical Reactive Strike on a manipulate action), `false` otherwise.
func check_trait_triggers(user: PFActor) -> bool:
	var disrupted = false
	var event_data = {"disrupted": false}
	
	if has_trait(&"manipulate") and PFContext.reaction_manager:
		event_data = await PFContext.reaction_manager.notify_event(PFCombatConstants.ReactionTriggers.ON_MANIPULATE, user, event_data)
		if event_data.get(&"disrupted", false):
			disrupted = true
			
	if has_trait(&"move") and PFContext.reaction_manager:
		event_data = await PFContext.reaction_manager.notify_event(PFCombatConstants.ReactionTriggers.ON_MOVE, user, event_data)
		if event_data.get(&"disrupted", false):
			disrupted = true
			
	return disrupted
