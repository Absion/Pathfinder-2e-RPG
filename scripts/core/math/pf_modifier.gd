# pf_modifier.gd
# Represents a single buff or debuff applied to a stat.
## Represents a typed bonus or penalty (Circumstance, Status, Item).
class_name PFModifier
extends RefCounted

# The core of PF2e math. Bonuses of the same type do not stack!
var value: int
var type: PFMathConstants.ModifierType
# We store the source (e.g., "Raise Shield") so we can easily find and remove it later 
# when the effect ends, and to show the player where the math comes from in the UI.
var source: String 

# Constructor
func _init(p_value: int, p_type: PFMathConstants.ModifierType, p_source: String):
	value = p_value
	type = p_type
	source = p_source
