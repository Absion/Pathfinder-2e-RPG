# pf_spell.gd
## A magical spell defining core tradition, category, and saving throws.
class_name PFSpell
extends PFEntity
var base_spell_rank: int
var spell_category: PFMagicConstants.SpellCategory
var traditions: Array[PFMagicConstants.MagicTradition]

var saving_throw: String # e.g. "Will", "Basic Reflex"
var is_attack: bool
var damage_type: StringName

var variants: Array[PFSpellVariant] = []

var scaling_rules: PFMagicConstants.ScalingType
var scaling_dice: int
var description: String

func _init(p_name: String = "", p_traits: Array[StringName] = [], p_rarity: PFBiographyConstants.Rarity = PFBiographyConstants.Rarity.COMMON):
	super._init(p_name, p_traits, p_rarity)

func get_damage_dice(cast_rank: int, action_cost: PFCombatConstants.ActionCost) -> int:
	var base_dice = 0
	
	# Find the matching variant to get the base damage dice
	for v in variants:
		if v.action_cost == action_cost:
			base_dice = v.damage_dice
			break
			
	if scaling_rules == PFMagicConstants.ScalingType.NONE or scaling_dice == 0:
		return base_dice
		
	# PF2e heightening math
	var rank_difference = cast_rank - base_spell_rank
	if rank_difference <= 0:
		return base_dice
		
	# Divide rank_difference by the scaling rule (e.g. PLUS_TWO means divide by 2)
	var multiplier = rank_difference / scaling_rules
	return base_dice + (multiplier * scaling_dice)
