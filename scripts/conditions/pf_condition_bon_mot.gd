# pf_condition_bon_mot.gd
class_name PFConditionBonMot
extends PFCondition

func _init(p_id: StringName = &"bon_mot", p_initial_value: int = 2, p_source_dc: int = 0):
	super._init(p_id, p_initial_value, p_source_dc)
	condition_name = "Bon Mot Penalty"
	modifier_type = "status"

func get_modifier(context: StringName) -> int:
	var ctx = str(context)
	# Bon Mot applies a status penalty to Perception and Will saves
	if ctx == "perception" or ctx == "will":
		return -value
	return 0
