extends GutTest

const DEITY_EDICT_IDS: Array[String] = [
	"edict_study",
	"edict_time_acceptance",
	"edict_pattern_recognition",
	"edict_protect_weak",
	"edict_confront_horrors",
	"edict_greet_dawn",
	"edict_stand_ground",
	"edict_allow_rot",
	"edict_spread_sickness",
	"edict_embrace_decay",
	"edict_travel_new_road",
	"edict_trust_chance",
	"edict_share_story",
	"edict_defy_tyrants",
	"edict_build_structures",
	"edict_fair_trade",
	"edict_respect_laws",
	"edict_invest_civilization",
	"edict_crush_opposition",
	"edict_inspire_fear",
	"edict_strike_without_warning",
	"edict_comfort_grieving",
	"edict_proper_burial",
	"edict_embrace_quiet",
	"edict_trust_intuition",
	"edict_create_subconscious_art",
	"edict_sleep_beneath_moonlight",
	"edict_hunt_survival",
	"edict_embrace_primal",
	"edict_allow_wild_reclaim",
	"edict_speak_truth",
	"edict_hone_mind_body",
	"edict_judge_by_actions",
	"edict_keep_secrets",
	"edict_seek_forbidden_lore",
	"edict_embrace_cold_isolation",
	"edict_seize_leadership",
	"edict_improve_station",
	"edict_assert_superiority",
	"edict_protect_bloodline",
	"edict_honor_ancestors",
	"edict_endure_pain"
]

func before_all():
	PFContext.init_shared_services()

func test_deity_edicts_seeding_and_hooks():
	var db = PFDatabase.get_instance()
	if db == null:
		db = PFDatabase.new()
		add_child_autofree(db)

	for edict_id in DEITY_EDICT_IDS:
		var s_name = StringName(edict_id)
		
		# Test PFBeliefs validation helper
		assert_true(PFBeliefs.is_valid_edict(s_name), "Edict '%s' should be valid in PFBeliefs" % edict_id)
		
		# Test DB query via get_belief_data
		var data = db.get_belief_data(s_name)
		assert_false(data.is_empty(), "Edict data for '%s' should not be empty" % edict_id)
		if not data.is_empty():
			assert_eq(data["type"], "edict", "Type for '%s' should be 'edict'" % edict_id)
			assert_eq(data["mechanic_hook"], "deity_edict", "Mechanic hook for '%s' should be 'deity_edict'" % edict_id)
			
		# Test query via get_edict_data delegate
		var edict_dict = db.get_edict_data(edict_id)
		assert_false(edict_dict.is_empty(), "get_edict_data('%s') should return valid dict" % edict_id)

func after_all():
	PFContext.cleanup_shared_services()
