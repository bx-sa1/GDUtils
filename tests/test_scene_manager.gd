class_name SceneManagerTest
extends GdUnitTestSuite

var scene_1 := preload("res://test_scenes/test_scene_1.tscn")
var scene_2 := preload("res://test_scenes/test_scene_2.tscn")
var transition := preload("res://scenes/transition/transition.tscn")

var s1
var s2
var t

func before_test() -> void:
	s1 = auto_free(scene_1.instantiate())
	s2 = auto_free(scene_2.instantiate())
	t = auto_free(transition.instantiate())

func test_change_scene():
	var runner := scene_runner("res://test_scenes/test_main.tscn")

	var scene_manager = runner.find_child("SceneManager")
	scene_manager.change_scene(s1, null)
	await runner.simulate_frames(1, 1000)
	scene_manager.change_scene(s2, null)
	await runner.simulate_frames(1, 1000)

	assert_array(scene_manager._scene_stack).contains_exactly([s2])
	assert_that(runner.scene().get_child(-1)).is_equal(s2)

func test_change_scene_with_transition():
	var runner := scene_runner("res://test_scenes/test_main.tscn")

	var scene_manager = runner.find_child("SceneManager")
	await scene_manager.change_scene(s1, t)
	await runner.simulate_frames(1, 1000)
	await scene_manager.change_scene(s2, t)
	await runner.simulate_frames(1, 1000)

	assert_array(scene_manager._scene_stack).contains_exactly([s2])
	assert_that(runner.scene().get_child(-1)).is_equal(s2)

func test_push_scene():
	var runner := scene_runner("res://test_scenes/test_main.tscn")

	var scene_manager = runner.find_child("SceneManager")
	scene_manager.change_scene(s1, null)
	await runner.simulate_frames(1, 1000)
	scene_manager.push_scene(s2)
	await runner.simulate_frames(1, 1000)

	assert_array(scene_manager._scene_stack).contains_exactly([s1, s2])
	assert_that(runner.scene().get_child(-1)).is_equal(s2)
	assert_that(runner.scene().get_child(-2)).is_equal(s1)

func test_pop_scene():
	var runner := scene_runner("res://test_scenes/test_main.tscn")

	var scene_manager = runner.find_child("SceneManager")
	scene_manager.change_scene(s1, null)
	await runner.simulate_frames(1, 1000)
	scene_manager.push_scene(s2)
	await runner.simulate_frames(1, 1000)
	scene_manager.pop_scene()
	await runner.simulate_frames(1, 1000)

	assert_array(scene_manager._scene_stack).contains_exactly([s1])
	assert_that(runner.scene().get_child(-1)).is_equal(s1)
