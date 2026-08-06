class_name ShopUI
extends CanvasLayer

@export_group("Gameplay References")
@export var game_manager: GameManager
@export var tony: CharacterBody2D

@export_group("Main Display")
@export var title_label: Label
@export var radish_label: Label
@export var no_radish_label: Label

@export_group("Item Rows")
@export var move_speed_row: Control
@export var throw_speed_row: Control
@export var plant_radius_row: Control
@export var shout_radius_row: Control

@export_group("Item Buttons")
@export var move_speed_button: Button
@export var throw_speed_button: Button
@export var plant_radius_button: Button
@export var shout_radius_button: Button

@export_group("Item Icons")
@export var move_speed_icon: TextureRect
@export var throw_speed_icon: TextureRect
@export var plant_radius_icon: TextureRect
@export var shout_radius_icon: TextureRect

@export_group("Action Buttons")
@export var continue_button: Button
@export var end_game_button: Button

const ITEM_NAMES := {
	Buff_Definition.StatType.MOVE_SPEED: "Coffee",
	Buff_Definition.StatType.THROW_SPEED: "Baseball glove",
	Buff_Definition.StatType.PLANT_RADIUS: "Big seed bag",
	Buff_Definition.StatType.SHOUT_RADIUS: "Whistle",
}

const ITEM_ORDER := [
	Buff_Definition.StatType.MOVE_SPEED,
	Buff_Definition.StatType.THROW_SPEED,
	Buff_Definition.StatType.PLANT_RADIUS,
	Buff_Definition.StatType.SHOUT_RADIUS,
]

const ITEM_COST := 1

# StatType -> {
#     "row": Control,
#     "button": Button,
#     "buff": Buff_Definition
# }
var _item_rows: Dictionary = {}

var buff_manager: Buff_Manager

var _opened_with_no_radishes: bool = false

var _focusable_buttons: Array[Button] = []
var _focus_index: int = 0


func _ready() -> void:
	_build_item_mapping()
	_connect_button_signals()
	_connect_game_signals()
	_resolve_buff_manager()

	visible = false


func _build_item_mapping() -> void:
	_item_rows = {
		Buff_Definition.StatType.MOVE_SPEED: {
			"row": move_speed_row,
			"button": move_speed_button,
			"icon": move_speed_icon,
			"buff": null,
		},
		Buff_Definition.StatType.THROW_SPEED: {
			"row": throw_speed_row,
			"button": throw_speed_button,
			"icon": throw_speed_icon,
			"buff": null,
		},
		Buff_Definition.StatType.PLANT_RADIUS: {
			"row": plant_radius_row,
			"button": plant_radius_button,
			"icon": plant_radius_icon,
			"buff": null,
		},
		Buff_Definition.StatType.SHOUT_RADIUS: {
			"row": shout_radius_row,
			"button": shout_radius_button,
			"icon": shout_radius_icon,
			"buff": null,
		},
	}


func _connect_button_signals() -> void:
	for stat_type in ITEM_ORDER:
		var data: Dictionary = _item_rows[stat_type]
		var button: Button = data["button"]

		if button == null:
			push_error(
				"ShopUI: button not assigned for stat type %s."
				% stat_type
			)
			continue

		button.pressed.connect(
			_on_item_pressed.bind(stat_type)
		)

	if continue_button:
		continue_button.pressed.connect(
			_on_continue_pressed
		)
	else:
		push_error("ShopUI: continue_button not assigned.")

	if end_game_button:
		end_game_button.pressed.connect(
			_on_end_game_pressed
		)
	else:
		push_error("ShopUI: end_game_button not assigned.")


func _connect_game_signals() -> void:
	if game_manager == null:
		push_error("ShopUI: game_manager not assigned.")
		return

	game_manager.day_ended.connect(_on_day_ended)
	game_manager.bonus_updated.connect(_on_bonus_updated)
	game_manager.day_started.connect(_on_day_started)


func _resolve_buff_manager() -> void:
	if tony == null:
		push_error("ShopUI: tony not assigned.")
		return

	if not tony.has_method("get_buff_manager"):
		push_error(
			"ShopUI: Tony does not provide get_buff_manager()."
		)
		return

	buff_manager = tony.get_buff_manager()

	if buff_manager == null:
		push_error("ShopUI: buff_manager could not be resolved.")


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W:
				_move_focus(-1)
				get_viewport().set_input_as_handled()
				return

			KEY_S:
				_move_focus(1)
				get_viewport().set_input_as_handled()
				return

			KEY_A, KEY_D:
				get_viewport().set_input_as_handled()
				return

			KEY_SPACE:
				_activate_focused()
				get_viewport().set_input_as_handled()
				return

			KEY_ENTER, KEY_KP_ENTER:
				get_viewport().set_input_as_handled()
				return

	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()


func _rebuild_focusable_list() -> void:
	_focusable_buttons.clear()

	if not _opened_with_no_radishes:
		for stat_type in ITEM_ORDER:
			var data: Dictionary = _item_rows[stat_type]
			var row: Control = data["row"]
			var button: Button = data["button"]

			if (
				row
				and row.visible
				and button
				and button.visible
			):
				_focusable_buttons.append(button)

	if continue_button:
		_focusable_buttons.append(continue_button)

	if end_game_button and end_game_button.visible:
		_focusable_buttons.append(end_game_button)

	if _focusable_buttons.is_empty():
		_focus_index = 0
		return

	_focus_index = clampi(
		_focus_index,
		0,
		_focusable_buttons.size() - 1
	)

	_apply_focus()


