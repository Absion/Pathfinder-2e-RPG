extends GutTest

var actor: PFPlayerCharacter

func before_each():
	PFContext.init_shared_services()
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
	var receptacle = PFSpellcastingReceptacle.new("wizard_class", PFMagicConstants.MagicTradition.ARCANE, PFMagicConstants.CasterType.PREPARED)
	# Give the wizard level 5 slots (Rank 1: 3, Rank 2: 3, Rank 3: 2)
	receptacle.spells_per_rank[1] = 3
	receptacle.spells_per_rank[2] = 3
	receptacle.spells_per_rank[3] = 2
	actor.spellbook.add_receptacle(receptacle)
	actor.spellbook.restore_daily_slots()

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


func after_each():
	PFContext.cleanup_shared_services()
