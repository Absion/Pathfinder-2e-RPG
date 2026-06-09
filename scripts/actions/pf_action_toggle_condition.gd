# pf_action_toggle_condition.gd
## A generic action script for actions that simply add or remove a condition.
class_name PFActionToggleCondition
extends PFAction

var action_id: StringName

func _init(p_action_id: StringName):
	var db = PFDatabase.get_instance()
	var data = db.get_action_data(p_action_id) if db else {}
	
	var action_name = data.get("name", str(p_action_id))
	var cost_str = data.get("cost", "1")
	var action_cost = PFCombatConstants.ActionCost.ONE_ACTION
	if cost_str == "reaction": action_cost = PFCombatConstants.ActionCost.REACTION
	elif cost_str == "free": action_cost = PFCombatConstants.ActionCost.FREE
	elif cost_str == "2": action_cost = PFCombatConstants.ActionCost.TWO_ACTIONS
	elif cost_str == "3": action_cost = PFCombatConstants.ActionCost.THREE_ACTIONS
	
	var raw_traits = data.get("traits", "[]")
	var traits_array: Array[StringName] = []
	
	# The traits come out as a JSON string like '["move"]'
	if raw_traits != "" and raw_traits != "[]":
		var json = JSON.new()
		var parse_result = json.parse(raw_traits)
		if parse_result == OK:
			var arr = json.get_data()
			if typeof(arr) == TYPE_ARRAY:
				for t in arr:
					traits_array.append(StringName(t))
					
	super._init(action_name, traits_array, action_cost)
	action_id = p_action_id

func execute(user: PFActor, target: PFActor = null) -> bool:
	super.execute(user, target)
	
	match action_id:
		&"drop_prone":
			var cond = PFCondition.create(&"prone")
			user.apply_condition(cond)
			print(" -> %s gains the Prone condition." % user.entity_name)
		&"stand":
			if user.has_condition("prone"):
				user.remove_condition("prone")
				print(" -> %s is no longer Prone." % user.entity_name)
			else:
				print(" -> %s is already standing." % user.entity_name)
		&"take_cover":
			var cond = PFCondition.create(&"cover")
			user.apply_condition(cond)
			print(" -> %s gains the Cover condition." % user.entity_name)
			
	return true
