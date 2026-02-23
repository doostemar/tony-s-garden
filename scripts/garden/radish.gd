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

func init(grid_coords: Vector2i) -> void:
	_grid_coords = grid_coords

	radish_animations.position = Vector2.ZERO
	radish_animations.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	growing = true
	change_state( RadishState.SEED )

func get_grid_coords() -> Vector2i:
	return _grid_coords

func change_state(new_state: RadishState) -> void:
	current_state = new_state

	match current_state:
		RadishState.SEED:
			radish_animations.play( "seed" )
			event_bus.radish_planted.emit( self, global_position, _grid_coords )
		RadishState.SPROUT:
			radish_animations.z_index = 1
			radish_animations.z_as_relative = true
			radish_animations.play( "sprout" )
			event_bus.radish_sprouted.emit( self, global_position, _grid_coords )
		RadishState.ADULT:
			radish_animations.play( "adult" )
			growing = false
			event_bus.radish_matured.emit( self, global_position, _grid_coords )
		RadishState.AIRBORNE:
			radish_animations.play( "airborne" )
		RadishState.LANDED:
			radish_animations.play( "landed" )

func _physics_process( delta: float ) -> void:
	if growing:
		radish_growth_timer += radish_growth_rate * delta
		if radish_growth_timer >= radish_state_change_timer:
			var next_state := current_state + 1
			if next_state <= RadishState.ADULT:
				change_state( next_state )
			radish_growth_timer = 0.0

func get_current_state() -> RadishState:
	return current_state
