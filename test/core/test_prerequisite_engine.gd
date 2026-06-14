# test_prerequisite_engine.gd
class_name TestPrerequisiteEngine
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

func test_ethnicity_requirements():
	var hero = auto_free(PFPlayerCharacter.new("Valeros", [&"human", &"fighter"], 1, 20, 2, 2, 2))
	var shadow_data = db.get_feat_data(&"nidalese_shadowcaster")
	
	var shadow_traits_raw = JSON.parse_string(shadow_data["traits"]) as Array
	var shadow_traits: Array[StringName] = []
	for t in shadow_traits_raw: shadow_traits.append(StringName(t))
	# Expected fail, default ethnicity is unknown
	assert_bool(PFPrerequisiteEngine.evaluate(shadow_data["prerequisites"], hero, shadow_traits)).is_false()
	
	# Set to Mualijae (wrong ethnicity)
	hero.ethnicity = &"mualijae"
	assert_bool(PFPrerequisiteEngine.evaluate(shadow_data["prerequisites"], hero, shadow_traits)).is_false()
	
	# Set to Nidalese (correct ethnicity)
	hero.ethnicity = &"nidalese"
	assert_bool(PFPrerequisiteEngine.evaluate(shadow_data["prerequisites"], hero, shadow_traits)).is_true()
	
func test_archetype_dedication_lock():
	var hero = auto_free(PFPlayerCharacter.new("Valeros", [&"human", &"fighter"], 1, 20, 2, 2, 2))
	var assassin_data = db.get_feat_data(&"assassin_dedication")
	
	var assassin_traits_raw = JSON.parse_string(assassin_data["traits"]) as Array
	var assassin_traits: Array[StringName] = []
	for t in assassin_traits_raw: assassin_traits.append(StringName(t))
	# Initially Valid (no dedications yet)
	assert_bool(PFPrerequisiteEngine.evaluate(assassin_data["prerequisites"], hero, assassin_traits)).is_true()
	
	# Give Acrobat Dedication (Count: 1)
	hero.feats.append(PFFeat.new(&"acrobat_dedication"))
	
	# Assassin Dedication should now fail (Lock is active)
	assert_bool(PFPrerequisiteEngine.evaluate(assassin_data["prerequisites"], hero, assassin_traits)).is_false()
	
	# Multitalented Override Test
	assert_bool(PFPrerequisiteEngine.evaluate(assassin_data["prerequisites"], hero, assassin_traits, true)).is_true()
	
	# Satisfy the Acrobat Dedication (Count: 3)
	hero.feats.append(PFFeat.new(&"dodge_away"))
	hero.feats.append(PFFeat.new(&"acrobat_grace"))
	
	# Assassin Dedication should now succeed (Lock is satisfied)
	assert_bool(PFPrerequisiteEngine.evaluate(assassin_data["prerequisites"], hero, assassin_traits)).is_true()
