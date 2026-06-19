extends GdUnitTestSuite

var db: PFDatabase
var caster: PFActor
var target: PFActor

func before() -> void:
	if not Engine.get_main_loop().root.has_node("PFDatabase"):
		db = PFDatabase.new()
		db.name = "PFDatabase"
		Engine.get_main_loop().root.add_child(db)
		db._ready()
	else:
		db = PFDatabase.get_instance()
		
	# Insert mock spells directly into the cache to avoid schema limitations during testing
	db._spells_cache["mock_ignition"] = {
		"name": "Ignition", "traits": '["attack", "fire", "cantrip"]', "base_spell_rank": 1, 
		"cast_time": "2", "range_ft": 30, "targets": "1 creature", "saving_throw": "", 
		"duration": "", "is_cantrip": 1, "description": "Fire damage",
		"scaling_rules": 1, "scaling_dice": 1
	}
	db._spells_cache["mock_fireball"] = {
		"name": "Fireball", "traits": '["fire"]', "base_spell_rank": 3, 
		"cast_time": "2", "range_ft": 500, "targets": "20-foot burst", "saving_throw": "reflex", 
		"duration": "", "is_cantrip": 0, "description": "Fireball boom",
		"scaling_rules": 1, "scaling_dice": 2
	}
	db._spells_cache["mock_lay_on_hands"] = {
		"name": "Lay on Hands", "traits": '["focus", "healing"]', "base_spell_rank": 1, 
		"cast_time": "1", "range_ft": 0, "targets": "1 willing creature", "saving_throw": "", 
		"duration": "", "is_cantrip": 0, "description": "Healing",
		"scaling_rules": 1, "scaling_dice": 1
	}

func before_test() -> void:
	caster = auto_free(PFPlayerCharacter.new("Caster", [], 5, 50, 0, 0, 0)) # Level 5 character
	target = auto_free(PFPlayerCharacter.new("Target", [], 5, 50, 0, 0, 0))
	
	add_child(caster)
	add_child(target)
	
	# Mock spellcaster class
	var mock_class = PFClass.new()
	mock_class.is_spellcaster = true
	caster.actor_class = mock_class
	
	var sb = PFSpellbook.new(caster)
	caster.set(&"spellbook", sb)
	sb.max_focus_points = 2
	sb.focus_points = 2
	sb.current_slots[1] = 2
	sb.current_slots[3] = 2
	sb.current_slots[4] = 1

func test_spell_attack_cantrip() -> void:
	var spell = PFIgnitionSpell.new("mock_ignition")
	spell.damage_dice = 2
	spell.die_faces = 4
	spell.damage_type = PFCombatConstants.DamageType.FIRE
	
	# Equip a spellbook with spell attack bonus
	# Force an attack roll that always hits
	var sb = caster.get(&"spellbook") as PFSpellbook
	
	# Caster spell attack vs Target AC
	# Give caster +50 to spell attacks to force a critical hit
	caster.attributes.attack_modifiers.add_modifier(PFModifier.new(50, PFMathConstants.ModifierType.ITEM, "test_boost"))
	
	var action = PFActionCastSpell.new(spell)
	
	var initial_hp = target.health.current_hp
	assert_bool(action.execute(caster, target)).is_true()
	
	# As a level 5 caster, cantrip heightens to Rank 3. Base rank 1. Difference = 2 ranks.
	# Scaling is +1 dice per 1 rank. So +2 dice. Total = 4 dice.
	# Since it's a critical hit (50+ roll vs AC 10), damage is doubled
	var new_hp = target.health.current_hp
	var damage_taken = initial_hp - new_hp
	
	# 4d4 damage * 2 (crit) = min 8, max 32
	assert_int(damage_taken).is_between(8, 32)
	
	# As a cantrip, it should not consume slots
	assert_int(sb.current_slots.get(1, 0)).is_equal(2)

func test_saving_throw_spell() -> void:
	var spell = PFSpell.new("mock_fireball")
	spell.damage_dice = 6
	spell.die_faces = 6
	spell.damage_type = PFCombatConstants.DamageType.FIRE
	
	var sb = caster.get(&"spellbook") as PFSpellbook
	
	# Force the target to critically fail the save
	# Caster spell DC = 10, Target save bonus = -50
	target.attributes.fort_save.add_modifier(PFModifier.new(-50, PFMathConstants.ModifierType.ITEM, "test_penalty"))
	target.attributes.ref_save.add_modifier(PFModifier.new(-50, PFMathConstants.ModifierType.ITEM, "test_penalty"))
	target.attributes.will_save.add_modifier(PFModifier.new(-50, PFMathConstants.ModifierType.ITEM, "test_penalty"))
	
	# Test casting it at Rank 4! (Heightened)
	var action = PFActionCastSpell.new(spell, 4)
	var initial_hp = target.health.current_hp
	assert_bool(action.execute(caster, target)).is_true()
	
	# Fireball is base Rank 3, cast at Rank 4. Heightened (+1) adds 2d6 damage.
	# Total dice = 8d6.
	# Crit fail on a save spell = double damage
	var damage_taken = initial_hp - target.health.current_hp
	
	# 8d6 * 2 = min 16, max 96
	assert_int(damage_taken).is_between(16, 96)
	
	# As a rank 4 spell, it should consume a rank 4 slot
	assert_int(sb.current_slots.get(4, 0)).is_equal(0) # Base had 1, consumed 1

func test_focus_points() -> void:
	var spell = PFSpell.new("mock_lay_on_hands")
	var sb = caster.get(&"spellbook") as PFSpellbook
	
	assert_int(sb.focus_points).is_equal(2)
	
	var action = PFActionCastSpell.new(spell)
	assert_bool(action.execute(caster, caster)).is_true()
	
	assert_int(sb.focus_points).is_equal(1)
	
	assert_bool(action.execute(caster, caster)).is_true()
	assert_int(sb.focus_points).is_equal(0)
	
	# Trying to cast again should fail
	assert_bool(action.execute(caster, caster)).is_false()
	
	# Refocus
	sb.refocus()
	assert_int(sb.focus_points).is_equal(1)
