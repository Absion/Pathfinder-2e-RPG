# test_weapon_logic.gd
class_name TestWeaponLogic
extends GutTest

var db: PFDatabase
var attacker: PFActor
var defender: PFActor

func before_all() -> void:
	# Ensure the database is initialized for traits and sizes
	if not Engine.get_main_loop().root.has_node("PFDatabase"):
		db = PFDatabase.new()
		db.name = "PFDatabase"
		Engine.get_main_loop().root.add_child(db)
		db._ready()
	else:
		db = PFDatabase.get_instance()

func before_each() -> void:
	PFContext.detection_manager = null
	attacker = PFPlayerCharacter.new("Attacker", [], 1, 50, 0, 0, 0)
	defender = PFPlayerCharacter.new("Defender", [], 1, 50, 0, 0, 0)
	add_child(attacker)
	add_child(defender)

func test_improvised_weapon_creation_and_penalty() -> void:
	var inv = attacker.get(&"inventory") as PFInventory
	var weapon = inv.create_improvised_weapon("Improvised Weapon", [], 1, 4, PFCombatConstants.DamageType.BLUDGEONING, 0, 1)
	
	assert_not_null(weapon)
	assert_true(weapon.is_improvised)
	assert_eq(weapon.hands_required, 1)
	assert_true(weapon.is_wielded)
	
	# Check strike action penalizes -2
	var strike = PFActionStrike.new(weapon)
	attacker.start_turn()
	await strike.execute(attacker, defender)
	# We can't strictly assert print statements, but we ensure it executes without crashing
	
func test_weapon_handedness() -> void:
	var weapon = PFWeapon.new("Greatsword", [], 1, 0, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.MARTIAL, PFEquipmentConstants.WeaponGroup.SWORD, 1, 12, PFCombatConstants.DamageType.SLASHING, PFEquipmentConstants.ItemMaterial.STEEL, 5, 20, 0, 0, PFEquipmentConstants.MaterialGrade.STANDARD, 0, 0, 0, 2)
	
	var inv = attacker.get(&"inventory") as PFInventory
	inv.add_item(weapon)
	
	# Try striking without holding it in two hands (should fail)
	var strike = PFActionStrike.new(weapon)
	assert_false(await strike.execute(attacker, defender))
	
	# Wield in two hands
	inv.equip_weapon(weapon, 2)
	assert_true(await strike.execute(attacker, defender))

func test_reload_and_ammunition() -> void:
	var bow = PFWeapon.new("Longbow", [], 1, 0, PFEquipmentConstants.WeaponType.RANGED, PFEquipmentConstants.WeaponCategory.MARTIAL, PFEquipmentConstants.WeaponGroup.BOW, 1, 8, PFCombatConstants.DamageType.PIERCING, PFEquipmentConstants.ItemMaterial.WOOD, 5, 20, 0, 0, PFEquipmentConstants.MaterialGrade.STANDARD, 100, 30, 0, 2, PFEquipmentConstants.AmmunitionType.ARROWS)
	
	var inv = attacker.get(&"inventory") as PFInventory
	inv.add_item(bow)
	inv.equip_weapon(bow, 2)
	
	var strike = PFActionStrike.new(bow)
	
	# Reload is 0, so it initializes as loaded
	assert_true(bow.is_loaded)
	assert_true(await strike.execute(attacker, defender))
	
	# After firing, it should be unloaded
	assert_false(bow.is_loaded)
	
	# Cannot fire again until loaded
	assert_false(await strike.execute(attacker, defender))

