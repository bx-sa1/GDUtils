class_name TraitTest
extends GdUnitTestSuite

func test_trait_add_metadata():
	var runner = scene_runner("res://test_scenes/test_trait.tscn")

	var trait_owner = runner.find_child("TraitOwner")

	assert_that(trait_owner.has_meta("InteractableTrait")).is_true()

func test_trait_add_metadata_extended():
	var runner = scene_runner("res://test_scenes/test_trait.tscn")

	var trait_owner = runner.find_child("TraitOwner")

	assert_that(trait_owner.has_meta("DamageableTrait")).is_true()

func test_trait_add_metadata_extended_with_class_name():
	var runner = scene_runner("res://test_scenes/test_trait.tscn")

	var trait_owner = runner.find_child("TraitOwner")

	assert_that(trait_owner.has_meta("DamageableTraitExt")).is_true()
