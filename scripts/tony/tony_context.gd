# tony_context.gd
# contains tony's contextual data for organized access across his scene
class_name Tony_Context
extends Node

# enums
enum Direction { UP, DOWN, LEFT, RIGHT }
enum CarryState { NONE, RADISH } # maybe tony can carry more things later?

# signals
signal movement_changed( last_dir: int, is_moving: bool )
signal carry_state_changed( carry_state: int, item_in_hand_id: StringName )
signal speed_mult_changed( speed_mult: float )
signal shout_radius_changed( shout_radius_mult: float )
signal throw_speed_mult_changed( throw_speed_mult: float )
signal plant_radius_mult_changed( plant_radius_mult: float )

# members
var last_dir: int = Direction.DOWN     : get = get_last_dir,            set = set_last_dir
var is_moving: bool = false            : get = get_is_moving,           set = set_is_moving
var speed_mult: float = 1.0            : get = get_speed_mult,          set = set_speed_mult
var shout_radius_mult: float = 1.0     : get = get_shout_radius_mult,   set = set_shout_radius_mult
var throw_speed_mult: float = 1.0      : get = get_throw_speed_mult,    set = set_throw_speed_mult
var plant_radius_mult: float = 1.0     : get = get_plant_radius_mult,   set = set_plant_radius_mult
var carry_state: int = CarryState.NONE : get = get_carry_state,         set = set_carry_state
var item_in_hand_id: StringName = &""  : get = get_item_in_hand_id,     set = set_item_in_hand_id

func get_last_dir() -> int:
	return last_dir

func set_last_dir(i: int) -> void:
	if i != last_dir:
		last_dir = i
		emit_signal("movement_changed", last_dir, is_moving)

func get_is_moving() -> bool:
	return is_moving

func set_is_moving(b: bool) -> void:
	if b != is_moving:
		is_moving = b
		emit_signal("movement_changed", last_dir, is_moving)

func get_speed_mult() -> float:
	return speed_mult

func set_speed_mult(f: float) -> void:
	if f != speed_mult:
		speed_mult = f
		emit_signal("speed_mult_changed", speed_mult)

func get_shout_radius_mult() -> float:
	return shout_radius_mult

func set_shout_radius_mult(f: float) -> void:
	if f != shout_radius_mult:
		shout_radius_mult = f
		emit_signal("shout_radius_changed", shout_radius_mult)

func get_throw_speed_mult() -> float:
	return throw_speed_mult

func set_throw_speed_mult(f: float) -> void:
	if f != throw_speed_mult:
		throw_speed_mult = f
		emit_signal("throw_speed_mult_changed", throw_speed_mult)

func get_plant_radius_mult() -> float:
	return plant_radius_mult

func set_plant_radius_mult(f: float) -> void:
	if f != plant_radius_mult:
		plant_radius_mult = f
		emit_signal("plant_radius_mult_changed", plant_radius_mult)

func get_carry_state() -> int:
	return carry_state

func set_carry_state(i: int) -> void:
	if i != carry_state:
		carry_state = i
		emit_signal("carry_state_changed", carry_state, item_in_hand_id)

func get_item_in_hand_id() -> StringName:
	return item_in_hand_id

func set_item_in_hand_id(s: StringName) -> void:
	if s != item_in_hand_id:
		item_in_hand_id = s
