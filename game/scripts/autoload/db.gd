extends Node
## Static game data: items, species, drop tables, tools, skill tree, buildables,
## staff, guest archetypes and review text. Everything tunable lives here.

const ERAS := ["Cenozoic", "Mesozoic", "Paleozoic"]
const DIETS := ["Carnivore", "Piscivore", "Herbivore", "Filter Feeder", "Detritivore", "Insectivore"]
const HABITATS := ["Open Ocean", "Shallow Seafloor", "Shallow Reef", "Coastal Shore", "Brackish Lagoon", "Land"]
const RARITY_VALUE := {"common": 4, "uncommon": 7, "rare": 12, "epic": 22}
const CELL := 2.0
const MUSEUM_SIZES := [Vector2i(5, 4), Vector2i(7, 5), Vector2i(9, 6), Vector2i(11, 7)]
const EXPANSION_COST := [0, 500, 1500, 3500]
const MUSEUM_FRONT_Z := -22.0

var RARITY_COLOR := {"common": Color("d9d4c7"), "uncommon": Color("7fd18b"), "rare": Color("6fb7ff"), "epic": Color("ffb347")}

# ------------------------------------------------------------ gems & ores ---
var GEMS := {
	"sea_glass": {"name": "Sea Glass", "value": 3, "model": "gem", "color": Color("8fe3c4")},
	"quartz": {"name": "Quartz Crystal", "value": 6, "model": "gem", "color": Color("f2f0ff")},
	"copper": {"name": "Copper Ore", "value": 8, "model": "ore", "color": Color("d9824a")},
	"iron": {"name": "Iron Ore", "value": 10, "model": "ore", "color": Color("9a5a4a")},
	"jasper": {"name": "Ocean Jasper", "value": 14, "model": "gem", "color": Color("6fbf8f")},
	"silver": {"name": "Silver Ore", "value": 26, "model": "ore", "color": Color("e6eef5")},
	"opal": {"name": "Fire Opal", "value": 45, "model": "gem", "color": Color("ff7a4a")},
	"gold": {"name": "Gold Nugget", "value": 65, "model": "ore", "color": Color("ffd23f")},
	"sapphire": {"name": "Sapphire", "value": 90, "model": "gem", "color": Color("3f6fff")},
}
const GEODE_VALUE := 20
const GEODE_CRACK_PRICE := 45

# ---------------------------------------------------------------- species ---
var PIECE_NAMES := {"skull": "Skull", "jaw": "Lower Jaw", "neck": "Neck Vertebrae", "back": "Dorsal Vertebrae",
	"ribs": "Ribcage", "flippers": "Paddles", "fore": "Fore Flipper", "hind": "Hind Flipper", "tail": "Tail Vertebrae"}
var PIECE_NODES := {"skull": "Skull", "jaw": "Jaw", "neck": "Neck", "back": "Back", "ribs": "Ribs",
	"flippers": "Flippers", "fore": "ForeFlipper", "hind": "HindFlipper", "tail": "Tail"}

