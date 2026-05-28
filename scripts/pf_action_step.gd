# pf_action_step.gd
class_name PFActionStep
extends PFAction

func _init():
	# We give it both "move" and "step" traits.
	super._init("Step", [&"move", &"step"], CostType.ONE)

func execute(user: PFActor, target: PFActor = null) -> bool:
	print("%s carefully steps 5 feet." % user.entity_name)
	return true
