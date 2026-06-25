extends GutTest

class_name TestLevelUpService

func get_test_name() -> String:
	return "Level Up Sandbox Tests"

func test_level_up() -> void:
	print("\n--- Running Level Up Service Tests ---")
	
	PFContext.init_shared_services()
	
	var db = PFDatabase.get_instance()
	# Ensure the basic data is loaded
	var fighter_class = PFClass.new()
	fighter_class.entity_name = "Fighter"
	fighter_class.hp_per_level = 10
	fighter_class.key_abilities.append(&"STR")
	fighter_class.is_spellcaster = false
	
	var human_ancestry = PFAncestry.new()
	human_ancestry.id = &"human"
	human_ancestry.hp = 8
	human_ancestry.size_id = &"medium"
	
	var pc = PFPlayerCharacter.new("Fighter Bob", [&"humanoid", &"human"], 1, 0, 0, 0, 0)
	pc.attributes.apply_free_boost(&"str")
	pc.attributes.apply_free_boost(&"str")
	pc.attributes.apply_free_boost(&"str")
	pc.attributes.apply_free_boost(&"str")
	pc.attributes.apply_free_boost(&"con")
	pc.attributes.apply_free_boost(&"con") # con_mod = +2
	pc.actor_class = fighter_class
	pc.apply_ancestry(human_ancestry) # sets max_hp to 8, plus whatever class normally gives at level 1... wait, in PF2E level 1 HP is Ancestry + Class + Con
	pc.health.max_hp = 8 + 10 + 2 # 20
	pc.health.current_hp = 20
	
	# Give them basic proficiency
	pc.sheet.set_skill_rank(&"athletics", PFMathConstants.ProficiencyRank.TRAINED)
	
	print("\nInitial State: Level %d, Max HP: %d" % [pc.level, pc.health.max_hp])
	
	# Mock class progression for fighter
	db.query("INSERT OR IGNORE INTO class_progressions (class_id, level, granted_features, granted_feat_slots, granted_spells) VALUES ('fighter', 2, '[]', '[\"class\", \"skill\"]', '{}')")
	
	# 1. Generate Blueprint
	var blueprint = PFLevelUpManager.generate_level_up_blueprint(pc)
	
	assert_eq(blueprint["new_level"], 2, "Blueprint should be for level 2.")
	assert_eq(blueprint["hp_gain"], 11, "HP gain should be 10 (class) + 1 (con).")
	assert_eq(blueprint["skill_increases"], 1, "Should gain 1 skill increase at level 2.")
	
	# 2. Begin Sandbox
	var service = PFLevelUpService.new()
	service.begin_level_up(pc, blueprint)
	
	var preview = service.get_preview_stats()
	assert_eq(preview["hp"], 31, "Preview HP should be 20 + 11 = 31.")
	
	# 3. Test Toughness Feat
	# Assuming Toughness exists in DB... we need to ensure Toughness is in DB if we test it.
	# Let's insert a dummy Toughness feat for the test if it's missing
	db.query("INSERT OR IGNORE INTO feats (id, name, feat_type, level, traits, prerequisites, granted_rules, description) VALUES ('toughness', 'Toughness', 3, 1, '[]', '{}', '{}', '');")
	
	# Since blueprint has slots: 1 class, 1 skill.
	# Let's check the size of feat_slots
	var slots_count = blueprint["feat_slots"].size()
	assert_eq(slots_count, 2, "Fighter should gain 2 feat slots at level 2 if mock is populated.")
	
	var success = service.select_feat(0, &"toughness")
	assert_true(success, "Should successfully select Toughness.")
	
	preview = service.get_preview_stats()
	assert_eq(preview["hp"], 33, "Preview HP should increase by 2 (character level 2) with Toughness.")
	
	service.undo_feat(0)
	preview = service.get_preview_stats()
	assert_eq(preview["hp"], 31, "Preview HP should revert to 31 after undoing Toughness.")
	
	# 4. Test Skill Upgrade Validations
	success = service.select_skill(&"athletics")
	assert_true(success, "Should successfully select Athletics to upgrade to Expert at Level 2.")
	
	var second_success = service.select_skill(&"acrobatics")
	assert_false(second_success, "Should fail because we only had 1 skill increase.")
	
	# Try upgrading from Expert to Master at Level 2
	# Force athletics to Expert to simulate illegal upgrade attempt
	pc.sheet.set_skill_rank(&"athletics", PFMathConstants.ProficiencyRank.EXPERT)
	service.selected_skills.clear() # clear selections
	success = service.select_skill(&"athletics")
	assert_false(success, "Should fail to upgrade from Expert to Master at Level 2.")
	
	# Reset athletics to trained for final commit
	pc.sheet.skills[&"athletics"] = PFMathConstants.ProficiencyRank.TRAINED
	service.select_skill(&"athletics")
	
	# 5. Commit Transaction
	service.commit_transaction()
	
	assert_eq(pc.level, 2, "Character should now be level 2.")
	assert_eq(pc.health.max_hp, 31, "Character max HP should be permanently updated.")
	assert_eq(pc.sheet.get_skill_rank(&"athletics"), PFMathConstants.ProficiencyRank.EXPERT, "Athletics should be permanently upgraded to Expert.")
	assert_true(pc.progression_history.has(2), "Audit log should have an entry for Level 2.")
	
	var history = pc.progression_history[2]
	assert_eq(history["skill_increases"][0], &"athletics", "Audit log should record Athletics skill increase.")
	
	print("\nAll Level Up Service Tests Passed!")
	