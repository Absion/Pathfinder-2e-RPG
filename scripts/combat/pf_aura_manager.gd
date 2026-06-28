# pf_aura_manager.gd
## A centralized manager to track and process auras (Banners, Bless, Stench, etc.)
## on the combat grid or in the scene.
class_name PFAuraManager
extends RefCounted

## Represents an active aura.
class AuraInstance:
	var emitter: Variant # Could be PFActor or PFItem
	var condition_id: StringName
	var radius_feet: int
	var applies_to: String # "allies", "enemies", "all"
	var current_targets: Array[PFActor] = []

var active_auras: Array[AuraInstance] = []

func register_aura(emitter: Variant, condition_id: StringName, radius_feet: int, applies_to: String = "allies") -> AuraInstance:
	var aura = AuraInstance.new()
	aura.emitter = emitter
	aura.condition_id = condition_id
	aura.radius_feet = radius_feet
	aura.applies_to = applies_to
	active_auras.append(aura)
	print("    > [AURA] Registered new aura from %s (Radius: %d ft, Condition: %s)." % [
		emitter.entity_name if "entity_name" in emitter else str(emitter),
		radius_feet, 
		condition_id
	])
	return aura

func unregister_aura(aura: AuraInstance) -> void:
	if active_auras.has(aura):
		_clear_aura_from_targets(aura)
		active_auras.erase(aura)
		print("    > [AURA] Unregistered aura.")

## Called periodically (e.g., at the start of a turn, or on movement)
func process_auras(all_actors: Array[PFActor]) -> void:
	for aura in active_auras:
		if not ("position" in aura.emitter):
			continue
			
		var emitter_pos = aura.emitter.position # Assuming a generic position vector
		
		# Find who is in range
		var in_range_actors: Array[PFActor] = []
		for actor in all_actors:
			if typeof(aura.emitter) == TYPE_OBJECT and actor == (aura.emitter as Object):
				in_range_actors.append(actor)
				continue
				
			var dist = actor.position.distance_to(emitter_pos) # Assume distance works this way in 3D/2D
			var grid_dist = (dist / 1.0) * 5.0 # Very rough approximation if 1 unit = 5 feet
			# Better: use PFSpatialMath if available, but for now we approximate distance
			# In actual PF2e game, we would query the CombatGrid.
			if grid_dist <= aura.radius_feet:
				# Check applies_to logic (simplified)
				if aura.applies_to == "all":
					in_range_actors.append(actor)
				elif aura.applies_to == "allies" and aura.emitter.has_method("is_ally") and aura.emitter.is_ally(actor):
					in_range_actors.append(actor)
				elif aura.applies_to == "enemies" and aura.emitter.has_method("is_enemy") and aura.emitter.is_enemy(actor):
					in_range_actors.append(actor)
					
		# Remove condition from targets that left the aura
		for target in aura.current_targets:
			if not in_range_actors.has(target):
				if target.has_method("remove_condition"):
					target.remove_condition(aura.condition_id)
				print("    > [AURA] %s left aura, removed %s." % [target.entity_name, aura.condition_id])
					
		# Add condition to targets that entered the aura
		for target in in_range_actors:
			if not aura.current_targets.has(target):
				if target.has_method("apply_condition"):
					var cond = PFCondition.create(aura.condition_id)
					if cond: target.apply_condition(cond)
				print("    > [AURA] %s entered aura, applied %s." % [target.entity_name, aura.condition_id])
				
		aura.current_targets = in_range_actors

func _clear_aura_from_targets(aura: AuraInstance) -> void:
	for target in aura.current_targets:
		if target.has_method("remove_condition"):
			target.remove_condition(aura.condition_id)
	aura.current_targets.clear()
