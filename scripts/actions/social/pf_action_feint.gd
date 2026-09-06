# pf_action_feint.gd
class_name PFActionFeint
extends PFAction

func _init():
	super._init("Feint", [&"mental"], PFCombatConstants.ActionCost.ONE_ACTION, 1)

func execute(user: PFActor, target: Variant = null) -> bool:
	if not target:
		print("    > [ERROR] No target for Feint!")
		return false
		
	var distance_sq = user.global_position.distance_squared_to(target.global_position)
	var reach = 5 # Should technically check weapon reach, but Feint generally requires melee reach
	if distance_sq > reach * reach:
		print("    > [ERROR] Target is too far for a melee Feint (%d ft > %d ft)!" % [sqrt(distance_sq), reach])
		return false
			
	var base_bonus = user.get_skill_bonus(&"deception")
	
	var nat_roll = PFDice.roll_d20()
	var roll_total = nat_roll + base_bonus
	
	var target_dc = 10 + (target.get_save_bonus(&"perception") if target.has_method(&"get_save_bonus") else 0)
	
	var degree = PFDice.determine_success(roll_total, target_dc, nat_roll)
	
	print("\n>>> %s attempts to Feint %s!" % [user.entity_name, target.entity_name])
	print("    Deception Roll: %d + Bonus: %d = Total: %d vs Perception DC %d" % [nat_roll, base_bonus, roll_total, target_dc])
	
	match degree:
		PFMathConstants.DegreeOfSuccess.CRIT_SUCCESS:
			print("    *** CRITICAL SUCCESS! ***")
			print("    > Target is Off-Guard against your melee attacks until the end of your next turn!")
			target.apply_condition(PFCondition.create(&"off_guard")) # Needs a duration tracker specific to the attacker
		PFMathConstants.DegreeOfSuccess.SUCCESS:
			print("    * SUCCESS! *")
			print("    > Target is Off-Guard against your next melee attack before the end of your current turn!")
			target.apply_condition(PFCondition.create(&"off_guard"))
		PFMathConstants.DegreeOfSuccess.FAIL:
			print("    Target is unaffected.")
		PFMathConstants.DegreeOfSuccess.CRIT_FAIL:
			print("    [CRITICAL FAILURE]")
			print("    > You fumble the feint and become Off-Guard to their melee attacks!")
			user.apply_condition(PFCondition.create(&"off_guard"))
			
	return true
