# pf_action_seek.gd
## Allows an actor to search for hidden or undetected creatures.
class_name PFActionSeek
extends PFAction

func _init():
	super._init("Seek", [&"concentrate", &"secret"], PFCombatConstants.ActionCost.ONE_ACTION, 0)

func execute(user: PFActor, target: PFActor = null) -> Variant:
	if await check_trait_triggers(user):
		return false
		
	var target_actors: Array[PFActor] = []
	if target == null:
		# TODO: Integrate spatial AOE math to grab actors in a 30-foot cone or 15-foot burst
		if PFContext.active_turn_manager:
			target_actors = PFContext.active_turn_manager.get_enemies(user)
	else:
		target_actors.append(target)
		
	if target_actors.is_empty():
		print("    > Seek aborted: No targets to search for.")
		return false
		
	var perception_bonus = user.get_skill_bonus(&"perception")
	var roll = PFDice.roll_d20()
	var total = roll + perception_bonus
	
	print("    > %s attempts to Seek! (Perception Roll: %d [Secret])" % [user.entity_name, total])
	
	var success_count = 0
	
	for tgt in target_actors:
		var current_state = PFContext.detection_manager.get_detection_state(user, tgt)
		
		# If they are already observed, Seeking doesn't do anything to them
		if current_state == PFCombatConstants.DetectionState.OBSERVED:
			continue
			
		var stealth_dc = 0
		var min_prof = 0
		
		if tgt is PFHazard:
			stealth_dc = tgt.stealth_dc
			min_prof = tgt.stealth_min_proficiency
		else:
			stealth_dc = tgt.get_skill_bonus(&"stealth") + 10
			
		# Check minimum proficiency if applicable
		if min_prof > PFMathConstants.ProficiencyRank.UNTRAINED:
			var seeker_prof = PFMathConstants.ProficiencyRank.UNTRAINED
			if "sheet" in user and user.sheet != null:
				seeker_prof = user.sheet.get_skill_rank(&"perception")
			if seeker_prof < min_prof:
				continue # Automatically fail to find it
				
		var degree = PFDice.determine_success(total, stealth_dc, roll)
		
		if degree == PFDice.Degree.CRIT_SUCCESS:
			PFContext.detection_manager.set_detection_state(user, tgt, PFCombatConstants.DetectionState.OBSERVED)
			success_count += 1
		elif degree == PFDice.Degree.SUCCESS:
			if current_state == PFCombatConstants.DetectionState.UNDETECTED or current_state == PFCombatConstants.DetectionState.UNNOTICED:
				PFContext.detection_manager.set_detection_state(user, tgt, PFCombatConstants.DetectionState.HIDDEN)
			elif current_state == PFCombatConstants.DetectionState.HIDDEN:
				PFContext.detection_manager.set_detection_state(user, tgt, PFCombatConstants.DetectionState.OBSERVED)
			success_count += 1
			
	return success_count > 0
