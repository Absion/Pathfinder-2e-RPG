# pf_spell_variant.gd
class_name PFSpellVariant
extends RefCounted

var action_cost: PFEntity.ActionCost = PFEntity.ActionCost.TWO_ACTIONS
var spell_range: PFEntity.Distance = PFEntity.Distance.TOUCH
var target: String = ""
var duration: String = ""

var damage_dice: int = 0
var damage_faces: int = 0

# e.g., ["blinded", "sickened", "shining_state"]
var applied_conditions: Array[StringName] = []

var special_effects: String = ""
