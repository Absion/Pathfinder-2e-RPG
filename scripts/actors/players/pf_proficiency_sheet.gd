# pf_proficiency_sheet.gd
# A component attached to an actor that manages their specific proficiencies.
## Stores and calculates all proficiency ranks for a player's skills and saves.
class_name PFProficiencySheet
extends RefCounted

var skills: Dictionary = {}
var weapon_proficiencies: Dictionary = {}
var armor_proficiencies: Dictionary = {}

func _init():
	# Initialize Core Skills
	var db = PFDatabase.get_instance()
	if db:
		var core_skills = db.get_core_skills()
		for s in core_skills:
			skills[s] = PFMathConstants.ProficiencyRank.UNTRAINED
		
	# Default Weapon Proficiencies
	weapon_proficiencies[PFEquipmentConstants.WeaponCategory.UNARMED] = PFMathConstants.ProficiencyRank.UNTRAINED
	weapon_proficiencies[PFEquipmentConstants.WeaponCategory.SIMPLE] = PFMathConstants.ProficiencyRank.UNTRAINED
	weapon_proficiencies[PFEquipmentConstants.WeaponCategory.MARTIAL] = PFMathConstants.ProficiencyRank.UNTRAINED
	weapon_proficiencies[PFEquipmentConstants.WeaponCategory.ADVANCED] = PFMathConstants.ProficiencyRank.UNTRAINED
	
	# Default Armor Proficiencies
	armor_proficiencies[PFEquipmentConstants.ArmorCategory.UNARMORED] = PFMathConstants.ProficiencyRank.UNTRAINED
	armor_proficiencies[PFEquipmentConstants.ArmorCategory.LIGHT] = PFMathConstants.ProficiencyRank.UNTRAINED
	armor_proficiencies[PFEquipmentConstants.ArmorCategory.MEDIUM] = PFMathConstants.ProficiencyRank.UNTRAINED
	armor_proficiencies[PFEquipmentConstants.ArmorCategory.HEAVY] = PFMathConstants.ProficiencyRank.UNTRAINED

# ---------------------------------------------------------
# SETTERS
# ---------------------------------------------------------

func add_lore_skill(lore_name: StringName, rank: PFMathConstants.ProficiencyRank = PFMathConstants.ProficiencyRank.TRAINED) -> void:
	var db = PFDatabase.get_instance()
	var is_standard = false
	if db:
		var data = db.get_skill_data(lore_name)
		if not data.is_empty() and data.get("is_lore", 0) == 1:
			is_standard = true
			
	if is_standard or str(lore_name).to_lower().ends_with("lore"):
		skills[lore_name] = rank
	else:
		push_warning("Adding non-standard lore skill: " + lore_name)
		skills[lore_name] = rank

func set_skill_rank(skill: StringName, rank: PFMathConstants.ProficiencyRank) -> void:
	if skills.has(skill): 
		skills[skill] = rank
	elif str(skill).to_lower().ends_with("lore"):
		add_lore_skill(skill, rank)
	else: 
		push_error("Trying to set rank for invalid skill: " + skill)

func set_weapon_rank(category: PFEquipmentConstants.WeaponCategory, rank: PFMathConstants.ProficiencyRank) -> void:
	weapon_proficiencies[category] = rank

func set_armor_rank(category: PFEquipmentConstants.ArmorCategory, rank: PFMathConstants.ProficiencyRank) -> void:
	armor_proficiencies[category] = rank

# ---------------------------------------------------------
# MATH DELEGATES
# Passes the actor's stored rank to the global math utility.
# ---------------------------------------------------------

func get_skill_bonus(skill: StringName, actor_level: int) -> int:
	var rank = skills.get(skill, PFMathConstants.ProficiencyRank.UNTRAINED)
	return PFProficiency.calculate_bonus(rank, actor_level)

func get_weapon_bonus(category: PFEquipmentConstants.WeaponCategory, actor_level: int) -> int:
	var rank = weapon_proficiencies.get(category, PFMathConstants.ProficiencyRank.UNTRAINED)
	return PFProficiency.calculate_bonus(rank, actor_level)

func get_armor_bonus(category: PFEquipmentConstants.ArmorCategory, actor_level: int) -> int:
	var rank = armor_proficiencies.get(category, PFMathConstants.ProficiencyRank.UNTRAINED)
	return PFProficiency.calculate_bonus(rank, actor_level)
