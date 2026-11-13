# Tide & Trove — Learn-by-Playing Plan

*Status: design proposal (not implemented yet).*

**Goal:** players come away knowing real paleontology and geology. The game stays a museum-management sim, never a quiz game.

## Design rules (the guardrails)

1. **Knowledge is a strategy, never a gate.** Every fact gives a small, optional edge: more money, better reviews, faster digs.
   - Nothing in the main loop *requires* recalling a fact.
   - The skill ceiling rises; the floor never does.
2. **There is always a non-learning path.** Any knowledge task can be handed to staff (the Intern) or tools (the Field Guide, the detector) for a cost.
   - The GDD's "zero penalties for skipping" stays true.
3. **Facts arrive at the moment they are useful.** Show the fact where the decision is: at the dig face, the display case, the lab bench, the guest.
   - No text walls and no separate "learning mode".
4. **Show before tell.** The world itself carries the information:
   - Strata colours, relief fossils in the cliffs, skeleton anatomy, size-comparison plaques.
   - Text confirms what the player already noticed.
5. **Feedback through the sim.** Learning shows up in the genre's own currencies, so it never feels like grading:
   - Reviews, Quality, ticket price, enthusiast tips, critic stars.
6. **Accuracy is a dial.** All facts come from `db.gd`. The one fictional species (*Pelagotyrannus*) stays clearly labelled.
   - **Mismatch to fix:** the beach comment says "Jurassic cliffs, Cretaceous caves" but the data stores only the era. Store the period too, and give `period` a short "when" line.

## What already exists (build on it, don't replace it)

| Existing hook | Where | Reuse for |
|---|---|---|
| Plaque Builder (era / diet / habitat), accuracy bonus (+$0.50 ticket, Fun ×1.2, enthusiast tips) | `panels.gd:686-767`, `placed_object.gd:327-358`, `guest.gd:443-453` | Core "curation" loop; extend, don't add a second one |
| Field Guide with species pages, era sections and "???" hints | `panels.gd:299-389` | The always-available reference; this is what keeps learning optional |
| Real strata zones (Cenozoic shore, Mesozoic cliffs and caves, Paleozoic shelf) with era-specific drop tables | `db.gd:128-172`, `beach.gd` | "Where to dig" knowledge pays off directly |
| Relief fossils in each era's cliffs, skeleton tailbends, sclerotic eye rings, scale-figure plaque (new Blender art) | `blender/ttassets/env.py`, `specimens.py`, `props.py` | Visual teaching that needs no UI |
| Field-trip trivia (one question, +1 UP) | `world.gd:364-385`, `panels.gd:963-982` | Reframe as a *tour* the player gives (see 4) |
| Intern auto-fills plaques; intern chatter facts | `day_cycle.gd:98-111`, `staff.gd:85` | The "delegate learning" path |
| Prep Lab with brush vs air scribe, preservation % | `lab_game.gd` | Technique knowledge (see 5) |
| Reward APIs: `GameState.earn()`, `up += n`, `_note()` + `REVIEW_GOOD` / `REVIEW_BAD`, `quality`, `Events.say` / `radio` | see the survey notes in this doc's history | Every mechanic below plugs into these |

## The mechanics

Each mechanic below lists:
- **Learn:** what the player learns.
- **Why it's fun:** why it plays as management.
- **Skip path:** what happens if they don't engage.
- **Hooks:** the code it plugs into.

### 1. Gallery Themes (set bonuses from real relationships) — *highest value, build first*

Exhibits placed near each other form a **themed gallery** when they share a real relationship. Build mode shows a soft outline around them, plus a name: "Jurassic Seas", "Living Fossils & Their Ancestors", "Filter Feeders Through Time", "Apex Predators".

- **Bonus:** each theme adds Decor, a review line ("Loved how the Jurassic room told a story!") and a ticket bump. It works like set bonuses in tycoon games.
- **Learn:** which animals lived together (era), shared ecology (diet / habitat), and ancestry. Examples:
  - Nautilus next to ammonites.
  - Horseshoe crab next to trilobites as distant arthropod kin.
- **Why it's fun:** it's pure layout optimization, which is the genre's core verb. Discovering a new theme feels like finding a combo.
- **Skip path:** no penalty. Themes are discovered by experimenting, and the Field Guide lists which tags a theme needs once you've seen it.
- **Hooks:** `Museum.objects_of()`, `PlacedObject.fossil_entry()`, and the pillar computation in `museum.gd:452-476`. Add `DB.THEMES` as tag rules.

### 2. The Timeline Walk (layout that teaches deep time)

If the guest path through display cases runs **Paleozoic → Mesozoic → Cenozoic**, guests get a "Story Flow" mood bonus. A thin painted **timeline stripe** on the floor tiles lights up era by era as the order is satisfied.

- **Learn:** the order of the eras, and which fossils belong to each. Players absorb it by arranging rooms.
- **Skip path:** rooms in any order work fine; this is just extra mood.
- **Hooks:** the guest A* path already exists in `museum.gd`. Score the order of cases visited along the default route.

### 3. Read the Rocks (geology as a dig strategy)

- **Index fossils:** the first time you dig an index fossil (an ammonite in the cliffs, a trilobite on the shelf), the detector learns that zone's "signature". After that, hidden buried nodes in the matching strata show a faint era-coloured ping.
- **Learn:** index fossils date rocks; each era's strata hold different life.
- **Tide window:** the reef / shelf's low-tide nodes (a new node variant) are only diggable while a "tide" timer is low. The tide clock sits on the HUD with a one-line *why* the first time.
- **Why it's fun:** it's route planning and timing. Knowing *where* to dig means more loot per in-game day.
- **Skip path:** dig anywhere; drops still roll normally. The bonus is just better odds.
- **Hooks:**
  - `DigNode.reveal()` and the drop roll in `dig_node.gd:61-118`.
  - The `ZONE_NODES` / `DROPS` tables.
  - Add a `GameState.flags["index_known"]` set.

