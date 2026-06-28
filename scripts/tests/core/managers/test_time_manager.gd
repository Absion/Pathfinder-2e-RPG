extends GutTest



func test_time_advancement():
	var time_manager = autofree(PFTimeManager.new())
	time_manager._ready()
	
	assert_eq(time_manager.current_day, 1)
	assert_eq(time_manager.current_time_seconds, 0)
	
	time_manager.advance_seconds(6) # 1 round
	assert_eq(time_manager.current_time_seconds, 6)
	
	time_manager.advance_minutes(10) # 600 seconds
	assert_eq(time_manager.current_time_seconds, 606)
	
	time_manager.advance_hours(1) # 3600 seconds
	assert_eq(time_manager.current_time_seconds, 4206)
	
	time_manager.free()

func test_day_rollover():
	var time_manager = autofree(PFTimeManager.new())
	time_manager._ready()
	
	assert_eq(time_manager.current_day, 1)
	
	# Advance almost a full day
	time_manager.advance_hours(23)
	assert_eq(time_manager.current_day, 1)
	
	# Push over the edge
	time_manager.advance_hours(2)
	assert_eq(time_manager.current_day, 2)
	assert_eq(time_manager.current_time_seconds, 3600) # 1 hour into day 2
	
	time_manager.free()

func test_rest_for_night():
	var time_manager = autofree(PFTimeManager.new())
	time_manager._ready()
	
	time_manager.rest_for_night()
	assert_eq(time_manager.current_time_seconds, 8 * 3600)
	
	time_manager.free()

