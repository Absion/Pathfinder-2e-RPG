# pf_action_sneak.gd
## Allows the actor to move stealthily.
class_name PFActionSneak
extends PFAction

func _init():
	super._init("Sneak", [&"secret", &"move"], PFCombatConstants.ActionCost.ONE_ACTION)

func execute(user: PFActor, _target: PFActor = null) -> bool:
	if not super.execute(user, null): return false
	
	if not PFContext.detection_manager:
		print("    > [ERROR] DetectionManager is missing!")
		return false
		
	# Sneak involves movement. We'll abstract the actual positional move for the backend
	# and just process the stealth implications. The actor moves at half speed.
	print("    > %s Sneaks (moves at half speed)." % user.entity_name)
	
	var stealth_mod = user.get_skill_bonus(&"stealth")
	var stealth_roll = PFDice.roll(1, 20).total + stealth_mod
	print("    > %s rolls Stealth: %d" % [user.entity_name, stealth_roll])
	
	var all_combatants = []
	all_combatants.append_array(PFContext.active_party)
	all_combatants.append_array(PFContext.reserve_party)
	
	var observers = user.get_tree().get_nodes_in_group("actors") if user.is_inside_tree() else all_combatants
	var valid_observers = 0
	
	for obs in observers:
		if obs == user or not obs is PFActor:
			continue
			
		valid_observers += 1
		var initial_state = PFContext.detection_manager.get_detection_state(obs, user)
		
		# You must be Hidden or Undetected to Sneak past someone
		if initial_state < PFCombatConstants.DetectionState.HIDDEN:
			print("    > %s is already Observed by %s. Sneak fails automatically against them." % [user.entity_name, obs.entity_name])
			continue
			
		# End of movement environmental check
		var cover = PFContext.detection_manager.get_cover(obs, user)
		var concealed = PFContext.detection_manager.is_concealed(obs, user)
		
		if cover == PFCombatConstants.CoverType.NONE and not concealed:
			print("    > %s ends movement without Cover or Concealment from %s. They become Observed." % [user.entity_name, obs.entity_name])
			PFContext.detection_manager.set_detection_state(obs, user, PFCombatConstants.DetectionState.OBSERVED)
			continue
			
		if PFContext.detection_manager.detects_with_precise_sense(obs, user):
			print("    > %s ends movement in range of %s's precise sense. They become Observed." % [user.entity_name, obs.entity_name])
			PFContext.detection_manager.set_detection_state(obs, user, PFCombatConstants.DetectionState.OBSERVED)
			continue
			
		# Resolve Stealth vs Perception DC
		var obs_perception_dc = 10 + obs.get_skill_bonus(&"perception")
		var degree = PFGameMath.get_degree_of_success(stealth_roll, obs_perception_dc)
		
		if degree >= PFCombatConstants.DegreeOfSuccess.SUCCESS:
			var new_state = PFCombatConstants.DetectionState.UNDETECTED
			PFContext.detection_manager.set_detection_state(obs, user, new_state)
			print("    > %s beat %s's Perception DC (%d). They remain %s." % [
				user.entity_name, obs.entity_name, obs_perception_dc, PFCombatConstants.DetectionState.keys()[new_state]
			])
		else:
			print("    > %s failed against %s's Perception DC (%d). They become Hidden (if undetected) or Observed (if already hidden or critical failure)." % [
				user.entity_name, obs.entity_name, obs_perception_dc
			])
			if degree == PFCombatConstants.DegreeOfSuccess.CRITICAL_FAILURE:
				PFContext.detection_manager.set_detection_state(obs, user, PFCombatConstants.DetectionState.OBSERVED)
			else:
				if initial_state == PFCombatConstants.DetectionState.UNDETECTED:
					PFContext.detection_manager.set_detection_state(obs, user, PFCombatConstants.DetectionState.HIDDEN)
				else:
					PFContext.detection_manager.set_detection_state(obs, user, PFCombatConstants.DetectionState.OBSERVED)
					
	if valid_observers == 0:
		print("    > %s sneaked, but there was no one around to observe them." % user.entity_name)
		
	return true
