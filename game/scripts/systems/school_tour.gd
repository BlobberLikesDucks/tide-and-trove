class_name SchoolTour
extends Node
## A booked school trip (from J-Mail). The yellow school bus drops off a teacher
## and a line of students. Talk to the teacher (Interact) to start the guided
## tour: the class follows you, and at each exhibit or attraction you press
## Interact and choose what to tell them. Tell them something WRONG and the
## class turns on you - expect a very negative reaction and review. Some
## students may throw tantrums along the way.

const STOPS_NEEDED := 3

var cycle: DayCycle
var ev: Dictionary
var teacher: Guest
var students: Array = []
var active := false
var done := false
var presented := {}
var right := 0
var wrong := 0
var _leave_t := -1.0

## False "facts" to pick from when the player describes an attraction.
const MYTHS := {
	"touch_table": ["Casts are real fossils, so touching them damages history.", "Fossil casts are made of real dinosaur bone powder."],
	"microscope_station": ["Microfossils are just grains of sand with no living origin.", "You need a telescope, not a microscope, to see microfossils."],
	"photo_booth": ["T. rex could outrun a car at 70 km/h.", "T. rex lived at the same time as the first humans."],
	"volcano_diorama": ["Volcanoes alone wiped out every animal on Earth 66 million years ago.", "Dinosaurs lived inside volcanoes to keep warm."],
	"dino_slide": ["Sauropods were the smallest dinosaurs.", "Sauropods could fly short distances with their long necks."],
	"time_tunnel": ["The top rock layers are always the oldest ones.", "All rock layers formed in the same year."],
	"fern_garden": ["Ferns only appeared after the dinosaurs died out.", "Dinosaurs never ate any plants."],
	"ammonite_fountain": ["Ammonites are a kind of snail that lived on land.", "Ammonites are still common in today's oceans."],
	"bookshelf": ["Mary Anning was a famous king of England.", "The first ichthyosaur was found on the Moon."],
	"aquarium": ["Horseshoe crabs are true crabs that appeared last century.", "The nautilus is a kind of fish."],
	"holo_theater": ["Holograms are made from real ghost dinosaurs.", "Dinosaurs and woolly mammoths lived side by side."],
	"dig_pit": ["Fossils are always found already cleaned and shiny.", "Only adults are allowed to touch real fossils, ever."],
	"water_fountain": ["Dinosaurs drank seawater only."],
}
const TRUTHS := {
	"aquarium": "Horseshoe crabs belong to a family of animals around 450 million years old - true living fossils.",
	"holo_theater": "Scientists rebuild extinct animals from their bones, comparing them with living relatives.",
	"dig_pit": "Real fossils have to be dug out slowly and cleaned carefully in a lab.",
}


func setup(c: DayCycle, e: Dictionary) -> void:
	cycle = c
	ev = e


func save_data(all: Array) -> Dictionary:
	var pres: Array = []
	for o in cycle.museum.all_objects():
		if presented.has(o.get_instance_id()):
			pres.append([o.cell.x, o.cell.y])
	var st: Array = []
	for g in students:
		st.append(all.find(g))
	return {"ev": ev, "teacher": all.find(teacher), "students": st, "active": active, "done": done,
		"presented": pres, "right": right, "wrong": wrong, "leave_t": _leave_t}


## Rebuild the tour from a save (members are already spawned in `all`).
func load_data(d: Dictionary, c: DayCycle, all: Array) -> void:
	setup(c, d.get("ev", {}))
	active = bool(d.get("active", false))
	done = bool(d.get("done", false))
	right = int(d.get("right", 0))
	wrong = int(d.get("wrong", 0))
	_leave_t = float(d.get("leave_t", -1.0))
	for cell in d.get("presented", []):
		for o in cycle.museum.all_objects():
			if o.cell == Vector2i(int(cell[0]), int(cell[1])):
				presented[o.get_instance_id()] = true
	var ti := int(d.get("teacher", -1))
	if ti >= 0 and ti < all.size():
		teacher = all[ti]
		teacher.trip = ev
		if active and not done:
			teacher.follow_node = World.instance.player
	for si in d.get("students", []):
		var i := int(si)
		if i >= 0 and i < all.size():
			var g: Guest = all[i]
			g.trip = ev
			g.follow_node = teacher
			students.append(g)
	if cycle.world.traffic:
		cycle.world.traffic._trip_total = students.size() + (1 if teacher else 0)


