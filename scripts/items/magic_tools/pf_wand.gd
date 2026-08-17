class_name PFWand
extends PFItem

var stored_spell: StringName
var spell_rank: int

var is_expended: bool = false
var wand_destroyed: bool = false

func _init(p_name: String = "", p_traits: Array[StringName] = [], p_level: int = 1, p_price_gp: float = 0.0, 
		p_spell_id: StringName = &"", p_spell_rank: int = 1):
	super._init(p_name, p_traits, p_level, p_price_gp, PFEquipmentConstants.ItemMaterial.WOOD, 3, 10, 5, PFEquipmentConstants.MaterialGrade.STANDARD, 0, 0, false, &"medium")
	
	stored_spell = p_spell_id
	spell_rank = p_spell_rank
	# Wands are Light Bulk (1 unit)
	bulk_value = 1
	base_bulk_value = 1

## Checks if the wand can be cast, handling the overcharge flat check and destruction rules.
## Returns true if the resource check passes and the spell can be cast.
func cast_wand(actor: PFActor) -> bool:
	if wand_destroyed or is_destroyed():
		print("    > [ERROR] This wand is destroyed and cannot be used.")
		return false
		
	if not is_expended:
		print("    > %s casts %s from the %s." % [actor.entity_name, stored_spell, entity_name])
		is_expended = true
		return true
	else:
		print("    > %s attempts to overcharge the %s!" % [actor.entity_name, entity_name])
		# Overcharge check: DC 10 flat check
		
		var roll = 10 
		if actor.has_meta("test_flat_check"):
			roll = actor.get_meta("test_flat_check")
		elif actor.has_method(&"roll_flat_check"):
			var res = actor.roll_flat_check()
			if typeof(res) == TYPE_DICTIONARY:
				roll = res.get("total", res.get("roll", 1))
			else:
				roll = res
				
		if roll >= 10:
			print("    > Overcharge successful! (Flat Check: %d) The spell is cast, but the wand remains expended." % roll)
			return true
		else:
			print("    > [CRITICAL FAILURE] Overcharge failed! (Flat Check: %d) The wand shatters!" % roll)
			wand_destroyed = true
			# We can also call take_damage to use the system logic, bypassing hardness:
			take_item_damage(max_hp + hardness)
			return false

## Resets the wand's charges during daily preparations.
func reset_for_day() -> void:
	if not wand_destroyed and not is_destroyed():
		is_expended = false
