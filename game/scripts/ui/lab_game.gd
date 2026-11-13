class_name LabGame
extends Control
## Precision cleaning mini-game. Chip away the rock matrix to expose every
## bone cell. The Micro-Brush is gentle; air scribes are fast but crack
## exposed bone. Damage lowers the Preservation Rating.

signal finished(pres: float)
signal changed

const GW := 18
const GH := 12

var bone: Array = []
var rock: Array = []
var dmg: Array = []
var tool := 1
var hover := Vector2i(-1, -1)
var cursor := Vector2i(9, 6)
var dmg_total := 0
var clicks := 0
var done := false
var bone_color := Color("e9dcc0")
var rng := RandomNumberGenerator.new()
var _total_bone := 0


func setup(shape: String, color: Color, seed_v: int) -> void:
	rng.seed = seed_v
	bone_color = color.lightened(0.25)
	bone.clear()
	rock.clear()
	dmg.clear()
	_total_bone = 0
	for y in range(GH):
		for x in range(GW):
			var u := ((x + 0.5) / GW * 2.0 - 1.0) * 1.5
			var v := (y + 0.5) / GH * 2.0 - 1.0
			var b := _in_shape(shape, u, v)
			bone.append(b)
			if b:
				_total_bone += 1
			var r := sqrt(u * u + v * v)
			rock.append(clampi(1 + int(rng.randf() * 2.2 + (1.0 - r * 0.6)), 1, 3))
			dmg.append(0)
	custom_minimum_size = Vector2(GW, GH) * 34.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	queue_redraw()


func _in_shape(s: String, u: float, v: float) -> bool:
	match s:
		"disc":
			return u * u + v * v < 0.55
		"spiral":
			var r := sqrt(u * u + v * v)
			return r < 0.85 and r > 0.08 and fmod(atan2(v, u) + PI + r * 9.0, TAU) > 0.8
		"tooth":
			return (v < 0.6 and absf(u) < (v + 0.85) * 0.5) or (v >= 0.5 and v < 0.85 and absf(u) < 0.8)
		"bone":
			return (absf(v) < 0.22 and absf(u) < 1.05) or (u - 1.1) * (u - 1.1) + v * v < 0.14 or (u + 1.1) * (u + 1.1) + v * v < 0.14
		"trilobite":
			return u * u / 0.42 + v * v / 0.72 < 1.0 and not (absf(u) > 0.25 and absf(u) < 0.32)
		"cone":
			return v < 0.85 and absf(u) < (v + 0.95) * 0.32
		"stem":
			return (absf(u) < 0.16 and v > -0.35) or (u * u + (v + 0.55) * (v + 0.55) < 0.22)
		"skull":
			return (u + 0.7) * (u + 0.7) + v * v / 0.8 < 0.32 or (u > -0.7 and u < 1.35 and absf(v) < 0.42 * (1.35 - u) / 2.0 + 0.06)
	return u * u + v * v < 0.5


func idx(c: Vector2i) -> int:
	return c.y * GW + c.x


func in_grid(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < GW and c.y < GH


func cell_px() -> Vector2:
	return size / Vector2(GW, GH)


func exposed() -> int:
	var n := 0
	for i in range(bone.size()):
		if bone[i] and rock[i] == 0:
			n += 1
	return n


func progress() -> float:
	return float(exposed()) / maxf(1.0, _total_bone)


func preservation() -> float:
	return clampf(1.0 - dmg_total * 0.05, 0.2, 1.0)


func _hit(c: Vector2i, amount: int, can_damage: bool, dmg_chance: float) -> void:
	if not in_grid(c):
		return
	var i := idx(c)
	if rock[i] > 0:
		rock[i] = maxi(0, rock[i] - amount)
	elif bone[i] and can_damage and rng.randf() < dmg_chance:
		dmg[i] += 1
		dmg_total += 1
		Audio.sfx("crack", 1.3, -6.0)


func chip(c: Vector2i) -> void:
	if done or not in_grid(c):
		return
	clicks += 1
	match tool:
		1:
			_hit(c, 1, false, 0.0)
			Audio.sfx("brush", randf_range(0.9, 1.2), -8.0)
		2:
			_hit(c, 2, true, 1.0)
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				_hit(c + d, 1, true, 0.35)
			Audio.sfx("chip", randf_range(0.9, 1.1), -4.0)
		_:
			_hit(c, 3, true, 1.0)
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
				_hit(c + d, 1, false, 0.0)
			Audio.sfx("chip", randf_range(0.7, 0.9), -4.0)
	queue_redraw()
	changed.emit()
	if exposed() >= _total_bone:
		done = true
		Audio.sfx("star_up")
		finished.emit(preservation())


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var c := Vector2i((event.position / cell_px()).floor())
		if c != hover:
			hover = c
			queue_redraw()
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT and tool == 1:
			chip(hover)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hover = Vector2i((event.position / cell_px()).floor())
		chip(hover)
		accept_event()


func move_cursor(d: Vector2i) -> void:
	cursor = Vector2i(clampi(cursor.x + d.x, 0, GW - 1), clampi(cursor.y + d.y, 0, GH - 1))
	hover = cursor
	queue_redraw()


func _draw() -> void:
	var cp := cell_px()
	draw_rect(Rect2(Vector2.ZERO, size), Color("4a3a2c"))
	var shades := [Color("5b4a3a"), Color("b8a98f"), Color("a0907a"), Color("85765f")]
	for y in range(GH):
		for x in range(GW):
			var i := y * GW + x
			var r := Rect2(Vector2(x, y) * cp, cp)
			var h := float((x * 73 + y * 151) % 7) / 60.0
			if rock[i] > 0:
				draw_rect(r.grow(-1), (shades[rock[i]] as Color).lightened(h))
				if rock[i] >= 2:
					draw_line(r.position + cp * Vector2(0.2, 0.3), r.position + cp * Vector2(0.6, 0.5), Color(0, 0, 0, 0.12), 2)
			elif bone[i]:
				var bc := bone_color.darkened(minf(0.6, dmg[i] * 0.25))
				draw_rect(r.grow(-0.5), bc.lightened(h * 0.5))
				if dmg[i] > 0:
					draw_line(r.position + cp * Vector2(0.1, 0.2), r.position + cp * Vector2(0.9, 0.8), Color("7a2a20"), 2)
					draw_line(r.position + cp * Vector2(0.5, 0.1), r.position + cp * Vector2(0.4, 0.9), Color("7a2a20"), 2)
			else:
				draw_rect(r.grow(-1), (shades[0] as Color).lightened(h))
	if in_grid(hover):
		var area: Array = [hover]
		if tool == 2:
			area += [hover + Vector2i(1, 0), hover + Vector2i(-1, 0), hover + Vector2i(0, 1), hover + Vector2i(0, -1)]
		elif tool == 3:
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					if dx != 0 or dy != 0:
						area.append(hover + Vector2i(dx, dy))
		for a: Vector2i in area:
			if in_grid(a):
				draw_rect(Rect2(Vector2(a) * cp, cp), Color(1, 0.85, 0.3, 0.9 if a == hover else 0.45), false, 2.0)
