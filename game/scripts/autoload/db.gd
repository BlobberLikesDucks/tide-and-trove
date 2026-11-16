extends Node
## Static game data: items, species, matrix types, dig spots, drop tables (built
## from the species list), tools, the Upgrade Tree, buildables, staff, guests,
## emails and review text. Everything tunable lives here.

const ERAS := ["Cenozoic", "Mesozoic", "Paleozoic"]
const DIETS := ["Carnivore", "Piscivore", "Herbivore", "Filter Feeder", "Detritivore", "Insectivore", "Photosynthesis (plant)"]
const HABITATS := ["Open Ocean", "Shallow Seafloor", "Shallow Reef", "Coastal Shore", "Brackish Lagoon", "Land"]
const RARITY_VALUE := {"common": 4, "uncommon": 7, "rare": 12, "epic": 22}
const RARITY_ORDER := ["common", "uncommon", "rare", "epic"]
const CELL := 2.0
## Floor plans: start + one expansion per star tier (bought in the Upgrade Tree).
const MUSEUM_SIZES := [Vector2i(5, 4), Vector2i(6, 5), Vector2i(7, 6), Vector2i(9, 6), Vector2i(11, 7)]
const MUSEUM_FRONT_Z := -22.0
## The museum level that comes with the Curator's Office computer (the 3-star expansion).
const OFFICE_LEVEL := 3

var RARITY_COLOR := {"common": Color("d9d4c7"), "uncommon": Color("7fd18b"), "rare": Color("6fb7ff"), "epic": Color("ffb347")}

# ---------------------------------------------------------- display cases ---
## Every fossil fits exactly ONE case size.
const CASES := {"small": "display_case", "medium": "display_case_medium", "big": "display_case_big", "mega": "display_case_mega"}
const CASE_OF_BUILD := {"display_case": "small", "display_case_medium": "medium", "display_case_big": "big", "display_case_mega": "mega"}
const CASE_NAMES := {"small": "Fossil Display Case", "medium": "Medium Fossil Display Case", "big": "Big Fossil Display Case", "mega": "Mega Display Case"}
## Model scale + height of the fossil inside each case.
const CASE_SHOW := {"small": [1.6, 1.05], "medium": [2.6, 0.95], "big": [4.6, 0.62], "mega": [1.0, 0.45]}
## Prep-lab grid (columns x rows) per case size; rarer finds add a little more rock.
const LAB_GRID := {"small": Vector2i(8, 6), "medium": Vector2i(11, 7), "big": Vector2i(14, 9), "mega": Vector2i(12, 8)}

# ------------------------------------------------------------ gems & ores ---
## Roughly $100 for a full early backpack (6 slots) of shore gems.
var GEMS := {
	"sea_glass": {"name": "Sea Glass", "value": 12, "model": "gem", "color": Color("8fe3c4")},
	"quartz": {"name": "Quartz Crystal", "value": 16, "model": "gem", "color": Color("f2f0ff")},
	"copper": {"name": "Copper Ore", "value": 20, "model": "ore", "color": Color("d9824a")},
	"iron": {"name": "Iron Ore", "value": 24, "model": "ore", "color": Color("9a5a4a")},
	"jasper": {"name": "Ocean Jasper", "value": 28, "model": "gem", "color": Color("6fbf8f")},
	"silver": {"name": "Silver Ore", "value": 38, "model": "ore", "color": Color("e6eef5")},
	"opal": {"name": "Fire Opal", "value": 55, "model": "gem", "color": Color("ff7a4a")},
	"gold": {"name": "Gold Nugget", "value": 75, "model": "ore", "color": Color("ffd23f")},
	"sapphire": {"name": "Sapphire", "value": 95, "model": "gem", "color": Color("3f6fff")},
}
const GEODE_VALUE := 30
const GEODE_CRACK_PRICE := 55

# ---------------------------------------------------------- fossil matrix ---
## What the find comes wrapped in. Names never give away the era.
var MATRIX := {
	"sandstone": {"name": "Sandstone Nodule", "rock": [Color("e2c48f"), Color("cfab73"), Color("b8915f")]},
	"tar": {"name": "Tar Seep Block", "rock": [Color("5a4a3e"), Color("42362d"), Color("2e2620")]},
	"shale": {"name": "Shale Slab", "rock": [Color("9aa2ab"), Color("7d8590"), Color("636b76")]},
	"limestone": {"name": "Limestone Block", "rock": [Color("e8dfc6"), Color("d4c8a8"), Color("bcae8a")]},
	"chalk": {"name": "Chalk Block", "rock": [Color("f4f0e4"), Color("e4ddc9"), Color("cfc6ae")]},
	"ironstone": {"name": "Ironstone Concretion", "rock": [Color("c98a5a"), Color("a86a42"), Color("86502f")]},
	"slate": {"name": "Slate Plate", "rock": [Color("7e8895"), Color("626c79"), Color("4b5361")]},
	"amber": {"name": "Amber Lump", "rock": [Color("f6c66a"), Color("e5a447"), Color("c98330")]},
	"jacket": {"name": "Plaster Field Jacket", "rock": [Color("f2efe6"), Color("dcd6c8"), Color("c4bcaa")]},
}

# ---------------------------------------------------------------- species ---
var PIECE_NAMES := {"skull": "Skull", "jaw": "Lower Jaw", "neck": "Neck Vertebrae", "back": "Dorsal Vertebrae",
	"ribs": "Ribcage", "flippers": "Paddles", "fore": "Fore Flipper", "hind": "Hind Flipper", "tail": "Tail Vertebrae",
	"arms": "Forelimbs", "legs": "Hind Limbs & Hips"}
var PIECE_NODES := {"skull": "Skull", "jaw": "Jaw", "neck": "Neck", "back": "Back", "ribs": "Ribs",
	"flippers": "Flippers", "fore": "ForeFlipper", "hind": "HindFlipper", "tail": "Tail", "arms": "Arms", "legs": "Legs"}

