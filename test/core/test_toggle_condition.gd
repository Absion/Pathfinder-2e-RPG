extends GdUnitTestSuite

func test_action_toggle_condition():
	var db = PFDatabase.get_instance()
	if not db:
		db = PFDatabase.new()
		db.name = "PFDatabase"
		get_tree().root.add_child(db)
		
	var hero = auto_free(PFPlayerCharacter.new("Valeros", [&"human"], 1, 20, 2, 2, 2))
	var drop_prone_action = PFActionToggleCondition.new(&"drop_prone")
	
	# Initial state
	assert_bool(hero.has_condition("prone")).is_false()
	
	# Execute drop prone
	drop_prone_action.execute(hero)
	assert_bool(hero.has_condition("prone")).is_true()
	
	# Stand up
	var stand_action = PFActionToggleCondition.new(&"stand")
	stand_action.execute(hero)
	assert_bool(hero.has_condition("prone")).is_false()
	
	# Take cover
	var cover_action = PFActionToggleCondition.new(&"take_cover")
	cover_action.execute(hero)
	assert_bool(hero.has_condition("cover")).is_true()
