# test_combination_weapons.gd
class_name TestCombinationWeapons
extends GdUnitTestSuite

var db: PFDatabase
var attacker: PFActor
var defender: PFActor

func before() -> void:
	if not Engine.get_main_loop().root.has_node("PFDatabase"):
		db = PFDatabase.new()
		db.name = "PFDatabase"
		Engine.get_main_loop().root.add_child(db)
		db._ready()
	else:
		db = PFDatabase.get_instance()
		
	# Insert mock combination weapon into DB
	db.db.query("INSERT OR REPLACE INTO weapons (id, name, traits, level, weapon_type, damage_dice, damage_faces, hands_required, linked_weapon_id, price_cp, material, hardness, max_hp, broken_threshold, grade, bulk, category, group_type, damage_type) VALUES ('mock_gunblade_melee', 'Gunblade', 'combination,critical fusion', 1, 0, 1, 8, 1, 'mock_gunblade_ranged', 0, 0, 5, 20, 10, 0, 1, 0, 0, 0)")
	db.db.query("INSERT OR REPLACE INTO weapons (id, name, traits, level, weapon_type, damage_dice, damage_faces, hands_required, range_increment, linked_weapon_id, price_cp, material, hardness, max_hp, broken_threshold, grade, bulk, category, group_type, damage_type) VALUES ('mock_gunblade_ranged', 'Gunblade (Ranged)', 'combination', 1, 1, 1, 6, 2, 40, 'mock_gunblade_melee', 0, 0, 5, 20, 10, 0, 1, 0, 0, 0)")

func before_test() -> void:
	attacker = PFPlayerCharacter.new("Attacker", [], 1, 50, 0, 0, 0)
	defender = PFPlayerCharacter.new("Defender", [], 1, 50, 0, 0, 0)

func test_combination_toggle() -> void:
	var gunblade = db.get_weapon("mock_gunblade_melee")
	assert_object(gunblade).is_not_null()
	assert_str(gunblade.linked_weapon_id).is_equal("mock_gunblade_ranged")
	assert_bool(gunblade.combination_data.is_empty()).is_false()
	
	# Initial stats (Melee)
	assert_int(gunblade.weapon_type).is_equal(0) # Melee
	assert_int(gunblade.die_faces).is_equal(8)
	assert_int(gunblade.hands_required).is_equal(1)
	
	# Equip it
	var inv = attacker.get("inventory") as PFInventory
	inv.add_item(gunblade)
	inv.equip_weapon(gunblade, 1, true)
	
	# Interact to toggle
	var toggle_action = PFActionInteractCombination.new(gunblade)
	assert_bool(toggle_action.execute(attacker)).is_true()
	
	# Should now be ranged
	assert_bool(gunblade.is_alternate_form_active).is_true()
	assert_int(gunblade.weapon_type).is_equal(1) # Ranged
	assert_int(gunblade.die_faces).is_equal(6)
	assert_int(gunblade.hands_required).is_equal(2)
	assert_int(gunblade.range_increment).is_equal(40)
	
	# Toggle back
	assert_bool(toggle_action.execute(attacker)).is_true()
	
	# Should now be melee again
	assert_bool(gunblade.is_alternate_form_active).is_false()
	assert_int(gunblade.weapon_type).is_equal(0)
	assert_int(gunblade.die_faces).is_equal(8)
	assert_int(gunblade.hands_required).is_equal(1)
