# pf_action_create_diversion.gd
class_name PFActionCreateDiversion
extends PFAction

func _init():
	super._init("Create a Diversion", [&"manipulate", &"mental"], PFCombatConstants.ActionCost.ONE_ACTION, 1)

func execute(user: PFActor, target: PFActor = null) -> bool:
	# Note: Create a Diversion can technically target all observing creatures in PF2e.
	# For simplicity in this demo, we'll allow targeting a specific creature.
	if not target:
		print("    > [ERROR] No target for Create a Diversion!")
		return false
			
	var base_bonus = user.get_skill_bonus(&"deception") if user.has_method(&"get_skill_bonus") else 0
	
	var nat_roll = PFDice.roll_d20()
	var roll_total = nat_roll + base_bonus
	
	var target_dc = 10 + (target.get_save_bonus(&"perception") if target.has_method(&"get_save_bonus") else 0)
	
	var degree = PFDice.determine_success(roll_total, target_dc, nat_roll)
	
	print("\n>>> %s attempts to Create a Diversion against %s!" % [user.entity_name, target.entity_name])
	print("    Deception Roll: %d + Bonus: %d = Total: %d vs Perception DC %d" % [nat_roll, base_bonus, roll_total, target_dc])
	
	match degree:
		PFMathConstants.DegreeOfSuccess.CRIT_SUCCESS, PFMathConstants.DegreeOfSuccess.SUCCESS:
			print("    * SUCCESS! *")
			print("    > You become Hidden to the target until the end of your turn or until you do something else that breaks your concealed state!")
			user.apply_condition(PFCondition.create(&"hidden"))
		PFMathConstants.DegreeOfSuccess.FAIL:
			print("    Your diversion fails.")
		PFMathConstants.DegreeOfSuccess.CRIT_FAIL:
			print("    [CRITICAL FAILURE] You fail to distract them and make your intentions obvious.")
			
	return true
