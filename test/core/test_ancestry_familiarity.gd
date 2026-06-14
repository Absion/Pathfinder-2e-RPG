extends GdUnitTestSuite

func test_ancestry_weapon_familiarity():
	# Create an elf character
	var elf = PFPlayerCharacter.new("Legolas", [&"humanoid", &"elf"], 1, 20, 0, 0, 0)
	auto_free(elf)
	add_child(elf)
	
	# Give them the familiar feat
	var feat = PFFeat.new(&"elf_weapon_familiarity")
	elf.feats.append(feat)
	
	# Give them an ancestry
	elf.ancestry = PFAncestry.new("Elf", 6, &"medium", 30, [], [], [], [], PFBiographyConstants.Vision.LOW_LIGHT, [], 0, 0, 0, 0, [], [], "", "", "", "", [], [], [], [&"elf", &"humanoid"])
	
	
	# Mock sheet and stats
	elf.sheet = PFProficiencySheet.new()
	# Set Simple to Trained (+2), Martial to Untrained (+0)
	elf.sheet.set_weapon_rank(PFEquipmentConstants.WeaponCategory.SIMPLE, PFMathConstants.ProficiencyRank.TRAINED)
	elf.sheet.set_weapon_rank(PFEquipmentConstants.WeaponCategory.MARTIAL, PFMathConstants.ProficiencyRank.UNTRAINED)
	
	elf.attributes.str_mod = 0
	elf.attributes.dex_mod = 0
	
	# Create a standard martial weapon with NO ancestry trait
	var longsword = PFWeapon.new("Longsword", [], 1, 1.0, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.MARTIAL, PFEquipmentConstants.WeaponGroup.SWORD, 1, 8, PFCombatConstants.DamageType.SLASHING)
	auto_free(longsword)
	
	# Create an advanced elven weapon
	var elven_curve_blade = PFWeapon.new("Elven Curve Blade", [&"elf", &"finesse"], 1, 2.0, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.ADVANCED, PFEquipmentConstants.WeaponGroup.SWORD, 1, 8, PFCombatConstants.DamageType.SLASHING)
	auto_free(elven_curve_blade)
	
	# Create a martial elven weapon
	var elven_branched_spear = PFWeapon.new("Elven Branched Spear", [&"elf", &"reach", &"finesse"], 1, 2.0, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.MARTIAL, PFEquipmentConstants.WeaponGroup.SPEAR, 1, 8, PFCombatConstants.DamageType.PIERCING)
	auto_free(elven_branched_spear)
	
	# Test the longsword (Martial, no trait). Should use Martial proficiency -> Untrained (+0).
	var ls_bonus = elf.get_strike_bonus(longsword)
	assert_int(ls_bonus).is_equal(0)
	
	# Test the Elven Curve Blade (Advanced -> Martial). Should use Martial proficiency -> Untrained (+0).
	var ecb_bonus = elf.get_strike_bonus(elven_curve_blade)
	assert_int(ecb_bonus).is_equal(0)
	
	# Test the Elven Branched Spear (Martial -> Simple). Should use Simple proficiency -> Trained (+2 + Level = +3).
	var ebs_bonus = elf.get_strike_bonus(elven_branched_spear)
	assert_int(ebs_bonus).is_equal(3) # +2 Trained + 1 Level = 3
