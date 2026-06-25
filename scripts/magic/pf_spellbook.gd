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
var cantrips: Array[PFSpell] = []

# --- SLOT TRACKING ---
var max_focus_points: int = 0
var focus_points: int = 0
# Maps Rank (int) -> amount (int)
var extra_slots: Dictionary = {} 
var current_slots: Dictionary = {}

func _init(p_owner: PFActor):
	owner = p_owner

func get_caster_type() -> PFMagicConstants.CasterType:
	if owner.actor_class:
		return owner.actor_class.caster_type
	return PFMagicConstants.CasterType.NONE

# --- PROGRESSION CALCULATION ---

func get_max_slots(rank: int) -> int:
	var total = 0
	
	# 1. Base Class Progression
	var level = owner.level
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
		print("    > %s learned %s" % [owner.entity_name, spell.entity_name])
		
		# In PF2e, gaining a focus spell automatically increases your focus pool by 1 (max 3).
		if spell.has_trait(&"focus"):
			increase_max_focus_points(1)

func add_to_repertoire(spell: PFSpell, rank: int) -> bool:
	if get_caster_type() != PFMagicConstants.CasterType.SPONTANEOUS:
		print("    > [ERROR] Only spontaneous casters have a repertoire.")
		return false
	if not known_spells.has(spell):
		print("    > [ERROR] Cannot add %s to repertoire. Spell is not known!" % spell.entity_name)
		return false
	if not repertoire.has(rank):
		repertoire[rank] = []
	if not repertoire[rank].has(spell):
		repertoire[rank].append(spell)
		print("    > Added %s to Rank %d repertoire." % [spell.entity_name, rank])
		return true
	return false
		
func set_signature_spell(spell: PFSpell) -> bool:
	if get_caster_type() != PFMagicConstants.CasterType.SPONTANEOUS:
		print("    > [ERROR] Only spontaneous casters can have signature spells.")
		return false
	# Ensure they don't already have a signature spell for this base rank
	for sig_spell in signature_spells:
		if sig_spell.base_spell_rank == spell.base_spell_rank:
			print("    > [ERROR] Already have a signature spell for Rank %d (%s)!" % [spell.base_spell_rank, sig_spell.entity_name])
			return false
	signature_spells.append(spell)
	print("    > %s set as Signature Spell for Rank %d." % [spell.entity_name, spell.base_spell_rank])
	return true

func prepare_spell(spell: PFSpell, rank: int) -> bool:
	if get_caster_type() != PFMagicConstants.CasterType.PREPARED:
		print("    > [ERROR] Only prepared casters can prepare spells.")
		return false
	if not known_spells.has(spell):
		var can_bypass = false
		if owner is PFPlayerCharacter and owner.actor_class:
			var tradition = owner.actor_class.spell_tradition
			if tradition == PFMagicConstants.MagicTradition.DIVINE or tradition == PFMagicConstants.MagicTradition.PRIMAL:
				if spell.rarity == PFBiographyConstants.Rarity.COMMON:
					can_bypass = true
		if not can_bypass:
			print("    > [ERROR] Cannot prepare %s. Spell is not known!" % spell.entity_name)
			return false
	if not prepared_spells.has(rank):
		prepared_spells[rank] = []
	if prepared_spells[rank].size() >= get_max_slots(rank):
		print("    > [ERROR] Cannot prepare %s. No Rank %d slots available!" % [spell.entity_name, rank])
		return false
	prepared_spells[rank].append(spell)
	print("    > %s prepared %s at Rank %d." % [owner.entity_name, spell.entity_name, rank])
	return true

func add_innate_spell(spell: PFSpell) -> void:
	var rank = spell.base_spell_rank
	if not innate_spells.has(rank):
		innate_spells[rank] = []
	if not innate_spells[rank].has(spell):
		innate_spells[rank].append(spell)

# --- DAILY PREPARATION ---

func restore_daily_slots() -> void:
	current_slots.clear()
	if get_caster_type() == PFMagicConstants.CasterType.SPONTANEOUS:
		for rank in range(1, 11):
			var max_s = get_max_slots(rank)
			if max_s > 0:
				current_slots[rank] = max_s
	elif get_caster_type() == PFMagicConstants.CasterType.PREPARED:
		prepared_spells.clear() # Must prepare again!
	
	focus_points = max_focus_points

