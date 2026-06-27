extends "res://addons/gut/test.gd"

func test_spellheart_affix():
	var weapon = PFWeapon.new("Sword")
	var spellheart = PFSpellheart.new("Fiery Spellheart", [&"spellheart"], 1, 0.0, &"produce_flame", 1)
	
	var res = spellheart.attach_to(weapon)
	assert_true(res, "Should be able to attach spellheart to a weapon")
	
	var spellheart2 = PFSpellheart.new("Icy Spellheart")
	var res2 = spellheart2.attach_to(weapon)
	assert_false(res2, "Should fail to attach a second spellheart to the same weapon")
