extends GutTest

func test_flanking_standard():
	var target = PFPlayerCharacter.new("Target", [], 1, 10, 0, 0, 0)
	var attacker = PFPlayerCharacter.new("Attacker", [], 1, 10, 0, 0, 0)
	var ally = PFPlayerCharacter.new("Ally", [], 1, 10, 0, 0, 0)
	
	# Place target in center
	target.position = Vector3(0, 0, 0)
	
	# Place attacker to the left, ally to the right
	attacker.position = Vector3(-1, 0, 0)
	ally.position = Vector3(1, 0, 0)
	assert_true(PFSpatialMath.is_flanking(attacker, target, ally))
	
	# Place attacker top left, ally bottom right (Corners)
	attacker.position = Vector3(-1, 0, -1)
	ally.position = Vector3(1, 0, 1)
	assert_true(PFSpatialMath.is_flanking(attacker, target, ally))
	
	# Place them on the same side (Not flanking)
	attacker.position = Vector3(-1, 0, 0)
	ally.position = Vector3(-1, 0, 1)
	assert_false(PFSpatialMath.is_flanking(attacker, target, ally))
	
func test_gang_up_exception():
	var target = PFPlayerCharacter.new("Target", [], 1, 10, 0, 0, 0)
	var rogue = PFPlayerCharacter.new("Rogue", [], 1, 10, 0, 0, 0)
	var ally = PFPlayerCharacter.new("Ally", [], 1, 10, 0, 0, 0)
	
	target.position = Vector3(0, 0, 0)
	
	# They are on the SAME side
	rogue.position = Vector3(-1, 0, 0)
	ally.position = Vector3(-1, 0, 1)
	
	# Ordinarily, this is NOT flanking
	assert_false(PFSpatialMath.is_flanking(rogue, target, ally))
	
	# Give Rogue Gang Up
	rogue.passive_features.append(&"gang_up")
	
	# Because both are adjacent, Gang Up makes it a valid flank!
	assert_true(PFSpatialMath.is_flanking(rogue, target, ally))
	
func test_deny_advantage_exception():
	# Level 5 Rogue vs Level 5 Attacker
	var rogue = PFPlayerCharacter.new("Rogue", [], 5, 50, 0, 0, 0)
	var attacker = PFPlayerCharacter.new("Goblin", [], 5, 30, 0, 0, 0)
	var ally = PFPlayerCharacter.new("Hobgoblin", [], 5, 30, 0, 0, 0)
	
	rogue.position = Vector3(0, 0, 0)
	attacker.position = Vector3(-1, 0, 0)
	ally.position = Vector3(1, 0, 0)
	
	# Standard flank works
	assert_true(PFSpatialMath.is_flanking(attacker, rogue, ally))
	
	# Give Rogue Deny Advantage
	rogue.passive_features.append(&"deny_advantage")
	
	# Attacker is same level, Deny Advantage negates the flank!
	assert_false(PFSpatialMath.is_flanking(attacker, rogue, ally))
	
	# If attacker is Level 6 (Higher than Rogue), Deny Advantage fails to protect the Rogue
	attacker.level = 6
	assert_true(PFSpatialMath.is_flanking(attacker, rogue, ally))

func test_aoe_functions_exist():
	# Since full 3D Physics testing requires active World3D spaces and CollisionObjects,
	# we will verify that the methods exist and correctly return empty arrays when passed null.
	var origin = Vector3(0, 0, 0)
	var dir = Vector3(0, 0, -1)
	
	var burst = PFSpatialMath.get_burst_targets(null, origin, 20.0)
	assert_true(burst.is_empty())
	
	var cone = PFSpatialMath.get_cone_targets(null, origin, dir, 30.0)
	assert_true(cone.is_empty())
	
	var line = PFSpatialMath.get_line_targets(null, origin, dir, 30.0)
	assert_true(line.is_empty())
	
	var target = PFPlayerCharacter.new("Target", [], 1, 10, 0, 0, 0)
	var emanation = PFSpatialMath.get_emanation_targets(null, target, 15.0)
	assert_true(emanation.is_empty())
	
	var splash = PFSpatialMath.get_splash_targets(null, origin)
	assert_true(splash.is_empty())
