extends GutTest

func test_ignition_heightening_and_persistent_damage():
	# Mock an actor
	var caster = autofree(PFPlayerCharacter.new("Wizard", [&"humanoid"], 5, 40, 0, 0, 0))
	add_child_autofree(caster)
	
	var target = autofree(PFActor.new("Goblin", [&"humanoid"], 1, 100))
	add_child_autofree(target)
	
	# Create ignition spell using the new factory
	var spell = PFSpell.create(&"ignition")
	
	# Verify script loaded correctly
	assert_true(spell is PFIgnitionSpell)
	
	# Test 1: Cast at Rank 1. Base should be 2d4 damage.
	# We mock rolling maximum on dice for testing if needed, but PFDice is random.
	# Let's just run it to see the print output, and check conditions.
	spell.resolve_effect(caster, target, PFDice.Degree.SUCCESS, 1)
	
	# Target should have taken some damage, but NO persistent damage on a standard success
	assert_eq(target.conditions.size(), 0)
	
	# Reset target HP
	target.health.current_hp = 100
	
	# Test 2: Cast at Rank 3. Base damage should be 2d4 + 2d4 = 4d4.
	spell.resolve_effect(caster, target, PFDice.Degree.SUCCESS, 3)
	assert_eq(target.conditions.size(), 0)
	
	# Reset target
	target.health.current_hp = 100
	
	# Test 3: Critical Hit at Rank 3.
	spell.resolve_effect(caster, target, PFDice.Degree.CRIT_SUCCESS, 3)
	
	# Target should now have a persistent damage condition
	assert_eq(target.conditions.size(), 1)
	var condition = target.conditions[0]
	assert_eq(condition.condition_name, "Persistent Fire")
	
	# Ignition scales persistent damage: +1d4 per increment.
	# Rank 3 - Rank 1 = 2 increments (since scaling_rules = 1)
	# Base persistent is 1d4 + 2 = 3d4.
	assert_eq(condition.dice_amount, 3)
	assert_eq(condition.damage_type, PFCombatConstants.DamageType.FIRE)
