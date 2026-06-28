# pf_condition_hidden.gd
class_name PFConditionHidden
extends PFCondition

func _init(p_id: StringName = &"hidden", p_initial_value: int = 1, p_source_dc: int = 0):
	super._init(p_id, p_initial_value, p_source_dc)
	condition_name = "Hidden"

func get_modifier(_context: StringName) -> int:
	# Hidden condition doesn't usually grant standard +/- modifiers, but rather a DC 11 flat check to target.
	# We'll return 0 for standard checks. The stealth system handles flat check mechanics.
	return 0
