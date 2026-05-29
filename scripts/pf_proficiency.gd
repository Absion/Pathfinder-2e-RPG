# pf_proficiency.gd
# Global utility for Pathfinder 2e's proficiency math and skill mapping.
class_name PFProficiency
extends RefCounted

enum Rank { UNTRAINED = 0, TRAINED = 2, EXPERT = 4, MASTER = 6, LEGENDARY = 8 }

# The core PF2e math: Rank + Level (unless Untrained)
static func calculate_bonus(rank: Rank, level: int) -> int:
	if rank == Rank.UNTRAINED:
		return 0
	return rank + level

# Helper to automatically know which stat to use for a skill check
static func get_skill_ability(skill: StringName) -> StringName:
	match skill:
		&"athletics": return &"STR"
		&"acrobatics", &"stealth", &"thievery": return &"DEX"
		&"arcana", &"crafting", &"lore", &"occultism", &"society": return &"INT"
		&"medicine", &"nature", &"religion", &"survival": return &"WIS"
		&"deception", &"diplomacy", &"intimidation", &"performance": return &"CHA"
		_:
			push_error("Unknown skill requested: " + skill)
			return &"STR"
