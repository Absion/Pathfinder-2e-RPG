# pf_action_component.gd
## Manages an actor's available actions and reactions during their turn.
class_name PFActionComponent
extends PFComponent

signal actions_changed(remaining: int)
signal reactions_changed(remaining: int)
signal attack_stacks_changed(stacks: int)

@export var actions_remaining: int = 0 :
	set(val):
		actions_remaining = clampi(val, 0, 4)
		actions_changed.emit(actions_remaining)

@export var reactions_remaining: int = 1 :
	set(val):
		reactions_remaining = max(val, 0)
		reactions_changed.emit(reactions_remaining)

@export var attack_stacks: int = 0 :
	set(val):
		attack_stacks = max(val, 0)
		attack_stacks_changed.emit(attack_stacks)

func start_turn():
	var new_actions = 3
	var parent = get_parent()
	
	if parent and parent is PFActor:
		# Quickened adds an action
		if parent.has_condition("quickened"):
			new_actions += 1
			
		# Stunned overrides Slowed
		var stunned = parent.get_condition("stunned")
		var slowed = parent.get_condition("slowed")
		
		var actions_lost = 0
		
		var stunned_val = 0
		if stunned:
			stunned_val = stunned.value
			stunned.value -= new_actions
			if stunned.value <= 0:
				parent.remove_condition("stunned")
				
		var slowed_val = slowed.value if slowed else 0
		
		# Stunned overrides Slowed, but you lose whichever is higher
		actions_lost = maxi(stunned_val, slowed_val)
			
		new_actions -= actions_lost
			
	actions_remaining = max(new_actions, 0)
	reactions_remaining = 1
	attack_stacks = 0

func consume_actions(amount: int) -> bool:
	if actions_remaining >= amount:
		actions_remaining -= amount
		return true
	return false

func consume_reaction() -> bool:
	if reactions_remaining > 0:
		reactions_remaining -= 1
		return true
	return false

func increment_attack():
	attack_stacks += 1
