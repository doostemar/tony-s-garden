class_name Rabbit
extends CharacterBody2D


enum State {
	CHASING,
	CHEWING,
	IDLE,
	FLEEING
}


const ANIMAL_GROUP := "animal"
const RABBIT_GROUP := "rabbit"


@export_group("Nodes")
@export var sprite: Sprite2D
@export var collision_shape: CollisionShape2D
@export var garden_bounds: Garden_Bounds


@export_group("Targeting")
@export var max_rabbits_divisor: float = 3.0


@export_group("Spawning")
@export var spawn_margin: float = 8.0


@export_group("Movement")
@export var chase_speed: float = 30.0
@export var idle_speed: float = 10.0
@export var flee_speed: float = 60.0


@export_group("Chase Deviation")
@export_range(0.0, 89.0)
var deviation_max_degrees: float = 25.0

@export var deviation_interval: float = 0.4
@export var deviation_fade_distance: float = 24.0


@export_group("Chewing")
@export var chew_distance: float = 6.0
@export var chew_duration: float = 3.0


@export_group("Idle")
@export var idle_wander_radius: float = 24.0
@export var idle_arrival_distance: float = 2.0
@export var idle_pause_min: float = 0.5
@export var idle_pause_max: float = 2.0
@export var idle_bounds_inset: float = 4.0


@export_group("Fleeing")
@export var flee_margin: float = 16.0
@export var flee_arrival_distance: float = 2.0


var _context: Animal_Context
var _target: Radish

var _state: State = State.CHASING

var _spawn_position: Vector2

var _active_animals: Array[Node] = []

var _chew_timer: Timer

var _deviation_angle: float = 0.0
var _deviation_timer: float = 0.0

var _idle_anchor: Vector2
var _idle_destination: Vector2
var _idle_has_destination: bool = false
var _idle_pause_timer: float = 0.0

var _flee_point: Vector2


# -------------------------------------------------
# manager contract

func prepare_spawn_attempt(
	context: Animal_Context,
	active_animals: Array[Node]
) -> bool:
	_context = context
	_active_animals = active_animals

	if _context == null:
		return false

	if garden_bounds == null:
		push_error(
			"Rabbit: garden_bounds is not assigned."
		)
		return false

	if not garden_bounds.refresh(_context):
		return false

	var available := _get_available_sprouts(
		active_animals
	)

	if available.is_empty():
		return false

	# Existing idle rabbits always get priority.
	var idle_rabbit := _find_idle_rabbit(
		active_animals
	)

	if idle_rabbit:
		var candidates := available.duplicate()

		while not candidates.is_empty():
			var radish: Radish = candidates.pick_random()

			if idle_rabbit.try_claim_sprout(radish):
				return false

			candidates.erase(radish)

		# continue normally if the idle rabbit couldn't actually claim
		# instead of wasting a tick

	if _count_rabbits(active_animals) >= _get_max_rabbits():
		return false

	_target = available.pick_random()

	var nearest_side := garden_bounds.get_nearest_side(
		_target.global_position
	)

	_spawn_position = (
		garden_bounds.get_random_point_outside(
			nearest_side,
			spawn_margin
		)
	)

	return true


func start_spawn() -> bool:
	if not _is_target_valid():
		_target = null
		return false

	global_position = _spawn_position

	return true


# -------------------------------------------------
# lifecycle

func _ready() -> void:
	add_to_group(ANIMAL_GROUP)
	add_to_group(RABBIT_GROUP)

	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	collision_layer = 1 << 5
	collision_mask = 0

	z_index = 2
	z_as_relative = true

	if sprite:
		sprite.texture_filter = (
			CanvasItem.TEXTURE_FILTER_NEAREST
		)

	_setup_chew_timer()
	_connect_events()

	if _context == null:
		_become_idle()
		return

	global_position = _spawn_position

	if _is_target_valid():
		_begin_chase()
	else:
		_release_target()
		_seek_new_target_or_idle()


func _setup_chew_timer() -> void:
	_chew_timer = Timer.new()
	_chew_timer.one_shot = true
	_chew_timer.wait_time = chew_duration
	_chew_timer.timeout.connect(_on_chew_finished)

	add_child(_chew_timer)


func _connect_events() -> void:
	if event_bus.has_signal("radish_sprouted"):
		event_bus.radish_sprouted.connect(
			_on_radish_sprouted
		)

	if event_bus.has_signal("radish_picked"):
		event_bus.radish_picked.connect(
			_on_radish_picked
		)


