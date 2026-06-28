# pf_combat_constants.gd
## System-wide static constants for combat logic and action economy.
class_name PFCombatConstants

enum ActionCost { NONE = 0, FREE = 1, REACTION = 2, ONE_ACTION = 3, TWO_ACTIONS = 4, THREE_ACTIONS = 5, ONE_ROUND = 6, TWO_ROUNDS = 7, ONE_MINUTE = 8, TEN_MINUTES = 9, ONE_HOUR = 10 }

enum DegreeOfSuccess { CRITICAL_FAILURE = 0, FAILURE = 1, SUCCESS = 2, CRITICAL_SUCCESS = 3, DETERMINED = 4, CRITICAL_SUCCESS_OR_SUCCESS = 5 }

class ReactionTriggers:
	const ON_LEAVE_SQUARE = &"on_leave_square"
	const BEFORE_TAKE_DAMAGE = &"before_take_damage"
	const ON_FALL = &"on_fall"
	const ON_ALLY_ACTION = &"on_ally_action"
	const ON_CAST_SPELL = &"on_cast_spell"
	const ON_MOVE = &"on_move"
	const ON_MANIPULATE = &"on_manipulate"
	const ON_RANGED_ATTACK = &"on_ranged_attack"

enum DamageType { 
	SLASHING, PIERCING, BLUDGEONING, 
	FIRE, COLD, ELECTRICITY, ACID, SONIC, 
	FORCE, VITALITY, VOID, 
	POISON, MENTAL, SPIRIT,
	BLEED, PRECISION, UNTYPED 
}

enum DetectionState {
	OBSERVED = 0,   # Normal vision, no penalties
	CONCEALED = 1,  # DC 5 flat check to target
	HIDDEN = 2,     # DC 11 flat check to target, observer knows grid square
	UNDETECTED = 3, # Observer must guess grid square, DC 11 flat check if correct
	UNNOTICED = 4   # Observer does not know target is present
}

enum CoverType {
	NONE = 0,
	LESSER = 1,     # +1 circumstance bonus to AC
	STANDARD = 2,   # +2 circumstance bonus to AC, Reflex, Stealth
	GREATER = 3     # +4 circumstance bonus to AC, Reflex, Stealth
}
