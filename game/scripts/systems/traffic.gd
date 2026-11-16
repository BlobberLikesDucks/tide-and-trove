class_name Traffic
extends Node3D
## Street traffic between the two road tunnels: four kinds of cars and two
## buses. Cars pass by now and then; while the museum is open, visitors ARRIVE
## by car (it pulls up at the kerb, drops them off and drives on); leaving
## visitors sit on the bus-stop bench (or stand next to it) until the city bus
## picks them up. School trips come in the yellow school bus. Anyone standing
## on the road - guests or YOU - gets knocked over (ragdoll).

const EAST_Z := -31.5   # museum-side lane, driving +X (kerb on the right)
const WEST_Z := -34.5   # shop-side lane, driving -X
const SPAWN_X := 47.0   # inside the tunnel bores, out of sight
const CARS := ["car_hatch", "car_sedan", "car_van", "car_pickup"]
const CAR_COLORS := [Color("e05a4a"), Color("3f7fd9"), Color("f4b82a"), Color("5aa84a"), Color("f2efe6"), Color("8a5cc2"), Color("2c3e4f"), Color("ff8a3c")]
const SEATS := [Vector3(-16.3, 0, -27.95), Vector3(-16.85, 0, -27.95), Vector3(-17.4, 0, -27.95)]
const BUS_DOOR_X := -16.0

var vehicles: Array = []
var _ambient_t := 4.0
var _bus_t := -1.0
var _waiting: Array = []
var _seat_taken := {}
var city_bus: Vehicle
var school_bus: Vehicle
## Trip members waiting for their school bus to come back and pick them up.
var _trip_waiting: Array = []
var _trip_total := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	# road tunnels at both ends of the street (the bore runs away from town)
	var east := Art.model("tunnel_portal")
	east.position = Vector3(28.6, 0, -33.0)
	add_child(east)
	var west := Art.model("tunnel_portal")
	west.position = Vector3(-28.6, 0, -33.0)
	west.rotation.y = PI
	add_child(west)


# ------------------------------------------------------------------- spawn ---
func spawn(model_id: String, dir: int, cruise: float, color: Color = Color.TRANSPARENT) -> Vehicle:
	var v := Vehicle.new()
	add_child(v)
	v.setup(self, model_id, dir, cruise, color)
	vehicles.append(v)
	return v


## Set while a save is being loaded: waiting guests must not call new buses.
var restoring := false


func _process(delta: float) -> void:
	vehicles = vehicles.filter(func(x): return is_instance_valid(x))
	_ambient_t -= delta
	if _ambient_t <= 0.0:
		_ambient_t = _rng.randf_range(5.0, 12.0)
		var dir := 1 if _rng.randf() < 0.5 else -1
		if _lane_clear(dir):
			spawn(CARS[_rng.randi() % CARS.size()], dir, _rng.randf_range(8.5, 12.0), CAR_COLORS[_rng.randi() % CAR_COLORS.size()])
	# the city bus comes for whoever waits at the stop
	_waiting = _waiting.filter(func(g): return is_instance_valid(g) and g.state == Guest.S.WAIT_BUS)
	if not _waiting.is_empty() and (city_bus == null or not is_instance_valid(city_bus)):
		if _bus_t < 0.0:
			_bus_t = _rng.randf_range(6.0, 14.0)
		_bus_t -= delta
		if _bus_t <= 0.0 and _lane_clear(1):
			_bus_t = -1.0
			city_bus = spawn("bus_city", 1, 9.0)
			city_bus.role = "city"
			city_bus.stop_at(BUS_DOOR_X - city_bus.door_offset(), _city_bus_arrived)


func _lane_clear(dir: int) -> bool:
	for v in vehicles:
		if is_instance_valid(v) and v.dir == dir and absf(v.position.x - (-SPAWN_X * dir)) < 14.0:
			return false
	return true


