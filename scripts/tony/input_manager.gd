# input_manager.gd
class_name Input_Manager
extends Node2D

var movement_input_stack: Array[String] = []

signal plant_pressed
signal shout_pressed
signal dance_pressed

# each action locked during a reset is released independently
var _locked_actions: Dictionary = {}


func lock_actions_until_released() -> void:
	# always block actions through the first input-processing
	# pass after reset, even if the key has already been released
	_locked_actions.clear()

	for action in ["plant", "shout", "dance"]:
		_locked_actions[action] = true


# called every physics frame by tony
func process_input() -> void:
	_update_action_locks()

	# one-shot gameplay actions
	if _can_trigger("plant") and Input.is_action_just_pressed("plant"):
		plant_pressed.emit()
	elif _can_trigger("shout") and Input.is_action_just_pressed("shout"):
		shout_pressed.emit()
	elif _can_trigger("dance") and Input.is_action_just_pressed("dance"):
		dance_pressed.emit()

	# movement
	if Input.is_action_just_pressed("move_up"):
		add_input_to_stack("move_up")
	if Input.is_action_just_pressed("move_down"):
		add_input_to_stack("move_down")
	if Input.is_action_just_pressed("move_left"):
		add_input_to_stack("move_left")
	if Input.is_action_just_pressed("move_right"):
		add_input_to_stack("move_right")

	clean_input_stack()


func _update_action_locks() -> void:
	for action in _locked_actions.keys():
		if not Input.is_action_pressed(action):
			_locked_actions.erase(action)


func _can_trigger(action: String) -> bool:
	return not _locked_actions.has(action)


func add_input_to_stack(input: String):
	movement_input_stack.erase(input)
	movement_input_stack.append(input)


func clean_input_stack() -> void:
	var still_pressed: Array[String] = []

	for input in movement_input_stack:
		if Input.is_action_pressed(input):
			still_pressed.append(input)

	movement_input_stack = still_pressed


func get_movement_input_stack() -> Array[String]:
	return movement_input_stack


func get_move_vector() -> Vector2:
	if movement_input_stack.is_empty():
		return Vector2.ZERO

	match movement_input_stack.back():
		"move_up":
			return Vector2.UP
		"move_down":
			return Vector2.DOWN
		"move_left":
			return Vector2.LEFT
		"move_right":
			return Vector2.RIGHT
		_:
			return Vector2.ZERO
