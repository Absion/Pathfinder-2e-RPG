extends GdUnitTestSuite

const Player = preload("res://scripts/actors/players/pf_player_character.gd")

func test_hero_points():
	# Player starts with 1 hero point
	var player = auto_free(Player.new("Valeros", [&"human", &"humanoid"], 1, 20, 0, 0, 0))
	assert_int(player.hero_points).is_equal(1)
	
	# Can spend one
	assert_bool(player.spend_hero_point()).is_true()
	assert_int(player.hero_points).is_equal(0)
	
	# Cannot spend when at 0
	assert_bool(player.spend_hero_point()).is_false()
	assert_int(player.hero_points).is_equal(0)
	
	# Can gain hero points
	player.gain_hero_point()
	assert_int(player.hero_points).is_equal(1)
	player.gain_hero_point()
	assert_int(player.hero_points).is_equal(2)
	player.gain_hero_point()
	assert_int(player.hero_points).is_equal(3)
	
	# Caps at 3
	player.gain_hero_point()
	assert_int(player.hero_points).is_equal(3)

func test_heroic_recovery():
	var Condition = preload("res://scripts/conditions/pf_condition.gd")
	var player = auto_free(Player.new("Valeros", [&"human", &"humanoid"], 1, 20, 0, 0, 0))
	
	player.take_damage(25) # Drop below 0 HP
	player.apply_condition(Condition.create("dying", 1))
	
	assert_bool(player.has_condition("dying")).is_true()
	assert_int(player.health.current_hp).is_equal(0) # clamped to 0
	
	player.heroic_recovery()
	
	assert_int(player.hero_points).is_equal(0)
	assert_bool(player.has_condition("dying")).is_false()
	assert_bool(player.has_condition("unconscious")).is_true()
	assert_int(player.health.current_hp).is_equal(0)

func test_heroic_reroll():
	var player = auto_free(Player.new("Valeros", [&"human", &"humanoid"], 1, 20, 0, 0, 0))
	
	# Start with 1 hero point, should successfully reroll
	var reroll = player.heroic_reroll()
	assert_int(reroll).is_greater_equal(10) # Because 1-9 becomes 11-19, and 10+ is 10+, it will ALWAYS be >= 10
	assert_int(reroll).is_less_equal(20)
	assert_int(player.hero_points).is_equal(0)
	
	# Out of points, should return -1
	assert_int(player.heroic_reroll()).is_equal(-1)
