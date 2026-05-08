# array_generator.gd
class_name Array_Generator
extends Node2D

var fill: float                # how filled the garden is with soil
var _len: int                   # length/width of square grid
var center: int                # finds center point of grid
var grid: Array[Array]         # grid 2d array (0 = grass, 1 = soil)
var bed_map: Array[Array]      # parallel grid, bed id per tile (-1 = no bed)
var beds: Array[Dictionary]    # one record per bed, for other scripts to read
var rng: RandomNumberGenerator # used to random draw soil tiles

# called when the node enters the scene tree for the first time.
# creates a non-soil grid then fills it
func _init( side_length: int, fill_factor: float ):
	_len = side_length
	fill = fill_factor
	for y in range( _len ):
		grid.insert( y, Array() )
		bed_map.insert( y, Array() )
		for x in range( _len ):
			grid[ y ].insert( x, 0 )
			bed_map[ y ].insert( x, -1 )
	center = _len / 2
	rng = RandomNumberGenerator.new()
	fill_grid()

func create_empty_grid():
	for y in range( _len ):
		for x in range( _len ):
			grid[ y ][ x ] = 0
			bed_map[ y ][ x ] = -1
	beds.clear()

# randomly fills grid with soil beds
func fill_grid():
	var total_tiles: int = _len * _len
	var target_soil: int = int( fill * total_tiles )
	var current_soil: int = 0
	var max_attempts: int = total_tiles * 10
	var attempts: int = 0

	while current_soil < target_soil && attempts < max_attempts:
		attempts += 1
		# one side of a bed is always 2, the other is 2..5
		var long_side: int = rng.randi_range( 2, 5 )
		var bed_w: int
		var bed_h: int
		if rng.randi_range( 0, 1 ) == 0:
			bed_w = 2
			bed_h = long_side
		else:
			bed_w = long_side
			bed_h = 2
		# skip if the grid is too small for this bed
		if _len < bed_w || _len < bed_h:
			continue
		# random top-left corner that keeps the bed fully in bounds
		var bx: int = rng.randi_range( 0, _len - bed_w )
		var by: int = rng.randi_range( 0, _len - bed_h )
		if can_place_bed( by, bx, bed_h, bed_w ):
			place_bed( by, bx, bed_h, bed_w )
			current_soil += bed_w * bed_h

	grid[ center ][ center ] = 0

# a bed may be placed if none of its tiles are near the center and
# the bed plus a 1-tile buffer contains no existing soil (keeps beds separate)
func can_place_bed( by: int, bx: int, h: int, w: int ) -> bool:
	# bed tiles must avoid the 3x3 center zone
	for y in range( by, by + h ):
		for x in range( bx, bx + w ):
			if near_center( y, x ):
				return false
	# bed + surrounding buffer must be all grass
	for y in range( by - 1, by + h + 1 ):
		for x in range( bx - 1, bx + w + 1 ):
			if y < 0 || y >= _len || x < 0 || x >= _len:
				continue
			if grid[ y ][ x ] == 1:
				return false
	return true

# writes soil tiles for a bed and records it in beds / bed_map
func place_bed( by: int, bx: int, h: int, w: int ):
	var bed_id: int = beds.size()
	var tiles: Array[Vector2i] = []
	for y in range( by, by + h ):
		for x in range( bx, bx + w ):
			grid[ y ][ x ] = 1
			bed_map[ y ][ x ] = bed_id
			tiles.append( Vector2i( x, y ) )
	beds.append( {
		"id": bed_id,
		"x": bx,
		"y": by,
		"width": w,
		"height": h,
		"area": w * h,
		"tiles": tiles
	} )

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

# returns the full list of bed records
func get_beds():
	return beds

# returns the tile -> bed-id grid
func get_bed_map():
	return bed_map

# returns the bed dictionary for the tile at (y, x), or null if it's grass
func get_bed_at( y: int, x: int ):
	if y < 0 || y >= _len || x < 0 || x >= _len:
		return null
	var id: int = bed_map[ y ][ x ]
	if id < 0:
		return null
	return beds[ id ]
