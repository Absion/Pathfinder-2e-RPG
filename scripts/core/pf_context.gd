# pf_context.gd
## Base class for global game states (combat, exploration, menus).
class_name PFContext
extends Node

# Emitted when this context wants the GameRoot to transition to another context
signal request_context_change(context_name: String, args: Dictionary)

# Lifecycle methods
func build_services() -> void:
	pass

func bind_services() -> void:
	pass

func setup() -> void:
	pass

func enter_context(args: Dictionary = {}) -> void:
	pass

func exit_context() -> void:
	pass
