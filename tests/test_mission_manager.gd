class_name MissionManagerTest
extends GdUnitTestSuite

var test_mission_1
var test_mission_2

func before_test():
	test_mission_1 = load("res://test_scenes/test_mission_1.tres")
	test_mission_2 = load("res://test_scenes/test_mission_2.tres")

func after_test():
	test_mission_1 = null
	test_mission_2 = null

func test_mission_manager_get_mission():
	var mission_manager := MissionManager.new()

	mission_manager.add_mission(test_mission_1)
	mission_manager.add_mission(test_mission_2)

	var mission = mission_manager.get_mission("Test Mission 1")

	assert_that(mission).is_not_null()
	assert_that(mission).is_equal(test_mission_1)

func test_mission_manager_add_mission():
	var mission_manager: MissionManager = MissionManager.new()

	mission_manager.add_mission(test_mission_1)
	mission_manager.add_mission(test_mission_2)

	assert_that(mission_manager.get_mission("Test Mission 1")).is_equal(test_mission_1)
	assert_that(mission_manager.get_mission("Test Mission 2")).is_equal(test_mission_2)
	assert_array(mission_manager.missions).contains_exactly([test_mission_1, test_mission_2])

func test_mission_manager_remove_mission():
	var mission_manager: MissionManager = MissionManager.new()

	mission_manager.add_mission(test_mission_1)
	mission_manager.add_mission(test_mission_2)
	mission_manager.remove_mission(test_mission_1)

	assert_that(mission_manager.get_mission("Test Mission 1")).is_null()
	assert_that(mission_manager.get_mission("Test Mission 2")).is_equal(test_mission_2)
	assert_array(mission_manager.missions).contains_exactly([test_mission_2])


func test_mission_manager_inc_progess():
	var mission_manager := MissionManager.new()

	mission_manager.add_mission(test_mission_1)
	mission_manager.add_mission(test_mission_2)

	mission_manager.inc_progress("Foo")
	assert_that(test_mission_1.is_completed()).is_false()
	mission_manager.inc_progress("DEADBEEF")
	assert_that(test_mission_2.is_completed()).is_true()

	assert_array(mission_manager.completed_missions).contains_exactly([test_mission_2])


func test_mission_manager_dec_progess():
	var mission_manager := MissionManager.new()

	mission_manager.add_mission(test_mission_1)
	mission_manager.add_mission(test_mission_2)

	var mission = mission_manager.get_mission("Test Mission 1")
	assert_that(mission).is_not_null()
	assert_that(mission).is_equal(test_mission_1)

	mission_manager.dec_progress("Foo")
	assert_that(mission.is_failed()).is_true()
	mission_manager.dec_progress("DEADBEEF")
	assert_that(mission.is_failed()).is_true()

	assert_array(mission_manager.failed_missions).contains_exactly([test_mission_1, test_mission_2])
