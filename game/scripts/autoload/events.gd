extends Node
## Global signal bus so gameplay systems and UI stay decoupled.

signal toast(text: String, color: Color)
signal walkie(text: String, kind: String, world_pos: Vector3)
signal prompt(text: String)
signal objective_changed(text: String)
signal phase_changed(phase: int)
signal clock_changed(hours: float)
signal dialog_requested(lines: Array)
signal dialog_finished
signal open_panel(panel: String, data: Variant)
signal museum_changed
signal detector_ping(strength: float)
signal discovery(species: String)
signal half_star_gained(half_stars: int)
signal game_won
signal game_over(reason: String)
signal story_beat(beat: String)


func say(text: String, color: Color = Color.WHITE) -> void:
	toast.emit(text, color)


func radio(text: String, kind: String = "info", pos: Vector3 = Vector3.ZERO) -> void:
	walkie.emit(text, kind, pos)
