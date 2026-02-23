# tony_movement.gd
extends Node2D
class_name Tony_Movement

@export var context: Tony_Context
@export var input_manager: Input_Manager

var _base_speed: float = 1.0 # tony's movement speed, set in tony
var _last_dir_enum: int = Tony_Context.Direction.DOWN # tony's most recent direction

func init( movement_speed: float ) -> void:
	_base_speed = movement_speed

func move() -> Vector2:
	var dir_vec := _get_dir_vec()
	var moving := dir_vec != Vector2.ZERO
	
	if moving:
		_last_dir_enum = _vec_to_enum( dir_vec, _last_dir_enum )
	
	if context:
		context.is_moving = moving
		context.last_dir = _last_dir_enum
	
	var mult := ( context.speed_mult if context else 1.0 )
	var speed := _base_speed * mult
	
	return dir_vec * speed

func _get_dir_vec() -> Vector2:
	if input_manager and input_manager.has_method("get_move_vector"):
		return input_manager.get_move_vector()
	# fall back from previous version, delete if unnecessary
	print("we got here: tony.tony_movement._get_dir_vec")
	var stack := _get_stack()
	if stack.is_empty():
		return Vector2.ZERO
	match stack.back():
		"move_up":    return Vector2(0, -1)
		"move_down":  return Vector2(0,  1)
		"move_left":  return Vector2(-1, 0)
		"move_right": return Vector2(1,  0)
		_:            return Vector2.ZERO

func _get_stack() -> Array[String]:
	if input_manager and input_manager.has_method("get_movement_input_stack"):
		return input_manager.get_movement_input_stack()
	# fallback, delete if unnecessary
	print("we got here: tony.tony_movement._get_stack")
	var p := get_parent()
	if p and p.has_method("get_movement_input_stack"):
		return p.get_movement_input_stack()
	return []

func _vec_to_enum(v: Vector2, last_dir: int) -> int:
	if v == Vector2.UP:    return Tony_Context.Direction.UP
	if v == Vector2.DOWN:  return Tony_Context.Direction.DOWN
	if v == Vector2.LEFT:  return Tony_Context.Direction.LEFT
	if v == Vector2.RIGHT: return Tony_Context.Direction.RIGHT
	return last_dir
