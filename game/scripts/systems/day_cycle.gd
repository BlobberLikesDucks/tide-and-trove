class_name DayCycle
extends Node
## Daily state machine:  PREP (time paused) -> OPEN (time flows, guests arrive
## by car) -> REVIEWS (reviews move Quality; Upgrade Points are EARNED here, from
## visitors and the new species they saw) -> LEDGER (wages, upkeep, bankruptcy
## check) -> next day PREP.

const OPEN_H := 9.0
const CLOSE_H := 18.0
const LAST_ENTRY := 16.6
const MAX_GUESTS := 28

var world: Node
var museum: Museum
var clock := OPEN_H
var guests: Array = []
var staff_nodes: Array = []
var reviews: Array = []
var visitors_today := 0
var closing := false
var _close_wait := 0.0
var _spawn_acc := 0.0
var _hour := 9
var _scheduled: Array = []
var commendations := 0
var publicity := 0
var summary := {}
var tour: SchoolTour
var _pending: Array = []
var _car_t := 0.0
## The ledger panel's data (kept so a save during the ledger can show it again).
var ledger_data := {}


func setup(w: Node, m: Museum) -> void:
	world = w
	museum = m
	spawn_staff()


func is_open() -> bool:
	return GameState.phase == GameState.Phase.OPEN

# ------------------------------------------------------------------ staff ---
func spawn_staff() -> void:
	for s in staff_nodes:
		if is_instance_valid(s):
			s.queue_free()
	staff_nodes.clear()
	for d in GameState.staff:
		var s := Staff.new()
		world.add_child(s)
		s.setup(d, museum, self)
		staff_nodes.append(s)


func has_staff(t: String) -> bool:
	for d in GameState.staff:
		if d["type"] == t:
			return true
	return false


func hire(t: String) -> bool:
	if GameState.staff.size() >= GameState.staff_cap() or not GameState.job_unlocked(t):
		return false
	var used := {}
	for d in GameState.staff:
		used[d["name"]] = true
	var nm: String = DB.STAFF_NAMES[randi() % DB.STAFF_NAMES.size()]
	for n in DB.STAFF_NAMES:
		if not used.has(n):
			nm = n
			if randf() < 0.5:
				break
	var d := {"type": t, "name": nm, "temper": randf_range(0.15, 0.85), "morale": 72.0, "bonus": 0, "praised": 0}
	GameState.staff.append(d)
	var s := Staff.new()
	world.add_child(s)
	s.setup(d, museum, self)
	staff_nodes.append(s)
	GameState.changed.emit()
	return true


func fire(s: Staff) -> void:
	remove_staff(s)
	Events.say("%s has been let go." % s.data["name"], UIKit.CORAL)
	s.queue_free()


func remove_staff(s: Staff) -> void:
	GameState.staff.erase(s.data)
	staff_nodes.erase(s)
	GameState.changed.emit()


func staff_morale_all(amount: float, reason: String) -> void:
	for s in staff_nodes.duplicate():
		if is_instance_valid(s):
			s.change_morale(amount, reason)


func autofill_plaques() -> void:
	if not has_staff("intern"):
		return
	var n := 0
	for o in museum.cases():
		var f: Dictionary = o.fossil_entry()
		if f.is_empty() or o.accurate_plaque():
			continue
		var sd: Dictionary = DB.SPECIES[GameState.species_of(f["f"])]
		o.data["plaque"] = {"era": sd["era"], "diet": sd["diet"], "habitat": sd["habitat"]}
		o.refresh_display()
		n += 1
	if n > 0:
		Events.say("Your intern updated %d plaque(s) with accurate tags." % n, UIKit.GOOD)

# ------------------------------------------------------------------- open ---
func open_museum() -> void:
	if GameState.phase != GameState.Phase.PREP:
		return
	GameState.phase = GameState.Phase.OPEN
	clock = OPEN_H
	_hour = 9
	closing = false
	reviews.clear()
	visitors_today = 0
	commendations = 0
	publicity = 0
	_pending.clear()
	_spawn_acc = 0.6
	_schedule_events()
	museum.set_sign_open(true)
	museum.compute_pillars()
	autofill_plaques()
	for s in staff_nodes:
		if is_instance_valid(s):
			s.go_post()
	Audio.play_music("open")
	Audio.sfx("bell")
	Events.say("The museum is OPEN! Ticket price: %s" % UIKit.money_text(GameState.ticket_price()), UIKit.GOLD)
	Events.phase_changed.emit(GameState.phase)
	GameState.changed.emit()