## zone: where it is found. case: which display case it fits (exactly one).
## matrix: what the find is wrapped in. shape: prep-lab silhouette.
var SPECIES := {
	# ---------------- Driftwood Shore (Cenozoic) --------------------------------
	"sand_dollar": {"name": "Fossil Sand Dollar", "sci": "Dendraster sp.", "era": "Cenozoic", "period": "Pliocene - Pleistocene (5 - 0.01 million years ago)",
		"diet": "Detritivore", "habitat": "Shallow Seafloor", "rarity": "common", "model": "sand_dollar", "color": Color("d8c7a0"), "shape": "disc", "case": "small", "matrix": "sandstone", "zone": "shore",
		"size": "About the width of your palm (7 cm).",
		"fact": "Sand dollars are animals: flattened sea urchins, cousins of starfish. The five-petal pattern on top marks where rows of tube feet poked out to breathe, and they sift tiny food particles out of the sand."},
	"turritella": {"name": "Turritella Snail", "sci": "Turritella sp.", "era": "Cenozoic", "period": "Eocene (about 50 million years ago)",
		"diet": "Filter Feeder", "habitat": "Shallow Seafloor", "rarity": "common", "model": "snail_shell", "color": Color("d9b98a"), "shape": "cone", "case": "small", "matrix": "sandstone", "zone": "shore",
		"size": "As long as your finger (6 cm).",
		"fact": "These tall spiral snails strained food from the water instead of grazing. In some Eocene rocks they are so abundant that they form entire shell beds."},
	"scallop": {"name": "Fossil Scallop", "sci": "Pecten sp.", "era": "Cenozoic", "period": "Pliocene (about 4 million years ago)",
		"diet": "Filter Feeder", "habitat": "Shallow Seafloor", "rarity": "common", "model": "scallop", "color": Color("dcb48a"), "shape": "fan", "case": "small", "matrix": "sandstone", "zone": "shore",
		"size": "About the size of a cookie (8 cm).",
		"fact": "Scallops swim by clapping their two shells together. They have up to 200 tiny blue eyes along the shell edge, each with a mirror inside made of crystals."},
	"crab": {"name": "Fossil Crab", "sci": "Harpactocarcinus punctulatus", "era": "Cenozoic", "period": "Eocene (about 45 million years ago)",
		"diet": "Detritivore", "habitat": "Coastal Shore", "rarity": "common", "model": "crab", "color": Color("b98c5e"), "shape": "crab", "case": "small", "matrix": "ironstone", "zone": "shore",
		"size": "About the size of a bottle cap to a fist (5 - 10 cm).",
		"fact": "Crabs are scavengers that clean up dead plants and animals. Fossil crabs are often found curled inside hard nodules that formed around their bodies as they decayed."},
	"shark_tooth": {"name": "Sand Tiger Shark Tooth", "sci": "Carcharias sp.", "era": "Cenozoic", "period": "Eocene - Present",
		"diet": "Piscivore", "habitat": "Coastal Shore", "rarity": "uncommon", "model": "tooth", "color": Color("4a4a50"), "shape": "tooth", "case": "small", "matrix": "sandstone", "zone": "shore",
		"size": "About the length of a paperclip (3 cm).",
		"fact": "Sharks shed and replace teeth constantly - thousands over a lifetime - which is why fossil shark teeth are the most common vertebrate fossils on beaches."},
	"amber": {"name": "Insect in Amber", "sci": "Termite in Baltic amber", "era": "Cenozoic", "period": "Eocene (about 44 million years ago)",
		"diet": "Detritivore", "habitat": "Land", "rarity": "uncommon", "model": "amber", "color": Color("f2a23a"), "shape": "disc", "case": "small", "matrix": "amber", "zone": "shore",
		"size": "A honey-coloured drop about the size of a walnut (3 cm); the termite inside is 6 mm long.",
		"fact": "Amber is fossilised tree resin, not a gemstone. Sticky sap trapped this termite about 44 million years ago and slowly hardened, preserving it in 3D right down to the hairs on its legs."},
	"palm_frond": {"name": "Fossil Palm Frond", "sci": "Sabalites sp.", "era": "Cenozoic", "period": "Eocene (about 50 million years ago)",
		"diet": "Photosynthesis (plant)", "habitat": "Land", "rarity": "common", "model": "plant_slab", "color": Color("8a7a58"), "shape": "leaf", "case": "small", "matrix": "shale", "zone": "shore",
		"size": "A leaf as wide as a dinner plate.",
		"fact": "Plants make their own food from sunlight - photosynthesis. Fossil palms far from today's tropics show the Eocene world was much warmer than now."},
	"whale_ear": {"name": "Whale Ear Bone", "sci": "Balaenopteridae", "era": "Cenozoic", "period": "Pliocene (about 4 million years ago)",
		"diet": "Filter Feeder", "habitat": "Open Ocean", "rarity": "uncommon", "model": "urchin", "color": Color("cbb89a"), "shape": "egg", "case": "small", "matrix": "sandstone", "zone": "shore",
		"size": "About the size of a fist (8 cm).",
		"fact": "Whale ear bones are so dense they survive when the rest of the skeleton is gone. This baleen whale filtered tiny krill through comb-like plates in its mouth."},
	"glyptodon": {"name": "Glyptodon Shell Scute", "sci": "Glyptodon clavipes", "era": "Cenozoic", "period": "Pleistocene (Ice Age)",
		"diet": "Herbivore", "habitat": "Land", "rarity": "uncommon", "model": "armor_plate", "color": Color("a08a68"), "shape": "plate", "case": "small", "matrix": "tar", "zone": "shore",
		"size": "One scute is coin-sized; the whole shell was as big as a small car.",
		"fact": "Glyptodon was a giant armadillo relative with a dome-shaped shell made of over 1,000 bony plates. Early humans may have used empty shells as shelters."},
	"horse_tooth": {"name": "Ancient Horse Tooth", "sci": "Equus sp.", "era": "Cenozoic", "period": "Pleistocene (Ice Age)",
		"diet": "Herbivore", "habitat": "Land", "rarity": "common", "model": "tooth", "color": Color("c8b48e"), "shape": "tooth", "case": "small", "matrix": "tar", "zone": "shore",
		"size": "About as long as your finger (8 cm).",
		"fact": "Horse teeth are tall and keep growing as they wear down, perfect for chewing gritty grass. Early horse ancestors were only the size of a dog and had several toes."},
	"dire_wolf": {"name": "Dire Wolf Skull", "sci": "Aenocyon dirus", "era": "Cenozoic", "period": "Pleistocene (Ice Age)",
		"diet": "Carnivore", "habitat": "Land", "rarity": "rare", "model": "mammal_skull", "color": Color("b8a07a"), "shape": "skull", "case": "medium", "matrix": "tar", "zone": "shore",
		"size": "A skull about 30 cm long; heavier than today's grey wolf.",
		"fact": "Over 4,000 dire wolves were found in the La Brea tar pits - they probably got stuck while trying to eat animals already trapped in the sticky tar."},
	"megalodon": {"name": "Megalodon Tooth", "sci": "Otodus megalodon", "era": "Cenozoic", "period": "Miocene - Pliocene (23 - 3.6 million years ago)",
		"diet": "Carnivore", "habitat": "Open Ocean", "rarity": "rare", "model": "tooth", "color": Color("2f3036"), "shape": "tooth", "case": "medium", "matrix": "sandstone", "zone": "shore",
		"size": "Teeth up to 18 cm - bigger than your hand. The shark was roughly as long as a bus.",
		"fact": "Megalodon was one of the largest predators that ever lived, estimated at around 15 - 20 m long. Bite marks on fossil whale bones show it hunted whales."},
	"sabre_tooth": {"name": "Sabre-Tooth Cat Fang", "sci": "Smilodon fatalis", "era": "Cenozoic", "period": "Pleistocene (Ice Age)",
		"diet": "Carnivore", "habitat": "Land", "rarity": "rare", "model": "claw", "color": Color("e3d3b0"), "shape": "claw", "case": "medium", "matrix": "tar", "zone": "shore",
		"size": "A fang about 28 cm long - longer than a ruler.",
		"fact": "Smilodon's fangs were thin and fragile, so it pinned prey with its muscular front legs before a precise bite. Thousands were found trapped in the La Brea tar pits."},
	"ground_sloth": {"name": "Giant Ground Sloth Claw", "sci": "Megatherium americanum", "era": "Cenozoic", "period": "Pleistocene (Ice Age)",
		"diet": "Herbivore", "habitat": "Land", "rarity": "rare", "model": "claw", "color": Color("c9b48c"), "shape": "claw", "case": "medium", "matrix": "tar", "zone": "shore",
		"size": "The sloth was as big as an elephant - up to 6 m tall standing up.",
		"fact": "Today's sloths are small tree-dwellers, but Megatherium walked on the ground and used its huge claws to pull down branches to eat."},
	"mammoth": {"name": "Woolly Mammoth Molar", "sci": "Mammuthus primigenius", "era": "Cenozoic", "period": "Pleistocene (Ice Age)",
		"diet": "Herbivore", "habitat": "Land", "rarity": "rare", "model": "bone", "color": Color("8a7a5a"), "shape": "bone", "case": "medium", "matrix": "sandstone", "zone": "shore",
		"size": "A single molar is as big as a shoebox and weighs about 2 kg.",
		"fact": "Fishing trawlers still drag mammoth teeth up from the North Sea floor: during the Ice Age it was dry grassland. The ridged enamel plates ground tough grasses."},
	"cave_bear": {"name": "Cave Bear Skull", "sci": "Ursus spelaeus", "era": "Cenozoic", "period": "Pleistocene (Ice Age)",
		"diet": "Herbivore", "habitat": "Land", "rarity": "rare", "model": "mammal_skull", "color": Color("d6c4a0"), "shape": "skull", "case": "medium", "matrix": "sandstone", "zone": "shore",
		"size": "A skull about 45 cm long; the bear was bigger than a grizzly.",
		"fact": "Despite its size, chemical clues in its teeth show the cave bear ate mostly plants. Thousands of skeletons were found in European caves where they hibernated."},
	"mammoth_tusk": {"name": "Woolly Mammoth Tusk Tip", "sci": "Mammuthus primigenius", "era": "Cenozoic", "period": "Pleistocene (Ice Age)",
		"diet": "Herbivore", "habitat": "Land", "rarity": "epic", "model": "tusk", "color": Color("efe2c4"), "shape": "tusk", "case": "medium", "matrix": "tar", "zone": "shore",
		"size": "This tip is about 60 cm long; a whole tusk grew up to 4 m, curling in a spiral.",
		"fact": "Tusks are giant incisor teeth that grew all life long, laying down yearly growth rings like a tree. Scientists read those rings to learn where a mammoth travelled."},
	# ---------------- Ammonite Cliffs (Mesozoic: Jurassic) ----------------------
	"ammonite": {"name": "Ammonite", "sci": "Dactylioceras commune", "era": "Mesozoic", "period": "Early Jurassic (about 180 million years ago)",
		"diet": "Carnivore", "habitat": "Open Ocean", "rarity": "common", "model": "ammonite", "color": Color("b98a5a"), "shape": "spiral", "case": "small", "matrix": "shale", "zone": "cliffs",
		"size": "About the size of a cookie (6 cm).",
		"fact": "Ammonites were squid-like animals living in coiled shells. Gas-filled chambers, regulated through a tube called the siphuncle, let them float like a submarine."},
	"belemnite": {"name": "Belemnite Guard", "sci": "Passaloteuthis sp.", "era": "Mesozoic", "period": "Early Jurassic",
		"diet": "Carnivore", "habitat": "Open Ocean", "rarity": "common", "model": "tooth", "color": Color("c98a4a"), "shape": "tooth", "case": "small", "matrix": "shale", "zone": "cliffs",
		"size": "Bullet-sized (8 cm).",
		"fact": "The bullet-shaped fossil is the guard: a heavy internal counterweight of a squid-like animal. Some belemnites are found with their fossil ink sacs still intact."},
	"gryphaea": {"name": "Devil's Toenail", "sci": "Gryphaea arcuata", "era": "Mesozoic", "period": "Early Jurassic",
		"diet": "Filter Feeder", "habitat": "Shallow Seafloor", "rarity": "common", "model": "snail_shell", "color": Color("8f8a80"), "shape": "cone", "case": "small", "matrix": "limestone", "zone": "cliffs",
		"size": "About the size of a toe (5 cm).",
		"fact": "A curled oyster that lay on soft muddy seafloors. Its gnarly shape gave rise to the folk name 'Devil's toenail'."},
	"ginkgo": {"name": "Ginkgo Leaf", "sci": "Ginkgo huttonii", "era": "Mesozoic", "period": "Middle Jurassic (about 170 million years ago)",
		"diet": "Photosynthesis (plant)", "habitat": "Land", "rarity": "common", "model": "plant_slab", "color": Color("7a6a48"), "shape": "leaf", "case": "small", "matrix": "shale", "zone": "cliffs",
		"size": "A fan-shaped leaf about 6 cm across.",
		"fact": "Ginkgo trees still grow in city streets today and have barely changed since the Jurassic - a true 'living fossil' that dinosaurs walked under."},
	"hybodus": {"name": "Hybodus Fin Spine", "sci": "Hybodus sp.", "era": "Mesozoic", "period": "Jurassic",
		"diet": "Carnivore", "habitat": "Open Ocean", "rarity": "uncommon", "model": "claw", "color": Color("6a5a48"), "shape": "claw", "case": "small", "matrix": "limestone", "zone": "cliffs",
		"size": "A spine about 15 cm long; the shark was about 2 m.",
		"fact": "Hybodus had a sharp spine in front of each back fin to deter predators, and two kinds of teeth: pointed ones for grabbing and flat ones for crushing shells."},
	"plesiosaurus": {"name": "Plesiosaur Paddle Bone", "sci": "Plesiosaurus dolichodeirus", "era": "Mesozoic", "period": "Early Jurassic",
		"diet": "Piscivore", "habitat": "Open Ocean", "rarity": "uncommon", "model": "bone", "color": Color("d9c39a"), "shape": "bone", "case": "medium", "matrix": "limestone", "zone": "cliffs",
		"size": "The whole animal was about 3.5 m - longer than a car.",
		"fact": "Long-necked plesiosaurs 'flew' underwater with four paddle-shaped flippers. Mary Anning found the first nearly complete skeleton in 1823."},
	"dimorphodon": {"name": "Dimorphodon Wing Bone", "sci": "Dimorphodon macronyx", "era": "Mesozoic", "period": "Early Jurassic",
		"diet": "Insectivore", "habitat": "Coastal Shore", "rarity": "uncommon", "model": "bone", "color": Color("e6d4b0"), "shape": "bone", "case": "medium", "matrix": "shale", "zone": "cliffs",
		"size": "Wingspan about 1.4 m - like a large gull.",
		"fact": "A pterosaur with an oversized, puffin-like head. Mary Anning found one of the first specimens in 1828. It probably snapped up insects and small animals."},
	"lepidotes": {"name": "Lepidotes Fish", "sci": "Lepidotes sp.", "era": "Mesozoic", "period": "Jurassic",
		"diet": "Carnivore", "habitat": "Shallow Reef", "rarity": "uncommon", "model": "fish_slab", "color": Color("6e5a40"), "shape": "fish", "case": "medium", "matrix": "limestone", "zone": "cliffs",
		"size": "About 30 cm - the length of a ruler.",
		"fact": "Lepidotes was covered in thick, shiny diamond-shaped scales. Its peg-like teeth crushed snails and clams - so it was a meat eater, not a plant eater."},
	"scelidosaurus": {"name": "Scelidosaurus Armour Scute", "sci": "Scelidosaurus harrisonii", "era": "Mesozoic", "period": "Early Jurassic (about 190 million years ago)",
		"diet": "Herbivore", "habitat": "Land", "rarity": "rare", "model": "armor_plate", "color": Color("8e7a5a"), "shape": "plate", "case": "small", "matrix": "limestone", "zone": "cliffs",
		"size": "The dinosaur was about 4 m long.",
		"fact": "One of the earliest armoured dinosaurs, found on England's Jurassic Coast. Its body washed out to sea after death, which is why it is found in marine rocks."},
	"megalosaurus": {"name": "Megalosaurus Tooth", "sci": "Megalosaurus bucklandii", "era": "Mesozoic", "period": "Middle Jurassic (about 166 million years ago)",
		"diet": "Carnivore", "habitat": "Land", "rarity": "rare", "model": "tooth", "color": Color("5a4a3a"), "shape": "tooth", "case": "small", "matrix": "limestone", "zone": "cliffs",
		"size": "A tooth about 9 cm long; the animal was about 6 m.",
		"fact": "In 1824 Megalosaurus became the very first dinosaur ever given a scientific name - years before the word 'dinosaur' was even invented."},
	"archaeopteryx": {"name": "Archaeopteryx Feather", "sci": "Archaeopteryx lithographica", "era": "Mesozoic", "period": "Late Jurassic (about 150 million years ago)",
		"diet": "Carnivore", "habitat": "Land", "rarity": "epic", "model": "wing_slab", "color": Color("5f5244"), "shape": "leaf", "case": "small", "matrix": "limestone", "zone": "cliffs",
		"size": "A single feather 7 cm long; the animal was raven-sized.",
		"fact": "Half bird, half dinosaur: Archaeopteryx had feathers and wings but also teeth, claws and a long bony tail. It is key evidence that birds evolved from dinosaurs."},
	"theropod_track": {"name": "Theropod Footprint", "sci": "Eubrontes (trace fossil)", "era": "Mesozoic", "period": "Early Jurassic",
		"diet": "Carnivore", "habitat": "Coastal Shore", "rarity": "rare", "model": "footprint", "color": Color("b8a07a"), "shape": "track", "case": "big", "matrix": "jacket", "zone": "cliffs",
		"size": "A print about 35 cm long, left by a 6 m meat eater.",
		"fact": "A trace fossil records behaviour, not bones. The spacing between footprints lets scientists work out how fast the dinosaur was walking on the muddy shore."},
	"stegosaurus": {"name": "Stegosaurus Back Plate", "sci": "Stegosaurus stenops", "era": "Mesozoic", "period": "Late Jurassic (about 150 million years ago)",
		"diet": "Herbivore", "habitat": "Land", "rarity": "epic", "model": "armor_plate", "color": Color("9a7e58"), "shape": "plate", "case": "big", "matrix": "jacket", "zone": "cliffs",
		"size": "Plates up to 60 cm tall on a 9 m animal.",
		"fact": "The plates were full of blood vessels and may have been used for display or to warm up and cool down. Stegosaurus had a brain about the size of a lime."},
	"ichthyosaurus": {"name": "Ichthyosaurus", "sci": "Ichthyosaurus communis", "era": "Mesozoic", "period": "Early Jurassic (200 - 190 million years ago)",
		"diet": "Piscivore", "habitat": "Open Ocean", "rarity": "rare", "model": "bone", "color": Color("efe3c4"), "shape": "skull", "case": "mega", "matrix": "jacket", "zone": "caves",
		"skeleton": "skeleton_ichthyosaur", "pieces": ["skull", "back", "ribs", "flippers", "tail"],
		"size": "About 2 - 3 m long - like a dolphin.",
		"fact": "Ichthyosaurs were dolphin-shaped marine reptiles that gave birth to live young at sea. Joseph and Mary Anning found the first skeleton recognised by science on the English coast in 1811 - 12."},
	# ---------------- Sea Caves (Mesozoic: Cretaceous) --------------------------
	"echinocorys": {"name": "Shepherd's Crown Urchin", "sci": "Echinocorys scutata", "era": "Mesozoic", "period": "Late Cretaceous (about 80 million years ago)",
		"diet": "Detritivore", "habitat": "Shallow Seafloor", "rarity": "common", "model": "urchin", "color": Color("e4dcc4"), "shape": "egg", "case": "small", "matrix": "chalk", "zone": "caves",
		"size": "About the size of a hen's egg.",
		"fact": "Chalk is made of trillions of microscopic plankton plates. Sea urchins ploughed through that soft ooze eating scraps; farmers once kept them as good-luck charms."},
	"inoceramus": {"name": "Inoceramus Clam", "sci": "Inoceramus sp.", "era": "Mesozoic", "period": "Cretaceous",
		"diet": "Filter Feeder", "habitat": "Shallow Seafloor", "rarity": "common", "model": "scallop", "color": Color("c8b490"), "shape": "fan", "case": "small", "matrix": "chalk", "zone": "caves",
		"size": "Usually 10 - 20 cm, but some grew over 1 m across.",
		"fact": "Some Inoceramus clams grew bigger than a car tyre. Little fish lived sheltered inside their giant shells."},
	"hadrosaur_egg": {"name": "Hadrosaur Egg Clutch", "sci": "Maiasaura peeblesorum", "era": "Mesozoic", "period": "Late Cretaceous (about 76 million years ago)",
		"diet": "Herbivore", "habitat": "Land", "rarity": "uncommon", "model": "egg", "color": Color("8a7a66"), "shape": "egg", "case": "small", "matrix": "ironstone", "zone": "caves",
		"size": "Each egg is about the size of a grapefruit.",
		"fact": "Maiasaura means 'good mother lizard'. Nesting colonies show parents fed babies in the nest - dinosaurs could be caring parents."},
	"velociraptor": {"name": "Velociraptor Sickle Claw", "sci": "Velociraptor mongoliensis", "era": "Mesozoic", "period": "Late Cretaceous (about 75 million years ago)",
		"diet": "Carnivore", "habitat": "Land", "rarity": "rare", "model": "claw", "color": Color("5e4e3c"), "shape": "claw", "case": "small", "matrix": "ironstone", "zone": "caves",
		"size": "A claw 6.5 cm long; the animal was turkey-sized and feathered.",
		"fact": "Real Velociraptors were about the size of a turkey and covered in feathers. One famous fossil shows a Velociraptor locked in battle with a Protoceratops."},
	"baryonyx": {"name": "Baryonyx Thumb Claw", "sci": "Baryonyx walkeri", "era": "Mesozoic", "period": "Early Cretaceous (about 125 million years ago)",
		"diet": "Piscivore", "habitat": "Brackish Lagoon", "rarity": "rare", "model": "claw", "color": Color("6a5440"), "shape": "claw", "case": "medium", "matrix": "ironstone", "zone": "caves",
		"size": "A claw 31 cm long on a 9 m animal.",
		"fact": "Baryonyx had a long crocodile-like snout and fish scales were found in its stomach - one of the first dinosaurs proven to eat fish. An amateur collector found the claw in 1983."},
	"pteranodon": {"name": "Pteranodon Crest", "sci": "Pteranodon longiceps", "era": "Mesozoic", "period": "Late Cretaceous (about 85 million years ago)",
		"diet": "Piscivore", "habitat": "Open Ocean", "rarity": "uncommon", "model": "horn", "color": Color("d8c8a6"), "shape": "claw", "case": "medium", "matrix": "chalk", "zone": "caves",
		"size": "Wingspan about 6 m - wider than a car is long.",
		"fact": "Pteranodon was a flying reptile, not a dinosaur. It had no teeth and soared far over the sea to scoop up fish like a pelican."},
	"triceratops": {"name": "Triceratops Horn", "sci": "Triceratops horridus", "era": "Mesozoic", "period": "Late Cretaceous (68 - 66 million years ago)",
		"diet": "Herbivore", "habitat": "Land", "rarity": "rare", "model": "horn", "color": Color("6e5a46"), "shape": "horn", "case": "big", "matrix": "jacket", "zone": "caves",
		"size": "Brow horns up to 1 m long on a 9 m animal.",
		"fact": "Triceratops lived at the very end of the age of dinosaurs. Healed puncture wounds on its frill suggest Triceratops fought each other with their horns."},
	"pachycephalosaurus": {"name": "Pachycephalosaurus Dome", "sci": "Pachycephalosaurus wyomingensis", "era": "Mesozoic", "period": "Late Cretaceous (about 67 million years ago)",
		"diet": "Herbivore", "habitat": "Land", "rarity": "rare", "model": "dino_skull", "color": Color("8a7458"), "shape": "skull", "case": "big", "matrix": "jacket", "zone": "caves",
		"size": "A skull roof up to 25 cm thick.",
		"fact": "Its domed skull was solid bone. Scientists still argue whether males head-butted each other like rams or just showed off their domes."},
	"ankylosaurus": {"name": "Ankylosaurus Tail Club", "sci": "Ankylosaurus magniventris", "era": "Mesozoic", "period": "Late Cretaceous (68 - 66 million years ago)",
		"diet": "Herbivore", "habitat": "Land", "rarity": "rare", "model": "armor_plate", "color": Color("7a6a54"), "shape": "plate", "case": "big", "matrix": "jacket", "zone": "caves",
		"size": "A bony club about 60 cm wide on a 7 m armoured animal.",
		"fact": "Ankylosaurus was covered in bony armour plates and swung its heavy tail club to defend itself - possibly hard enough to break a predator's ankle."},
	"spinosaurus": {"name": "Spinosaurus Sail Spine", "sci": "Spinosaurus aegyptiacus", "era": "Mesozoic", "period": "Cretaceous (about 95 million years ago)",
		"diet": "Piscivore", "habitat": "Brackish Lagoon", "rarity": "epic", "model": "vertebra", "color": Color("8c7050"), "shape": "bone", "case": "big", "matrix": "jacket", "zone": "caves",
		"size": "Spines over 1.6 m tall on a 15 m animal - longer than T. rex.",
		"fact": "The first Spinosaurus skeleton was destroyed by bombing in World War II. New finds show it spent much of its life in water hunting giant fish."},
	"mosasaurus": {"name": "Mosasaurus", "sci": "Mosasaurus hoffmannii", "era": "Mesozoic", "period": "Late Cretaceous (82 - 66 million years ago)",
		"diet": "Carnivore", "habitat": "Open Ocean", "rarity": "rare", "model": "bone", "color": Color("c9a77a"), "shape": "skull", "case": "mega", "matrix": "jacket", "zone": "caves",
		"skeleton": "skeleton_mosasaur", "pieces": ["skull", "jaw", "back", "ribs", "flippers", "tail"],
		"size": "Up to about 12 m - as long as a city bus.",
		"fact": "Mosasaurs were giant marine lizards, cousins of today's monitor lizards and snakes. The first known skull was dug from a quarry near Maastricht in the Netherlands around 1764."},
	"iguanodon": {"name": "Iguanodon", "sci": "Iguanodon bernissartensis", "era": "Mesozoic", "period": "Early Cretaceous (about 125 million years ago)",
		"diet": "Herbivore", "habitat": "Land", "rarity": "rare", "model": "bone", "color": Color("e2d6bc"), "shape": "bone", "case": "mega", "matrix": "jacket", "zone": "caves",
		"skeleton": "skeleton_iguanodon", "pieces": ["skull", "neck", "back", "ribs", "arms", "legs", "tail"],
		"size": "About 10 m long and as heavy as an elephant.",
		"fact": "When it was discovered in 1825, scientists put its thumb spike on its nose like a rhino horn! Later complete skeletons showed the spike belonged on the hand."},
	"trex": {"name": "Tyrannosaurus rex", "sci": "Tyrannosaurus rex", "era": "Mesozoic", "period": "Late Cretaceous (68 - 66 million years ago)",
		"diet": "Carnivore", "habitat": "Land", "rarity": "epic", "model": "bone", "color": Color("8e6e4c"), "shape": "skull", "case": "mega", "matrix": "jacket", "zone": "caves",
		"skeleton": "skeleton_trex", "pieces": ["skull", "jaw", "neck", "back", "ribs", "arms", "legs", "tail"],
		"size": "About 12 m long and 4 m tall at the hips.",
		"fact": "T. rex had one of the strongest bites of any land animal ever, strong enough to crunch bone. Its tiny arms were still muscular - each could curl about 200 kg."},
	"apex": {"name": "Pelagotyrannus (The Cove Tyrant)", "sci": "Pelagotyrannus covensis", "era": "Mesozoic", "period": "Late Jurassic",
		"diet": "Carnivore", "habitat": "Open Ocean", "rarity": "epic", "model": "bone", "color": Color("ddd2bd"), "shape": "skull", "case": "mega", "matrix": "jacket", "zone": "caves",
		"skeleton": "skeleton_apex", "pieces": ["skull", "jaw", "neck", "back", "ribs", "fore", "hind", "tail"], "fictional": true,
		"size": "Estimated 15 m - longer than three cars nose to tail.",
		"fact": "Unknown to science until you dug it up. This apex marine reptile exists only in the strata of Ammonite Bay. Its bite marks appear on ichthyosaur bones all along the coast. (In-game species - not a real animal.)"},
	# ---------------- Paleozoic Shelf -------------------------------------------
	"trilobite": {"name": "Trilobite", "sci": "Calymene blumenbachii", "era": "Paleozoic", "period": "Silurian (about 430 million years ago)",
		"diet": "Detritivore", "habitat": "Shallow Reef", "rarity": "common", "model": "trilobite", "color": Color("8a7f74"), "shape": "trilobite", "case": "small", "matrix": "slate", "zone": "reef",
		"size": "About the size of a matchbox (5 cm).",
		"fact": "Nicknamed the 'Dudley Bug', it could roll into a ball like a woodlouse. Trilobites had some of the earliest complex eyes, with lenses made of the mineral calcite."},
	"crinoid": {"name": "Crinoid (Sea Lily)", "sci": "Crinoidea", "era": "Paleozoic", "period": "Carboniferous (about 340 million years ago)",
		"diet": "Filter Feeder", "habitat": "Shallow Reef", "rarity": "common", "model": "crinoid", "color": Color("b8a890"), "shape": "stem", "case": "small", "matrix": "limestone", "zone": "reef",
		"size": "Stems could grow taller than a person.",
		"fact": "Despite looking like plants, crinoids are animals related to starfish. Their disc-shaped stem pieces were once strung as 'St Cuthbert's beads'."},
	"brachiopod": {"name": "Brachiopod", "sci": "Spirifer sp.", "era": "Paleozoic", "period": "Carboniferous",
		"diet": "Filter Feeder", "habitat": "Shallow Seafloor", "rarity": "common", "model": "scallop", "color": Color("a8977c"), "shape": "fan", "case": "small", "matrix": "limestone", "zone": "reef",
		"size": "About the size of a coin (3 cm).",
		"fact": "Brachiopods look like clams but belong to a separate group of animals. Spirifer means 'spiral-bearer', after the coiled internal supports of its feeding organ."},
	"horn_coral": {"name": "Horn Coral", "sci": "Rugosa", "era": "Paleozoic", "period": "Devonian (about 380 million years ago)",
		"diet": "Filter Feeder", "habitat": "Shallow Reef", "rarity": "common", "model": "coral", "color": Color("b09878"), "shape": "cone", "case": "small", "matrix": "limestone", "zone": "reef",
		"size": "About the length of your thumb to your hand.",
		"fact": "Each horn coral was a single animal like a sea anemone living in a stony cup. Growth lines on their sides show a Devonian year had about 400 days - Earth spun faster back then!"},
	"lepidodendron": {"name": "Scale Tree Bark", "sci": "Lepidodendron sp.", "era": "Paleozoic", "period": "Carboniferous (about 310 million years ago)",
		"diet": "Photosynthesis (plant)", "habitat": "Land", "rarity": "common", "model": "plant_slab", "color": Color("4e4a44"), "shape": "leaf", "case": "small", "matrix": "shale", "zone": "reef",
		"size": "The trees grew up to 30 m tall.",
		"fact": "Giant 'scale trees' formed huge swamp forests. Their buried remains became much of the coal we burn today - that's why the period is called the Carboniferous ('coal-bearing')."},
	"graptolite": {"name": "Graptolite", "sci": "Didymograptus murchisoni", "era": "Paleozoic", "period": "Ordovician (about 465 million years ago)",
		"diet": "Filter Feeder", "habitat": "Open Ocean", "rarity": "uncommon", "model": "wing_slab", "color": Color("3e3a38"), "shape": "leaf", "case": "small", "matrix": "slate", "zone": "reef",
		"size": "Tuning-fork shapes a few cm long.",
		"fact": "Graptolites were floating colonies of tiny animals. They changed so quickly through time that geologists use them like clocks to date rocks."},
	"goniatite": {"name": "Goniatite", "sci": "Goniatites sp.", "era": "Paleozoic", "period": "Carboniferous (about 330 million years ago)",
		"diet": "Carnivore", "habitat": "Open Ocean", "rarity": "common", "model": "ammonite", "color": Color("8a6e52"), "shape": "spiral", "case": "small", "matrix": "limestone", "zone": "reef",
		"size": "About the size of a walnut (4 cm).",
		"fact": "Goniatites were early relatives of the ammonites. The zig-zag lines on their shells show where the walls between their gas chambers met the outer shell."},
	"orthoceras": {"name": "Orthoceras", "sci": "Orthoceras regulare", "era": "Paleozoic", "period": "Ordovician (about 470 million years ago)",
		"diet": "Carnivore", "habitat": "Open Ocean", "rarity": "uncommon", "model": "snail_shell", "color": Color("5e5a58"), "shape": "cone", "case": "small", "matrix": "limestone", "zone": "reef",
		"size": "Shells about 15 cm long - like a pencil.",
		"fact": "A straight-shelled relative of the nautilus. Swedish 'Orthoceras limestone', packed with these shells, has been used as a building stone for centuries."},
	"stromatolite": {"name": "Stromatolite", "sci": "Cyanobacterial mat", "era": "Paleozoic", "period": "Cambrian (about 500 million years ago)",
		"diet": "Photosynthesis (plant)", "habitat": "Shallow Reef", "rarity": "uncommon", "model": "stromatolite", "color": Color("a88a6a"), "shape": "egg", "case": "medium", "matrix": "limestone", "zone": "reef",
		"size": "Domes from a fist to a car in size.",
		"fact": "Stromatolites were built layer by layer by microbes that make food from sunlight. Over billions of years they pumped out the oxygen we breathe today."},
	"anomalocaris": {"name": "Anomalocaris Claw", "sci": "Anomalocaris canadensis", "era": "Paleozoic", "period": "Cambrian (about 505 million years ago)",
		"diet": "Carnivore", "habitat": "Open Ocean", "rarity": "rare", "model": "claw", "color": Color("6a5a52"), "shape": "claw", "case": "small", "matrix": "shale", "zone": "reef",
		"size": "The animal was about 1 m - a giant for its time.",
		"fact": "Its grasping claws were first thought to be a shrimp, its mouth a jellyfish and its body a sponge - until a whole fossil showed they were all one strange predator."},
	"eurypterus": {"name": "Sea Scorpion", "sci": "Eurypterus remipes", "era": "Paleozoic", "period": "Silurian (about 420 million years ago)",
		"diet": "Carnivore", "habitat": "Brackish Lagoon", "rarity": "rare", "model": "trilobite", "color": Color("6a4a3a"), "shape": "trilobite", "case": "medium", "matrix": "slate", "zone": "reef",
		"size": "About 20 cm - but some relatives grew longer than 2 m.",
		"fact": "Eurypterids were arthropods related to horseshoe crabs and scorpions. Eurypterus remipes is the state fossil of New York."},
	"coelacanth": {"name": "Coelacanth", "sci": "Coelacanthiformes", "era": "Paleozoic", "period": "Devonian (about 380 million years ago)",
		"diet": "Carnivore", "habitat": "Open Ocean", "rarity": "rare", "model": "fish_slab", "color": Color("4e4640"), "shape": "fish", "case": "medium", "matrix": "slate", "zone": "reef",
		"size": "Fossil kinds from 30 cm to over 3 m.",
		"fact": "Scientists thought coelacanths died out with the dinosaurs - until a living one was caught off South Africa in 1938. Their fleshy fins are related to our own arms and legs."},
	"tiktaalik": {"name": "Tiktaalik", "sci": "Tiktaalik roseae", "era": "Paleozoic", "period": "Late Devonian (about 375 million years ago)",
		"diet": "Carnivore", "habitat": "Brackish Lagoon", "rarity": "epic", "model": "fish_slab", "color": Color("6e5e50"), "shape": "fish", "case": "medium", "matrix": "slate", "zone": "reef",
		"size": "About 2.7 m long.",
		"fact": "A 'fishapod': a fish with a neck, lungs and sturdy fins with wrist bones. It shows how animals began moving from water onto land."},
	"meganeura": {"name": "Meganeura Wing", "sci": "Meganeura monyi", "era": "Paleozoic", "period": "Late Carboniferous (about 300 million years ago)",
		"diet": "Carnivore", "habitat": "Land", "rarity": "rare", "model": "wing_slab", "color": Color("4a4440"), "shape": "leaf", "case": "medium", "matrix": "shale", "zone": "reef",
		"size": "Wingspan about 70 cm - as wide as a hawk.",
		"fact": "A giant dragonfly relative that hunted other insects. Higher oxygen levels in the Carboniferous air may have let insects grow this huge."},
	"dunkleosteus": {"name": "Dunkleosteus Jaw Plate", "sci": "Dunkleosteus terrelli", "era": "Paleozoic", "period": "Late Devonian (372 - 359 million years ago)",
		"diet": "Carnivore", "habitat": "Open Ocean", "rarity": "epic", "model": "tooth", "color": Color("3a3a3e"), "shape": "tooth", "case": "big", "matrix": "jacket", "zone": "reef",
		"size": "Around 4 m long - about the size of a small car.",
		"fact": "An armoured fish with self-sharpening bony blades instead of teeth, and one of the most powerful bites of any fish ever."},
	"helicoprion": {"name": "Helicoprion Tooth Whorl", "sci": "Helicoprion bessonowi", "era": "Paleozoic", "period": "Permian (about 275 million years ago)",
		"diet": "Carnivore", "habitat": "Open Ocean", "rarity": "epic", "model": "whorl", "color": Color("4c4038"), "shape": "spiral", "case": "big", "matrix": "jacket", "zone": "reef",
		"size": "Whorls up to 60 cm across; the fish was up to 8 m.",
		"fact": "For 100 years nobody knew where this buzz-saw of teeth went. CT scans finally showed it sat inside the lower jaw and sliced soft squid-like prey."},
	"dimetrodon": {"name": "Dimetrodon", "sci": "Dimetrodon grandis", "era": "Paleozoic", "period": "Early Permian (about 290 million years ago)",
		"diet": "Carnivore", "habitat": "Land", "rarity": "epic", "model": "bone", "color": Color("b8a07e"), "shape": "bone", "case": "mega", "matrix": "jacket", "zone": "reef",
		"skeleton": "skeleton_dimetrodon", "pieces": ["skull", "jaw", "neck", "back", "ribs", "arms", "legs", "tail"],
		"size": "About 3.5 m long with a sail 1 m tall.",
		"fact": "Not a dinosaur! Dimetrodon is a synapsid - closer to mammals (and you) than to dinosaurs - and it died out 40 million years before the first dinosaur appeared."},
}

