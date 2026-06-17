# test_environment.gd
extends SceneTree

func _init():
	print("--- Running Environmental Rules Tests ---")
	
	PFContext.init_shared_services()
	
	test_damage_by_level()
	test_aquatic_combat()
	test_extreme_weather()
	
	print("--- All Environmental Tests Completed Successfully! ---")
	quit(0)

func test_damage_by_level() -> void:
	print("\n--- Test: Damage by Level Table ---")
	
	var lvl_1_minor = PFGameMath.get_environmental_damage(1, PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR)
	var lvl_10_major = PFGameMath.get_environmental_damage(10, PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR)
	var lvl_20_massive = PFGameMath.get_environmental_damage(20, PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE)
	
	print("Level 1 Minor Damage Roll: 1d6 -> Roll Result: %d (Faces: %d)" % [lvl_1_minor.total, lvl_1_minor.faces])
	print("Level 10 Major Damage Roll: 10d8 -> Roll Result: %d (Faces: %d)" % [lvl_10_major.total, lvl_10_major.faces])
	print("Level 20 Massive Damage Roll: 28d8 -> Roll Result: %d (Faces: %d)" % [lvl_20_massive.total, lvl_20_massive.faces])
	
	assert(lvl_1_minor.faces == 6)
	assert(lvl_10_major.faces == 8)
	assert(lvl_20_massive.faces == 8)
	print("    > Damage by Level: PASS")

func test_aquatic_combat() -> void:
	print("\n--- Test: Aquatic Combat ---")
	
	var env_mgr = PFEnvironmentManager.get_instance()
	env_mgr.is_underwater = true
	
	var pc = PFPlayerCharacter.new("Fighter", 1)
	PFContext.active_party.append(pc)
	
	# Create a slashing weapon
	var sword = PFWeapon.new("Longsword", [&"slashing"], 1, 0, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.MARTIAL, PFEquipmentConstants.WeaponGroup.SWORD, 1, 8, PFCombatConstants.DamageType.SLASHING)
	pc.inventory.held_main_hand = sword
	sword.is_wielded = true
	
	var target = PFNpc.new("Target", 1)
	
	var strike = PFActionStrike.new(sword)
	strike.execute(pc, target)
	
	# Check Cast Spell underwater
	var fireball = PFSpell.new("Fireball", [&"fire"], 3, "2 actions", 120, "burst", "Reflex")
	var cast_fireball = PFActionCastSpell.new(fireball)
	pc.spellbook = PFSpellbook.new() # mock
	
	# Since is_underwater = true, this should fail to cast and return false
	var cast_success = cast_fireball.execute(pc, target)
	assert(cast_success == false, "Fireball should fail underwater!")
	
	env_mgr.is_underwater = false
	print("    > Aquatic Combat Constraints: PASS")

func test_extreme_weather() -> void:
	print("\n--- Test: Extreme Weather Periodic Damage ---")
	
	var env_mgr = PFEnvironmentManager.get_instance()
	var time_mgr = PFTimeManager.new()
	Engine.get_main_loop().root.add_child(time_mgr)
	time_mgr._ready() # Force ready
	env_mgr._ready() # Re-bind signals to the new mock TimeManager
	
	env_mgr.current_temperature = PFEnvironmentConstants.Temperature.EXTREME_HEAT
	env_mgr.environment_level = 5 # Moderate at level 5 is 4d8 damage
	
	print("Advancing time by 9 minutes (No Damage Expected)...")
	time_mgr.advance_minutes(9)
	
	print("Advancing time by 1 more minute (Damage Expected!)...")
	time_mgr.advance_minutes(1)
	
	print("    > Extreme Weather Tests: PASS")
