# rabbit.gd
class_name Rabbit
extends CharacterBody2D

const ANIMAL_GROUP := "animal"
const RABBIT_GROUP := "rabbit"

@export_group("Nodes")
@export var sprite: Sprite2D
@export var collision_shape: CollisionShape2D
@export var garden_bounds: Garden_Bounds
@export var targeting: Rabbit_Targeting
@export var state_machine: Rabbit_State_Machine

@export_group("States")
@export var chase_state: Rabbit_State
@export var idle_state: Rabbit_State
@export var flee_state: Rabbit_State

@export_group("Targeting")
@export var max_rabbits_divisor: float = 3.0

@export_group("Spawning")
@export var spawn_margin: float = 8.0

var _spawn_position: Vector2


# -------------------------------------------------
# manager contract

func prepare_spawn_attempt(context: Animal_Context, active_animals: Array[Node]) -> bool:
	targeting.init(self)
	targeting.set_context(context, active_animals)

	if context == null:
		return false

	if garden_bounds == null:
		push_error("Rabbit: garden_bounds is not assigned.")
		return false

	if not garden_bounds.refresh(context):
		return false

	var available := targeting.get_available_sprouts(active_animals)

	if available.is_empty():
		return false

	# existing idle rabbits always get priority
	# maybe change to nearest rabbit?
	var idle_rabbit := _find_idle_rabbit(active_animals)

	if idle_rabbit:
		var candidates := available.duplicate()

		while not candidates.is_empty():
			var radish: Radish = candidates.pick_random()

			if idle_rabbit.try_claim_sprout(radish):
				return false

			candidates.erase(radish)

		# if the idle rabbit couldn't actually
		# claim anything, continue normally

	if _count_rabbits(active_animals) >= _get_max_rabbits():
		return false

	var target: Radish = available.pick_random()

	targeting.set_target(target)

	var nearest_side := garden_bounds.get_nearest_side(target.global_position)

	_spawn_position = garden_bounds.get_random_point_outside(nearest_side, spawn_margin)

	return true


func start_spawn() -> bool:
	if not targeting.is_target_valid():
		targeting.release_target()
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
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	targeting.init(self)

	_connect_events()

	var starting_state := idle_state

	if targeting.is_target_valid():
		global_position = _spawn_position
		starting_state = chase_state
	else:
		targeting.release_target()

		if targeting.acquire_random_sprout():
			starting_state = chase_state

	state_machine.init(self, targeting, starting_state)


func _physics_process(delta: float) -> void:
	state_machine.process_physics(delta)


func _connect_events() -> void:
	if event_bus.has_signal("radish_sprouted"):
		event_bus.radish_sprouted.connect(_on_radish_sprouted)

	if event_bus.has_signal("radish_picked"):
		event_bus.radish_picked.connect(_on_radish_picked)


# -------------------------------------------------
# public

func get_target() -> Radish:
	return targeting.get_target()


func is_idle() -> bool:
	return state_machine.is_in_state(idle_state)


func try_claim_sprout(radish: Radish) -> bool:
	if not is_idle():
		return false

	if not targeting.is_sprout_available(radish, targeting.get_other_rabbits()):
		return false

	targeting.set_target(radish)

	return true


func exit() -> void:
	if state_machine.is_in_state(flee_state):
		return

	flee_state.enter()


# -------------------------------------------------
# rabbit population

func _find_idle_rabbit(animals: Array[Node]) -> Rabbit:
	for animal in animals:
		if not is_instance_valid(animal):
			continue

		if animal is Rabbit and (animal as Rabbit).is_idle():
			return animal as Rabbit

	return null


func _count_rabbits(animals: Array[Node]) -> int:
	var count := 0

	for animal in animals:
		if is_instance_valid(animal) and animal is Rabbit:
			count += 1

	return count


func _get_max_rabbits() -> int:
	if targeting.context == null:
		return 0

	var grid := targeting.context.get_cell_grid()

	if grid == null:
		return 0

	var side_length: int = grid.get_grid_len()

	return int(ceil(side_length / maxf(max_rabbits_divisor, 0.001)))


func offer_to_idle_rabbit(radish: Radish) -> void:
	if not is_instance_valid(radish):
		return

	if radish.get_current_state() != Radish.RadishState.SPROUT:
		return

	for animal in targeting.get_other_rabbits():
		if not is_instance_valid(animal):
			continue

		if animal == self:
			continue

		if animal is Rabbit and (animal as Rabbit).try_claim_sprout(radish):
			return


# -------------------------------------------------
# radish events

func _on_radish_sprouted(radish: Radish, _world_position: Vector2, _grid_coords: Vector2i) -> void:
	if not is_idle():
		return

	try_claim_sprout(radish)


func _on_radish_picked(radish: Radish, _world_position: Vector2, _grid_coords: Vector2i) -> void:
	if radish != targeting.get_target():
		return

	# if Chew owns the radish right now, its
	# exit() must run so growth cleanup happens
	if state_machine.current_state is Rabbit_Chew_State:
		state_machine.change_state(idle_state)

	targeting.release_target()

	if targeting.acquire_random_sprout():
		state_machine.change_state(chase_state)
