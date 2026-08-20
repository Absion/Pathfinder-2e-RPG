extends GutTest

func before_all():
	PFContext.init_shared_services()

func test_get_ancestry_from_db():
	var db = PFDatabase.get_instance()
	if db == null:
		db = PFDatabase.new()
		add_child_autofree(db)
		
	var human = db.get_ancestry("human")
	assert_not_null(human, "Human ancestry should be loaded from DB")
	
	if human != null:
		assert_eq(human.id, &"human")
		assert_eq(human.entity_name, "Human")
		assert_eq(human.hp, 8)
		assert_eq(human.size_id, &"medium")
		assert_eq(human.speed, 25)
		assert_eq(human.starting_gold, 15)
		
		assert_true(human.traits.has(&"humanoid"))
		assert_true(human.ability_boosts.has(&"free") or human.ability_boosts.has(&"FREE"))
		assert_true(human.known_languages.has(&"common"))
		assert_false(human.description.is_empty())
		assert_true(human.ethnicities.has("cordovalen"))
		assert_true(human.heritages.has("versatile_human"))
		assert_true(human.common_names.has("Alden") or human.common_names.has("Valerius"))

func after_all():
	PFContext.cleanup_shared_services()