func _move_focus(direction: int) -> void:
	if _focusable_buttons.is_empty():
		return

	_focus_index = wrapi(
		_focus_index + direction,
		0,
		_focusable_buttons.size()
	)

	_apply_focus()


func _apply_focus() -> void:
	if _focusable_buttons.is_empty():
		return

	_focus_index = clampi(
		_focus_index,
		0,
		_focusable_buttons.size() - 1
	)

	_focusable_buttons[_focus_index].grab_focus()


func _activate_focused() -> void:
	if _focusable_buttons.is_empty():
		return

	var button := _focusable_buttons[_focus_index]

	if button.disabled:
		return

	button.pressed.emit()


func _on_day_ended(
	success: bool,
	_harvested: int,
	_quota: int
) -> void:
	if not success:
		return

	_open_shop()


func _on_day_started(_day_number: int) -> void:
	_close_shop()


func _open_shop() -> void:
	if game_manager == null:
		return

	_opened_with_no_radishes = (
		game_manager.get_bonus_radishes() <= 0
	)

	if not _opened_with_no_radishes:
		_resolve_shop_buffs()

	var final_day := game_manager.is_on_final_day()

	if continue_button:
		continue_button.text = (
			"Continue Playing"
			if final_day
			else "Continue to Next Day"
		)

	if end_game_button:
		end_game_button.visible = final_day

	_refresh()

	visible = true
	_focus_index = 0
	_rebuild_focusable_list()


func _close_shop() -> void:
	visible = false


func _on_continue_pressed() -> void:
	_close_shop()

	if game_manager == null:
		return

	if game_manager.is_on_final_day():
		game_manager.enter_endless_mode()

	if game_manager.is_awaiting_continue():
		game_manager.confirm_continue()


func _on_end_game_pressed() -> void:
	_close_shop()

	if game_manager:
		game_manager.end_game()


func _on_item_pressed(stat_type: int) -> void:
	if game_manager == null or buff_manager == null:
		return

	if not _item_rows.has(stat_type):
		return

	var data: Dictionary = _item_rows[stat_type]
	var buff: Buff_Definition = data.get("buff")

	if buff == null:
		return

	if game_manager.get_bonus_radishes() < ITEM_COST:
		return

	if buff_manager.get_buff_tier(buff.buff_id) >= buff.max_tier:
		return

	if not game_manager.spend_bonus_radishes(ITEM_COST):
		return

	buff_manager.apply_buff(buff, &"shop")

	_refresh()
	_rebuild_focusable_list()


func _on_bonus_updated(_total: int) -> void:
	if visible:
		_refresh()
		_rebuild_focusable_list()


func _refresh() -> void:
	if _opened_with_no_radishes:
		if title_label:
			title_label.text = ""

		if radish_label:
			radish_label.visible = false

		if no_radish_label:
			no_radish_label.visible = true

		_set_item_rows_visible(false)
		return

	if title_label:
		title_label.text = "Shop"

	if radish_label:
		radish_label.visible = true

	if no_radish_label:
		no_radish_label.visible = false

	_set_item_rows_visible(true)

	var radishes := game_manager.get_bonus_radishes()

	if radish_label:
		radish_label.text = "Radishes: %d" % radishes

	for stat_type in ITEM_ORDER:
		var data: Dictionary = _item_rows[stat_type]
		var row: Control = data["row"]
		var button: Button = data["button"]
		var buff: Buff_Definition = data.get("buff")
		var item_name: String = ITEM_NAMES[stat_type]

		if row == null or button == null:
			continue

		if buff == null:
			row.visible = true
			button.visible = true
			button.disabled = true
			button.text = "%s (unavailable)" % item_name
			continue

		var current_tier := buff_manager.get_buff_tier(
			buff.buff_id
		)

		var at_max := current_tier >= buff.max_tier

		# Preserve the original behavior:
		# only the button is hidden at max tier.
		if at_max:
			button.visible = false
		else:
			button.visible = true
			button.disabled = radishes < ITEM_COST
			button.text = (
				"%s  (1 radish)  [tier %d/%d]"
				% [
					item_name,
					current_tier,
					buff.max_tier,
				]
			)


func _set_item_rows_visible(value: bool) -> void:
	for stat_type in ITEM_ORDER:
		var data: Dictionary = _item_rows[stat_type]
		var row: Control = data["row"]

		if row:
			row.visible = value


func _resolve_shop_buffs() -> void:
	if buff_manager == null:
		return

	for stat_type in ITEM_ORDER:
		var buff := _find_buff_for_stat(stat_type)
		var data: Dictionary = _item_rows[stat_type]

		data["buff"] = buff

		var icon_rect: TextureRect = data["icon"]

		if icon_rect:
			icon_rect.texture = buff.icon if buff else null
			icon_rect.visible = (
				buff != null
				and buff.icon != null
			)


func _find_buff_for_stat(stat_type: int) -> Buff_Definition:
	if buff_manager == null:
		return null

	for buff in buff_manager.radish_buff_pool:
		if buff and buff.stat_type == stat_type:
			return buff

	return null
