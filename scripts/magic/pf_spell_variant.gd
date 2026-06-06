# pf_spell_variant.gd
## A specific castable version of a spell, such as a 2-Action vs 3-Action Heal.
class_name PFSpellVariant
extends RefCounted

var action_cost: PFCombatConstants.ActionCost = PFCombatConstants.ActionCost.TWO_ACTIONS
var spell_range: PFMathConstants.Distance = PFMathConstants.Distance.TOUCH
var target: String = ""
var duration: String = ""

var damage_dice: int = 0
var damage_faces: int = 0

# e.g., ["blinded", "sickened", "shining_state"]
var applied_conditions: Array[StringName] = []

var special_effects: String = ""
