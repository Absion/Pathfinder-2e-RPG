# pf_action_component.gd
## Manages an actor's available actions and reactions during their turn.
class_name PFActionComponent
extends PFComponent

signal actions_changed(remaining: int)
signal reactions_changed(remaining: int)
signal attack_stacks_changed(stacks: int)

@export var actions_remaining: int = 0 :
	set(val):
		actions_remaining = clampi(val, 0, 3)
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
	actions_remaining = 3
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