## Called by Traffic as each person steps off the bus.
func make_member(kind: String, pos: Vector3, leader: Variant) -> Guest:
	var g := cycle.spawn_guest(kind, pos)
	g.trip = ev
	if kind == "teacher":
		teacher = g
		g.gname = String(ev.get("teacher", "The teacher"))
		g.visits_left = 999
		g.weight = 3.0
		var pay := int(ev.get("pay", 200))
		GameState.earn(pay, "School trips")
		Events.radio("The class from %s has arrived! Talk to %s to start the tour." % [ev.get("school", "school"), g.gname], "vip", g.global_position)
		Events.say("School trip fee received: %s" % UIKit.money_text(pay), UIKit.GOLD)
	else:
		g.follow_node = leader if leader is Node3D else teacher
		g.weight = 0.5
		students.append(g)
		g.state = Guest.S.FOLLOW
	return g


func _process(delta: float) -> void:
	if _leave_t >= 0.0:
		_leave_t -= delta
		if _leave_t < 0.0:
			_send_home()


## Interact with the teacher.
func teacher_talk() -> void:
	var nm := teacher.gname if is_instance_valid(teacher) else "The teacher"
	if done:
		Events.dialog_requested.emit([{"name": nm, "text": "Thank you so much! The children loved it. We'll head back to the bus soon."}])
		return
	if active:
		Events.dialog_requested.emit([{"name": nm, "text": "We're right behind you! %d of %d stops so far. Press %s at an exhibit or attraction to tell us about it." % [presented.size(), STOPS_NEEDED, Settings.prompt("interact")]}])
		return
	active = true
	teacher.follow_node = World.instance.player
	teacher.state = Guest.S.FOLLOW
	teacher.inside = true
	Events.dialog_requested.emit([
		{"name": nm, "text": "Hello! We're the class from %s. The children have been SO excited about your museum." % ev.get("school", "school")},
		{"name": nm, "text": "Please lead the way: show us %d different exhibits or attractions. At each one press %s and tell the class about it." % [STOPS_NEEDED, Settings.prompt("interact")]},
		{"name": "Tip", "text": "Only say what you know is true - check the Field Guide (%s) first. A wrong fact in front of a whole class goes down VERY badly." % Settings.prompt("field_guide")},
	])
	Audio.sfx("cheer", 1.2, -6.0)


## Interact with an exhibit while leading the tour: choose what to tell them.
func present(o: PlacedObject) -> bool:
	if not active or done:
		return false
	var key := o.get_instance_id()
	if presented.has(key):
		Events.say("You already told the class about this one - show them something else.", UIKit.CORAL)
		return true
	if is_instance_valid(teacher) and teacher.global_position.distance_to(o.global_position) > 9.0:
		Events.say("Wait for the class to catch up!", UIKit.CORAL)
		return true
	var q := _question(o)
	if q.is_empty():
		Events.say("There's not much to say about that. Show them an exhibit or attraction.", UIKit.CORAL)
		return true
	q["obj"] = key
	Events.open_panel.emit("tour", q)
	return true


