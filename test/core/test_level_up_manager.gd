# test_level_up_manager.gd
class_name TestLevelUpManager
extends GdUnitTestSuite

var db: PFDatabase

func before():
	db = PFDatabase.get_instance()
	if db == null:
		db = PFDatabase.new()
		db.name = "PFDatabase"
		Engine.get_main_loop().root.add_child(db)
		db._ready()

func after():
	if is_instance_valid(db):
		db.queue_free()

func test_level_up_manager():
	var hero = auto_free(PFPlayerCharacter.new("Valeros", [&"human", &"fighter"], 1, 20, 2, 2, 2))
	hero.apply_class(&"wizard")
	
	# Verify Wizard HP applied correctly (Level 1)
	assert_int(hero.health.max_hp).is_equal(26) # 20 (base) + 6 (wizard hp)
	
	# Mock DB with a spell progression
	db.query("INSERT INTO class_progressions (class_id, level, granted_features, granted_feat_slots, granted_spells) VALUES ('wizard', 2, '[]', '[\"class\", \"skill\"]', '{\"spells_learned\": 2}')")
	
	# Simulate Level Up
	var pending_choices = PFLevelUpManager.generate_level_up_blueprint(hero)
	hero.level += 1
	hero.health.max_hp += pending_choices["hp_gain"]
	
	# Verify Level bumped
	assert_int(hero.level).is_equal(2)
	
	# Verify HP gain (Level 2)
	assert_int(hero.health.max_hp).is_equal(32) # 26 + 6
	
	# Verify Choices from class progression
	assert_array(pending_choices["feat_slots"]).contains(["class", "skill"])
	assert_int(pending_choices["spells_learned"]).is_equal(2)

func test_experience_tracker():
	var hero = auto_free(PFPlayerCharacter.new("Valeros", [&"human", &"fighter"], 1, 20, 2, 2, 2))
	hero.apply_class(&"wizard")
	
	assert_int(hero.level).is_equal(1)
	assert_int(hero.experience_points).is_equal(0)
	
	# Gain 500 XP (no level up)
	hero.gain_experience(500)
	assert_int(hero.level).is_equal(1)
	assert_int(hero.experience_points).is_equal(500)
	
	# Gain 700 XP (level up, 200 carry over)
	hero.gain_experience(700)
	assert_int(hero.level).is_equal(2)
	assert_int(hero.experience_points).is_equal(200)
	assert_int(hero.pending_level_up_choices.size()).is_equal(1)
	
	# Gain 2000 XP (two level ups, 200 carry over)
	hero.gain_experience(2000)
	assert_int(hero.level).is_equal(4)
	assert_int(hero.experience_points).is_equal(200)
	assert_int(hero.pending_level_up_choices.size()).is_equal(3)

