class_name Garden_Bounds
extends Node


@export var fallback_cell_size: float = 16.0


var _rect: Rect2
var _valid: bool = false


func refresh(context: Animal_Context) -> bool:
	_valid = false

	if context == null:
		return false

	var grid := context.get_cell_grid()

	if grid == null:
		return false

	var side_length: int = grid.get_grid_len()

	if side_length <= 0:
		return false

	var first: Cell = context.get_cell_local(Vector2i.ZERO)
	var last: Cell = context.get_cell_local(
		Vector2i(side_length - 1, side_length - 1)
	)

	if first == null or last == null:
		return false

	var cell_size := _get_cell_size(
		context,
		first,
		side_length
	)

	var half_cell := Vector2.ONE * cell_size * 0.5

	var min_pos := Vector2(
		minf(first.global_position.x, last.global_position.x),
		minf(first.global_position.y, last.global_position.y)
	) - half_cell

	var max_pos := Vector2(
		maxf(first.global_position.x, last.global_position.x),
		maxf(first.global_position.y, last.global_position.y)
	) + half_cell

	_rect = Rect2(
		min_pos,
		max_pos - min_pos
	)

	_valid = true

	return true


func is_valid() -> bool:
	return _valid


func get_rect() -> Rect2:
	return _rect


func clamp_inside(
	point: Vector2,
	inset: float = 0.0
) -> Vector2:
	var rect := _rect.grow(-inset)

	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return _rect.get_center()

	return Vector2(
		clampf(point.x, rect.position.x, rect.end.x),
		clampf(point.y, rect.position.y, rect.end.y)
	)


func get_nearest_side(point: Vector2) -> int:
	var nearest_side := SIDE_LEFT
	var nearest_distance := absf(
		point.x - _rect.position.x
	)

	var distance := absf(
		_rect.end.x - point.x
	)

	if distance < nearest_distance:
		nearest_distance = distance
		nearest_side = SIDE_RIGHT

	distance = absf(
		point.y - _rect.position.y
	)

	if distance < nearest_distance:
		nearest_distance = distance
		nearest_side = SIDE_TOP

	distance = absf(
		_rect.end.y - point.y
	)

	if distance < nearest_distance:
		nearest_side = SIDE_BOTTOM

	return nearest_side


func get_random_point_outside(
	side: int,
	margin: float
) -> Vector2:
	match side:
		SIDE_LEFT:
			return Vector2(
				_rect.position.x - margin,
				randf_range(
					_rect.position.y,
					_rect.end.y
				)
			)

		SIDE_RIGHT:
			return Vector2(
				_rect.end.x + margin,
				randf_range(
					_rect.position.y,
					_rect.end.y
				)
			)

		SIDE_TOP:
			return Vector2(
				randf_range(
					_rect.position.x,
					_rect.end.x
				),
				_rect.position.y - margin
			)

		_:
			return Vector2(
				randf_range(
					_rect.position.x,
					_rect.end.x
				),
				_rect.end.y + margin
			)


func get_exit_point(
	point: Vector2,
	margin: float
) -> Vector2:
	var side := get_nearest_side(point)
	var clamped := clamp_inside(point)

	match side:
		SIDE_LEFT:
			return Vector2(
				_rect.position.x - margin,
				clamped.y
			)

		SIDE_RIGHT:
			return Vector2(
				_rect.end.x + margin,
				clamped.y
			)

		SIDE_TOP:
			return Vector2(
				clamped.x,
				_rect.position.y - margin
			)

		_:
			return Vector2(
				clamped.x,
				_rect.end.y + margin
			)


func _get_cell_size(
	context: Animal_Context,
	first: Cell,
	side_length: int
) -> float:
	if side_length > 1:
		var neighbor: Cell = context.get_cell_local(
			Vector2i(1, 0)
		)

		if neighbor:
			var spacing := absf(
				neighbor.global_position.x
				- first.global_position.x
			)

			if spacing > 0.0:
				return spacing

	return fallback_cell_size
