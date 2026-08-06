class_name Buff_Definition
extends Resource

enum StatType {
	MOVE_SPEED,
	SHOUT_RADIUS,
	THROW_SPEED,
	PLANT_RADIUS
}

@export var buff_id: StringName = &""
@export var display_name: String = ""
@export_multiline var flavor_text: String = ""
@export var icon: Texture2D
@export var stat_type: StatType = StatType.MOVE_SPEED

@export_range(0.01, 10.0, 0.01)
var modifier_per_tier: float = 0.20

@export_range(1, 99, 1)
var max_tier: int = 3

@export var duplicates_upgrade: bool = true


func get_multiplier_for_tier(tier: int) -> float:
	var clamped_tier := clampi(tier, 0, max_tier)
	return 1.0 + (modifier_per_tier * clamped_tier)
