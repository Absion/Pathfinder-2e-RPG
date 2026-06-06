# pf_background.gd
## Represents an actor's history, providing skills and ability boosts.
class_name PFBackground
extends PFEntity

var ability_boosts: Array[StringName]
var trained_skills: Array[StringName]
var trained_lores: Array[StringName]
var background_description: String

func _init(
		p_name: String = "", 
		p_boosts: Array[StringName] = [], 
		p_skills: Array[StringName] = [], 
		p_lores: Array[StringName] = [], 
		p_desc: String = "",
		p_traits: Array[StringName] = [],
		p_rarity: PFBiographyConstants.Rarity = PFBiographyConstants.Rarity.COMMON
	):
	
	super._init(p_name, p_traits, p_rarity)
	
	_validate_abilities(p_boosts, "ability_boosts")
	
	ability_boosts = p_boosts
	trained_skills = p_skills
	trained_lores = p_lores
	background_description = p_desc

func _validate_abilities(abilities: Array[StringName], context: String) -> void:
	const VALID_ABILITIES: Array[StringName] = [&"STR", &"DEX", &"CON", &"INT", &"WIS", &"CHA", &"FREE"]
	for ability in abilities:
		if not VALID_ABILITIES.has(ability):
			push_error("PFBackground Error: '%s' is not a valid ability string in %s for %s." % [ability, context, entity_name])