func _schedule_events() -> void:
	_scheduled.clear()
	var h := GameState.half_stars
	if h >= 4 and randf() < 0.4:
		_scheduled.append({"t": randf_range(10.0, 14.5), "what": "critic"})
	if h >= 3 and randf() < 0.3:
		_scheduled.append({"t": randf_range(10.5, 15.0), "what": "celebrity"})
	if h >= 1 and randf() < 0.3:
		_scheduled.append({"t": randf_range(9.5, 12.5), "what": "trip"})
	if int(GameState.flags.get("act", 1)) >= 3:
		for i in range(randi_range(1, 2)):
			_scheduled.append({"t": randf_range(10.0, 16.0), "what": "spy"})
	# booked over J-Mail: school trips arrive mid-morning on their day
	for ev in GameState.events.duplicate():
		if int(ev.get("day", 0)) < GameState.day:
			GameState.events.erase(ev)  # missed (the museum stayed closed that day)
			continue
		if int(ev.get("day", 0)) != GameState.day:
			continue
		match String(ev.get("what", "")):
			"school_trip":
				_scheduled.append({"t": randf_range(9.6, 10.6), "what": "school_trip", "ev": ev})
			"celebrity", "critic":
				GameState.events.erase(ev)
				_scheduled.append({"t": randf_range(10.5, 13.5), "what": ev["what"]})


func _process(delta: float) -> void:
	if GameState.phase != GameState.Phase.OPEN:
		return
	GameState.playtime += delta
	var rate := (CLOSE_H - OPEN_H) / (maxf(1.0, float(Settings.get_v("day_len"))) * 60.0)
	var dh := delta * rate
	clock += dh
	Events.clock_changed.emit(clock)
	if int(clock) > _hour:
		_hour = int(clock)
		_hourly()
	for e in _scheduled.duplicate():
		if clock >= float(e["t"]):
			_scheduled.erase(e)
			if e["what"] == "school_trip":
				_start_school_trip(e["ev"])
			else:
				_trigger(e["what"])
	if clock < LAST_ENTRY and not closing:
		var per_hour := (2.6 + float(GameState.pillars["fun_points"]) * 0.12 + GameState.half_stars * 1.3) * (0.35 + 0.65 * GameState.reputation())
		if GameState.has_skill("press_kit"):
			per_hour *= 1.25
		if GameState.has_skill("ticket_5"):
			per_hour *= 1.1
		_spawn_acc += per_hour * dh
		while _spawn_acc >= 1.0:
			_spawn_acc -= 1.0
			if _count_inside() + _pending.size() < MAX_GUESTS:
				_pending.append(_roll_kind())
	# visitors come by car: one car every couple of seconds carries 1-3 of them
	_car_t -= delta
	if not _pending.is_empty() and _car_t <= 0.0:
		_car_t = randf_range(1.5, 3.0)
		var n := mini(_pending.size(), randi_range(1, 3))
		var group: Array = _pending.slice(0, n)
		_pending = _pending.slice(n)
		arrive_by_car(group)
	if clock >= CLOSE_H and not closing:
		_begin_closing()
	if closing:
		_close_wait += delta
		_prune()
		if guests.is_empty() or _close_wait > 40.0:
			_finish_day()


## Bring visitors in a car (falls back to walking in if there is no traffic).
func arrive_by_car(kinds: Array) -> void:
	if world.traffic == null:
		for k in kinds:
			spawn_guest(k)
		return
	world.traffic.drop_off(kinds, _car_make)


## A visitor steps out of a car at the kerb.
func _car_make(kind: String, p: Vector3) -> Guest:
	if GameState.phase != GameState.Phase.OPEN:
		return null
	return spawn_guest(kind, p)


## A class booked over J-Mail arrives in the yellow school bus.
func _start_school_trip(ev: Dictionary) -> void:
	GameState.events.erase(ev)
	tour = SchoolTour.new()
	world.add_child(tour)
	tour.setup(self, ev)
	if world.traffic:
		world.traffic.school_trip(int(ev.get("kids", 8)), tour.make_member)
	else:
		var t: Guest = tour.make_member("teacher", Vector3(0, 0, -29.5), null)
		for i in range(int(ev.get("kids", 8))):
			tour.make_member("student", Vector3(randf_range(-2, 2), 0, -29.5), t)


func _count_inside() -> int:
	_prune()
	return guests.size()


func _prune() -> void:
	var keep: Array = []
	for g in guests:
		if is_instance_valid(g) and not g.is_queued_for_deletion():
			keep.append(g)
	guests = keep


