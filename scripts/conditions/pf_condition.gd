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

# For conditions like Grabbed or Restrained that require an Escape check
var source_dc: int = 0

# Duration tracking (-1 means permanent until removed/cured)
var duration_turns: int = -1

func _init(p_id: StringName, p_initial_value: int = 1, p_source_dc: int = 0, p_duration: int = -1):
	condition_id = p_id
	var db_inst = PFDatabase.get_instance()
	var data: Dictionary = {}
	if db_inst:
		data = db_inst.get_condition_data(p_id, true)
	if data:
		condition_name = data.get(&"name", str(p_id))
		modifier_type = data.get(&"modifier_type", "")
		target_stat = data.get(&"target_stat", "")
		multiplier = data.get(&"multiplier", 0)
		strategy_script_path = data.get(&"script_path", "")
	else:
		condition_name = str(p_id)
		modifier_type = ""
		target_stat = ""
		multiplier = 0
		strategy_script_path = ""
		
	value = p_initial_value
	source_dc = p_source_dc
	duration_turns = p_duration

# NEW: Factory method for instantiating the correct condition subclass
static func create(p_id: StringName, p_initial_value: int = 1, p_source_dc: int = 0, p_duration: int = -1) -> PFCondition:
	var db_inst = PFDatabase.get_instance()
	var data: Dictionary = {}
	if db_inst:
		data = db_inst.get_condition_data(p_id, true)
		
		# If not found in conditions, check afflictions
		if data.is_empty():
			var affliction_data = db_inst.get_affliction_data(p_id)
			if not affliction_data.is_empty():
				return PFConditionAffliction.new(p_id, p_initial_value, p_source_dc)
				
	if data and data.get(&"script_path", "") != "":
		var script = load(data["script_path"])
		if script:
			# persistent damage is instantiated manually, but factory shouldn't crash
			if p_id == &"persistent_damage":
				pass 
			return script.new(p_id, p_initial_value, p_source_dc, p_duration)
	return PFCondition.new(p_id, p_initial_value, p_source_dc, p_duration)

# NEW: Called right before it is added to the actor. Return false to reject the condition.
func on_apply(_owner: PFActor) -> bool:
	return true

# NEW: Called when the condition is removed from the actor. Use this to remove linked sub-conditions.
func on_remove(_owner: PFActor) -> void:
	pass

func on_turn_start(_owner: PFActor) -> void:
	pass

func on_turn_end(_owner: PFActor) -> void:
	pass

func get_modifier(context: StringName) -> int:
	var context_string = str(context)
	# Check if this condition targets the given context
	if target_stat == context_string or target_stat == "all_checks_and_dcs" or (target_stat == "dex_based" and context_string in ["ac", "ref"]):
		return value * multiplier
	return 0

