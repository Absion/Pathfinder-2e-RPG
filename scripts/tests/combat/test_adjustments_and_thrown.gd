extends GutTest

var db_instance: PFDatabase

func before_all() -> void:
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
	assert_not_null(shield)
	
	# Verify bash weapon initially doesn't have agile (Wait, it DOES have agile by default)
	var bash = shield.get_bash_weapon()
	assert_true(bash.has_trait(&"agile"))
	assert_false(bash.has_trait(&"trip"))
	
	# Get Shield Augmentation and assign 'trip'
	var augmentation = db_instance.get_adjustment("shield_augmentation")
	assert_not_null(augmentation)
	augmentation.granted_traits.append(&"trip")
	
	# Attach
	var success = augmentation.attach_to(shield)
	assert_true(success)
	assert_not_null(shield.adjustment)
	
	# Verify bash weapon inherits trip
	var augmented_bash = shield.get_bash_weapon()
	assert_true(augmented_bash.has_trait(&"trip"))
	
	# Detach
	augmentation.detach()
	assert_null(shield.adjustment)
	
func test_thrown_trait():
	var shield = db_instance.get_shield("steel_shield")
	var throwing_adj = db_instance.get_adjustment("throwing_shield")
	
	throwing_adj.attach_to(shield)
	
	var throw_bash = shield.get_bash_weapon()
	assert_true(throw_bash.can_be_thrown())
	assert_eq(throw_bash.get_thrown_range(), 20)
