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
		# ⚡ Bolt: Cache squared radius outside the loop to avoid redundant math
		var radius_units = aura.radius_feet / 5.0
		var radius_sq = radius_units * radius_units
		
		# ⚡ Bolt: Cache loop-invariant reflection and type checks to minimize GDScript overhead
		var emitter_is_object = typeof(aura.emitter) == TYPE_OBJECT
		var emitter_obj = aura.emitter as Object if emitter_is_object else null
		var applies_all = aura.applies_to == "all"
		var applies_allies = aura.applies_to == "allies"
		var applies_enemies = aura.applies_to == "enemies"
		var has_is_ally = emitter_is_object and aura.emitter.has_method(&"is_ally")
		var has_is_enemy = emitter_is_object and aura.emitter.has_method(&"is_enemy")

		# Find who is in range
		var in_range_actors: Array[PFActor] = []
		for actor in all_actors:
			if emitter_is_object and actor == emitter_obj:
				in_range_actors.append(actor)
				continue
				
			# ⚡ Bolt: Use native distance_squared_to instead of distance_to
			# to avoid expensive `sqrt` calls while maintaining 2D/3D compatibility
			if actor.position.distance_squared_to(emitter_pos) <= radius_sq:
				# Check applies_to logic (simplified)
				if applies_all:
					in_range_actors.append(actor)
				elif applies_allies and has_is_ally and aura.emitter.is_ally(actor):
					in_range_actors.append(actor)
				elif applies_enemies and has_is_enemy and aura.emitter.is_enemy(actor):
					in_range_actors.append(actor)
					
		# Remove condition from targets that left the aura
		for target in aura.current_targets:
			if not in_range_actors.has(target):
				if target.has_method(&"remove_condition"):
					target.remove_condition(aura.condition_id)
				print("    > [AURA] %s left aura, removed %s." % [target.entity_name, aura.condition_id])
					
		# Add condition to targets that entered the aura
		for target in in_range_actors:
			if not aura.current_targets.has(target):
				if target.has_method(&"apply_condition"):
					var cond = PFCondition.create(aura.condition_id)
					if cond: target.apply_condition(cond)
				print("    > [AURA] %s entered aura, applied %s." % [target.entity_name, aura.condition_id])
				
		aura.current_targets = in_range_actors

func _clear_aura_from_targets(aura: AuraInstance) -> void:
	for target in aura.current_targets:
		if target.has_method(&"remove_condition"):
			target.remove_condition(aura.condition_id)
	aura.current_targets.clear()
