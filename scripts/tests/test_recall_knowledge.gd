extends SceneTree

class_name TestRecallKnowledge

func get_test_name() -> String:
	return "Recall Knowledge Tests"

func _init() -> void:
	run_test()
	quit()

func run_test() -> void:
	print("\n--- Running Recall Knowledge Tests ---")
	
	PFContext.init_shared_services()
	
	var wizard = PFPlayerCharacter.new("Wizard", [&"humanoid"], 5, 0, 0, 0, 0)
	wizard.attributes.int = 18
	wizard.sheet.set_skill_rank(&"arcana", PFMathConstants.ProficiencyRank.EXPERT) # +4 + 5 + 4 = 13
	wizard.sheet.set_skill_rank(&"religion", PFMathConstants.ProficiencyRank.TRAINED) # +4 + 5 + 2 = 11
	
	# Undead skeleton, Level 2
	var skeleton = PFPlayerCharacter.new("Skeleton", [&"undead", &"mindless"], 2, 0, 0, 0, 0)
	skeleton.health.max_hp = 20
	skeleton.health.current_hp = 20
	
	# Dragon, Level 5
	var dragon = PFPlayerCharacter.new("Young Dragon", [&"dragon", &"fire"], 5, 0, 0, 0, 0)
	
	var action = PFActionRecallKnowledge.new()
	
	print("\nTest 1: Recall Knowledge on Undead (Religion)")
	# We expect Religion to be used. Skeleton level 2 DC is 16.
	# Wizard has +11 Religion. Rolling 1-20. 
	action.execute(wizard, skeleton)
	
	print("\nTest 2: Recall Knowledge on Dragon (Arcana)")
	# We expect Arcana. Dragon level 5 DC is 20.
	action.execute(wizard, dragon)
	
	print("\nAll Recall Knowledge tests executed (Check logs for expected output)!")
