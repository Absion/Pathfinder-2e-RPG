class_name PFStaff
extends PFWeapon

var max_charges: int = 0
var current_charges: int = 0
# Maps rank (int) to Array[StringName] of spell IDs
var stored_spells: Dictionary = {}

func _init(p_name: String = "Magical Staff", p_traits: Array[StringName] = [&"monk", &"two-hand-d8", &"magical", &"staff"], p_level: int = 1, p_price_gp: float = 0.0, p_stored_spells: Dictionary = {}):
	super._init(p_name, p_traits, p_level, p_price_gp, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.SIMPLE, PFEquipmentConstants.WeaponGroup.CLUB, 1, 4, PFCombatConstants.DamageType.BLUDGEONING, PFEquipmentConstants.ItemMaterial.WOOD, 5, 20, 0, 0, PFEquipmentConstants.MaterialGrade.STANDARD, 0, 0, 0, 1, PFEquipmentConstants.AmmunitionType.NONE)
	
	stored_spells = p_stored_spells
	requires_investment = true

## Clears charges during a long rest
func clear_charges() -> void:
	current_charges = 0
	max_charges = 0

## Prepares the staff during daily preparations. 
## The UI/Player decides the base charges (usually highest spell slot) and if a prepared caster is expending a slot.
func prepare_staff(actor: PFActor, base_charges: int, expend_slot_rank: int = 0) -> void:
	if not actor or not actor.spellbook:
		return
		
	max_charges = base_charges
	
	if expend_slot_rank > 0:
		var rep = null
		# Find the prepared receptacle for this actor
		for r in actor.spellbook.receptacles:
			if r.tradition == actor.actor_class.spell_tradition and r.caster_type == PFMagicConstants.CasterType.PREPARED:
				rep = r
				break
				
		if rep != null and rep.get_available_slots(expend_slot_rank) > 0:
			rep.expend_slot(expend_slot_rank)
			max_charges += expend_slot_rank
			print("    > %s expends a rank %d spell slot to add %d extra charges to the %s." % [actor.entity_name, expend_slot_rank, expend_slot_rank, entity_name])
		else:
			print("    > [ERROR] %s does not have a rank %d prepared spell slot to expend!" % [actor.entity_name, expend_slot_rank])
				
	current_charges = max_charges
	print("    > %s prepares the %s, charging it with %d total charges." % [actor.entity_name, entity_name, max_charges])

## Attempts to cast a spell from the staff.
## Returns true if the resource cost (charges / spell slots) was successfully paid.
func cast_staff_spell(actor: PFActor, spell_id: StringName, rank: int, spontaneous_slot_rank: int = -1) -> bool:
	if not _has_spell(spell_id, rank):
		print("    > [ERROR] The %s does not contain the spell %s at rank %d." % [entity_name, spell_id, rank])
		return false
		
	if spontaneous_slot_rank > 0:
		# Spontaneous caster rule: 1 charge + 1 slot of the exact spell rank
		if current_charges < 1:
			print("    > [ERROR] Not enough charges to cast %s spontaneously (Requires 1 charge)." % spell_id)
			return false
			
		var rep = null
		for r in actor.spellbook.receptacles:
			if r.tradition == actor.actor_class.spell_tradition and r.caster_type == PFMagicConstants.CasterType.SPONTANEOUS:
				rep = r
				break
				
		if rep == null or rep.get_available_slots(spontaneous_slot_rank) < 1:
			print("    > [ERROR] No spontaneous spell slots of rank %d available to fuel the staff." % spontaneous_slot_rank)
			return false
			
		rep.expend_slot(spontaneous_slot_rank)
		current_charges -= 1
		print("    > %s spontaneously casts %s (Rank %d) from the %s! (Remaining Charges: %d)" % [actor.entity_name, spell_id, rank, entity_name, current_charges])
		return true
	else:
		# Standard cast: 1 charge per rank
		if current_charges < rank:
			print("    > [ERROR] Not enough charges to cast %s (Requires %d charges)." % [spell_id, rank])
			return false
			
		current_charges -= rank
		print("    > %s casts %s (Rank %d) from the %s! (Remaining Charges: %d)" % [actor.entity_name, spell_id, rank, entity_name, current_charges])
		return true

func _has_spell(spell_id: StringName, rank: int) -> bool:
	if stored_spells.has(rank):
		var spells = stored_spells[rank]
		for s in spells:
			if s == spell_id:
				return true
	return false