var LIVING := {
	"horseshoe_crab": {"name": "Atlantic Horseshoe Crab", "sci": "Limulus polyphemus",
		"fact": "Horseshoe crabs belong to a lineage around 450 million years old. Their blood is blue because it carries oxygen with copper instead of iron."},
	"nautilus": {"name": "Chambered Nautilus", "sci": "Nautilus pompilius",
		"fact": "The last living cephalopods with an external chambered shell, distant cousins of the extinct ammonites. They adjust buoyancy by moving fluid in and out of their chambers."},
}

# ----------------------------------------------------------- zones & nodes --
var ZONES := [
	{"id": "shore", "name": "Driftwood Shore", "era": "Cenozoic", "skill": "", "stars": 0, "x0": -25.0, "x1": 25.0, "cliff": "cliff_ceno"},
	{"id": "cliffs", "name": "Ammonite Cliffs", "era": "Mesozoic", "skill": "zone_cliffs", "stars": 1, "x0": 25.0, "x1": 65.0, "cliff": "cliff_meso"},
	{"id": "caves", "name": "Sea Caves", "era": "Mesozoic", "skill": "zone_caves", "stars": 2, "x0": 65.0, "x1": 105.0, "cliff": "cliff_meso"},
	{"id": "reef", "name": "Paleozoic Shelf", "era": "Paleozoic", "skill": "zone_reef", "stars": 3, "x0": -70.0, "x1": -25.0, "cliff": "cliff_paleo"},
]
const BEACH_Z0 := -10.0
const BEACH_Z1 := 44.0

