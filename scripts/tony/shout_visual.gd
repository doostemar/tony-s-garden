# shout_visual.gd
# renders tony's shout aoe via shout_visual.gdshader.
# it does not decide the radius; Shout_Component pushes the real collision
# radius/offset into it so the drawn circle always matches the physics shape.

class_name Shout_Visual
extends Sprite2D

# extra pixels around the circle so anti-aliased edges/rings are never clipped
@export var quad_padding: float = 4.0

# testing aid: draw a faint outline of the exact aoe at all times
@export var always_show_outline: bool = false:
	set(v):
		always_show_outline = v
		_set_param("show_static_outline", v)
		_update_visibility()

var _radius: float = 0.0
var _timer: Timer = null
var _active: bool = false

func _ready() -> void:
	centered = true
	_ensure_texture()
	_ensure_material()
	_set_param("show_static_outline", always_show_outline)
	_set_param("active", false)
	_set_param("progress", 0.0)
	_update_visibility()
	set_process(false)

func _process(_delta: float) -> void:
	if _timer == null or _timer.is_stopped():
		stop()
		return

	var wait := maxf(_timer.wait_time, 0.0001)
	var progress := 1.0 - (_timer.time_left / wait)
	_set_param("progress", clampf(progress, 0.0, 1.0))

# ---- api used by Shout_Component ---- #

# called whenever the actual CircleShape2D radius / collision offset changes
func sync_shape(radius: float, offset: Vector2) -> void:
	_radius = radius
	position = offset

	var quad_size := 2.0 * _radius + 2.0 * quad_padding

	# texture is 2x2, so scale = quad_size / 2 gives a quad_size x quad_size sprite
	scale = Vector2.ONE * (quad_size * 0.5)

	_set_param("radius", _radius)
	_set_param("quad_size", quad_size)

# start the effect; its lifetime is read directly from the hitbox timer
func play(hitbox_timer: Timer) -> void:
	_timer = hitbox_timer
	_active = true
	_set_param("active", true)
	_set_param("progress", 0.0)
	_update_visibility()
	set_process(true)

func stop() -> void:
	_active = false
	_timer = null
	_set_param("active", false)
	_set_param("progress", 0.0)
	set_process(false)
	_update_visibility()

# ---- internals ---- #

func _ensure_texture() -> void:
	if texture != null:
		return

	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	texture = ImageTexture.create_from_image(img)

func _ensure_material() -> void:
	if material is ShaderMaterial:
		return

	# fallback so the node still works if the material wasn't assigned in the inspector
	var shader := load("res://shaders/shout_visual.gdshader") as Shader

	if shader == null:
		push_warning("Shout_Visual: no ShaderMaterial assigned and fallback shader not found")
		return

	var mat := ShaderMaterial.new()
	mat.shader = shader
	material = mat

func _set_param(name: String, value) -> void:
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter(name, value)

func _update_visibility() -> void:
	visible = _active or always_show_outline