func _roll_kind() -> String:
	var h := GameState.half_stars
	var opts := [["tourist", 10.0]]
	if h >= 1:
		opts.append(["kid", 3.5])
	if h >= 2:
		opts.append(["nerd", 2.5])
	if h >= 5:
		opts.append(["shoplifter", 0.9])
	var total := 0.0
	for o in opts:
		total += o[1]
	var r := randf() * total
	for o in opts:
		r -= o[1]
		if r <= 0.0:
			return o[0]
	return "tourist"


func spawn_guest(kind: String, at: Vector3 = Vector3.INF) -> Guest:
	var g := Guest.new()
	world.add_child(g)
	var spawn := at if at != Vector3.INF else Vector3(randf_range(-22.0, -12.0), 0, randf_range(-29.5, -27.5))
	g.setup(kind, museum, self, spawn)
	guests.append(g)
	return g


func spawn_fans(celeb: Guest) -> void:
	for i in range(randi_range(4, 6)):
		var f := spawn_guest("fan", celeb.global_position + Vector3(randf_range(-3, 3), 0, -randf_range(3, 7)))
		f.leader = celeb
	Audio.sfx("cheer", 1.0, -4.0)


func _trigger(what: String) -> void:
	match what:
		"critic", "celebrity", "spy":
			arrive_by_car([what])


func _hourly() -> void:
	var mult := 0.5 if GameState.has_skill("staff_training") else 1.0
	for s in staff_nodes.duplicate():
		if not is_instance_valid(s) or s.state == "leaving":
			continue
		s.change_morale(-1.0 * mult, "burnt out")
		if s.state == "leaving":
			continue
		var low: float = 1.6 - float(s.morale()) / 100.0
		if not s.rogue and randf() < 0.04 * float(s.data.get("temper", 0.5)) * mult * low:
			s.go_rogue()
			s.change_morale(-5.0, "burnt out")


func _begin_closing() -> void:
	closing = true
	_close_wait = 0.0
	Events.radio("Sunset! The museum is closing - guests are heading out.", "info", Vector3.ZERO)
	Audio.play_music("closing")
	museum.set_sign_open(false)
	_pending.clear()
	if tour:
		tour.finish_day()
	for g in guests:
		if is_instance_valid(g) and g.state != Guest.S.LEAVE and g.state != Guest.S.KNOCKED and g.state != Guest.S.WAIT_BUS and g.state != Guest.S.BOARD:
			if g.state == Guest.S.CLIMB:
				g.get_down()
			g._leave()


func guest_left(g: Guest) -> void:
	guests.erase(g)
	if g.no_review or g.kind == "spy":
		return
	if not g.inside and g.state == Guest.S.ARRIVE:
		return
	var r := g.make_review()
	reviews.append(r)
	if g.kind == "critic" and int(r["stars"]) >= 4:
		commendations += 2
		Events.say("The critic was impressed! +2 Upgrade Points (Commendation)", UIKit.GOLD)
	if g.kind == "celebrity" and int(r["stars"]) >= 4:
		var bonus := 30 * int(r["stars"])
		GameState.earn(bonus, "Publicity")
		GameState.quality = minf(99.0, GameState.quality + 3.0)
		publicity += bonus
		Events.say("%s posted about your museum! +%s publicity" % [g.gname, UIKit.money_text(bonus)], UIKit.GOLD)



# ---------------------------------------------------------------- closing ---
func _finish_day() -> void:
	for g in guests.duplicate():
		if is_instance_valid(g):
			if world.traffic:
				world.traffic.leave_stop(g)
			guest_left(g)
			g.queue_free()
	guests.clear()
	if tour and is_instance_valid(tour):
		tour.queue_free()
	tour = null
	if world.traffic:
		world.traffic.school_bus_leave()
	GameState.phase = GameState.Phase.REVIEWS
	Events.phase_changed.emit(GameState.phase)
	for s in staff_nodes:
		if is_instance_valid(s):
			s.go_post()
	summary = _review_summary()
	GameState.last_reviews = summary["shown"]
	Events.open_panel.emit("reviews", summary)