## time: base seconds of HOLDING Use with a tier-1 tool on a normal-sized spot.
## life: seconds before an untouched spot weathers away. fossil: chance a drop is a fossil.
var NODE_TYPES := {
	"sand": {"name": "Sand Patch", "tool": "shovel", "tier": 1, "time": 2.8, "model": "node_sand", "sfx": "dig_sand", "drops": [1, 2], "fossil": 0.2, "life": [150.0, 240.0]},
	"dirt": {"name": "Dirt Mound", "tool": "shovel", "tier": 1, "time": 3.4, "model": "node_dirt", "sfx": "dig_sand", "drops": [1, 2], "fossil": 0.24, "life": [150.0, 240.0]},
	"buried": {"name": "Buried Find", "tool": "shovel", "tier": 1, "time": 3.8, "model": "node_buried", "sfx": "dig_sand", "drops": [1, 1], "fossil": 0.9, "life": [200.0, 300.0]},
	"dune": {"name": "Giant Dune Mound", "tool": "shovel", "tier": 2, "time": 12.0, "model": "node_big_sand", "sfx": "dig_sand", "drops": [2, 3], "fossil": 1.0, "big": true, "life": [100.0, 150.0]},
	"cracked": {"name": "Cracked Rock", "tool": "pick", "tier": 1, "time": 3.8, "model": "node_cracked_rock", "sfx": "dig_rock", "drops": [1, 2], "fossil": 0.25, "life": [160.0, 260.0]},
	"hard": {"name": "Crystal Boulder", "tool": "pick", "tier": 2, "time": 4.6, "model": "node_hard_rock", "sfx": "dig_rock", "drops": [1, 3], "fossil": 0.25, "life": [160.0, 260.0]},
	"deep": {"name": "Slate Outcrop", "tool": "pick", "tier": 3, "time": 5.4, "model": "node_deep_rock", "sfx": "dig_rock", "drops": [2, 3], "fossil": 0.3, "life": [160.0, 260.0]},
	"boulder": {"name": "Fossil Boulder", "tool": "pick", "tier": 2, "time": 14.0, "model": "node_big_rock", "sfx": "dig_rock", "drops": [2, 3], "fossil": 1.0, "big": true, "life": [110.0, 160.0]},
	"bonebed": {"name": "Bone Bed", "tool": "pick", "tier": 3, "time": 17.0, "model": "node_bonebed", "sfx": "dig_rock", "drops": [2, 4], "fossil": 1.0, "big": true, "life": [110.0, 160.0]},
}
## Target number of spots per zone (big ones only appear now and then).
var ZONE_NODES := {
	"shore": {"sand": 11, "dirt": 6, "buried": 3, "dune": 1},
	"cliffs": {"sand": 5, "cracked": 9, "buried": 4, "boulder": 1},
	"caves": {"cracked": 5, "hard": 8, "buried": 5, "boulder": 1},
	"reef": {"hard": 5, "deep": 9, "buried": 4, "bonebed": 1},
}
## Chance (per respawn check) that a missing BIG spot reappears.
const BIG_SPAWN_CHANCE := 0.3
var ZONE_GEMS := {
	"shore": [[30, "gem:sea_glass"], [24, "gem:quartz"], [14, "gem:copper"], [6, "geode"]],
	"cliffs": [[24, "gem:quartz"], [18, "gem:jasper"], [14, "gem:iron"], [8, "geode"]],
	"caves": [[18, "gem:iron"], [16, "gem:silver"], [10, "gem:opal"], [8, "gem:gold"], [8, "geode"]],
	"reef": [[16, "gem:silver"], [12, "gem:gold"], [10, "gem:sapphire"], [8, "gem:opal"], [8, "geode"]],
}
const RARITY_WEIGHT := {"common": 10.0, "uncommon": 5.0, "rare": 2.0, "epic": 0.7}
## Star rating that unlocks each case size (its blueprint's tree tier). A shore
## only gives fossils whose case is unlocked at that shore's own star rating.
const CASE_STARS := {"small": 0, "medium": 0, "big": 1, "mega": 2}