var SPECIES := {
	"sand_dollar": {"name": "Fossil Sand Dollar", "sci": "Dendraster sp.", "era": "Cenozoic", "period": "Pliocene - Pleistocene (5 - 0.01 million years ago)",
		"diet": "Detritivore", "habitat": "Shallow Seafloor", "rarity": "common", "model": "sand_dollar", "color": Color("d8c7a0"), "shape": "disc",
		"size": "About the width of your palm (7 cm).",
		"fact": "Sand dollars are flattened sea urchins. The five-petal pattern on top marks where rows of tube feet poked out to breathe. They sift tiny food particles out of the sand."},
	"turritella": {"name": "Turritella Snail", "sci": "Turritella sp.", "era": "Cenozoic", "period": "Eocene (about 50 million years ago)",
		"diet": "Filter Feeder", "habitat": "Shallow Seafloor", "rarity": "common", "model": "snail_shell", "color": Color("d9b98a"), "shape": "cone",
		"size": "As long as your finger (6 cm).",
		"fact": "These tall spiral snails strained food from the water instead of grazing. In some Eocene rocks they are so abundant that they form entire shell beds."},
	"shark_tooth": {"name": "Sand Tiger Shark Tooth", "sci": "Carcharias sp.", "era": "Cenozoic", "period": "Eocene - Present",
		"diet": "Piscivore", "habitat": "Coastal Shore", "rarity": "uncommon", "model": "tooth", "color": Color("4a4a50"), "shape": "tooth",
		"size": "About the length of a paperclip (3 cm).",
		"fact": "Sharks shed and replace teeth constantly - thousands over a lifetime - which is why fossil shark teeth are the most common vertebrate fossils on beaches."},
	"megalodon": {"name": "Megalodon Tooth", "sci": "Otodus megalodon", "era": "Cenozoic", "period": "Miocene - Pliocene (23 - 3.6 million years ago)",
		"diet": "Carnivore", "habitat": "Open Ocean", "rarity": "rare", "model": "tooth", "color": Color("2f3036"), "shape": "tooth", "scale": 1.7,
		"size": "Teeth up to 18 cm - bigger than your hand. The shark was roughly as long as a bus.",
		"fact": "Megalodon was one of the largest predators that ever lived, estimated at around 15 - 20 m long. Bite marks on fossil whale bones show it hunted whales."},
	"mammoth": {"name": "Woolly Mammoth Molar", "sci": "Mammuthus primigenius", "era": "Cenozoic", "period": "Pleistocene (Ice Age)",
		"diet": "Herbivore", "habitat": "Land", "rarity": "rare", "model": "bone", "color": Color("8a7a5a"), "shape": "bone", "scale": 1.3,
		"size": "A single molar is as big as a shoebox and weighs about 2 kg.",
		"fact": "Fishing trawlers still drag mammoth teeth up from the North Sea floor: during the Ice Age it was dry grassland. The ridged enamel plates ground tough grasses."},
	"ammonite": {"name": "Ammonite", "sci": "Dactylioceras commune", "era": "Mesozoic", "period": "Early Jurassic (about 180 million years ago)",
		"diet": "Carnivore", "habitat": "Open Ocean", "rarity": "common", "model": "ammonite", "color": Color("b98a5a"), "shape": "spiral",
		"size": "About the size of a cookie (6 cm).",
		"fact": "Ammonites were squid-like animals living in coiled shells. Gas-filled chambers, regulated through a tube called the siphuncle, let them float like a submarine."},
	"belemnite": {"name": "Belemnite Guard", "sci": "Passaloteuthis sp.", "era": "Mesozoic", "period": "Early Jurassic",
		"diet": "Carnivore", "habitat": "Open Ocean", "rarity": "common", "model": "tooth", "color": Color("c98a4a"), "shape": "tooth",
		"size": "Bullet-sized (8 cm).",
		"fact": "The bullet-shaped fossil is the guard: a heavy internal counterweight of a squid-like animal. Some belemnites are found with their fossil ink sacs still intact."},
	"gryphaea": {"name": "Devil's Toenail", "sci": "Gryphaea arcuata", "era": "Mesozoic", "period": "Early Jurassic",
		"diet": "Filter Feeder", "habitat": "Shallow Seafloor", "rarity": "common", "model": "snail_shell", "color": Color("8f8a80"), "shape": "cone",
		"size": "About the size of a toe (5 cm).",
		"fact": "A curled oyster that lay on soft muddy seafloors. Its gnarly shape gave rise to the folk name 'Devil's toenail'."},
	"ichthyosaurus": {"name": "Ichthyosaurus", "sci": "Ichthyosaurus communis", "era": "Mesozoic", "period": "Early Jurassic (200 - 190 million years ago)",
		"diet": "Piscivore", "habitat": "Open Ocean", "rarity": "rare", "model": "bone", "color": Color("efe3c4"), "shape": "skull",
		"skeleton": "skeleton_ichthyosaur", "pieces": ["skull", "back", "ribs", "flippers", "tail"],
		"size": "About 2 - 3 m long - like a dolphin.",
		"fact": "Ichthyosaurs were dolphin-shaped marine reptiles that gave birth to live young at sea. Joseph and Mary Anning found the first skeleton recognised by science on the English coast in 1811 - 12."},
	"plesiosaurus": {"name": "Plesiosaur Paddle Bone", "sci": "Plesiosaurus dolichodeirus", "era": "Mesozoic", "period": "Early Jurassic",
		"diet": "Piscivore", "habitat": "Open Ocean", "rarity": "uncommon", "model": "bone", "color": Color("d9c39a"), "shape": "bone",
		"size": "The whole animal was about 3.5 m - longer than a car.",
		"fact": "Long-necked plesiosaurs 'flew' underwater with four paddle-shaped flippers. Mary Anning found the first nearly complete skeleton in 1823."},
	"dimorphodon": {"name": "Dimorphodon Wing Bone", "sci": "Dimorphodon macronyx", "era": "Mesozoic", "period": "Early Jurassic",
		"diet": "Insectivore", "habitat": "Coastal Shore", "rarity": "uncommon", "model": "bone", "color": Color("e6d4b0"), "shape": "bone", "scale": 0.7,
		"size": "Wingspan about 1.4 m - like a large gull.",
		"fact": "A pterosaur with an oversized, puffin-like head. Mary Anning found one of the first specimens in 1828. It probably snapped up insects and small animals."},
	"mosasaurus": {"name": "Mosasaurus", "sci": "Mosasaurus hoffmannii", "era": "Mesozoic", "period": "Late Cretaceous (82 - 66 million years ago)",
		"diet": "Carnivore", "habitat": "Open Ocean", "rarity": "rare", "model": "bone", "color": Color("c9a77a"), "shape": "skull",
		"skeleton": "skeleton_mosasaur", "pieces": ["skull", "jaw", "back", "ribs", "flippers", "tail"],
		"size": "Up to about 12 m - as long as a city bus.",
		"fact": "Mosasaurs were giant marine lizards, cousins of today's monitor lizards and snakes. The first known skull was dug from a quarry near Maastricht in the Netherlands around 1764."},
	"apex": {"name": "Pelagotyrannus (The Cove Tyrant)", "sci": "Pelagotyrannus covensis", "era": "Mesozoic", "period": "Late Jurassic",
		"diet": "Carnivore", "habitat": "Open Ocean", "rarity": "epic", "model": "bone", "color": Color("ddd2bd"), "shape": "skull",
		"skeleton": "skeleton_apex", "pieces": ["skull", "jaw", "neck", "back", "ribs", "fore", "hind", "tail"], "fictional": true,
		"size": "Estimated 15 m - longer than three cars nose to tail.",
		"fact": "Unknown to science until you dug it up. This apex marine reptile exists only in the strata of Ammonite Bay. Its bite marks appear on ichthyosaur bones all along the cliffs. (In-game species - not a real animal.)"},
	"amber": {"name": "Insect in Amber", "sci": "Termite in Baltic amber", "era": "Cenozoic", "period": "Eocene (about 44 million years ago)",
		"diet": "Detritivore", "habitat": "Land", "rarity": "uncommon", "model": "amber", "color": Color("f2a23a"), "shape": "disc",
		"size": "A honey-coloured drop about the size of a walnut (3 cm); the termite inside is 6 mm long.",
		"fact": "Amber is fossilised tree resin, not a gemstone. Sticky sap trapped this termite about 44 million years ago and slowly hardened, preserving it in 3D right down to the hairs on its legs."},
	"trilobite": {"name": "Trilobite", "sci": "Calymene blumenbachii", "era": "Paleozoic", "period": "Silurian (about 430 million years ago)",
		"diet": "Detritivore", "habitat": "Shallow Reef", "rarity": "common", "model": "trilobite", "color": Color("8a7f74"), "shape": "trilobite",
		"size": "About the size of a matchbox (5 cm).",
		"fact": "Nicknamed the 'Dudley Bug', it could roll into a ball like a woodlouse. Trilobites had some of the earliest complex eyes, with lenses made of the mineral calcite."},
	"crinoid": {"name": "Crinoid (Sea Lily)", "sci": "Crinoidea", "era": "Paleozoic", "period": "Carboniferous (about 340 million years ago)",
		"diet": "Filter Feeder", "habitat": "Shallow Reef", "rarity": "common", "model": "crinoid", "color": Color("b8a890"), "shape": "stem",
		"size": "Stems could grow taller than a person.",
		"fact": "Despite looking like plants, crinoids are animals related to starfish. Their disc-shaped stem pieces were once strung as 'St Cuthbert's beads'."},
	"brachiopod": {"name": "Brachiopod", "sci": "Spirifer sp.", "era": "Paleozoic", "period": "Carboniferous",
		"diet": "Filter Feeder", "habitat": "Shallow Seafloor", "rarity": "common", "model": "sand_dollar", "color": Color("a8977c"), "shape": "disc",
		"size": "About the size of a coin (3 cm).",
		"fact": "Brachiopods look like clams but belong to a separate group of animals. Spirifer means 'spiral-bearer', after the coiled internal supports of its feeding organ."},
	"orthoceras": {"name": "Orthoceras", "sci": "Orthoceras regulare", "era": "Paleozoic", "period": "Ordovician (about 470 million years ago)",
		"diet": "Carnivore", "habitat": "Open Ocean", "rarity": "uncommon", "model": "snail_shell", "color": Color("5e5a58"), "shape": "cone", "scale": 1.3,
		"size": "Shells about 15 cm long - like a pencil.",
		"fact": "A straight-shelled relative of the nautilus. Swedish 'Orthoceras limestone', packed with these shells, has been used as a building stone for centuries."},
	"eurypterus": {"name": "Sea Scorpion", "sci": "Eurypterus remipes", "era": "Paleozoic", "period": "Silurian (about 420 million years ago)",
		"diet": "Carnivore", "habitat": "Brackish Lagoon", "rarity": "rare", "model": "trilobite", "color": Color("6a4a3a"), "shape": "trilobite", "scale": 1.5,
		"size": "About 20 cm - but some relatives grew longer than 2 m.",
		"fact": "Eurypterids were arthropods related to horseshoe crabs and scorpions. Eurypterus remipes is the state fossil of New York."},
	"dunkleosteus": {"name": "Dunkleosteus Jaw Plate", "sci": "Dunkleosteus terrelli", "era": "Paleozoic", "period": "Late Devonian (372 - 359 million years ago)",
		"diet": "Carnivore", "habitat": "Open Ocean", "rarity": "epic", "model": "tooth", "color": Color("3a3a3e"), "shape": "tooth", "scale": 2.0,
		"size": "Around 4 m long - about the size of a small car.",
		"fact": "An armoured fish with self-sharpening bony blades instead of teeth, and one of the most powerful bites of any fish ever."},
}

