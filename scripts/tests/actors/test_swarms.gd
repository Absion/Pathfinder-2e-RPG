extends GutTest

var combat_context: PFCombatContext
var grid: PFCombatGrid
var hero: PFActor
var swarm: PFSwarm
var ActionSwarmAttack = preload("res://scripts/actions/combat/pf_action_swarm_attack.gd")
var ActionStride = preload("res://scripts/actions/movement/pf_action_stride.gd")

func before_each():
	combat_context = PFCombatContext.new()
	add_child_autofree(combat_context)
	combat_context.enter_context()
	grid = combat_context.grid_manager
	
	hero = PFNpc.new(&"hero_npc", "Hero", [&"humanoid"], 1, 20, 0, 5, 0, 0, 0, 0, 0, 0, 0) # Ref save +5
	swarm = PFSwarm.new(&"spider_swarm", "Spider Swarm", [], 1, 30, 2, 4, 1, 0, 0, 0, 0, 0, 0)
	
	combat_context.add_child(hero)
	combat_context.add_child(swarm)
	
	combat_context.turn_manager.add_combatant(hero, false)
	combat_context.turn_manager.add_combatant(swarm, true)

func after_each():
	combat_context.exit_context()
	hero.free()
	swarm.free()

func test_swarm_immunities():
	assert_true(swarm.has_immunity(&"grabbed"), "Swarm should be immune to grabbed")
	assert_true(swarm.has_immunity(&"prone"), "Swarm should be immune to prone")
	assert_true(swarm.has_immunity(&"restrained"), "Swarm should be immune to restrained")
	assert_eq(swarm.health.trait_resistances.get(&"precision", 0), 9999, "Swarm should be immune to precision damage")

func test_swarm_weakness():
	swarm.health.trait_weaknesses[&"area"] = 5
	
	# Take 10 fire damage (area)
	swarm.take_damage(10, PFCombatConstants.DamageType.FIRE, [&"area"])
	
	# Should take 10 + 5 = 15 damage
	assert_eq(swarm.health.current_hp, 15, "Swarm should take extra damage from area weakness")

func test_swarm_occupancy():
	hero.global_position = Vector3(0, 0, 0)
	
	# Normal enemies cannot occupy
	var enemy = PFNpc.new(&"goblin", "Goblin", [&"humanoid"], 1, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0)
	combat_context.add_child(enemy)
	enemy.global_position = Vector3(0, 0, 0)
	combat_context.turn_manager.add_combatant(enemy, true)
	
	assert_true(grid.is_space_occupied(Vector3(0, 0, 0), enemy), "Goblin should not be able to occupy Hero space")
	
	# Swarm CAN occupy
	swarm.global_position = Vector3(0, 0, 0)
	
	assert_false(grid.is_space_occupied(Vector3(0, 0, 0), swarm), "Swarm should be able to overlap Hero space")
	enemy.free()

func test_swarm_attack():
	# Both at origin
	hero.global_position = Vector3(0, 0, 0)
	swarm.global_position = Vector3(0, 0, 0)
	
	# Swarm uses Swarm Attack (1d4 piercing, DC 15)
	var attack = ActionSwarmAttack.new("Swarm Attack", 4, PFCombatConstants.DamageType.PIERCING, 15)
	
	# Stub the RNG to simulate a roll (seed(1) yields 18 + 5 = 23 vs 15 -> Success)
	seed(1)
	
	attack.execute(swarm)
	
	# Hero should take half damage (2) from success
	assert_eq(hero.health.current_hp, 18, "Hero should take 2 damage on a successful save")
