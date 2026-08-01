# pf_reaction_manager.gd
## Manages global reaction triggers and asynchronous UI prompting for reactions.
class_name PFReactionManager
extends Node

## Emitted when the engine needs to pause and ask a player if they want to use a reaction.
signal reaction_prompted(listener: PFActor, trigger_actor: PFActor, reaction_id: StringName, event_data: Dictionary)

## Emitted by the UI to resolve the pending reaction.
signal reaction_resolved(use_reaction: bool)

## Set to true during unit tests to automatically approve/resolve reactions without pausing.
var auto_resolve_prompts: bool = false

class ReactionRegistration extends RefCounted:
	var listener: PFActor
	var reaction_id: StringName
	var condition_callback: Callable
	var execute_callback: Callable
	
	func _init(p_listener: PFActor, p_id: StringName, p_cond: Callable, p_exec: Callable):
		listener = p_listener
		reaction_id = p_id
		condition_callback = p_cond
		execute_callback = p_exec

# Dictionary mapping trigger types (StringName) to an Array of ReactionRegistration
var active_triggers: Dictionary = {}

func register_listener(trigger_type: StringName, listener: PFActor, reaction_id: StringName, condition_callback: Callable, execute_callback: Callable) -> void:
	if not active_triggers.has(trigger_type):
		active_triggers[trigger_type] = []
		
	# Ensure no duplicate registrations for the exact same reaction
	for r in active_triggers[trigger_type]:
		if r.listener == listener and r.reaction_id == reaction_id:
			return
			
	active_triggers[trigger_type].append(ReactionRegistration.new(listener, reaction_id, condition_callback, execute_callback))

func unregister_listener(listener: PFActor, reaction_id: StringName = &"") -> void:
	# ⚡ Bolt: Iterate dictionary directly instead of using .keys() to avoid GC array allocation
	for trigger in active_triggers:
		var arr = active_triggers[trigger]
		for i in range(arr.size() - 1, -1, -1):
			var r = arr[i]
			if r.listener == listener and (reaction_id == &"" or r.reaction_id == reaction_id):
				arr.remove_at(i)

## Notifies all listeners of a specific event. Pauses execution if a player prompt is required.
## Returns the potentially modified event_data dictionary.
func notify_event(trigger_type: StringName, trigger_actor: PFActor, event_data: Dictionary) -> Dictionary:
	if not active_triggers.has(trigger_type):
		return event_data
		
	var listeners = active_triggers[trigger_type]
	
	for reg in listeners:
		# Check if the actor is alive and has a reaction to spend
		if not is_instance_valid(reg.listener) or reg.listener.action_economy.reactions_remaining <= 0:
			continue
			
		# Check the specific condition (e.g. is trigger_actor within reach?)
		if not reg.condition_callback.call(trigger_actor, event_data):
			continue
			
		# Conditions met! We must decide if we use it.
		var will_use = false
		
		# If AI, standard logic applies (always use for now, or roll chance)
		if auto_resolve_prompts or reg.listener.get_meta(&"is_ai", false) or reg.listener is PFNpc:
			will_use = true
		else:
			# If Player, pause and prompt UI
			print("--- [PAUSE] Prompting %s for Reaction: %s ---" % [reg.listener.entity_name, reg.reaction_id])
			reaction_prompted.emit(reg.listener, trigger_actor, reg.reaction_id, event_data)
			
			# Wait for UI to respond. The return value of the signal is passed as an Array.
			var result = await self.reaction_resolved
			will_use = result[0] if result is Array else result
			
		if will_use:
			print("--- [REACTION] %s uses %s! ---" % [reg.listener.entity_name, reg.reaction_id])
			reg.listener.action_economy.consume_reaction()
			event_data = await reg.execute_callback.call(trigger_actor, event_data)
			
	return event_data