func _physics_process(delta: float) -> void:
	match _state:
		State.CHASING:
			_process_chase(delta)

		State.CHEWING:
			_process_chewing()

		State.IDLE:
			_process_idle(delta)

		State.FLEEING:
			_process_fleeing()


# -------------------------------------------------
# chasing

func _begin_chase() -> void:
	_state = State.CHASING
	_deviation_timer = 0.0
	_deviation_angle = 0.0


func _process_chase(delta: float) -> void:
	if not _is_target_valid():
		_release_target()
		_seek_new_target_or_idle()
		return

	var to_target := (
		_target.global_position
		- global_position
	)

	var distance := to_target.length()

	if distance <= chew_distance:
		_begin_chewing()
		return

	_update_deviation(
		delta,
		distance
	)

	var direction := (
		to_target.normalized()
		.rotated(_deviation_angle)
	)

	velocity = direction * chase_speed
	move_and_slide()


func _update_deviation(
	delta: float,
	distance: float
) -> void:
	_deviation_timer -= delta

	if _deviation_timer <= 0.0:
		_deviation_timer = deviation_interval

		_deviation_angle = deg_to_rad(
			randf_range(
				-deviation_max_degrees,
				deviation_max_degrees
			)
		)

	# remove the wobble as we approach the target so the rabbit doesn't circle sprout forever
	var fade := clampf(
		(distance - chew_distance)
		/ maxf(deviation_fade_distance, 0.001),
		0.0,
		1.0
	)

	_deviation_angle *= fade


# ------------------------------------------------- 
# chewing 

func _begin_chewing() -> void:
	if not _is_target_valid():
		_seek_new_target_or_idle()
		return

	_state = State.CHEWING
	velocity = Vector2.ZERO

	_target.pause_growth()

	_chew_timer.start(chew_duration)


func _process_chewing() -> void:
	if not _is_target_valid():
		_release_target()
		_seek_new_target_or_idle()


func _on_chew_finished() -> void:
	if _state != State.CHEWING:
		return

	if not _is_target_valid():
		_release_target()
		_seek_new_target_or_idle()
		return

	_eat_target()
	_seek_new_target_or_idle()


func _eat_target() -> void:
	var radish := _target
	_target = null

	event_bus.emit_signal(
		"animal_stealing",
		self
	)

	if _context:
		_context.forget_radish(radish)

	# rabbit decides that its target was eaten
	# manager destroys
	event_bus.emit_signal(
		"radish_destroy_requested",
		radish
	)


# -------------------------------------------------
# idle

func _become_idle() -> void:
	_state = State.IDLE

	velocity = Vector2.ZERO

	_idle_anchor = global_position

	if garden_bounds and garden_bounds.is_valid():
		_idle_anchor = garden_bounds.clamp_inside(
			global_position,
			idle_bounds_inset
		)

	_idle_has_destination = false

	_idle_pause_timer = randf_range(
		idle_pause_min,
		idle_pause_max
	)


func _process_idle(delta: float) -> void:
	# fallback scan in case a sprout appeared without the normal event reaching us
	var sprout := _find_available_sprout()

	if sprout:
		_target = sprout
		_begin_chase()
		return

	if _idle_pause_timer > 0.0:
		_idle_pause_timer -= delta
		velocity = Vector2.ZERO
		return

	if not _idle_has_destination:
		_pick_idle_destination()

	var to_destination := (
		_idle_destination
		- global_position
	)

	if (
		to_destination.length()
		<= idle_arrival_distance
	):
		_idle_has_destination = false

		_idle_pause_timer = randf_range(
			idle_pause_min,
			idle_pause_max
		)

		velocity = Vector2.ZERO
		return

	velocity = (
		to_destination.normalized()
		* idle_speed
	)

	move_and_slide()


func _pick_idle_destination() -> void:
	var offset := (
		Vector2.from_angle(randf() * TAU)
		* randf_range(
			idle_wander_radius * 0.25,
			idle_wander_radius
		)
	)

	var destination := (
		_idle_anchor + offset
	)

	if garden_bounds and garden_bounds.is_valid():
		destination = garden_bounds.clamp_inside(
			destination,
			idle_bounds_inset
		)

	_idle_destination = destination
	_idle_has_destination = true


func is_idle() -> bool:
	return _state == State.IDLE


func try_claim_sprout(
	radish: Radish
) -> bool:
	if _state != State.IDLE:
		return false

	if not _is_sprout_available(
		radish,
		_get_other_rabbits()
	):
		return false

	_target = radish
	_begin_chase()

	return true


# -------------------------------------------------
# fleeing

