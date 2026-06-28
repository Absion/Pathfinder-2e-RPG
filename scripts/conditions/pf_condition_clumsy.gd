# pf_condition_clumsy.gd
## You are clumsy. You take a status penalty equal to the condition value to Dexterity-based checks and DCs, including AC, Reflex saves, ranged attacks, and skill checks using Dexterity.
class_name PFConditionClumsy
extends PFCondition

func on_apply(owner: PFActor) -> bool:
	if not "attributes" in owner or owner.attributes == null:
		return false
	
	print("%s becomes clumsy %d!" % [owner.entity_name, value])
	
	# Apply negative modifier to AC
	if "ac_modifiers" in owner.attributes:
		var mod_ac = PFModifier.new(-value, PFMathConstants.ModifierType.STATUS, condition_name)
		owner.attributes.ac_modifiers.add_modifier(mod_ac)
		
	# Apply to Reflex Save
	if "ref_save" in owner.attributes:
		var mod_ref = PFModifier.new(-value, PFMathConstants.ModifierType.STATUS, condition_name)
		owner.attributes.ref_save.add_modifier(mod_ref)
		
	# Dexterity attacks and skills...
	if "dc_modifiers" in owner.attributes:
		var mod_dc = PFModifier.new(-value, PFMathConstants.ModifierType.STATUS, condition_name)
		owner.attributes.dc_modifiers.add_modifier(mod_dc)
		
	return true

func on_remove(owner: PFActor) -> void:
	if "attributes" in owner and owner.attributes != null:
		if "ref_save" in owner.attributes:
			owner.attributes.ref_save.remove_modifier_by_source(condition_name)
		if "dc_modifiers" in owner.attributes:
			owner.attributes.dc_modifiers.remove_modifier_by_source(condition_name)
		if "ac_modifiers" in owner.attributes:
			owner.attributes.ac_modifiers.remove_modifier_by_source(condition_name)
	print("%s is no longer clumsy." % owner.entity_name)
