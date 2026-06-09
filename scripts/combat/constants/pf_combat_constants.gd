# pf_combat_constants.gd
## System-wide static constants for combat logic and action economy.
class_name PFCombatConstants

enum ActionCost { NONE = 0, FREE = 1, REACTION = 2, ONE_ACTION = 3, TWO_ACTIONS = 4, THREE_ACTIONS = 5, ONE_ROUND = 6, TWO_ROUNDS = 7, ONE_MINUTE = 8, TEN_MINUTES = 9, ONE_HOUR = 10 }

enum DegreeOfSuccess { CRITICAL_FAILURE = 0, FAILURE = 1, SUCCESS = 2, CRITICAL_SUCCESS = 3 }
enum DamageType { 
	SLASHING, PIERCING, BLUDGEONING, 
	FIRE, COLD, ELECTRICITY, ACID, SONIC, 
	FORCE, VITALITY, VOID, 
	POISON, MENTAL, SPIRIT,
	BLEED, PRECISION, UNTYPED 
}
