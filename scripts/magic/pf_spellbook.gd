# pf_spellbook.gd
## Manages the spells known and prepared by a spellcaster.
class_name PFSpellbook
extends RefCounted

# Pre-defined progressions mapping character level to available spell slots per rank.
# Format: { level_int: { rank_int: max_slots_int } }
const FULL_CASTER_PROGRESSION: Dictionary = {
	1: {1: 2},
	2: {1: 3},
	3: {1: 3, 2: 2},
	4: {1: 3, 2: 3},
	5: {1: 3, 2: 3, 3: 2},
	6: {1: 3, 2: 3, 3: 3},
	7: {1: 3, 2: 3, 3: 3, 4: 2},
	8: {1: 3, 2: 3, 3: 3, 4: 3},
	9: {1: 3, 2: 3, 3: 3, 4: 3, 5: 2},
	10: {1: 3, 2: 3, 3: 3, 4: 3, 5: 3},
	11: {1: 3, 2: 3, 3: 3, 4: 3, 5: 3, 6: 2},
	12: {1: 3, 2: 3, 3: 3, 4: 3, 5: 3, 6: 3},
	13: {1: 3, 2: 3, 3: 3, 4: 3, 5: 3, 6: 3, 7: 2},
	14: {1: 3, 2: 3, 3: 3, 4: 3, 5: 3, 6: 3, 7: 3},
	15: {1: 3, 2: 3, 3: 3, 4: 3, 5: 3, 6: 3, 7: 3, 8: 2},
	16: {1: 3, 2: 3, 3: 3, 4: 3, 5: 3, 6: 3, 7: 3, 8: 3},
	17: {1: 3, 2: 3, 3: 3, 4: 3, 5: 3, 6: 3, 7: 3, 8: 3, 9: 2},
	18: {1: 3, 2: 3, 3: 3, 4: 3, 5: 3, 6: 3, 7: 3, 8: 3, 9: 3},
	19: {1: 3, 2: 3, 3: 3, 4: 3, 5: 3, 6: 3, 7: 3, 8: 3, 9: 3, 10: 1},
	20: {1: 3, 2: 3, 3: 3, 4: 3, 5: 3, 6: 3, 7: 3, 8: 3, 9: 3, 10: 1}
}

const BOUNDED_CASTER_PROGRESSION: Dictionary = {
	1: {1: 1},
	2: {1: 2},
	3: {1: 2, 2: 1},
	4: {1: 2, 2: 2},
	5: {2: 2, 3: 1},
	6: {2: 2, 3: 2},
	7: {3: 2, 4: 1},
	8: {3: 2, 4: 2},
	9: {4: 2, 5: 1},
	10: {4: 2, 5: 2},
	11: {5: 2, 6: 1},
	12: {5: 2, 6: 2},
	13: {6: 2, 7: 1},
	14: {6: 2, 7: 2},
	15: {7: 2, 8: 1},
	16: {7: 2, 8: 2},
	17: {8: 2, 9: 1},
	18: {8: 2, 9: 2},
	19: {8: 2, 9: 2},
	20: {8: 2, 9: 2}
}

var owner: PFActor

# --- MAGIC STORAGE ---
var known_spells: Array[PFSpell] = []
var signature_spells: Array[PFSpell] = []

# Dictionaries mapping Rank (int) to Array[PFSpell]
var repertoire: Dictionary = {}
var prepared_spells: Dictionary = {}
var innate_spells: Dictionary = {}

# --- SLOT TRACKING ---
# Maps Rank (int) -> amount (int)
var extra_slots: Dictionary = {} 
var current_slots: Dictionary = {}

func _init(p_owner: PFActor):
	owner = p_owner

# --- PROGRESSION CALCULATION ---

func get_max_slots(rank: int) -> int:
	var total = 0
	
	# 1. Base Class Progression
	var level = owner.sheet.level
	if owner.actor_class:
		match owner.actor_class.spell_progression:
			PFMagicConstants.SpellProgression.FULL_CASTER:
				if FULL_CASTER_PROGRESSION.has(level) and FULL_CASTER_PROGRESSION[level].has(rank):
					total += FULL_CASTER_PROGRESSION[level][rank]
			PFMagicConstants.SpellProgression.BOUNDED_CASTER:
				if BOUNDED_CASTER_PROGRESSION.has(level) and BOUNDED_CASTER_PROGRESSION[level].has(rank):
					total += BOUNDED_CASTER_PROGRESSION[level][rank]
	
	# 2. Add extra slots from feats/tattoos
	if extra_slots.has(rank):
		total += extra_slots[rank]
		
	return total

func add_extra_slot(rank: int, amount: int = 1) -> void:
	if not extra_slots.has(rank):
		extra_slots[rank] = 0
	extra_slots[rank] += amount
	
# --- SPELL MANAGEMENT ---

func learn_spell(spell: PFSpell) -> void:
	if not known_spells.has(spell):
		known_spells.append(spell)
		print("%s learned %s" % [owner.entity_name, spell.entity_name])

func add_to_repertoire(spell: PFSpell, rank: int) -> void:
	if not repertoire.has(rank):
		repertoire[rank] = []
	if not repertoire[rank].has(spell):
		repertoire[rank].append(spell)
		
func set_signature_spell(spell: PFSpell) -> void:
	if not signature_spells.has(spell):
		signature_spells.append(spell)

func prepare_spell(spell: PFSpell, rank: int) -> void:
	if not prepared_spells.has(rank):
		prepared_spells[rank] = []
	prepared_spells[rank].append(spell)

func add_innate_spell(spell: PFSpell) -> void:
	var rank = spell.base_spell_rank
	if not innate_spells.has(rank):
		innate_spells[rank] = []
	if not innate_spells[rank].has(spell):
		innate_spells[rank].append(spell)

# --- DAILY PREPARATION ---

func restore_daily_slots() -> void:
	current_slots.clear()
	for rank in range(1, 11):
		var max_s = get_max_slots(rank)
		if max_s > 0:
			current_slots[rank] = max_s
