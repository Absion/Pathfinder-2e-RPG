# pf_action_command_minion.gd
class_name PFActionCommandMinion
extends PFAction

func _init():
	super._init("Command an Animal", [&"auditory", &"concentrate", &"manipulate"], PFCombatConstants.ActionCost.ONE_ACTION)

func execute(actor: PFActor, target: Variant = null) -> bool:
	if target == null:
		print("    > [ERROR] Command requires a target minion.")
		return false
		
	if not target is PFMinion:
		print("    > [ERROR] Target must be a PFMinion.")
		return false
		
	if target.master != actor:
		print("    > [ERROR] You can only command your own minions.")
		return false
		
	print("    > %s issues commands to %s!" % [actor.entity_name, target.entity_name])
	
	# Grant the minion 2 actions and push the sub-turn
	target.action_economy.actions_remaining = 2
	target.commanded_this_turn = true
	
	if PFContext.active_turn_manager:
		PFContext.active_turn_manager.push_sub_turn(target)
		
	return true
