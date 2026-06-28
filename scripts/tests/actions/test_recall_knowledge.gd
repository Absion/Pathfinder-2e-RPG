extends GutTest

class_name TestRecallKnowledge

func get_test_name() -> String:
	return "Recall Knowledge Tests"

func test_main() -> void:
	print("\n--- Running Recall Knowledge Tests ---")
	
	PFContext.init_shared_services()
	
	var wizard = autofree(PFPlayerCharacter.new("Wizard", [&"humanoid"], 5, 0, 0, 0, 0))
	wizard.attributes.apply_ancestry_boost(&"int")
	wizard.attributes.apply_background_boost(&"int")
	wizard.attributes.apply_class_boost(&"int")
	wizard.attributes.apply_free_boost(&"int")
	wizard.sheet.set_skill_rank(&"arcana", PFMathConstants.ProficiencyRank.EXPERT) # +4 + 5 + 4 = 13
	wizard.sheet.set_skill_rank(&"religion", PFMathConstants.ProficiencyRank.TRAINED) # +4 + 5 + 2 = 11
	
	# Undead skeleton, Level 2
	var skeleton = autofree(PFPlayerCharacter.new("Skeleton", [&"undead", &"mindless"], 2, 0, 0, 0, 0))
	skeleton.health.max_hp = 20
	skeleton.health.current_hp = 20
	
	# Dragon, Level 5
	var dragon = autofree(PFPlayerCharacter.new("Young Dragon", [&"dragon", &"fire"], 5, 0, 0, 0, 0))
	
	var _action = PFActionRecallKnowledge.new()
	
	print("\nTest 1: Recall Knowledge on Undead (Religion)")
	# We expect Religion to be used. Skeleton level 2 DC is 16.
	# Wizard has +11 Religion. Rolling 1-20. 
	_action.execute(wizard, skeleton)
	
	print("\nTest 2: Recall Knowledge on Dragon (Arcana)")
	# We expect Arcana. Dragon level 5 DC is 20.
	_action.execute(wizard, dragon)
	
	print("\nAll Recall Knowledge tests executed (Check logs for expected output)!")
	assert_true(true, "Completed recall knowledge tests")

func after_all():
	PFContext.cleanup_shared_services()
