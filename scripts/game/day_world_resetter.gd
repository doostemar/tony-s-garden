# day_world_resetter.gd
class_name DayWorldResetter
extends Node

var _tony: CharacterBody2D
var _garden_manager: Garden_Manager
var _radish_manager: Radish_Manager
var _animal_manager: Node2D

var _tony_spawn_position: Vector2


func configure(
	tony: CharacterBody2D,
	garden_manager: Garden_Manager,
	radish_manager: Radish_Manager,
	animal_manager: Node2D
) -> void:
	_tony = tony
	_garden_manager = garden_manager
	_radish_manager = radish_manager
	_animal_manager = animal_manager

	if _tony:
		_tony_spawn_position = _tony.global_position


func reset_for_day(config: DayConfig) -> void:
	# Order is intentional:
	# 1. Tony releases anything he is carrying.
	# 2. Animals release/reset their gameplay state.
	# 3. Radishes are detached from the world.
	# 4. Garden is rebuilt.

	_reset_tony()
	_reset_animals()
	_reset_radishes()
	_regenerate_garden(config)


func _reset_tony() -> void:
	if _tony == null:
		return

	var carry_manager = _tony.get("carry_manager")

	if (
		carry_manager
		and carry_manager.has_method("clear_hand")
	):
		carry_manager.clear_hand()

	_tony.global_position = _tony_spawn_position


func _reset_animals() -> void:
	if _animal_manager == null:
		push_warning(
			"DayWorldResetter: animal_manager not assigned."
		)
		return

	if _animal_manager.has_method("reset"):
		_animal_manager.reset()


func _reset_radishes() -> void:
	if _radish_manager == null:
		push_warning(
			"DayWorldResetter: radish_manager not assigned."
		)
		return

	_radish_manager.reset()


func _regenerate_garden(config: DayConfig) -> void:
	if _garden_manager == null:
		push_warning(
			"DayWorldResetter: garden_manager not assigned."
		)
		return

	_garden_manager.side_length = (
		config.garden_side_length
	)

	_garden_manager.regenerate_garden()
