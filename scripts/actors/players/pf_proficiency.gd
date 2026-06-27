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
	var database = PFDatabase.get_instance()
	if database:
		var data = database.get_skill_data(skill)
		if not data.is_empty() and data.has(&"key_ability"):
			return StringName(data["key_ability"])
			
	# Fallback for dynamic Lores not explicitly in DB
	if str(skill).to_lower().ends_with("lore"):
		return &"INT"
		
	push_warning("Unknown skill '%s'. Defaulting to INT." % skill)
	return &"INT"

