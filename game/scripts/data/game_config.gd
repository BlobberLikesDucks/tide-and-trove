class_name GameConfig
extends Resource
## All gameplay tuning in one inspector-editable resource
## (res://data/game_config.tres). Scripts read numbers from here instead of
## hard-coding them, so balancing never needs a code change.

const PATH := "res://data/game_config.tres"
static var _cfg: GameConfig

@export_group("Rendering")
## Cel shader + ink outlines on every painted model (off = Godot's built-in toon mode).
@export var cel_shading: bool = true
@export_range(0.0, 0.05, 0.001) var outline_width: float = 0.006
@export var outline_color: Color = Color(0.16, 0.12, 0.14)

@export_group("Player")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.4
@export var jump_velocity: float = 5.2
@export var gravity: float = 16.0
@export var eye_height: float = 1.62
@export var reach: float = 2.7

@export_group("Inventory")
@export var hotbar_base_slots: int = 3
@export var backpack_base_slots: int = 6
@export var backpack_slots_per_upgrade: int = 4
@export var speed_bonus_per_upgrade: float = 0.12

@export_group("Economy")
@export var debt_limit: int = 1000
@export var debt_warn: int = 500
@export var start_money: int = 0

@export_group("Guests & stands")
@export var queue_patience: float = 45.0
@export var queue_patience_impatient: float = 30.0
@export var vendor_serve_time: float = 3.5
@export var trash_bin_capacity: int = 8
@export var restroom_dirty_at: int = 6

@export_group("Plaques")
## Mood a fossil enthusiast loses when they catch a wrong plaque.
@export var nerd_wrong_plaque_mood: float = 60.0
## How much an enthusiast's harsh review counts compared with a normal one.
@export var harsh_review_weight: float = 2.0
@export_range(0.0, 1.0) var visitor_complain_chance: float = 0.45


static func get_cfg() -> GameConfig:
	if _cfg == null:
		if ResourceLoader.exists(PATH):
			_cfg = load(PATH)
		if _cfg == null:
			_cfg = GameConfig.new()
	return _cfg