func zone_stars(zone: String) -> int:
	for z in ZONES:
		if z["id"] == zone:
			return int(z.get("stars", 0))
	return 0


## Fossil drop table for a zone + spot kind, built from the species list:
## ordinary spots give small/medium finds; big spots and buried finds favour big
## fossils, skeleton pieces and the rare stuff.
func fossil_table(zone: String, kind: String) -> Array:
	var big: bool = NODE_TYPES[kind].get("big", false)
	var buried := kind == "buried"
	var out: Array = []
	for sp in SPECIES.keys():
		var d: Dictionary = SPECIES[sp]
		if d["zone"] != zone:
			continue
		var c: String = d["case"]
		if int(CASE_STARS[c]) > zone_stars(zone):
			continue
		var w: float = RARITY_WEIGHT[d["rarity"]]
		var entry: String = ("piece:" if d.has("pieces") else "fossil:") + String(sp)
		if big:
			if c == "big" or c == "mega":
				w *= 3.0
			elif d["rarity"] == "rare" or d["rarity"] == "epic":
				w *= 1.0
			else:
				continue
		elif buried:
			if d["rarity"] == "common":
				w *= 0.3
			elif c == "big" or c == "mega":
				w *= 0.8
		else:
			if c == "big" or c == "mega":
				continue
		out.append([w, entry])
	return out


# ------------------------------------------------------------------ tools ---
var TOOLS := {
	"shovel_1": {"name": "Rusty Shovel", "kind": "shovel", "tier": 1, "speed": 1.0, "cost": 0, "req": "", "color": Color("a0522d"), "desc": "Digs sand, dirt and buried finds."},
	"shovel_2": {"name": "Steel Shovel", "kind": "shovel", "tier": 2, "speed": 1.6, "cost": 80, "req": "", "color": Color("b8c0c8"), "desc": "60% faster digging, and strong enough for Giant Dune Mounds."},
	"shovel_3": {"name": "Titanium Spade", "kind": "shovel", "tier": 3, "speed": 2.4, "cost": 320, "req": "equip_1", "color": Color("7fa7d9"), "desc": "Slices through sand like butter."},
	"pick_1": {"name": "Stone Pick", "kind": "pick", "tier": 1, "speed": 1.0, "cost": 50, "req": "", "color": Color("8a8478"), "desc": "Breaks cracked rock."},
	"pick_2": {"name": "Steel Pickaxe", "kind": "pick", "tier": 2, "speed": 1.5, "cost": 240, "req": "equip_1", "color": Color("b8c0c8"), "desc": "Breaks crystal boulders and Fossil Boulders."},
	"pick_3": {"name": "Diamond Pickaxe", "kind": "pick", "tier": 3, "speed": 2.2, "cost": 800, "req": "equip_2", "color": Color("7ff0ff"), "desc": "Splits Paleozoic slate outcrops and Bone Beds."},
	"detector_1": {"name": "Fossil Detector", "kind": "detector", "tier": 1, "radius": 9.0, "cost": 160, "req": "equip_1", "color": Color("b8c0c8"), "desc": "Pings when you walk near hidden buried fossils. Toggle with the detector key."},
	"detector_2": {"name": "Deep-Scan Detector", "kind": "detector", "tier": 2, "radius": 16.0, "cost": 550, "req": "equip_2", "color": Color("ffd23f"), "desc": "Much larger scan radius."},
	"lab_1": {"name": "Micro-Brush", "kind": "lab", "tier": 1, "cost": 0, "req": "", "color": Color("a0522d"), "desc": "Gentle and slow: it can never crack bone."},
	"lab_2": {"name": "Air Scribe", "kind": "lab", "tier": 2, "cost": 90, "req": "", "color": Color("b8c0c8"), "desc": "Chips a plus-shaped area fast, but can crack bone it touches."},
	"lab_3": {"name": "Pneumatic Pro Scribe", "kind": "lab", "tier": 3, "cost": 380, "req": "equip_2", "color": Color("7ff0ff"), "desc": "Clears a 3x3 area: only the centre cell risks damage."},
}
const PLUSHIE_PACK := {"count": 5, "cost": 20}

