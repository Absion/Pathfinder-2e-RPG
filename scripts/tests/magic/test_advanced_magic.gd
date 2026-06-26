# test_advanced_magic.gd
extends GutTest

var counteract_manager: PFCounteractManager
var turn_manager: PFTurnManager
var time_manager: PFTimeManager

var caster: PFActor
var target: PFActor

func before_each():
	# Ensure the DB is fully initialized and singletons are ready
	PFDatabase.get_instance()._initialize_schema_if_needed()
	
	PFContext.init_shared_services()
	
	# Instantiate specific managers for direct testing
	counteract_manager = PFContext.counteract_manager
	turn_manager = autofree(PFTurnManager.new())
	PFContext.active_turn_manager = turn_manager
		
	time_manager = PFTimeManager.get_instance()
	if not time_manager:
		time_manager = autofree(PFTimeManager.new())
		time_manager._ready()
		
	caster = autofree(PFPlayerCharacter.new("Caster", [&"humanoid"], 1, 10, 0, 0, 0))
	target = autofree(PFPlayerCharacter.new("Target", [&"humanoid"], 1, 10, 0, 0, 0))
	
	caster.actor_class = PFClass.new("Wizard")
	caster.actor_class.caster_type = PFMagicConstants.CasterType.SPONTANEOUS
	
	var sb = PFSpellbook.new(caster)
	var rep = PFSpellcastingReceptacle.new(&"mock", PFMagicConstants.MagicTradition.ARCANE, PFMagicConstants.CasterType.SPONTANEOUS)
	rep.spells_per_rank[1] = 3
	rep.restore_slots()
	sb.add_receptacle(rep)
	caster.set(&"spellbook", sb)

func after_each():
	pass

func test_counteract_math():
	# 3rd rank Dispel Magic vs 4th rank spell
	# Target Rank: 4, Target DC: 20
	# Source Rank: 3
	
	# Crit Success (Source + 3 >= 4) -> 3 + 3 = 6 >= 4 -> True
	assert_true(counteract_manager.roll_counteract(3, 30, 20, 4))
	
	# Success (Source + 1 >= 4) -> 3 + 1 = 4 >= 4 -> True
	assert_true(counteract_manager.roll_counteract(3, 22, 20, 4))
	
	# Failure (Target < Source) -> 4 < 3 -> False
	assert_false(counteract_manager.roll_counteract(3, 19, 20, 4))
	
	# Crit Failure
	assert_false(counteract_manager.roll_counteract(3, 5, 20, 4))
	
	# Now let's try a 1st rank trying to counteract a 5th rank
	# Crit success -> Source (1) + 3 = 4 >= 5 -> False! A nat 20 still fails here.
	assert_false(counteract_manager.roll_counteract(1, 35, 20, 5))

func test_sustained_spells():
	var spell = PFSpell.new(&"illusory_object")
	spell.is_sustained = true
	caster.spellbook.known_spells.append(spell)
	caster.spellbook.receptacles[0].add_to_repertoire(spell, 1)
	caster.spellbook.receptacles[0].restore_slots()
	
	# Start encounter
	turn_manager.add_combatant(caster, false)
	turn_manager.add_combatant(target, true)
	turn_manager.start_encounter()
	
	assert_true(turn_manager.get_current_actor() == caster)
	
	# Cast spell
	assert_true(caster.spellbook.cast_spell(spell, null, 1))
	
	# Verify it's registered
	assert_true(turn_manager.active_sustained_spells.has(caster))
	assert_true(turn_manager.active_sustained_spells[caster].has(spell))
	
	# End turn without sustaining
	turn_manager.next_turn()
	
	# Wait, it was cast THIS turn, so it's in spells_sustained_this_turn.
	# Next turn is target's turn.
	assert_true(turn_manager.get_current_actor() == target)
	# The spell should STILL be active because caster hasn't ended a turn without sustaining it yet.
	assert_true(turn_manager.active_sustained_spells.has(caster))
	
	# Target ends turn
	turn_manager.next_turn()
	
	# Caster's turn again (Round 2)
	assert_true(turn_manager.get_current_actor() == caster)
	
	# Now the caster just ends their turn without sustaining
	turn_manager.next_turn()
	
	# The spell should be dropped!
	assert_false(turn_manager.active_sustained_spells.has(caster))
	
	# Let's test actually sustaining it
	caster.spellbook.receptacles[0].restore_slots()
	caster.spellbook.cast_spell(spell, null, 1)
	assert_true(turn_manager.active_sustained_spells.has(caster))
	
	# Advance to target's turn
	turn_manager.next_turn()
	# Advance back to caster's turn
	turn_manager.next_turn()
	
	# Caster sustains it!
	var sustain_action = PFActionSustain.new(spell)
	sustain_action.execute(caster)
	
	# Advance to target's turn
	turn_manager.next_turn()
	
	# Should still be active!
	assert_true(turn_manager.active_sustained_spells.has(caster))

func test_focus_points():
	caster.spellbook.increase_max_focus_points(1)
	caster.spellbook.increase_max_focus_points(1)
	caster.spellbook.increase_max_focus_points(2) # Should cap at 3
	assert_eq(caster.spellbook.max_focus_points, 3)
	
	caster.spellbook.restore_daily_slots() # fills to 3
	assert_eq(caster.spellbook.focus_points, 3)
	
	# Spend one
	assert_true(caster.spellbook.spend_focus_point())
	assert_eq(caster.spellbook.focus_points, 2)
	
	# Refocus action
	var refocus = PFActionRefocus.new()
	var initial_time = time_manager.current_time_seconds
	refocus.execute(caster)
	
	assert_eq(caster.spellbook.focus_points, 3)
	
	# 10 minutes should have passed (600 seconds)
	assert_eq(time_manager.current_time_seconds, initial_time + 600)

func after_all():
	PFContext.cleanup_shared_services()