var LIVING := {
	"horseshoe_crab": {"name": "Atlantic Horseshoe Crab", "sci": "Limulus polyphemus",
		"fact": "Horseshoe crabs belong to a lineage around 450 million years old. Their blood is blue because it carries oxygen with copper instead of iron."},
	"nautilus": {"name": "Chambered Nautilus", "sci": "Nautilus pompilius",
		"fact": "The last living cephalopods with an external chambered shell, distant cousins of the extinct ammonites. They adjust buoyancy by moving fluid in and out of their chambers."},
}

# ----------------------------------------------------------- zones & nodes --
var ZONES := [
	{"id": "shore", "name": "Driftwood Shore", "era": "Cenozoic", "skill": "", "x0": -25.0, "x1": 25.0, "cliff": "cliff_ceno"},
	{"id": "cliffs", "name": "Ammonite Cliffs", "era": "Mesozoic", "skill": "zone_cliffs", "x0": 25.0, "x1": 65.0, "cliff": "cliff_meso"},
	{"id": "caves", "name": "Sea Caves", "era": "Mesozoic", "skill": "zone_caves", "x0": 65.0, "x1": 105.0, "cliff": "cliff_meso"},
	{"id": "reef", "name": "Paleozoic Shelf", "era": "Paleozoic", "skill": "zone_reef", "x0": -70.0, "x1": -25.0, "cliff": "cliff_paleo"},
]
const BEACH_Z0 := -10.0
const BEACH_Z1 := 44.0

