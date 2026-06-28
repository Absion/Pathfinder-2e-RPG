# test_conditions.gd
class_name TestConditions
extends GutTest

var database: PFDatabase

func before_all():
	database = PFDatabase.get_instance()
	if database == null:
		database = PFDatabase.new()
		database.name = "PFDatabase"
		Engine.get_main_loop().root.add_child(database)
		database._ready()

func after_all():
	if is_instance_valid(database):
		pass # database.queue_free()

func before_each():
	PFContext.init_shared_services()

func after_each():
	PFContext.cleanup_shared_services()

func test_condition_stacking():
	var hero = autofree(PFPlayerCharacter.new("Valeros", [&"human"], 1, 20, 2, 2, 2))
	
	var fright1 = PFCondition.create(&"frightened", 1)
	hero.apply_condition(fright1)
	assert_eq(hero.get_condition("frightened").value, 1)
	
	# Stack higher
	var fright3 = PFCondition.create(&"frightened", 3)
	hero.apply_condition(fright3)
	assert_eq(hero.get_condition("frightened").value, 3)
	
	# Apply lower, shouldn't change
	var fright2 = PFCondition.create(&"frightened", 2)
	hero.apply_condition(fright2)
	assert_eq(hero.get_condition("frightened").value, 3)

func test_flat_modifiers():
	var hero = autofree(PFPlayerCharacter.new("Valeros", [&"human"], 1, 20, 2, 2, 2))
	var off_guard = PFCondition.create(&"off_guard")
	hero.apply_condition(off_guard)
	
	assert_eq(hero.get_condition_modifier(&"ac"), -2)

func test_action_economy_slowed_and_stunned():
	var hero = autofree(PFPlayerCharacter.new("Valeros", [&"human"], 1, 20, 2, 2, 2))
	
	var slowed = PFCondition.create(&"slowed", 2)
	hero.apply_condition(slowed)
	
	hero.action_economy.start_turn()
	assert_eq(hero.action_economy.actions_remaining, 1) # 3 - 2 = 1
	
	var stunned = PFCondition.create(&"stunned", 1)
	hero.apply_condition(stunned)
	
	# Stunned overrides Slowed (Stunned 1 + Slowed 2) Wait, PF2e says Stunned overrides Slowed. 
	# "If the duration of your stunned condition ends while you are slowed, you count the actions lost to the stunned condition toward those lost to being slowed"
	# So if Stunned 1 and Slowed 2 -> lose 1 to Stunned (stunned value is now 0), then 1 more to slowed. Total lost: 2. Remaining: 1
	hero.action_economy.start_turn()
	assert_eq(hero.action_economy.actions_remaining, 1) # Wait, my implementation: Stunned 1 -> loses 1, leaves 2 actions. Stunned overrides slowed, wait, no. My code does: `if stunned: actions_lost = stunned.value`. This means Stunned entirely ignores Slowed. 
	# Let's see if my code works exactly like the rules!
	
	# Quickened test
	var quickened = PFCondition.create(&"quickened", 1)
	hero.apply_condition(quickened)
	# Remove stunned
	hero.remove_condition("stunned")
	hero.remove_condition("slowed")
	
	hero.action_economy.start_turn()
	assert_eq(hero.action_economy.actions_remaining, 4)

func test_subconditions():
	var hero = autofree(PFPlayerCharacter.new("Valeros", [&"human"], 1, 20, 2, 2, 2))
	var grabbed = PFCondition.create(&"grabbed")
	hero.apply_condition(grabbed)
	
	assert_true(hero.has_condition("off_guard"))
	assert_true(hero.has_condition("immobilized"))
	
	hero.remove_condition("grabbed")
	assert_false(hero.has_condition("off_guard"))
	assert_false(hero.has_condition("immobilized"))

func test_dying_rules_player():
	var hero = autofree(PFPlayerCharacter.new("Valeros", [&"human"], 1, 20, 2, 2, 2))
	hero.health.current_hp = 10
	
	# Lethal damage
	var tags1: Array[StringName] = [&"lethal"]
	hero.health.apply_damage(10, PFCombatConstants.DamageType.SLASHING, tags1)
	assert_true(hero.has_condition("dying"))
	assert_eq(hero.get_condition("dying").value, 1)
	assert_true(hero.has_condition("unconscious"))
	
	# Wounded modifies dying
	hero.health.heal(10)
	hero.remove_condition("dying")
	hero.remove_condition("unconscious")
	hero.apply_condition(PFCondition.create(&"wounded", 1))
	var tags2: Array[StringName] = [&"lethal"]
	hero.health.apply_damage(10, PFCombatConstants.DamageType.SLASHING, tags2)
	assert_eq(hero.get_condition("dying").value, 2)

func test_dying_rules_nonlethal():
	var hero = autofree(PFPlayerCharacter.new("Valeros", [&"human"], 1, 20, 2, 2, 2))
	hero.health.current_hp = 10
	
	# Nonlethal damage
	var tags3: Array[StringName] = [&"nonlethal"]
	hero.health.apply_damage(10, PFCombatConstants.DamageType.BLUDGEONING, tags3)
	assert_false(hero.has_condition("dying"))
	assert_true(hero.has_condition("unconscious"))

func test_npc_dying_rules():
	var goblin = autofree(PFNpc.new(&"goblin", "Goblin", [&"goblinoid", &"humanoid"], -1, 6, 2, 4, 1, 0, 3, 1, -1, 0, -1))
	goblin.health.current_hp = 6
	
	# Lethal damage instantly kills NPCs
	var tags4: Array[StringName] = [&"lethal"]
	goblin.health.apply_damage(6, PFCombatConstants.DamageType.SLASHING, tags4)
	assert_false(goblin.has_condition("dying"))
	assert_true(goblin.has_condition("dead"))
	assert_true(goblin.inventory.is_lootable())
	
	# Heal and reset for nonlethal
	goblin.health.heal(6)
	goblin.remove_condition("dead")
	
	var tags5: Array[StringName] = [&"nonlethal"]
	goblin.health.apply_damage(6, PFCombatConstants.DamageType.BLUDGEONING, tags5)
	assert_false(goblin.has_condition("dead"))
	assert_true(goblin.has_condition("unconscious"))
	assert_true(goblin.inventory.is_lootable())