# --- FOCUS POINTS ---

func increase_max_focus_points(amount: int = 1) -> void:
	max_focus_points = clampi(max_focus_points + amount, 0, 3)
	print("    > %s increased max Focus Points to %d." % [owner.entity_name, max_focus_points])

func spend_focus_point() -> bool:
	if focus_points > 0:
		focus_points -= 1
		print("%s spent a Focus Point. (%d remaining)" % [owner.entity_name, focus_points])
		return true
	print("%s tried to spend a Focus Point but has none left!" % owner.entity_name)
	return false

func refocus() -> void:
	if focus_points < max_focus_points:
		focus_points += 1
		print("%s refocused and regained a Focus Point. (%d/%d)" % [owner.entity_name, focus_points, max_focus_points])
	else:
		print("%s refocused but already has maximum Focus Points." % owner.entity_name)

# --- CASTING INTERFACE ---

func expend_slot(rank: int) -> bool:
	if current_slots.has(rank) and current_slots[rank] > 0:
		current_slots[rank] -= 1
		print("%s expended a Rank %d spell slot. (%d remaining)" % [owner.entity_name, rank, current_slots[rank]])
		return true
	print("%s tried to cast a Rank %d spell but has no slots left!" % [owner.entity_name, rank])
	return false

func cast_spell(spell: PFSpell, rank_cast_at: int = -1) -> bool:
	if spell.is_cantrip:
		print("%s casts the cantrip %s!" % [owner.entity_name, spell.entity_name])
		return true
		
	if spell.has_trait(&"focus"):
		if spend_focus_point():
			print("%s successfully casts the focus spell %s!" % [owner.entity_name, spell.entity_name])
			return true
		return false
		
	var actual_rank = rank_cast_at if rank_cast_at > 0 else spell.base_spell_rank
	
	# INNATE SPELLS
	if innate_spells.has(actual_rank) and spell in innate_spells[actual_rank]:
		print("%s successfully casts the innate spell %s at Rank %d!" % [owner.entity_name, spell.entity_name, actual_rank])
		_register_sustained(spell)
		return true
	
	var caster_type = get_caster_type()
	
	if caster_type == PFMagicConstants.CasterType.PREPARED:
		if prepared_spells.has(actual_rank) and prepared_spells[actual_rank].has(spell):
			prepared_spells[actual_rank].erase(spell)
			print("%s successfully casts %s at Rank %d! (Slot expended)" % [owner.entity_name, spell.entity_name, actual_rank])
			_register_sustained(spell)
			return true
		else:
			print("    > [ERROR] %s does not have %s prepared at Rank %d!" % [owner.entity_name, spell.entity_name, actual_rank])
			return false
			
	elif caster_type == PFMagicConstants.CasterType.SPONTANEOUS:
		var can_cast = false
		if repertoire.has(actual_rank) and repertoire[actual_rank].has(spell):
			can_cast = true
		elif signature_spells.has(spell):
			can_cast = true
			
		if can_cast:
			if expend_slot(actual_rank):
				print("%s successfully casts %s at Rank %d!" % [owner.entity_name, spell.entity_name, actual_rank])
				_register_sustained(spell)
				return true
			return false
		else:
			print("    > [ERROR] %s does not have %s in their Rank %d repertoire (and it is not a signature spell)!" % [owner.entity_name, spell.entity_name, actual_rank])
			return false

	print("    > [ERROR] %s cannot cast spells of this type." % owner.entity_name)
	return false

func _register_sustained(spell: PFSpell) -> void:
	if not spell.is_sustained:
		return
		
	var tm = PFContext.active_turn_manager
	if not tm:
		return
		
	if not tm.active_sustained_spells.has(owner):
		tm.active_sustained_spells[owner] = []
		
	if not tm.active_sustained_spells[owner].has(spell):
		tm.active_sustained_spells[owner].append(spell)
		print("    > %s can sustain %s on future turns." % [owner.entity_name, spell.entity_name])
	
	# Mark it as sustained this turn so it doesn't immediately expire
	if not tm.spells_sustained_this_turn.has(owner):
		tm.spells_sustained_this_turn[owner] = []
	if not tm.spells_sustained_this_turn[owner].has(spell):
		tm.spells_sustained_this_turn[owner].append(spell)
