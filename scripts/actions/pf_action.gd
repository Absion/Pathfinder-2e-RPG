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

# This is a virtual function. Specific actions (like Strike or Stride) will 
# override this to perform their unique logic.
func execute(user: PFActor, _target: PFActor = null):
	print("%s performs %s!" % [user.entity_name, entity_name])
	return true
