extends GutTest

var actor: PFPlayerCharacter
var tm: PFTimeManager

func before_each():
	actor = autofree(PFPlayerCharacter.new("Wizard", [&"human", &"humanoid"], 5, 40, 5, 5, 7, 25))
	var c_data = {
		"name": "Wizard",
		"hp_per_level": 6,
		"perception_rank": PFMathConstants.ProficiencyRank.TRAINED,
		"class_dc_rank": PFMathConstants.ProficiencyRank.TRAINED,
		"save_fort": PFMathConstants.ProficiencyRank.TRAINED,
		"save_ref": PFMathConstants.ProficiencyRank.TRAINED,
		"save_will": PFMathConstants.ProficiencyRank.EXPERT,
		"trained_skills_count": 2,
		"is_spellcaster": 1,
		"caster_type": PFMagicConstants.CasterType.PREPARED,
		"spell_tradition": PFMagicConstants.MagicTradition.ARCANE,
		"spell_proficiency": PFMathConstants.ProficiencyRank.TRAINED,
		"spell_progression": PFMagicConstants.SpellProgression.FULL_CASTER,
		"key_abilities": ""
	}
	actor.actor_class = PFClass.new("Wizard", c_data["hp_per_level"], [], c_data["perception_rank"], c_data["class_dc_rank"],
		{"fort": c_data["save_fort"], "ref": c_data["save_ref"], "will": c_data["save_will"]},
		c_data["trained_skills_count"], {}, {}, "", [], [],
		c_data["is_spellcaster"] == 1, c_data["caster_type"], c_data["spell_tradition"],
		c_data["spell_proficiency"], c_data["spell_progression"])
	
	actor.spellbook = PFSpellbook.new(actor)
	var rep = PFSpellcastingReceptacle.new("wizard_class", PFMagicConstants.MagicTradition.ARCANE, PFMagicConstants.CasterType.PREPARED)
	# Give the wizard level 5 slots (Rank 1: 3, Rank 2: 3, Rank 3: 2)
	rep.spells_per_rank[1] = 3
	rep.spells_per_rank[2] = 3
	rep.spells_per_rank[3] = 2
	actor.spellbook.add_receptacle(rep)
	actor.spellbook.restore_daily_slots()
	
	tm = autofree(PFTimeManager.new())
	tm._ready()

func test_wand_cast():
	var wand = PFWand.new("Wand of Fireball", [], 5, 160.0, &"fireball", 3)
	
	# Initial cast
	assert_false(wand.is_expended, "Wand should start unexpended")
	var result = wand.cast_wand(actor)
	assert_true(result, "First cast should succeed")
	assert_true(wand.is_expended, "Wand should be expended after casting")

func test_wand_overcharge_success():
	# Stub the actor's flat check to always succeed for this test
	actor.set_meta("test_flat_check", 15)
	
	var wand = PFWand.new("Wand of Fireball", [], 5, 160.0, &"fireball", 3)
	wand.is_expended = true
	
	var result = wand.cast_wand(actor)
	assert_true(result, "Overcharge should succeed on a 15")
	assert_false(wand.wand_destroyed, "Wand should not be destroyed on success")
	assert_true(wand.is_expended, "Wand should remain expended")

func test_wand_overcharge_failure():
	actor.set_meta("test_flat_check", 5)
	
	var wand = PFWand.new("Wand of Fireball", [], 5, 160.0, &"fireball", 3)
	wand.is_expended = true
	
	var result = wand.cast_wand(actor)
	assert_false(result, "Overcharge should fail on a 5")
	assert_true(wand.wand_destroyed, "Wand should be destroyed on failure")

func test_staff_preparation():
	var staff = PFStaff.new("Staff of Fire", [], 3, 60.0, {})
	actor.inventory.add_item(staff)
	
	actor._on_rested_for_night()
	
	assert_eq(staff.current_charges, 0, "Staff charges should be cleared on long rest")
	
	# Actor prepares the staff manually
	staff.prepare_staff(actor, 3, 0)
	
	assert_eq(staff.max_charges, 3, "Staff should gain 3 charges matching the wizard's highest slot")
	assert_eq(staff.current_charges, 3, "Staff should be fully charged")

func test_staff_standard_cast():
	var staff = PFStaff.new("Staff of Fire", [], 3, 60.0, {3: [&"fireball"]})
	staff.current_charges = 3
	
	# Trying to cast a spell it doesn't have
	var res1 = staff.cast_staff_spell(actor, &"magic_missile", 1)
	assert_false(res1, "Should fail to cast a spell not in the staff")
	
	# Casting a spell it does have
	var res2 = staff.cast_staff_spell(actor, &"fireball", 3)
	assert_true(res2, "Should succeed casting a spell in the staff")
	assert_eq(staff.current_charges, 0, "Should deduct 3 charges")
	
	# Trying to cast again with 0 charges
	var res3 = staff.cast_staff_spell(actor, &"fireball", 3)
	assert_false(res3, "Should fail to cast without enough charges")

func test_staff_spontaneous_cast():
	# Convert our wizard to spontaneous for this test
	var rep = actor.spellbook.receptacles[0]
	rep.caster_type = PFMagicConstants.CasterType.SPONTANEOUS
	actor.actor_class.caster_type = PFMagicConstants.CasterType.SPONTANEOUS
	
	var staff = PFStaff.new("Staff of Fire", [], 3, 60.0, {3: [&"fireball"]})
	staff.current_charges = 3
	
	var initial_rank3_slots = rep.get_available_slots(3) # Should be 2
	assert_eq(initial_rank3_slots, 2)
	
	# Cast spontaneously: 1 charge + 1 rank 3 slot
	var res = staff.cast_staff_spell(actor, &"fireball", 3, 3)
	assert_true(res, "Should succeed spontaneously casting")
	assert_eq(staff.current_charges, 2, "Should deduct 1 charge")
	assert_eq(rep.get_available_slots(3), 1, "Should deduct 1 rank 3 spell slot")
