# pf_detection_manager.gd
## Manages the relational detection states (Observed, Hidden, Undetected) between all actors.
## Inherently asymmetrical: Actor A can be Hidden to Actor B, but Observed by Actor C.
class_name PFDetectionManager
extends Node

# A nested dictionary tracking detection.
# Structure: { observer_actor: { target_actor: PFCombatConstants.DetectionState } }
var matrix: Dictionary = {}

## Gets the detection state of the target relative to the observer.
## If no specific state has been set, it assumes OBSERVED by default.
func get_detection_state(observer: PFActor, target: PFActor) -> PFCombatConstants.DetectionState:
	if matrix.has(observer):
		if matrix[observer].has(target):
			return matrix[observer][target]
	return PFCombatConstants.DetectionState.OBSERVED

## Sets the detection state of the target relative to the observer.
func set_detection_state(observer: PFActor, target: PFActor, state: PFCombatConstants.DetectionState) -> void:
	if not matrix.has(observer):
		matrix[observer] = {}
		
	var old_state = get_detection_state(observer, target)
	if old_state != state:
		matrix[observer][target] = state
		print("    > [Detection] %s is now %s to %s." % [
			target.entity_name, 
			PFCombatConstants.DetectionState.keys()[state], 
			observer.entity_name
		])

## Cleans up any references to an actor if they are destroyed.
func remove_actor(actor: PFActor) -> void:
	# Remove as observer
	matrix.erase(actor)
	# Remove as target
	for obs in matrix:
		matrix[obs].erase(actor)

## Forces a flat check based on the target's detection state relative to the observer.
## Returns true if the attack/spell is allowed to proceed, false if it automatically misses.
func roll_flat_check_for_targeting(observer: PFActor, target: PFActor) -> bool:
	var state = get_detection_state(observer, target)
	
	if state == PFCombatConstants.DetectionState.OBSERVED:
		return true
		
	if state == PFCombatConstants.DetectionState.UNNOTICED:
		print("    > %s tries to target %s but they are completely Unnoticed!" % [observer.entity_name, target.entity_name])
		return false
		
	var dc = 0
	if state == PFCombatConstants.DetectionState.CONCEALED:
		dc = 5
	elif state == PFCombatConstants.DetectionState.HIDDEN or state == PFCombatConstants.DetectionState.UNDETECTED:
		dc = 11
		
	# Roll the flat check (1d20 >= DC, no modifiers apply)
	# Flat checks don't have degrees of success in the same way, just pass/fail.
	var roll = PFDice.roll(1, 20).total
	var success = roll >= dc
	
	var state_str = PFCombatConstants.DetectionState.keys()[state].capitalize()
	if success:
		print("    > Flat Check (%s DC %d): %s rolled %d. Success!" % [state_str, dc, observer.entity_name, roll])
		return true
	else:
		print("    > Flat Check (%s DC %d): %s rolled %d. Failure! The attack misses." % [state_str, dc, observer.entity_name, roll])
		return false
