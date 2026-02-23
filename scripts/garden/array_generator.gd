# array_generator.gd
class_name Array_Generator
extends Node2D

var fill: float                # how filled the garden is with soil
var _len: int                   # length/width of square grid
var center: int                # finds center point of grid
var grid: Array[Array]         # grid 2d array
var rng: RandomNumberGenerator # used to random draw soil tiles

# called when the node enters the scene tree for the first time.
# creates an non-soil grid then fills it
func _init( side_length: int, fill_factor: float ):
	_len = side_length
	fill = fill_factor
	for y in range( _len ):
		grid.insert( y, Array() )
		for x in range( _len ):
			grid[ y ].insert( x, 0 )
	center = _len / 2
	rng = RandomNumberGenerator.new()
	fill_grid()
	
func create_empty_grid():
	for y in range( _len ):
		for x in range( _len ):
			grid[ y ][ x ] = 0

# randomly fills grid with soil tiles
func fill_grid():
	for y in range( _len ):
		for x in range( _len ):
			# fill randomly based on the fill factor
			# but don't fill any tiles around the center tile
			if rng.randf() < fill && !near_center( y, x ):
				grid[ y ][ x ] = 1
	grid[ center ][ center ] = 0

# makes sure soil tiles do not appear around the stash tile
func near_center( y: int, x: int ):
	return y >= center - 1 && y <= center + 1 && x >= center - 1 && x <= center + 1

func print_grid():
	print()
	for y in range( _len ):
		print( grid[ y ] )
	print()

func get_grid():
	return grid
