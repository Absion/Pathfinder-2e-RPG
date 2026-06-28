# test_troops.gd
extends "res://addons/gut/test.gd"

var combat_context: PFCombatContext
var grid: PFCombatGrid
var troop: PFTroop
var enemy: PFNpc

func before_each():
	PFContext.init_shared_services()
	combat_context = PFCombatContext.new()
	add_child_autofree(combat_context)
	combat_context.enter_context()
	grid = combat_context.grid_manager
	
	# Troop with 30 HP. Threshold 1 = 20, Threshold 2 = 10
	troop = PFTroop.new(&"city_guard_troop", "City Guard Troop", [&"humanoid"], 1, 30, 2, 4, 1, 0, 0, 0, 0, 0, 0)
	enemy = PFNpc.new(&"goblin", "Goblin", [&"humanoid"], 1, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0)
	
	combat_context.add_child(troop)
	combat_context.add_child(enemy)
	
	combat_context.turn_manager.add_combatant(troop, false)
	combat_context.turn_manager.add_combatant(enemy, true)

func after_each():
	PFContext.cleanup_shared_services()
	combat_context.exit_context()
	troop.free()
	enemy.free()

func test_troop_initialization():
	assert_eq(troop.active_segments.size(), 4, "Troop should start with 4 segments")
	assert_eq(troop.threshold_1, 20, "Threshold 1 should be 20 (2/3 of 30)")
	assert_eq(troop.threshold_2, 10, "Threshold 2 should be 10 (1/3 of 30)")

func test_troop_segment_removal_single_target():
	# Position enemy near segment 0 (0,0,0)
	enemy.global_position = Vector3(-1, 0, -1)
	troop.global_position = Vector3(0, 0, 0)
	
	# Deal 12 damage (drops HP to 18, crossing Threshold 1 = 20)
	troop.take_damage(12, PFCombatConstants.DamageType.PIERCING, [], enemy, Vector3(0, 0, 0))
	
	assert_eq(troop.health.current_hp, 18, "Troop should have 18 HP")
	assert_eq(troop.active_segments.size(), 3, "Troop should have lost 1 segment")
	
	# The targeted segment (0,0,0) should have been removed
	assert_false(troop.active_segments.has(Vector3(0, 0, 0)), "Segment (0,0,0) should have been removed")

func test_troop_segment_removal_aoe():
	troop.global_position = Vector3(0, 0, 0)
	
	# Deal 12 damage (drops HP to 18) via an AoE spell with no specific attacker position
	troop.take_damage(12, PFCombatConstants.DamageType.FIRE, [&"area"])
	
	assert_eq(troop.active_segments.size(), 3, "Troop should have lost 1 segment")
	
func test_form_up_valid():
	troop.global_position = Vector3(0, 0, 0)
	
	# New layout: L-shape instead of 2x2 square
	# (0,0), (0,2), (0,4), (2,0)
	var new_layout: Array[Vector3] = [
		Vector3(0, 0, 0),
		Vector3(0, 0, 2),
		Vector3(0, 0, 4),
		Vector3(2, 0, 0)
	]
	
	var form_up = PFActionFormUp.new(Vector3(0, 0, 0), new_layout)
	assert_true(form_up.is_usable(troop), "Form Up should be valid with a contiguous L-shape")
	
	form_up.execute(troop)
	assert_eq(troop.active_segments[2], Vector3(0, 0, 4), "Troop layout should have updated")

func test_form_up_invalid_disjoint():
	troop.global_position = Vector3(0, 0, 0)
	
	# New layout with a gap
	var new_layout: Array[Vector3] = [
		Vector3(0, 0, 0),
		Vector3(0, 0, 2),
		Vector3(0, 0, 6), # Disjoint!
		Vector3(2, 0, 0)
	]
	
	var form_up = PFActionFormUp.new(Vector3(0, 0, 0), new_layout)
	assert_false(form_up.is_usable(troop), "Form Up should be invalid with disjoint segments")

func test_troop_occupancy():
	troop.global_position = Vector3(0, 0, 0)
	
	# Enemy trying to move into segment 1 (2, 0, 0)
	assert_true(grid.is_space_occupied(Vector3(2, 0, 0), enemy), "Space (2,0,0) should be occupied by the troop segment")
	assert_true(grid.is_space_occupied(Vector3(0, 0, 0), enemy), "Space (0,0,0) should be occupied by the troop segment")
	
	# Space (4,0,0) is outside the 2x2 blocks
	assert_false(grid.is_space_occupied(Vector3(4, 0, 0), enemy), "Space (4,0,0) should be free")
