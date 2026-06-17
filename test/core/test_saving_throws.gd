# test_saving_throws.gd
extends GdUnitTestSuite

var db: PFDatabase

func before() -> void:
	if not Engine.get_main_loop().root.has_node("PFDatabase"):
		db = PFDatabase.new()
		db.name = "PFDatabase"
		Engine.get_main_loop().root.add_child(db)
		db._ready()
	else:
		db = PFDatabase.get_instance()

func after():
	# don't close here if we are reusing it across tests
	pass

func test_player_character_fortitude_save():
	var pc = auto_free(PFPlayerCharacter.new("Saver", [], 1, 15, 0, 0, 0))
	add_child(pc)
	
	# Let's set Constitution modifier to +3
	pc.attributes.apply_free_boost(&"con")
	pc.attributes.apply_class_boost(&"con")
	pc.attributes.apply_background_boost(&"con")
	
	# Let's set Fortitude proficiency to TRAINED (rank 1)
	pc.sheet.set_save_rank(&"fort", PFMathConstants.ProficiencyRank.TRAINED)
	
	# Expected Calculation for Level 1 PC:
	# Level (1) + Proficiency (2) + Con Mod (3) = +6
	var fort = pc.get_save_bonus(&"fort")
	assert_int(fort).is_equal(6)
	
	# Add an item bonus
	pc.attributes.fort_save.add_modifier(PFModifier.new(1, PFMathConstants.ModifierType.ITEM, "Belt of Health"))
	fort = pc.get_save_bonus(&"fort")
	assert_int(fort).is_equal(7)

func test_npc_reflex_save():
	var npc = auto_free(PFNpc.new("Goblin", [], 1, 6, 4, 7, 1, 0, 0, 0, 0, 0, 0))
	add_child(npc)
	
	# NPCs should use their static base saves (from initialization / statblock)
	# The Goblin was initialized with Reflex = 7
	var ref = npc.get_save_bonus(&"reflex")
	assert_int(ref).is_equal(7)
	
	# Add a status penalty
	npc.attributes.item_penalty_to_save = 2
	ref = npc.get_save_bonus(&"reflex")
	assert_int(ref).is_equal(5)

func test_spell_dc_calculation():
	var pc = auto_free(PFPlayerCharacter.new("Wizard", [], 3, 20, 0, 0, 0))
	add_child(pc)
	
	pc.actor_class = PFClass.new()
	pc.actor_class.is_spellcaster = true
	pc.actor_class.spell_proficiency = PFMathConstants.ProficiencyRank.EXPERT
	var keys: Array[StringName] = [&"INT"]
	pc.actor_class.key_abilities = keys
	
	pc.attributes.apply_free_boost(&"int")
	pc.attributes.apply_class_boost(&"int")
	pc.attributes.apply_background_boost(&"int")
	pc.attributes.apply_ancestry_boost(&"int")
	
	# Expected: 10 + Level (3) + Expert (4) + Int (4) = 21
	var dc = pc.get_spell_dc()
	assert_int(dc).is_equal(21)
