class_name Mail
extends RefCounted
## J-Mail: the emails that arrive on the office computer (after the 3-star
## expansion) and what each choice does. Scams cost a MASSIVE share of your
## cash if you fall for them - delete them! School trips (3+ stars) pay well
## and bring a whole class on the school bus. Plenty of other emails too.

const SCAM_KINDS := ["scam_prince", "scam_lottery", "scam_bank", "scam_crypto", "scam_inheritance"]


## New emails for the morning (1 - 3 of them).
static func generate_day() -> void:
	if not GameState.has_office():
		return
	var n := randi_range(1, 3)
	var made := 0
	if not GameState.flags.get("mail_welcome", false):
		GameState.flags["mail_welcome"] = true
		_add("welcome", "IT Department <it@ammonite-bay.gov>", "Welcome to J-Mail!", "Your new office computer is set up. Emails arrive every morning: offers, bookings, news... and the occasional scam. Never send money or passwords to strangers - if something looks too good to be true, DELETE it.", {})
		made += 1
	var pool := ["scam", "scam", "newsletter", "collector", "charity", "supplier", "interview", "fan_mail", "bill", "storm", "exchange", "celebrity"]
	if GameState.star_count() >= 3:
		pool += ["school_trip", "school_trip", "school_trip"]
	if GameState.star_count() >= 4:
		pool.append("critic")
	if int(GameState.flags.get("act", 1)) >= 3:
		pool.append("grimsby")
	while made < n:
		var k: String = pool[randi() % pool.size()]
		if _make(k):
			made += 1
	Events.mail_arrived.emit(unread())


static func unread() -> int:
	var c := 0
	for m in GameState.emails:
		if not m.get("read", false):
			c += 1
	return c


static func _add(kind: String, from: String, subject: String, body: String, data: Dictionary) -> Dictionary:
	var m := {"id": GameState.next_mail, "kind": kind, "from": from, "subject": subject, "body": body, "day": GameState.day, "read": false, "done": false, "data": data}
	GameState.next_mail += 1
	GameState.emails.push_front(m)
	while GameState.emails.size() > 40:
		GameState.emails.pop_back()
	return m


