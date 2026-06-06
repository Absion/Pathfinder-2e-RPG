# pf_action_fly.gd
## Implements the Fly action for aerial movement.
class_name PFActionFly
extends PFAction

func _init():
	super._init("Fly", [&"move"], PFCombatConstants.ActionCost.ONE_ACTION)

func execute(user: PFActor, target: PFActor = null) -> bool:
	# Check if the actor actually has a fly speed!
	if user.speed_fly <= 0:
		print("%s tries to fly, but they don't have a fly speed!" % user.entity_name)
		return false # Action fails, but they still spent the action (PF2e rules!)
		
	print("%s flies up to %d feet." % [user.entity_name, user.speed_fly])
	return true
