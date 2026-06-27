# pf_action_sneak.gd
## Allows an actor to move while remaining undetected or hidden.
class_name PFActionSneak
extends PFAction

func _init():
	super._init("Sneak", [&"move", &"secret"], PFCombatConstants.ActionCost.ONE_ACTION, 0)

func execute(user: PFActor, target: Variant = null) -> Variant:
	if await check_trait_triggers(user):
		return false
		
	# If targets is empty, grab all enemies from context
	var target_actors: Array[PFActor] = []
	if target == null:
		if PFContext.active_turn_manager:
			target_actors = PFContext.active_turn_manager.get_enemies(user)
	else:
		target_actors.append(target)
		
	if target_actors.is_empty():
		print("    > Sneak aborted: No hostile observers found.")
		return false
		
	var stealth_bonus = user.get_skill_bonus(&"stealth")
	var roll = PFDice.roll_d20()
	var total = roll + stealth_bonus
	
	print("    > %s attempts to Sneak! (Stealth Roll: %d [Secret])" % [user.entity_name, total])
	
	var success_count = 0
	
	for tgt in target_actors:
		var current_state = PFContext.detection_manager.get_detection_state(tgt, user)
		
		# You can only Sneak if you are Hidden or Undetected from the target
		if current_state == PFCombatConstants.DetectionState.OBSERVED:
			print("    > %s cannot Sneak past %s because they are already Observed!" % [user.entity_name, tgt.entity_name])
			continue
			
		var perception_dc = tgt.get_skill_bonus(&"perception") + 10
		var degree = PFDice.determine_success(total, perception_dc, roll)
		
		if degree == PFDice.Degree.SUCCESS or degree == PFDice.Degree.CRIT_SUCCESS:
			# Stay hidden/undetected
			print("    > %s successfully sneaks past %s." % [user.entity_name, tgt.entity_name])
			user.set_meta(&"is_sneaking", true)
			success_count += 1
		elif degree == PFDice.Degree.FAIL:
			# If Undetected, become Hidden. If Hidden, become Observed.
			if current_state == PFCombatConstants.DetectionState.UNDETECTED or current_state == PFCombatConstants.DetectionState.UNNOTICED:
				PFContext.detection_manager.set_detection_state(tgt, user, PFCombatConstants.DetectionState.HIDDEN)
			else:
				PFContext.detection_manager.set_detection_state(tgt, user, PFCombatConstants.DetectionState.OBSERVED)
		elif degree == PFDice.Degree.CRIT_FAIL:
			# Automatically observed
			PFContext.detection_manager.set_detection_state(tgt, user, PFCombatConstants.DetectionState.OBSERVED)
			
	return success_count > 0
