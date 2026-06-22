# pf_action_point_out.gd
## Allows an actor to point out an undetected creature, dropping them to Hidden for allies.
class_name PFActionPointOut
extends PFAction

func _init():
	super._init("Point Out", [&"auditory", &"manipulate", &"visual"], PFCombatConstants.ActionCost.ONE_ACTION, 0)

func execute(user: PFActor, target: PFActor = null) -> Variant:
	if await check_trait_triggers(user):
		return false
		
	if target == null:
		print("    > Point Out aborted: No target selected.")
		return false
	
	# The user must be able to at least see (Observe or have them Hidden) the target
	var user_state = PFContext.detection_manager.get_detection_state(user, target)
	if user_state == PFCombatConstants.DetectionState.UNDETECTED or user_state == PFCombatConstants.DetectionState.UNNOTICED:
		print("    > %s cannot Point Out %s because they are Undetected/Unnoticed to them!" % [user.entity_name, target.entity_name])
		return false
		
	print("    > %s points out the location of %s to their allies!" % [user.entity_name, target.entity_name])
	
	# Grab allies of the user
	var allies: Array[PFActor] = []
	if PFContext.active_turn_manager:
		allies = PFContext.active_turn_manager.get_enemies(target) # Enemies of the target are allies of the user
		
	var success_count = 0
	
	for ally in allies:
		if ally == user:
			continue
			
		var ally_state = PFContext.detection_manager.get_detection_state(ally, target)
		
		# If the target is Undetected or Unnoticed by the ally, upgrade them to Hidden
		if ally_state == PFCombatConstants.DetectionState.UNDETECTED or ally_state == PFCombatConstants.DetectionState.UNNOTICED:
			# Ideally we also check if the ally can see/hear the user pointing it out, but we'll assume they can for now.
			PFContext.detection_manager.set_detection_state(ally, target, PFCombatConstants.DetectionState.HIDDEN)
			print("    > %s is now Hidden to %s thanks to the Point Out!" % [target.entity_name, ally.entity_name])
			success_count += 1
			
	if success_count == 0:
		print("    > Point Out had no new effect (allies already knew their location).")
		
	return true
