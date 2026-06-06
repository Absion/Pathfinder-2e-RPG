# pf_proficiency_sheet.gd
# A component attached to an actor that manages their specific proficiencies.
## Stores and calculates all proficiency ranks for a player's skills and saves.
class_name PFProficiencySheet
extends RefCounted

var level: int
var skills: Dictionary = {}
var weapon_proficiencies: Dictionary = {}
var armor_proficiencies: Dictionary = {}

const STANDARD_LORES: Array[StringName] = [
	&"Academia Lore", &"Accounting Lore", &"Architecture Lore", &"Art Lore", 
	&"Circus Lore", &"Engineering Lore", &"Farming Lore", &"Fishing Lore", 
	&"Fortune-Telling Lore", &"Games Lore", &"Genealogy Lore", &"Gladiatorial Lore", 
	&"Guild Lore", &"Heraldry Lore", &"Herbalism Lore", &"Hunting Lore", 
	&"Labor Lore", &"Legal Lore", &"Library Lore", &"Mercantile Lore", 
	&"Midwifery Lore", &"Milling Lore", &"Mining Lore", &"Piloting Lore", 
	&"Sailing Lore", &"Scouting Lore", &"Scribing Lore", &"Stabling Lore", 
	&"Tanning Lore", &"Theater Lore", &"Underworld Lore"
]

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
	if lore_name in STANDARD_LORES or str(lore_name).to_lower().ends_with("lore"):
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

func get_weapon_bonus(category: PFEquipmentConstants.WeaponCategory) -> int:
	var rank = weapon_proficiencies.get(category, PFMathConstants.ProficiencyRank.UNTRAINED)
	return PFProficiency.calculate_bonus(rank, level)

func get_armor_bonus(category: PFEquipmentConstants.ArmorCategory) -> int:
	var rank = armor_proficiencies.get(category, PFMathConstants.ProficiencyRank.UNTRAINED)
	return PFProficiency.calculate_bonus(rank, level)
