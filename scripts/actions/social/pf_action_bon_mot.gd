# pf_action_bon_mot.gd
class_name PFActionBonMot
extends PFAction

func _init():
	super._init("Bon Mot", [&"auditory", &"concentrate", &"emotion", &"linguistic", &"mental"], PFCombatConstants.ActionCost.ONE_ACTION, 1)

func execute(user: PFActor, target: PFActor = null) -> bool:
	if not target:
		print("    > [ERROR] No target for Bon Mot!")
		return false
		
	var distance = user.global_position.distance_to(target.global_position)
	if distance > 30.0:
		print("    > [ERROR] Target is too far (%d ft > 30 ft)!" % distance)
		return false
		
	var immunity_key = StringName("bon_mot_" + user.name)
	if target.has_immunity(immunity_key):
		print("    > %s is immune to %s's Bon Mot!" % [target.entity_name, user.entity_name])
		return false
			
	var base_bonus = user.get_skill_bonus(&"diplomacy") if user.has_method(&"get_skill_bonus") else 0
	
	var nat_roll = PFDice.roll_d20()
	var roll_total = nat_roll + base_bonus
	
	var target_dc = 10 + (target.get_save_bonus(&"will") if target.has_method(&"get_save_bonus") else 0)
	
	var degree = PFDice.determine_success(roll_total, target_dc, nat_roll)
	
	print("\n>>> %s attempts a Bon Mot against %s!" % [user.entity_name, target.entity_name])
	print("    Diplomacy Roll: %d + Bonus: %d = Total: %d vs Will DC %d" % [nat_roll, base_bonus, roll_total, target_dc])
	
	match degree:
		PFMathConstants.DegreeOfSuccess.CRIT_SUCCESS:
			print("    *** CRITICAL SUCCESS! ***")
			print("    > Target takes a -3 status penalty to Perception and Will saves for 1 minute.")
			target.apply_condition(PFCondition.create(&"bon_mot", 3))
		PFMathConstants.DegreeOfSuccess.SUCCESS:
			print("    * SUCCESS! *")
			print("    > Target takes a -2 status penalty to Perception and Will saves for 1 minute.")
			target.apply_condition(PFCondition.create(&"bon_mot", 2))
		PFMathConstants.DegreeOfSuccess.FAIL:
			print("    Your quip falls flat. Target is unaffected.")
		PFMathConstants.DegreeOfSuccess.CRIT_FAIL:
			print("    [CRITICAL FAILURE] Your quip is completely misunderstood.")
			
	return true