func _question(o: PlacedObject) -> Dictionary:
	var sp: String = o.species_shown()
	var opts: Array = []
	var correct := ""
	if sp != "":
		var sd: Dictionary = DB.SPECIES[sp]
		var nm: String = String(sd["name"]).split(" (")[0]
		var kinds := ["era", "diet", "habitat"]
		kinds.shuffle()
		var k: String = kinds[0]
		var pool: Array = {"era": DB.ERAS, "diet": DB.DIETS, "habitat": DB.HABITATS}[k]
		var phrase: String = {"era": "This %s lived in the %s era.", "diet": "The %s's diet: %s.", "habitat": "The %s lived in this habitat: %s."}[k]
		correct = phrase % [nm, sd[k]]
		opts.append(correct)
		var wrongs: Array = pool.filter(func(x): return x != sd[k])
		wrongs.shuffle()
		for w in wrongs.slice(0, 2):
			opts.append(phrase % [nm, w])
	else:
		var t: String = o.type
		if not MYTHS.has(t):
			return {}
		correct = String(PlacedObject.INFO.get(t, TRUTHS.get(t, "")))
		if correct == "":
			return {}
		opts.append(correct)
		var m: Array = (MYTHS[t] as Array).duplicate()
		m.shuffle()
		for w in m.slice(0, 2):
			opts.append(w)
	opts.shuffle()
	return {"what": o.def["name"] if sp == "" else DB.SPECIES[sp]["name"], "options": opts, "answer": correct, "teacher": teacher.gname if is_instance_valid(teacher) else "Teacher"}


## The player's choice from the tour panel.
func answer(obj_id: int, ok: bool) -> void:
	presented[obj_id] = true
	if ok:
		right += 1
		Audio.sfx("cheer")
		Events.say("The class is fascinated! (%d/%d stops)" % [presented.size(), STOPS_NEEDED], UIKit.GOOD)
	else:
		wrong += 1
		Audio.sfx("error")
		Events.say("WRONG! The class groans and the teacher is horrified... (%d/%d stops)" % [presented.size(), STOPS_NEEDED], UIKit.BAD)
		GameState.quality = maxf(0.0, GameState.quality - 6.0)
		if is_instance_valid(teacher):
			teacher.mood = maxf(0.0, teacher.mood - 45.0)
			teacher.visual.set_bubble("!!!", UIKit.BAD)
	for s in students:
		if is_instance_valid(s):
			s.tour_react(ok)
	if presented.size() >= STOPS_NEEDED:
		_finish_tour()


func _finish_tour() -> void:
	done = true
	active = false
	var nm := teacher.gname if is_instance_valid(teacher) else "The teacher"
	var text := ""
	if wrong == 0:
		var bonus := 60 + 20 * GameState.star_count()
		GameState.earn(bonus, "School trips")
		text = "What a wonderful tour - every fact spot on! Here's a little extra for the museum fund (%s)." % UIKit.money_text(bonus)
		GameState.quality = minf(99.0, GameState.quality + 5.0)
	elif wrong >= 2:
		text = "I'm sorry, but you taught my class things that simply aren't true. I'll be writing to the school about this."
	else:
		text = "Thank you... although one of those 'facts' was wrong. We'll double-check it back at school."
	Events.dialog_requested.emit([{"name": nm, "text": text}])
	if is_instance_valid(teacher):
		teacher.follow_node = null
		teacher.state = Guest.S.DECIDE
	_leave_t = 20.0


func _send_home() -> void:
	if is_instance_valid(teacher) and teacher.state != Guest.S.LEAVE and teacher.state != Guest.S.WAIT_BUS:
		teacher.follow_node = null
		teacher._leave()


## Museum closing: everybody back on the bus.
func finish_day() -> void:
	active = false
	_leave_t = -1.0
	_send_home()


## The teacher's review counts a lot (weight 3 - 4).
func teacher_review(g: Guest) -> Dictionary:
	var stars := 5
	var key := "tour"
	var text := ""
	if not done and presented.is_empty():
		stars = 2
		key = "boring"
		text = "We waited by the door but nobody gave our class the tour we booked."
	elif wrong > 0:
		stars = 1
		key = "bad_tour"
		var arr: Array = DB.REVIEW_BAD["bad_tour"]
		text = arr[randi() % arr.size()]
	elif presented.size() < STOPS_NEEDED:
		stars = 3
		text = "A nice tour, but it ended rather quickly."
	else:
		var arr2: Array = DB.REVIEW_GOOD["tour"]
		text = arr2[randi() % arr2.size()]
	return {"name": "%s (%s)" % [g.gname, ev.get("school", "school")], "kind": "teacher", "stars": stars, "text": text, "weight": 4.0 if wrong > 0 else 3.0, "key": key}
