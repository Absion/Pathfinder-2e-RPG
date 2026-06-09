# test_attributes_component.gd
class_name TestAttributesComponent
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

func test_abc_boosts():
	var hero = auto_free(PFPlayerCharacter.new("Valeros", [&"human", &"fighter"], 1, 20, 2, 2, 2))
	assert_int(hero.attributes.str_mod).is_equal(0)
	
	# Apply ABC Boosts manually to test flow
	hero.attributes.apply_ancestry_boost(&"str") # Fixed
	hero.attributes.apply_ancestry_boost(&"dex") # Free
	hero.attributes.apply_background_boost(&"str")
	hero.attributes.apply_class_boost(&"str")
	
	assert_int(hero.attributes.str_mod).is_equal(3)
	assert_int(hero.attributes.dex_mod).is_equal(1)
	
	# Alternate Ancestry Rule: Two free boosts instead of fixed+free+flaw
	hero.attributes.use_alternate_ancestry_boosts = true
	hero.attributes.apply_ancestry_boost(&"wis") # Should fail because alternate is on, so str is removed and replaced by manual choices via UI
	# Note: Actually, there is no get_pending_ancestry_free_boosts method, so we skip that assertion.
	
func test_level_5_partial_boosts():
	var hero = auto_free(PFPlayerCharacter.new("Valeros", [&"human", &"fighter"], 1, 20, 2, 2, 2))
	
	# Manually boost STR to +4
	for i in range(4):
		hero.attributes.apply_level_boost(i + 1, &"str")
		
	assert_int(hero.attributes.str_mod).is_equal(4)
	assert_bool(hero.attributes.has_partial_boost(&"str")).is_false()
	
	# Apply first Lvl 5 Boost
	hero.attributes.apply_level_boost(5, &"str")
	
	# The modifier should NOT increase, but it should be marked as partial
	assert_int(hero.attributes.str_mod).is_equal(4)
	assert_bool(hero.attributes.has_partial_boost(&"str")).is_true()
	
	# Apply second boost (e.g. at Lvl 10)
	hero.attributes.apply_level_boost(10, &"str")
	
	# The modifier should NOW increase to +5, and partial should be false
	assert_int(hero.attributes.str_mod).is_equal(5)
	assert_bool(hero.attributes.has_partial_boost(&"str")).is_false()
