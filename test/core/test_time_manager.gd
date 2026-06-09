extends GdUnitTestSuite

const TimeManager = preload("res://scripts/core/pf_time_manager.gd")

func test_time_advancement():
	var tm = TimeManager.new()
	tm._ready()
	
	assert_int(tm.current_day).is_equal(1)
	assert_int(tm.current_time_seconds).is_equal(0)
	
	tm.advance_seconds(6) # 1 round
	assert_int(tm.current_time_seconds).is_equal(6)
	
	tm.advance_minutes(10) # 600 seconds
	assert_int(tm.current_time_seconds).is_equal(606)
	
	tm.advance_hours(1) # 3600 seconds
	assert_int(tm.current_time_seconds).is_equal(4206)
	
	tm.free()

func test_day_rollover():
	var tm = TimeManager.new()
	tm._ready()
	
	assert_int(tm.current_day).is_equal(1)
	
	# Advance almost a full day
	tm.advance_hours(23)
	assert_int(tm.current_day).is_equal(1)
	
	# Push over the edge
	tm.advance_hours(2)
	assert_int(tm.current_day).is_equal(2)
	assert_int(tm.current_time_seconds).is_equal(3600) # 1 hour into day 2
	
	tm.free()

func test_rest_for_night():
	var tm = TimeManager.new()
	tm._ready()
	
	tm.rest_for_night()
	assert_int(tm.current_time_seconds).is_equal(8 * 3600)
	
	tm.free()
