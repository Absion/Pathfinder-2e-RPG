class_name PFSpellbook
extends RefCounted

var owner: PFActor

# Array of receptacles (class, archetypes, innate)
var receptacles: Array[PFSpellcastingReceptacle] = []

# Known spells across all traditions (useful for spontaneous casters selecting repertoire)
var known_spells: Array[PFSpell] = []
var signature_spells: Array[PFSpell] = []

# Focus points are a shared pool across all spellcasting sources
var max_focus_points: int = 0
var focus_points: int = 0

func _init(p_owner: PFActor):
	owner = p_owner

func add_receptacle(receptacle: PFSpellcastingReceptacle) -> void:
	if not receptacles.has(receptacle):
		receptacles.append(receptacle)

# Focus Point Management
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

# Daily Prep
func restore_daily_slots() -> void:
	focus_points = max_focus_points
	for req in receptacles:
		req.restore_slots()

# Learning
func learn_spell(spell: PFSpell) -> void:
	if not known_spells.has(spell):
		known_spells.append(spell)
		print("    > %s learned %s" % [owner.entity_name, spell.entity_name])
		if spell.has_trait(&"focus"):
			increase_max_focus_points(1)

func add_to_repertoire(spell: PFSpell, rank: int, receptacle: PFSpellcastingReceptacle = null) -> bool:
	if receptacle == null and receptacles.size() > 0:
		receptacle = receptacles[0]
	if receptacle == null:
		return false
	if receptacle.caster_type != PFMagicConstants.CasterType.SPONTANEOUS:
		print("    > [ERROR] Only spontaneous casters have a repertoire.")
		return false
	if not known_spells.has(spell):
		print("    > [ERROR] Cannot add %s to repertoire. Spell is not known!" % spell.entity_name)
		return false
	receptacle.add_to_repertoire(spell, rank)
	print("    > Added %s to %s repertoire." % [spell.entity_name, receptacle.source_id])
	return true

func set_signature_spell(spell: PFSpell, receptacle: PFSpellcastingReceptacle = null) -> bool:
	if receptacle == null and receptacles.size() > 0:
		receptacle = receptacles[0]
	if receptacle == null:
		return false
	var res = receptacle.set_signature_spell(spell)
	if res:
		print("    > %s set as Signature Spell for Rank %d in %s." % [spell.entity_name, spell.base_spell_rank, receptacle.source_id])
	return res

# Preparation
func prepare_spell(spell: PFSpell, rank: int, receptacle: PFSpellcastingReceptacle = null) -> bool:
	if receptacle == null and receptacles.size() > 0:
		receptacle = receptacles[0]
	if receptacle == null or not receptacles.has(receptacle):
		print("    > [ERROR] Receptacle not found in spellbook.")
		return false
		
	if not known_spells.has(spell):
		var can_bypass = false
		if receptacle.tradition == PFMagicConstants.MagicTradition.DIVINE or receptacle.tradition == PFMagicConstants.MagicTradition.PRIMAL:
			if spell.rarity == PFBiographyConstants.Rarity.COMMON:
				can_bypass = true
		if not can_bypass:
			print("    > [ERROR] Cannot prepare %s. Spell is not known!" % spell.entity_name)
			return false
			
	return receptacle.prepare_spell(spell, rank)

# Casting
func cast_spell(spell: PFSpell, receptacle: PFSpellcastingReceptacle = null, rank_cast_at: int = -1) -> bool:
	if spell.is_cantrip:
		print("%s casts the cantrip %s!" % [owner.entity_name, spell.entity_name])
		return true
		
	var actual_rank = rank_cast_at if rank_cast_at > 0 else spell.base_spell_rank
	
	if spell.has_trait(&"focus"):
		if focus_points > 0:
			focus_points -= 1
			print("%s successfully casts the focus spell %s!" % [owner.entity_name, spell.entity_name])
			return true
		return false

	var valid_receptacles = get_valid_receptacles_for_spell(spell, actual_rank)
	
	if receptacle == null:
		# Fallback to finding the first valid receptacle
		if valid_receptacles.size() > 0:
			receptacle = valid_receptacles[0]
			
	if receptacle == null or not valid_receptacles.has(receptacle):
		print("    > [ERROR] %s has no receptacle capable of casting %s at Rank %d." % [owner.entity_name, spell.entity_name, actual_rank])
		return false
		
	if receptacle.cast(spell, actual_rank):
		print("%s successfully casts %s at Rank %d!" % [owner.entity_name, spell.entity_name, actual_rank])
		_register_sustained(spell)
		return true
	else:
		print("    > [ERROR] Failed to cast %s from %s." % [spell.entity_name, receptacle.source_id])
		return false

func get_valid_receptacles_for_spell(spell: PFSpell, rank: int) -> Array[PFSpellcastingReceptacle]:
	var valid: Array[PFSpellcastingReceptacle] = []
	for req in receptacles:
		if req.can_cast(spell, rank):
			valid.append(req)
	return valid

func _register_sustained(spell: PFSpell) -> void:
	if not spell.is_sustained:
		return
	var tm = PFContext.active_turn_manager
	if not tm: return
	if not tm.active_sustained_spells.has(owner):
		tm.active_sustained_spells[owner] = []
	if not tm.active_sustained_spells[owner].has(spell):
		tm.active_sustained_spells[owner].append(spell)
		print("    > %s can sustain %s on future turns." % [owner.entity_name, spell.entity_name])
	if not tm.spells_sustained_this_turn.has(owner):
		tm.spells_sustained_this_turn[owner] = []
	if not tm.spells_sustained_this_turn[owner].has(spell):
		tm.spells_sustained_this_turn[owner].append(spell)
