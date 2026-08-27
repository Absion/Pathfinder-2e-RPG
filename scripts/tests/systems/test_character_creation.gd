extends GutTest

func before_all():
	PFContext.init_shared_services()

func test_character_creation_draft_remaster_attributes():
	var db = PFDatabase.get_instance()
	if db == null:
		db = PFDatabase.new()
		add_child_autofree(db)
		
	var manager = PFCharacterCreationManager.new()
	manager.draft_name = "Valeros"
	manager.draft_ancestry_id = "human"
	manager.draft_background_id = "warrior"
	manager.draft_class_id = "fighter"
	
	# Human: 2 Free boosts (e.g. STR, CON)
	manager.selected_ancestry_free_boosts = [&"str", &"con"]
	
	# Warrior Background: STR or CON + FREE (e.g. STR + DEX)
	manager.selected_background_boosts = [&"str", &"dex"]
	
	# Fighter Class: STR or DEX (e.g. STR)
	manager.selected_class_boost = &"str"
	
	# Level 1: 4 Free boosts (STR, DEX, CON, WIS)
	manager.selected_level_1_boosts = [&"str", &"dex", &"con", &"wis"]
	
	assert_true(manager.is_valid_character(), "Character draft should be valid.")
	
	var pc = autofree(manager.generate_draft_character())
	assert_not_null(pc, "Character should be generated successfully.")
	
	# Verify Remaster attribute modifiers:
	# STR: +1 (ancestry) +1 (background) +1 (class) +1 (level 1 free) = +4 mod
	assert_eq(pc.attributes.str_mod, 4, "STR mod should be +4.")
	
	# DEX: +1 (background) +1 (level 1 free) = +2 mod
	assert_eq(pc.attributes.dex_mod, 2, "DEX mod should be +2.")
	
	# CON: +1 (ancestry) +1 (level 1 free) = +2 mod
	assert_eq(pc.attributes.con_mod, 2, "CON mod should be +2.")
	
	# INT: 0 boosts = +0 mod
	assert_eq(pc.attributes.int_mod, 0, "INT mod should be +0.")
	
	# WIS: +1 (level 1 free) = +1 mod
	assert_eq(pc.attributes.wis_mod, 1, "WIS mod should be +1.")
	
	# CHA: 0 boosts = +0 mod
	assert_eq(pc.attributes.cha_mod, 0, "CHA mod should be +0.")

func test_invalid_free_boosts_with_duplicates():
	var manager = PFCharacterCreationManager.new()
	manager.draft_name = "Test"
	manager.draft_ancestry_id = "human"
	manager.draft_background_id = "warrior"
	manager.draft_class_id = "fighter"
	# Duplicate STR boosts in level 1 free boosts (illegal)
	manager.selected_level_1_boosts = [&"str", &"str", &"con", &"wis"]
	
	assert_false(manager.is_valid_character(), "Character draft with duplicate free boosts should be invalid.")

func test_ancestry_with_fixed_boosts():
	var db = PFDatabase.get_instance()
	if db == null:
		db = PFDatabase.new()
		add_child_autofree(db)
		
	var ancestry = db.get_ancestry("bullfolk")
	if ancestry != null:
		var manager = PFCharacterCreationManager.new()
		manager.draft_name = "Minotaur"
		manager.draft_ancestry_id = "bullfolk"
		manager.draft_background_id = "warrior"
		manager.draft_class_id = "fighter"
		
		# Free ancestry boost for Bullfolk: picking DEX (valid, STR/CON are fixed)
		manager.selected_ancestry_free_boosts = [&"dex"]
		manager.selected_background_boosts = [&"str", &"wis"]
		manager.selected_class_boost = &"str"
		manager.selected_level_1_boosts = [&"str", &"dex", &"con", &"cha"]
		
		var pc = autofree(manager.generate_draft_character())
		assert_not_null(pc)
		# Bullfolk: +1 STR, +1 CON, -1 CHA fixed. +1 DEX free.
		# Background: +1 STR, +1 WIS
		# Class: +1 STR
		# Level 1 Free: +1 STR, +1 DEX, +1 CON, +1 CHA
		# Final STR: +4, DEX: +2, CON: +2, INT: +0, WIS: +1, CHA: -1 + 1 = +0
		assert_eq(pc.attributes.str_mod, 4)
		assert_eq(pc.attributes.dex_mod, 2)
		assert_eq(pc.attributes.con_mod, 2)
		assert_eq(pc.attributes.int_mod, 0)
		assert_eq(pc.attributes.wis_mod, 1)
		assert_eq(pc.attributes.cha_mod, 0)

func test_background_skills_and_lores():
	var db = PFDatabase.get_instance()
	if db == null:
		db = PFDatabase.new()
		add_child_autofree(db)
		
	var manager = PFCharacterCreationManager.new()
	manager.draft_name = "Cleric Jane"
	manager.draft_ancestry_id = "human"
	manager.draft_background_id = "acolyte"
	manager.draft_class_id = "cleric"
	
	manager.selected_ancestry_free_boosts = [&"wis", &"cha"]
	manager.selected_background_boosts = [&"wis", &"con"]
	manager.selected_class_boost = &"wis"
	manager.selected_level_1_boosts = [&"wis", &"cha", &"con", &"str"]
	
	var pc = autofree(manager.generate_draft_character())
	assert_not_null(pc)
	
	# Acolyte grants trained religion and scribing lore
	assert_eq(pc.sheet.get_skill_rank(&"religion"), PFMathConstants.ProficiencyRank.TRAINED, "Acolyte should grant trained Religion.")
	assert_eq(pc.sheet.get_skill_rank(&"scribing_lore"), PFMathConstants.ProficiencyRank.TRAINED, "Acolyte should grant trained Scribing Lore.")

func test_language_granting_and_bonus_languages():
	var db = PFDatabase.get_instance()
	if db == null:
		db = PFDatabase.new()
		add_child_autofree(db)
		
	var manager = PFCharacterCreationManager.new()
	manager.draft_name = "Bullfolk Wizard"
	manager.draft_ancestry_id = "bullfolk"
	manager.draft_background_id = "scholar"
	manager.draft_class_id = "wizard"
	
	var pc = autofree(manager.generate_draft_character())
	assert_not_null(pc)
	
	# Character should automatically know Common and Bullfolk
	assert_true(pc.languages.has(&"common"), "Character must know Common by default.")
	assert_true(pc.languages.has(&"bullfolk"), "Bullfolk character must know Bullfolk language by default.")

func test_ancestry_specific_languages():
	var db = PFDatabase.get_instance()
	if db == null:
		db = PFDatabase.new()
		add_child_autofree(db)
		
	var catfolk_anc = db.get_ancestry("catfolk")
	assert_not_null(catfolk_anc)
	assert_true(catfolk_anc.known_languages.has(&"catfolk"))
	
	var leshy_anc = db.get_ancestry("leshy")
	assert_not_null(leshy_anc)
	assert_true(leshy_anc.known_languages.has(&"fey"))
	
	var kobold_anc = db.get_ancestry("kobold")
	assert_not_null(kobold_anc)
	assert_true(kobold_anc.known_languages.has(&"fey"))
	
	var titanborn_anc = db.get_ancestry("titanborn")
	assert_not_null(titanborn_anc)
	assert_true(titanborn_anc.known_languages.has(&"jotun"))

func after_all():
	PFContext.cleanup_shared_services()

