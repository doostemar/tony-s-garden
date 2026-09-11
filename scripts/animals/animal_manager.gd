# animal_manager.gd
extends Node2D

@export_group("Nodes")
@export var garden_manager: Garden_Manager
@export var context: Animal_Context

@export_group("Animals")
@export var animal_scenes: Array[PackedScene] = []

@export_group("Spawn Settings")
@export var spawn_rate: float = 1.0
@export var spawn_chance: float = 0.2

var _spawn_timer: Timer
var _active_animals: Array[Node] = []

signal spawn_chance_updated(chance: float)


func _ready() -> void:
	await _setup_context()
	_setup_timer()
	_connect_signals()


func _setup_context() -> void:
	if not context:
		push_error("animal manager: context not assigned!")
		return

	if not is_instance_valid(garden_manager):
		push_error("animal manager: garden not assigned!")
		return

	var grid = garden_manager.get_cell_grid()
	context.set_grid(grid)


func _setup_timer() -> void:
	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_rate
	_spawn_timer.timeout.connect(_on_timeout)
	add_child(_spawn_timer)
	_spawn_timer.start(spawn_rate)


func _connect_signals() -> void:
	if event_bus.has_signal("difficulty_changed"):
		event_bus.difficulty_changed.connect(
			_on_global_difficulty_changed
		)

	if event_bus.has_signal("animal_despawned"):
		event_bus.animal_despawned.connect(
			_on_animal_despawned
		)

	if context.has_signal("spawn_chance_changed"):
		context.spawn_chance_changed.connect(
			_on_spawn_chance_changed
		)


## destroys all active animals and clears shared animal state
## called at the start of each day and via debug reset
func reset() -> void:
	if _spawn_timer:
		_spawn_timer.stop()

	for animal in _active_animals:
		if is_instance_valid(animal):
			animal.queue_free()

	_active_animals.clear()

	if context:
		context.clear_radishes()

	if _spawn_timer:
		_spawn_timer.start(spawn_rate)

	print("AnimalManager: reset complete")


func _on_timeout() -> void:
	_cleanup_active_animals()
	_attempt_spawn()


func _attempt_spawn() -> void:
	if animal_scenes.is_empty():
		return

	var animal_scene := _get_animal_scene()

	if animal_scene == null:
		return

	var animal := animal_scene.instantiate()

	if not animal.has_method("prepare_spawn_attempt"):
		push_error(
			"AnimalManager: animal scene does not implement "
			+ "prepare_spawn_attempt(context, active_animals)"
		)
		animal.free()
		return

	if not animal.has_method("start_spawn"):
		push_error(
			"AnimalManager: animal scene does not implement start_spawn()"
		)
		animal.free()
		return

	# the animal decides the following:
	# - whether a target exists
	# - which target it wants
	# - where it would spawn
	#
	# **note** this happens before the shared spawn roll so the mole can preserve
	# the old target-selection behavior. this may need to change
	var prepared: bool = animal.call(
		"prepare_spawn_attempt",
		context,
		_active_animals
	)

	if not prepared:
		animal.free()
		return

	# kinda backwards looking
	if randf() <= spawn_chance:
		animal.free()
		return

	# animal performs its final species-specific eligibility checks
	var started: bool = animal.call("start_spawn")

	if not started:
		animal.free()
		return

	# animal_spawned emitted before animal is added to the scene. is this ok?
	event_bus.emit_signal("animal_spawned")

	add_child(animal)
	_active_animals.append(animal)


func _get_animal_scene() -> PackedScene:
	if animal_scenes.size() == 1:
		return animal_scenes[0]

	return animal_scenes.pick_random()


func _cleanup_active_animals() -> void:
	for i in range(_active_animals.size() - 1, -1, -1):
		if not is_instance_valid(_active_animals[i]):
			_active_animals.remove_at(i)


func _on_global_difficulty_changed(new_difficulty: int) -> void:
	if context:
		context.difficulty = new_difficulty


func _on_spawn_chance_changed(modifier: float) -> void:
	spawn_chance = spawn_chance * modifier
	spawn_chance_updated.emit(spawn_chance)


func increase_spawn_chance(amount: float) -> void:
	spawn_chance = clampf(
		spawn_chance + amount,
		0.0,
		1.0
	)

	spawn_chance_updated.emit(spawn_chance)


func get_spawn_chance() -> float:
	return spawn_chance


func get_difficulty() -> int:
	return context.difficulty if context else 0


func _on_animal_despawned(animal) -> void:
	_active_animals.erase(animal)
