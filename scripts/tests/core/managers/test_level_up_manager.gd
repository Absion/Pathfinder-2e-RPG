# test_level_up_manager.gd
class_name TestLevelUpManager
extends GutTest

var database: PFDatabase

func before_all():
	PFContext.init_shared_services()
	database = PFDatabase.get_instance()
	
	database.query("REPLACE INTO class_progressions (class_id, level, granted_features, granted_feat_slots, granted_spells) VALUES ('wizard', 2, '[]', '[\"class\", \"skill\"]', '{\"spells_learned\": 2}')")
	database.query("REPLACE INTO class_progressions (class_id, level, granted_features, granted_feat_slots, granted_spells) VALUES ('wizard', 3, '[]', '[\"skill\"]', '{}')")
	database.query("REPLACE INTO class_progressions (class_id, level, granted_features, granted_feat_slots, granted_spells) VALUES ('wizard', 4, '[]', '[\"class\", \"skill\"]', '{}')")

func after_all():
	PFContext.cleanup_shared_services()
	if is_instance_valid(database):
		pass # database.queue_free()

func test_level_up_manager():
	var hero = autofree(PFPlayerCharacter.new("Valeros", [&"human", &"fighter"], 1, 20, 2, 2, 2))
	hero.apply_class(&"wizard")
	
	# Verify Wizard HP applied correctly (Level 1)
	assert_eq(hero.health.max_hp, 26) # 20 (base) + 6 (wizard hp)
	
	# Mock DB with a spell progression done in before_all
	
	# Simulate Level Up
	var pending_choices = PFLevelUpManager.generate_level_up_blueprint(hero)
	hero.level += 1
	hero.health.max_hp += pending_choices["hp_gain"]
	
	# Verify Level bumped
	assert_eq(hero.level, 2)
	
	# Verify HP gain (Level 2)
	assert_eq(hero.health.max_hp, 32) # 26 + 6
	
	# Verify Choices from class progression
	assert_has(pending_choices["feat_slots"], &"class")
	assert_has(pending_choices["feat_slots"], &"skill")
	if pending_choices.has("spells_learned"):
		assert_eq(pending_choices["spells_learned"], 2)
	else:
		assert_true(false, "spells_learned not in pending_choices! Actual: " + str(pending_choices))

func test_experience_tracker():
	var hero = autofree(PFPlayerCharacter.new("Valeros", [&"human", &"fighter"], 1, 20, 2, 2, 2))
	hero.apply_class(&"wizard")
	
	assert_eq(hero.level, 1)
	assert_eq(hero.experience_points, 0)
	
	# Gain 500 XP (no level up)
	hero.gain_experience(500)
	assert_eq(hero.level, 1)
	assert_eq(hero.experience_points, 500)
	
	# Gain 700 XP (level up, 200 carry over)
	hero.gain_experience(700)
	assert_eq(hero.level, 2)
	assert_eq(hero.experience_points, 200)
	assert_eq(hero.pending_level_up_choices.size(), 1)
	
	# Gain 2000 XP (two level ups, 200 carry over)
	hero.gain_experience(2000)
	assert_eq(hero.level, 4)
	assert_eq(hero.experience_points, 200)
	assert_eq(hero.pending_level_up_choices.size(), 3)