# ------------------------------------------------------------- skill tree ---
## A big pannable tree. Every node sits on a star tier (row 0-5 = museum stars
## needed) and a column; `req` are its parent nodes (all must be owned). `cost` is
## Upgrade Points, `cash` an optional extra price. "bp_" nodes unlock builds.
var SKILLS := {
	# Expedition
	"backpack_1": {"name": "Bigger Backpack I", "cost": 1, "cash": 0, "req": [], "tier": 0, "x": 0, "icon": "backpack", "desc": "+4 backpack slots."},
	"backpack_2": {"name": "Bigger Backpack II", "cost": 2, "cash": 60, "req": ["backpack_1"], "tier": 1, "x": 0, "icon": "backpack", "desc": "+4 backpack slots."},
	"backpack_3": {"name": "Bigger Backpack III", "cost": 3, "cash": 150, "req": ["backpack_2"], "tier": 2, "x": 0, "icon": "backpack", "desc": "+4 backpack slots."},
	"backpack_4": {"name": "Bigger Backpack IV", "cost": 4, "cash": 300, "req": ["backpack_3"], "tier": 3, "x": 0, "icon": "backpack", "desc": "+4 backpack slots."},
	"backpack_5": {"name": "Expedition Pack", "cost": 5, "cash": 600, "req": ["backpack_4"], "tier": 4, "x": 0, "icon": "backpack", "desc": "+4 backpack slots."},
	"dig_1": {"name": "Strong Arms I", "cost": 1, "cash": 0, "req": [], "tier": 0, "x": 1, "icon": "shovel", "desc": "Dig and mine 12% faster (hold-to-dig fills quicker)."},
	"dig_2": {"name": "Strong Arms II", "cost": 2, "cash": 40, "req": ["dig_1"], "tier": 1, "x": 1, "icon": "shovel", "desc": "Dig and mine another 12% faster."},
	"dig_3": {"name": "Strong Arms III", "cost": 3, "cash": 120, "req": ["dig_2"], "tier": 2, "x": 1, "icon": "shovel", "desc": "Dig and mine another 12% faster."},
	"dig_4": {"name": "Strong Arms IV", "cost": 3, "cash": 250, "req": ["dig_3"], "tier": 3, "x": 1, "icon": "pickaxe", "desc": "Dig and mine another 12% faster."},
	"dig_5": {"name": "Strong Arms V", "cost": 4, "cash": 450, "req": ["dig_4"], "tier": 4, "x": 1, "icon": "pickaxe", "desc": "Dig and mine another 12% faster."},
	"dig_6": {"name": "Master Excavator", "cost": 5, "cash": 800, "req": ["dig_5"], "tier": 5, "x": 1, "icon": "pickaxe", "desc": "Dig and mine another 12% faster."},
	"zone_cliffs": {"name": "Ammonite Cliffs Permit", "cost": 2, "cash": 0, "req": [], "tier": 1, "x": 2, "icon": "ammonite", "desc": "Open the cliffs east of the museum: ammonites, early dinosaurs and big fossils for the Big Case."},
	"zone_caves": {"name": "Sea Caves Permit", "cost": 3, "cash": 250, "req": ["zone_cliffs"], "tier": 2, "x": 2, "icon": "ammonite", "desc": "Open the coastal sea caves. T. rex, Triceratops, ichthyosaurs: whole skeletons for the Mega Case."},
	"zone_reef": {"name": "Paleozoic Shelf Permit", "cost": 5, "cash": 600, "req": ["zone_caves"], "tier": 3, "x": 2, "icon": "ammonite", "desc": "Open the ancient slate shelf to the west: trilobites, armoured fish and Dimetrodon."},
	"speed_1": {"name": "Beach Legs I", "cost": 1, "cash": 0, "req": [], "tier": 0, "x": 3, "icon": "happy", "desc": "+12% walk and sprint speed."},
	"speed_2": {"name": "Beach Legs II", "cost": 2, "cash": 0, "req": ["speed_1"], "tier": 1, "x": 3, "icon": "happy", "desc": "+12% walk and sprint speed."},
	"speed_3": {"name": "Beach Legs III", "cost": 3, "cash": 120, "req": ["speed_2"], "tier": 3, "x": 3, "icon": "happy", "desc": "+12% walk and sprint speed."},
	"lucky_1": {"name": "Fossil Eye I", "cost": 2, "cash": 0, "req": [], "tier": 1, "x": 4, "icon": "bone", "desc": "+15% chance that a dig turns up a fossil instead of a gem."},
	"lucky_2": {"name": "Fossil Eye II", "cost": 3, "cash": 200, "req": ["lucky_1"], "tier": 3, "x": 4, "icon": "bone", "desc": "+15% more fossil chance, and rare finds a little more often."},
	"lucky_3": {"name": "Fossil Eye III", "cost": 5, "cash": 600, "req": ["lucky_2"], "tier": 5, "x": 4, "icon": "bone", "desc": "Big dig spots appear twice as often."},
	"detector_range": {"name": "Keen Ears", "cost": 2, "cash": 80, "req": ["equip_1"], "tier": 1, "x": 23, "icon": "walkie", "desc": "+40% fossil detector radius."},
	# Museum
	"ticket_1": {"name": "Marketing I", "cost": 1, "cash": 0, "req": [], "tier": 0, "x": 6, "icon": "ticket", "desc": "+$2 base ticket price."},
	"ticket_2": {"name": "Marketing II", "cost": 2, "cash": 0, "req": ["ticket_1"], "tier": 1, "x": 6, "icon": "ticket", "desc": "+$3 base ticket price."},
	"ticket_3": {"name": "Marketing III", "cost": 3, "cash": 0, "req": ["ticket_2"], "tier": 2, "x": 6, "icon": "ticket", "desc": "+$4 base ticket price."},
	"ticket_4": {"name": "Marketing IV", "cost": 4, "cash": 0, "req": ["ticket_3"], "tier": 4, "x": 6, "icon": "ticket", "desc": "+$6 base ticket price."},
	"ticket_5": {"name": "Billboard on the Highway", "cost": 5, "cash": 500, "req": ["ticket_4"], "tier": 5, "x": 6, "icon": "ticket", "desc": "+$8 base ticket price and more visitors."},
	"expand_1": {"name": "Expansion I", "cost": 2, "cash": 400, "req": [], "tier": 1, "x": 7, "icon": "gear", "desc": "Builds a bigger museum right away: 6x5 floor."},
	"expand_2": {"name": "Expansion II", "cost": 3, "cash": 900, "req": ["expand_1"], "tier": 2, "x": 7, "icon": "gear", "desc": "Builds a bigger museum right away: 7x6 floor."},
	"expand_3": {"name": "Expansion III + Office", "cost": 4, "cash": 1800, "req": ["expand_2"], "tier": 3, "x": 7, "icon": "gear", "desc": "9x6 floor, plus a Curator's Office with a computer in the Prep Lab: J-Mail brings school trips, offers... and scams."},
	"expand_4": {"name": "Expansion IV", "cost": 6, "cash": 3500, "req": ["expand_3"], "tier": 4, "x": 7, "icon": "gear", "desc": "The grand hall: 11x7 floor."},
	"refund_1": {"name": "Resale Contacts I", "cost": 1, "cash": 0, "req": [], "tier": 0, "x": 8, "icon": "coin", "desc": "Selling builds in Build Mode returns 40% of the price (base 25%)."},
	"refund_2": {"name": "Resale Contacts II", "cost": 2, "cash": 100, "req": ["refund_1"], "tier": 2, "x": 8, "icon": "coin", "desc": "Selling builds returns 55%."},
	"refund_3": {"name": "Resale Contacts III", "cost": 3, "cash": 300, "req": ["refund_2"], "tier": 4, "x": 8, "icon": "coin", "desc": "Selling builds returns 70%."},
	"audio_guide": {"name": "Audio Guide", "cost": 3, "cash": 200, "req": ["ticket_2"], "tier": 2, "x": 9, "icon": "research", "desc": "Visitors learn more from every exhibit: +mood and better reviews."},
	"membership": {"name": "Museum Membership", "cost": 4, "cash": 400, "req": ["audio_guide"], "tier": 3, "x": 9, "icon": "star", "desc": "Members keep coming back: +4% Quality after every open day with visitors."},
	"press_kit": {"name": "Press Kit", "cost": 4, "cash": 500, "req": ["membership"], "tier": 4, "x": 9, "icon": "walkie", "desc": "Newspapers write about you: +25% visitors."},
	# Exhibit blueprints
	"bp_case_medium": {"name": "Blueprint: Medium Case", "cost": 1, "cash": 40, "req": [], "tier": 0, "x": 11, "icon": "bone", "desc": "Build Medium Fossil Display Cases (2x1) for hand- to arm-sized fossils."},
	"bp_case_big": {"name": "Blueprint: Big Case", "cost": 2, "cash": 150, "req": ["bp_case_medium"], "tier": 1, "x": 11, "icon": "bone", "desc": "Build Big Fossil Display Cases (2x2) for skulls, horns and other huge single fossils."},
	"bp_case_mega": {"name": "Blueprint: Mega Case", "cost": 3, "cash": 300, "req": ["bp_case_big"], "tier": 2, "x": 11, "icon": "bone", "desc": "Build the Mega Display Case (3x3): assemble skeleton bones into a towering skeleton."},
	"bp_touch": {"name": "Blueprint: Touch Table", "cost": 1, "cash": 60, "req": [], "tier": 1, "x": 12, "icon": "happy", "desc": "A 'Please Touch!' table of fossil casts. Kids love it."},
	"bp_microscope": {"name": "Blueprint: Microscope Station", "cost": 2, "cash": 150, "req": ["bp_touch"], "tier": 2, "x": 12, "icon": "research", "desc": "Look at microfossils. Fossil enthusiasts adore it."},
	"bp_volcano": {"name": "Blueprint: Volcano Diorama", "cost": 3, "cash": 400, "req": ["bp_microscope"], "tier": 3, "x": 12, "icon": "star", "desc": "A smoking Cretaceous volcano diorama (2x2). Big fun."},
	"bp_time_tunnel": {"name": "Blueprint: Time Tunnel", "cost": 4, "cash": 700, "req": ["bp_volcano"], "tier": 4, "x": 12, "icon": "calendar", "desc": "Walk through the rock layers from oldest to youngest (2x1)."},
	"lic_aquarium": {"name": "Living Fossil Aquariums", "cost": 3, "cash": 400, "req": ["bp_case_big"], "tier": 3, "x": 13, "icon": "heart", "desc": "Saltwater tanks with horseshoe crabs and nautiluses. Guests pay to feed them."},
	"lic_holo": {"name": "Prehistoric Holo-Theater", "cost": 5, "cash": 1500, "req": ["lic_aquarium"], "tier": 4, "x": 13, "icon": "star", "desc": "High-end projection rings. Huge fun. Best beside a complete skeleton."},
	# Attractions & food
	"lic_food": {"name": "Food Vendor License", "cost": 1, "cash": 50, "req": [], "tier": 1, "x": 15, "icon": "coin", "desc": "Build Dino-Dog, Fossil Popcorn and Amber Lemonade stands. You serve the queue yourself!"},
	"bp_icecream": {"name": "Blueprint: Ice Cream Cart", "cost": 2, "cash": 150, "req": ["lic_food"], "tier": 2, "x": 15, "icon": "coin", "desc": "Ice Age Ice Cream: the snack everyone queues for."},
	"bp_dig_pit": {"name": "Blueprint: Junior Dig Pit", "cost": 1, "cash": 80, "req": [], "tier": 1, "x": 16, "icon": "shovel", "desc": "Kids pay to dig up your duplicate fossils. Calms tantrums."},
	"bp_dino_slide": {"name": "Blueprint: Dino Slide", "cost": 3, "cash": 350, "req": ["bp_dig_pit"], "tier": 3, "x": 16, "icon": "happy", "desc": "A sauropod-shaped slide (2x2). Kids stop tantrums to play on it."},
	"bp_photo_booth": {"name": "Blueprint: Photo Booth", "cost": 1, "cash": 60, "req": [], "tier": 1, "x": 17, "icon": "star", "desc": "'Selfie with a T. rex' cut-out board. Tourists post photos (free publicity)."},
	"bp_gift_shop": {"name": "Blueprint: Gift Shop", "cost": 2, "cash": 150, "req": ["bp_photo_booth"], "tier": 2, "x": 17, "icon": "gem", "desc": "Geode Cracker & Gift Shop: sells stored gems at 1.5x, cracks geodes, sells plushies."},
	"souvenir": {"name": "Souvenir Markup", "cost": 2, "cash": 0, "req": ["bp_gift_shop"], "tier": 3, "x": 17, "icon": "coin", "desc": "+25% gift shop income."},
	"bp_fountain": {"name": "Blueprint: Water Fountain", "cost": 1, "cash": 40, "req": [], "tier": 0, "x": 18, "icon": "heart", "desc": "Thirsty visitors stay happier."},
	"bp_vending": {"name": "Blueprint: Vending Machine", "cost": 2, "cash": 120, "req": ["bp_fountain"], "tier": 2, "x": 18, "icon": "coin", "desc": "Sells snacks by itself - no queue to serve."},
	# Decor blueprints
	"bp_lamp": {"name": "Blueprint: Brass Lamp", "cost": 1, "cash": 20, "req": [], "tier": 0, "x": 20, "icon": "star", "desc": "Warm lighting decoration."},
	"bp_banner": {"name": "Blueprint: Banner", "cost": 1, "cash": 30, "req": ["bp_lamp"], "tier": 1, "x": 20, "icon": "star", "desc": "Teal and gold museum banners."},
	"bp_dino_statue": {"name": "Blueprint: Dino Statue", "cost": 2, "cash": 80, "req": ["bp_banner"], "tier": 2, "x": 20, "icon": "happy", "desc": "A friendly dino statue. Kids love it."},
	"bp_ammonite_fountain": {"name": "Blueprint: Ammonite Fountain", "cost": 3, "cash": 250, "req": ["bp_dino_statue"], "tier": 3, "x": 20, "icon": "ammonite", "desc": "A splashing stone ammonite fountain. Lots of decoration."},
	"bp_rug": {"name": "Blueprint: Ammonite Rug", "cost": 1, "cash": 15, "req": [], "tier": 0, "x": 21, "icon": "ammonite", "desc": "A walkable rug decoration."},
	"bp_fern_garden": {"name": "Blueprint: Fern Garden", "cost": 1, "cash": 50, "req": ["bp_rug"], "tier": 1, "x": 21, "icon": "heart", "desc": "Prehistoric plants: tree ferns, cycads and horsetails."},
	"bp_bookshelf": {"name": "Blueprint: Bookshelf", "cost": 2, "cash": 80, "req": ["bp_fern_garden"], "tier": 2, "x": 21, "icon": "research", "desc": "A reading nook of field guides. Enthusiasts approve."},
	# Trade & gear
	"equip_1": {"name": "Better Equipment I", "cost": 2, "cash": 0, "req": [], "tier": 0, "x": 23, "icon": "pickaxe", "desc": "Pearl stocks steel pickaxes, titanium spades and fossil detectors."},
	"equip_2": {"name": "Better Equipment II", "cost": 4, "cash": 300, "req": ["equip_1"], "tier": 3, "x": 23, "icon": "pickaxe", "desc": "Pearl stocks diamond pickaxes, deep-scan detectors and pro scribes."},
	"haggle": {"name": "Gem Haggling", "cost": 2, "cash": 0, "req": [], "tier": 0, "x": 24, "icon": "gem", "desc": "+20% cash when selling gems and ores at the shop."},
	"haggle_2": {"name": "Gem Dealer", "cost": 3, "cash": 150, "req": ["haggle"], "tier": 2, "x": 24, "icon": "gem", "desc": "Another +20% for gems and ores."},
	# Staff
	"job_janitor": {"name": "Job: Janitor", "cost": 1, "cash": 0, "req": [], "tier": 1, "x": 26, "icon": "broom", "desc": "Lets you hire Janitors (sweep trash and sand, empty bins, clean restrooms). You still need a staff slot."},
	"job_security": {"name": "Job: Security Guard", "cost": 2, "cash": 100, "req": ["job_janitor"], "tier": 2, "x": 26, "icon": "warning", "desc": "Lets you hire Security Guards: they catch shoplifters and spies, stop climbers and calm tantrums."},
	"job_intern": {"name": "Job: Paleontology Intern", "cost": 3, "cash": 150, "req": ["job_security"], "tier": 3, "x": 26, "icon": "research", "desc": "Lets you hire Interns: they correct every plaque each morning and impress enthusiasts."},
	"job_vendor": {"name": "Job: Snack Vendor", "cost": 2, "cash": 80, "req": [], "tier": 1, "x": 27, "icon": "coin", "desc": "Lets you hire Snack Vendors: they serve whichever snack stand has a queue."},
	"staff_training": {"name": "Staff Training", "cost": 2, "cash": 200, "req": ["job_vendor", "staff_slot_1"], "tier": 4, "x": 27, "icon": "heart", "desc": "Staff go rogue half as often and lose morale more slowly."},
	"staff_slot_1": {"name": "Staff Slot +1", "cost": 2, "cash": 0, "req": [], "tier": 2, "x": 28, "icon": "staff", "desc": "+1 max employee. You start with none."},
	"staff_slot_2": {"name": "Staff Slot +1 (II)", "cost": 3, "cash": 150, "req": ["staff_slot_1"], "tier": 3, "x": 28, "icon": "staff", "desc": "+1 max employee."},
	"staff_slot_3": {"name": "Staff Slot +1 (III)", "cost": 3, "cash": 300, "req": ["staff_slot_2"], "tier": 4, "x": 28, "icon": "staff", "desc": "+1 max employee."},
	"staff_slot_4": {"name": "Staff Slot +1 (IV)", "cost": 4, "cash": 500, "req": ["staff_slot_3"], "tier": 5, "x": 28, "icon": "staff", "desc": "+1 max employee."},
	# Hotbar
	"hotbar_1": {"name": "Tool Belt +1", "cost": 1, "cash": 30, "req": [], "tier": 1, "x": 30, "icon": "shovel", "desc": "+1 hotbar slot (start with 3)."},
	"hotbar_2": {"name": "Tool Belt +1 (II)", "cost": 2, "cash": 80, "req": ["hotbar_1"], "tier": 2, "x": 30, "icon": "shovel", "desc": "+1 hotbar slot."},
	"hotbar_3": {"name": "Tool Belt +1 (III)", "cost": 2, "cash": 150, "req": ["hotbar_2"], "tier": 3, "x": 30, "icon": "shovel", "desc": "+1 hotbar slot."},
	"hotbar_4": {"name": "Tool Belt +1 (IV)", "cost": 3, "cash": 250, "req": ["hotbar_3"], "tier": 4, "x": 30, "icon": "shovel", "desc": "+1 hotbar slot."},
	"hotbar_5": {"name": "Tool Belt +1 (V)", "cost": 3, "cash": 400, "req": ["hotbar_4"], "tier": 5, "x": 30, "icon": "shovel", "desc": "+1 hotbar slot."},
}
const SKILL_BRANCHES := [["Expedition", 0, 4], ["Museum", 6, 9], ["Exhibits", 11, 13], ["Attractions & Food", 15, 18], ["Decor", 20, 21], ["Trade & Gear", 23, 24], ["Staff", 26, 28], ["Hotbar", 30, 30]]
const SKILL_COLUMNS := 31
const QUIT_LINES := ["I'm outta here!", "I didn't sign up for this!", "My cousin's crab shack is hiring.", "Find someone else to sweep your sand!",
	"I'm going back to finger-painting trilobites.", "This museum is a fossil and so is my paycheck."]

