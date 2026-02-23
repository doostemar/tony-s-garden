# tony_animations.gd
extends AnimatedSprite2D
class_name Tony_Animations

@export var context: Tony_Context

var _last_dir: int = Tony_Context.Direction.DOWN
var _is_moving: bool = false
var _carry_state: int = Tony_Context.CarryState.NONE

func init(ctx: Tony_Context = null) -> void:
	if context == null:
		play("idle_down")
		return
	
	_last_dir = context.get_last_dir()
	_is_moving = context.get_is_moving()
	_carry_state = context.get_carry_state()
	
	context.movement_changed.connect(_on_movement_changed)
	context.carry_state_changed.connect(_on_carry_state_changed)
	
	_update_animation()

func _on_movement_changed(last_dir: int, is_moving: bool) -> void:
	_last_dir = last_dir
	_is_moving = is_moving
	_update_animation()

func _on_carry_state_changed(carry_state: int, _item_id: StringName) -> void:
	_carry_state = carry_state
	_update_animation()

func _update_animation() -> void:
	var base = "walking" if _is_moving else "idle"

	var dir: String
	match _last_dir:
		Tony_Context.Direction.UP: dir = "up"
		Tony_Context.Direction.DOWN: dir = "down"
		Tony_Context.Direction.LEFT: dir = "left"
		Tony_Context.Direction.RIGHT: dir = "right"
		_: dir = "down"
		
	var carry_suffix = "" if _carry_state == Tony_Context.CarryState.NONE else "_carry"

	var clip := "%s_%s%s" % [base, dir, carry_suffix]

	if sprite_frames and sprite_frames.has_animation(clip):
		play(clip)
	else:
		var fallback := "%s_%s" % [base, dir]
		if sprite_frames and sprite_frames.has_animation(fallback):
			play(fallback)
		else:
			play("idle_down")
