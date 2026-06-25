# pf_action_hide.gd
## Allows an actor to hide from enemies, transitioning to the Hidden state.
class_name PFActionHide
extends PFAction

func _init():
	super._init("Hide", [&"secret"], PFCombatConstants.ActionCost.ONE_ACTION, 0)

func execute(user: PFActor, target: PFActor = null) -> Variant:
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
		print("    > Hide fails: No hostile observers found.")
		return false

	var stealth_bonus = user.get_skill_bonus(&"stealth")
	var roll = PFDice.roll_d20()
	var total = roll + stealth_bonus
	
	print("    > %s attempts to Hide! (Stealth Roll: %d [Secret])" % [user.entity_name, total])
	
	var success_count = 0
	
	for tgt in target_actors:
		# Check if user has cover or is concealed
		var cover = PFContext.detection_manager.get_cover(tgt, user)
		var is_concealed = PFContext.detection_manager.is_concealed(tgt, user)
		
		if cover == PFCombatConstants.CoverType.NONE and not is_concealed:
			print("    > %s lacks cover/concealment against %s! Automatically observed." % [user.entity_name, tgt.entity_name])
			PFContext.detection_manager.set_detection_state(tgt, user, PFCombatConstants.DetectionState.OBSERVED)
			continue
			
		var perception_dc = tgt.get_skill_bonus(&"perception") + 10
		var degree = PFDice.determine_success(total, perception_dc, roll)
		
		if degree == PFDice.Degree.SUCCESS or degree == PFDice.Degree.CRIT_SUCCESS:
			PFContext.detection_manager.set_detection_state(tgt, user, PFCombatConstants.DetectionState.HIDDEN)
			success_count += 1
		else:
			# If you fail, you remain observed (or become observed)
			PFContext.detection_manager.set_detection_state(tgt, user, PFCombatConstants.DetectionState.OBSERVED)
			
	return success_count > 0
