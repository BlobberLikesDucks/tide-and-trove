# Graph Report - docs  (2026-11-11)

## Corpus Check
- Corpus is ~2,431 words - fits in a single context window. You may not need a graph.

## Summary
- 79 nodes · 147 edges · 7 communities
- Extraction: 86% EXTRACTED · 13% INFERRED · 1% AMBIGUOUS · INFERRED: 19 edges (avg confidence: 0.83)
- Token cost: 152,813 input · 0 output

## Community Hubs (Navigation)
- Open Shift & Quality Upkeep
- Digging & Dual Economy
- Lab Prep & Upgrade Points
- Attractions & Guest Archetypes
- Tech, Saves & Finances
- Story: Saving the Cove
- Education & Strata Zones

## God Nodes (most connected - your core abstractions)
1. `Tide & Trove (Incremental Museum Simulator GDD)` - 14 edges
2. `Daily Customer Reviews` - 9 edges
3. `Museum Quality Meter (0-100%)` - 9 edges
4. `Star Rating` - 9 edges
5. `Fossils` - 8 edges
6. `Skill Tree` - 8 edges
7. `Upgrade Points (Research & Mastery Points)` - 7 edges
8. `Multi-Tier Upgrade Tree` - 7 edges
9. `Top-Down Build Mode` - 7 edges
10. `Rowdy Kids` - 7 edges

## Surprising Connections (you probably didn't know these)
- `The Secret of Ammonite Bay (Narrative Arc)` --rationale_for--> `Multi-Tier Upgrade Tree`  [INFERRED]
  GDD_Tide_and_Trove.md → GDD_Tide_and_Trove.md  _Bridges community 5 → community 2_
- `Act 2: Beneath the Strata` --conceptually_related_to--> `Unlockable Beach Zones`  [INFERRED]
  GDD_Tide_and_Trove.md → GDD_Tide_and_Trove.md  _Bridges community 5 → community 6_
- `Apex Prehistoric Marine Reptile` --conceptually_related_to--> `Mega-Skeleton Podiums`  [INFERRED]
  GDD_Tide_and_Trove.md → GDD_Tide_and_Trove.md  _Bridges community 5 → community 3_
- `Gems & Ores` --shares_data_with--> `Daily Financial Ledger`  [INFERRED]
  GDD_Tide_and_Trove.md → GDD_Tide_and_Trove.md  _Bridges community 1 → community 4_
- `Prep Phase (Time Paused)` --conceptually_related_to--> `Top-Down Build Mode`  [INFERRED]
  GDD_Tide_and_Trove.md → GDD_Tide_and_Trove.md  _Bridges community 2 → community 3_

## Hyperedges (group relationships)
- **Ticket Price Drivers** — gdd_tide_and_trove_base_ticket_price, gdd_tide_and_trove_fossils, gdd_tide_and_trove_preservation_rating, gdd_tide_and_trove_museum_quality, gdd_tide_and_trove_skill_tree [INFERRED 0.85]
- **Star-Gated Special Customer Archetypes** — gdd_tide_and_trove_standard_tourists, gdd_tide_and_trove_rowdy_kids, gdd_tide_and_trove_fossil_enthusiasts, gdd_tide_and_trove_celebrities, gdd_tide_and_trove_museum_critics, gdd_tide_and_trove_souvenir_shoplifters, gdd_tide_and_trove_rival_snoops [EXTRACTED 1.00]
- **Four Sources of Upgrade Points** — gdd_tide_and_trove_upgrade_points, gdd_tide_and_trove_half_star_milestones, gdd_tide_and_trove_first_time_fossil_discoveries, gdd_tide_and_trove_five_star_review_streaks, gdd_tide_and_trove_vip_critic_commendations [EXTRACTED 1.00]

## Communities (7 total, 0 thin omitted)

### Community 0 - "Open Shift & Quality Upkeep"
Cohesion: 0.19
Nodes (12): Cleanliness (Quality Pillar), Closing Phase, Daily Customer Reviews, Decorations (Quality Pillar), Dino-Dog & Fossil Popcorn Stands, Janitors, Museum Critics, Open Phase (Time Flows) (+4 more)

