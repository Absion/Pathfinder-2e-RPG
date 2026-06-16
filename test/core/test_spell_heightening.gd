extends GdUnitTestSuite

func test_ignition_heightening_and_persistent_damage():
	# Mock an actor
	var caster = PFPlayerCharacter.new("Wizard", [&"humanoid"], 5, 40, 0, 0, 0)
	auto_free(caster)
	add_child(caster)
	
	var target = PFActor.new("Goblin", [&"humanoid"], 1, 100)
	auto_free(target)
	add_child(target)
	
	# Create ignition spell using the new factory
	var spell = PFSpell.create(&"ignition")
	
	# Verify script loaded correctly
	assert_bool(spell is PFIgnitionSpell).is_true()
	
	# Test 1: Cast at Rank 1. Base should be 2d4 damage.
	# We mock rolling maximum on dice for testing if needed, but PFDice is random.
	# Let's just run it to see the print output, and check conditions.
	spell.resolve_effect(caster, target, PFDice.Degree.SUCCESS, 1)
	
	# Target should have taken some damage, but NO persistent damage on a standard success
	assert_int(target.conditions.size()).is_equal(0)
	
	# Reset target HP
	target.health.current_hp = 100
	
	# Test 2: Cast at Rank 3. Base damage should be 2d4 + 2d4 = 4d4.
	spell.resolve_effect(caster, target, PFDice.Degree.SUCCESS, 3)
	assert_int(target.conditions.size()).is_equal(0)
	
	# Reset target
	target.health.current_hp = 100
	
	# Test 3: Critical Hit at Rank 3.
	spell.resolve_effect(caster, target, PFDice.Degree.CRIT_SUCCESS, 3)
	
	# Target should now have a persistent damage condition
	assert_int(target.conditions.size()).is_equal(1)
	var condition = target.conditions[0]
	assert_str(condition.condition_name).is_equal("Persistent Fire")
	
	# Ignition scales persistent damage: +1d4 per increment.
	# Rank 3 - Rank 1 = 2 increments (since scaling_rules = 1)
	# Base persistent is 1d4 + 2 = 3d4.
	assert_int(condition.dice_amount).is_equal(3)
	assert_int(condition.damage_type).is_equal(PFCombatConstants.DamageType.FIRE)
