# pf_action_sense_motive.gd
## Allows an actor to roll a secret Perception check against a target's Deception DC.
class_name PFActionSenseMotive
extends PFAction

func _init():
	super._init("Sense Motive", [&"concentrate", &"secret"], PFCombatConstants.ActionCost.ONE_ACTION)

func execute(user: PFActor, target: Variant = null) -> bool:
	if not super.execute(user, target): return false
	
	if target == null:
		print("    > [ERROR] Sense Motive requires a target.")
		return false
		
	var perc_mod = user.get_skill_bonus(&"perception")
	var roll = PFDice.roll(1, 20).total + perc_mod
	
	var deception_dc = 10 + target.get_skill_bonus(&"deception")
	
	print("    > %s attempts to Sense Motive of %s. Rolling secret Perception..." % [
		user.entity_name, target.entity_name
	])
	
	var degree = PFGameMath.get_degree_of_success(roll, deception_dc)
	
	match degree:
		PFCombatConstants.DegreeOfSuccess.CRITICAL_SUCCESS:
			print("    > [CRITICAL SUCCESS] You determine the creature's true intentions and get a solid idea of any mental magic affecting it.")
		PFCombatConstants.DegreeOfSuccess.SUCCESS:
			print("    > [SUCCESS] You can tell whether the creature is behaving normally, but you don't know its exact intentions or what magic might be affecting it.")
		PFCombatConstants.DegreeOfSuccess.FAILURE:
			print("    > [FAILURE] You detect what a deceptive creature wants you to believe. If they're not being deceptive, you believe they're behaving normally.")
		PFCombatConstants.DegreeOfSuccess.CRITICAL_FAILURE:
			print("    > [CRITICAL FAILURE] You get a false sense of the creature's intentions.")
			
	return true
