# pf_overworld_context.gd
## Manages free-roam exploration outside of encounter mode.
class_name PFOverworldContext
extends PFContext

func enter_context(args: Dictionary = {}) -> void:
	print("Entering Overworld Context...")
	build_services()
	bind_services()
	setup()

func exit_context() -> void:
	print("Exiting Overworld Context...")
	for child in get_children():
		child.queue_free()
