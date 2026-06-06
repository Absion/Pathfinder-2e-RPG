# pf_damage.gd
# A global utility class defining damage types for the entire engine.
class_name PFDamage
extends RefCounted

# Helper function to easily print the name of the damage type in the combat log
static func get_type_name(type: PFCombatConstants.DamageType) -> String:
	return PFCombatConstants.DamageType.keys()[type].capitalize()
