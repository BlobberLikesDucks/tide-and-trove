# Graph Report - feedback  (2026-11-13)

## Corpus Check
- Corpus is ~1,165 words - fits in a single context window. You may not need a graph.

## Summary
- 55 nodes · 121 edges · 6 communities
- Extraction: 88% EXTRACTED · 11% INFERRED · 2% AMBIGUOUS · INFERRED: 13 edges (avg confidence: 0.77)
- Token cost: 89,789 input · 0 output

## Community Hubs (Navigation)
- UI, Guide & Settings Fixes
- Inventory, Hotbar & Tools
- Museum Displays & Reviews
- Upgrade Tree & Progression
- Interaction Prompts & Shop Area
- Bus Stop, Signs & Mesh Overlaps

## God Nodes (most connected - your core abstractions)
1. `Game Feedback List` - 54 edges
2. `Museum` - 10 edges
3. `Manual Fossil Display Categorization` - 7 edges
4. `Sign Text (Bus, Museum, Shop, Tide & Trove, Open/Closed)` - 6 edges
5. `Hotbar` - 6 edges
6. `Upgrade Tree` - 6 edges
7. `Museum Customers` - 6 edges
8. `Bus Stop` - 5 edges
9. `Look-At Interaction Prompt Range` - 5 edges
10. `Inventory` - 5 edges

## Surprising Connections (you probably didn't know these)
- `Tool Station` --conceptually_related_to--> `Equipment Shop`  [AMBIGUOUS]
  game_feedback_list.md → game_feedback_list.md  _Bridges community 4 → community 1_
- `Physical Trash Pickup` --conceptually_related_to--> `Employee System`  [INFERRED]
  game_feedback_list.md → game_feedback_list.md  _Bridges community 4 → community 3_
- `'Auto' Display Option` --conceptually_related_to--> `Manual Fossil Display Categorization`  [INFERRED]
  game_feedback_list.md → game_feedback_list.md  _Bridges community 0 → community 2_
- `Game Feedback List` --references--> `Amber`  [EXTRACTED]
  game_feedback_list.md → game_feedback_list.md  _Bridges community 0 → community 1_
- `Game Feedback List` --references--> `Bench Model`  [EXTRACTED]
  game_feedback_list.md → game_feedback_list.md  _Bridges community 0 → community 5_

## Hyperedges (group relationships)
- **Item Management Flow (Hotbar / Inventory / Backpack / Storage)** — game_feedback_list_hotbar, game_feedback_list_inventory, game_feedback_list_backpack, game_feedback_list_storage, game_feedback_list_cleaned_fossils, game_feedback_list_vital_tools, game_feedback_list_tool_equip_system [INFERRED 0.85]
- **Star-Gated Progression (Upgrade Tree, Currencies, Employees, Hotbar Slots)** — game_feedback_list_upgrade_tree, game_feedback_list_star_rating, game_feedback_list_upgrade_points, game_feedback_list_cash, game_feedback_list_employee_system, game_feedback_list_hotbar [EXTRACTED 1.00]
- **Customer Satisfaction & Review Loop** — game_feedback_list_customers, game_feedback_list_refreshment_stands, game_feedback_list_manual_fossil_display, game_feedback_list_display_validator_building, game_feedback_list_nerd_customers, game_feedback_list_daily_review [INFERRED 0.85]

## Communities (6 total, 0 thin omitted)

### Community 0 - "UI, Guide & Settings Fixes"
Cohesion: 0.24
Nodes (12): Game Feedback List, 'Auto' Display Option, Bottom-Right UI Element, Curator's Desk, Curator's Field Guide GUI, Game Map, GUI Title Plate Alignment, Guide (G Key) (+4 more)

### Community 1 - "Inventory, Hotbar & Tools"
Cohesion: 0.21
Nodes (11): Amber, Backpack, Cleaned Fossils, First-Person Arm Model & Animations, Fossils, Held Item Display, Hotbar, Inventory (+3 more)

### Community 2 - "Museum Displays & Reviews"
Cohesion: 0.27
Nodes (9): Black Line / Rectangle Artifacts, Museum Customers, Daily Reviews, Gem Display, Hanged Shell Displays, Museum, Nerd Customers, NPC Model & Waving Animation (+1 more)

### Community 3 - "Upgrade Tree & Progression"
Cohesion: 0.33
Nodes (4): Build Menu, Cash, Star Rating (1-5 Stars), Upgrade Points (UGP)

### Community 4 - "Interaction Prompts & Shop Area"
Cohesion: 0.29
Nodes (5): Equipment Shop, Floating Objects, Open/Closed Sign, Trash Bin, Workbench

### Community 5 - "Bus Stop, Signs & Mesh Overlaps"
Cohesion: 0.40
Nodes (6): Bench Model, Bus Stop, Floating Billboard Text, Mesh Interpenetration (Objects Phasing Through Each Other), Sign Text (Bus, Museum, Shop, Tide & Trove, Open/Closed), Tide & Trove

## Ambiguous Edges - Review These
- `Settings Menu` → `'Auto' Display Option`  [AMBIGUOUS]
  game_feedback_list.md · relation: conceptually_related_to
- `Equipment Shop` → `Tool Station`  [AMBIGUOUS]
  game_feedback_list.md · relation: conceptually_related_to

## Knowledge Gaps
- **3 isolated node(s):** `GUI Title Plate Alignment`, `Bottom-Right UI Element`, `Unpainted Texture Gaps`
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 3 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Game Feedback List` connect `UI, Guide & Settings Fixes` to `Inventory, Hotbar & Tools`, `Museum Displays & Reviews`, `Upgrade Tree & Progression`, `Interaction Prompts & Shop Area`, `Bus Stop, Signs & Mesh Overlaps`?**
  _High betweenness centrality (0.905) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `Museum` (e.g. with `Gem Display` and `Manual Fossil Display Categorization`) actually correct?**
  _`Museum` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `GUI Title Plate Alignment`, `Bottom-Right UI Element`, `Unpainted Texture Gaps` to the rest of the system?**
  _3 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Why does `Museum` connect `Museum Displays & Reviews` to `UI, Guide & Settings Fixes`, `Bus Stop, Signs & Mesh Overlaps`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `Manual Fossil Display Categorization` (e.g. with `'Auto' Display Option` and `Museum`) actually correct?**
  _`Manual Fossil Display Categorization` has 2 INFERRED edges - model-reasoned connections that need verification._

### Low-confidence Hints
_AMBIGUOUS edges — the extractor was unsure. Verify before acting on these._

- **What is the exact relationship between `Settings Menu` and `'Auto' Display Option`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `Equipment Shop` and `Tool Station`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._