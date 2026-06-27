# pf_spellheart.gd
## A permanent magical attachment that grants passive benefits and cantrips/spells.
class_name PFSpellheart
extends PFAttachment

var granted_spell_id: StringName = &""
var granted_spell_rank: int = 1

func _init(p_name: String = "Spellheart", p_traits: Array[StringName] = [&"invested", &"magical", &"spellheart"], p_level: int = 1, p_price_gp: float = 0.0, p_spell_id: StringName = &"", p_spell_rank: int = 1):
	super._init(p_name, p_traits, p_level, p_price_gp)
	granted_spell_id = p_spell_id
	granted_spell_rank = p_spell_rank

func attach_to(item: PFItem) -> bool:
	if item is PFWeapon or item is PFArmor:
		if item.attachment != null:
			if item.attachment is PFSpellheart or item.attachment.traits.has(&"talisman"):
				print("    > [ERROR] %s already has a spellheart or talisman affixed!" % item.entity_name)
				return false
		return super.attach_to(item)
	
	print("    > [ERROR] Spellhearts can only be affixed to Weapons or Armor.")
	return false

## Tries to cast the spellheart's spell. The actor must be a spellcaster and must have invested this spellheart.
func cast_spellheart_spell(actor: PFActor) -> bool:
	if granted_spell_id == &"":
		return false
		
	if actor.inventory and not actor.inventory.invested_items.has(self):
		print("    > [ERROR] %s must invest the %s before casting its spell!" % [actor.entity_name, entity_name])
		return false
		
	# Verify spellcasting capability (has a spellbook or spell repertoire)
	if actor.spellbook == null:
		print("    > [ERROR] %s is not a spellcaster and cannot cast the spell from %s!" % [actor.entity_name, entity_name])
		return false
		
	print("    > %s channels magic through the %s and casts %s (Rank %d)!" % [actor.entity_name, entity_name, granted_spell_id, granted_spell_rank])
	return true