# ----------------------------------------------------------------- arrivals --
## A car brings `kinds` (1-4 visitors) and drops them at the kerb in front of
## the museum. `make` is called as make(kind, position) for each of them.
func drop_off(kinds: Array, make: Callable) -> void:
	var model: String = "car_van" if kinds.size() >= 3 else CARS[_rng.randi() % CARS.size()]
	var car := spawn(model, 1, _rng.randf_range(9.0, 11.0), CAR_COLORS[_rng.randi() % CAR_COLORS.size()])
	car.role = "drop"
	car.extra = {"kinds": kinds}
	car.make = make
	car.stop_at(_rng.randf_range(-5.0, 4.0), _dropped.bind(car))


func _dropped(car: Vehicle) -> void:
	var kinds: Array = car.extra.get("kinds", [])
	for i in range(kinds.size()):
		var p := Vector3(car.position.x - 0.6 + i * 0.7, 0, -29.7)
		if car.make.is_valid():
			car.make.call(kinds[i], p)
	car.extra["kinds"] = []
	Audio.sfx("pickup", 0.6, -14.0)
	car.resume_after(1.4)


## The yellow school bus brings a class: the teacher steps out first and the
## students follow in a line, then the bus drives off (it would block the road)
## and comes back to collect them when the class heads home.
func school_trip(count: int, make: Callable) -> void:
	_trip_total = count + 1
	_trip_waiting.clear()
	school_bus = spawn("bus_school", 1, 8.5)
	school_bus.role = "school_drop"
	school_bus.extra = {"left": count, "teacher": false}
	school_bus.make = make
	school_bus.stop_at(0.2 - school_bus.door_offset(), _school_unload.bind(school_bus, null))


## The class steps off one by one (also resumes half-way after loading a save).
func _school_unload(bus: Vehicle, teacher: Guest) -> void:
	bus.open_door(true)
	var door := bus.door_pos()
	if not bool(bus.extra.get("teacher", false)):
		teacher = bus.make.call("teacher", door, null)
		bus.extra["teacher"] = true
	while int(bus.extra.get("left", 0)) > 0:
		await get_tree().create_timer(0.45, false).timeout
		if not is_instance_valid(bus) or not is_instance_valid(teacher):
			return
		bus.make.call("student", door, teacher)
		bus.extra["left"] = int(bus.extra["left"]) - 1
	await get_tree().create_timer(1.0, false).timeout
	if is_instance_valid(bus):
		bus.role = ""
		bus.open_door(false)
		bus.resume_after(0.6)


func school_bus_door() -> Vector3:
	return school_bus.door_pos() if is_instance_valid(school_bus) else Vector3(1.0, 0, -29.8)


## The class is waiting at the kerb: send the school bus back for them.
func _call_school_bus() -> void:
	if is_instance_valid(school_bus) and school_bus.stop_x != INF:
		return
	school_bus = spawn("bus_school", 1, 8.5)
	school_bus.role = "school_pick"
	school_bus.stop_at(0.2 - school_bus.door_offset(), _school_pickup.bind(school_bus))


func _school_pickup(bus: Vehicle) -> void:
	bus.open_door(true)
	var door := bus.door_pos()
	for g in _trip_waiting:
		if is_instance_valid(g):
			g.board_bus(door)
	var t := 0.0
	while t < 16.0:
		await get_tree().create_timer(0.5, false).timeout
		t += 0.5
		var left := 0
		for g in _trip_waiting:
			if is_instance_valid(g) and (g.state == Guest.S.BOARD or g.state == Guest.S.WAIT_BUS):
				left += 1
		if left == 0 and t > 1.5:
			break
	if is_instance_valid(bus):
		bus.role = ""
		bus.open_door(false)
		bus.resume_after(0.8)
	_trip_waiting.clear()


## Day over: no more waiting.
func school_bus_leave() -> void:
	_trip_waiting.clear()
	if is_instance_valid(school_bus):
		school_bus.open_door(false)
		school_bus.parked = false
		school_bus.resume_after(1.0)


# --------------------------------------------------------------- bus stop ---
func stop_spot(g: Node) -> Vector3:
	for i in range(SEATS.size()):
		if not _seat_taken.has(i) or not is_instance_valid(_seat_taken[i]):
			_seat_taken[i] = g
			return SEATS[i]
	return Vector3(_rng.randf_range(-18.6, -14.4), 0, _rng.randf_range(-29.4, -28.7))