var NODE_TYPES := {
	"sand": {"name": "Sand Patch", "tool": "shovel", "tier": 1, "time": 1.1, "model": "node_sand", "sfx": "dig_sand", "drops": [1, 2]},
	"dirt": {"name": "Dirt Mound", "tool": "shovel", "tier": 1, "time": 1.6, "model": "node_dirt", "sfx": "dig_sand", "drops": [1, 2]},
	"buried": {"name": "Buried Find", "tool": "shovel", "tier": 1, "time": 1.8, "model": "node_buried", "sfx": "dig_sand", "drops": [1, 1]},
	"cracked": {"name": "Cracked Rock", "tool": "pick", "tier": 1, "time": 2.0, "model": "node_cracked_rock", "sfx": "dig_rock", "drops": [1, 2]},
	"hard": {"name": "Crystal Boulder", "tool": "pick", "tier": 2, "time": 2.4, "model": "node_hard_rock", "sfx": "dig_rock", "drops": [1, 3]},
	"deep": {"name": "Slate Outcrop", "tool": "pick", "tier": 3, "time": 2.8, "model": "node_deep_rock", "sfx": "dig_rock", "drops": [2, 3]},
}
var ZONE_NODES := {
	"shore": {"sand": 11, "dirt": 6, "buried": 3},
	"cliffs": {"sand": 5, "cracked": 9, "buried": 4},
	"caves": {"cracked": 5, "hard": 8, "buried": 6},
	"reef": {"hard": 5, "deep": 9, "buried": 4},
}
var DROPS := {
	"shore": {
		"sand": [[30, "gem:sea_glass"], [18, "gem:quartz"], [8, "gem:copper"], [5, "geode"], [14, "fossil:sand_dollar"], [12, "fossil:turritella"], [9, "fossil:shark_tooth"]],
		"dirt": [[22, "gem:copper"], [16, "gem:quartz"], [10, "gem:iron"], [6, "fossil:amber"], [6, "geode"], [12, "fossil:turritella"], [10, "fossil:shark_tooth"], [8, "fossil:sand_dollar"], [4, "fossil:mammoth"]],
		"buried": [[30, "fossil:megalodon"], [25, "fossil:mammoth"], [25, "fossil:amber"], [20, "fossil:shark_tooth"]],
	},
	"cliffs": {
		"sand": [[20, "gem:quartz"], [14, "gem:jasper"], [16, "fossil:belemnite"], [14, "fossil:gryphaea"], [14, "fossil:ammonite"], [6, "geode"]],
		"cracked": [[20, "fossil:ammonite"], [10, "fossil:belemnite"], [8, "fossil:gryphaea"], [6, "fossil:dimorphodon"], [6, "fossil:plesiosaurus"], [16, "piece:ichthyosaurus"], [10, "gem:iron"], [10, "gem:jasper"], [5, "fossil:amber"], [6, "geode"]],
		"buried": [[45, "piece:ichthyosaurus"], [20, "fossil:plesiosaurus"], [20, "fossil:dimorphodon"], [15, "fossil:amber"]],
	},
	"caves": {
		"cracked": [[18, "fossil:ammonite"], [14, "piece:mosasaurus"], [14, "gem:iron"], [12, "gem:silver"], [8, "geode"], [8, "fossil:belemnite"]],
		"hard": [[26, "piece:mosasaurus"], [16, "gem:silver"], [10, "gem:opal"], [8, "gem:gold"], [8, "gem:iron"], [8, "geode"]],
		"buried": [[70, "piece:apex"], [30, "piece:mosasaurus"]],
	},
	"reef": {
		"hard": [[14, "fossil:trilobite"], [12, "fossil:crinoid"], [12, "gem:silver"], [10, "gem:gold"], [8, "gem:sapphire"], [8, "geode"]],
		"deep": [[20, "fossil:trilobite"], [15, "fossil:crinoid"], [14, "fossil:brachiopod"], [10, "fossil:orthoceras"], [6, "fossil:eurypterus"], [4, "fossil:dunkleosteus"], [8, "gem:sapphire"], [8, "gem:gold"], [6, "geode"]],
		"buried": [[35, "fossil:dunkleosteus"], [35, "fossil:eurypterus"], [30, "gem:sapphire"]],
	},
}

# ------------------------------------------------------------------ tools ---
var TOOLS := {
	"shovel_1": {"name": "Rusty Shovel", "kind": "shovel", "tier": 1, "speed": 1.0, "cost": 0, "req": "", "color": Color("a0522d"), "desc": "Digs sand, dirt and buried finds."},
	"shovel_2": {"name": "Steel Shovel", "kind": "shovel", "tier": 2, "speed": 1.6, "cost": 80, "req": "", "color": Color("b8c0c8"), "desc": "60% faster digging in sand and dirt."},
	"shovel_3": {"name": "Titanium Spade", "kind": "shovel", "tier": 3, "speed": 2.4, "cost": 320, "req": "equip_1", "color": Color("7fa7d9"), "desc": "Slices through sand like butter."},
	"pick_1": {"name": "Stone Pick", "kind": "pick", "tier": 1, "speed": 1.0, "cost": 50, "req": "", "color": Color("8a8478"), "desc": "Breaks cracked rock."},
	"pick_2": {"name": "Steel Pickaxe", "kind": "pick", "tier": 2, "speed": 1.5, "cost": 240, "req": "equip_1", "color": Color("b8c0c8"), "desc": "Breaks crystal boulders in the sea caves."},
	"pick_3": {"name": "Diamond Pickaxe", "kind": "pick", "tier": 3, "speed": 2.2, "cost": 800, "req": "equip_2", "color": Color("7ff0ff"), "desc": "Splits Paleozoic slate outcrops."},
	"detector_1": {"name": "Fossil Detector", "kind": "detector", "tier": 1, "radius": 9.0, "cost": 160, "req": "equip_1", "color": Color("b8c0c8"), "desc": "Pings when you walk near hidden buried fossils. Toggle with the detector key."},
	"detector_2": {"name": "Deep-Scan Detector", "kind": "detector", "tier": 2, "radius": 16.0, "cost": 550, "req": "equip_2", "color": Color("ffd23f"), "desc": "Much larger scan radius."},
	"lab_1": {"name": "Micro-Brush", "kind": "lab", "tier": 1, "cost": 0, "req": "", "color": Color("a0522d"), "desc": "Gentle. Never damages bone."},
	"lab_2": {"name": "Air Scribe", "kind": "lab", "tier": 2, "cost": 90, "req": "", "color": Color("b8c0c8"), "desc": "Chips a 3x3 area fast. Can crack exposed bone."},
	"lab_3": {"name": "Pneumatic Pro Scribe", "kind": "lab", "tier": 3, "cost": 380, "req": "equip_2", "color": Color("7ff0ff"), "desc": "Fast and precise: only the centre cell risks damage."},
}
const PLUSHIE_PACK := {"count": 5, "cost": 20}

