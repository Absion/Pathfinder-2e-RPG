extends GutTest

func before_each():
	PFContext.init_shared_services()

func after_each():
	PFContext.cleanup_shared_services()

func test_action_toggle_condition():
	var database = PFDatabase.get_instance()
	if not database:
		database = autofree(PFDatabase.new())
		database.name = "PFDatabase"
		add_child_autofree(database)
		
	var hero = autofree(PFPlayerCharacter.new("Valeros", [&"human"], 1, 20, 2, 2, 2))
	add_child_autofree(hero)
	var drop_prone_action = PFActionToggleCondition.new(&"drop_prone")
	
	# Initial state
	assert_false(hero.has_condition("prone"))
	
	# Execute drop prone
	await drop_prone_action.execute(hero)
	assert_true(hero.has_condition("prone"))
	
	# Stand up
	var stand_action = PFActionToggleCondition.new(&"stand")
	await stand_action.execute(hero)
	assert_false(hero.has_condition("prone"))
	
	# Take cover
	var cover_action = PFActionToggleCondition.new(&"take_cover")
	await cover_action.execute(hero)
	assert_true(hero.has_condition("cover"))