static func _make(k: String) -> bool:
	match k:
		"scam":
			var s: String = SCAM_KINDS[randi() % SCAM_KINDS.size()]
			match s:
				"scam_prince":
					_add(s, "Prince Adebayo of Fossilia <royal.treasury@f0ssilia-gold.biz>", "URGENT: confidential business partnership!!!", "Dear Esteemed Curator,\n\nI am a prince with 45 MILLION dollars of dinosaur gold stuck in a bank. If you send your museum's money to my 'release fee' account TODAY, I will send you HALF of my fortune.\n\nAct now, tell nobody!\n\nYour friend, Prince Adebayo", {})
				"scam_lottery":
					_add(s, "Global Fossil Lottery <winner@fossil-lott3ry.win>", "CONGRATULATIONS!!! You WON $1,000,000", "You have been randomly selected as our GRAND WINNER! To claim your prize, just transfer the small processing fee (most of your current balance) and we will deposit $1,000,000 within 24 hours.\n\nOffer expires TODAY.", {})
				"scam_bank":
					_add(s, "Securty Team <security@bannk-ammonite.co>", "Your bank account is LOCKED", "We detected suspicious activity. Your account will be CLOSED unless you verify it now by moving your funds to our 'safe account'.\n\nClick ACCEPT to verify immediately.", {})
				"scam_crypto":
					_add(s, "Grimsby Coin Investments <profit@grimsbycoin.moon>", "DOUBLE your money in 24 hours, guaranteed", "Our trading robot has NEVER lost. Send us your cash and get twice as much back tomorrow. 100% guaranteed! No risk!\n\n(Not affiliated with any extraction company.)", {})
				"scam_inheritance":
					_add(s, "Barrister J. Smiths <claims@inherit-now.biz>", "You have inherited a dinosaur ranch", "A distant relative you have never heard of left you a dinosaur ranch worth millions. Simply pay the legal transfer tax (a large share of your savings) to receive the deeds.", {})
			return true
		"school_trip":
			for m in GameState.emails:
				if m["kind"] == "school_trip" and not m.get("done", false):
					return false
			var stars := maxi(3, GameState.star_count())
			var kids := randi_range(7, 12)
			var pay := 180 + 80 * stars + kids * 10
			var school: String = DB.SCHOOLS[randi() % DB.SCHOOLS.size()]
			var teacher: String = DB.TEACHER_NAMES[randi() % DB.TEACHER_NAMES.size()]
			var day := GameState.day + randi_range(1, 2)
			_add("school_trip", "%s <%s@school.edu>" % [teacher, school.to_lower().replace(" ", "").replace("'", "").replace(".", "")], "Class trip booking request - %s" % school,
				"Hello!\n\nI teach at %s and I'd love to bring %d students to your %d-star museum on Day %d. We can pay %s for the visit.\n\nWe'd like YOU to give us a guided tour: please show the class at least three exhibits or attractions and tell them about each one. The children will be listening carefully!\n\nBest wishes,\n%s" % [school, kids, stars, day, UIKit.money_text(pay), teacher],
				{"school": school, "teacher": teacher, "kids": kids, "pay": pay, "day": day})
			return true
		"newsletter":
			var keys := DB.SPECIES.keys()
			var sp: String = keys[randi() % keys.size()]
			var sd: Dictionary = DB.SPECIES[sp]
			_add("newsletter", "Fossil Fact Weekly <facts@fossilfacts.org>", "Fact of the day: %s" % String(sd["name"]).split(" (")[0],
				"%s (%s)\n\n%s\n\nEra: %s   Diet: %s   Habitat: %s" % [sd["name"], sd["sci"], sd["fact"], sd["era"], sd["diet"], sd["habitat"]], {})
			return true
		"collector":
			var dups := GameState.duplicate_fossils()
			if dups.is_empty():
				return false
			var e: Dictionary = dups[randi() % dups.size()]
			var price := int(DB.RARITY_VALUE[GameState.fossil_rarity(e["f"])]) * 12 + 30
			_add("collector", "Dr. Amelia Stone <stone@private-collections.org>", "Offer for your spare %s" % GameState.fossil_name(e["f"]),
				"Good morning,\n\nI hear you have a duplicate %s in storage. I'd pay %s for it - it would complete my teaching collection.\n\nKind regards,\nDr. Amelia Stone" % [GameState.fossil_name(e["f"]), UIKit.money_text(price)], {"uid": int(e["uid"]), "price": price})
			return true
		"charity":
			_add("charity", "Beach Clean-Up Club <hello@cleanbeach.org>", "Help us keep Ammonite Bay clean", "We clean the beach every weekend. A donation of $60 buys gloves and bags for 20 volunteers - and we'll tell everyone your museum helped!", {"cost": 60})
			return true
		"supplier":
			_add("supplier", "Pearl's Equipment & Supplies <pearl@pearlsupply.com>", "Free plushies for loyal customers!", "Thanks for being my best customer, curator! I've set aside a box of 5 dino plushies for you, free of charge. Just say yes.\n\n- Pearl", {})
			return true
		"interview":
			var keys2 := DB.SPECIES.keys()
			var sp2: String = keys2[randi() % keys2.size()]
			_add("interview", "Coastal Gazette <newsdesk@coastalgazette.com>", "Interview request: one quick question", "We're writing about your museum! Our readers want to know:\n\nIn which era did the %s live?\n\nAnswer below - we'll print it in tomorrow's paper." % String(DB.SPECIES[sp2]["name"]).split(" (")[0], {"sp": sp2})
			return true
		"fan_mail":
			_add("fan_mail", "Maya, age 8 <maya@family-mail.com>", "i love your museum!!!", "Dear museum, I visited with my grandma and I saw a REAL fossil. I drew you a picture of a trilobite. When I grow up I want to be a paleontologist like you.\n\nLove, Maya", {})
			return true
		"bill":
			var amount := 30 + GameState.museum_level * 15
			_add("bill", "Ammonite Bay Power Co. <billing@abpower.com>", "Your electricity bill (%s)" % UIKit.money_text(amount), "Your museum's lights, tanks and kiosks used a lot of power this week. Amount due: %s.\n\nPay now, or it is added to tonight's ledger with a %s late fee." % [UIKit.money_text(amount), UIKit.money_text(20)], {"amount": amount})
			return true
		"storm":
			_add("storm", "Coastal Weather Service <alerts@coastweather.gov>", "Storm warning tonight", "A storm will batter the coast tonight. Big waves wash away sand and expose fresh rock - expect more rare BIG dig spots on the beach tomorrow.", {})
			GameState.flags["storm_day"] = GameState.day + 1
			return true
		"exchange":
			_add("exchange", "Harbour City Museum <loans@harbourmuseum.org>", "Exhibit loan offer", "We'd like to lend you our travelling 'Age of Giants' display for 3 days - a big crowd-pleaser. There is a $90 handling fee.", {"cost": 90})
			return true
		"celebrity":
			var who: String = DB.CELEB_NAMES[randi() % DB.CELEB_NAMES.size()]
			_add("celebrity", "%s's Agent <bookings@starmgmt.com>" % who, "%s wants to visit!" % who, "My client %s would love to visit your museum tomorrow and post about it. They expect VIP treatment - greet them personally!" % who, {"who": who})
			return true
		"critic":
			_add("critic", "Museum Monthly <editor@museummonthly.com>", "Our critic is coming", "Heads up: one of our critics will visit tomorrow. Make sure every plaque is right and the floors are spotless.", {})
			return true
		"grimsby":
			_add("grimsby", "Grimsby Extraction Co. <ceo@grimsby-extraction.com>", "Final offer for your 'museum'", "Sell us your land now and walk away with something. Refuse, and we'll make sure your little museum fails.\n\n- G.", {})
			return true
	return false