# ------------------------------------------------------------- skill tree ---
## A real tree: every node sits on a star tier (0-5 = museum stars needed) and a
## column; `req` are its parent nodes (all must be owned). `cost` is Upgrade Points,
## `cash` an optional extra price in dollars. Some parents unlock several children.
var SKILLS := {
	# Expedition
	"backpack_1": {"name": "Bigger Backpack I", "cost": 1, "cash": 0, "req": [], "tier": 0, "x": 0, "icon": "backpack", "desc": "+4 backpack slots."},
	"backpack_2": {"name": "Bigger Backpack II", "cost": 2, "cash": 60, "req": ["backpack_1"], "tier": 1, "x": 0, "icon": "backpack", "desc": "+4 backpack slots."},
	"backpack_3": {"name": "Bigger Backpack III", "cost": 3, "cash": 150, "req": ["backpack_2"], "tier": 2, "x": 0, "icon": "backpack", "desc": "+4 backpack slots."},
	"zone_cliffs": {"name": "Ammonite Cliffs Permit", "cost": 2, "cash": 0, "req": [], "tier": 0, "x": 1, "icon": "ammonite", "desc": "Open the Mesozoic cliffs east of the museum: ammonites and ichthyosaur bones."},
	"zone_caves": {"name": "Sea Caves Permit", "cost": 3, "cash": 250, "req": ["zone_cliffs"], "tier": 1, "x": 1, "icon": "ammonite", "desc": "Open the coastal sea caves. Something big is buried in there..."},
	"zone_reef": {"name": "Paleozoic Shelf Permit", "cost": 5, "cash": 600, "req": ["zone_caves"], "tier": 2, "x": 1, "icon": "ammonite", "desc": "Open the ancient slate shelf to the west: trilobites and armoured fish."},
	"speed_1": {"name": "Beach Legs I", "cost": 1, "cash": 0, "req": [], "tier": 0, "x": 2, "icon": "happy", "desc": "+12% walk and sprint speed."},
	"speed_2": {"name": "Beach Legs II", "cost": 2, "cash": 0, "req": ["speed_1"], "tier": 1, "x": 2, "icon": "happy", "desc": "+12% walk and sprint speed."},
	"speed_3": {"name": "Beach Legs III", "cost": 3, "cash": 120, "req": ["speed_2"], "tier": 3, "x": 2, "icon": "happy", "desc": "+12% walk and sprint speed."},
	# Museum
	"ticket_1": {"name": "Marketing I", "cost": 1, "cash": 0, "req": [], "tier": 0, "x": 4, "icon": "ticket", "desc": "+$2 base ticket price. Opens the Museum branch."},
	"ticket_2": {"name": "Marketing II", "cost": 2, "cash": 0, "req": ["ticket_1"], "tier": 1, "x": 3, "icon": "ticket", "desc": "+$3 base ticket price."},
	"lic_food": {"name": "Food Vendor License", "cost": 1, "cash": 50, "req": ["ticket_1"], "tier": 1, "x": 4, "icon": "coin", "desc": "Build Dino-Dog, Fossil Popcorn and Amber Lemonade stands. You serve the queue yourself!"},
	"lic_podium": {"name": "Mega-Skeleton Podiums", "cost": 2, "cash": 200, "req": ["ticket_1"], "tier": 1, "x": 5, "icon": "bone", "desc": "Build podiums that assemble 5-8 bone finds into towering skeletons."},
	"ticket_3": {"name": "Marketing III", "cost": 3, "cash": 0, "req": ["ticket_2"], "tier": 2, "x": 3, "icon": "ticket", "desc": "+$4 base ticket price."},
	"expand_1": {"name": "Expansion Permit I", "cost": 2, "cash": 500, "req": ["ticket_2", "lic_food"], "tier": 2, "x": 4, "icon": "gear", "desc": "Allows buying a 7x5 museum floor in Build Mode."},
	"lic_aquarium": {"name": "Living Fossil Aquariums", "cost": 3, "cash": 400, "req": ["lic_podium"], "tier": 3, "x": 5, "icon": "heart", "desc": "Build saltwater tanks with horseshoe crabs and nautiluses. Guests pay to feed them."},
	"expand_2": {"name": "Expansion Permit II", "cost": 4, "cash": 1200, "req": ["expand_1"], "tier": 3, "x": 4, "icon": "gear", "desc": "Allows buying a 9x6 museum floor."},
	"ticket_4": {"name": "Marketing IV", "cost": 4, "cash": 0, "req": ["ticket_3"], "tier": 4, "x": 3, "icon": "ticket", "desc": "+$6 base ticket price."},
	"lic_holo": {"name": "Prehistoric Holo-Theater", "cost": 5, "cash": 1500, "req": ["lic_aquarium"], "tier": 4, "x": 5, "icon": "star", "desc": "High-end projection rings. Huge fun, longer visits. Best beside a complete skeleton."},
	"expand_3": {"name": "Expansion Permit III", "cost": 6, "cash": 3000, "req": ["expand_2"], "tier": 5, "x": 4, "icon": "gear", "desc": "Allows buying an 11x7 museum floor."},
	# Trade & gear
	"equip_1": {"name": "Better Equipment I", "cost": 2, "cash": 0, "req": [], "tier": 0, "x": 6, "icon": "pickaxe", "desc": "Pearl stocks steel pickaxes, titanium spades and fossil detectors."},
	"haggle": {"name": "Gem Haggling", "cost": 2, "cash": 0, "req": [], "tier": 0, "x": 7, "icon": "gem", "desc": "+20% cash when selling gems and ores at the shop."},
	"detector_range": {"name": "Keen Ears", "cost": 2, "cash": 80, "req": ["equip_1"], "tier": 1, "x": 6, "icon": "walkie", "desc": "+40% fossil detector radius."},
	"souvenir": {"name": "Souvenir Markup", "cost": 2, "cash": 0, "req": ["haggle"], "tier": 2, "x": 7, "icon": "coin", "desc": "+25% gift shop income."},
	"equip_2": {"name": "Better Equipment II", "cost": 4, "cash": 300, "req": ["equip_1"], "tier": 3, "x": 6, "icon": "pickaxe", "desc": "Pearl stocks diamond pickaxes, deep-scan detectors and pro scribes."},
	# Staff: one +1 slot per star from 2 stars on; each job is its own licence
	"job_vendor": {"name": "Job: Snack Vendor", "cost": 2, "cash": 80, "req": [], "tier": 1, "x": 8, "icon": "coin", "desc": "Lets you hire Snack Vendors: they walk to whichever snack stand has a queue and serve the guests for you. Needs a staff slot (2 stars) and the Food Vendor License to be useful."},
	"job_janitor": {"name": "Job: Janitor", "cost": 1, "cash": 0, "req": [], "tier": 1, "x": 9, "icon": "broom", "desc": "Lets you hire Janitors (sweep trash and sand, empty bins, clean restrooms). You still need a staff slot (2 stars)."},
	"staff_slot_1": {"name": "Staff Slot +1", "cost": 2, "cash": 0, "req": [], "tier": 2, "x": 8, "icon": "staff", "desc": "+1 max employee. You start with none."},
	"job_security": {"name": "Job: Security Guard", "cost": 2, "cash": 100, "req": ["job_janitor"], "tier": 2, "x": 9, "icon": "warning", "desc": "Lets you hire Security Guards: they catch shoplifters and spies, stop climbers and calm tantrums."},
	"staff_slot_2": {"name": "Staff Slot +1 (II)", "cost": 3, "cash": 150, "req": ["staff_slot_1"], "tier": 3, "x": 8, "icon": "staff", "desc": "+1 max employee."},
	"job_intern": {"name": "Job: Paleontology Intern", "cost": 3, "cash": 150, "req": ["job_security"], "tier": 3, "x": 9, "icon": "research", "desc": "Lets you hire Interns: they correct every plaque each morning and impress enthusiasts."},
	"staff_slot_3": {"name": "Staff Slot +1 (III)", "cost": 3, "cash": 300, "req": ["staff_slot_2"], "tier": 4, "x": 8, "icon": "staff", "desc": "+1 max employee."},
	"staff_training": {"name": "Staff Training", "cost": 2, "cash": 200, "req": ["staff_slot_1", "job_janitor"], "tier": 4, "x": 9, "icon": "heart", "desc": "Staff go rogue half as often and lose morale more slowly."},
	"staff_slot_4": {"name": "Staff Slot +1 (IV)", "cost": 4, "cash": 500, "req": ["staff_slot_3"], "tier": 5, "x": 8, "icon": "staff", "desc": "+1 max employee."},
	# Hotbar: one extra slot per star
	"hotbar_1": {"name": "Tool Belt +1", "cost": 1, "cash": 30, "req": [], "tier": 1, "x": 10, "icon": "shovel", "desc": "+1 hotbar slot (start with 3)."},
	"hotbar_2": {"name": "Tool Belt +1 (II)", "cost": 2, "cash": 80, "req": ["hotbar_1"], "tier": 2, "x": 10, "icon": "shovel", "desc": "+1 hotbar slot."},
	"hotbar_3": {"name": "Tool Belt +1 (III)", "cost": 2, "cash": 150, "req": ["hotbar_2"], "tier": 3, "x": 10, "icon": "shovel", "desc": "+1 hotbar slot."},
	"hotbar_4": {"name": "Tool Belt +1 (IV)", "cost": 3, "cash": 250, "req": ["hotbar_3"], "tier": 4, "x": 10, "icon": "shovel", "desc": "+1 hotbar slot."},
	"hotbar_5": {"name": "Tool Belt +1 (V)", "cost": 3, "cash": 400, "req": ["hotbar_4"], "tier": 5, "x": 10, "icon": "shovel", "desc": "+1 hotbar slot."},
}
const SKILL_BRANCHES := [["Expedition", 0, 2], ["Museum", 3, 5], ["Trade & Gear", 6, 7], ["Staff", 8, 9], ["Hotbar", 10, 10]]
const SKILL_COLUMNS := 11
const QUIT_LINES := ["I'm outta here!", "I didn't sign up for this!", "My cousin's crab shack is hiring.", "Find someone else to sweep your sand!",
	"I'm going back to finger-painting trilobites.", "This museum is a fossil and so is my paycheck."]

