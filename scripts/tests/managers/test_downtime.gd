extends GutTest

class_name TestDowntime

func get_test_name() -> String:
	return "Downtime Subsystem Tests (Crafting, Earn Income, Retraining)"

func test_downtime() -> void:
	print("\n--- Running Downtime Tests ---")
	
	PFContext.init_shared_services()
	
	# We need a TimeManager and DowntimeManager
	var time_mgr = autofree(PFTimeManager.new())
	var downtime_mgr = autofree(PFDowntimeManager.new())
	# Simulate _ready since they aren't in tree
	PFTimeManager._instance = time_mgr
	downtime_mgr._ready()
	
	var smith = autofree(PFPlayerCharacter.new("Blacksmith", [&"humanoid"], 3, 0, 0, 0, 0))
	smith.sheet.set_skill_rank(&"crafting", PFMathConstants.ProficiencyRank.EXPERT)
	
	var bard = autofree(PFPlayerCharacter.new("Bard", [&"humanoid"], 3, 0, 0, 0, 0))
	bard.sheet.set_skill_rank(&"performance", PFMathConstants.ProficiencyRank.EXPERT)
	
	print("\nTest 1: Crafting Setup")
	# Level 2 item -> DC 16. Blacksmith has +4 + 3 + int (let's say 18 int = +4) = +11
	smith.attributes.apply_ancestry_boost(&"int")
	smith.attributes.apply_background_boost(&"int")
	smith.attributes.apply_class_boost(&"int")
	smith.attributes.apply_free_boost(&"int")
	var success = downtime_mgr.begin_crafting(smith, &"steel_shield", 2)
	assert_true(success, "Should successfully start crafting.")
	assert_true(smith.get_meta(&"is_busy"), "Smith should be busy.")
	
	print("\nTest 2: Earn Income")
	bard.attributes.apply_free_boost(&"cha")
	bard.attributes.apply_free_boost(&"cha")
	bard.attributes.apply_free_boost(&"cha")
	bard.attributes.apply_free_boost(&"cha")
	success = downtime_mgr.begin_earn_income(bard, &"performance", 3, 5) # 5 days
	assert_true(success, "Should successfully start earning income.")
	assert_true(bard.get_meta(&"is_busy"), "Bard should be busy.")
	
	# Try starting another task while busy
	var failed_start = downtime_mgr.begin_retraining(bard, &"fascinating_performance", &"versatile_performance", 7)
	assert_false(failed_start, "Cannot start retraining while busy earning income.")
	
	print("\nTest 3: Advancing Time")
	time_mgr.advance_days(1) # Day 1 complete. Crafting might finish if crit success. Let's say it's 2 days.
	
	# Let's forcefully advance 4 more days so both finish
	time_mgr.advance_days(4)
	
	assert_false(smith.get_meta(&"is_busy"), "Smith should be done crafting.")
	assert_false(bard.get_meta(&"is_busy"), "Bard should be done earning income.")
	
	print("\nAll Downtime Tests executed!")

func after_all():
	PFContext.cleanup_shared_services()
