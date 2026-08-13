extends GutTest

const DEITY_ANATHEMA_IDS: Array[String] = [
	"anathema_destroy_history",
	"anathema_act_blindly",
	"anathema_rewrite_past",
	"anathema_flee_battle",
	"anathema_allow_monsters",
	"anathema_extinguish_flame",
	"anathema_cure_without_toll",
	"anathema_preserve_corpse",
	"anathema_construct_monuments",
	"anathema_own_property",
	"anathema_refuse_gamble",
	"anathema_enforce_laws",
	"anathema_destroy_building",
	"anathema_break_contract",
	"anathema_hoard_wealth",
	"anathema_show_mercy",
	"anathema_allow_insult",
	"anathema_submit_weaker",
	"anathema_deny_mourning",
	"anathema_force_happiness",
	"anathema_desecrate_tomb",
	"anathema_rely_empirical",
	"anathema_wake_dreamer",
	"anathema_suppress_hallucination",
	"anathema_domesticate_predator",
	"anathema_suppress_instincts",
	"anathema_destroy_nature",
	"anathema_tell_lie",
	"anathema_cloud_judgment",
	"anathema_indulge_excess",
	"anathema_reveal_truth",
	"anathema_show_fear",
	"anathema_share_knowledge",
	"anathema_accept_subordinate",
	"anathema_show_doubt",
	"anathema_allow_outmaneuver",
	"anathema_betray_family",
	"anathema_refuse_bloodshed",
	"anathema_forget_ancestors"
]

func before_all():
	PFContext.init_shared_services()

func test_deity_anathemas_seeding_and_hooks():
	var db = PFDatabase.get_instance()
	if db == null:
		db = PFDatabase.new()
		add_child_autofree(db)

	for anathema_id in DEITY_ANATHEMA_IDS:
		var s_name = StringName(anathema_id)
		
		# Test PFBeliefs validation helper
		assert_true(PFBeliefs.is_valid_anathema(s_name), "Anathema '%s' should be valid in PFBeliefs" % anathema_id)
		
		# Test DB query via get_belief_data
		var data = db.get_belief_data(s_name)
		assert_false(data.is_empty(), "Anathema data for '%s' should not be empty" % anathema_id)
		if not data.is_empty():
			assert_eq(data["type"], "anathema", "Type for '%s' should be 'anathema'" % anathema_id)
			assert_eq(data["mechanic_hook"], "deity_anathema", "Mechanic hook for '%s' should be 'deity_anathema'" % anathema_id)
			
		# Test query via get_anathema_data delegate
		var anathema_dict = db.get_anathema_data(anathema_id)
		assert_false(anathema_dict.is_empty(), "get_anathema_data('%s') should return valid dict" % anathema_id)

func after_all():
	PFContext.cleanup_shared_services()