# -------------------------------------------------------------- buildables --
## size in cells (x = width, y = depth); stars in half-star units.
var BUILD := {
	"display_case": {"name": "Fossil Display Case", "cat": "Exhibits", "cost": 40, "size": Vector2i(1, 1), "model": "display_case", "stars": 0, "lic": "", "fun": 0, "decor": 0,
		"desc": "Mount one cleaned fossil. Customise its plaque for an education bonus."},
	"plaque_checker": {"name": "Fact-Check Kiosk", "cat": "Exhibits", "cost": 30, "size": Vector2i(1, 1), "model": "plaque_checker", "stars": 0, "lic": "", "fun": 0, "decor": 1,
		"desc": "Tells you which display cases have a wrong or blank plaque (lamp turns red). Nerds tear apart museums with wrong plaques!"},
	"mega_podium": {"name": "Mega-Skeleton Podium", "cat": "Exhibits", "cost": 300, "size": Vector2i(3, 2), "model": "mega_podium", "stars": 0, "lic": "lic_podium", "fun": 0, "decor": 0,
		"desc": "Assemble 5-8 bone finds of one species into a towering skeleton."},
	"aquarium": {"name": "Living Fossil Aquarium", "cat": "Attractions", "cost": 600, "size": Vector2i(2, 1), "model": "aquarium", "stars": 0, "lic": "lic_aquarium", "fun": 16, "decor": 2,
		"desc": "Horseshoe crabs and nautiluses. Guests pay $4 for feeding."},
	"dig_pit": {"name": "Junior Dino-Dig Pit", "cat": "Attractions", "cost": 150, "size": Vector2i(2, 2), "model": "dig_pit", "stars": 1, "lic": "", "fun": 12, "decor": 0,
		"desc": "Bury duplicate fossils here. Kids pay $5 to dig and it calms tantrums."},
	"gift_shop": {"name": "Geode Cracker & Gift Shop", "cat": "Attractions", "cost": 250, "size": Vector2i(2, 1), "model": "gift_shop", "stars": 2, "lic": "", "fun": 6, "decor": 1,
		"desc": "Sells stored gems at 1.5x, cracks stored geodes for tourists and sells plushies."},
	"holo_theater": {"name": "Prehistoric Holo-Theater", "cat": "Attractions", "cost": 2000, "size": Vector2i(2, 2), "model": "holo_theater", "stars": 0, "lic": "lic_holo", "fun": 34, "decor": 3,
		"desc": "Projects animated visuals. Doubles its fun near a complete skeleton."},
	"popcorn_stand": {"name": "Fossil Popcorn Stand", "cat": "Concessions", "cost": 120, "size": Vector2i(1, 1), "model": "popcorn_stand", "stars": 0, "lic": "lic_food", "fun": 3, "decor": 0, "price": 4, "serve": "held_bag", "item": "popcorn",
		"desc": "Guests queue here. Grab a bag, fill it at the machine and serve them before they give up. Creates trash."},
	"dinodog_stand": {"name": "Dino-Dog Stand", "cat": "Concessions", "cost": 140, "size": Vector2i(1, 1), "model": "dinodog_stand", "stars": 0, "lic": "lic_food", "fun": 3, "decor": 0, "price": 5, "serve": "held_dog", "item": "Dino-Dog",
		"desc": "Guests queue here. Grab a bun, add a dog from the grill and serve them before they give up. Creates trash."},
	"lemonade_stand": {"name": "Amber Lemonade Stand", "cat": "Concessions", "cost": 100, "size": Vector2i(1, 1), "model": "lemonade_stand", "stars": 0, "lic": "lic_food", "fun": 2, "decor": 1, "price": 3, "serve": "held_cup", "item": "lemonade",
		"desc": "Guests queue here. Grab a cup, fill it from the jug and serve them. Refreshed guests stay longer."},
	"restroom": {"name": "Restroom", "cat": "Amenities", "cost": 90, "size": Vector2i(1, 1), "model": "restroom", "stars": 0, "lic": "", "fun": 0, "decor": 0,
		"desc": "Essential for cleanliness once crowds grow. Gets dirty."},
	"trash_bin": {"name": "Trash Bin", "cat": "Amenities", "cost": 15, "size": Vector2i(1, 1), "model": "trash_bin", "stars": 0, "lic": "", "fun": 0, "decor": 0,
		"desc": "Guests nearby use it instead of littering. Throw picked-up trash in it. Empty it when full."},
	"bench": {"name": "Bench", "cat": "Amenities", "cost": 25, "size": Vector2i(1, 1), "model": "bench", "stars": 0, "lic": "", "fun": 1, "decor": 2,
		"desc": "Tired guests rest here."},
	"plant_pot": {"name": "Potted Fern", "cat": "Decor", "cost": 20, "size": Vector2i(1, 1), "model": "plant_pot", "stars": 0, "lic": "", "fun": 0, "decor": 4, "desc": "Greenery."},
	"rug": {"name": "Ammonite Rug", "cat": "Decor", "cost": 25, "size": Vector2i(1, 1), "model": "rug", "stars": 0, "lic": "", "fun": 0, "decor": 3, "walkable": true, "desc": "Guests can walk on it."},
	"floor_lamp": {"name": "Brass Lamp", "cat": "Decor", "cost": 35, "size": Vector2i(1, 1), "model": "floor_lamp", "stars": 1, "lic": "", "fun": 0, "decor": 4, "desc": "Warm lighting."},
	"banner": {"name": "Museum Banner", "cat": "Decor", "cost": 30, "size": Vector2i(1, 1), "model": "banner", "stars": 1, "lic": "", "fun": 0, "decor": 4, "desc": "Teal and gold."},
	"dino_statue": {"name": "Friendly Dino Statue", "cat": "Decor", "cost": 120, "size": Vector2i(1, 1), "model": "dino_statue", "stars": 2, "lic": "", "fun": 2, "decor": 10, "desc": "Kids love it."},
}
const BUILD_CATS := ["Exhibits", "Attractions", "Concessions", "Amenities", "Decor"]