## Buttons for an email: [label, action] pairs (Delete is always added by the UI).
static func actions(m: Dictionary) -> Array:
	if m.get("done", false):
		return []
	match String(m["kind"]):
		"scam_prince", "scam_lottery", "scam_bank", "scam_crypto", "scam_inheritance":
			return [["Accept offer", "accept"], ["Report as scam", "report"]]
		"school_trip":
			return [["Accept booking", "accept"], ["Decline", "decline"]]
		"collector":
			return [["Sell it", "accept"], ["No thanks", "decline"]]
		"charity":
			return [["Donate $60", "accept"], ["Not now", "decline"]]
		"supplier":
			return [["Yes please!", "accept"]]
		"interview":
			var out: Array = []
			for e in DB.ERAS:
				out.append([e, "era:" + e])
			return out
		"bill":
			return [["Pay now", "accept"]]
		"exchange":
			return [["Accept the loan ($90)", "accept"], ["Decline", "decline"]]
		"celebrity":
			return [["Welcome them", "accept"], ["Decline", "decline"]]
		"critic":
			return [["Got it", "decline"]]
	return []


## Do what the player chose. Returns a short status message for the screen.
static func act(m: Dictionary, action: String) -> String:
	var kind := String(m["kind"])
	m["done"] = true
	if kind.begins_with("scam_"):
		if action == "accept":
			var lost := int(maxi(0, GameState.money) * randf_range(0.55, 0.75))
			if lost > 0:
				GameState.charge(lost, "Scammed!")
			Events.say("It was a SCAM. You lost %s! Never send money to strangers." % UIKit.money_text(lost), UIKit.BAD)
			Audio.sfx("gameover", 1.2, -4.0)
			return "Payment sent... and the 'prince' vanished with %s. It was a scam." % UIKit.money_text(lost)
		GameState.up += 1
		Audio.sfx("star_up", 1.3, -6.0)
		Events.say("Scam reported! The bank thanks you. +1 Upgrade Point", UIKit.GOOD)
		return "Reported to the bank's fraud team. Good catch! (+1 Upgrade Point)"
	var d: Dictionary = m.get("data", {})
	match kind:
		"school_trip":
			if action == "accept":
				GameState.events.append({"what": "school_trip", "day": int(d["day"]), "school": d["school"], "teacher": d["teacher"], "kids": int(d["kids"]), "pay": int(d["pay"])})
				Events.say("School trip booked for Day %d!" % int(d["day"]), UIKit.GOLD)
				return "Booked! %s's class arrives by school bus on Day %d. Open the museum that day and give them a great tour." % [d["teacher"], int(d["day"])]
			return "You declined the booking."
		"collector":
			if action == "accept":
				var e := GameState.find_uid(int(d["uid"]))
				if e.is_empty() or e.get("where", "") != "":
					return "That fossil is no longer in storage."
				GameState.collection.erase(e)
				GameState.earn(int(d["price"]), "Fossil sales")
				return "Sold for %s." % UIKit.money_text(int(d["price"]))
			return "You kept your fossil."
		"charity":
			if action == "accept":
				if not GameState.try_spend(60, "Donations"):
					m["done"] = false
					return "Not enough cash to donate right now."
				GameState.quality = minf(99.0, GameState.quality + 6.0)
				GameState.up += 1
				return "Thank you! The beach is cleaner and people are talking about your museum. (+Quality, +1 Upgrade Point)"
			return "Maybe next time."
		"supplier":
			GameState.plushies += 5
			return "5 dino plushies delivered to the gift shop stock."
		"interview":
			var sp: String = d.get("sp", "")
			var era := action.substr(4)
			if era == String(DB.SPECIES[sp]["era"]):
				GameState.quality = minf(99.0, GameState.quality + 5.0)
				GameState.earn(40, "Publicity")
				return "Correct! The article makes you look like a real expert. (+Quality, +$40 publicity)"
			GameState.quality = maxf(0.0, GameState.quality - 6.0)
			return "Oops - it lived in the %s. The newspaper printed your mistake... (-Quality)" % DB.SPECIES[sp]["era"]
		"bill":
			GameState.charge(int(d["amount"]), "Electricity")
			return "Bill paid."
		"exchange":
			if action == "accept":
				if not GameState.try_spend(int(d["cost"]), "Exhibit loan"):
					m["done"] = false
					return "Not enough cash for the handling fee."
				GameState.flags["loan_exhibit_until"] = GameState.day + 3
				return "The 'Age of Giants' display arrives today: extra fun for 3 days."
			return "Declined."
		"celebrity":
			if action == "accept":
				GameState.events.append({"what": "celebrity", "day": GameState.day + 1})
				return "%s will visit tomorrow. Greet them in person!" % d.get("who", "The celebrity")
			return "Declined."
		"critic":
			GameState.events.append({"what": "critic", "day": GameState.day + 1})
			return "Noted. Get the museum spotless for tomorrow."
	return "Done."


## Bills nobody paid are added (with a late fee) to the evening ledger.
static func unpaid_bills() -> int:
	var total := 0
	for m in GameState.emails:
		if m["kind"] == "bill" and not m.get("done", false) and int(m["day"]) < GameState.day:
			total += int(m["data"]["amount"]) + 20
			m["done"] = true
	return total
