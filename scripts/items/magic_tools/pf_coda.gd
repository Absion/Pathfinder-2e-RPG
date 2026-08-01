# pf_coda.gd
## A musical instrument with the coda trait that functions similarly to a staff, 
## but only for Bards. It cannot be used to Strike or etched with weapon runes.
class_name PFCoda
extends PFItem

var casting_component: Resource
var skill_bonus_data: Dictionary = {}
var _active_modifiers: Array[PFModifier] = []

func _init(p_name: String = "Coda Instrument", p_traits: Array[StringName] = [&"magical", &"coda", &"staff"], p_level: int = 1, p_price_gp: float = 0.0, p_stored_spells: Dictionary = {}, p_bulk: int = 1):
	super._init(p_name, p_traits, p_level, p_price_gp, p_bulk)
	
	casting_component = load("res://scripts/items/magic_tools/pf_staff_casting_component.gd").new(p_stored_spells)
	requires_investment = true

## Clears charges during a long rest
func clear_charges() -> void:
	casting_component.clear_charges()

## Prepares the coda during daily preparations. 
func prepare_coda(actor: PFActor, base_charges: int, expend_slot_rank: int = 0) -> void:
	if actor.actor_class.id != "bard":
		print("    > [ERROR] Only Bards can prepare a coda instrument!")
		return
	casting_component.prepare(actor, entity_name, base_charges, expend_slot_rank)

func on_equipped(wearer: PFActor) -> void:
	if not "attributes" in wearer or not wearer.attributes: return
	
	# ⚡ Bolt: Iterate dictionary directly instead of using .keys() to avoid GC array allocation
	for stat_name in skill_bonus_data:
		var bonus = skill_bonus_data[stat_name]
		var modifier = PFModifier.new(bonus, PFMathConstants.ModifierType.ITEM, entity_name)
		
		# Specifically for performance or other skills. For now, since skills aren't fully mapped to modifiers in the sheet,
		# we just print or map it where available. We'll map generic attributes here.
		if stat_name == "performance":
			# In a full implementation, you would add this to the character's performance skill modifier.
			print("    > %s grants a +%d item bonus to Performance!" % [entity_name, bonus])
			
		_active_modifiers.append(modifier)

func on_unequipped(wearer: PFActor) -> void:
	if not "attributes" in wearer or not wearer.attributes: return
	
	for modifier in _active_modifiers:
		# Remove from attributes/skills where it was added
		print("    > %s loses passive bonuses from %s." % [wearer.entity_name, entity_name])
			
	_active_modifiers.clear()


## Attempts to cast a spell from the coda.
func cast_coda_spell(actor: PFActor, spell_id: StringName, rank: int, spontaneous_slot_rank: int = -1) -> bool:
	if actor.actor_class.id != "bard":
		print("    > [ERROR] Only Bards can cast spells from a coda instrument!")
		return false
	return casting_component.cast_spell(actor, entity_name, spell_id, rank, spontaneous_slot_rank)

func get_current_charges() -> int:
	return casting_component.current_charges
	
func get_max_charges() -> int:
	return casting_component.max_charges

