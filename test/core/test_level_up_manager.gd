# test_level_up_manager.gd
class_name TestLevelUpManager
extends GdUnitTestSuite

var db: PFDatabase

func before():
	db = PFDatabase.get_instance()
	if db == null:
		db = preload("res://scripts/database/pf_database.gd").new()
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
	
	# Simulate Level Up
	var pending_choices = PFLevelUpManager.level_up(hero)
	
	# Verify Level bumped
	assert_int(hero.level).is_equal(2)
	
	# Verify HP gain (Level 2)
	assert_int(hero.health.max_hp).is_equal(32) # 26 + 6
	
	# Verify Choices from class progression
	assert_array(pending_choices["feat_slots"]).contains(["class", "skill"])
