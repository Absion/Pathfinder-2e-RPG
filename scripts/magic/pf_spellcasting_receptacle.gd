class_name PFSpellcastingReceptacle
extends RefCounted

var source_id: StringName # e.g. "cleric_class", "wizard_archetype", "innate"
var tradition: PFMagicConstants.MagicTradition
var caster_type: PFMagicConstants.CasterType

# Max slots per rank
# keys are spell ranks (1-10), values are integers representing max slots
var spells_per_rank: Dictionary = {}
var expended_slots_per_rank: Dictionary = {}

# For Spontaneous Casters: List of PFSpell that can be cast at specific ranks
var spell_repertoire: Dictionary = {}

var signature_spells: Array[PFSpell] = []

# For Prepared Casters: List of PFSpell that are prepared (can have duplicates)
# Dictionary mapping Rank (int) to Array[PFSpell]
var prepared_spells: Dictionary = {}

func _init(p_source_id: StringName, p_tradition: PFMagicConstants.MagicTradition, p_caster_type: PFMagicConstants.CasterType):
	source_id = p_source_id
	tradition = p_tradition
	caster_type = p_caster_type

func get_max_slots(rank: int) -> int:
	return spells_per_rank.get(rank, 0)
	
func get_available_slots(rank: int) -> int:
	var max_slots = get_max_slots(rank)
	var expended_slots = expended_slots_per_rank.get(rank, 0)
	return max(0, max_slots - expended_slots)

func expend_slot(rank: int) -> bool:
	if get_available_slots(rank) > 0:
		expended_slots_per_rank[rank] = expended_slots_per_rank.get(rank, 0) + 1
		return true
	return false

func restore_slots() -> void:
	expended_slots_per_rank.clear()
	# For prepared casters, typically they would unprepare or just restore
	# In a real game, this might clear prepared spells or just restore slots
	# We'll leave prepared spells intact, assuming they keep the same preparation

func add_to_repertoire(spell: PFSpell, rank: int) -> void:
	if not spell_repertoire.has(rank):
		spell_repertoire[rank] = []
	if not spell_repertoire[rank].has(spell):
		spell_repertoire[rank].append(spell)

func set_signature_spell(spell: PFSpell) -> bool:
	if caster_type != PFMagicConstants.CasterType.SPONTANEOUS:
		return false
	for sig_spell in signature_spells:
		if sig_spell.base_spell_rank == spell.base_spell_rank:
			return false
	signature_spells.append(spell)
	return true

func prepare_spell(spell: PFSpell, rank: int) -> bool:
	if caster_type != PFMagicConstants.CasterType.PREPARED:
		print("    > [ERROR] Receptacle %s is not prepared." % source_id)
		return false
		
	if not prepared_spells.has(rank):
		prepared_spells[rank] = []
		
	var currently_prepared: Array = prepared_spells[rank]
	if currently_prepared.size() >= get_max_slots(rank):
		print("    > [ERROR] No more Rank %d slots available to prepare %s in %s." % [rank, spell.entity_name, source_id])
		return false
		
	currently_prepared.append(spell)
	return true

func can_cast(spell: PFSpell, rank: int) -> bool:
	if get_available_slots(rank) <= 0:
		return false
		
	if caster_type == PFMagicConstants.CasterType.SPONTANEOUS:
		if spell_repertoire.has(rank) and spell_repertoire[rank].has(spell):
			return true
		if signature_spells.has(spell):
			return true
		return false
		
	elif caster_type == PFMagicConstants.CasterType.PREPARED:
		if not prepared_spells.has(rank):
			return false
		return prepared_spells[rank].has(spell)
		
	return false

func cast(spell: PFSpell, rank: int) -> bool:
	if can_cast(spell, rank):
		if caster_type == PFMagicConstants.CasterType.PREPARED:
			# Remove one instance of the prepared spell
			prepared_spells[rank].erase(spell)
			# Expend slot happens implicitly if we track it, but in PF2e, prepared spell IS the slot.
			# Let's also expend the numeric slot for consistency.
			expend_slot(rank)
			return true
		elif caster_type == PFMagicConstants.CasterType.SPONTANEOUS:
			return expend_slot(rank)
	return false
