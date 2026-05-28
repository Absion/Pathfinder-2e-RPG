# pf_damage.gd
# A global utility class defining damage types for the entire engine.
class_name PFDamage
extends RefCounted

# Strict Enum using Pathfinder 2e Remaster terminology.
enum Type {
	UNTYPED,
	BLUDGEONING, PIERCING, SLASHING,
	FIRE, COLD, ELECTRICITY, ACID, SONIC,
	VITALITY, VOID, FORCE, MENTAL, POISON, BLEED, PRECISION, SPIRIT
}

# Helper function to easily print the name of the damage type in the combat log
static func get_type_name(type: Type) -> String:
	return PFDamage.Type.keys()[type].capitalize()