### 4. Guided Tours instead of trivia questions

Replace the single trivia pop-up with a **tour** the player *leads*. Walk a school group or a VIP to up to three exhibits and pick one "talking point" from two or three options per exhibit.

- **Talking points are true facts, not right/wrong answers.** They are also flavoured to the audience:
  - **Kids:** "big eyes to see in the dark sea".
  - **Enthusiasts:** "the sclerotic ring".
  - **Critics:** "the 1811 Anning discovery".
- **Scoring:** matching the point to the audience earns bigger tips and reviews. Picking any point still pays out.
- **Learn:** facts get reused in context. Matching facts to audiences is a soft comprehension check with no "wrong" screen.
- **Skip path:** the Intern can run tours (less income), or decline the tour (no penalty).
- **Hooks:**
  - Field-trip spawn in `day_cycle.gd:242-248`.
  - `on_field_trip_done` in `world.gd`.
  - The `trivia` panel becomes `tour`.
  - Rewards via `GameState.earn("Tips & donations")` and `up += 1`.

### 5. Lab technique matters (learn by doing)

Matrix type follows the zone's real rock:
- Sandstone on the shore.
- Shale and limestone in the cliffs.
- Nodules in the caves.
- Slate on the shelf.

Each matrix favours a tool (brush for soft sand, air scribe for limestone, consolidant glue for crumbly shale). The bench shows a tiny "rock card" the first time you meet a matrix. The right tool raises preservation, which raises exhibit Fun and ticket price.

- **Learn:** how real fossil preparation works, and why rock type matters.
- **Skip path:** any tool works, just with more cracks.
- **Hooks:**
  - `lab_game.gd` hardness grid (already 1-3; map it per matrix).
  - Preservation → fun (`placed_object.gd:357`).
  - The GDD's "preservation affects ticket price" (`game_state.gd:186`), which the code doesn't do yet.

### 6. Collection cards with tiered facts (collecting, not studying)

Each species page in the Field Guide becomes a **card with 3 fact tiers**:
- **Tier 1:** unlocks on first find.
- **Tier 2:** unlocks after a Pristine prep or 3 specimens.
- **Tier 3:** unlocks after an accurate plaque and a Gallery Theme that uses it.

Completing a card pays UP and unlocks a cosmetic. Examples: a mini replica for the gift shop, or a poster for the walls (the new `wall` model already has a poster frame).

- **Learn:** facts deepen as you play more with each species.
- **Why it's fun:** collection completion, the familiar "Pokédex" pull.
- **Hooks:** `GameState.discovered[sp]`, `claim()` in `game_state.gd:392-404`, and the species page renderer in `panels.gd:350-381`.

### 7. Misinformation & Forgeries (Act 3, learn to spot a fake)

Grimsby Extraction Co. sometimes offers **cheap "rare" fossils** through a shady dealer at the shop. Some are forgeries with a real-world tell:
- A "trilobite" with no compound eyes.
- A "mosasaur" tooth with no serrations.
- A "Cenozoic" dinosaur.

**Outcomes:**
- **Display a fake:** a critic eventually exposes it (Quality hit, review scandal).
- **Turn it down or report it:** UP plus a story beat.

- **Learn:** anatomy and era logic, used as detective work. It fits the existing spy and story arc.
- **Skip path:** just never buy from the dealer. Or hire the Intern, who flags fakes for a fee.
- **Hooks:** Act 3 flags in `world.gd`, `DB.REVIEW_BAD`, the shop panel, and `critic` guests (`guest.gd:91`).

### 8. Ambient learning (zero friction)

All three are optional, and Settings gets a "museum chatter" slider:
- **Plaque glances:** looking at a case for 1.5 s shows a one-line fact under the crosshair prompt.
- **Walkie chatter:** the Intern and Pearl radio short facts tied to what just happened. Example: "Did you know? That ammonite's spiral grew chamber by chamber".
- **Guest bubbles:** enthusiasts sometimes "think" a fact bubble next to an exhibit.

## What we deliberately won't do

- No quizzes that block progress, no grades or "you got it wrong" screens, no timers on reading.
- No mandatory tutorials for facts. The Field Guide is always one key away.
- No rewards so large that ignoring the learning layer makes the game unwinnable. **Tuning target:** a knowledgeable player earns about 10–20% more per day, never 2×.

## Rollout

| Phase | Ship | Why first |
|---|---|---|
| 1 | Gallery Themes + Timeline Walk | Pure management mechanics on top of existing plaque tags; biggest learning per line of code |
| 2 | Collection cards (tiered facts) + ambient plaque glances | Reuses the Field Guide; makes facts collectible |
| 3 | Guided Tours (replacing trivia) | Turns the one quiz into a hosting minigame |
| 4 | Read the Rocks (index fossils, tide window) + Lab matrix types | Touches digging / lab balance; needs playtesting |
| 5 | Forgeries in Act 3 | Story content; depends on cards + reviews |

## How we'll know it works

- **Autotest:**
  - Each theme triggers from a scripted layout.
  - Tour rewards scale with audience match.
  - The skip path (Intern) completes a day with no learning interactions and still turns a profit.
- **Telemetry (`GameState.stats`):** % of plaques filled by hand vs Intern, themes discovered per day, tours led, fakes declined, and Field Guide opens per day. Healthy engagement is opening the Guide to *solve something*.
- **Playtest questions (after 30 minutes):**
  - "Which era came first?"
  - "Name an animal alive today that's related to an ammonite."
  - "Why does the cliff rock look striped?"

  Compare answers with and without the learning layer.
