# carry_visual.gd
extends Sprite2D

@export var context: Tony_Context

# vertical distance between stacked radishes (in this sprite's local pixels)
@export var stack_spacing: float = 5.0

var carry_item_location: String
var _held_count: int = 0
var _stack_sprites: Array[Sprite2D] = []


func _ready() -> void:
	context.carry_state_changed.connect(_on_hand_item_change)
	context.held_count_changed.connect(_on_held_count_changed)

	_held_count = context.held_count
	_update_stack()


func _on_hand_item_change(carry_state: int, _item_id: StringName):
	match _item_id:
		"radish":
			print("we are carrying a radish")
			carry_item_location = "res://sprites/radish/radish_picked.png"
			set_visibility(true)

		_:
			set_visibility(false)

	_update_stack()


func _on_held_count_changed(count: int) -> void:
	_held_count = count
	_update_stack()


func set_visibility(is_visible: bool):
	if self.visible && is_visible or !self.visible && !is_visible:
		return

	if is_visible:
		self.texture = load(carry_item_location)
		self.visible = true
	else:
		self.visible = false


# root sprite = radish #1 
# extra radishes are child sprites stacked upward
func _update_stack() -> void:
	var extra := maxi(_held_count - 1, 0)

	# grow the pool as needed (sprites are reused, never freed)
	while _stack_sprites.size() < extra:
		var s := Sprite2D.new()
		s.name = "StackSprite%d" % (_stack_sprites.size() + 2)
		s.visible = false

		add_child(s)
		_stack_sprites.append(s)

	for i in _stack_sprites.size():
		var s := _stack_sprites[i]

		if i < extra:
			_copy_sprite_settings(s)
			s.position = Vector2(0, -stack_spacing * (i + 1))
			s.visible = true
		else:
			s.visible = false


func _copy_sprite_settings(s: Sprite2D) -> void:
	s.texture = texture
	s.centered = centered
	s.offset = offset
	s.flip_h = flip_h
	s.flip_v = flip_v
	s.hframes = hframes
	s.vframes = vframes
	s.frame = frame
	s.region_enabled = region_enabled
	s.region_rect = region_rect
	s.modulate = Color.WHITE
	s.texture_filter = texture_filter
