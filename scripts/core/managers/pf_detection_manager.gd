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



## Calculates the current cover the target has relative to the observer.
## In a full 3D game, this would use raycasting. For the backend, we provide a placeholder that can be mocked.
func get_cover(observer: PFActor, target: PFActor) -> PFCombatConstants.CoverType:
	# Default to no cover. Tests can override or mock this.
	# We can check a mock dictionary for testing
	if target.has_meta(&"mock_cover_vs_" + observer.name):
		return target.get_meta(&"mock_cover_vs_" + observer.name) as PFCombatConstants.CoverType
	return PFCombatConstants.CoverType.NONE

## Calculates if the target is concealed from the observer (e.g. by fog, dim light).
func is_concealed(observer: PFActor, target: PFActor) -> bool:
	if target.has_meta(&"mock_concealed_vs_" + observer.name):
		return target.get_meta(&"mock_concealed_vs_" + observer.name) as bool
		
	# Check Lighting Conditions
	if PFContext.environment_manager:
		var light_level = PFContext.environment_manager.current_light_level
		if light_level == PFEnvironmentConstants.LightLevel.DIM_LIGHT or light_level == PFEnvironmentConstants.LightLevel.DARKNESS:
			# Dim Light / Darkness grants Concealment (or worse), unless observer has special vision
			var vision = PFBiographyConstants.Vision.NORMAL
			if "senses" in observer and observer.senses != null:
				vision = observer.senses.vision
				
			if light_level == PFEnvironmentConstants.LightLevel.DARKNESS and vision != PFBiographyConstants.Vision.DARKVISION:
				# In darkness without darkvision, you are blinded to the target (they are Hidden or Undetected).
				# For the simple is_concealed check, we can return true because they definitely have concealment.
				# A more robust system would push them straight to Hidden if they try to target.
				return true
				
			if light_level == PFEnvironmentConstants.LightLevel.DIM_LIGHT and vision == PFBiographyConstants.Vision.NORMAL:
				return true
				
	# If the target has the Invisible condition, they are practically concealed to vision
	if target.has_meta(&"is_invisible") and target.get_meta(&"is_invisible"):
		return true
		
	return false

## Evaluates if the observer's precise senses automatically detect the target, bypassing visual cover.
func detects_with_precise_sense(observer: PFActor, target: PFActor) -> bool:
	if not "senses" in observer or observer.senses == null: return false
	var senses_comp = observer.senses
	
	var cached_dist_sq = -1.0

	for sense in senses_comp.senses:
		if sense.acuity == PFBiographyConstants.SenseAcuity.PRECISE:
			# If it's vision, it requires line of sight (cover applies).
			if sense.type == PFBiographyConstants.SenseType.VISION:
				if target.has_meta(&"is_invisible") and target.get_meta(&"is_invisible"):
					continue # Vision cannot detect an invisible creature precisely
				continue
				
			# If it's a non-visual precise sense (e.g., Scent, Tremorsense)
			if target.has_meta(&"masked_sense_" + str(sense.type)):
				continue
				
			# Range check
			if sense.range_ft > 0:
				if cached_dist_sq < 0.0:
					cached_dist_sq = observer.global_position.distance_squared_to(target.global_position)
				if cached_dist_sq > (sense.range_ft * sense.range_ft):
					continue
					
			print("    > [Senses] %s detects %s using precise %s!" % [observer.entity_name, target.entity_name, PFBiographyConstants.SenseType.keys()[sense.type]])
			return true
				
	return false

## Evaluates if an imprecise sense (like Hearing or Scent) detects the target.
func detects_with_imprecise_sense(observer: PFActor, target: PFActor) -> bool:
	if not "senses" in observer or observer.senses == null: return false
	var senses_comp = observer.senses
	
	var cached_dist_sq = -1.0

	for sense in senses_comp.senses:
		if sense.acuity == PFBiographyConstants.SenseAcuity.IMPRECISE:
			if target.has_meta(&"masked_sense_" + str(sense.type)):
				continue
				
			if sense.range_ft > 0:
				if cached_dist_sq < 0.0:
					cached_dist_sq = observer.global_position.distance_squared_to(target.global_position)
				if cached_dist_sq > (sense.range_ft * sense.range_ft):
					continue
					
			return true
			
	return false

