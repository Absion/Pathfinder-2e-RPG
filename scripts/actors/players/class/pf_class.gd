# pf_class.gd
## Defines the progression, proficiencies, and abilities gained as an actor levels up.
class_name PFClass
extends PFEntity

var hp_per_level: int
var key_abilities: Array[StringName]

var perception_rank: PFMathConstants.ProficiencyRank
var class_dc_rank: PFMathConstants.ProficiencyRank
var saving_throws: Dictionary # e.g. { "fort": PFMathConstants.ProficiencyRank.EXPERT, ... }
var trained_skills_count: int # 3 + INT modifier usually

# --- SPELLCASTING ---
var is_spellcaster: bool
var caster_type: PFMagicConstants.CasterType
var spell_tradition: PFMagicConstants.MagicTradition
var spell_proficiency: PFMathConstants.ProficiencyRank
var spell_progression: PFMagicConstants.SpellProgression

var weapon_proficiencies: Dictionary
var armor_proficiencies: Dictionary
var class_description: String

var forced_edicts: Array[StringName]
var forced_anathema: Array[StringName]

func _init(
		p_name: String = "", 
		p_hp: int = 8, 
		p_key_abilities: Array[StringName] = [],
		p_perception: PFMathConstants.ProficiencyRank = PFMathConstants.ProficiencyRank.TRAINED,
		p_class_dc: PFMathConstants.ProficiencyRank = PFMathConstants.ProficiencyRank.TRAINED,
		p_saves: Dictionary = {},
		p_skills_count: int = 3,
		p_weapons: Dictionary = {},
		p_armors: Dictionary = {},
		p_desc: String = "",
		p_forced_edicts: Array[StringName] = [],
		p_forced_anathema: Array[StringName] = [],
		p_is_spellcaster: bool = false,
		p_caster_type: PFMagicConstants.CasterType = PFMagicConstants.CasterType.NONE,
		p_spell_tradition: PFMagicConstants.MagicTradition = PFMagicConstants.MagicTradition.NONE,
		p_spell_proficiency: PFMathConstants.ProficiencyRank = PFMathConstants.ProficiencyRank.UNTRAINED,
		p_spell_progression: PFMagicConstants.SpellProgression = PFMagicConstants.SpellProgression.NONE,
		p_traits: Array[StringName] = [],
		p_rarity: PFBiographyConstants.Rarity = PFBiographyConstants.Rarity.COMMON
	):
	
	super._init(p_name, p_traits, p_rarity)
	
	hp_per_level = p_hp
	key_abilities = p_key_abilities
	perception_rank = p_perception
	class_dc_rank = p_class_dc
	saving_throws = p_saves
	trained_skills_count = p_skills_count
	weapon_proficiencies = p_weapons
	armor_proficiencies = p_armors
	class_description = p_desc
	forced_edicts = p_forced_edicts
	forced_anathema = p_forced_anathema
	is_spellcaster = p_is_spellcaster
	caster_type = p_caster_type
	spell_tradition = p_spell_tradition
	spell_proficiency = p_spell_proficiency
	spell_progression = p_spell_progression