# ------------------------------------------------------------------ staff ---
var STAFF := {
	"janitor": {"name": "Janitor", "job": "job_janitor", "wage": 30, "desc": "Sweeps trash and sand, empties bins, cleans restrooms."},
	"security": {"name": "Security Guard", "job": "job_security", "wage": 45, "desc": "Catches shoplifters and spies, stops kids climbing exhibits, calms tantrums."},
	"vendor": {"name": "Snack Vendor", "job": "job_vendor", "wage": 35, "desc": "Runs your snack stands: serves every queue so guests never give up waiting."},
	"intern": {"name": "Paleontology Intern", "job": "job_intern", "wage": 40, "desc": "Corrects every plaque each morning and impresses enthusiasts."},
}
var STAFF_NAMES := ["Rosa", "Dev", "Kiki", "Marlon", "Ines", "Tobi", "Wren", "Sam", "Priya", "Otto", "Juno", "Felix", "Noor", "Bea", "Hal"]

# ----------------------------------------------------------------- guests ---
var GUESTS := {
	"tourist": {"name": "Tourist", "stars": 0},
	"kid": {"name": "Rowdy Kid", "stars": 1},
	"nerd": {"name": "Fossil Enthusiast", "stars": 2},
	"celebrity": {"name": "Celebrity", "stars": 3},
	"critic": {"name": "Museum Critic", "stars": 4},
	"shoplifter": {"name": "Shoplifter", "stars": 5},
	"spy": {"name": "Corporate Spy", "stars": 0},
	"teacher": {"name": "Teacher", "stars": 0},
	"fan": {"name": "Fan", "stars": 0},
}
var FIRST_NAMES := ["Alex", "Bo", "Cleo", "Dana", "Eli", "Fatima", "Gus", "Hana", "Ivo", "Jade", "Kofi", "Lena", "Milo", "Nia", "Oscar", "Pia",
	"Quinn", "Ravi", "Sofia", "Theo", "Uma", "Vic", "Wes", "Ximena", "Yara", "Zed", "Ana", "Ben", "Chen", "Dmitri", "Esme", "Femi"]
