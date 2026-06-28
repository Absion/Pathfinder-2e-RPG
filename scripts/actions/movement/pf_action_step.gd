# pf_action_step.gd
## Allows movement that does not trigger reactions.
class_name PFActionStep
extends PFAction

func _init():
	# We give it both "move" and "step" traits.
	super._init("Step", [&"move", &"step"], PFCombatConstants.ActionCost.ONE_ACTION)

func execute(user: PFActor, target: Variant = null) -> bool:
	print("%s carefully steps 5 feet." % user.entity_name)
	return true
