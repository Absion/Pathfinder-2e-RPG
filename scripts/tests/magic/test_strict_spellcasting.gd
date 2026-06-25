extends GutTest
var db: PFDatabase

func before_all() -> void:
	PFContext.init_shared_services()
	db = PFDatabase.get_instance()
	PFContext.environment_manager = PFEnvironmentManager.new()
	
	db._spells_cache[&"magic_missile"] = {
		"name": "Magic Missile", "traits": "attack", "base_spell_rank": 1, 
		"cast_time": "1 to 3", "range_ft": 120, "targets": "1 creature", "saving_throw": "", 
		"duration": "", "is_cantrip": 0, "description": "Missile", "scaling_rules": 1, "scaling_dice": 1
	}
	db._spells_cache[&"fireball"] = {
		"name": "Fireball", "traits": "fire", "base_spell_rank": 3, 
		"cast_time": "2", "range_ft": 500, "targets": "20-foot burst", "saving_throw": "reflex", 
		"duration": "", "is_cantrip": 0, "description": "Boom", "scaling_rules": 1, "scaling_dice": 2
	}
	db._spells_cache[&"grease"] = {
		"name": "Grease", "traits": "", "base_spell_rank": 1, 
		"cast_time": "2", "range_ft": 30, "targets": "1 area", "saving_throw": "reflex", 
		"duration": "1 minute", "is_cantrip": 0, "description": "Slippery", "scaling_rules": 0, "scaling_dice": 0
	}
	db._spells_cache[&"heal"] = {
		"name": "Heal", "traits": "healing", "base_spell_rank": 1, 
		"cast_time": "1 to 3", "range_ft": 30, "targets": "1 creature", "saving_throw": "", 
		"duration": "", "is_cantrip": 0, "description": "Heals", "scaling_rules": 1, "scaling_dice": 1
	}
	db._spells_cache[&"rare_heal"] = {
		"name": "Rare Heal", "traits": "healing", "base_spell_rank": 1, 
		"cast_time": "1 to 3", "range_ft": 30, "targets": "1 creature", "saving_throw": "", 
		"duration": "", "is_cantrip": 0, "description": "Heals", "scaling_rules": 1, "scaling_dice": 1
	}

func test_prepared_spellcasting():
	var char_class = PFClass.new("Wizard", 6, [&"intelligence"])
	char_class.caster_type = PFMagicConstants.CasterType.PREPARED
	char_class.spell_progression = PFMagicConstants.SpellProgression.FULL_CASTER
	
	var caster = PFPlayerCharacter.new("Prepared Mage", [&"humanoid"], 1, 10, 0, 0, 0)
	caster.actor_class = char_class
	caster.level = 1
	var spellbook = PFSpellbook.new(caster)
	caster.set(&"spellbook", spellbook)
	
	# Full Caster at level 1 gets 2 Rank 1 slots
	assert_eq(spellbook.get_max_slots(1), 2)
	
	# Create a spell
	var magic_missile = PFSpell.new(&"magic_missile")
	magic_missile.base_spell_rank = 1
	
	# 1. Try to prepare before learning
	assert_false(spellbook.prepare_spell(magic_missile, 1))
	
	# Learn it
	spellbook.learn_spell(magic_missile)
	
	# 2. Try to prepare it now
	assert_true(spellbook.prepare_spell(magic_missile, 1))
	
	# 3. Prepare it again (takes up 2nd slot)
	assert_true(spellbook.prepare_spell(magic_missile, 1))
	
	# 4. Try to prepare it a 3rd time (should fail, max slots = 2)
	assert_false(spellbook.prepare_spell(magic_missile, 1))
	
	# 5. Try to cast un-prepared spell
	var fireball = PFSpell.new(&"fireball")
	fireball.base_spell_rank = 3
	spellbook.learn_spell(fireball)
	spellbook.extra_slots[3] = 1 # hack to give slot
	assert_false(spellbook.cast_spell(fireball, 3)) # Cannot cast, not prepared
	
	# 6. Cast magic missile once
	assert_true(spellbook.cast_spell(magic_missile, 1))
	
	# 7. Cast magic missile twice
	assert_true(spellbook.cast_spell(magic_missile, 1))
	
	# 8. Cast magic missile third time (fails, slots empty)
	assert_false(spellbook.cast_spell(magic_missile, 1))