# -------------------------------------------------------------- buildables --
## size in cells (x = width, y = depth). lic = Upgrade Tree node that unlocks it ("" = starter).
var BUILD := {
	"display_case": {"name": "Fossil Display Case", "cat": "Exhibits", "cost": 40, "size": Vector2i(1, 1), "model": "display_case", "lic": "", "fun": 0, "decor": 0,
		"desc": "Small case for small fossils (teeth, shells, trilobites...). Customise its plaque for an education bonus."},
	"display_case_medium": {"name": "Medium Fossil Display Case", "cat": "Exhibits", "cost": 110, "size": Vector2i(2, 1), "model": "display_case_medium", "lic": "bp_case_medium", "fun": 0, "decor": 0,
		"desc": "Long case for medium fossils (big teeth, claws, fish slabs, paddle bones)."},
	"display_case_big": {"name": "Big Fossil Display Case", "cat": "Exhibits", "cost": 280, "size": Vector2i(2, 2), "model": "display_case_big", "lic": "bp_case_big", "fun": 0, "decor": 1,
		"desc": "Raised island for big single fossils (skulls, horns, plates, tusks)."},
	"display_case_mega": {"name": "Mega Display Case", "cat": "Exhibits", "cost": 450, "size": Vector2i(3, 3), "model": "display_case_mega", "lic": "bp_case_mega", "fun": 0, "decor": 2,
		"desc": "Assemble the bones of one skeleton species into a towering skeleton."},
	"plaque_checker": {"name": "Fact-Check Kiosk", "cat": "Exhibits", "cost": 30, "size": Vector2i(1, 1), "model": "plaque_checker", "lic": "", "fun": 0, "decor": 1,
		"desc": "Lists every case with a wrong or blank plaque (lamp turns red). Nerds tear apart museums with wrong plaques!"},
	"touch_table": {"name": "Touch Table", "cat": "Exhibits", "cost": 90, "size": Vector2i(1, 1), "model": "touch_table", "lic": "bp_touch", "fun": 8, "decor": 1,
		"desc": "Fossil casts visitors may handle. Kids especially love it."},
	"microscope_station": {"name": "Microscope Station", "cat": "Exhibits", "cost": 160, "size": Vector2i(1, 1), "model": "microscope_station", "lic": "bp_microscope", "fun": 10, "decor": 1,
		"desc": "Microfossils under the scope. Fossil enthusiasts tip here."},
	"aquarium": {"name": "Living Fossil Aquarium", "cat": "Attractions", "cost": 600, "size": Vector2i(2, 1), "model": "aquarium", "lic": "lic_aquarium", "fun": 16, "decor": 2,
		"desc": "Horseshoe crabs and nautiluses. Guests pay $4 for feeding."},
	"dig_pit": {"name": "Junior Dino-Dig Pit", "cat": "Attractions", "cost": 150, "size": Vector2i(2, 2), "model": "dig_pit", "lic": "bp_dig_pit", "fun": 12, "decor": 0,
		"desc": "Bury duplicate fossils here. Kids pay $5 to dig and it calms tantrums."},
	"gift_shop": {"name": "Geode Cracker & Gift Shop", "cat": "Attractions", "cost": 250, "size": Vector2i(2, 1), "model": "gift_shop", "lic": "bp_gift_shop", "fun": 6, "decor": 1,
		"desc": "Sells stored gems at 1.5x, cracks stored geodes for tourists and sells plushies."},
	"holo_theater": {"name": "Prehistoric Holo-Theater", "cat": "Attractions", "cost": 2000, "size": Vector2i(2, 2), "model": "holo_theater", "lic": "lic_holo", "fun": 34, "decor": 3,
		"desc": "Projects animated visuals. Doubles its fun near a complete skeleton."},
	"volcano_diorama": {"name": "Volcano Diorama", "cat": "Attractions", "cost": 520, "size": Vector2i(2, 2), "model": "volcano_diorama", "lic": "bp_volcano", "fun": 22, "decor": 4,
		"desc": "A smoking Cretaceous volcano with tiny dinosaurs."},
	"dino_slide": {"name": "Dino Slide", "cat": "Attractions", "cost": 380, "size": Vector2i(2, 2), "model": "dino_slide", "lic": "bp_dino_slide", "fun": 16, "decor": 1,
		"desc": "Kids slide down a sauropod's neck. Calms tantrums."},
	"photo_booth": {"name": "Dino Photo Booth", "cat": "Attractions", "cost": 70, "size": Vector2i(1, 1), "model": "photo_booth", "lic": "bp_photo_booth", "fun": 5, "decor": 2,
		"desc": "Selfie with a T. rex! Tourists' photos bring a little publicity."},
	"time_tunnel": {"name": "Time Tunnel", "cat": "Attractions", "cost": 800, "size": Vector2i(2, 1), "model": "time_tunnel", "lic": "bp_time_tunnel", "fun": 18, "decor": 4,
		"desc": "Walk through the strata: Paleozoic at the bottom, Cenozoic on top."},
	"popcorn_stand": {"name": "Fossil Popcorn Stand", "cat": "Concessions", "cost": 120, "size": Vector2i(1, 1), "model": "popcorn_stand", "lic": "lic_food", "fun": 3, "decor": 0, "price": 4, "serve": "held_bag", "item": "popcorn",
		"desc": "Guests queue here. Grab a bag, fill it at the machine and serve them before they give up. Creates trash."},
	"dinodog_stand": {"name": "Dino-Dog Stand", "cat": "Concessions", "cost": 140, "size": Vector2i(1, 1), "model": "dinodog_stand", "lic": "lic_food", "fun": 3, "decor": 0, "price": 5, "serve": "held_dog", "item": "Dino-Dog",
		"desc": "Guests queue here. Grab a bun, add a dog from the grill and serve them before they give up. Creates trash."},
	"lemonade_stand": {"name": "Amber Lemonade Stand", "cat": "Concessions", "cost": 100, "size": Vector2i(1, 1), "model": "lemonade_stand", "lic": "lic_food", "fun": 2, "decor": 1, "price": 3, "serve": "held_cup", "item": "lemonade",
		"desc": "Guests queue here. Grab a cup, fill it from the jug and serve them. Refreshed guests stay longer."},
	"ice_cream_stand": {"name": "Ice Age Ice Cream Cart", "cat": "Concessions", "cost": 170, "size": Vector2i(1, 1), "model": "ice_cream_stand", "lic": "bp_icecream", "fun": 4, "decor": 1, "price": 6, "serve": "held_cup", "item": "ice cream",
		"desc": "Grab a cup, scoop it from the freezer and serve the queue. Kids go wild for it."},
	"restroom": {"name": "Restroom", "cat": "Amenities", "cost": 90, "size": Vector2i(1, 1), "model": "restroom", "lic": "", "fun": 0, "decor": 0,
		"desc": "Essential for cleanliness once crowds grow. Gets dirty."},
	"trash_bin": {"name": "Trash Bin", "cat": "Amenities", "cost": 15, "size": Vector2i(1, 1), "model": "trash_bin", "lic": "", "fun": 0, "decor": 0,
		"desc": "Guests nearby throw trash in it instead of on the floor. Throw picked-up trash in it. Empty it when full."},
	"bench": {"name": "Bench", "cat": "Amenities", "cost": 25, "size": Vector2i(1, 1), "model": "bench", "lic": "", "fun": 1, "decor": 2,
		"desc": "Tired guests rest here."},
	"water_fountain": {"name": "Water Fountain", "cat": "Amenities", "cost": 45, "size": Vector2i(1, 1), "model": "water_fountain", "lic": "bp_fountain", "fun": 1, "decor": 0,
		"desc": "Thirsty visitors drink here and stay happier."},
	"vending_machine": {"name": "Dino Snacks Vending Machine", "cat": "Amenities", "cost": 160, "size": Vector2i(1, 1), "model": "vending_machine", "lic": "bp_vending", "fun": 1, "decor": 0,
		"desc": "Sells snacks by itself ($3 each). Snack wrappers end up as trash."},
	"plant_pot": {"name": "Potted Fern", "cat": "Decor", "cost": 20, "size": Vector2i(1, 1), "model": "plant_pot", "lic": "", "fun": 0, "decor": 4, "desc": "Greenery."},
	"rug": {"name": "Ammonite Rug", "cat": "Decor", "cost": 25, "size": Vector2i(1, 1), "model": "rug", "lic": "bp_rug", "fun": 0, "decor": 3, "walkable": true, "desc": "Guests can walk on it."},
	"floor_lamp": {"name": "Brass Lamp", "cat": "Decor", "cost": 35, "size": Vector2i(1, 1), "model": "floor_lamp", "lic": "bp_lamp", "fun": 0, "decor": 4, "desc": "Warm lighting."},
	"banner": {"name": "Museum Banner", "cat": "Decor", "cost": 30, "size": Vector2i(1, 1), "model": "banner", "lic": "bp_banner", "fun": 0, "decor": 4, "desc": "Teal and gold."},
	"dino_statue": {"name": "Friendly Dino Statue", "cat": "Decor", "cost": 120, "size": Vector2i(1, 1), "model": "dino_statue", "lic": "bp_dino_statue", "fun": 2, "decor": 10, "desc": "Kids love it."},
	"fern_garden": {"name": "Prehistoric Fern Garden", "cat": "Decor", "cost": 70, "size": Vector2i(1, 1), "model": "fern_garden", "lic": "bp_fern_garden", "fun": 1, "decor": 7, "desc": "Tree ferns, cycads and horsetails - plants older than dinosaurs."},
	"ammonite_fountain": {"name": "Ammonite Fountain", "cat": "Decor", "cost": 260, "size": Vector2i(1, 1), "model": "ammonite_fountain", "lic": "bp_ammonite_fountain", "fun": 2, "decor": 14, "desc": "A splashing stone ammonite."},
	"bookshelf": {"name": "Field Guide Bookshelf", "cat": "Decor", "cost": 90, "size": Vector2i(1, 1), "model": "bookshelf", "lic": "bp_bookshelf", "fun": 2, "decor": 5, "desc": "Fossil enthusiasts love a good library."},
}
const BUILD_CATS := ["Exhibits", "Attractions", "Concessions", "Amenities", "Decor"]
const DISPLAY_CASES := ["display_case", "display_case_medium", "display_case_big", "display_case_mega"]

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
	"student": {"name": "Student", "stars": 0},
	"fan": {"name": "Fan", "stars": 0},
}
var FIRST_NAMES := ["Alex", "Bo", "Cleo", "Dana", "Eli", "Fatima", "Gus", "Hana", "Ivo", "Jade", "Kofi", "Lena", "Milo", "Nia", "Oscar", "Pia",
	"Quinn", "Ravi", "Sofia", "Theo", "Uma", "Vic", "Wes", "Ximena", "Yara", "Zed", "Ana", "Ben", "Chen", "Dmitri", "Esme", "Femi"]
