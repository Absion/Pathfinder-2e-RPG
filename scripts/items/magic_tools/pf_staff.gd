class_name PFStaff
extends PFWeapon

var casting_component: Resource

func _init(p_name: String = "Magical Staff", p_traits: Array[StringName] = [&"monk", &"two-hand-d8", &"magical", &"staff"], p_level: int = 1, p_price_gp: float = 0.0, p_stored_spells: Dictionary = {}):
	super._init(p_name, p_traits, p_level, p_price_gp, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.SIMPLE, PFEquipmentConstants.WeaponGroup.CLUB, 1, 4, PFCombatConstants.DamageType.BLUDGEONING, PFEquipmentConstants.ItemMaterial.WOOD, 5, 20, 0, 0, PFEquipmentConstants.MaterialGrade.STANDARD, 0, 0, 0, 1, PFEquipmentConstants.AmmunitionType.NONE)
	
	casting_component = load("res://scripts/items/magic_tools/pf_staff_casting_component.gd").new(p_stored_spells)
	requires_investment = true

## Clears charges during a long rest
func clear_charges() -> void:
	casting_component.clear_charges()

## Prepares the staff during daily preparations. 
## The UI/Player decides the base charges (usually highest spell slot) and if a prepared caster is expending a slot.
func prepare_staff(actor: PFActor, base_charges: int, expend_slot_rank: int = 0) -> void:
	casting_component.prepare(actor, entity_name, base_charges, expend_slot_rank)

## Attempts to cast a spell from the staff.
## Returns true if the resource cost (charges / spell slots) was successfully paid.
func cast_staff_spell(actor: PFActor, spell_id: StringName, rank: int, spontaneous_slot_rank: int = -1) -> bool:
	return casting_component.cast_spell(actor, entity_name, spell_id, rank, spontaneous_slot_rank)

func get_current_charges() -> int:
	return casting_component.current_charges
	
func get_max_charges() -> int:
	return casting_component.max_charges
