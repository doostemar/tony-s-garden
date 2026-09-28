# mole_animation.gd
class_name Mole_Animations
extends AnimatedSprite2D

func init() -> void:
	play("emerge")
	animation_finished.connect( _on_emerge_finished )
	z_index = 1
	z_as_relative = true
	y_sort_enabled = true

func _on_emerge_finished():
	if animation == "emerge":
		play( "default" )

func play_exit():
	speed_scale = speed_scale * 2
	play( "shouted_exit" )