## Upgrades state to Hidden if observer detects target with Imprecise senses while they were Undetected.
func apply_imprecise_senses() -> void:
	# This should be called periodically or after movements
	# ⚡ Bolt: Iterate directly over dictionaries instead of using .keys() to avoid Array allocations
	for obs in matrix:
		for tgt in matrix[obs]:
			var state = matrix[obs][tgt]
			if state == PFCombatConstants.DetectionState.UNDETECTED or state == PFCombatConstants.DetectionState.UNNOTICED:
				if tgt.has_meta(&"is_sneaking") and tgt.get_meta(&"is_sneaking"):
					continue # Target is actively Sneaking, masking their imprecise presence
					
				if detects_with_imprecise_sense(obs, tgt):
					# Imprecise senses can't make you Observed, but they stop you from being Undetected
					set_detection_state(obs, tgt, PFCombatConstants.DetectionState.HIDDEN)
					print("    > %s detects %s's general presence via imprecise senses." % [obs.entity_name, tgt.entity_name])

## Evaluates if a vague sense (like smell) detects the target.
func detects_with_vague_sense(observer: PFActor, target: PFActor) -> bool:
	if not "senses" in observer or observer.senses == null: return false
	var senses_comp = observer.senses
	
	var cached_dist_sq = -1.0

	for sense in senses_comp.senses:
		if sense.acuity == PFBiographyConstants.SenseAcuity.VAGUE:
			if target.has_meta(&"masked_sense_" + str(sense.type)):
				continue
			if sense.range_ft > 0:
				if cached_dist_sq < 0.0:
					cached_dist_sq = observer.global_position.distance_squared_to(target.global_position)
				if cached_dist_sq > (sense.range_ft * sense.range_ft):
					continue
			return true
	return false

## Upgrades state to Undetected if observer detects target with Vague senses while they were Unnoticed.
func apply_vague_senses() -> void:
	# ⚡ Bolt: Iterate directly over dictionaries instead of using .keys() to avoid Array allocations
	for obs in matrix:
		for tgt in matrix[obs]:
			var state = matrix[obs][tgt]
			if state == PFCombatConstants.DetectionState.UNNOTICED:
				if tgt.has_meta(&"is_sneaking") and tgt.get_meta(&"is_sneaking"):
					continue # Target is actively Sneaking, masking their vague presence too
					
				if detects_with_vague_sense(obs, tgt):
					set_detection_state(obs, tgt, PFCombatConstants.DetectionState.UNDETECTED)
					print("    > %s notices something is present via vague senses." % [obs.entity_name])

## Performs the mandatory flat check for targeting Concealed, Hidden, or Undetected creatures.
func roll_flat_check_for_targeting(attacker: PFActor, target: PFActor) -> bool:
	var state = get_detection_state(attacker, target)
	
	# If Unnoticed, you can't even try to target them.
	if state == PFCombatConstants.DetectionState.UNNOTICED:
		print("    > Targeting fails: %s is unaware of %s!" % [attacker.entity_name, target.entity_name])
		return false
		
	# Check if target is Concealed (independent of stealth state, e.g., due to dim light/fog)
	var is_target_concealed = is_concealed(attacker, target)
	
	var dc = 0
	if state == PFCombatConstants.DetectionState.UNDETECTED:
		dc = 11
		print("    > Targeting UNDETECTED creature! (Must guess square first). Flat Check DC 11.")
	elif state == PFCombatConstants.DetectionState.HIDDEN:
		dc = 11
		print("    > Targeting HIDDEN creature! Flat Check DC 11.")
	elif is_target_concealed:
		dc = 5
		print("    > Targeting CONCEALED creature! Flat Check DC 5.")
		
	if dc > 0:
		var roll = PFDice.roll_d20()
		if roll < dc:
			print("    > Flat check failed! (Rolled %d vs DC %d)" % [roll, dc])
			return false
		print("    > Flat check succeeded! (Rolled %d vs DC %d)" % [roll, dc])
		
	return true
