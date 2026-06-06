# pf_proficiency.gd
## Helper class representing a proficiency rank from Untrained to Legendary.
class_name PFProficiency
extends RefCounted

# The exact mathematical values for PF2e Proficiency Ranks
# The core PF2e proficiency formula: PFMathConstants.ProficiencyRank + Level (If you are at least Trained)
static func calculate_bonus(rank: PFMathConstants.ProficiencyRank, level: int) -> int:
	if rank == PFMathConstants.ProficiencyRank.UNTRAINED:
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
			if skill_lower.ends_with("lore"):
				return &"INT"
			push_warning("Unknown skill '%s'. Defaulting to INT." % skill)
			return &"INT"
