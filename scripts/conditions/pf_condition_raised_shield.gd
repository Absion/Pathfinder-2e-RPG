# pf_condition_raised_shield.gd
## Grants a circumstance bonus to AC while active.
class_name PFConditionRaisedShield
extends PFCondition

var shield: PFShield

func _init(p_shield: PFShield):
	super._init("Raised Shield", p_shield.ac_bonus)
	shield = p_shield

func get_modifier(context: StringName) -> int:
	if context == &"ac":
		return value # Adds the shield's AC bonus to the Actor!
	return 0

func on_turn_start(owner: PFActor) -> void:
	# PF2e Rule: Raising a shield expires at the start of your next turn.
	is_active = false 
	print("    > %s lowers their %s." % [owner.entity_name, shield.entity_name])
