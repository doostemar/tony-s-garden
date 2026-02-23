# input_manager.gd
class_name Input_Manager
extends Node2D

var movement_input_stack: Array[String] = [] # a stack of movement inputs

signal plant_pressed
signal shout_pressed
signal dance_pressed

# called every frame by tony
func process_input() -> void:
	# other actions
	if Input.is_action_just_pressed("plant"): plant_pressed.emit()
	elif Input.is_action_just_pressed("shout"): shout_pressed.emit()
	elif Input.is_action_just_pressed("dance"): dance_pressed.emit()
	
	# movement
	if Input.is_action_just_pressed("move_up"): add_input_to_stack("move_up")
	if Input.is_action_just_pressed("move_down"): add_input_to_stack("move_down")
	if Input.is_action_just_pressed("move_left"): add_input_to_stack("move_left")
	if Input.is_action_just_pressed("move_right"): add_input_to_stack("move_right")
	
	# checks if movement inputs are still pressed
	clean_input_stack()

# attempts to erase the input from the stack, and adds input at the top
func add_input_to_stack(input: String):
	movement_input_stack.erase(input)
	movement_input_stack.append(input)

# checks the stack every frame, making sure only things that are currently pressed
# are in the movement input stack
func clean_input_stack() -> void: 
	var still_pressed: Array[String] = []
	for input in movement_input_stack:
		if Input.is_action_pressed(input):
			still_pressed.append(input)
	movement_input_stack = still_pressed

# tony needs to get the stack to send it to the movement component
func get_movement_input_stack() -> Array[String]:
	return movement_input_stack

func get_move_vector() -> Vector2:
	if movement_input_stack.is_empty():
		return Vector2.ZERO
	match movement_input_stack.back():
		"move_up"    : return Vector2.UP
		"move_down"  : return Vector2.DOWN
		"move_left"  : return Vector2.LEFT
		"move_right" : return Vector2.RIGHT
		_            : return Vector2.ZERO
