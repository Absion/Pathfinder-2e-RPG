# pf_proficiency_sheet.gd
# A component attached to an actor that manages their specific proficiencies.
class_name PFProficiencySheet
extends RefCounted

var level: int
var skills: Dictionary = {}
var weapon_proficiencies: Dictionary = {}
var armor_proficiencies: Dictionary = {}

func _init(p_level: int):
	level = p_level
	
	# Default Skills (17 Core PF2e Skills)
	var all_skills = [
		&"acrobatics", &"arcana", &"athletics", &"crafting", 
		&"deception", &"diplomacy", &"intimidation", &"medicine", 
		&"nature", &"occultism", &"perception", &"performance", 
		&"religion", &"society", &"stealth", &"survival", &"thievery"
	]
	
	for s in all_skills:
		skills[s] = PFProficiency.Rank.UNTRAINED
		
	# Default Weapon Proficiencies
	weapon_proficiencies[PFWeapon.Category.UNARMED] = PFProficiency.Rank.UNTRAINED
	weapon_proficiencies[PFWeapon.Category.SIMPLE] = PFProficiency.Rank.UNTRAINED
	weapon_proficiencies[PFWeapon.Category.MARTIAL] = PFProficiency.Rank.UNTRAINED
	weapon_proficiencies[PFWeapon.Category.ADVANCED] = PFProficiency.Rank.UNTRAINED
	
	# Default Armor Proficiencies
	armor_proficiencies[PFArmor.Category.UNARMORED] = PFProficiency.Rank.UNTRAINED
	armor_proficiencies[PFArmor.Category.LIGHT] = PFProficiency.Rank.UNTRAINED
	armor_proficiencies[PFArmor.Category.MEDIUM] = PFProficiency.Rank.UNTRAINED
	armor_proficiencies[PFArmor.Category.HEAVY] = PFProficiency.Rank.UNTRAINED

# ---------------------------------------------------------
# SETTERS
# ---------------------------------------------------------

func set_skill_rank(skill: StringName, rank: PFProficiency.Rank) -> void:
	if skills.has(skill): 
		skills[skill] = rank
	else: 
		push_error("Trying to set rank for invalid skill: " + skill)

func set_weapon_rank(category: PFWeapon.Category, rank: PFProficiency.Rank) -> void:
	weapon_proficiencies[category] = rank

func set_armor_rank(category: PFArmor.Category, rank: PFProficiency.Rank) -> void:
	armor_proficiencies[category] = rank

# ---------------------------------------------------------
# MATH DELEGATES
# Passes the actor's stored rank to the global math utility.
# ---------------------------------------------------------

func get_weapon_bonus(category: PFWeapon.Category) -> int:
	var rank = weapon_proficiencies.get(category, PFProficiency.Rank.UNTRAINED)
	return PFProficiency.calculate_bonus(rank, level)

func get_armor_bonus(category: PFArmor.Category) -> int:
	var rank = armor_proficiencies.get(category, PFProficiency.Rank.UNTRAINED)
	return PFProficiency.calculate_bonus(rank, level)
