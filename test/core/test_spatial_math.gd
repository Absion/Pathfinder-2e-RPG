extends GdUnitTestSuite

func test_flanking_standard():
	var target = auto_free(PFPlayerCharacter.new("Target", [], 1, 10, 0, 0, 0))
	var attacker = auto_free(PFPlayerCharacter.new("Attacker", [], 1, 10, 0, 0, 0))
	var ally = auto_free(PFPlayerCharacter.new("Ally", [], 1, 10, 0, 0, 0))
	
	# Place target in center
	target.position = Vector3(0, 0, 0)
	
	# Place attacker to the left, ally to the right
	attacker.position = Vector3(-1, 0, 0)
	ally.position = Vector3(1, 0, 0)
	assert_bool(PFSpatialMath.is_flanking(attacker, target, ally)).is_true()
	
	# Place attacker top left, ally bottom right (Corners)
	attacker.position = Vector3(-1, 0, -1)
	ally.position = Vector3(1, 0, 1)
	assert_bool(PFSpatialMath.is_flanking(attacker, target, ally)).is_true()
	
	# Place them on the same side (Not flanking)
	attacker.position = Vector3(-1, 0, 0)
	ally.position = Vector3(-1, 0, 1)
	assert_bool(PFSpatialMath.is_flanking(attacker, target, ally)).is_false()
	
func test_gang_up_exception():
	var target = auto_free(PFPlayerCharacter.new("Target", [], 1, 10, 0, 0, 0))
	var rogue = auto_free(PFPlayerCharacter.new("Rogue", [], 1, 10, 0, 0, 0))
	var ally = auto_free(PFPlayerCharacter.new("Ally", [], 1, 10, 0, 0, 0))
	
	target.position = Vector3(0, 0, 0)
	
	# They are on the SAME side
	rogue.position = Vector3(-1, 0, 0)
	ally.position = Vector3(-1, 0, 1)
	
	# Ordinarily, this is NOT flanking
	assert_bool(PFSpatialMath.is_flanking(rogue, target, ally)).is_false()
	
	# Give Rogue Gang Up
	rogue.passive_features.append(&"gang_up")
	
	# Because both are adjacent, Gang Up makes it a valid flank!
	assert_bool(PFSpatialMath.is_flanking(rogue, target, ally)).is_true()
	
func test_deny_advantage_exception():
	# Level 5 Rogue vs Level 5 Attacker
	var rogue = auto_free(PFPlayerCharacter.new("Rogue", [], 5, 50, 0, 0, 0))
	var attacker = auto_free(PFPlayerCharacter.new("Goblin", [], 5, 30, 0, 0, 0))
	var ally = auto_free(PFPlayerCharacter.new("Hobgoblin", [], 5, 30, 0, 0, 0))
	
	rogue.position = Vector3(0, 0, 0)
	attacker.position = Vector3(-1, 0, 0)
	ally.position = Vector3(1, 0, 0)
	
	# Standard flank works
	assert_bool(PFSpatialMath.is_flanking(attacker, rogue, ally)).is_true()
	
	# Give Rogue Deny Advantage
	rogue.passive_features.append(&"deny_advantage")
	
	# Attacker is same level, Deny Advantage negates the flank!
	assert_bool(PFSpatialMath.is_flanking(attacker, rogue, ally)).is_false()
	
	# If attacker is Level 6 (Higher than Rogue), Deny Advantage fails to protect the Rogue
	attacker.level = 6
	assert_bool(PFSpatialMath.is_flanking(attacker, rogue, ally)).is_true()