var CELEB_NAMES := ["DJ Trilobyte", "Coral Monroe", "Rex Sterling", "Lady Amber", "Marina Vale", "Captain Splash"]
var CRITIC_NAMES := ["V. Pemberton (Coastal Gazette)", "H. Okafor (Museum Monthly)", "L. Duval (The Fossil Review)"]

# ---------------------------------------------------------------- reviews ---
var REVIEW_GOOD := {
	"exhibits": ["Incredible fossil displays!", "The fossils here are the real deal.", "Learned so much - fabulous exhibits!"],
	"skeleton": ["That towering skeleton was worth the ticket alone!", "Stood under the skeleton for ten minutes. Wow."],
	"apex": ["THE COVE TYRANT IS REAL. I have goosebumps.", "A brand-new species, right here on the beach. Historic!"],
	"aquarium": ["Fed a horseshoe crab. Best day ever!", "The nautilus tank is mesmerising."],
	"holo": ["The holo-show made the bones come alive!", "Holo-theater + skeleton = pure magic."],
	"digpit": ["My kid found a real fossil in the dig pit!", "The dig pit kept the kids happy for hours."],
	"food": ["Dino-Dogs were delicious.", "Fossil Popcorn is my new obsession."],
	"lemonade": ["That amber lemonade hit the spot."],
	"clean": ["Spotless floors, lovely place.", "So clean you could eat off the floor."],
	"decor": ["Gorgeous decorations - so cozy!", "Beautifully decorated."],
	"plaque": ["Accurate plaques! Finally a museum that gets its eras right.", "The plaques were spot-on. Bravo, curator."],
	"owner": ["The owner personally greeted me. Classy!", "Friendliest museum owner on the coast."],
	"celebrity": ["Saw a celebrity here!! Selfie secured.", "Can't believe who I bumped into by the exhibits!"],
	"giftshop": ["Grabbed a dino plushie and a geode. Cute gift shop!"],
	"intern": ["The intern answered all my nerdy questions!"],
	"served": ["Quick, friendly service at the snack stand!", "Got my lemonade in seconds - lovely service."],
}
var REVIEW_BAD := {
	"dirty": ["Attractions were filthy!", "Trash everywhere. Gross.", "Has nobody heard of a broom?"],
	"sand": ["Sand all over the floor..."],
	"no_restroom": ["No restroom?! Unacceptable."],
	"restroom_dirty": ["The restroom was a disaster."],
	"assault": ["The owner drop-kicked me near the {place}!", "The owner bullied me!", "I got ragdolled by the owner. 0/10 would not recommend."],
	"witness": ["Saw the owner body-slam someone. Yikes.", "Violence in a museum? Not the vibe."],
	"rude_staff": ["A staff member was rude to me.", "The security guard yelled at my grandma!"],
	"lazy_staff": ["Your janitor was asleep on a bench."],
	"tantrum": ["A screaming kid ruined my visit.", "Couldn't hear myself think over the tantrums."],
	"boring": ["Not much to see yet.", "Kind of empty. Come back later?"],
	"pricey": ["Overpriced for what it is."],
	"vip": ["Some celebrity's entourage shoved us aside."],
	"theft": ["Someone pocketed stuff from the gift shop and nobody stopped them."],
	"climb": ["A kid was climbing the skeleton and nobody cared?!"],
	"sabotage": ["One exhibit was smashed. Sad."],
	"wrong_plaque": ["A plaque had the wrong era on it. Hmm.", "Pretty sure that plaque is wrong..."],
	"blank_plaque": ["Some display cases had blank plaques.", "No info on half the exhibits."],
	"harsh_plaque": ["DISGRACEFUL. A '{fossil}' labelled {wrong}? My seven-year-old knows better. Zero stars if I could.",
		"Scientific malpractice on display. The {fossil} plaque is flat-out wrong ({wrong}). Avoid.",
		"I have never been so insulted by a plaque. {fossil}: {wrong}?! Close this place down."],
	"slow_service": ["Waited forever at the {stand} and nobody served me!", "Stood in the {stand} queue for ages, then gave up."],
}
