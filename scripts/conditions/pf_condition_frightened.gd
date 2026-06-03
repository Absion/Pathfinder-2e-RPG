# pf_condition_frightened.gd
class_name PFConditionFrightened
extends PFCondition

func _init(p_initial_value: int):
	super._init("Frightened", p_initial_value)

# Frightened decreases by 1 at the end of your turn!
func on_turn_end(owner: PFActor) -> void:
	value -= 1
	if value <= 0:
		is_active = false
		print("    > %s is no longer Frightened." % owner.entity_name)
	else:
		print("    > %s's Frightened condition reduces to %d." % [owner.entity_name, value])

# Frightened applies its penalty to literally everything.
func get_modifier(context: StringName) -> int:
	# In a full PF2e implementation, you'd check context to ensure it only applies 
	# to checks and DCs, but Frightened touches almost all standard rolls!
	return -value
