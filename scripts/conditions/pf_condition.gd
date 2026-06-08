# pf_condition.gd
## An active effect or status applied to an actor.
class_name PFCondition
extends RefCounted

var condition_name: String
var value: int
var is_active: bool = true

# Data-Driven Modifier Matrix
var modifier_type: String
var target_stat: String
var multiplier: int
var strategy_script_path: String

func _init(p_id: StringName, p_initial_value: int = 1):
	var db_inst = PFDatabase.get_instance()
	var data = db_inst.get_condition_data(p_id) if db_inst else null
	if data:
		condition_name = data.get("name", str(p_id))
		modifier_type = data.get("modifier_type", "")
		target_stat = data.get("target_stat", "")
		multiplier = data.get("multiplier", 0)
		strategy_script_path = data.get("script_path", "")
	else:
		condition_name = str(p_id)
		modifier_type = ""
		target_stat = ""
		multiplier = 0
		strategy_script_path = ""
		
	value = p_initial_value

# NEW: Called right before it is added to the actor. Return false to reject the condition.
func on_apply(owner: PFActor) -> bool:
	if strategy_script_path != "":
		# Strategy Pattern: Load complex behavior script if provided
		var script = load(strategy_script_path)
		if script:
			var instance = script.new()
			# Ideally we append it to the owner, but for now we just let it attach
			# This implies the script might be a Node or just an object that wires signals
			if instance is Node:
				owner.add_child(instance)
	return true

func on_turn_start(owner: PFActor) -> void:
	pass

func on_turn_end(owner: PFActor) -> void:
	pass

func get_modifier(context: StringName) -> int:
	var ctx = str(context)
	# Check if this condition targets the given context
	if target_stat == ctx or target_stat == "all_checks_and_dcs" or (target_stat == "dex_based" and ctx in ["ac", "ref"]):
		return value * multiplier
	return 0
