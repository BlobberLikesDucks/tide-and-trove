class_name MoneyPopup
extends Control
## "+$25" that pops, floats up and fades next to the HUD money counter. The
## motion is authored as the "pop" animation of this scene's AnimationPlayer
## (res://scenes/ui/money_popup.tscn).

@onready var amount: Label = $Amount
@onready var anim: AnimationPlayer = $AnimationPlayer


func show_amount(v: int) -> void:
	amount.text = ("+" if v > 0 else "-") + UIKit.money_text(absi(v))
	amount.add_theme_color_override("font_color", Color(0.55, 0.95, 0.55) if v > 0 else Color(1.0, 0.45, 0.4))
	anim.play("pop")
	anim.animation_finished.connect(func(_n: StringName) -> void: queue_free(), CONNECT_ONE_SHOT)
