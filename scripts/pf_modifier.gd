# pf_modifier.gd
# Represents a single buff or debuff applied to a stat.
class_name PFModifier
extends RefCounted

# The core of PF2e math. Bonuses of the same type do not stack!
enum Type { UNTYPED, CIRCUMSTANCE, STATUS, ITEM }

var value: int
var type: Type
# We store the source (e.g., "Raise Shield") so we can easily find and remove it later 
# when the effect ends, and to show the player where the math comes from in the UI.
var source: String 

# Constructor
func _init(p_value: int, p_type: Type, p_source: String):
	value = p_value
	type = p_type
	source = p_source
