# pf_entity.gd
# Base class for anything in the game that needs traits (Actors, Items, Spells).
class_name PFEntity
extends RefCounted # We use RefCounted instead of Node because this is pure data. It saves memory and cleans itself up automatically.

var entity_name: String
# We use an Array of StringNames. In Godot, StringNames (&"text") are optimized 
# for ultra-fast comparisons, which is vital when checking traits thousands of times in combat.
var traits: Array[StringName] = []

# Constructor: Called when we create a new PFEntity using .new()
func _init(p_name: String, p_traits: Array[StringName] = []):
	entity_name = p_name
	traits = p_traits

# Checks if the entity has a specific trait (e.g., checking if a weapon has "agile")
func has_trait(trait_name: StringName) -> bool:
	return traits.has(trait_name)

# Adds a trait dynamically. We check if it already exists to avoid duplicates.
# Example use: A spell gives a character the "invisible" trait temporarily.
func add_trait(trait_name: StringName) -> void:
	if not has_trait(trait_name):
		traits.append(trait_name)

# Removes a trait dynamically.
# Example use: The "invisible" spell wears off.
func remove_trait(trait_name: StringName) -> void:
	if has_trait(trait_name):
		traits.erase(trait_name)