func _review_summary() -> Dictionary:
	var wsum := 0.0
	var ssum := 0.0
	for r in reviews:
		wsum += float(r["weight"])
		ssum += float(r["stars"]) * float(r["weight"])
	var avg := ssum / wsum if wsum > 0.0 else 0.0
	var n := reviews.size()
	var old_q := GameState.quality
	var old_h := GameState.half_stars
	var delta := 0.0
	if n > 0:
		# early days are generous: even a small, decent museum climbs toward its first star
		var tier := 1.0 / (1.0 + 0.12 * GameState.half_stars)
		delta = (avg - 2.2) * 30.0 * tier * minf(1.0, n / 3.0) + minf(8.0, visitors_today * 0.5)
		if GameState.has_skill("membership"):
			delta += 4.0
	else:
		delta = -2.0
	# Upgrade Points come from OPENING: visitors, good reviews and new species they saw
	var up_gain := commendations
	var up_visitors := visitors_today / 5 + (1 if visitors_today > 0 else 0)
	up_gain += up_visitors
	var five_star := n >= 4 and avg >= 4.5
	if five_star:
		up_gain += 2
	elif n >= 3 and avg >= 3.5:
		up_gain += 1
	var seen: Array = []
	for sp in GameState.discovered.keys():
		var dd: Dictionary = GameState.discovered[sp]
		if dd.get("seen", false) and not dd.get("claimed", false):
			var pts := GameState.discovery_points(sp)
			dd["claimed"] = true
			up_gain += pts
			seen.append(DB.SPECIES[sp]["name"])
	GameState.quality = maxf(0.0, GameState.quality + delta)
	var gained := 0
	while GameState.quality >= 100.0 and GameState.half_stars < 10:
		GameState.half_stars += 1
		gained += 1
		up_gain += 3 + GameState.half_stars / 2
		GameState.quality = 0.0
		Events.half_star_gained.emit(GameState.half_stars)
	if GameState.half_stars >= 10:
		GameState.quality = minf(GameState.quality, 100.0)
	GameState.up += up_gain
	if n > 0 and avg >= 4.0:
		staff_morale_all(5.0, "")
	elif n > 0 and avg < 2.5:
		staff_morale_all(-6.0, "terrible reviews")
	var sorted := reviews.duplicate()
	sorted.sort_custom(func(a, b): return float(a["weight"]) * 10.0 - float(a["stars"]) > float(b["weight"]) * 10.0 - float(b["stars"]))
	GameState.changed.emit()
	return {
		"day": GameState.day, "count": n, "avg": avg, "shown": sorted.slice(0, 14),
		"old_q": old_q, "new_q": GameState.quality, "delta": delta, "gained": gained,
		"old_h": old_h, "new_h": GameState.half_stars, "up": up_gain, "five_star": five_star,
		"visitors": visitors_today, "commend": commendations, "publicity": publicity,
		"up_visitors": up_visitors, "seen": seen,
	}


func to_ledger() -> void:
	GameState.phase = GameState.Phase.LEDGER
	Events.phase_changed.emit(GameState.phase)
	var wages := 0
	for d in GameState.staff:
		wages += GameState.staff_wage(d)
	if wages > 0:
		GameState.charge(wages, "Staff wages")
	var bills := Mail.unpaid_bills()
	if bills > 0:
		GameState.charge(bills, "Unpaid bills + late fees")
	var upkeep := GameState.museum_level * 20
	for o in museum.all_objects():
		if o.def.get("cat", "") == "Concessions":
			upkeep += 4
		elif o.def.get("cat", "") == "Attractions":
			upkeep += 3
	if upkeep > 0:
		GameState.charge(upkeep, "Museum upkeep")
	var inc := 0
	for v in GameState.ledger["income"].values():
		inc += int(v)
	var spent := 0
	for v in GameState.ledger["expense"].values():
		spent += int(v)
	var data := {
		"day": GameState.day, "income": GameState.ledger["income"].duplicate(), "expense": GameState.ledger["expense"].duplicate(),
		"net": inc - spent, "money": GameState.money, "debt": GameState.debt_total(),
		"warn": GameState.money < -GameState.DEBT_WARN, "bankrupt": GameState.money < -GameState.DEBT_LIMIT,
	}
	if inc - spent > int(GameState.stats["best_day"]):
		GameState.stats["best_day"] = inc - spent
	# Staff morale: bounced paychecks hurt, low morale means resignations.
	if wages > 0 and GameState.money < 0:
		staff_morale_all(-15.0, "paycheck bounced")
	var resigned: Array = []
	for s in staff_nodes.duplicate():
		if not is_instance_valid(s) or s.state == "leaving":
			continue
		var m: float = s.morale()
		if m < 35.0 and randf() < (35.0 - m) / 35.0 * 0.7:
			resigned.append("%s (%s)" % [s.data["name"], DB.STAFF[s.type]["name"]])
			s.quit("low morale")
	data["resigned"] = resigned
	ledger_data = data
	Events.open_panel.emit("ledger", data)


