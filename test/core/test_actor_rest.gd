extends GdUnitTestSuite

const Player = preload("res://scripts/actors/players/pf_player_character.gd")
const Condition = preload("res://scripts/conditions/pf_condition.gd")

func test_rest_healing():
	# Player level 2, CON modifier +2, max hp 30.
	var player = Player.new("Valeros", [&"human", &"humanoid"], 2, 30, 0, 0, 0)
	player.attributes.apply_background_boost(&"con")
	player.attributes.apply_class_boost(&"con")
	# CON mod should be +2
	
	# Damage the player
	player.take_damage(10)
	assert_int(player.health.current_hp).is_equal(20)
	
	# Trigger rest. Should heal Level (2) * Con Mod (2) = 4 HP.
	player._on_rested_for_night()
	
	assert_int(player.health.current_hp).is_equal(24)

func test_rest_condition_decay():
	var player = Player.new("Valeros", [&"human", &"humanoid"], 1, 30, 0, 0, 0)
	player.attributes.con_mod = 1
	
	player.apply_condition(Condition.create("doomed", 2))
	player.apply_condition(Condition.create("drained", 1))
	player.apply_condition(Condition.create("fatigued", 1))
	
	player._on_rested_for_night()
	
	# Doomed should drop from 2 to 1
	assert_bool(player.has_condition("doomed")).is_true()
	assert_int(player.get_condition("doomed").value).is_equal(1)
	
	# Drained should drop from 1 to 0 (removed)
	assert_bool(player.has_condition("drained")).is_false()
	
	# Fatigued should be completely removed
	assert_bool(player.has_condition("fatigued")).is_false()

func test_rest_minimum_healing():
	# CON modifier -1, level 5
	var player = Player.new("Ezren", [&"human", &"humanoid"], 5, 30, 0, 0, 0)
	player.attributes.apply_voluntary_flaw(&"con") 
	# CON mod should be -1 
	
	player.take_damage(10)
	assert_int(player.health.current_hp).is_equal(20)
	
	# Con mod (-1) * Level (5) = -5. Minimum is 1.
	player._on_rested_for_night()
	
	assert_int(player.health.current_hp).is_equal(21)
