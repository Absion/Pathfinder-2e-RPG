# pf_grimoire.gd
## A magical book used by prepared spellcasters during their daily preparations.
class_name PFGrimoire
extends PFItem

var granted_spell_capacity: int = 1
var granted_spell_rank: int = 1

func _init(p_name: String = "Grimoire", p_traits: Array[StringName] = [&"grimoire", &"magical", &"invested"], p_level: int = 1, p_price_gp: float = 0.0):
	super._init(p_name, p_traits, p_level, p_price_gp, PFEquipmentConstants.ItemMaterial.STANDARD, 0, 0, 0, PFEquipmentConstants.MaterialGrade.STANDARD, 1)
	carry_state = PFEquipmentConstants.CarryState.STOWED
	requires_investment = true

## Called during Phase 8 Morning Rest when a prepared caster studies the grimoire
func study_grimoire(actor: PFActor) -> void:
	if not requires_investment or not actor.inventory.invested_items.has(self):
		print("    > [ERROR] %s must invest the %s to study it!" % [actor.entity_name, entity_name])
		return
		
	if actor.spellbook == null:
		print("    > [ERROR] %s is not a spellcaster and cannot study a grimoire." % actor.entity_name)
		return
		
	var prepared = false
	for r in actor.spellbook.receptacles:
		if r.caster_type == PFMagicConstants.CasterType.PREPARED:
			prepared = true
			# Increase the spell capacity for the granted rank
			r.add_extra_slots(granted_spell_rank, granted_spell_capacity)
			break
			
	if prepared:
		print("    > %s studies the %s and gains %d extra spell slot(s) of rank %d!" % [actor.entity_name, entity_name, granted_spell_capacity, granted_spell_rank])
	else:
		print("    > [ERROR] %s is not a prepared spellcaster!" % actor.entity_name)
