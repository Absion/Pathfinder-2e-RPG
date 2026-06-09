# pf_condition.gd
## An active effect or status applied to an actor.
class_name PFCondition
extends RefCounted

var condition_id: StringName
var condition_name: String
var value: int
var is_active: bool = true

# Data-Driven Modifier Matrix
var modifier_type: String
var target_stat: String
var multiplier: int
var strategy_script_path: String

func _init(p_id: StringName, p_initial_value: int = 1):
	condition_id = p_id
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

# NEW: Factory method for instantiating the correct condition subclass
static func create(p_id: StringName, p_initial_value: int = 1) -> PFCondition:
	var db_inst = PFDatabase.get_instance()
	var data = db_inst.get_condition_data(p_id) if db_inst else null
	if data and data.get("script_path", "") != "":
		var script = load(data["script_path"])
		if script:
			return script.new(p_id, p_initial_value)
	return PFCondition.new(p_id, p_initial_value)

# NEW: Called right before it is added to the actor. Return false to reject the condition.
func on_apply(owner: PFActor) -> bool:
	return true

# NEW: Called when the condition is removed from the actor. Use this to remove linked sub-conditions.
func on_remove(owner: PFActor) -> void:
	pass

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
