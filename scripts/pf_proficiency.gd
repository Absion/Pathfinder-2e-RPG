# pf_proficiency.gd
class_name PFProficiency
extends RefCounted

# The exact mathematical values for PF2e Proficiency Ranks
enum Rank { UNTRAINED = 0, TRAINED = 2, EXPERT = 4, MASTER = 6, LEGENDARY = 8 }

# The core PF2e proficiency formula: Rank + Level (If you are at least Trained)
static func calculate_bonus(rank: Rank, level: int) -> int:
	if rank == Rank.UNTRAINED:
		return 0
	return level + int(rank)

# Maps every specific skill to its governing attribute
static func get_skill_ability(skill: StringName) -> StringName:
	var skill_lower = str(skill).to_lower()

	# Pattern match the 17 Core PF2e Skills
	match skill_lower:
		# Strength
		"athletics": 
			return &"STR"
			
		# Dexterity
		"acrobatics", "stealth", "thievery": 
			return &"DEX"
			
		# Intelligence
		"arcana", "crafting", "occultism", "society": 
			return &"INT"
			
		# Wisdom
		"medicine", "nature", "religion", "survival": 
			return &"WIS"
			
		# Charisma
		"deception", "diplomacy", "intimidation", "performance": 
			return &"CHA"
			
		_:
			push_warning("Unknown skill '%s'. Defaulting to INT." % skill)
			return &"INT"
