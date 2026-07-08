# pf_ancestry.gd
## Represents an actor's biological heritage and innate traits.
class_name PFAncestry
extends PFEntity

const VALID_ABILITIES: Array[StringName] = [&"STR", &"DEX", &"CON", &"INT", &"WIS", &"CHA", &"FREE"]

var hp: int
var size_id: StringName

# --- MOVEMENT SPEEDS ---
var speed: int
var speed_fly: int
var speed_swim: int
var speed_climb: int
var speed_burrow: int

# --- ABILITIES & LANGUAGES ---
var ability_boosts: Array[StringName]
var ability_flaws: Array[StringName]
var alternate_ancestry_boosts: Array[StringName] = [&"FREE", &"FREE"]

var known_languages: Array[StringName]
var bonus_language_options: Array[StringName]

# --- SENSES ---
var vision: PFBiographyConstants.Vision
var additional_senses: Array[PFSense]

# --- SUB-SELECTIONS ---
var ethnicities: Array[String]
var heritages: Array[String]

# --- LORE & FLAVOR ---
var ancestry_description: String
var physical_description: String
var societal_description: String
var common_beliefs: String
var common_edicts: Array[StringName]
var common_anathema: Array[StringName]
var common_names: Array[String]

# --- STARTING ASSETS ---
# Holds PFAction or passive abilities (e.g., Kashrishi Horn unarmed attack)
var granted_abilities: Array[PFEntity] 
# Holds physical starting items (e.g., Dwarven Dagger)
var granted_items: Array[PFItem]
var starting_gold: int

func _init(
		p_name: String = "", 
		p_hp: int = 8, 
		p_size_id: StringName = &"medium", 
		p_speed: int = 25, 
		p_boosts: Array[StringName] = [], 
		p_flaws: Array[StringName] = [], 
		p_known_langs: Array[StringName] = [], 
		p_bonus_langs: Array[StringName] = [], 
		p_vision: PFBiographyConstants.Vision = PFBiographyConstants.Vision.NORMAL,
		p_additional_senses: Array[PFSense] = [],
		p_speed_fly: int = 0,   
		p_speed_swim: int = 0,  
		p_speed_climb: int = 0, 
		p_speed_burrow: int = 0,
		p_ethnicities: Array[String] = [],
		p_heritages: Array[String] = [],
		p_ancestry_description: String = "",
		p_physical_description: String = "",
		p_societal_description: String = "",
		p_common_beliefs: String = "",
		p_common_edicts: Array[StringName] = [],
		p_common_anathema: Array[StringName] = [],
		p_common_names: Array[String] = [],
		p_traits: Array[StringName] = [], 
		p_rarity: PFBiographyConstants.Rarity = PFBiographyConstants.Rarity.COMMON,
		p_granted_abilities: Array[PFEntity] = [], 
		p_granted_items: Array[PFItem] = [],
		p_starting_gold: int = 15
	):
	
	super._init(p_name, p_traits, p_rarity)
	
	_validate_abilities(p_boosts, "ability_boosts")
	_validate_abilities(p_flaws, "ability_flaws")
	
	hp = p_hp
	size_id = p_size_id
	speed = p_speed
	speed_fly = p_speed_fly
	speed_swim = p_speed_swim
	speed_climb = p_speed_climb
	speed_burrow = p_speed_burrow
	ability_boosts = p_boosts
	ability_flaws = p_flaws
	known_languages = p_known_langs
	bonus_language_options = p_bonus_langs
	vision = p_vision
	additional_senses = p_additional_senses
	ethnicities = p_ethnicities
	heritages = p_heritages
	
	ancestry_description = p_ancestry_description
	physical_description = p_physical_description
	societal_description = p_societal_description
	common_beliefs = p_common_beliefs
	
	for e in p_common_edicts:
		if not PFBeliefs.is_valid_edict(e):
			push_error("PFAncestry Error: Invalid edict '%s' in %s" % [e, p_name])
	common_edicts = p_common_edicts
	
	for a in p_common_anathema:
		if not PFBeliefs.is_valid_anathema(a):
			push_error("PFAncestry Error: Invalid anathema '%s' in %s" % [a, p_name])
	common_anathema = p_common_anathema
	
	common_names = p_common_names
	granted_abilities = p_granted_abilities
	granted_items = p_granted_items
	starting_gold = p_starting_gold # Assign it here!

# --- DATA SETTERS ---

# Helper function to assign massive blocks of text cleanly after initialization
func set_lore(p_ancestry_desc: String, p_physical_desc: String, p_societal_desc: String, p_beliefs: String, p_edicts: Array[StringName], p_anathema: Array[StringName], p_names: Array[String]) -> void:
	ancestry_description = p_ancestry_desc
	physical_description = p_physical_desc
	societal_description = p_societal_desc
	common_beliefs = p_beliefs
	
	for e in p_edicts:
		if not PFBeliefs.is_valid_edict(e):
			push_error("PFAncestry Error: Invalid edict '%s' in set_lore for %s" % [e, entity_name])
	common_edicts = p_edicts
	
	for a in p_anathema:
		if not PFBeliefs.is_valid_anathema(a):
			push_error("PFAncestry Error: Invalid anathema '%s' in set_lore for %s" % [a, entity_name])
	common_anathema = p_anathema
	
	common_names = p_names

# --- DATA VALIDATION ---

func _validate_abilities(abilities: Array[StringName], context: String) -> void:
	for ability in abilities:
		if not VALID_ABILITIES.has(ability):
			push_error("PFAncestry Error: '%s' is not a valid ability string in %s for %s." % [ability, context, entity_name])
