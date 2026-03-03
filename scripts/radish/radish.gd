# radish.gd
class_name Radish
extends Node2D

@export var radish_animations: AnimatedSprite2D

var growing: bool = false
var radish_growth_rate: float = 50.0
var radish_growth_timer: float = 0.0 
var radish_state_change_timer: float = 100.0

enum RadishState { SEED, SPROUT, ADULT, AIRBORNE, LANDED }
var current_state: RadishState = RadishState.SEED

var _grid_coords: Vector2i = Vector2i.ZERO

# --- ownership --- #
var holder: Node2D = null
var _follow_offset: Vector2 = Vector2.ZERO

# --- pickup collision --- #
var pickup_area: Area2D
var pickup_collision: CollisionShape2D
@export var pickup_collision_radius: float = 4.0
@export var radish_layer_bit: int = 3

func init(grid_coords: Vector2i, initial_holder: Node2D = null) -> void:
	_grid_coords = grid_coords
	holder = initial_holder

	radish_animations.position = Vector2.ZERO
	radish_animations.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	_setup_pickup_collision()

	growing = true
	change_state(RadishState.SEED)

func _setup_pickup_collision() -> void:
	pickup_area = Area2D.new()
	pickup_area.monitoring = false
	pickup_area.monitorable = true
	add_child(pickup_area)

	pickup_collision = CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = pickup_collision_radius
	pickup_collision.shape = shape
	pickup_area.add_child(pickup_collision)

	pickup_area.collision_layer = 1 << radish_layer_bit
	pickup_area.collision_mask = 0

	_update_pickup_collision()

# --- holder management --- #

func set_holder(new_holder: Node2D, offset: Vector2 = Vector2.ZERO) -> void:
	var old_holder = holder
	holder = new_holder
	_follow_offset = offset

	if old_holder and is_instance_valid(old_holder) and old_holder.has_method("clear_radish"):
		old_holder.clear_radish()

	_update_pickup_collision()
	_update_visibility()

func is_pickable() -> bool:
	return current_state == RadishState.ADULT or current_state == RadishState.LANDED

func _update_pickup_collision() -> void:
	if pickup_collision:
		pickup_collision.disabled = not is_pickable()

func _update_visibility() -> void:
	if holder and holder is CharacterBody2D:
		visible = false
	else:
		visible = true

# --- state ---

func change_state(new_state: RadishState) -> void:
	current_state = new_state
	_update_pickup_collision()

	match current_state:
		RadishState.SEED:
			radish_animations.play("seed")
			event_bus.radish_planted.emit(self, global_position, _grid_coords)
		RadishState.SPROUT:
			radish_animations.z_index = 1
			radish_animations.z_as_relative = true
			radish_animations.play("sprout")
			event_bus.radish_sprouted.emit(self, global_position, _grid_coords)
		RadishState.ADULT:
			radish_animations.play("adult")
			growing = false
			event_bus.radish_matured.emit(self, global_position, _grid_coords)
		RadishState.AIRBORNE:
			radish_animations.play("airborne")
		RadishState.LANDED:
			radish_animations.play("landed")

func _physics_process(delta: float) -> void:
	if holder and is_instance_valid(holder):
		global_position = holder.global_position + _follow_offset

	if growing:
		radish_growth_timer += radish_growth_rate * delta
		if radish_growth_timer >= radish_state_change_timer:
			var next_state := current_state + 1
			if next_state <= RadishState.ADULT:
				change_state(next_state as RadishState)
			radish_growth_timer = 0.0

func get_current_state() -> RadishState:
	return current_state

func get_grid_coords() -> Vector2i:
	return _grid_coords
