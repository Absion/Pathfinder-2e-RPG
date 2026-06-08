# pf_heritage.gd
## Represents an actor's specific heritage, applied on top of their ancestry.
class_name PFHeritage
extends PFEntity

var ancestry_id: StringName
var is_versatile: bool

var hp_bonus: int
var size_id: StringName # Empty string if no size override
var speed_bonus: int
var vision_override: int # PFBiographyConstants.Vision.UNKNOWN or -1 if no override

var granted_traits: Array[StringName]
var granted_abilities: Array[PFEntity]

func _init(
		p_name: String = "", 
		p_ancestry_id: StringName = &"",
		p_is_versatile: bool = false,
		p_hp_bonus: int = 0,
		p_size_id: StringName = &"",
		p_speed_bonus: int = 0,
		p_vision_override: int = -1,
		p_granted_traits: Array[StringName] = [],
		p_granted_abilities: Array[PFEntity] = [],
		p_traits: Array[StringName] = [],
		p_rarity: PFBiographyConstants.Rarity = PFBiographyConstants.Rarity.COMMON
	):
	
	super._init(p_name, p_traits, p_rarity)
	
	ancestry_id = p_ancestry_id
	is_versatile = p_is_versatile
	hp_bonus = p_hp_bonus
	size_id = p_size_id
	speed_bonus = p_speed_bonus
	vision_override = p_vision_override
	granted_traits = p_granted_traits
	granted_abilities = p_granted_abilities