func exit() -> void:
	if _state == State.FLEEING:
		return

	var released := _release_target()

	_state = State.FLEEING
	velocity = Vector2.ZERO

	if garden_bounds and garden_bounds.is_valid():
		_flee_point = garden_bounds.get_exit_point(
			global_position,
			flee_margin
		)
	else:
		_flee_point = global_position

	# sprout becomes available immediately
	_offer_to_idle_rabbit(released)


func _process_fleeing() -> void:
	var to_exit := (
		_flee_point
		- global_position
	)

	if (
		to_exit.length()
		<= flee_arrival_distance
	):
		_despawn()
		return

	velocity = (
		to_exit.normalized()
		* flee_speed
	)

	move_and_slide()


func _despawn() -> void:
	event_bus.emit_signal(
		"animal_despawned",
		self
	)

	queue_free()


# -------------------------------------------------
# target management

func _release_target() -> Radish:
	var released := _target

	if (
		_state == State.CHEWING
		and is_instance_valid(released)
	):
		released.resume_growth()

	if _chew_timer:
		_chew_timer.stop()

	_target = null

	return released


func _seek_new_target_or_idle() -> void:
	var sprout := _find_available_sprout()

	if sprout == null:
		_become_idle()
		return

	_target = sprout
	_begin_chase()


func _find_available_sprout() -> Radish:
	var available := _get_available_sprouts(
		_get_other_rabbits()
	)

	if available.is_empty():
		return null

	return available.pick_random()


func _get_available_sprouts(
	rabbits: Array[Node]
) -> Array[Radish]:
	var result: Array[Radish] = []

	if _context == null:
		return result

	for radish in _context.get_radishes():
		if _is_sprout_available(
			radish,
			rabbits
		):
			result.append(radish)

	return result


func _is_sprout_available(
	radish: Radish,
	rabbits: Array[Node]
) -> bool:
	if not is_instance_valid(radish):
		return false

	if radish.is_queued_for_deletion():
		return false

	if (
		radish.get_current_state()
		!= Radish.RadishState.SPROUT
	):
		return false

	for rabbit in rabbits:
		if not is_instance_valid(rabbit):
			continue

		if rabbit == self:
			continue

		if rabbit is Rabbit:
			if (
				(rabbit as Rabbit).get_target()
				== radish
			):
				return false

	return true


func _is_target_valid() -> bool:
	if not is_instance_valid(_target):
		return false

	if _target.is_queued_for_deletion():
		return false

	return (
		_target.get_current_state()
		== Radish.RadishState.SPROUT
	)


func get_target() -> Radish:
	return _target


# -------------------------------------------------
# rabbit population / target reservation

func _get_other_rabbits() -> Array[Node]:
	if not is_inside_tree():
		return _active_animals

	return get_tree().get_nodes_in_group(
		RABBIT_GROUP
	)


func _find_idle_rabbit(
	animals: Array[Node]
) -> Rabbit:
	for animal in animals:
		if not is_instance_valid(animal):
			continue

		if (
			animal is Rabbit
			and (animal as Rabbit).is_idle()
		):
			return animal as Rabbit

	return null


func _count_rabbits(
	animals: Array[Node]
) -> int:
	var count := 0

	for animal in animals:
		if (
			is_instance_valid(animal)
			and animal is Rabbit
		):
			count += 1

	return count


func _get_max_rabbits() -> int:
	if _context == null:
		return 0

	var grid := _context.get_cell_grid()

	if grid == null:
		return 0

	var side_length: int = grid.get_grid_len()

	return int(
		ceil(
			side_length
			/ maxf(
				max_rabbits_divisor,
				0.001
			)
		)
	)


func _offer_to_idle_rabbit(
	radish: Radish
) -> void:
	if not is_instance_valid(radish):
		return

	if (
		radish.get_current_state()
		!= Radish.RadishState.SPROUT
	):
		return

	for animal in _get_other_rabbits():
		if not is_instance_valid(animal):
			continue

		if animal == self:
			continue

		if (
			animal is Rabbit
			and (animal as Rabbit).try_claim_sprout(
				radish
			)
		):
			return


# -------------------------------------------------
# radish events

func _on_radish_sprouted(
	radish: Radish,
	_world_position: Vector2,
	_grid_coords: Vector2i
) -> void:
	if _state != State.IDLE:
		return

	try_claim_sprout(radish)


func _on_radish_picked(
	radish: Radish,
	_world_position: Vector2,
	_grid_coords: Vector2i
) -> void:
	if radish != _target:
		return

	_release_target()
	_seek_new_target_or_idle()
