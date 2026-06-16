# pf_action_point_out.gd
## Allows a user who can see a Hidden/Undetected creature to reveal it to allies.
class_name PFActionPointOut
extends PFAction

func _init():
	super._init("Point Out", [&"auditory", &"manipulate", &"visual"], PFCombatConstants.ActionCost.ONE_ACTION)

func execute(user: PFActor, target: PFActor = null) -> bool:
	if not super.execute(user, target): return false
	
	if target == null:
		print("    > [ERROR] Point Out requires a specific target!")
		return false
		
	if not PFContext.detection_manager:
		return false
		
	var user_state = PFContext.detection_manager.get_detection_state(user, target)
	
	# User must know where the target is (Observed or Hidden) to point them out.
	# If they are Undetected to the user, they can't point them out.
	if user_state >= PFCombatConstants.DetectionState.UNDETECTED:
		print("    > [ERROR] %s cannot Point Out %s because they are Undetected or Unnoticed by %s!" % [
			user.entity_name, target.entity_name, user.entity_name
		])
		return false
		
	print("    > %s points out the location of %s!" % [user.entity_name, target.entity_name])
	
	# Find all allies (rough logic for now: active_party vs enemies)
	# Assuming user is a PC, allies are active_party + reserve_party. If enemy, allies are other enemies.
	# For simplicity, we just lower the target's stealth state for EVERYONE who considers them Undetected.
	var observers = user.get_tree().get_nodes_in_group("actors") if user.is_inside_tree() else PFContext.active_party + PFContext.reserve_party
	
	for obs in observers:
		if obs == user or obs == target or not obs is PFActor:
			continue
			
		var obs_state = PFContext.detection_manager.get_detection_state(obs, target)
		if obs_state == PFCombatConstants.DetectionState.UNDETECTED or obs_state == PFCombatConstants.DetectionState.UNNOTICED:
			# Point Out reduces Undetected/Unnoticed to Hidden for allies.
			PFContext.detection_manager.set_detection_state(obs, target, PFCombatConstants.DetectionState.HIDDEN)
			print("    > %s is now aware of %s (Hidden)." % [obs.entity_name, target.entity_name])
			
	return true
