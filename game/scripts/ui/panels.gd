class_name Panels
extends RefCounted
## Builders for every modal panel. Each returns a root Control that GameUI
## adds to its panel layer.

var ui: GameUI
var _lab: LabGame
var _lab_item: Dictionary
var _lab_info: Label
var _lab_tools: HBoxContainer
var _guide_page: VBoxContainer
var _guide_claim := false
var _tree_sel := ""
var _tree_info: PanelContainer


func _init(p_ui: GameUI) -> void:
	ui = p_ui


func world() -> World:
	return World.instance


func build(n: String, data: Variant) -> Control:
	match n:
		"shop":
			return shop()
		"lab":
			return lab()
		"guide":
			return guide(bool(data) if data != null else false)
		"skills":
			return skills()
		"inventory":
			return inventory()
		"storage":
			return storage()
		"gear":
			return gear()
		"factcheck":
			return factcheck(data)
		"management":
			return management(String(data) if data is String else "")
		"exhibit":
			return exhibit(data)
		"podium":
			return podium(data)
		"pit":
			return pit()
		"giftshop":
			return giftshop()
		"discipline":
			return discipline(data)
		"reviews":
			return reviews(data)
		"ledger":
			return ledger(data)
		"trivia":
			return trivia(data)
		"choice":
			return choice(data)
		"tour":
			return tour_panel(data)
		"jmail_note":
			return choice(data)
		"pause":
			return pause()
		"settings":
			return SettingsPanel.create(ui.close_panel)
		"gameover":
			return gameover(String(data))
		"radio":
			return radio_log()
	return null


