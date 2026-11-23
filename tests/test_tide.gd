extends GutTest
# Run: godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests

func test_day1_low_at_0730():
	assert_almost_eq(TideSystem.water_height(1, 450.0), 0.2, 0.01)

func test_day1_high_is_half_cycle_later():
	assert_almost_eq(TideSystem.water_height(1, 450.0 + TideSystem.HALF_CYCLE), 4.2, 0.01)

func test_lows_drift_50_min_per_day():
	assert_almost_eq(TideSystem.low_minute_of_day(3), 550.0, 0.01)

func test_day5_spring_low():
	assert_almost_eq(TideSystem.water_height(5, TideSystem.low_minute_of_day(5)), -0.4, 0.01)

func test_depth_bands():
	assert_eq(TideSystem.depth_band(0.2), "splash")
	assert_eq(TideSystem.depth_band(0.5), "knee")
	assert_eq(TideSystem.depth_band(0.9), "thigh")
	assert_eq(TideSystem.depth_band(1.0), "swept")

func test_sandbar_gate():
	assert_true(TideSystem.sandbars_open(2.1))
	assert_false(TideSystem.sandbars_open(2.11))
