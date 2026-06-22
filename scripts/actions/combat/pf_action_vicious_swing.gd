# pf_action_vicious_swing.gd
# A heavy attack. Costs 2 Actions, adds 2 to MAP (unless using Furious Focus).
## A powerful two-action strike that deals additional weapon damage dice.
class_name PFActionViciousSwing
extends PFAction

func _init(has_furious_focus: bool = false):
	# PF2e Rule: Vicious Swing counts as two attacks for MAP.
	# Furious Focus feat reduces it to counting as one.
	var weight = 1 if has_furious_focus else 2
	
	# Costs TWO actions, map_weight varies based on feat
	super._init("Vicious Swing", [&"attack"], PFCombatConstants.ActionCost.TWO_ACTIONS, weight)

func execute(user: PFActor, target: PFActor = null) -> bool:
	if target == null:
		return false
		
	# The attack roll is still made at whatever the current MAP stack is.
	# The penalty only increases AFTER the execute completes.
	var map_penalty = mini(user.attack_stacks, 2) * -5
	print("%s delivers a massive Vicious Swing at %s! (MAP Penalty: %d)" % [user.entity_name, target.entity_name, map_penalty])
	
	return true
