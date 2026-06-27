extends "res://addons/gut/test.gd"

var aura_manager: PFAuraManager

func before_each():
	aura_manager = PFAuraManager.new()

func test_banner_emits_aura():
	var banner = PFBanner.new("Test Banner", [&"magical"], 1, 0.0, &"bless", 30)
	banner.aura_manager = aura_manager
	
	var actor = autofree(PFActor.new("Banner Carrier", [], 1, 10))
	
	assert_eq(aura_manager.active_auras.size(), 0)
	
	banner.on_equipped(actor)
	
	assert_eq(aura_manager.active_auras.size(), 1)
	assert_eq(aura_manager.active_auras[0].condition_id, &"bless")
	assert_eq(aura_manager.active_auras[0].radius_feet, 30)
	
	banner.on_unequipped(actor)
	assert_eq(aura_manager.active_auras.size(), 0)
