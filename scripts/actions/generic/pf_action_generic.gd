# pf_action_generic.gd
## A generic fallback action for Basic Actions that don't have complex
## automated mechanics yet, or require GM arbitration (like 'Sense Motive' or 'Interact').
class_name PFActionGeneric
extends PFAction

var action_id: StringName

func _init(p_action_id: StringName):
	var database = PFDatabase.get_instance()
	var data = database.get_action_data(p_action_id) if database else {}
	
	var action_name = data.get(&"name", str(p_action_id))
	var cost_str = data.get(&"cost", "1")
	var action_cost = PFCombatConstants.ActionCost.ONE_ACTION
	if cost_str == "reaction": action_cost = PFCombatConstants.ActionCost.REACTION
	elif cost_str == "free": action_cost = PFCombatConstants.ActionCost.FREE
	elif cost_str == "2": action_cost = PFCombatConstants.ActionCost.TWO_ACTIONS
	elif cost_str == "3": action_cost = PFCombatConstants.ActionCost.THREE_ACTIONS
	
	var raw_traits = data.get(&"traits", "[]")
	var traits_array: Array[StringName] = []
	if raw_traits != "" and raw_traits != "[]":
		var arr = JSON.parse_string(raw_traits)
		if typeof(arr) == TYPE_ARRAY:
			for t in arr: traits_array.append(StringName(t))
					
	super._init(action_name, traits_array, action_cost)
	action_id = p_action_id

func execute(user: PFActor, target: Variant = null) -> bool:
	super.execute(user, target)
	
	var target_str = ""
	if target:
		target_str = " on %s" % target.entity_name
		
	# Simply log the action for now since it's generic
	print(" -> %s uses %s%s." % [user.entity_name, entity_name, target_str])
	return true

