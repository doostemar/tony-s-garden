# sound_manager.gd
# this is only a draft to test the event bus later
extends Node

func _ready():
	event_bus.radish_planted.connect(_on_planted)
	event_bus.radish_picked.connect(_on_picked)

func _on_planted(_radish, world_pos: Vector2, _coords: Vector2i) -> void:
	_play_2d("plant_seed", world_pos)

func _on_picked(_radish, world_pos: Vector2, _coords: Vector2i) -> void:
	_play_2d("pull_radish", world_pos)

# we play the sounds with this function, match the name
func _play_2d(name: String, world_pos: Vector2) -> void:
	# pool an AudioStreamPlayer2D, set its stream by `name`,
	# position to `world_pos`, then play
	print("[SFX]", name, "@", world_pos)
