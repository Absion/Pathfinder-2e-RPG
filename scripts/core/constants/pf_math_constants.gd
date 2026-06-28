# pf_math_constants.gd
## System-wide constants for proficiencies, distances, and core math.
class_name PFMathConstants

enum Distance { TOUCH = 0, MELEE = 5, REACH = 10, CLOSE = 30, MEDIUM = 60, LONG = 120, EXTREME = 500 }
enum DegreeOfSuccess { CRIT_FAIL = 0, FAIL = 1, SUCCESS = 2, CRIT_SUCCESS = 3 }
enum ModifierType { UNTYPED, CIRCUMSTANCE, STATUS, ITEM }
enum ProficiencyRank { UNTRAINED = 0, TRAINED = 2, EXPERT = 4, MASTER = 6, LEGENDARY = 8 }
