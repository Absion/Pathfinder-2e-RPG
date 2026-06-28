# pf_overworld_context.gd
## Manages free-roam exploration outside of encounter mode.
class_name PFOverworldContext
extends PFContext

var active_exploration_activities: Dictionary = {}

func enter_context(_args: Dictionary = {}) -> void:
	print("Entering Overworld Context...")
	build_services()
	bind_services()
	setup()

func exit_context() -> void:
	print("Exiting Overworld Context...")
	active_exploration_activities.clear()
	for child in get_children():
		child.queue_free()

func set_exploration_activity(actor: PFActor, activity_id: StringName) -> void:
	active_exploration_activities[actor] = activity_id
	print("[Overworld] %s is now performing exploration activity: %s" % [actor.entity_name, activity_id])

func get_exploration_activity(actor: PFActor) -> StringName:
	return active_exploration_activities.get(actor, &"")
