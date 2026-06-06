# pf_component.gd
## Base class for modular actor components.
class_name PFComponent
extends Node

# Emitted when this component's core state changes (e.g. Health changing)
signal state_changed

func _ready():
	# Components often need to interact with their owner (the Actor)
	# But they should never blindly call get_parent() if they can avoid it.
	pass
