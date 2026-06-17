# pf_action_cast_spell.gd
class_name PFActionCastSpell
extends PFAction

var spell: PFSpell
var spell_rank: int

func _init(p_spell: PFSpell, p_rank: int = -1):
	spell = p_spell
	spell_rank = p_rank
	
	# Determine base action cost
	var action_cost = PFCombatConstants.ActionCost.TWO_ACTIONS
	match spell.cast_time.to_lower():
		"1", "1 action": action_cost = PFCombatConstants.ActionCost.ONE_ACTION
		"2", "2 actions": action_cost = PFCombatConstants.ActionCost.TWO_ACTIONS
		"3", "3 actions": action_cost = PFCombatConstants.ActionCost.THREE_ACTIONS
		"free": action_cost = PFCombatConstants.ActionCost.FREE
		"reaction": action_cost = PFCombatConstants.ActionCost.REACTION
		
	# Gather traits (concentrate and manipulate are usually applied in Remaster based on components, but we'll add manipulate by default for somatic/material equivalents, and concentrate for verbal)
	# For simplicity, we just inherit the spell's traits plus cast-specific ones.
	var initial_traits: Array[StringName] = spell.traits.duplicate()
	if not initial_traits.has(&"manipulate"):
		initial_traits.append(&"manipulate")
	if not initial_traits.has(&"concentrate"):
		initial_traits.append(&"concentrate")
		
	super._init("Cast " + spell.entity_name, initial_traits, action_cost)

func execute(user: PFActor, target: PFActor = null) -> bool:
	if not user.has_method("get") or not user.get("spellbook"):
		print("    > [ERROR] %s cannot cast spells (no spellbook)." % user.entity_name)
		return false
		
	if PFContext.environment_manager and PFContext.environment_manager.is_underwater:
		if spell.has_trait(&"fire"):
			print("    > [ERROR] Cannot cast fire spells underwater!")
			return false
		
	# Dynamic Heightening
	var active_rank = spell_rank
	if active_rank <= 0:
		if spell.is_cantrip or spell.has_trait(&"focus"):
			active_rank = maxi(spell.base_spell_rank, ceili(user.level / 2.0))
		else:
			active_rank = spell.base_spell_rank
			
	var spellbook = user.get("spellbook") as PFSpellbook
	
	# Try to spend resources
	if not spellbook.cast_spell(spell, active_rank):
		return false # Failed to cast due to missing slot/focus point
		
	if target == null:
		print("    > %s casts %s (Rank %d)!" % [user.entity_name, spell.entity_name, active_rank])
		spell.resolve_effect(user, user, PFDice.Degree.SUCCESS, active_rank)
		return true

	# Calculate distance
	var distance = user.global_position.distance_to(target.global_position)
	if distance > spell.range_ft:
		print("    > [ERROR] Target %s is out of range (%d ft > %d ft)." % [target.entity_name, distance, spell.range_ft])
		# The spell slot is already expended though! (Rules-wise: wasting the spell)
		return true
		
	print("    > %s casts %s (Rank %d) at %s!" % [user.entity_name, spell.entity_name, active_rank, target.entity_name])
	
	# Determine resolution path
	if spell.requires_attack_roll():
		var attack_bonus = user.get_spell_attack()
		var d20_roll = PFDice.roll_d20()
		var total = d20_roll + attack_bonus
		var target_ac = target.get_ac()
		
		print("      Spell Attack Roll: %d (1d20) + Bonus: %d = Total: %d vs AC %d" % [d20_roll, attack_bonus, total, target_ac])
		
		var degree = PFDice.determine_success(total, target_ac, d20_roll)
		match degree:
			PFDice.Degree.CRIT_SUCCESS:
				print("      *** CRITICAL HIT! ***")
			PFDice.Degree.SUCCESS:
				print("      * HIT! *")
			PFDice.Degree.FAIL, PFDice.Degree.CRIT_FAIL:
				print("      Miss.")
				
		spell.resolve_effect(user, target, degree, active_rank)
		
	elif spell.get_saving_throw() != &"":
		var save_type = spell.get_saving_throw()
		var spell_dc = user.get_spell_dc()
		
		var save_bonus = target.get_save_bonus(save_type)
		
		var d20_roll = PFDice.roll_d20()
		var total = d20_roll + save_bonus
		
		print("      Target rolls %s Save: %d (1d20) + Bonus: %d = Total: %d vs Spell DC %d" % [save_type.capitalize(), d20_roll, save_bonus, total, spell_dc])
		
		var degree = PFDice.determine_success(total, spell_dc, d20_roll)
		match degree:
			PFDice.Degree.CRIT_SUCCESS:
				print("      Target Critically Succeeds!")
			PFDice.Degree.SUCCESS:
				print("      Target Succeeds.")
			PFDice.Degree.FAIL:
				print("      Target Fails.")
			PFDice.Degree.CRIT_FAIL:
				print("      Target Critically Fails!")
				
		spell.resolve_effect(user, target, degree, active_rank)
		
	else:
		# Automatic effect
		spell.resolve_effect(user, target, PFDice.Degree.SUCCESS, active_rank)
		
	return true