func is_seat(p: Vector3) -> bool:
	for s in SEATS:
		if s.distance_to(p) < 0.05:
			return true
	return false


func waiting(g: Guest) -> void:
	if not g.trip.is_empty():
		if not _trip_waiting.has(g):
			_trip_waiting.append(g)
		if is_instance_valid(school_bus) and school_bus.stopped and school_bus.stop_x != INF:
			g.board_bus(school_bus_door())
		elif not restoring:
			_call_school_bus()
		return
	if not _waiting.has(g):
		_waiting.append(g)
	if is_instance_valid(city_bus) and city_bus.stopped and not restoring:
		g.board_bus(city_bus.door_pos())


func leave_stop(g: Guest) -> void:
	_waiting.erase(g)
	for k in _seat_taken.keys():
		if _seat_taken[k] == g:
			_seat_taken.erase(k)


func _city_bus_arrived() -> void:
	city_bus.open_door(true)
	Audio.sfx("bell", 1.4, -8.0)
	var door := city_bus.door_pos()
	for g in _waiting:
		if is_instance_valid(g):
			g.board_bus(door)
	_seat_taken.clear()
	_wait_boarding()


func _wait_boarding() -> void:
	var t := 0.0
	while t < 14.0:
		await get_tree().create_timer(0.5, false).timeout
		t += 0.5
		if not is_instance_valid(city_bus):
			return
		var left := 0
		for g in _waiting:
			if is_instance_valid(g) and (g.state == Guest.S.BOARD or g.state == Guest.S.WAIT_BUS):
				left += 1
		if left == 0 and t > 1.5:
			break
	if is_instance_valid(city_bus):
		city_bus.role = ""
		city_bus.open_door(false)
		city_bus.resume_after(0.8)


## Give a restored guest back the exact bench seat (or standing spot) they had.
func take_spot(g: Node, spot: Vector3) -> void:
	for i in range(SEATS.size()):
		if SEATS[i].distance_to(spot) < 0.05:
			_seat_taken[i] = g


# -------------------------------------------------------------- save/load ---
func save_data() -> Dictionary:
	vehicles = vehicles.filter(func(x): return is_instance_valid(x) and not x.is_queued_for_deletion())
	var vs: Array = []
	for v in vehicles:
		vs.append(v.save_data())
	return {"vehicles": vs, "ambient_t": _ambient_t, "bus_t": _bus_t, "trip_total": _trip_total,
		"city": vehicles.find(city_bus), "school": vehicles.find(school_bus)}


func clear_vehicles() -> void:
	for v in vehicles:
		if is_instance_valid(v):
			v.free()
	vehicles.clear()
	city_bus = null
	school_bus = null
	_waiting.clear()
	_seat_taken.clear()
	_trip_waiting.clear()


## Rebuild every car and bus exactly where it was, doing what it was doing.
func restore_vehicles(d: Dictionary) -> void:
	_ambient_t = float(d.get("ambient_t", _ambient_t))
	_bus_t = float(d.get("bus_t", -1.0))
	_trip_total = int(d.get("trip_total", _trip_total))
	var dc: DayCycle = World.instance.day_cycle
	var made: Array = []
	for vd in d.get("vehicles", []):
		var col := Color.TRANSPARENT if String(vd.get("color", "")) == "" else Color.html(String(vd["color"]))
		var v := spawn(String(vd["model"]), int(vd["dir"]), float(vd["cruise"]), col)
		v.load_data(vd)
		made.append(v)
	var ci := int(d.get("city", -1))
	city_bus = made[ci] if ci >= 0 and ci < made.size() else null
	var si := int(d.get("school", -1))
	school_bus = made[si] if si >= 0 and si < made.size() else null
	for v in made:
		match v.role:
			"drop":
				v.make = dc._car_make
				if not v.stopped:
					v.stop_at(v.stop_x, _dropped.bind(v))
				elif not (v.extra.get("kinds", []) as Array).is_empty():
					_dropped(v)
			"city":
				if not v.stopped:
					v.stop_at(v.stop_x, _city_bus_arrived)
				else:
					_city_bus_arrived()
			"school_drop":
				v.make = dc.tour.make_member if dc.tour else Callable()
				var teacher: Guest = dc.tour.teacher if dc.tour and is_instance_valid(dc.tour.teacher) else null
				if not v.make.is_valid():
					v.role = ""
					v.resume_after(0.5)
				elif not v.stopped:
					v.stop_at(v.stop_x, _school_unload.bind(v, teacher))
				else:
					_school_unload(v, teacher)
			"school_pick":
				if not v.stopped:
					v.stop_at(v.stop_x, _school_pickup.bind(v))
				else:
					_school_pickup(v)
	# the class was waiting at the kerb and no bus was on its way yet
	if not _trip_waiting.is_empty() and not (is_instance_valid(school_bus) and school_bus.role == "school_pick"):
		_call_school_bus()