# -------------------------------------------------------------- save/load ---
## The whole running day: clock, visitors (where they are and how they feel),
## queued arrivals, scheduled events, reviews so far, the school tour.
func snapshot() -> Dictionary:
	_prune()
	var gs: Array = []
	for g in guests:
		gs.append(g.save_data())
	for i in range(guests.size()):
		gs[i]["leader"] = guests.find(guests[i].leader) if is_instance_valid(guests[i].leader) else -1
	return {"clock": clock, "hour": _hour, "closing": closing, "close_wait": _close_wait, "visitors": visitors_today,
		"reviews": reviews, "commend": commendations, "publicity": publicity, "scheduled": _scheduled, "pending": _pending,
		"spawn_acc": _spawn_acc, "summary": summary, "ledger_data": ledger_data, "guests": gs, "car_t": _car_t,
		"tour": tour.save_data(guests) if tour and is_instance_valid(tour) else {}}


func restore(d: Dictionary, phase: int) -> void:
	for g in guests:
		if is_instance_valid(g):
			g.free()
	guests.clear()
	if tour and is_instance_valid(tour):
		tour.free()
	tour = null
	clock = float(d.get("clock", OPEN_H))
	_hour = int(d.get("hour", int(clock)))
	closing = bool(d.get("closing", false))
	_close_wait = float(d.get("close_wait", 0.0))
	visitors_today = int(d.get("visitors", 0))
	reviews = d.get("reviews", [])
	commendations = int(d.get("commend", 0))
	publicity = int(d.get("publicity", 0))
	_scheduled = d.get("scheduled", [])
	_pending = d.get("pending", [])
	_spawn_acc = float(d.get("spawn_acc", 0.0))
	_car_t = float(d.get("car_t", 0.0))
	summary = d.get("summary", {})
	ledger_data = d.get("ledger_data", {})
	GameState.phase = phase
	var list: Array = d.get("guests", [])
	var made: Array = []
	for gd in list:
		var g := Guest.new()
		g.look_seed = int(gd.get("seed", 0))
		world.add_child(g)
		g.setup(String(gd.get("kind", "tourist")), museum, self, Vector3(float(gd["pos"][0]), 0, float(gd["pos"][1])))
		guests.append(g)
		made.append(g)
	var td: Dictionary = d.get("tour", {})
	if not td.is_empty():
		tour = SchoolTour.new()
		world.add_child(tour)
		tour.load_data(td, self, made)
	if world.traffic:
		world.traffic.restoring = true
	for i in range(made.size()):
		var li := int(list[i].get("leader", -1))
		if li >= 0 and li < made.size():
			made[i].leader = made[li]
		made[i].load_data(list[i])
	if world.traffic:
		world.traffic.restoring = false
	# snack queues in the order people were standing in them
	var queued: Array = []
	for i in range(made.size()):
		if made[i].state == Guest.S.BUY and made[i].queued_at:
			queued.append([int(list[i].get("queue_i", 0)), made[i]])
	queued.sort_custom(func(a, b): return a[0] < b[0])
	for q in queued:
		(q[1] as Guest).queued_at.join_queue(q[1])
	if tour and is_instance_valid(tour.teacher):
		tour.teacher.gname = String(tour.ev.get("teacher", tour.teacher.gname))
	if phase == GameState.Phase.OPEN:
		museum.set_sign_open(not closing)
		museum.compute_pillars()
		Audio.play_music("closing" if closing else "open")
		Events.clock_changed.emit(clock)
	Events.phase_changed.emit(phase)
	if phase == GameState.Phase.REVIEWS and not summary.is_empty():
		Events.open_panel.emit("reviews", summary)
	elif phase == GameState.Phase.LEDGER and not ledger_data.is_empty():
		Events.open_panel.emit("ledger", ledger_data)


func next_day() -> void:
	if GameState.money < -GameState.DEBT_LIMIT:
		Audio.sfx("gameover")
		Events.game_over.emit("Your debt passed %s. The bank forecloses on the museum and Grimsby Extraction Co. moves in..." % UIKit.money_text(GameState.DEBT_LIMIT))
		return
	GameState.day += 1
	GameState.reset_ledger()
	for d in GameState.staff:
		d["morale"] = minf(100.0, float(d.get("morale", 70.0)) + 4.0)
	GameState.phase = GameState.Phase.PREP
	clock = OPEN_H
	world.new_day()
	Audio.play_music("prep")
	Events.phase_changed.emit(GameState.phase)
	GameState.changed.emit()
	SaveManager.save()
	Events.say("Day %d - autosaved. Time is paused until you open." % GameState.day, Color.WHITE)