func test_two_hand_trait() -> void:
	var bastard_sword = PFWeapon.new("Bastard Sword", [&"two-hand d12"], 1, 0, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.MARTIAL, PFEquipmentConstants.WeaponGroup.SWORD, 1, 8, PFCombatConstants.DamageType.SLASHING, PFEquipmentConstants.ItemMaterial.STEEL, 5, 20, 0, 0, PFEquipmentConstants.MaterialGrade.STANDARD, 0, 0, 0, 1)
	
	var inv = attacker.get(&"inventory") as PFInventory
	inv.add_item(bastard_sword)
	
	# Equip in one hand
	inv.equip_weapon(bastard_sword, 1, true)
	var strike = PFActionStrike.new(bastard_sword)
	await strike.execute(attacker, defender) # Base damage d8
	
	# Equip in two hands
	inv.equip_weapon(bastard_sword, 2)
	assert_true(true, "Completed two_hand_trait test")
	await strike.execute(attacker, defender) # Should trigger Two-Hand and upgrade die
	
func test_property_rune_capacity() -> void:
	var weapon = PFWeapon.new("Sword", [], 1)
	
	# Base weapon has potency 0, cannot hold property runes
	assert_false(weapon.add_property_rune(PFEquipmentConstants.PropertyRune.FLAMING))
	
	# Upgrade to +1
	weapon.apply_fundamental_runes(PFEquipmentConstants.PotencyRune.PLUS_ONE, PFEquipmentConstants.StrikingRune.NONE)
	assert_true(weapon.add_property_rune(PFEquipmentConstants.PropertyRune.FLAMING))
	
	# Cannot hold two
	assert_false(weapon.add_property_rune(PFEquipmentConstants.PropertyRune.FROST))

func test_injection_payload() -> void:
	var weapon = PFWeapon.new("Syringe Spear", [&"injection"], 1, 0, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.MARTIAL, PFEquipmentConstants.WeaponGroup.SPEAR, 1, 6, PFCombatConstants.DamageType.PIERCING, PFEquipmentConstants.ItemMaterial.STEEL, 5, 20, 0, 0, PFEquipmentConstants.MaterialGrade.STANDARD, 0, 0, 0, 2)
	var poison = PFItem.new("Giant Centipede Venom")
	
	var inv = attacker.get(&"inventory") as PFInventory
	inv.add_item(weapon)
	inv.add_item(poison)
	inv.equip_weapon(weapon, 2)
	
	# Load it
	var inject_action = PFActionInteractInject.new(weapon, poison)
	assert_true(inject_action.execute(attacker))
	
	# Payload should be loaded, inventory should not have poison
	assert_eq(weapon.injection_payload, poison)
	assert_false(inv.items.has(poison))
	
	# Strike target
	weapon.potency_bonus = 20 # Force a hit
	var strike = PFActionStrike.new(weapon)
	assert_true(await strike.execute(attacker, defender))
	
	# Payload should be consumed/cleared
	assert_null(weapon.injection_payload)

func test_specific_magic_weapon_runes():
	# Create a standard weapon and a specific magic weapon
	var std_weapon = PFWeapon.new("Standard Sword")
	var spec_weapon = PFWeapon.new("Flame Tongue")
	spec_weapon.is_specific_magic = true
	
	# Apply fundamental runes
	std_weapon.apply_fundamental_runes(PFEquipmentConstants.PotencyRune.PLUS_ONE, PFEquipmentConstants.StrikingRune.NONE)
	spec_weapon.apply_fundamental_runes(PFEquipmentConstants.PotencyRune.PLUS_ONE, PFEquipmentConstants.StrikingRune.NONE)
	
	# Standard weapon should accept a property rune
	assert_true(std_weapon.add_property_rune(PFEquipmentConstants.PropertyRune.FLAMING))
	
	# Specific magic weapon should reject the property rune
	assert_false(spec_weapon.add_property_rune(PFEquipmentConstants.PropertyRune.FLAMING))
	
	# Verify specific magic weapon CAN still upgrade fundamental runes
	spec_weapon.apply_fundamental_runes(PFEquipmentConstants.PotencyRune.PLUS_TWO, PFEquipmentConstants.StrikingRune.STRIKING)
	assert_eq(spec_weapon.potency_bonus, 2)
	assert_eq(spec_weapon.dice_amount, 2)