func test_spontaneous_spellcasting():
	var char_class = PFClass.new("Sorcerer", 6, [&"charisma"])
	char_class.caster_type = PFMagicConstants.CasterType.SPONTANEOUS
	char_class.spell_progression = PFMagicConstants.SpellProgression.FULL_CASTER
	
	var caster = PFPlayerCharacter.new("Spontaneous Mage", [&"humanoid"], 3, 20, 0, 0, 0)
	caster.actor_class = char_class
	caster.level = 3 # Level 3 full caster gets 3 Rank 1, 2 Rank 2
	var spellbook = PFSpellbook.new(caster)
	caster.set(&"spellbook", spellbook)
	spellbook.restore_daily_slots()
	
	var magic_missile = PFSpell.new(&"magic_missile")
	magic_missile.base_spell_rank = 1
	var fireball = PFSpell.new(&"fireball")
	fireball.base_spell_rank = 2 # fake rank 2 fireball for test
	
	spellbook.learn_spell(magic_missile)
	spellbook.learn_spell(fireball)
	
	# Add to repertoire
	assert_true(spellbook.add_to_repertoire(magic_missile, 1))
	assert_true(spellbook.add_to_repertoire(fireball, 2))
	
	# 1. Cast magic missile at rank 1 (success)
	assert_true(spellbook.cast_spell(magic_missile, 1))
	assert_eq(spellbook.current_slots[1], 2)
	
	# 2. Try to cast magic missile at rank 2 (fails, not in rank 2 repertoire and not signature)
	assert_false(spellbook.cast_spell(magic_missile, 2))
	
	# 3. Set magic missile as signature
	assert_true(spellbook.set_signature_spell(magic_missile))
	
	# 4. Try to set another signature for rank 1
	var grease = PFSpell.new(&"grease")
	grease.base_spell_rank = 1
	spellbook.learn_spell(grease)
	assert_false(spellbook.set_signature_spell(grease)) # Cannot have 2 signature spells for rank 1
	
	# 5. Cast magic missile at rank 2 (success because it is signature now)
	assert_true(spellbook.cast_spell(magic_missile, 2))
	assert_eq(spellbook.current_slots[2], 1)
	
	# 6. Cast fireball at rank 2
	assert_true(spellbook.cast_spell(fireball, 2))
	assert_eq(spellbook.current_slots[2], 0)
	
	# 7. Cast fireball again at rank 2 (fails, out of slots)
	assert_false(spellbook.cast_spell(fireball, 2))

func test_learn_a_spell_action():
	var char_class = PFClass.new("Wizard", 6, [&"intelligence"])
	char_class.caster_type = PFMagicConstants.CasterType.PREPARED
	
	var caster = PFPlayerCharacter.new("Student", [&"humanoid"], 1, 10, 0, 0, 0)
	caster.actor_class = char_class
	caster.level = 1
	var spellbook = PFSpellbook.new(caster)
	caster.set(&"spellbook", spellbook)
	
	caster.inventory.gold = 10 # Rank 1 costs 2 GP
	
	var spell = PFSpell.new(&"magic_missile")
	spell.base_spell_rank = 1
	
	var learn_action = PFActionLearnSpell.new(spell)
	var est = learn_action.estimate(caster)
	
	assert_eq(est["cost_gp"], 2)
	assert_eq(est["dc"], 15)
	
	# Fail intentionally (Not enough gold)
	caster.inventory.gold = 1
	assert_false(learn_action.execute(caster))
	assert_false(spellbook.known_spells.has(spell))
	
	# Give plenty of gold
	caster.inventory.gold = 100
	
	# Keep executing until success or critical success
	var success = false
	for i in range(100):
		if learn_action.execute(caster):
			success = true
	
	assert_true(success)
	assert_true(spellbook.known_spells.has(spell))

func test_divine_spellcasting():
	var char_class = PFClass.new("Cleric", 8, [&"wisdom"])
	char_class.caster_type = PFMagicConstants.CasterType.PREPARED
	char_class.spell_tradition = PFMagicConstants.MagicTradition.DIVINE
	char_class.spell_progression = PFMagicConstants.SpellProgression.FULL_CASTER
	
	var caster = PFPlayerCharacter.new("Priest", [&"humanoid"], 1, 10, 0, 0, 0)
	caster.actor_class = char_class
	caster.level = 1
	var spellbook = PFSpellbook.new(caster)
	caster.set(&"spellbook", spellbook)
	
	# Common divine spell
	var heal_spell = PFSpell.new(&"heal")
	heal_spell.base_spell_rank = 1
	heal_spell.rarity = PFBiographyConstants.Rarity.COMMON
	
	# Cleric should be able to prepare it WITHOUT learning it
	assert_true(spellbook.prepare_spell(heal_spell, 1))
	
	# Uncommon divine spell
	var rare_spell = PFSpell.new(&"rare_heal")
	rare_spell.base_spell_rank = 1
	rare_spell.rarity = PFBiographyConstants.Rarity.UNCOMMON
	
	# Cleric should NOT be able to prepare uncommon spell without learning it
	assert_false(spellbook.prepare_spell(rare_spell, 1))
	
	# After learning it, they can
	spellbook.learn_spell(rare_spell)
	assert_true(spellbook.prepare_spell(rare_spell, 1))
