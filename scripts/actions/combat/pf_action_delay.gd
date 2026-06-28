# pf_action_delay.gd
## Allows an actor to delay their turn, removing them from the initiative order to re-enter later.
class_name PFActionDelay
extends PFAction

func _init():
	super._init("Delay", [], PFCombatConstants.ActionCost.FREE)

func execute(user: PFActor, _target: Variant = null) -> bool:
	if not super.execute(user, null): return false
	
	if user.action_economy.actions_remaining < 3:
		print("    > [ERROR] You cannot Delay if you have already taken actions this turn.")
		return false
		
	# In Pathfinder 2e, you can't delay if you've already used actions, and your turn immediately ends.
	if PFContext.active_turn_manager:
		return PFContext.active_turn_manager.delay_current_turn()
		
	return false
