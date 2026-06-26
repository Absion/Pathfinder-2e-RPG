# pf_condition_raised_shield.gd
## Grants a circumstance bonus to AC while active.
class_name PFConditionRaisedShield
extends PFCondition

var shield: PFShield

func _init(p_shield: PFShield):
	super._init(&"raised_shield", p_shield.ac_bonus)
	shield = p_shield

func get_modifier(context: StringName) -> int:
	if context == &"ac":
		return value # Adds the shield's AC bonus to the Actor!
	return 0

func on_apply(owner: PFActor) -> bool:
	if PFContext.reaction_manager:
		# Bind the static callbacks using Callable

		# Since condition and execute expect (trigger_actor, event_data), and bind appends arguments to the end,
		# wait, bind appends. So the static function signature should be (trigger_actor, event_data, listener).
		# Let's use lambda functions for cleaner closure over `owner`.
		
		var cond_lambda = func(trigger_actor: PFActor, event_data: Dictionary) -> bool:
			return PFReactionShieldBlock.condition(trigger_actor, event_data, owner)
			
		var exec_lambda = func(trigger_actor: PFActor, event_data: Dictionary) -> Dictionary:
			return PFReactionShieldBlock.execute(trigger_actor, event_data, owner)
			
		PFContext.reaction_manager.register_listener(PFCombatConstants.ReactionTriggers.BEFORE_TAKE_DAMAGE, owner, &"Shield Block", cond_lambda, exec_lambda)
	return true

func on_remove(owner: PFActor) -> void:
	if PFContext.reaction_manager:
		PFContext.reaction_manager.unregister_listener(owner, &"Shield Block")

func on_turn_start(owner: PFActor) -> void:
	# PF2e Rule: Raising a shield expires at the start of your next turn.
	is_active = false 
	print("    > %s lowers their %s." % [owner.entity_name, shield.entity_name])