var CELEB_NAMES := ["DJ Trilobyte", "Coral Monroe", "Rex Sterling", "Lady Amber", "Marina Vale", "Captain Splash"]
var CRITIC_NAMES := ["V. Pemberton (Coastal Gazette)", "H. Okafor (Museum Monthly)", "L. Duval (The Fossil Review)"]
var SCHOOLS := ["Seaview Primary", "Coral Bay Elementary", "St. Anning's School", "Driftwood Middle School", "Harbour Hill Academy", "Lighthouse Lane School"]
var TEACHER_NAMES := ["Ms. Okafor", "Mr. Lindqvist", "Mrs. Patel", "Mr. Alvarez", "Ms. Nakamura", "Mrs. O'Brien"]

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
	"touch": ["My kids got to TOUCH a fossil. Magic.", "The touch table is genius."],
	"microscope": ["Saw tiny fossils under the microscope. Mind blown!"],
	"volcano": ["That volcano diorama is amazing!"],
	"slide": ["The dino slide! My kids want to live here."],
	"photo": ["Took the best photo with the T. rex board!"],
	"tunnel": ["Walking through the Time Tunnel finally made rock layers make sense."],
	"tour": ["The owner gave the best school tour I've ever seen!", "Our class learned SO much on the tour."],
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
	"hit_by_car": ["I got hit by a car on the way in. Not the museum's fault, but still.", "Watch out for the traffic outside!"],
	"bad_tour": ["The owner told our class something completely WRONG on the tour. Unacceptable for a museum.",
		"Our school tour was full of mistakes. The children knew more than the guide!"],
}
