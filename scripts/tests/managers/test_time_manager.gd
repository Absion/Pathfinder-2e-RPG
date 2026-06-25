extends GutTest



func test_time_advancement():
	var tm = autofree(PFTimeManager.new())
	tm._ready()
	
	assert_eq(tm.current_day, 1)
	assert_eq(tm.current_time_seconds, 0)
	
	tm.advance_seconds(6) # 1 round
	assert_eq(tm.current_time_seconds, 6)
	
	tm.advance_minutes(10) # 600 seconds
	assert_eq(tm.current_time_seconds, 606)
	
	tm.advance_hours(1) # 3600 seconds
	assert_eq(tm.current_time_seconds, 4206)
	
	tm.free()

func test_day_rollover():
	var tm = autofree(PFTimeManager.new())
	tm._ready()
	
	assert_eq(tm.current_day, 1)
	
	# Advance almost a full day
	tm.advance_hours(23)
	assert_eq(tm.current_day, 1)
	
	# Push over the edge
	tm.advance_hours(2)
	assert_eq(tm.current_day, 2)
	assert_eq(tm.current_time_seconds, 3600) # 1 hour into day 2
	
	tm.free()

func test_rest_for_night():
	var tm = autofree(PFTimeManager.new())
	tm._ready()
	
	tm.rest_for_night()
	assert_eq(tm.current_time_seconds, 8 * 3600)
	
	tm.free()
