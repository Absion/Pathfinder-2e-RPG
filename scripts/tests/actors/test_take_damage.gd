extends GutTest

func test_take_damage_basic():
	var actor = PFActor.new("Target", [], 1, 30)
	actor.health.current_hp = 30

	actor.take_damage(10, PFCombatConstants.DamageType.SLASHING)
	assert_eq(actor.health.current_hp, 20, "Should subtract 10 damage")

func test_take_damage_immunities():
	var actor = PFActor.new("Target", [], 1, 30)
	actor.health.current_hp = 30

	# Actor is immune to fire
	actor.health.immunities.append(PFCombatConstants.DamageType.FIRE)

	actor.take_damage(15, PFCombatConstants.DamageType.FIRE)
	assert_eq(actor.health.current_hp, 30, "Immunity should negate all damage")

func test_take_damage_weaknesses():
	var actor = PFActor.new("Target", [], 1, 30)
	actor.health.current_hp = 30

	# Actor has weakness to cold
	actor.health.weaknesses[PFCombatConstants.DamageType.COLD] = 5

	actor.take_damage(10, PFCombatConstants.DamageType.COLD)
	assert_eq(actor.health.current_hp, 15, "10 damage + 5 weakness = 15 total damage")

func test_take_damage_resistances():
	var actor = PFActor.new("Target", [], 1, 30)
	actor.health.current_hp = 30

	# Actor has resistance to slashing
	actor.health.resistances[PFCombatConstants.DamageType.SLASHING] = 5

	actor.take_damage(15, PFCombatConstants.DamageType.SLASHING)
	assert_eq(actor.health.current_hp, 20, "15 damage - 5 resistance = 10 total damage")
