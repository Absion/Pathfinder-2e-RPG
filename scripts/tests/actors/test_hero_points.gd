extends GutTest



func test_hero_points():
	# Player starts with 1 hero point
	var player = PFPlayerCharacter.new("Valeros", [&"human", &"humanoid"], 1, 20, 0, 0, 0)
	assert_eq(player.hero_points, 1)
	
	# Can spend one
	assert_true(player.spend_hero_point())
	assert_eq(player.hero_points, 0)
	
	# Cannot spend when at 0
	assert_false(player.spend_hero_point())
	assert_eq(player.hero_points, 0)
	
	# Can gain hero points
	player.gain_hero_point()
	assert_eq(player.hero_points, 1)
	player.gain_hero_point()
	assert_eq(player.hero_points, 2)
	player.gain_hero_point()
	assert_eq(player.hero_points, 3)
	
	# Caps at 3
	player.gain_hero_point()
	assert_eq(player.hero_points, 3)

func test_heroic_recovery():

	var player = PFPlayerCharacter.new("Valeros", [&"human", &"humanoid"], 1, 20, 0, 0, 0)
	
	player.take_damage(25) # Drop below 0 HP
	player.apply_condition(PFCondition.create("dying", 1))
	
	assert_true(player.has_condition("dying"))
	assert_eq(player.health.current_hp, 0) # clamped to 0
	
	player.heroic_recovery()
	
	assert_eq(player.hero_points, 0)
	assert_false(player.has_condition("dying"))
	assert_true(player.has_condition("unconscious"))
	assert_eq(player.health.current_hp, 0)

func test_heroic_reroll():
	var player = PFPlayerCharacter.new("Valeros", [&"human", &"humanoid"], 1, 20, 0, 0, 0)
	
	# Start with 1 hero point, should successfully reroll
	var reroll = player.heroic_reroll()
	assert_true(reroll >= 10) # Because 1-9 becomes 11-19, and 10+ is 10+, it will ALWAYS be >= 10
	assert_true(reroll <= 20)
	assert_eq(player.hero_points, 0)
	
	# Out of points, should return -1
	assert_eq(player.heroic_reroll(), -1)