## The whole radio log, every message in full (the walkie on the HUD only fits
## the last five, trimmed to one line).
func radio_log() -> Control:
	var m := _modal("Radio Log", 860, 0)
	var body: VBoxContainer = m["body"]
	var log: Array = ui.radio_log
	var hint := UIKit.label("Every message from your staff radio today, newest first. Press %s or Esc to close." % Settings.prompt("radio"), 15, UIKit.MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(800, 0)
	body.add_child(hint)
	if log.is_empty():
		body.add_child(UIKit.label("No radio messages yet.", 17, UIKit.MUTED))
		return m["root"]
	var s := UIKit.scroll(420)
	(s["scroll"] as Control).custom_minimum_size = Vector2(800, 420)
	body.add_child(s["scroll"])
	var list: VBoxContainer = s["body"]
	var screen := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("1d3a2c")
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(14)
	screen.add_theme_stylebox_override("panel", sb)
	screen.custom_minimum_size = Vector2(780, 0)
	list.add_child(screen)
	var lines := UIKit.vbox(8)
	screen.add_child(lines)
	for e in log:
		var l := UIKit.label(String(e["text"]), 17, e["color"], true)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(750, 0)
		lines.add_child(l)
	return m["root"]


func _modal(title: String, w: float = 780.0, h: float = 0.0, closable: bool = true) -> Dictionary:
	return UIKit.modal(title, w, h, ui.close_panel if closable else Callable())


func _row(parent: Control, left: String, right: String, rc: Color = UIKit.TEXT) -> void:
	var h := UIKit.hbox(8)
	parent.add_child(h)
	h.add_child(UIKit.expand(UIKit.label(left, 17)))
	var r := UIKit.label(right, 17, rc, true)
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(r)

# ------------------------------------------------------------------- shop ---
func shop() -> Control:
	var m := _modal("Equipment Shop", 860, 600)
	var body: VBoxContainer = m["body"]
	body.add_child(UIKit.label("Pearl: \"Best gear on the coast! Bring me your gems and ores for quick cash.\"   Cash: %s" % UIKit.money_text(GameState.money), 17, UIKit.MUTED))
	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(820, 470)
	body.add_child(tabs)
	# Tools
	var s1 := UIKit.scroll(420)
	s1["scroll"].name = "Tools"
	tabs.add_child(s1["scroll"])
	var tv: VBoxContainer = s1["body"]
	for id in DB.TOOLS.keys():
		var d: Dictionary = DB.TOOLS[id]
		if int(d["cost"]) == 0:
			continue
		var owned := int(GameState.tools.get(d["kind"], 0)) >= int(d["tier"])
		var locked: bool = d["req"] != "" and not GameState.has_skill(d["req"])
		var card := UIKit.card()
		tv.add_child(card)
		var h := UIKit.hbox(10)
		card.add_child(h)
		var info := UIKit.vbox(2)
		UIKit.expand(info)
		h.add_child(info)
		info.add_child(UIKit.label("%s  (%s tier %d)" % [d["name"], {"shovel": "Shovel", "pick": "Pickaxe", "detector": "Detector", "lab": "Lab tool"}[d["kind"]], int(d["tier"])], 18, UIKit.TEXT, true))
		info.add_child(UIKit.label(d["desc"], 15, UIKit.MUTED))
		if owned:
			h.add_child(UIKit.label("Owned", 17, UIKit.GOOD, true))
		elif locked:
			h.add_child(UIKit.label("Needs %s" % DB.SKILLS[d["req"]]["name"], 15, UIKit.CORAL, true))
		else:
			var b := UIKit.button("Buy %s" % UIKit.money_text(int(d["cost"])), _buy_tool.bind(id), 150)
			b.disabled = GameState.money < int(d["cost"])
			h.add_child(b)
	# Supplies
	var s2 := UIKit.vbox(10)
	s2.name = "Supplies"
	tabs.add_child(s2)
	s2.add_child(UIKit.label("Dino Plushies - calm tantrums instantly and sell for $8 in the gift shop.", 17))
	s2.add_child(UIKit.label("In stock at the museum: %d" % GameState.plushies, 16, UIKit.MUTED))
	var pb := UIKit.button("Buy %d plushies for %s" % [DB.PLUSHIE_PACK["count"], UIKit.money_text(DB.PLUSHIE_PACK["cost"])], _buy_plush, 0)
	pb.disabled = GameState.money < int(DB.PLUSHIE_PACK["cost"])
	s2.add_child(pb)
	# Sell
	var s3 := UIKit.vbox(8)
	s3.name = "Sell"
	tabs.add_child(s3)
	var counts := {}
	var total := 0
	for it in GameState.backpack + GameState.storage + GameState.hotbar:
		if not it.is_empty() and (it["t"] == "gem" or it["t"] == "geode"):
			var k: String = GameState.item_name(it)
			counts[k] = int(counts.get(k, 0)) + 1
			total += GameState.item_value(it)
	if counts.is_empty():
		s3.add_child(UIKit.label("You have no gems or ores to sell. Dig on the beach!", 17, UIKit.MUTED))
	for k in counts.keys():
		_row(s3, k, "x%d" % counts[k])
	s3.add_child(UIKit.spacer(6))
	s3.add_child(UIKit.label("Tip: gems kept in storage sell for 1.5x at your own Gift Shop - but cash now pays the bills.", 15, UIKit.MUTED))
	var sb := UIKit.button("Sell everything for %s%s" % [UIKit.money_text(total), " (haggling +20%)" if GameState.has_skill("haggle") else ""], _sell_all, 0, UIKit.GOOD)
	sb.disabled = total == 0
	s3.add_child(sb)
	return m["root"]


func _buy_tool(id: String) -> void:
	var d: Dictionary = DB.TOOLS[id]
	if GameState.try_spend(int(d["cost"]), "Tools"):
		GameState.tools[d["kind"]] = int(d["tier"])
		Audio.sfx("register")
		Events.say("Bought the %s!" % d["name"], UIKit.GOLD)
		if GameState.VITAL_TOOLS.has(d["kind"]) and not GameState.has_tool_item(d["kind"]):
			var err := GameState.issue_tool(d["kind"])
			if err != "":
				Events.say(err + " Collect it later from the gear rack in the Prep Lab.", UIKit.CORAL)
		if d["kind"] == "detector":
			Events.say("Select it in your hotbar near the beach - it pings over buried fossils while you hold it.", UIKit.GOLD)
		GameState.changed.emit()
	ui.reopen()


func _buy_plush() -> void:
	if GameState.try_spend(int(DB.PLUSHIE_PACK["cost"]), "Supplies"):
		GameState.plushies += int(DB.PLUSHIE_PACK["count"])
		Audio.sfx("register")
	ui.reopen()


func _sell_all() -> void:
	var v := GameState.sell_all_gems()
	if v > 0:
		Audio.sfx("register")
		Events.say("Sold for %s!" % UIKit.money_text(v), UIKit.GOOD)
	ui.reopen()

# -------------------------------------------------------------------- lab ---
func lab() -> Control:
	var m := _modal("Prep Lab - Workbench", 900, 0)
	var body: VBoxContainer = m["body"]
	var items := GameState.encased_items()
	if items.is_empty():
		body.add_child(UIKit.label("No encased fossils. Dig them up on the beach - rock-encased finds go to storage when you return.", 18, UIKit.MUTED))
		return m["root"]
	body.add_child(UIKit.label("Choose a find to prepare. Expose every bit of bone; cracks lower the Preservation Rating (and the ticket price it earns). Small finds clean quickly; big field jackets take longer.", 16, UIKit.MUTED))
	var s := UIKit.scroll(380)
	body.add_child(s["scroll"])
	for it in items:
		var h := UIKit.hbox(8)
		(s["body"] as VBoxContainer).add_child(h)
		var g := GameState.lab_grid(String(it["f"]))
		var csz := GameState.fossil_case(String(it["f"]))
		h.add_child(UIKit.icon("bone", 26))
		h.add_child(UIKit.expand(UIKit.label("%s   (%s find, %dx%d grid)" % [GameState.item_name(it), String(DB.CASE_NAMES[csz]).replace("Fossil Display Case", "").replace("Display Case", "").strip_edges().to_lower() if csz != "small" else "small", g.x, g.y], 17, UIKit.TEXT, true)))
		h.add_child(UIKit.button("Prepare", _start_lab.bind(it), 130))
		if Settings.get_v("auto_clean"):
			h.add_child(UIKit.button("Quick clean (60%)", _quick_clean.bind(it), 0, Color("8a8478")))
	return m["root"]


func _quick_clean(it: Dictionary) -> void:
	GameState.remove_item(it)
	_finish_clean(it, 0.6)


func _start_lab(it: Dictionary) -> void:
	_lab_item = it
	var m := _modal("Preparing an Encased Fossil", 920, 0)
	var body: VBoxContainer = m["body"]
	var sp := GameState.species_of(it["f"])
	var sd: Dictionary = DB.SPECIES[sp]
	var shape: String = sd["shape"]
	if GameState.piece_of(it["f"]) != "":
		shape = "skull" if GameState.piece_of(it["f"]) in ["skull", "jaw"] else "bone"
	_lab = LabGame.new()
	var grid := GameState.lab_grid(String(it["f"]))
	var csz := GameState.fossil_case(String(it["f"]))
	var hard := 2 if csz in ["big", "mega"] else 1
	_lab.setup(shape, sd["color"], hash(String(it["f"]) + str(GameState.next_uid)), grid, GameState.matrix_of(it), hard)
	var cell := minf(56.0, minf(760.0 / grid.x, 430.0 / grid.y))
	_lab.custom_minimum_size = Vector2(grid.x * cell, grid.y * cell)
	var center := CenterContainer.new()
	body.add_child(center)
	center.add_child(_lab)
	_lab_tools = UIKit.hbox(8)
	body.add_child(_lab_tools)
	for t in range(1, 4):
		if int(GameState.tools["lab"]) >= t:
			var d: Dictionary = DB.TOOLS["lab_%d" % t]
			_lab_tools.add_child(UIKit.button(d["name"], _set_lab_tool.bind(t), 0))
	_lab_tools.add_child(UIKit.expand(Control.new()))
	_lab_info = UIKit.label("", 17, UIKit.TEXT, true)
	_lab_tools.add_child(_lab_info)
	var help := UIKit.label("Mouse: click / drag to chip.  Keyboard: WASD or arrows move the cursor, %s or Space chips, %s switches tool.  Gamepad: D-pad + %s." % [Settings.prompt("interact"), Settings.prompt("drop_item"), Settings.prompt("interact")], 14, UIKit.MUTED)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.custom_minimum_size = Vector2(860, 0)
	body.add_child(help)
	var dmg_help := UIKit.label("Damage = cracks in exposed bone. The Micro-Brush can never crack bone; only the faster Air Scribe and Pro Scribe (sold at Pearl's shop) can.", 14, UIKit.MUTED)
	dmg_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dmg_help.custom_minimum_size = Vector2(860, 0)
	body.add_child(dmg_help)
	_lab.changed.connect(_lab_refresh)
	_lab.finished.connect(_lab_done)
	_lab.gui_input.connect(_lab_pad)
	_set_lab_tool(int(GameState.tools["lab"]))
	ui.current.queue_free()
	ui.panel_layer.add_child(m["root"])
	ui.current = m["root"]
	ui.current_name = "lab_game"
	(m["root"] as Control).set_process_unhandled_input(true)
	_lab.grab_focus()
	_lab_refresh()


func _lab_pad(e: InputEvent) -> void:
	if e.is_action_pressed("ui_left", true) or e.is_action_pressed("move_left", true):
		_lab.move_cursor(Vector2i(-1, 0))
	elif e.is_action_pressed("ui_right", true) or e.is_action_pressed("move_right", true):
		_lab.move_cursor(Vector2i(1, 0))
	elif e.is_action_pressed("ui_up", true) or e.is_action_pressed("move_forward", true):
		_lab.move_cursor(Vector2i(0, -1))
	elif e.is_action_pressed("ui_down", true) or e.is_action_pressed("move_back", true):
		_lab.move_cursor(Vector2i(0, 1))
	elif e.is_action_pressed("interact", true) or e.is_action_pressed("jump", true) or e.is_action_pressed("ui_accept", true):
		# keyboard F / Space / Enter and the gamepad all chip at the cursor
		_lab.chip(_lab.cursor)
	elif e.is_action_pressed("drop_item"):
		_set_lab_tool(_lab.tool % int(GameState.tools["lab"]) + 1)
	else:
		return
	_lab.accept_event()


func _set_lab_tool(t: int) -> void:
	_lab.tool = t
	var i := 1
	for c in _lab_tools.get_children():
		if c is Button:
			UIKit.style_button(c, "btn_gold" if i == t else "btn_teal")
			i += 1
	_lab.queue_redraw()


func _lab_refresh() -> void:
	if _lab_info and _lab:
		var tool_name: String = DB.TOOLS["lab_%d" % _lab.tool]["name"]
		_lab_info.text = "Exposed %d%%   Cracks %d%s   Preservation %d%%" % [int(_lab.progress() * 100), _lab.dmg_total,
			" (brush is safe)" if _lab.tool == 1 else " (%s can crack bone!)" % tool_name, int(_lab.preservation() * 100)]


func _lab_done(pres: float) -> void:
	GameState.remove_item(_lab_item)
	_finish_clean(_lab_item, pres)


func _finish_clean(it: Dictionary, pres: float) -> void:
	var e := GameState.add_cleaned(it["f"], pres)
	var sp := GameState.species_of(it["f"])
	var sd: Dictionary = DB.SPECIES[sp]
	var m := _modal("Fossil Prepared!", 680, 0)
	var body: VBoxContainer = m["body"]
	body.add_child(UIKit.label(GameState.fossil_name(it["f"]), 30, UIKit.ACCENT.darkened(0.2), true))
	body.add_child(UIKit.label("%s  -  %s" % [sd["sci"], sd["period"]], 16, UIKit.MUTED))
	var grade := "Pristine" if pres >= 0.95 else ("Excellent" if pres >= 0.8 else ("Good" if pres >= 0.6 else ("Fair" if pres >= 0.4 else "Poor")))
	body.add_child(UIKit.label("Preservation Rating: %d%% (%s)" % [int(pres * 100), grade], 20, UIKit.GOOD if pres >= 0.6 else UIKit.CORAL, true))
	body.add_child(UIKit.label("Rarity: %s" % GameState.fossil_rarity(it["f"]).capitalize(), 17))
	var csz := GameState.fossil_case(String(it["f"]))
	body.add_child(UIKit.label("Display it in a: %s" % DB.CASE_NAMES[csz], 17, UIKit.ACCENT, true))
	if e.get("new", false):
		var nl := UIKit.label("NEW SPECIES for your Field Guide! Put it on display and OPEN the museum: the first day visitors see it earns +%d Upgrade Point(s)." % GameState.discovery_points(sp), 17, Color("c08a10"), true)
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nl.custom_minimum_size = Vector2(620, 0)
		body.add_child(nl)
	if sp == "apex":
		body.add_child(UIKit.label("A piece of the Cove Tyrant! (%d/8 found)" % GameState.owned_pieces("apex").size(), 18, UIKit.CORAL, true))
	var h := UIKit.hbox(8)
	body.add_child(h)
	h.add_child(UIKit.button("Prepare another", _open_lab_again, 0))
	h.add_child(UIKit.button("Done", ui.close_panel, 0, UIKit.CORAL))
	if ui.current:
		ui.current.queue_free()
	ui.panel_layer.add_child(m["root"])
	ui.current = m["root"]
	ui.current_name = "lab_done"
	UIKit.focus_first(m["root"])

# ------------------------------------------------------------------ guide ---
const GUIDE_TOPICS := [
	["Getting started", "[b]Your goal:[/b] grow a seaside fossil museum to 5 stars and reveal the secret of Ammonite Bay.\n\n[b]The daily loop[/b]\n1. [b]Prep[/b] (time is paused): dig on the beach, sell gems at the Equipment Shop, clean fossils at the Prep Lab, and arrange your museum in Build Mode.\n2. [b]Open[/b]: flip the OPEN sign by the museum door. Visitors arrive by car, buy tickets and look at your exhibits.\n3. [b]Sunset[/b]: visitors take the bus home, you read the day's reviews, then the ledger pays wages and upkeep.\n4. Opening is how you earn [b]Upgrade Points[/b]: spend them in the Upgrade Tree and start the next day.\n\nYou can save at any time from the pause menu."],
	["Hotbar & tools", "The row of slots at the bottom of the screen is your [b]hotbar[/b]. Whatever is in the selected slot is in your hand.\n\n- Select a slot with [b]1-9[/b] or the mouse wheel.\n- [b]Use[/b] (left mouse) uses the held tool: HOLD it with the [b]shovel[/b] or [b]pickaxe[/b] on a dig spot; the [b]detector[/b] scans while you hold it; held [b]trash[/b] is thrown (aim at a bin!).\n- [b]Drop[/b] (Q) puts the held item on the ground. Pick it up again with Interact.\n- [b]Trash[/b] (X) throws the held item away. Your shovel, pickaxe and detector are vital and can't be trashed.\n- Lost or dropped a tool? The [b]gear rack[/b] in the Prep Lab re-issues any tool you own.\n- The Upgrade Tree's [b]Tool Belt[/b] nodes add hotbar slots."],
	["Digging & zones", "Look at a dig spot, hold the right tool and [b]HOLD Use[/b]. The percentage climbs while you hold; let go (or look away) and it resets, so you can stop any time.\n\n- [b]Sand patches, dirt mounds and buried finds[/b]: shovel. [b]Cracked rock, crystal boulders and slate[/b]: pickaxe (better tiers break harder rock).\n- Bigger spots take longer. Better tools and the [b]Strong Arms[/b] upgrades (one per star tier) dig faster.\n- Rare [b]BIG spots[/b] (Giant Dune Mound, Fossil Boulder, Bone Bed) need better tools and take a long time, but hold the zone's biggest and rarest finds.\n- Untouched spots weather away after a while, and new ones keep appearing.\n- Hidden buried finds only appear when the [b]detector[/b] is in your hand and you walk close.\n- Gems and ores are common (a full early backpack sells for about $100); fossils are rarer.\n\nEach beach zone exposes rock of a different age, and each matches a star rating: its permit unlocks at that rating, and it only holds fossils for the cases you can build by then.\n- [b]Driftwood Shore[/b] (Cenozoic, 0 stars): small and medium finds.\n- [b]Ammonite Cliffs[/b] (Mesozoic, 1 star): adds Big Case fossils.\n- [b]Sea Caves[/b] (Mesozoic, 2 stars): adds whole skeletons for the Mega Case.\n- [b]Paleozoic Shelf[/b] (Paleozoic, 3 stars): the oldest and rarest finds."],
	["Backpack & storage", "Finds go into your [b]backpack[/b] (press [b]E[/b] to open it). When it is full, unload at the [b]storage crates[/b] in the Prep Lab.\n\nThe storage window lets you move single items between your hotbar, backpack and storage. It also lists every cleaned fossil that is ready to put on display."],
	["Prep Lab", "Fossils come out of the ground wrapped in rock: a [b]Sandstone Nodule[/b], [b]Shale Slab[/b], [b]Chalk Block[/b], [b]Tar Seep Block[/b], [b]Amber Lump[/b] or, for big finds, a [b]Plaster Field Jacket[/b]. Clean them at the [b]workbench[/b].\n\nThe grid matches the find: small common fossils are quick, big rare ones take longer. Click or drag to chip, or use WASD + F/Space. [b]Cracks[/b] lower the preservation rating - the Micro-Brush never cracks bone; only the faster scribes from Pearl's shop can.\n\nCleaning a species for the first time adds it to your Field Guide."],
	["Exhibits & plaques", "Every fossil fits exactly ONE kind of case:\n- [b]Fossil Display Case[/b] (1x1): small finds.\n- [b]Medium Case[/b] (2x1): hand- to arm-sized finds.\n- [b]Big Case[/b] (2x2): skulls, horns, tusks, plates.\n- [b]Mega Case[/b] (3x3): assemble skeleton bones into a whole skeleton.\nBigger cases are unlocked in the Upgrade Tree.\n\nEvery case needs a correct [b]plaque[/b]: pick the right Era, Diet and Habitat. A correct plaque raises the ticket price and earns tips; a blank one disappoints; a [b]wrong[/b] one makes fossil enthusiasts write brutal one-star reviews. Build a [b]Fact-Check Kiosk[/b] to see which plaques are wrong."],
	["Opening & Upgrade Points", "Flip the [b]OPEN/CLOSED sign[/b] by the door to start the day. Visitors arrive by car, wander between your exhibits, and some will throw litter - pick it up and throw it in a bin.\n\nAt sunset every visitor writes a review. Good days fill the Quality bar; a full bar earns half a star.\n\n[b]Upgrade Points come from opening:[/b] +1 for every 5 visitors, a bonus for good review days, and the FIRST day visitors see a new species on display earns its discovery points.\n\nThe road outside is busy: cars and buses come out of the tunnels, and they won't stop for you!"],
	["Snack stands", "Concession stands don't sell by themselves: [b]you serve the queue.[/b]\n1. Look at the stand and press Interact to grab an empty cup, bag or bun.\n2. Interact again to fill it.\n3. Interact once more to serve the guest at the front of the queue.\n\nGuests wait about 45 seconds. Busy day? Unlock the [b]Snack Vendor[/b] job and hire one."],
	["Trash & cleanliness", "Visitors throw trash: into a bin if one is close, otherwise onto the floor. Look at a piece of trash and press Interact to [b]pick it up[/b] into your hotbar, then aim at a [b]trash bin[/b] and press Use to throw it in (or Interact with the bin). Empty full bins with empty hands. Janitors do all of this for you."],
	["Building", "Press [b]B[/b] for Build Mode - before or while the museum is open (never on top of a visitor or yourself). Right-click [b]sells[/b] a build for 25% of its price (Resale Contacts upgrades raise it). New builds and bigger floors are unlocked in the [b]Upgrade Tree[/b]."],
	["Office & J-Mail", "The 3-star expansion adds an office computer to the Prep Lab. Sit down and read your [b]J-Mail[/b] every morning: schools book class trips (they pay well - give the class a guided tour and only tell them true facts!), collectors make offers, newspapers ask questions...\n\n[b]Beware of scams:[/b] if an email promises free money or asks you to send yours, DELETE it. Falling for one costs a huge share of your cash."],
	["Stars & the Upgrade Tree", "Open the Upgrade Tree with [b]T[/b]. It is much bigger than the window: drag to move around, scroll to zoom, or jump to a branch with the buttons on top. Nodes sit on [b]star tiers[/b] (0 to 5 stars); a tier stays locked until your museum has that many stars. Buy a node's parents first."],
	["Staff", "You start with [b]no staff slots[/b]. Each star tier from 2 stars up has a [b]Staff Slot +1[/b] node, and every job must be unlocked first.\n\nStaff have morale. Praise them, give raises, and never shove them, or they quit."],
	["Controls", "[b]Move[/b] WASD - [b]Sprint[/b] Shift - [b]Jump[/b] Space\n[b]Interact / pick up[/b] F - [b]Use held item[/b] Left mouse (HOLD to dig)\n[b]Inventory / backpack[/b] E (or Tab) - [b]Hotbar[/b] 1-9 / wheel\n[b]Drop[/b] Q - [b]Trash held item[/b] X\n[b]Build Mode[/b] B - [b]Upgrade Tree[/b] T - [b]Guide[/b] G - [b]Management[/b] M - [b]Radio log[/b] V - [b]Pause[/b] Esc\n\nEverything can be remapped in Settings, and gamepads work too."],
]


func guide(claim_mode: bool) -> Control:
	_guide_claim = claim_mode
	var m := _modal("Curator's Desk" if claim_mode else "Guide", 960, 560)
	var body: VBoxContainer = m["body"]
	if GameState.unclaimed_count() > 0:
		var top := UIKit.label("%d new species waiting to be seen by visitors: put them on display and open the museum to earn their Upgrade Points." % GameState.unclaimed_count(), 15, UIKit.CORAL, true)
		top.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		top.custom_minimum_size = Vector2(900, 0)
		body.add_child(top)
	var split := UIKit.hbox(12)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(split)
	var ls := UIKit.scroll(460)
	(ls["scroll"] as Control).custom_minimum_size = Vector2(260, 460)
	split.add_child(ls["scroll"])
	var lv: VBoxContainer = ls["body"]
	lv.add_child(UIKit.label("HOW TO PLAY", 14, UIKit.ACCENT, true))
	for i in range(GUIDE_TOPICS.size()):
		var b := UIKit.button(GUIDE_TOPICS[i][0], _guide_topic.bind(i), 240)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(240, 36)
		b.add_theme_font_size_override("font_size", 15)
		lv.add_child(b)
	lv.add_child(UIKit.spacer(6))
	lv.add_child(UIKit.label("FIELD GUIDE  (%d/%d)" % [GameState.discovered.size(), DB.SPECIES.size()], 14, UIKit.ACCENT, true))
	for era in DB.ERAS:
		lv.add_child(UIKit.label(era, 13, UIKit.MUTED, true))
		for sp in DB.SPECIES.keys():
			var sd: Dictionary = DB.SPECIES[sp]
			if sd["era"] != era:
				continue
			var known := GameState.discovered.has(sp)
			var txt: String = sd["name"] if known else "???"
			if known and not GameState.discovered[sp]["claimed"]:
				txt += "  (!)"
			var b2 := UIKit.button(txt, _guide_show.bind(sp), 240, UIKit.ACCENT if known else Color("a39c8e"))
			b2.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b2.custom_minimum_size = Vector2(240, 34)
			b2.add_theme_font_size_override("font_size", 14)
			b2.clip_text = true
			lv.add_child(b2)
	if not world().museum.objects_of("aquarium").is_empty():
		lv.add_child(UIKit.label("Living fossils", 13, UIKit.MUTED, true))
		for k in DB.LIVING.keys():
			var b3 := UIKit.button(DB.LIVING[k]["name"], _guide_living.bind(k), 240)
			b3.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b3.add_theme_font_size_override("font_size", 14)
			lv.add_child(b3)
	var page := UIKit.card(Color("fffaf0"), Color("d8c9a8"))
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(page)
	var ps := UIKit.scroll(440)
	page.add_child(ps["scroll"])
	_guide_page = ps["body"]
	var first := ""
	for sp in DB.SPECIES.keys():
		if claim_mode and GameState.discovered.has(sp) and not GameState.discovered[sp]["claimed"]:
			first = sp
			break
	if first != "":
		_guide_show(first)
	else:
		_guide_topic(0)
	return m["root"]


func _guide_topic(i: int) -> void:
	UIKit.clear(_guide_page)
	_guide_page.add_child(UIKit.label(GUIDE_TOPICS[i][0], 26, UIKit.ACCENT.darkened(0.25), true))
	var r := UIKit.rich(GUIDE_TOPICS[i][1], 17)
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.custom_minimum_size = Vector2(560, 0)
	_guide_page.add_child(r)


func _guide_show(sp: String) -> void:
	UIKit.clear(_guide_page)
	var sd: Dictionary = DB.SPECIES[sp]
	if not GameState.discovered.has(sp):
		_guide_page.add_child(UIKit.label("Undiscovered", 26, UIKit.MUTED, true))
		var u := UIKit.label("Found in %s strata. Dig it up and clean it at the Prep Lab to reveal this page." % sd["era"], 17, UIKit.MUTED)
		u.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_guide_page.add_child(u)
		return
	_guide_page.add_child(UIKit.label(sd["name"], 26, UIKit.ACCENT.darkened(0.25), true))
	_guide_page.add_child(UIKit.label(sd["sci"] + ("   (in-game species)" if sd.get("fictional", false) else ""), 16, UIKit.MUTED))
	var tags := "[b]Era:[/b] %s     [b]Diet:[/b] %s     [b]Habitat:[/b] %s" % [sd["era"], sd["diet"], sd["habitat"]]
	var tr := UIKit.rich("[bgcolor=#f3e6cc] %s [/bgcolor]" % tags, 16)
	tr.custom_minimum_size = Vector2(560, 0)
	_guide_page.add_child(tr)
	var body := "[b]Period:[/b] %s\n[b]Rarity:[/b] %s\n[b]Size:[/b] %s\n\n%s" % [sd["period"], String(sd["rarity"]).capitalize(), sd["size"], sd["fact"]]
	var r := UIKit.rich(body, 16)
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.custom_minimum_size = Vector2(560, 0)
	_guide_page.add_child(r)
	if sd.has("pieces"):
		var owned := GameState.owned_pieces(sp)
		var s := "Skeleton pieces: "
		for pc in sd["pieces"]:
			s += ("[x] " if owned.has(pc) else "[ ] ") + DB.PIECE_NAMES[pc] + "   "
		var pl := UIKit.label(s, 14, UIKit.MUTED)
		pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_guide_page.add_child(pl)
	var cl := UIKit.label("Display case: %s" % DB.CASE_NAMES[String(sd.get("case", "small"))], 15, UIKit.ACCENT, true)
	_guide_page.add_child(cl)
	if not GameState.discovered[sp]["claimed"]:
		var rl := UIKit.label("Reward: +%d Upgrade Point(s) the first day visitors see it on display." % GameState.discovery_points(sp), 15, UIKit.CORAL, true)
		rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rl.custom_minimum_size = Vector2(540, 0)
		_guide_page.add_child(rl)
	Audio.sfx("page", 1.0, -8.0)


func _guide_living(k: String) -> void:
	UIKit.clear(_guide_page)
	var l: Dictionary = DB.LIVING[k]
	_guide_page.add_child(UIKit.label(l["name"], 26, UIKit.ACCENT.darkened(0.25), true))
	_guide_page.add_child(UIKit.label(l["sci"] + "  -  living fossil (in your aquarium)", 16, UIKit.MUTED))
	var r := UIKit.rich(l["fact"], 16)
	r.custom_minimum_size = Vector2(560, 0)
	_guide_page.add_child(r)


func _claim(sp: String) -> void:
	var pts := GameState.claim(sp)
	if pts > 0:
		Audio.sfx("star_up")
		Events.say("Discovery claimed: +%d Upgrade Point(s)!" % pts, UIKit.GOLD)
	ui.open("guide", true)


func _claim_all() -> void:
	var total := 0
	for sp in GameState.discovered.keys():
		total += GameState.claim(sp)
	if total > 0:
		Audio.sfx("star_up")
		Events.say("Claimed %d Upgrade Points from new discoveries!" % total, UIKit.GOLD)
	ui.open("guide", true)

# ----------------------------------------------------------- upgrade tree ---
const TREE_COL_W := 138.0
const TREE_ROW_H := 124.0
const TREE_LEFT := 74.0
const TREE_TOP := 60.0
const TREE_VIEW := Vector2(1200, 470)
var TREE_W: float:
	get: return TREE_LEFT + DB.SKILL_COLUMNS * TREE_COL_W + 40.0
var TREE_H: float:
	get: return TREE_TOP + 6.0 * TREE_ROW_H + 20.0
var _tree_view: TreeView


func _tree_pos(id: String) -> Vector2:
	var d: Dictionary = DB.SKILLS[id]
	return Vector2(TREE_LEFT + (float(d["x"]) + 0.5) * TREE_COL_W, TREE_TOP + (float(d["tier"]) + 0.5) * TREE_ROW_H)


## The Upgrade Tree: far bigger than the window - drag to pan, scroll to zoom,
## jump between branches with the tabs on top.
func skills() -> Control:
	var m := _modal("Upgrade Tree", 1260, 0)
	var body: VBoxContainer = m["body"]
	var top := UIKit.hbox(14)
	body.add_child(top)
	top.add_child(UIKit.icon_label("research", "Upgrade Points: %d" % GameState.up, 18, UIKit.ACCENT, true, 28))
	top.add_child(UIKit.icon_label("coin", UIKit.money_text(GameState.money), 18, UIKit.GOOD, true, 26))
	top.add_child(UIKit.stars_row(GameState.half_stars, 22))
	var owned := GameState.skills.size()
	top.add_child(UIKit.label("%d / %d unlocked" % [owned, DB.SKILLS.size()], 15, UIKit.MUTED, true))
	top.add_child(UIKit.expand(UIKit.label("Drag to move around, scroll to zoom. Earn points by opening the museum.", 14, UIKit.MUTED)))
	var jumps := UIKit.hbox(6)
	body.add_child(jumps)
	for br in DB.SKILL_BRANCHES:
		var jb := UIKit.button(br[0], _tree_jump.bind(br), 0, Color.TRANSPARENT)
		jb.custom_minimum_size = Vector2(0, 34)
		jb.add_theme_font_size_override("font_size", 14)
		jumps.add_child(jb)
	var canvas := Control.new()
	canvas.custom_minimum_size = Vector2(TREE_W, TREE_H)
	canvas.size = canvas.custom_minimum_size
	canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	_tree_view = TreeView.new()
	_tree_view.custom_minimum_size = TREE_VIEW
	body.add_child(_tree_view)
	_tree_view.setup(canvas)
	var bg := ColorRect.new()
	bg.color = Color("efe2c6")
	bg.size = canvas.custom_minimum_size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(bg)
	var rh := TREE_ROW_H
	var stars := GameState.star_count()
	for t in range(6):  # star tier bands
		var band := ColorRect.new()
		band.color = Color("f3e6cc") if t % 2 == 0 else Color("fbf3e3")
		if t > stars:
			band.color = band.color.darkened(0.12)
		band.position = Vector2(0, TREE_TOP + t * rh)
		band.size = Vector2(TREE_W, rh)
		band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(band)
		var tl := UIKit.icon_label("star" if t <= stars else "lock", "%d" % t, 16, UIKit.ACCENT if t <= stars else UIKit.GREY, true, 20)
		tl.position = Vector2(8, TREE_TOP + t * rh + rh * 0.5 - 14)
		tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(tl)
	var cw := TREE_COL_W
	for br in DB.SKILL_BRANCHES:  # branch headers + soft column backdrops
		var col := ColorRect.new()
		col.color = Color(1, 1, 1, 0.22)
		col.position = Vector2(TREE_LEFT + float(br[1]) * cw + 4, TREE_TOP)
		col.size = Vector2((float(br[2]) - float(br[1]) + 1.0) * cw - 8, 6.0 * rh)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(col)
		var hl := UIKit.label(br[0], 18, UIKit.ACCENT.darkened(0.2), true)
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hl.position = Vector2(TREE_LEFT + float(br[1]) * cw, 18)
		hl.size = Vector2((float(br[2]) - float(br[1]) + 1.0) * cw, 28)
		hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(hl)
	for id in DB.SKILLS.keys():  # connecting lines (drawn under the nodes)
		for r in DB.SKILLS[id]["req"]:
			var ln := Line2D.new()
			ln.width = 5.0
			ln.default_color = UIKit.GOLD.darkened(0.15) if GameState.has_skill(r) and GameState.has_skill(id) else (UIKit.ACCENT if GameState.has_skill(r) else Color("b9b0a0"))
			var a := _tree_pos(r)
			var b := _tree_pos(id)
			ln.add_point(a)
			ln.add_point(Vector2(a.x, (a.y + b.y) * 0.5))
			ln.add_point(Vector2(b.x, (a.y + b.y) * 0.5))
			ln.add_point(b)
			canvas.add_child(ln)
	if _tree_sel == "" or not DB.SKILLS.has(_tree_sel):
		_tree_sel = "backpack_1"
	for id in DB.SKILLS.keys():
		var st := GameState.skill_state(id)
		var p := _tree_pos(id)
		var b := Button.new()
		b.icon = UIKit.icon_tex(String(DB.SKILLS[id]["icon"]), 34)
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.expand_icon = false
		b.custom_minimum_size = Vector2(58, 58)
		b.size = Vector2(58, 58)
		b.position = p - Vector2(29, 29)
		var nl := UIKit.label(String(DB.SKILLS[id]["name"]).replace("Blueprint: ", ""), 12, UIKit.TEXT if st != "locked" and st != "stars" else UIKit.MUTED, true)
		nl.add_theme_stylebox_override("normal", UIKit.sb(Color(1, 0.98, 0.93, 0.85), Color.TRANSPARENT, 0, 6, 2))
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.position = p + Vector2(-64, 31)
		nl.size = Vector2(128, 30)
		nl.custom_minimum_size = Vector2(128, 0)
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(nl)
		b.tooltip_text = DB.SKILLS[id]["name"]
		b.focus_mode = Control.FOCUS_ALL
		UIKit.style_button(b, {"owned": "btn_gold", "available": "btn_teal", "locked": "btn_grey", "stars": "btn_grey"}[st])
		if st == "locked" or st == "stars":
			b.modulate = Color(0.78, 0.76, 0.72)
		b.pressed.connect(_tree_select.bind(id))
		canvas.add_child(b)
		if id == _tree_sel:
			# the selection ring is a child of the button, so it always wraps the
			# button itself whatever size its style gives it
			var ring := Panel.new()
			ring.add_theme_stylebox_override("panel", UIKit.sb(Color(1, 1, 1, 0), UIKit.CORAL, 4, 14, 0))
			ring.set_anchors_preset(Control.PRESET_FULL_RECT)
			ring.offset_left = -6
			ring.offset_top = -6
			ring.offset_right = 6
			ring.offset_bottom = 6
			ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(ring)
		if st == "owned":
			var ck := UIKit.icon("check", 20)
			ck.position = p + Vector2(14, -34)
			canvas.add_child(ck)
	_tree_info = UIKit.card()
	_tree_info.custom_minimum_size = Vector2(TREE_VIEW.x, 104)
	body.add_child(_tree_info)
	_tree_fill_info()
	return m["root"]


func _tree_jump(br: Array) -> void:
	if _tree_view:
		var mid := (float(br[1]) + float(br[2]) + 1.0) * 0.5
		_tree_view.center_on(Vector2(TREE_LEFT + mid * TREE_COL_W, TREE_TOP + 2.6 * TREE_ROW_H))


func _tree_select(id: String) -> void:
	_tree_sel = id
	Audio.sfx("click")
	ui.reopen()


func _tree_fill_info() -> void:
	UIKit.clear(_tree_info)
	var id := _tree_sel
	var d: Dictionary = DB.SKILLS[id]
	var st := GameState.skill_state(id)
	var h := UIKit.hbox(14)
	_tree_info.add_child(h)
	h.add_child(UIKit.icon(String(d["icon"]), 54))
	var v := UIKit.vbox(2)
	UIKit.expand(v)
	h.add_child(v)
	v.add_child(UIKit.label("%s   (%d-star tier)" % [d["name"], int(d["tier"])], 20, UIKit.TEXT, true))
	var desc := UIKit.label(d["desc"], 15, UIKit.MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(desc)
	var price := "%d UP" % int(d["cost"])
	if int(d.get("cash", 0)) > 0:
		price += "  +  %s" % UIKit.money_text(int(d["cash"]))
	var pv := UIKit.vbox(4)
	h.add_child(pv)
	pv.add_child(UIKit.label("Price: " + price, 17, UIKit.ACCENT, true))
	match st:
		"owned":
			pv.add_child(UIKit.label("Unlocked", 17, UIKit.GOOD, true))
		"available":
			var b := UIKit.button("Unlock", _buy_skill.bind(id), 180, UIKit.GOLD.darkened(0.2))
			b.disabled = not GameState.can_afford_skill(id)
			if b.disabled:
				b.tooltip_text = "Not enough Upgrade Points or cash."
			pv.add_child(b)
		_:
			var need := UIKit.label("Requires: " + ", ".join(GameState.skill_missing(id)), 14, UIKit.CORAL, true)
			need.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			need.custom_minimum_size = Vector2(300, 0)
			pv.add_child(need)


func _buy_skill(id: String) -> void:
	if GameState.buy_skill(id):
		Audio.sfx("star_up")
		Events.say("Unlocked: %s" % DB.SKILLS[id]["name"], UIKit.GOLD)
		if id.begins_with("zone_"):
			world().beach.refresh_barriers(true)
		if id.begins_with("equip_"):
			Events.say("Pearl's Equipment Shop has new stock!", UIKit.GOLD)
		if id.begins_with("bp_") or id.begins_with("lic_"):
			Events.say("New build unlocked - find it in Build Mode (%s)." % Settings.prompt("build_mode"), UIKit.GOLD)
	ui.reopen()

# -------------------------------------------------------------- inventory ---
func _item_row(parent: Control, it: Dictionary, label_extra: String, moves: Array, src: String, idx: int) -> void:
	var h := UIKit.hbox(6)
	parent.add_child(h)
	var ic := "gem"
	match String(it.get("t", "")):
		"tool":
			ic = {"shovel": "shovel", "pick": "pickaxe", "detector": "walkie"}.get(String(it["kind"]), "gear")
		"encased":
			ic = "bone"
		"trash":
			ic = "trash"
		"serve":
			ic = "coin"
	h.add_child(UIKit.icon(ic, 22))
	var nm := GameState.item_name(it)
	if it.get("t", "") == "gem":
		nm += "  (%s)" % UIKit.money_text(GameState.item_value(it))
	h.add_child(UIKit.expand(UIKit.label(nm + label_extra, 15)))
	for mv in moves:
		var b := UIKit.button(mv[0], _move_item.bind(src, idx, mv[1]), 0)
		b.custom_minimum_size = Vector2(0, 34)
		b.add_theme_font_size_override("font_size", 13)
		h.add_child(b)


func _move_item(src: String, idx: int, dst: String) -> void:
	var err := GameState.move_item(src, idx, dst)
	if err != "":
		Events.say(err, UIKit.CORAL)
		Audio.sfx("error")
	else:
		Audio.sfx("pickup", 1.2, -6.0)
	ui.reopen()


func _hotbar_section(v: VBoxContainer, at_storage: bool) -> void:
	v.add_child(UIKit.label("Hotbar (%d slots)" % GameState.hotbar.size(), 18, UIKit.ACCENT, true))
	for i in range(GameState.hotbar.size()):
		var it: Dictionary = GameState.hotbar[i]
		if it.is_empty():
			v.add_child(UIKit.label("  %d.  (empty)" % (i + 1), 14, UIKit.MUTED))
			continue
		var moves := [["To backpack", "backpack"]]
		if at_storage:
			moves.append(["To storage", "storage"])
		if it["t"] == "trash" or it["t"] == "serve":
			moves = []
		_item_row(v, it, "", moves, "hotbar", i)


func inventory() -> Control:
	var m := _modal("Inventory", 900, 600)
	var body: VBoxContainer = m["body"]
	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(860, 520)
	body.add_child(tabs)
	var b1 := UIKit.scroll(460)
	b1["scroll"].name = "Hotbar & Backpack"
	tabs.add_child(b1["scroll"])
	var v1: VBoxContainer = b1["body"]
	_hotbar_section(v1, false)
	v1.add_child(UIKit.spacer(6))
	v1.add_child(UIKit.label("Backpack (%d/%d)" % [GameState.backpack.size(), GameState.backpack_capacity()], 18, UIKit.ACCENT, true))
	if GameState.backpack.is_empty():
		v1.add_child(UIKit.label("Empty", 15, UIKit.MUTED))
	for i in range(GameState.backpack.size()):
		_item_row(v1, GameState.backpack[i], "", [["To hotbar", "hotbar"]], "backpack", i)
	v1.add_child(UIKit.spacer(6))
	v1.add_child(UIKit.label("Storage: %d item(s) - open the crates in the Prep Lab to move them." % GameState.storage.size(), 15, UIKit.MUTED))
	var v3 := UIKit.vbox(6)
	v3.name = "Tools"
	tabs.add_child(v3)
	for kind in ["shovel", "pick", "detector", "lab"]:
		var d := GameState.tool_def(kind)
		_row(v3, {"shovel": "Shovel", "pick": "Pickaxe", "detector": "Detector", "lab": "Lab tool"}[kind], d.get("name", "None"))
	_row(v3, "Dino plushies", str(GameState.plushies))
	_row(v3, "Dig pit stock", "%d digs" % GameState.pit_stock)
	v3.add_child(UIKit.label("Dropped or lost a tool? The gear rack in the Prep Lab re-issues it.", 15, UIKit.MUTED))
	return m["root"]


## The storage crates: move single items between hotbar, backpack and storage;
## cleaned fossils waiting for a display case are listed too.
func storage() -> Control:
	var m := _modal("Storage Crates", 1020, 620)
	var body: VBoxContainer = m["body"]
	var top := UIKit.hbox(10)
	body.add_child(top)
	top.add_child(UIKit.expand(UIKit.label("Move items one at a time. Gems, ores and geodes sell at the Equipment Shop; encased fossils go to the workbench.", 15, UIKit.MUTED)))
	var ub := UIKit.button("Unload whole backpack", _unload_all, 0, UIKit.GOOD)
	ub.disabled = GameState.backpack.is_empty()
	top.add_child(ub)
	var cols := UIKit.hbox(12)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(cols)
	var lsc := UIKit.scroll(500)
	(lsc["scroll"] as Control).custom_minimum_size = Vector2(480, 500)
	cols.add_child(lsc["scroll"])
	var lv: VBoxContainer = lsc["body"]
	_hotbar_section(lv, true)
	lv.add_child(UIKit.spacer(6))
	lv.add_child(UIKit.label("Backpack (%d/%d)" % [GameState.backpack.size(), GameState.backpack_capacity()], 18, UIKit.ACCENT, true))
	if GameState.backpack.is_empty():
		lv.add_child(UIKit.label("Empty", 15, UIKit.MUTED))
	for i in range(GameState.backpack.size()):
		_item_row(lv, GameState.backpack[i], "", [["To storage", "storage"], ["To hotbar", "hotbar"]], "backpack", i)
	var rsc := UIKit.scroll(500)
	(rsc["scroll"] as Control).custom_minimum_size = Vector2(480, 500)
	cols.add_child(rsc["scroll"])
	var rv: VBoxContainer = rsc["body"]
	rv.add_child(UIKit.label("Storage (%d)" % GameState.storage.size(), 18, UIKit.ACCENT, true))
	if GameState.storage.is_empty():
		rv.add_child(UIKit.label("Empty", 15, UIKit.MUTED))
	for i in range(GameState.storage.size()):
		_item_row(rv, GameState.storage[i], "", [["To backpack", "backpack"], ["To hotbar", "hotbar"]], "storage", i)
	rv.add_child(UIKit.spacer(8))
	var free := GameState.free_fossils()
	rv.add_child(UIKit.label("Cleaned fossils ready to display (%d)" % free.size(), 18, UIKit.ACCENT, true))
	if free.is_empty():
		rv.add_child(UIKit.label("None yet - clean encased finds at the workbench.", 15, UIKit.MUTED))
	for e in free:
		var h := UIKit.hbox(6)
		rv.add_child(h)
		h.add_child(UIKit.icon("bone", 22))
		var rar := GameState.fossil_rarity(e["f"])
		h.add_child(UIKit.expand(UIKit.label("%s  -  %d%% preserved  (%s)" % [GameState.fossil_name(e["f"]), int(float(e["pres"]) * 100), rar], 15, DB.RARITY_COLOR[rar].darkened(0.45), true)))
	var shown := 0
	for e in GameState.collection:
		if e["where"] != "":
			shown += 1
	rv.add_child(UIKit.label("%d more cleaned fossil(s) are on display in the museum." % shown, 14, UIKit.MUTED))
	return m["root"]


func _unload_all() -> void:
	var n := GameState.deposit_backpack()
	if n > 0:
		Audio.sfx("pickup", 0.8)
		Events.say("Unloaded %d item(s) into storage." % n, UIKit.GOOD)
	ui.reopen()


## Gear rack: re-equip any tool you own (lost or dropped ones are re-issued).
func gear() -> Control:
	var m := _modal("Gear Rack", 720, 0)
	var body: VBoxContainer = m["body"]
	body.add_child(UIKit.label("Pick up any tool you own. If you dropped or lost one, it's re-issued here.", 16, UIKit.MUTED))
	for kind in GameState.VITAL_TOOLS:
		var card := UIKit.card()
		body.add_child(card)
		var h := UIKit.hbox(10)
		card.add_child(h)
		h.add_child(UIKit.icon({"shovel": "shovel", "pick": "pickaxe", "detector": "walkie"}[kind], 40))
		var td := GameState.tool_def(kind)
		var v := UIKit.vbox(2)
		UIKit.expand(v)
		h.add_child(v)
		v.add_child(UIKit.label(String(td.get("name", "No %s" % GameState.TOOL_NAMES[kind])), 18, UIKit.TEXT, true))
		if td.is_empty():
			v.add_child(UIKit.label("Buy one at the Equipment Shop.", 14, UIKit.MUTED))
			continue
		var carried := GameState.has_tool_item(kind)
		v.add_child(UIKit.label("In your hotbar or bags" if carried else "Not carried (dropped or lost)", 14, UIKit.GOOD if carried else UIKit.CORAL))
		var b := UIKit.button("Equip" if not carried else "Carried", _equip_tool.bind(kind), 140, UIKit.GOOD if not carried else Color.TRANSPARENT)
		b.disabled = carried
		h.add_child(b)
	return m["root"]


func _equip_tool(kind: String) -> void:
	Pickup.clear_tool(ui.get_tree(), kind)
	var err := GameState.issue_tool(kind)
	if err != "":
		Events.say(err, UIKit.CORAL)
		Audio.sfx("error")
	else:
		Audio.sfx("pickup")
		Events.say("Equipped your %s." % GameState.TOOL_NAMES[kind], UIKit.GOOD)
	ui.reopen()


## Fact-Check Kiosk report: one tidy row per display case (fossil, where it is,
## and exactly which tags are wrong or missing), in a scrolling list.
func factcheck(_o: Variant) -> Control:
	var m := _modal("Fact-Check Kiosk", 820, 0)
	var body: VBoxContainer = m["body"]
	var cases: Array = world().museum.cases()
	var shown: Array = cases.filter(func(o): return not o.fossil_entry().is_empty())
	var bad: Array = world().museum.wrong_plaques()
	var summary := UIKit.hbox(10)
	body.add_child(summary)
	summary.add_child(UIKit.icon("check" if bad.is_empty() else "warning", 34))
	var st := UIKit.label("All %d plaque(s) are correct. The enthusiasts will be pleased!" % shown.size() if bad.is_empty() else "%d of %d plaque(s) need fixing." % [bad.size(), shown.size()], 19, UIKit.GOOD if bad.is_empty() else UIKit.BAD, true)
	st.autowrap_mode = TextServer.AUTOWRAP_OFF
	summary.add_child(st)
	var why := UIKit.label("Wrong plaques make visitors complain, and fossil enthusiasts leave furious one-star reviews. Blank plaques disappoint everyone.", 15, UIKit.MUTED)
	why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	why.custom_minimum_size = Vector2(760, 0)
	body.add_child(why)
	if shown.is_empty():
		body.add_child(UIKit.label("No fossils on display yet.", 16, UIKit.MUTED))
		return m["root"]
	var s := UIKit.scroll(330)
	(s["scroll"] as Control).custom_minimum_size = Vector2(760, 330)
	body.add_child(s["scroll"])
	var list: VBoxContainer = s["body"]
	for o in shown:
		var status: String = o.plaque_status()
		var card := UIKit.card()
		card.custom_minimum_size = Vector2(740, 0)
		list.add_child(card)
		var row := UIKit.hbox(12)
		card.add_child(row)
		row.add_child(UIKit.icon("check" if status == "ok" else "warning", 30))
		var v := UIKit.vbox(2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(v)
		var f: Dictionary = o.fossil_entry()
		var nm := UIKit.label(GameState.fossil_name(f["f"]), 18, UIKit.TEXT, true)
		nm.autowrap_mode = TextServer.AUTOWRAP_OFF
		v.add_child(nm)
		var where := UIKit.label("%s, row %d / column %d" % [o.def["name"], o.cell.y + 1, o.cell.x + 1], 14, UIKit.MUTED)
		where.autowrap_mode = TextServer.AUTOWRAP_OFF
		v.add_child(where)
		var detail := ""
		var col := UIKit.GOOD
		match status:
			"ok":
				detail = "Correct"
			"blank":
				detail = "Blank plaque - pick its Era, Diet and Habitat"
				col = UIKit.CORAL
			_:
				detail = "Wrong: " + ", ".join(o.wrong_tags())
				col = UIKit.BAD
		var dl := UIKit.label(detail, 15, col, true)
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.custom_minimum_size = Vector2(560, 0)
		v.add_child(dl)
	body.add_child(UIKit.label("Tip: look the species up in the Field Guide (%s)." % Settings.prompt("field_guide"), 14, UIKit.MUTED))
	return m["root"]

# ------------------------------------------------------------- management ---
func management(tab: String) -> Control:
	var m := _modal("Management", 920, 620)
	var body: VBoxContainer = m["body"]
	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(880, 540)
	body.add_child(tabs)
	# Staff
	var ss := UIKit.scroll(480)
	ss["scroll"].name = "Staff"
	tabs.add_child(ss["scroll"])
	var sv: VBoxContainer = ss["body"]
	var cap := GameState.staff_cap()
	var slots := UIKit.hbox(8)
	sv.add_child(slots)
	slots.add_child(UIKit.icon("staff", 30))
	slots.add_child(UIKit.label("Staff slots: %d / %d" % [GameState.staff.size(), cap], 19, UIKit.ACCENT, true))
	for i in range(6):
		var pip := UIKit.icon("check" if i < cap else "lock", 22)
		pip.modulate = Color.WHITE if i < cap else Color(1, 1, 1, 0.45)
		slots.add_child(pip)
	if cap == 0:
		sv.add_child(UIKit.label("You have no staff slots yet. Buy a \"Staff Slot +1\" (2-star tier) and a job licence in the Upgrade Tree (%s) to employ your first worker." % Settings.prompt("skill_tree"), 16, UIKit.CORAL, true))
	elif cap < 6:
		sv.add_child(UIKit.label("Each \"Staff Slot +1\" in the Upgrade Tree adds one more slot; each job needs its own licence. Wages are paid at the end of each day.", 15, UIKit.MUTED))
	sv.add_child(UIKit.label("Unhappy staff QUIT: shoving them, reprimands, bounced paychecks and bad review days all hurt morale. Praise and raises help.", 15, UIKit.MUTED))
	for s in world().day_cycle.staff_nodes:
		if not is_instance_valid(s):
			continue
		var card := UIKit.card()
		sv.add_child(card)
		var cv := UIKit.vbox(4)
		card.add_child(cv)
		var h := UIKit.hbox(8)
		cv.add_child(h)
		var t: float = float(s.data.get("temper", 0.5))
		var temper := "calm" if t < 0.35 else ("moody" if t < 0.65 else "hot-headed")
		h.add_child(UIKit.expand(UIKit.label("%s - %s   (%s)%s" % [s.data["name"], DB.STAFF[s.type]["name"], temper, "   ROGUE!" if s.rogue else ""], 17, UIKit.BAD if s.rogue else UIKit.TEXT, true)))
		var bonus := int(s.data.get("bonus", 0))
		h.add_child(UIKit.icon_label("coin", "%s/day%s" % [UIKit.money_text(GameState.staff_wage(s.data)), (" (+%s raise)" % UIKit.money_text(bonus)) if bonus > 0 else ""], 15, UIKit.MUTED, true, 22))
		var mh := UIKit.hbox(8)
		cv.add_child(mh)
		mh.add_child(UIKit.icon("heart", 24))
		mh.add_child(UIKit.label("Morale", 15, UIKit.TEXT, true))
		var mo: float = s.morale()
		var mb := UIKit.bar(UIKit.GOOD if mo >= 55.0 else (UIKit.GOLD if mo >= 30.0 else UIKit.CORAL), mo, 16)
		mb.custom_minimum_size = Vector2(220, 16)
		mh.add_child(mb)
		var mood := "Happy" if mo >= 70.0 else ("Content" if mo >= 45.0 else ("Unhappy" if mo >= 20.0 else "About to quit!"))
		mh.add_child(UIKit.label("%d%%  %s" % [int(mo), mood], 15, UIKit.GOOD if mo >= 45.0 else UIKit.BAD, true))
		mh.add_child(UIKit.expand(Control.new()))
		var pb := UIKit.button("Praise", _praise.bind(s), 0, UIKit.GOOD, "happy")
		pb.disabled = int(s.data.get("praised", 0)) == GameState.day
		pb.tooltip_text = "+10 morale (once per day)"
		mh.add_child(pb)
		var rb := UIKit.button("Raise +$10", _raise.bind(s), 0, UIKit.GOLD, "coin")
		rb.disabled = bonus >= 30
		rb.tooltip_text = "+$10/day wage, +22 morale (up to 3 raises)"
		mh.add_child(rb)
		mh.add_child(UIKit.button("Fire", _fire.bind(s), 0, UIKit.CORAL))
	sv.add_child(UIKit.spacer(4))
	sv.add_child(UIKit.label("Hire", 19, UIKit.ACCENT, true))
	for t in DB.STAFF.keys():
		var d: Dictionary = DB.STAFF[t]
		var hc := UIKit.card()
		sv.add_child(hc)
		var h2 := UIKit.hbox(8)
		hc.add_child(h2)
		h2.add_child(UIKit.expand(UIKit.label("%s (%s/day) - %s" % [d["name"], UIKit.money_text(int(d["wage"])), d["desc"]], 15)))
		var job_ok := GameState.job_unlocked(t)
		var label := "Hire" if job_ok and cap > 0 else ("Job locked" if not job_ok else "No slots")
		var hb := UIKit.button(label, _hire.bind(t), 120, Color.TRANSPARENT, "staff" if job_ok and cap > 0 else "lock")
		hb.disabled = GameState.staff.size() >= cap or not job_ok
		if not job_ok:
			hb.tooltip_text = "Unlock \"%s\" in the Upgrade Tree." % DB.SKILLS[d["job"]]["name"]
		h2.add_child(hb)
	# Finances
	var fv := UIKit.vbox(8)
	fv.name = "Finances"
	tabs.add_child(fv)
	_row(fv, "Cash", UIKit.money_text(GameState.money), UIKit.GOOD if GameState.money >= 0 else UIKit.BAD)
	_row(fv, "Overdraft", UIKit.money_text(GameState.debt_total()), UIKit.BAD if GameState.debt_total() > 0 else UIKit.TEXT)
	_row(fv, "Bankruptcy threshold", "cash below %s" % UIKit.money_text(-GameState.DEBT_LIMIT), UIKit.CORAL)
	fv.add_child(UIKit.label("Today so far", 18, UIKit.ACCENT, true))
	for k in GameState.ledger["income"].keys():
		_row(fv, "  + " + k, UIKit.money_text(int(GameState.ledger["income"][k])), UIKit.GOOD)
	for k in GameState.ledger["expense"].keys():
		_row(fv, "  - " + k, UIKit.money_text(int(GameState.ledger["expense"][k])), UIKit.BAD)
	fv.add_child(UIKit.label("No loans: grow by selling gems, opening every day and selling builds you no longer need.", 15, UIKit.MUTED))
	# Museum
	var mv := UIKit.vbox(6)
	mv.name = "Museum"
	tabs.add_child(mv)
	var p := GameState.pillars
	_row(mv, "Rating", GameState.star_text())
	_row(mv, "Quality toward next half-star", "%d%%" % int(GameState.quality))
	_row(mv, "Fun (exhibits & attractions)", "%d%%  (%d pts)" % [int(p["fun"]), int(p["fun_points"])])
	_row(mv, "Decorations", "%d%%  (%d pts)" % [int(p["decor"]), int(p["decor_points"])])
	_row(mv, "Cleanliness", "%d%%" % int(p["clean"]))
	_row(mv, "Accurate plaques", str(int(p["accurate"])))
	_row(mv, "Ticket price", UIKit.money_text(GameState.ticket_price()))
	_row(mv, "Total visitors", str(int(GameState.stats["visitors"])))
	_row(mv, "Species discovered", "%d / %d" % [GameState.discovered.size(), DB.SPECIES.size()])
	mv.add_child(UIKit.label("Quality rises with good daily reviews. Fun, decorations and cleanliness drive what guests write. At 100% the museum gains half a star and the bar resets with a tougher threshold.", 15, UIKit.MUTED))
	if tab == "Finances":
		tabs.current_tab = 1
	return m["root"]


func _fire(s: Staff) -> void:
	world().day_cycle.fire(s)
	ui.reopen()


func _praise(s: Staff) -> void:
	if not is_instance_valid(s):
		return
	s.data["praised"] = GameState.day
	s.change_morale(10.0, "")
	Audio.sfx("cheer", 1.2, -8.0)
	Events.say("%s appreciates the praise. (+10 morale)" % s.data["name"], UIKit.GOOD)
	ui.reopen()


func _raise(s: Staff) -> void:
	if not is_instance_valid(s):
		return
	s.data["bonus"] = int(s.data.get("bonus", 0)) + 10
	s.change_morale(22.0, "")
	Audio.sfx("register")
	Events.say("%s got a raise! Wage now %s/day." % [s.data["name"], UIKit.money_text(GameState.staff_wage(s.data))], UIKit.GOLD)
	ui.reopen()


func _hire(t: String) -> void:
	if world().day_cycle.hire(t):
		Audio.sfx("register")
		Events.say("Hired a new %s!" % DB.STAFF[t]["name"], UIKit.GOOD)
	ui.reopen()



# --------------------------------------------------------------- exhibits ---
func exhibit(o: PlacedObject) -> Control:
	var m := _modal(String(o.def["name"]), 900, 0)
	var body: VBoxContainer = m["body"]
	var f := o.fossil_entry()
	if not f.is_empty():
		var sd: Dictionary = DB.SPECIES[GameState.species_of(f["f"])]
		body.add_child(UIKit.label("On display: %s  (%d%% preserved)" % [GameState.fossil_name(f["f"]), int(float(f["pres"]) * 100)], 20, UIKit.ACCENT, true))
		var info := UIKit.label("Plaque Builder: pick the correct Era, Diet and Habitat (look them up in the Guide, %s). Correct plaques raise the ticket price and earn tips. Blank plaques disappoint visitors, and wrong ones get you savaged by fossil enthusiasts." % Settings.prompt("field_guide"), 15, UIKit.MUTED)
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(info)
		var pl: Dictionary = o.data.get("plaque", {})
		var row := UIKit.hbox(10)
		body.add_child(row)
		var opts := {}
		for pair in [["era", DB.ERAS], ["diet", DB.DIETS], ["habitat", DB.HABITATS]]:
			var v := UIKit.vbox(2)
			row.add_child(v)
			v.add_child(UIKit.label(String(pair[0]).capitalize(), 15, UIKit.ACCENT, true))
			var ob := OptionButton.new()
			ob.add_item("- choose -")
			for x in pair[1]:
				ob.add_item(x)
			var cur: String = pl.get(pair[0], "")
			ob.selected = maxi(0, (pair[1] as Array).find(cur) + 1)
			ob.custom_minimum_size = Vector2(240, 40)
			v.add_child(ob)
			opts[pair[0]] = ob
		var res := UIKit.label("", 16, UIKit.TEXT, true)
		var h := UIKit.hbox(8)
		body.add_child(h)
		h.add_child(UIKit.button("Save plaque", _save_plaque.bind(o, opts, res), 0, UIKit.GOOD))
		h.add_child(UIKit.button("Remove fossil", _remove_fossil.bind(o), 0, UIKit.CORAL))
		body.add_child(res)
		if o.plaque_status() == "blank":
			res.text = "This plaque is blank - fill it in before you open."
			res.add_theme_color_override("font_color", UIKit.CORAL)
		elif world().museum.has_checker() and o.accurate_plaque():
			res.text = "Fact-Check Kiosk: this plaque is accurate."
			res.add_theme_color_override("font_color", UIKit.GOOD)
		elif world().museum.has_checker():
			res.text = "Fact-Check Kiosk: this plaque is WRONG (%s)." % ", ".join(o.wrong_tags())
			res.add_theme_color_override("font_color", UIKit.BAD)
		body.add_child(HSeparator.new())
	var csz: String = o.case_size()
	var all_free := GameState.free_fossils()
	var free: Array = all_free.filter(func(e): return GameState.piece_of(e["f"]) == "" and GameState.fossil_case(e["f"]) == csz)
	body.add_child(UIKit.label("Mount a cleaned fossil that fits this case (%d available):" % free.size(), 18, UIKit.ACCENT, true))
	if free.is_empty():
		body.add_child(UIKit.label("No free fossils of this size. Prepare finds at the Prep Lab.", 16, UIKit.MUTED))
	var other := {}
	for e in all_free:
		var c2 := GameState.fossil_case(e["f"])
		if c2 != csz:
			other[c2] = int(other.get(c2, 0)) + 1
	for c2 in other.keys():
		var ol := UIKit.label("%d other cleaned fossil(s) need a %s." % [other[c2], DB.CASE_NAMES[c2]], 15, UIKit.MUTED)
		ol.autowrap_mode = TextServer.AUTOWRAP_OFF
		body.add_child(ol)
	var s := UIKit.scroll(260)
	body.add_child(s["scroll"])
	for e in free:
		var hh := UIKit.hbox(8)
		(s["body"] as VBoxContainer).add_child(hh)
		var rar := GameState.fossil_rarity(e["f"])
		hh.add_child(UIKit.expand(UIKit.label("%s  -  %d%% preserved  (%s)" % [GameState.fossil_name(e["f"]), int(float(e["pres"]) * 100), rar], 16, DB.RARITY_COLOR[rar].darkened(0.45), true)))
		hh.add_child(UIKit.button("Mount", _mount.bind(o, e), 100))
	return m["root"]


func _mount(o: PlacedObject, e: Dictionary) -> void:
	o.mount_fossil(e)
	Audio.sfx("register")
	Events.say("Mounted %s." % GameState.fossil_name(e["f"]), UIKit.GOOD)
	ui.reopen(o)


func _save_plaque(o: PlacedObject, opts: Dictionary, res: Label) -> void:
	var pl := {}
	var keys := {"era": DB.ERAS, "diet": DB.DIETS, "habitat": DB.HABITATS}
	for k in opts.keys():
		var i: int = (opts[k] as OptionButton).selected
		if i > 0:
			pl[k] = keys[k][i - 1]
	o.data["plaque"] = pl if pl.size() == 3 else {}
	o.refresh_display()
	Events.museum_changed.emit()
	if pl.size() < 3:
		res.text = "Pick all three tags - a blank plaque disappoints visitors."
		res.add_theme_color_override("font_color", UIKit.CORAL)
	elif not world().museum.has_checker():
		# without a kiosk you only find out from your visitors
		res.text = "Plaque saved. Not sure it's right? Build a Fact-Check Kiosk to verify it."
		res.add_theme_color_override("font_color", UIKit.MUTED)
		Audio.sfx("page", 1.2, -6.0)
	elif o.accurate_plaque():
		res.text = "Fact-Check Kiosk: accurate plaque! Educational bonus active."
		res.add_theme_color_override("font_color", UIKit.GOOD)
		Audio.sfx("star_up", 1.2, -4.0)
	else:
		res.text = "Fact-Check Kiosk: wrong tag(s) - %s." % ", ".join(o.wrong_tags())
		res.add_theme_color_override("font_color", UIKit.BAD)
		Audio.sfx("error", 1.0, -6.0)


func podium(o: PlacedObject) -> Control:
	var m := _modal("Mega Display Case", 860, 0)
	var body: VBoxContainer = m["body"]
	var cur: String = o.data.get("species", "")
	if cur != "":
		var sd: Dictionary = DB.SPECIES[cur]
		body.add_child(UIKit.label("%s - %d/%d bones mounted" % [sd["name"], o.mounted_count(), sd["pieces"].size()], 20, UIKit.ACCENT, true))
		var s := ""
		for pc in sd["pieces"]:
			s += ("[x] " if (o.data["pieces"] as Dictionary).has(pc) else "[ ] ") + DB.PIECE_NAMES[pc] + "    "
		body.add_child(UIKit.label(s, 16))
		if o.skeleton_complete():
			body.add_child(UIKit.label("COMPLETE! A towering centrepiece.", 18, UIKit.GOOD, true))
	var hint := UIKit.label("Assemble the bones of ONE skeleton species. Skeleton bones come from big dig spots and buried finds: Ichthyosaurus (cliffs), Mosasaurus, Iguanodon and T. rex (caves), Dimetrodon (Paleozoic shelf)... and something else in the caves.", 15, UIKit.MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(800, 0)
	body.add_child(hint)
	var any := false
	var megas: Array = []
	for k in DB.SPECIES.keys():
		if DB.SPECIES[k].has("pieces"):
			megas.append(k)
	for sp in megas:
		var free := GameState.free_fossils(sp)
		var distinct := {}
		for e in free:
			distinct[GameState.piece_of(e["f"])] = true
		if distinct.is_empty():
			continue
		any = true
		var label := "Mount %d %s bone(s)" % [distinct.size(), DB.SPECIES[sp]["name"].split(" (")[0]]
		if cur != "" and cur != sp:
			label += " (replaces current)"
		body.add_child(UIKit.button(label, _mount_species.bind(o, sp), 0, UIKit.GOOD))
	if not any:
		body.add_child(UIKit.label("No free skeleton bones. Clean bone pieces at the lab first.", 16, UIKit.MUTED))
	if cur != "":
		body.add_child(UIKit.button("Clear podium (bones return to storage)", _clear_podium.bind(o), 0, UIKit.CORAL))
	return m["root"]


func _mount_species(o: PlacedObject, sp: String) -> void:
	var n := o.mount_species(sp)
	Audio.sfx("register")
	Events.say("Mounted %d bone(s)." % n, UIKit.GOOD)
	if o.skeleton_complete():
		Audio.sfx("fanfare")
		Events.say("%s skeleton complete!" % DB.SPECIES[sp]["name"], UIKit.GOLD)
	ui.reopen(o)


func pit() -> Control:
	var m := _modal("Junior Dino-Dig Pit", 700, 0)
	var body: VBoxContainer = m["body"]
	var dups := GameState.duplicate_fossils()
	body.add_child(UIKit.label("Current stock: %d digs. Each buried duplicate fossil gives 5 kid digs ($5 each). The pit also distracts kids mid-tantrum." % GameState.pit_stock, 16))
	body.add_child(UIKit.label("Duplicate fossils available: %d" % dups.size(), 18, UIKit.ACCENT, true))
	var b := UIKit.button("Bury all duplicates", _bury.bind(dups), 0, UIKit.GOOD)
	b.disabled = dups.is_empty()
	body.add_child(b)
	return m["root"]


func _bury(dups: Array) -> void:
	for e in dups:
		GameState.collection.erase(e)
	GameState.pit_stock += dups.size() * 5
	Audio.sfx("dig_sand")
	Events.say("Buried %d duplicates in the dig pit." % dups.size(), UIKit.GOOD)
	ui.reopen()


func giftshop() -> Control:
	var m := _modal("Geode Cracker & Gift Shop", 680, 0)
	var body: VBoxContainer = m["body"]
	var gems := 0
	var geodes := 0
	for it in GameState.storage:
		if it["t"] == "gem":
			gems += 1
		elif it["t"] == "geode":
			geodes += 1
	_row(body, "Gems & ores in storage (sold at 1.5x)", str(gems))
	_row(body, "Sealed geodes (cracked for tourists, %s each)" % UIKit.money_text(DB.GEODE_CRACK_PRICE), str(geodes))
	_row(body, "Dino plushies ($8 each)", str(GameState.plushies))
	body.add_child(UIKit.label("Restock plushies at Pearl's Equipment Shop. Watch for shoplifters once your museum is famous!", 15, UIKit.MUTED))
	return m["root"]


func discipline(s: Staff) -> Control:
	var m := _modal("Rogue Employee", 640, 0)
	var body: VBoxContainer = m["body"]
	body.add_child(UIKit.label("%s the %s is %s" % [s.data["name"], DB.STAFF[s.type]["name"], "asleep on the job." if s.type == "janitor" else "being harsh with guests!"], 19, UIKit.BAD, true))
	body.add_child(UIKit.label("Give them a stern reprimand, fire them on the spot, or 'teach them a lesson' (face them and press %s to shove them with whatever you hold - guests may not love seeing that)." % Settings.prompt("use_item"), 15, UIKit.MUTED))
	var h := UIKit.hbox(8)
	body.add_child(h)
	h.add_child(UIKit.button("Stern reprimand", _reprimand.bind(s), 0, UIKit.GOOD))
	h.add_child(UIKit.button("Fire them", _fire_close.bind(s), 0, UIKit.CORAL))
	h.add_child(UIKit.button("Never mind", ui.close_panel, 0))
	return m["root"]

# ------------------------------------------------------------ end of day ---
func reviews(d: Dictionary) -> Control:
	var m := _modal("Daily Customer Reviews - Day %d" % int(d["day"]), 900, 0, false)
	var body: VBoxContainer = m["body"]
	var n := int(d["count"])
	if n == 0:
		body.add_child(UIKit.label("No reviews today - nobody visited. Make the museum more fun and attractive!", 18, UIKit.MUTED))
	else:
		var sh := UIKit.hbox(10)
		body.add_child(sh)
		sh.add_child(UIKit.icon("ticket", 28))
		sh.add_child(UIKit.label("%d visitors  |  %d reviews  |  average %.1f / 5" % [int(d["visitors"]), n, float(d["avg"])], 19, UIKit.ACCENT, true))
		sh.add_child(UIKit.stars_row(int(round(float(d["avg"]) * 2.0)), 26))
	var s := UIKit.scroll(330)
	body.add_child(s["scroll"])
	for r in d["shown"]:
		var card := UIKit.card(Color("fffaf0") if int(r["stars"]) >= 3 else Color("fdebe6"))
		(s["body"] as VBoxContainer).add_child(card)
		var v := UIKit.vbox(2)
		card.add_child(v)
		var who: String = r["name"]
		if r["kind"] == "critic":
			who += "  (CRITIC - counts triple)"
		elif r["kind"] == "celebrity":
			who += "  (celebrity)"
		var h := UIKit.hbox(8)
		v.add_child(h)
		h.add_child(UIKit.stars_row(int(r["stars"]) * 2, 24))
		h.add_child(UIKit.label("- " + who, 14, UIKit.MUTED))
		var q := UIKit.label("\"%s\"" % r["text"], 17, UIKit.TEXT, true)
		q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(q)
	var qrow := UIKit.hbox(8)
	body.add_child(qrow)
	qrow.add_child(UIKit.icon("star", 26))
	qrow.add_child(UIKit.label("Quality", 17, UIKit.TEXT, true))
	var bar := UIKit.bar(Color("e0a020"), float(d["old_q"]), 20)
	UIKit.expand(bar)
	qrow.add_child(bar)
	var dl := float(d["delta"])
	qrow.add_child(UIKit.label("%+d%%" % int(round(dl)), 18, UIKit.GOOD if dl >= 0 else UIKit.BAD, true))
	var target := 100.0 if int(d["gained"]) > 0 else float(d["new_q"])
	bar.create_tween().tween_property(bar, "value", target, 1.2).set_trans(Tween.TRANS_CUBIC)
	if int(d["gained"]) > 0:
		var lb := UIKit.label("MUSEUM LEVEL UP!  %s  - new upgrades unlocked" % GameState.star_text(int(d["new_h"])), 24, Color("c08a10"), true)
		body.add_child(lb)
		Audio.sfx("fanfare")
	if int(d["up"]) > 0:
		var why: Array = []
		if int(d["gained"]) > 0:
			why.append("half-star milestone")
		if d["five_star"]:
			why.append("5-star review day")
		if int(d["commend"]) > 0:
			why.append("critic commendation")
		if int(d.get("up_visitors", 0)) > 0:
			why.append("%d from visitors" % int(d["up_visitors"]))
		var seen: Array = d.get("seen", [])
		if not seen.is_empty():
			why.append("new species seen: " + ", ".join(seen))
		body.add_child(UIKit.label("+%d Upgrade Points (%s)" % [int(d["up"]), ", ".join(why)], 18, UIKit.ACCENT, true))
	body.add_child(UIKit.button("Continue to the ledger", _to_ledger, 0, UIKit.GOOD))
	return m["root"]


func ledger(d: Dictionary) -> Control:
	var m := _modal("Daily Ledger - Day %d" % int(d["day"]), 720, 0, false)
	var body: VBoxContainer = m["body"]
	body.add_child(UIKit.icon_label("coin", "Income", 19, UIKit.GOOD, true, 26))
	if (d["income"] as Dictionary).is_empty():
		body.add_child(UIKit.label("  (none)", 16, UIKit.MUTED))
	for k in d["income"].keys():
		_row(body, "  " + k, UIKit.money_text(int(d["income"][k])), UIKit.GOOD)
	body.add_child(UIKit.icon_label("trash", "Expenses", 19, UIKit.BAD, true, 26))
	if (d["expense"] as Dictionary).is_empty():
		body.add_child(UIKit.label("  (none - no rent in Act 1!)", 16, UIKit.MUTED))
	for k in d["expense"].keys():
		_row(body, "  " + k, "-" + UIKit.money_text(int(d["expense"][k])), UIKit.BAD)
	body.add_child(HSeparator.new())
	_row(body, "Net today", UIKit.money_text(int(d["net"])), UIKit.GOOD if int(d["net"]) >= 0 else UIKit.BAD)
	_row(body, "Cash balance", UIKit.money_text(int(d["money"])), UIKit.GOOD if int(d["money"]) >= 0 else UIKit.BAD)
	if int(d["debt"]) > 0:
		_row(body, "Outstanding debt", UIKit.money_text(int(d["debt"])), UIKit.CORAL)
	var resigned: Array = d.get("resigned", [])
	if not resigned.is_empty():
		var rc := UIKit.card()
		body.add_child(rc)
		var rv := UIKit.vbox(2)
		rc.add_child(rv)
		rv.add_child(UIKit.icon_label("warning", "Resignations", 18, UIKit.BAD, true, 24))
		for who in resigned:
			rv.add_child(UIKit.label("  %s handed in their notice and won't be back tomorrow." % who, 15, UIKit.TEXT))
	if d["bankrupt"]:
		body.add_child(UIKit.label("Your cash is below %s. The bank is calling in your debts..." % UIKit.money_text(-GameState.DEBT_LIMIT), 18, UIKit.BAD, true))
	elif d["warn"]:
		body.add_child(UIKit.label("WARNING: deep in the red. Below %s means bankruptcy!" % UIKit.money_text(-GameState.DEBT_LIMIT), 17, UIKit.BAD, true))
	body.add_child(UIKit.button("Start next day (autosave)", _next_day, 0, UIKit.GOOD))
	return m["root"]


func trivia(q: Dictionary) -> Control:
	var m := _modal("School Field Trip Trivia", 720, 0, false)
	var body: VBoxContainer = m["body"]
	body.add_child(UIKit.label("The class gathers around you, notebooks ready...", 16, UIKit.MUTED))
	body.add_child(UIKit.label(q["q"], 21, UIKit.TEXT, true))
	for o in q["options"]:
		body.add_child(UIKit.button(o, _answer.bind(o, q["answer"]), 0))
	return m["root"]


func _answer(a: String, correct: String) -> void:
	if a == correct:
		GameState.up += 1
		Audio.sfx("cheer")
		Events.say("Correct! The kids cheer. +1 Upgrade Point", UIKit.GOLD)
	else:
		Audio.sfx("error")
		Events.say("Not quite - the answer was %s. (Check the Field Guide!)" % correct, UIKit.CORAL)
	GameState.changed.emit()
	ui.close_panel()


## Guided school tour: pick what to tell the class about this exhibit.
func tour_panel(q: Dictionary) -> Control:
	var m := _modal("Guided Tour", 760, 0, false)
	var body: VBoxContainer = m["body"]
	var l := UIKit.label("The class gathers round the %s. %s and the children look at you expectantly. What do you tell them?" % [q["what"], q["teacher"]], 17, UIKit.TEXT, true)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(700, 0)
	body.add_child(l)
	for o in q["options"]:
		var b := UIKit.button(String(o), _tour_pick.bind(int(q["obj"]), String(o) == String(q["answer"])), 700)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(700, 58)
		body.add_child(b)
	var tip := UIKit.label("Not sure? Close this with the Field Guide in mind - you can come back.", 14, UIKit.MUTED)
	body.add_child(tip)
	body.add_child(UIKit.button("Not yet (check the Field Guide first)", ui.close_panel, 0, UIKit.CORAL))
	return m["root"]


func _tour_pick(obj_id: int, ok: bool) -> void:
	ui.close_panel()
	var dc := world().day_cycle
	if dc.tour and is_instance_valid(dc.tour):
		dc.tour.answer(obj_id, ok)


func choice(d: Dictionary) -> Control:
	var m := _modal(d.get("title", "Choose"), 700, 0, false)
	var body: VBoxContainer = m["body"]
	body.add_child(UIKit.label(d.get("text", ""), 17))
	var h := UIKit.hbox(8)
	body.add_child(h)
	for o in d.get("options", []):
		h.add_child(UIKit.button(o[0], _choice_pick.bind(o[1]), 0))
	return m["root"]


func _choice_pick(cb: Variant) -> void:
	ui.close_panel()
	if cb is Callable and (cb as Callable).is_valid():
		(cb as Callable).call()

# ------------------------------------------------------------------ pause ---
## Pause: the close X sits in the very top-LEFT corner of the panel and the
## "Paused" ribbon is centred at the top. Saving works in every phase.
func pause() -> Control:
	var m := _modal("Paused", 500, 0)
	var body: VBoxContainer = m["body"]
	var header: HBoxContainer = (m["root"] as Control).get_node("Center/Panel/Layout/Header")
	var close: TextureButton = header.get_node("Close")
	header.remove_child(close)
	var panel: PanelContainer = m["panel"]
	# the X lives on the full-screen modal root and is pinned to the panel frame's
	# very top-left corner whenever the panel is laid out / resized
	(m["root"] as Control).add_child(close)
	close.size = Vector2(46, 46)
	var pin := func() -> void:
		if is_instance_valid(close) and is_instance_valid(panel):
			close.global_position = panel.global_position + Vector2(6, 6)
	panel.item_rect_changed.connect(pin)
	pin.call_deferred()
	header.get_node("SpacerRight").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(UIKit.label("Day %d  |  %s  |  %s" % [GameState.day, UIKit.money_text(GameState.money), GameState.star_text()], 17, UIKit.MUTED))
	body.add_child(UIKit.button("Resume", ui.close_panel, 420, UIKit.GOOD, "check"))
	body.add_child(UIKit.button("Ledger & Finances", _open_finances, 420, Color.TRANSPARENT, "coin"))
	body.add_child(UIKit.button("Settings", _open_settings, 420, Color.TRANSPARENT, "gear"))
	body.add_child(UIKit.button("Save Game", _save, 420, UIKit.GOLD, "save"))
	if GameState.phase != GameState.Phase.PREP:
		var nl := UIKit.label("Saving now ends today early: loading this save starts the next morning, keeping what you earned.", 14, UIKit.MUTED)
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nl.custom_minimum_size = Vector2(420, 0)
		body.add_child(nl)
	body.add_child(UIKit.button("Quit to Main Menu", _to_menu, 420, UIKit.CORAL, "calendar"))
	body.add_child(UIKit.button("Quit Game", _quit, 420, UIKit.CORAL, "warning"))
	return m["root"]


func _save() -> void:
	if SaveManager.save():
		Events.say("Game saved to slot %d." % (GameState.slot + 1), UIKit.GOOD)
	ui.close_panel()


func _to_menu() -> void:
	if GameState.phase == GameState.Phase.PREP:
		SaveManager.save()
	ui.get_tree().paused = false
	ui.get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func gameover(reason: String) -> Control:
	var m := _modal("Bankrupt!", 640, 0, false)
	var body: VBoxContainer = m["body"]
	body.add_child(UIKit.label(reason, 18, UIKit.BAD, true))
	body.add_child(UIKit.label("Day %d  |  %d visitors served  |  %d species discovered" % [GameState.day, int(GameState.stats["visitors"]), GameState.discovered.size()], 16, UIKit.MUTED))
	body.add_child(UIKit.button("Load last save", _load_last, 0, UIKit.GOOD))
	body.add_child(UIKit.button("Main Menu", _to_menu, 0, UIKit.CORAL))
	return m["root"]

# ---------------------------------------------------------------- helpers ---
func _open_lab_again() -> void:
	ui.open("lab")


func _remove_fossil(o: PlacedObject) -> void:
	o.unmount_fossil()
	ui.reopen(o)


func _clear_podium(o: PlacedObject) -> void:
	o.release_contents()
	o.refresh_display()
	Events.museum_changed.emit()
	ui.reopen(o)


func _reprimand(s: Staff) -> void:
	s.reprimand()
	ui.close_panel()


func _fire_close(s: Staff) -> void:
	world().day_cycle.fire(s)
	ui.close_panel()


func _to_ledger() -> void:
	ui.close_panel()
	world().day_cycle.to_ledger()


func _next_day() -> void:
	ui.close_panel()
	world().day_cycle.next_day()


func _open_finances() -> void:
	ui.open("management", "Finances")


func _open_settings() -> void:
	ui.open("settings")


func _quit() -> void:
	ui.get_tree().quit()


func _load_last() -> void:
	if SaveManager.load_slot(GameState.slot):
		ui.get_tree().paused = false
		ui.get_tree().change_scene_to_file("res://scenes/world.tscn")
