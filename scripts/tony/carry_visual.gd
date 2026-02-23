extends Sprite2D

@export var context: Tony_Context

var carry_item_location: String

func _ready() -> void:
	context.carry_state_changed.connect(_on_hand_item_change)
	
func _on_hand_item_change(carry_state: int, _item_id: StringName):
	match _item_id:
		"radish":
			print("we are carrying a radish")
			carry_item_location = "res://sprites/radish/radish_picked.png"
			set_visibility(true)
		_: 
			set_visibility(false)

func set_visibility(is_visible: bool):
	if self.visible && is_visible or !self.visible && !is_visible:
		return
	
	if is_visible:
		self.texture = load(carry_item_location)
		self.visible = true
	else:
		self.visible = false
