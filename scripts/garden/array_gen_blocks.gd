class_name Array_Block_Generator
extends Node2D

@export var fill: float # how filled the garden is with soil (still used to control density)

var _len: int
var center: int
var grid: Array[Array]
var rng: RandomNumberGenerator
var basket := 2
var max_block_attempts := 1000

func _init(side_length: int, fill_factor: float):
	_len = side_length
	fill = fill_factor
	center = _len / 2
	grid = []
	rng = RandomNumberGenerator.new()
	rng.randomize()
	for x in range(_len):
		grid.append([])
		for y in range(_len):
			grid[x].append(0)
	fill_grid()

func fill_grid():
	clear_grid()
	grid[center][center] = basket

	var placed_blocks := 0
	var max_blocks := int(fill * 0.5 * _len * _len / 5) # crude density control

	for i in range(max_block_attempts):
		if placed_blocks >= max_blocks:
			break

		var w := rng.randi_range(1, 2)
		var h := rng.randi_range(1, 2)
		if rng.randf() < 0.5:
			w = rng.randi_range(1, 2)
			h = rng.randi_range(1, 5)
		else:
			w = rng.randi_range(1, 5)
			h = rng.randi_range(1, 2)

		var x := rng.randi_range(0, _len - w)
		var y := rng.randi_range(0, _len - h)

		if can_place_block(x, y, w, h):
			place_block(x, y, w, h)
			placed_blocks += 1

func clear_grid():
	for x in range(_len):
		for y in range(_len):
			grid[x][y] = 0

func can_place_block(x_start: int, y_start: int, w: int, h: int) -> bool:
	for x in range(x_start - 1, x_start + w + 1):
		for y in range(y_start - 1, y_start + h + 1):
			if !is_in_bounds(x, y):
				continue
			if grid[x][y] != 0 or near_center(x, y):
				return false
	return true

func place_block(x_start: int, y_start: int, w: int, h: int):
	for x in range(x_start, x_start + w):
		for y in range(y_start, y_start + h):
			grid[x][y] = 1

func is_in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < _len and y < _len

func near_center(x: int, y: int) -> bool:
	return x >= center && x <= center && y >= center && y <= center

func print_grid():
	print()
	for x in range(_len):
		print(grid[x])
	print()

func get_grid():
	return grid
