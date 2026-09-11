# mole.gd
class_name Mole
extends StaticBody2D

@export_group("Nodes")
@export var animation_component: Mole_Animations
@export var collision_shape: CollisionShape2D
@export var adjacent_grass_finder: Adjacent_Grass_Finder

@export_group("Targeting")
@export var target_state: int = 2

@export_group("Stealing")
@export var steal_rates: Array[float] = [
	2.5,
	2.0,
	1.5
]

var _context: Animal_Context
var _target: Radish
var _spawn_cell: Cell

var _steal_timer: Timer
var _timer_duration: int


## called by manager before the mole enters the tree
##
## this function makes the mole's species-specific decisions:
## - which radish to attempt
## - whether that radish is already targeted by another Mole
## - which adjacent grass cell to attempt spawning on
##
func prepare_spawn_attempt(
	context: Animal_Context,
	active_animals: Array[Node]
) -> bool:
	_context = context

	if _context == null:
		return false

	if adjacent_grass_finder == null:
		push_error(
			"Mole: adjacent_grass_finder not assigned"
		)
		return false

	var available_radishes := _get_available_radishes(
		active_animals
	)

	if available_radishes.is_empty():
		return false

	_target = available_radishes.pick_random()

	var candidates := (
		adjacent_grass_finder.find_tiles(
			_context,
			_target
		)
	)

	if candidates.is_empty():
		_target = null
		return false

	_spawn_cell = candidates.pick_random()

	return _spawn_cell != null


## callec by manager after the shared spawn-chance roll succeeds.
## performs the rest of the mole spawn logic
func start_spawn() -> bool:
	if not is_instance_valid(_target):
		return false

	if not is_instance_valid(_spawn_cell):
		return false

	# should this happen after the roll?
	if _spawn_cell.check_overlapping_bodies():
		return false

	_spawn_cell.reset_collision()

	# only state 2
	if _target.get_current_state() != target_state:
		return false

	global_position = _spawn_cell.global_position

	_timer_duration = int(
		steal_rates[_context.difficulty]
	)

	return true


func _ready() -> void:
	add_to_group("animal")

	animation_component.init()

	z_index = 0
	z_as_relative = true
	y_sort_enabled = false

	if event_bus.has_signal("radish_picked"):
		event_bus.radish_picked.connect(
			_on_radish_picked
		)

	_setup_timer()


func _setup_timer() -> void:
	_steal_timer = Timer.new()
	_steal_timer.wait_time = _timer_duration
	_steal_timer.one_shot = true
	_steal_timer.timeout.connect(_on_timeout)

	add_child(_steal_timer)

	# is this necessary?
	_steal_timer.start.call_deferred()


func _get_available_radishes(
	active_animals: Array[Node]
) -> Array[Radish]:
	var available: Array[Radish] = []

	for radish in _context.get_radishes():
		if not is_instance_valid(radish):
			continue

		if not _is_targeted_by_mole(
			radish,
			active_animals
		):
			available.append(radish)

	return available


func _is_targeted_by_mole(
	radish: Radish,
	active_animals: Array[Node]
) -> bool:
	for animal in active_animals:
		if not is_instance_valid(animal):
			continue

		if animal is Mole:
			var mole := animal as Mole
			var other_target := mole.get_target()

			if (
				is_instance_valid(other_target)
				and other_target == radish
			):
				return true

	return false


func get_target() -> Radish:
	return _target


func _on_radish_picked(
	radish: Radish,
	_world_pos: Vector2,
	_grid_coords: Vector2i
) -> void:
	if radish == _target:
		_target = null


func _on_timeout() -> void:
	event_bus.emit_signal(
		"animal_stealing",
		self
	)

	if is_instance_valid(_target):
		if _context:
			_context.forget_radish(_target)

		_target.queue_free()

	exit()


func exit() -> void:
	collision_shape.set_deferred(
		"disabled",
		true
	)

	animation_component.play_exit()

	animation_component.animation_finished.connect(
		_on_exit_finished
	)


func _on_exit_finished() -> void:
	event_bus.emit_signal(
		"animal_despawned",
		self
	)

	queue_free()