# ------------------------------------------------------------------ hits ----
## Anyone on the road in front of a moving vehicle is knocked flying.
func _check_hits(v: Vehicle) -> void:
	if v.speed < 1.5:
		return
	var w := World.instance
	if w == null:
		return
	var targets: Array = w.actors()
	if w.player:
		targets.append(w.player)
	for a in targets:
		if not is_instance_valid(a):
			continue
		var p: Vector3 = (a as Node3D).global_position
		if p.y > 1.2:
			continue
		var dx := (p.x - v.position.x) * v.dir
		var dz := absf(p.z - v.position.z)
		if dz < v.half_w + 0.35 and dx > -v.half_l and dx < v.half_l + 0.45:
			if a is Player:
				if a.ragdolled or a.locked:
					continue
				a.knockback(Vector3(v.dir * v.speed * 0.85, 4.2, (p.z - v.position.z) * 2.0))
			elif a.has_method("knockback"):
				if a is Guest and (a.state == Guest.S.KNOCKED or a.state == Guest.S.BOARD):
					continue
				a.knockback(Vector3(v.dir * v.speed * 0.85, 4.0, (p.z - v.position.z) * 2.0), false)
				Events.radio("A visitor got hit by a car outside!", "threat", p)
			Audio.sfx("bonk", 0.7)
			FX.burst(get_parent(), p + Vector3(0, 0.8, 0), "dust", 1.2)


