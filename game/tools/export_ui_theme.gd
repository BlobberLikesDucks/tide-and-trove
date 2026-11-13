extends Node
## Saves the Canva UI theme (UIKit.build_theme) to data/ui/ui_theme.res so the
## editor-built UI scenes can use it. Re-run after changing UIKit.build_theme():
##   godot --headless --path game res://tools/export_ui_theme.tscn
func _ready() -> void:
	var t := UIKit.build_theme()
	var err := ResourceSaver.save(t, UIKit.THEME_PATH, ResourceSaver.FLAG_COMPRESS)
	print("ui theme saved: ", err == OK, " -> ", UIKit.THEME_PATH)
	get_tree().quit()
