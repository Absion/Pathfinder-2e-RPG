# test_combination_weapons.gd
class_name TestCombinationWeapons
extends GutTest

var database: PFDatabase
var attacker: PFActor
var defender: PFActor

func before_all() -> void:
	if not Engine.get_main_loop().root.has_node("PFDatabase"):
		database = PFDatabase.new()
		database.name = "PFDatabase"
		Engine.get_main_loop().root.add_child(database)
		database._ready()
	else:
		database = PFDatabase.get_instance()
		
	# Insert mock combination weapon into DB
	database.query("INSERT OR REPLACE INTO weapons (id, name, traits, level, weapon_type, damage_dice, damage_faces, hands_required, linked_weapon_id, price_cp, material, hardness, max_hp, broken_threshold, grade, bulk, category, group_type, damage_type) VALUES ('mock_gunblade_melee', 'Gunblade', 'combination,critical fusion', 1, 0, 1, 8, 1, 'mock_gunblade_ranged', 0, 0, 5, 20, 10, 0, 1, 0, 0, 0)")
	database.query("INSERT OR REPLACE INTO weapons (id, name, traits, level, weapon_type, damage_dice, damage_faces, hands_required, range_increment, linked_weapon_id, price_cp, material, hardness, max_hp, broken_threshold, grade, bulk, category, group_type, damage_type) VALUES ('mock_gunblade_ranged', 'Gunblade (Ranged)', 'combination', 1, 1, 1, 6, 2, 40, 'mock_gunblade_melee', 0, 0, 5, 20, 10, 0, 1, 0, 0, 0)")

func before_each() -> void:
	attacker = autofree(PFPlayerCharacter.new("Attacker", [], 1, 50, 0, 0, 0))
	defender = autofree(PFPlayerCharacter.new("Defender", [], 1, 50, 0, 0, 0))

func test_combination_toggle() -> void:
	var gunblade = database.get_weapon("mock_gunblade_melee")
	assert_not_null(gunblade)
	assert_eq(gunblade.linked_weapon_id, "mock_gunblade_ranged")
	assert_false(gunblade.combination_data.is_empty())
	
	# Initial stats (Melee)
	assert_eq(gunblade.weapon_type, 0) # Melee
	assert_eq(gunblade.die_faces, 8)
	assert_eq(gunblade.hands_required, 1)
	
	# Equip it
	var inventory = attacker.get(&"inventory") as PFInventory
	inventory.add_item(gunblade)
	inventory.equip_weapon(gunblade, 1, true)
	
	# Interact to toggle
	var toggle_action = PFActionInteractCombination.new(gunblade)
	assert_true(toggle_action.execute(attacker))
	
	# Should now be ranged
	assert_true(gunblade.is_alternate_form_active)
	assert_eq(gunblade.weapon_type, 1) # Ranged
	assert_eq(gunblade.die_faces, 6)
	assert_eq(gunblade.hands_required, 2)
	assert_eq(gunblade.range_increment, 40)
	
	# Toggle back
	assert_true(toggle_action.execute(attacker))
	
	# Should now be melee again
	assert_false(gunblade.is_alternate_form_active)
	assert_eq(gunblade.weapon_type, 0)
	assert_eq(gunblade.die_faces, 8)
	assert_eq(gunblade.hands_required, 1)

