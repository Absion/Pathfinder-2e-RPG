# pf_action_hide.gd
## Allows the user to roll Stealth to become Hidden or Undetected to observers.
class_name PFActionHide
extends PFAction

func _init():
	# Represents Hide, Sneak, and Avoid Notice mechanically for now.
	super._init("Hide", [&"secret"], PFCombatConstants.ActionCost.ONE_ACTION)

func execute(user: PFActor, _target: PFActor = null) -> bool:
	if not super.execute(user, null): return false
	
	if not PFContext.detection_manager:
		print("    > [ERROR] DetectionManager is missing!")
		return false
		
	# Roll Stealth
	var stealth_mod = user.get_skill_bonus(&"stealth")
	var stealth_roll = PFDice.roll(1, 20).total + stealth_mod
	print("    > %s rolls Stealth: %d" % [user.entity_name, stealth_roll])
	
	# Evaluate against all potential observers
	var all_combatants = []
	all_combatants.append_array(PFContext.active_party)
	all_combatants.append_array(PFContext.reserve_party)
	
	var observers = user.get_tree().get_nodes_in_group("actors") if user.is_inside_tree() else all_combatants
	var valid_observers = 0
	
	for obs in observers:
		if obs == user or not obs is PFActor:
			continue
			
		valid_observers += 1
		
		# 1. Environment Check: Must have Cover or Concealment
		var cover = PFContext.detection_manager.get_cover(obs, user)
		var concealed = PFContext.detection_manager.is_concealed(obs, user)
		
		if cover == PFCombatConstants.CoverType.NONE and not concealed:
			print("    > %s automatically fails to Hide from %s (No Cover or Concealment)." % [user.entity_name, obs.entity_name])
			PFContext.detection_manager.set_detection_state(obs, user, PFCombatConstants.DetectionState.OBSERVED)
			continue
			
		# 2. Senses Check: Bypassing cover if precise sense is used
		if PFContext.detection_manager.detects_with_precise_sense(obs, user):
			print("    > %s automatically fails to Hide from %s (Detected by precise non-visual sense)." % [user.entity_name, obs.entity_name])
			PFContext.detection_manager.set_detection_state(obs, user, PFCombatConstants.DetectionState.OBSERVED)
			continue
			
		var obs_perception_dc = 10 + obs.get_skill_bonus(&"perception")
		var degree = PFGameMath.get_degree_of_success(stealth_roll, obs_perception_dc)
		
		# If user succeeds, they become Hidden (or Undetected if they were already Hidden/Concealed)
		if degree >= PFCombatConstants.DegreeOfSuccess.SUCCESS:
			var current_state = PFContext.detection_manager.get_detection_state(obs, user)
			var new_state = PFCombatConstants.DetectionState.HIDDEN
			
			if current_state >= PFCombatConstants.DetectionState.HIDDEN:
				new_state = PFCombatConstants.DetectionState.UNDETECTED
				
			PFContext.detection_manager.set_detection_state(obs, user, new_state)
			print("    > %s beat %s's Perception DC (%d). They are now %s." % [
				user.entity_name, obs.entity_name, obs_perception_dc, PFCombatConstants.DetectionState.keys()[new_state]
			])
		else:
			print("    > %s failed against %s's Perception DC (%d). They remain observed." % [
				user.entity_name, obs.entity_name, obs_perception_dc
			])
			if degree == PFCombatConstants.DegreeOfSuccess.CRITICAL_FAILURE:
				PFContext.detection_manager.set_detection_state(obs, user, PFCombatConstants.DetectionState.OBSERVED)
				
	if valid_observers == 0:
		print("    > %s hid, but there was no one around to observe them." % user.entity_name)
		
	return true
