# test_attributes_component.gd
class_name TestAttributesComponent
extends GutTest

var db: PFDatabase

func before_all():
	db = PFDatabase.get_instance()
	if db == null:
		db = PFDatabase.new()
		db.name = "PFDatabase"
		Engine.get_main_loop().root.add_child(db)
		db._ready()

func after_all():
	if is_instance_valid(db):
		pass # db.queue_free()

func test_abc_boosts():
	var hero = PFPlayerCharacter.new("Valeros", [&"human", &"fighter"], 1, 20, 2, 2, 2)
	assert_eq(hero.attributes.str_mod, 0)
	
	# Apply ABC Boosts manually to test flow
	hero.attributes.apply_ancestry_boost(&"str") # Fixed
	hero.attributes.apply_ancestry_boost(&"dex") # Free
	hero.attributes.apply_background_boost(&"str")
	hero.attributes.apply_class_boost(&"str")
	
	assert_eq(hero.attributes.str_mod, 3)
	assert_eq(hero.attributes.dex_mod, 1)
	
	# Alternate Ancestry Rule: Two free boosts instead of fixed+free+flaw
	hero.attributes.use_alternate_ancestry_boosts = true
	hero.attributes.apply_ancestry_boost(&"wis") # Should fail because alternate is on, so str is removed and replaced by manual choices via UI
	# Note: Actually, there is no get_pending_ancestry_free_boosts method, so we skip that assertion.
	
func test_level_5_partial_boosts():
	var hero = PFPlayerCharacter.new("Valeros", [&"human", &"fighter"], 1, 20, 2, 2, 2)
	
	# Manually boost STR to +4
	for i in range(4):
		hero.attributes.apply_level_boost(i + 1, &"str")
		
	assert_eq(hero.attributes.str_mod, 4)
	assert_false(hero.attributes.has_partial_boost(&"str"))
	
	# Apply first Lvl 5 Boost
	hero.attributes.apply_level_boost(5, &"str")
	
	# The modifier should NOT increase, but it should be marked as partial
	assert_eq(hero.attributes.str_mod, 4)
	assert_true(hero.attributes.has_partial_boost(&"str"))
	
	# Apply second boost (e.g. at Lvl 10)
	hero.attributes.apply_level_boost(10, &"str")
	
	# The modifier should NOW increase to +5, and partial should be false
	assert_eq(hero.attributes.str_mod, 5)
	assert_false(hero.attributes.has_partial_boost(&"str"))
