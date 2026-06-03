# pf_class.gd
class_name PFClass
extends PFEntity

var hp_per_level: int
var key_abilities: Array[StringName]

var perception_rank: PFProficiency.Rank
var class_dc_rank: PFProficiency.Rank
var saving_throws: Dictionary # e.g. { "fort": PFProficiency.Rank.EXPERT, ... }
var trained_skills_count: int # 3 + INT mod usually

# --- SPELLCASTING ---
var is_spellcaster: bool
var caster_type: PFEntity.CasterType
var spell_tradition: PFEntity.MagicTradition
var spell_proficiency: PFProficiency.Rank
var spell_progression: PFEntity.SpellProgression

var weapon_proficiencies: Dictionary
var armor_proficiencies: Dictionary
var class_description: String

var forced_edicts: Array[String]
var forced_anathema: Array[String]

func _init(
		p_name: String = "", 
		p_hp: int = 8, 
		p_key_abilities: Array[StringName] = [],
		p_perception: PFProficiency.Rank = PFProficiency.Rank.TRAINED,
		p_class_dc: PFProficiency.Rank = PFProficiency.Rank.TRAINED,
		p_saves: Dictionary = {},
		p_skills_count: int = 3,
		p_weapons: Dictionary = {},
		p_armors: Dictionary = {},
		p_desc: String = "",
		p_forced_edicts: Array[String] = [],
		p_forced_anathema: Array[String] = [],
		p_is_spellcaster: bool = false,
		p_caster_type: PFEntity.CasterType = PFEntity.CasterType.NONE,
		p_spell_tradition: PFEntity.MagicTradition = PFEntity.MagicTradition.NONE,
		p_spell_proficiency: PFProficiency.Rank = PFProficiency.Rank.UNTRAINED,
		p_spell_progression: PFEntity.SpellProgression = PFEntity.SpellProgression.NONE,
		p_traits: Array[StringName] = [],
		p_rarity: PFEntity.Rarity = PFEntity.Rarity.COMMON
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
