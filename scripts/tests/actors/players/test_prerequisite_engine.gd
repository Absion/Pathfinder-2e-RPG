# test_prerequisite_engine.gd
class_name TestPrerequisiteEngine
extends GutTest

var database: PFDatabase

func before_all():
	database = PFDatabase.get_instance()
	if database == null:
		database = PFDatabase.new()
		database.name = "PFDatabase"
		Engine.get_main_loop().root.add_child(database)
		database._ready()

func after_all():
	if is_instance_valid(database):
		pass # database.queue_free()

func test_ethnicity_requirements():
	var hero = autofree(PFPlayerCharacter.new("Valeros", [&"human", &"fighter"], 1, 20, 2, 2, 2))
	var shadow_data = database.get_feat_data(&"ashen_shadowcaster")
	
	var shadow_traits_raw = JSON.parse_string(shadow_data["traits"]) as Array
	var shadow_traits: Array[StringName] = []
	for t in shadow_traits_raw: shadow_traits.append(StringName(t))
	# Expected fail, default ethnicity is unknown
	assert_false(PFPrerequisiteEngine.evaluate(shadow_data["prerequisites"], hero, shadow_traits))
	
	# Set to Torvallan (wrong ethnicity)
	hero.ethnicity = &"torvallan"
	assert_false(PFPrerequisiteEngine.evaluate(shadow_data["prerequisites"], hero, shadow_traits))
	
	# Set to Ashen Nomad (correct ethnicity)
	hero.ethnicity = &"ashen_nomad"
	assert_true(PFPrerequisiteEngine.evaluate(shadow_data["prerequisites"], hero, shadow_traits))
	
func test_archetype_dedication_lock():
	var hero = autofree(PFPlayerCharacter.new("Valeros", [&"human", &"fighter"], 1, 20, 2, 2, 2))
	var assassin_data = database.get_feat_data(&"assassin_dedication")
	
	var assassin_traits_raw = JSON.parse_string(assassin_data["traits"]) as Array
	var assassin_traits: Array[StringName] = []
	for t in assassin_traits_raw: assassin_traits.append(StringName(t))
	# Initially Valid (no dedications yet)
	assert_true(PFPrerequisiteEngine.evaluate(assassin_data["prerequisites"], hero, assassin_traits))
	
	# Give Acrobat Dedication (Count: 1)
	hero.feats.append(PFFeat.new(&"acrobat_dedication"))
	
	# Assassin Dedication should now fail (Lock is active)
	assert_false(PFPrerequisiteEngine.evaluate(assassin_data["prerequisites"], hero, assassin_traits))
	
	# Multitalented Override Test
	assert_true(PFPrerequisiteEngine.evaluate(assassin_data["prerequisites"], hero, assassin_traits, true))
	
	# Satisfy the Acrobat Dedication (Count: 3)
	hero.feats.append(PFFeat.new(&"dodge_away"))
	hero.feats.append(PFFeat.new(&"acrobat_grace"))
	
	# Assassin Dedication should now succeed (Lock is satisfied)
	assert_true(PFPrerequisiteEngine.evaluate(assassin_data["prerequisites"], hero, assassin_traits))

