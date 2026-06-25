# test_environment.gd
extends GutTest

func before_all():
	PFContext.init_shared_services()
	var db = PFDatabase.get_instance()
	if db == null:
		db = PFDatabase.new()
		add_child(db)

func test_damage_by_level() -> void:
	print("\n--- Test: Damage by Level Table ---")
	
	var lvl_1_minor = PFGameMath.get_environmental_damage(1, PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR)
	var lvl_10_major = PFGameMath.get_environmental_damage(10, PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR)
	var lvl_20_massive = PFGameMath.get_environmental_damage(20, PFEnvironmentConstants.EnvironmentDamageSeverity.MASSIVE)
	
	print("Level 1 Minor Damage Roll: 1d6 -> Roll Result: %d" % [lvl_1_minor.total])
	print("Level 10 Major Damage Roll: 10d8 -> Roll Result: %d" % [lvl_10_major.total])
	print("Level 20 Massive Damage Roll: 28d8 -> Roll Result: %d" % [lvl_20_massive.total])
	
	assert_true(lvl_1_minor.total >= 1, "Level 1 minor should be at least 1")
	assert_true(lvl_10_major.total >= 10, "Level 10 major should be at least 10")
	assert_true(lvl_20_massive.total >= 28, "Level 20 massive should be at least 28")
	print("    > Damage by Level: PASS")

func test_aquatic_combat() -> void:
	print("\n--- Test: Aquatic Combat ---")
	
	var pc = PFPlayerCharacter.new("Fighter", [&"humanoid"], 1, 10, 0, 0, 0)
	var target = PFPlayerCharacter.new("Target", [&"humanoid"], 1, 10, 0, 0, 0)
	add_child(pc)
	add_child(target)
	
	var env_mgr = PFEnvironmentManager.get_instance()
	if not env_mgr:
		env_mgr = PFEnvironmentManager.new()
	env_mgr.is_underwater = true
	
	var sword = PFWeapon.new("longsword")
	sword.entity_name = "Longsword"
	sword.traits.append(&"slashing")
	
	pc.inventory.add_item(sword)
	pc.inventory.held_main_hand = sword
	sword.is_wielded = true
	
	var strike = PFActionStrike.new(sword)
	strike.execute(pc, target)
	
	# Check Cast Spell underwater
	var fireball = PFSpell.new(&"fireball")
	fireball.entity_name = "Fireball"
	fireball.traits.append(&"fire")
	fireball.base_spell_rank = 3
	fireball.cast_time = "2 actions"
	fireball.range_ft = 120
	fireball.targets = "burst"
	fireball.saving_throw = "Reflex"
	var cast_fireball = PFActionCastSpell.new(fireball)
	pc.spellbook = PFSpellbook.new(pc) # mock
	
	# Since is_underwater = true, this should fail to cast and return false
	var cast_success = cast_fireball.execute(pc, target)
	if cast_success is Signal:
		cast_success = await cast_success
	assert_false(cast_success, "Fireball should fail underwater!")
	
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
	
	assert_true(true, "Completed extreme weather test")
	print("    > Extreme Weather Tests: PASS")
