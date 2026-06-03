# pf_condition.gd
class_name PFCondition
extends RefCounted

var condition_name: String
var value: int
var is_active: bool = true

func _init(p_name: String, p_initial_value: int = 1):
	condition_name = p_name
	value = p_initial_value

# NEW: Called right before it is added to the actor. Return false to reject the condition.
func on_apply(owner: PFActor) -> bool:
	return true

func on_turn_start(owner: PFActor) -> void:
	pass

func on_turn_end(owner: PFActor) -> void:
	pass

func get_modifier(context: StringName) -> int:
	return 0
