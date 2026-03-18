# shout_component.gd
class_name Shout_Component
extends Node2D

@export var shout_layer_bit: int = 5
@export var collision_offset: Vector2 = Vector2(0, 0)

@export var context: Tony_Context

var _shout_area: Area2D
var _shout_collision: CollisionShape2D
var _base_hitbox_radius: float
var _hitbox_duration: float
var _hitbox_timer: Timer

func init(hitbox_radius: float, hitbox_duration: float) -> void:
	if context:
		context.shout_radius_changed.connect(_on_shout_radius_changed)

	_base_hitbox_radius = hitbox_radius
	_hitbox_duration = hitbox_duration
	_setup_timer()
	_setup_hitbox()
	_apply_radius_from_context()

func _setup_hitbox() -> void:
	_shout_area = Area2D.new()
	add_child(_shout_area)

	_shout_collision = CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = _base_hitbox_radius
	_shout_collision.shape = shape
	_shout_collision.position = collision_offset
	_shout_area.add_child(_shout_collision)

	_turn_off_hitbox()

	_shout_area.collision_layer = 1 << 0
	_shout_area.collision_mask = 1 << shout_layer_bit
	_shout_area.body_entered.connect(_on_body_entered)

func _setup_timer() -> void:
	_hitbox_timer = Timer.new()
	_hitbox_timer.one_shot = true
	_hitbox_timer.wait_time = _hitbox_duration
	_hitbox_timer.timeout.connect(_on_hitbox_timeout)
	add_child(_hitbox_timer)

func _on_shout_radius_changed(_new_mult: float) -> void:
	_apply_radius_from_context()

func _apply_radius_from_context() -> void:
	if _shout_collision == null:
		return
	var shape := _shout_collision.shape as CircleShape2D
	if shape == null:
		return

	var mult := 1.0
	if context:
		mult = context.shout_radius_mult

	shape.radius = _base_hitbox_radius * mult

func _on_hitbox_timeout() -> void:
	print("done shouting, thanks")
	_turn_off_hitbox()

func _turn_off_hitbox() -> void:
	_shout_area.monitoring = false
	_shout_area.monitorable = false
	_shout_collision.debug_color = Color(0.9, 0.9, 0.9, .3)

func shouting() -> bool:
	if not _hitbox_timer.is_stopped():
		return false

	_shout_area.monitoring = true
	_shout_area.monitorable = true
	_shout_collision.debug_color = Color(0.9, 0, 0, .7)
	_hitbox_timer.start()
	print("shouting")
	return true

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("animal"):
		print("bodies found")
		body.exit()
	else:
		print("no bodies found")
	return
