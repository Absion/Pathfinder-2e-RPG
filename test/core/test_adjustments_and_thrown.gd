extends GdUnitTestSuite

var db_instance: PFDatabase

func before() -> void:
	if not Engine.get_main_loop().root.has_node("PFDatabase"):
		db_instance = PFDatabase.new()
		db_instance.name = "PFDatabase"
		Engine.get_main_loop().root.add_child(db_instance)
		db_instance._ready()
	else:
		db_instance = PFDatabase.get_instance()

func test_adjustments():
	# Get a generic shield
	var shield = db_instance.get_shield("steel_shield")
	assert_that(shield).is_not_null()
	
	# Verify bash weapon initially doesn't have agile (Wait, it DOES have agile by default)
	var bash = shield.get_bash_weapon()
	assert_that(bash.has_trait(&"agile")).is_true()
	assert_that(bash.has_trait(&"trip")).is_false()
	
	# Get Shield Augmentation and assign 'trip'
	var augmentation = db_instance.get_adjustment("shield_augmentation")
	assert_that(augmentation).is_not_null()
	augmentation.granted_traits.append(&"trip")
	
	# Attach
	var success = augmentation.attach_to(shield)
	assert_that(success).is_true()
	assert_that(shield.adjustment).is_not_null()
	
	# Verify bash weapon inherits trip
	var augmented_bash = shield.get_bash_weapon()
	assert_that(augmented_bash.has_trait(&"trip")).is_true()
	
	# Detach
	augmentation.detach()
	assert_that(shield.adjustment).is_null()
	
func test_thrown_trait():
	var shield = db_instance.get_shield("steel_shield")
	var throwing_adj = db_instance.get_adjustment("throwing_shield")
	
	throwing_adj.attach_to(shield)
	
	var throw_bash = shield.get_bash_weapon()
	assert_that(throw_bash.can_be_thrown()).is_true()
	assert_that(throw_bash.get_thrown_range()).is_equal(20)
