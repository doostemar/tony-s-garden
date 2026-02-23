# event_bus.gd
# singleton
extends Node

# radish lifecycle
signal radish_planted( radish, world_pos: Vector2, grid_coords: Vector2i )
signal radish_sprouted( radish, world_pos: Vector2, grid_coords: Vector2i )
signal radish_matured( radish, world_pos: Vector2, grid_coords: Vector2i )
signal radish_picked( radish, world_pos: Vector2, grid_coords: Vector2i )
signal radish_landed( radish )
signal radish_targeted( world_pos: Vector2 )
signal radish_thrown(radish: Radish, position: Vector2, direction: Vector2)
signal radish_landed_on_ground(radish: Radish, position: Vector2)
signal radish_spawn_requested(dirt, grid_coords: Vector2i)
signal radish_destroy_requested(radish)

# garden lifecycle / layout
signal garden_regenerated( side_length: int )
signal grid_ready()

# animals
signal spawn_requested( spawn_pos: Vector2, radish_state: int )
signal animal_spawned()
signal animal_despawned()
signal animal_stealing( animal )

# score
signal harvested( value: int )

# progression
signal difficulty_changed( difficulty: int )

# ui / achievement / economy events below

# game manager / progression
signal day_started( day: int )
signal day_ended( day: int, radishes_harvested: int, quota_met: bool )
signal quota_met()
signal time_expired()
