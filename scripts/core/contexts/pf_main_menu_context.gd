# pf_main_menu_context.gd
## Handles the start screen and save data loading.
class_name PFMainMenuContext
extends PFContext

func enter_context(_args: Dictionary = {}) -> void:
	print("Entering Main Menu Context...")
	build_services()
	bind_services()
	setup()

func exit_context() -> void:
	print("Exiting Main Menu Context...")
	for child in get_children():
		child.queue_free()