# ================================================================= vehicle ===
class Vehicle extends Node3D:
	var traffic: Traffic
	var model: Node3D
	var wheels: Array = []
	var door: Node3D
	var _door_rest := Vector3.ZERO
	var dir := 1
	var speed := 0.0
	var cruise := 10.0
	var half_l := 2.0
	var half_w := 0.9
	var stop_x := INF
	var stopped := false
	var parked := false
	var _on_stop: Callable
	var _honk_t := 0.0
	var _resume_t := -1.0
	var wheel_r := 0.35
	var model_id := ""
	var color := Color.TRANSPARENT
	## What it is doing: "" (just driving), "drop" (bringing visitors), "city"
	## (city bus collecting the stop), "school_drop" / "school_pick".
	var role := ""
	var extra := {}
	var make: Callable
	var door_open := false

	func setup(t: Traffic, model_id_: String, d: int, c: float, color_: Color) -> void:
		traffic = t
		dir = d
		cruise = c
		speed = c
		model_id = model_id_
		color = color_
		model = Art.model(model_id_)
		Art.strip_collision(model)
		add_child(model)
		var b := Art.local_aabb(model)
		half_l = b.size.x * 0.5
		half_w = b.size.z * 0.5
		for n in ["Wheel_FL", "Wheel_FR", "Wheel_RL", "Wheel_RR"]:
			var wn := model.find_child(n, true, false)
			if wn:
				wheels.append(wn)
		if not wheels.is_empty():
			wheel_r = maxf(0.2, (wheels[0] as Node3D).position.y)
		door = model.find_child("Door", true, false) as Node3D
		if door:
			_door_rest = door.position
		if color_ != Color.TRANSPARENT:
			Art.tint(model, "CarPaint", color_)
		position = Vector3(-Traffic.SPAWN_X * dir, 0.0, Traffic.EAST_Z if dir > 0 else Traffic.WEST_Z)
		rotation.y = 0.0 if dir > 0 else PI
		for mi in Art.meshes(model):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

	## Distance from the vehicle centre to its passenger door along its length.
	func door_offset() -> float:
		return (door.position.x - 0.55) if door else half_l * 0.7

	func door_pos() -> Vector3:
		var off := door_offset()
		return Vector3(position.x + off * dir, 0, position.z + (half_w + 0.5) * dir)

	func stop_at(x: float, cb: Callable) -> void:
		stop_x = x
		_on_stop = cb

	func resume_after(t: float) -> void:
		_resume_t = t

	func save_data() -> Dictionary:
		var wr: Array = []
		for w in wheels:
			wr.append((w as Node3D).rotation.z)
		return {"model": model_id, "color": color.to_html() if color != Color.TRANSPARENT else "", "dir": dir,
			"cruise": cruise, "speed": speed, "x": position.x, "z": position.z, "stop_x": stop_x if stop_x != INF else null,
			"stopped": stopped, "parked": parked, "resume_t": _resume_t, "honk_t": _honk_t, "role": role,
			"extra": extra, "door": door_open, "wheels": wr}

	func load_data(d: Dictionary) -> void:
		position = Vector3(float(d.get("x", position.x)), 0.0, float(d.get("z", position.z)))
		speed = float(d.get("speed", cruise))
		stop_x = INF if d.get("stop_x") == null else float(d["stop_x"])
		stopped = bool(d.get("stopped", false))
		parked = bool(d.get("parked", false))
		_resume_t = float(d.get("resume_t", -1.0))
		_honk_t = float(d.get("honk_t", 0.0))
		role = String(d.get("role", ""))
		extra = d.get("extra", {})
		var wr: Array = d.get("wheels", [])
		for i in range(mini(wr.size(), wheels.size())):
			(wheels[i] as Node3D).rotation.z = float(wr[i])
		door_open = bool(d.get("door", false))
		if door:
			door.position = _door_rest + (Vector3(-1.1, 0, 0) if door_open else Vector3.ZERO)

	func open_door(on: bool) -> void:
		door_open = on
		if door == null:
			return
		var tw := create_tween()
		tw.tween_property(door, "position", _door_rest + (Vector3(-1.1, 0, 0) if on else Vector3.ZERO), 0.6).set_trans(Tween.TRANS_SINE)

	func _process(delta: float) -> void:
		if _resume_t >= 0.0:
			_resume_t -= delta
			if _resume_t < 0.0:
				stopped = false
				stop_x = INF
		var want := cruise
		if parked or (stopped and _resume_t >= 0.0):
			want = 0.0
		elif stop_x != INF:
			var dist := (stop_x - position.x) * dir
			if dist <= 0.05:
				want = 0.0
				if not stopped and speed < 0.3:
					stopped = true
					speed = 0.0
					if _on_stop.is_valid():
						_on_stop.call()
			else:
				want = minf(cruise, sqrt(2.0 * 7.0 * dist))
		# keep a gap behind the vehicle in front (queues behind a stopped bus)
		for o in traffic.vehicles:
			if o == self or not is_instance_valid(o) or o.dir != dir:
				continue
			var gap: float = (o.position.x - position.x) * dir - (o.half_l + half_l)
			if gap > -0.5 and gap < 14.0:
				want = minf(want, maxf(0.0, (gap - 2.5) * 1.6))
		var acc := 5.0 if want > speed else 10.0
		speed = move_toward(speed, want, acc * delta)
		position.x += dir * speed * delta
		for w in wheels:
			(w as Node3D).rotation.z -= speed * delta / wheel_r
		traffic._check_hits(self)
		_honk(delta)
		if absf(position.x) > Traffic.SPAWN_X + 2.0 and (position.x * dir) > 0.0:
			queue_free()

	func _honk(delta: float) -> void:
		_honk_t -= delta
		var p := World.instance.player if World.instance else null
		if p == null or _honk_t > 0.0 or speed < 3.0:
			return
		var dx := (p.global_position.x - position.x) * dir
		if dx > half_l and dx < half_l + 12.0 and absf(p.global_position.z - position.z) < half_w + 0.8:
			_honk_t = 2.5
			Audio.sfx("alert", 0.55, -2.0)
