# pf_action_demoralize.gd
class_name PFActionDemoralize
extends PFAction

func _init():
	super._init("Demoralize", [&"auditory", &"concentrate", &"emotion", &"fear", &"mental"], PFCombatConstants.ActionCost.ONE_ACTION, 1)

func execute(user: PFActor, target: Variant = null) -> bool:
	if not target:
		print("    > [ERROR] No target for Demoralize!")
		return false
		
	var distance = user.global_position.distance_to(target.global_position)
	if distance > 30.0:
		print("    > [ERROR] Target is too far (%d ft > 30 ft)!" % distance)
		return false
		
	var immunity_key = StringName("demoralize_" + str(user.get_instance_id()))
	if target.has_immunity(immunity_key):
		print("    > %s is immune to %s's Demoralize!" % [target.entity_name, user.entity_name])
		return false
		
	# Check if target understands language (usually Demoralize takes a -4 penalty if they don't, but we'll assume they do for now or apply penalty if no common language)
	var penalty = 0
	if user.has_method("languages") and target.has_method("languages"):
		var share_language = false
		for lang in user.languages:
			if target.languages.has(lang):
				share_language = true
				break
		if not share_language:
			penalty = -4
			print("    > (No shared language: -4 penalty to Demoralize)")
			
	var base_bonus = user.get_skill_bonus(&"intimidation") if user.has_method(&"get_skill_bonus") else 0
	var total_bonus = base_bonus + penalty
	
	var nat_roll = PFDice.roll_d20()
	var roll_total = nat_roll + total_bonus
	
	var target_dc = 10 + (target.get_save_bonus(&"will") if target.has_method(&"get_save_bonus") else 0)
	
	var degree = PFDice.determine_success(roll_total, target_dc, nat_roll)
	
	print("\n>>> %s attempts to Demoralize %s!" % [user.entity_name, target.entity_name])
	print("    Intimidation Roll: %d + Bonus: %d = Total: %d vs Will DC %d" % [nat_roll, total_bonus, roll_total, target_dc])
	
	match degree:
		PFMathConstants.DegreeOfSuccess.CRIT_SUCCESS:
			print("    *** CRITICAL SUCCESS! ***")
			target.apply_condition(PFCondition.create(&"frightened", 2))
		PFMathConstants.DegreeOfSuccess.SUCCESS:
			print("    * SUCCESS! *")
			target.apply_condition(PFCondition.create(&"frightened", 1))
		PFMathConstants.DegreeOfSuccess.FAIL:
			print("    Target is unaffected.")
		PFMathConstants.DegreeOfSuccess.CRIT_FAIL:
			print("    [CRITICAL FAILURE] Target is unaffected and completely unimpressed.")
			
	# Target is immune for 10 minutes (100 rounds)
	target.add_immunity(immunity_key, 100)
	return true
