# pf_action_seek.gd
## Allows the user to roll Perception to find Hidden or Undetected targets.
class_name PFActionSeek
extends PFAction

func _init():
	super._init("Seek", [&"concentrate", &"secret"], PFCombatConstants.ActionCost.ONE_ACTION)

func execute(user: PFActor, target: PFActor = null) -> bool:
	if not super.execute(user, target): return false
	
	if not PFContext.detection_manager:
		print("    > [ERROR] DetectionManager is missing!")
		return false
		
	# Roll Perception
	var perc_mod = user.get_skill_bonus(&"perception")
	var perc_roll = PFDice.roll(1, 20).total + perc_mod
	print("    > %s rolls Perception to Seek: %d" % [user.entity_name, perc_roll])
	
	var targets = [target] if target else user.get_tree().get_nodes_in_group("actors")
	
	for t in targets:
		if t == user or not t is PFActor:
			continue
			
		var state = PFContext.detection_manager.get_detection_state(user, t)
		if state >= PFCombatConstants.DetectionState.HIDDEN:
			var user_prof = user.get_skill_rank(&"perception") if user.has_method(&"get_skill_rank") else PFMathConstants.ProficiencyRank.UNTRAINED
			
			if t is PFHazard and user_prof < t.stealth_min_proficiency:
				print("    > %s lacks the minimum Perception proficiency to notice %s." % [user.entity_name, t.entity_name])
				continue
				
			var stealth_dc = t.stealth_dc if t is PFHazard else 10 + t.get_skill_bonus(&"stealth")
			var degree = PFGameMath.get_degree_of_success(perc_roll, stealth_dc)
			
			if degree >= PFCombatConstants.DegreeOfSuccess.SUCCESS:
				# Success drops them to Observed (or Hidden if they are Invisible, but we'll assume Observed for now)
				var new_state = PFCombatConstants.DetectionState.OBSERVED
				PFContext.detection_manager.set_detection_state(user, t, new_state)
				print("    > %s found %s! They beat their Stealth DC (%d)." % [
					user.entity_name, t.entity_name, stealth_dc
				])
			else:
				print("    > %s failed to find %s (Stealth DC %d)." % [
					user.entity_name, t.entity_name, stealth_dc
				])
				
	return true
