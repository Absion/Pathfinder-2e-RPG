# pf_action_stride.gd
## Standard movement action up to the actor's speed.
class_name PFActionStride
extends PFAction

func _init():
	# A Stride costs 1 action and has the "move" trait.
	super._init("Stride", [&"move"], PFCombatConstants.ActionCost.ONE_ACTION)

func execute(user: PFActor, target: PFActor = null) -> bool:
	# In a real game, this would interface with your grid movement system.
	print("%s moves to a new location." % user.entity_name)
	return true