### Community 1 - "Digging & Dual Economy"
Cohesion: 0.18
Nodes (10): Act 1: The Washed-Up Dream, Backpack Capacity Upgrade, Better Equipment Upgrade, Across-the-Street Equipment Shop, Fossil Detector, Fossils, Fun (Quality Pillar), Gems & Ores (+2 more)

### Community 2 - "Lab Prep & Upgrade Points"
Cohesion: 0.22
Nodes (10): Air Scribes & Micro-Brushes, Base Ticket Price, Curator's Desk & Encyclopedia (Field Guide), First-Time Fossil Discoveries (Research Points), 5-Star Daily Review Streaks, Half-Star Milestones, Movement Speed Upgrade, Prep Phase (Time Paused) (+2 more)

### Community 3 - "Attractions & Guest Archetypes"
Cohesion: 0.22
Nodes (11): Amber Lemonade Stand, Celebrities, Geode Cracker & Gift Shop, Junior Dino-Dig Pit, Living Fossil Aquariums, Mega-Skeleton Podiums, Prehistoric Holo-Theaters, Rowdy Kids (+3 more)

### Community 4 - "Tech, Saves & Finances"
Cohesion: 0.33
Nodes (9): Bankruptcy Game Over (Debt Threshold), Daily Financial Ledger, Godot Engine (GDScript), Input Support (Godot InputMap), Stylized Mid-Poly Cel-Shaded Visual Style, Pause Menu, Save System (10 Slots + Continue), Modular Settings Menu (+1 more)

### Community 5 - "Story: Saving the Cove"
Cohesion: 0.33
Nodes (7): Act 2: Beneath the Strata, Act 3: Saving the Cove, Apex Prehistoric Marine Reptile, Greedy Corporate Collector, Rival Snoops / Corporate Spies, The Secret of Ammonite Bay (Narrative Arc), Security Guards

### Community 6 - "Education & Strata Zones"
Cohesion: 0.33
Nodes (5): Unlockable Beach Zones, Optional Exhibit Plaque Builder, Fossil Enthusiasts / Paleontology Nerds, Paleontology Intern, Research Assistant

## Ambiguous Edges - Review These
- `Daily Cycle (4-Stage State Machine)` → `Daily Customer Reviews`  [AMBIGUOUS]
  GDD_Tide_and_Trove.md · relation: conceptually_related_to

## Knowledge Gaps
- **7 isolated node(s):** `Stylized Mid-Poly Cel-Shaded Visual Style`, `Living Fossil Aquariums`, `Decorations (Quality Pillar)`, `Dino-Dog & Fossil Popcorn Stands`, `Amber Lemonade Stand` (+2 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 7 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Tide & Trove (Incremental Museum Simulator GDD)` connect `Tech, Saves & Finances` to `Open Shift & Quality Upkeep`, `Digging & Dual Economy`, `Lab Prep & Upgrade Points`, `Story: Saving the Cove`, `Education & Strata Zones`?**
  _High betweenness centrality (0.278) - this node is a cross-community bridge._
- **What connects `Stylized Mid-Poly Cel-Shaded Visual Style`, `Living Fossil Aquariums`, `Decorations (Quality Pillar)` to the rest of the system?**
  _7 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Why does `Museum Quality Meter (0-100%)` connect `Open Shift & Quality Upkeep` to `Digging & Dual Economy`, `Lab Prep & Upgrade Points`, `Attractions & Guest Archetypes`, `Tech, Saves & Finances`?**
  _High betweenness centrality (0.169) - this node is a cross-community bridge._
- **Why does `Star Rating` connect `Attractions & Guest Archetypes` to `Open Shift & Quality Upkeep`, `Lab Prep & Upgrade Points`, `Story: Saving the Cove`, `Education & Strata Zones`?**
  _High betweenness centrality (0.130) - this node is a cross-community bridge._

### Low-confidence Hints
_AMBIGUOUS edges — the extractor was unsure. Verify before acting on these._

- **What is the exact relationship between `Daily Cycle (4-Stage State Machine)` and `Daily Customer Reviews`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._