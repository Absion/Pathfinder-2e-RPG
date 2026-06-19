# pf_action_exploration.gd
## Action script for Exploration Activities. Updates the OverworldContext
## to track what the actor is currently doing outside of encounter mode.
class_name PFActionExploration
extends PFAction

var action_id: StringName

func _init(p_action_id: StringName):
	var db = PFDatabase.get_instance()
	var data = db.get_action_data(p_action_id) if db else {}
	
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
		var json = JSON.new()
		if json.parse(raw_traits) == OK:
			var arr = json.get_data()
			if typeof(arr) == TYPE_ARRAY:
				for t in arr: traits_array.append(StringName(t))
					
	super._init(action_name, traits_array, action_cost)
	action_id = p_action_id

func execute(user: PFActor, target: PFActor = null) -> bool:
	super.execute(user, target)
	
	var ml = Engine.get_main_loop()
	if ml and ml.root.has_node("PFGameRoot"):
		var root = ml.root.get_node("PFGameRoot") as PFGameRoot
		var context = root.current_context as PFOverworldContext
		if context:
			context.set_exploration_activity(user, action_id)
		else:
			print(" -> %s uses %s (Warning: Not in OverworldContext)" % [user.entity_name, entity_name])
	else:
		print(" -> %s uses %s (Warning: PFGameRoot not found)" % [user.entity_name, entity_name])

	return true
