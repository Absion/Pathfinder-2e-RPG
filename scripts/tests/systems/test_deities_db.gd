extends GutTest

const THE_THIRTEEN_DEITIES: Dictionary = {
	"aethelis": { "name": "Aethelis", "sanctification": PFBiographyConstants.DivineSanctification.NONE },
	"kaldian": { "name": "Kaldian", "sanctification": PFBiographyConstants.DivineSanctification.MUST_CHOOSE_HOLY },
	"cankros": { "name": "Cankros", "sanctification": PFBiographyConstants.DivineSanctification.MUST_CHOOSE_UNHOLY },
	"tavrin": { "name": "Tavrin", "sanctification": PFBiographyConstants.DivineSanctification.NONE },
	"brada": { "name": "Brada", "sanctification": PFBiographyConstants.DivineSanctification.NONE },
	"kragthor": { "name": "Kragthor", "sanctification": PFBiographyConstants.DivineSanctification.CAN_CHOOSE_UNHOLY },
	"morwenna": { "name": "Morwenna", "sanctification": PFBiographyConstants.DivineSanctification.CAN_CHOOSE_HOLY },
	"oneris": { "name": "Oneris", "sanctification": PFBiographyConstants.DivineSanctification.NONE },
	"vurrok": { "name": "Vurrok", "sanctification": PFBiographyConstants.DivineSanctification.CAN_CHOOSE_EITHER },
	"severin": { "name": "Severin", "sanctification": PFBiographyConstants.DivineSanctification.CAN_CHOOSE_HOLY },
	"bathyos": { "name": "Bathyos", "sanctification": PFBiographyConstants.DivineSanctification.CAN_CHOOSE_UNHOLY },
	"stryvan": { "name": "Stryvan", "sanctification": PFBiographyConstants.DivineSanctification.CAN_CHOOSE_EITHER },
	"corvyna": { "name": "Corvyna", "sanctification": PFBiographyConstants.DivineSanctification.CAN_CHOOSE_EITHER }
}

func before_all():
	PFContext.init_shared_services()

func test_the_thirteen_deities_hydration():
	var db = PFDatabase.get_instance()
	if db == null:
		db = PFDatabase.new()
		add_child_autofree(db)

	for deity_id in THE_THIRTEEN_DEITIES:
		var expected = THE_THIRTEEN_DEITIES[deity_id]
		var deity = db.get_deity(deity_id)
		
		assert_not_null(deity, "Deity '%s' should load successfully from DB" % deity_id)
		if deity != null:
			assert_eq(deity.entity_name, expected["name"], "Deity '%s' name mismatch" % deity_id)
			assert_eq(deity.category, "The Thirteen", "Deity '%s' category should be 'The Thirteen'" % deity_id)
			assert_eq(deity.divine_sanctification, expected["sanctification"], "Deity '%s' sanctification mismatch" % deity_id)
			assert_false(deity.edicts.is_empty(), "Deity '%s' edicts should not be empty" % deity_id)
			assert_false(deity.anathema.is_empty(), "Deity '%s' anathema should not be empty" % deity_id)
			assert_false(deity.domains.is_empty(), "Deity '%s' domains should not be empty" % deity_id)

func after_all():
	PFContext.cleanup_shared_services()
