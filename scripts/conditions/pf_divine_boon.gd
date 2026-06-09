# pf_divine_boon.gd
## A specific condition representing a deity's boon or curse.
class_name PFDivineBoon
extends PFCondition

var description: String
var is_curse: bool
var tier: PFBiographyConstants.DivineBoonTier

func _init(p_id: StringName, p_name: String, p_desc: String, p_is_curse: bool, p_tier: PFBiographyConstants.DivineBoonTier = PFBiographyConstants.DivineBoonTier.MINOR):
	condition_id = p_id
	condition_name = p_name
	description = p_desc
	is_curse = p_is_curse
	tier = p_tier
	value = 1
	is_active = true

func on_apply(owner: PFActor) -> bool:
	if is_curse:
		print("    > [DIVINE CURSE] %s has been cursed by the gods! (%s)" % [owner.entity_name, condition_name])
	else:
		print("    > [DIVINE BOON] %s has received a divine boon! (%s)" % [owner.entity_name, condition_name])
	return true
