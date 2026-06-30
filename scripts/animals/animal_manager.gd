# animal_manager.gd
extends Node2D

@export_group("Nodes")
@export var garden_manager: Garden_Manager
@export var spawn_helper: Spawn_Helper
@export var factory: Enemy_Factory
@export var context: Animal_Context

@export_group("Spawn Settings")
@export var spawn_rate: float = 1.0
@export var spawn_chance: float = 0.2
@export var steal_rates: Array = [2.5, 2, 1.5]

var _spawn_timer: Timer
var _spawn_targets: Dictionary = {}
var _active_creatures: Dictionary = {}

signal spawn_chance_updated(chance: float)

func _ready() -> void:
	await _setup_context()
	_setup_timer()
	_connect_signals()
	factory.init(steal_rates)

func _setup_context():
	if not context:
		push_error("animal manager: context not assigned!")
		return
	
	if not is_instance_valid(garden_manager):
		push_error("animal manager: garden not assigned!")
		return

	var grid = garden_manager.get_cell_grid()
	context.set_grid(grid)

func _setup_timer():
	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_rate
	_spawn_timer.timeout.connect(_on_timeout)
	add_child(_spawn_timer)
	_spawn_timer.start(spawn_rate)

func _connect_signals():
	if event_bus.has_signal("difficulty_changed"): event_bus.difficulty_changed.connect(_on_global_difficulty_changed)
	if event_bus.has_signal("radish_planted"):     event_bus.radish_planted.connect(_on_radish_added)
	if event_bus.has_signal("radish_picked"):      event_bus.radish_picked.connect(_on_radish_removed)
	if event_bus.has_signal("radish_landed"):      event_bus.radish_landed.connect(_on_radish_added)
	if event_bus.has_signal("animal_stealing"):    event_bus.animal_stealing.connect(_on_radish_stolen)
	if event_bus.has_signal("animal_despawned"):   event_bus.animal_despawned.connect(_on_animal_despawned)
	if context.has_signal("spawn_chance_changed"): context.spawn_chance_changed.connect(_on_spawn_chance_changed)

## destroys all active animal instances.
## called at the start of each day and via debug reset.
func reset() -> void:
	if _spawn_timer:
		_spawn_timer.stop()

	# actually destroy every living animal node
	for child in get_children():
		if child.is_in_group("animal"):
			child.queue_free()

	_active_creatures.clear()
	_spawn_targets.clear()

	if _spawn_timer:
		_spawn_timer.start(spawn_rate)

	print("AnimalManager: reset complete")


func _on_radish_added(radish, world_pos: Vector2, grid_coords: Vector2i):
	_spawn_targets[radish] = spawn_helper.find_adjacent_grass_tiles(radish)

func _on_radish_removed(radish, world_pos: Vector2, grid_coords: Vector2i):
	_spawn_targets.erase(radish)
	_active_creatures.erase(radish)

func _on_timeout() -> void:
	_attempt_spawn()

func _attempt_spawn() -> void:
	if _spawn_targets.is_empty():
		return
	
	var available_radishes = _spawn_targets.keys().filter(
		func(radish):
			if not _active_creatures.has(radish):
				return true
			var animal = _active_creatures[radish]
			if not is_instance_valid(animal):
				_active_creatures.erase(radish)
				return true
			return false
	)
	
	if available_radishes.is_empty():
		return
	
	var radish = available_radishes.pick_random()
	var candidates = _spawn_targets.get(radish)
	var cell = spawn_helper.spawn_request(candidates, spawn_chance)
	if cell:
		cell.reset_collision()
		var animal = factory.spawn_animal(cell.global_position, radish.get_current_state())
		if animal:
			event_bus.emit_signal("animal_spawned")
			add_child(animal)
			_active_creatures[radish] = animal

func _on_global_difficulty_changed(new_difficulty: int) -> void:
	if context:
		context.difficulty = new_difficulty

func _on_spawn_chance_changed(modifier: float) -> void:
	spawn_chance = spawn_chance * modifier
	spawn_chance_updated.emit(spawn_chance)

func increase_spawn_chance(amount: float) -> void:
	spawn_chance = clampf(spawn_chance + amount, 0.0, 1.0)
	spawn_chance_updated.emit(spawn_chance)

func get_spawn_chance() -> float:
	return spawn_chance
	
func get_difficulty() -> int:
	return context.difficulty if context else 0

func _on_animal_despawned(animal) -> void:
	var radish = _active_creatures.find_key(animal)
	if radish:
		_active_creatures.erase(radish)

func _on_radish_stolen(animal) -> void:
	print("we get here: animal_manager._on_radish_stolen")
	var radish = _active_creatures.find_key(animal)
	if radish:
		_spawn_targets.erase(radish)
		_active_creatures.erase(radish)
		radish.queue_free()
