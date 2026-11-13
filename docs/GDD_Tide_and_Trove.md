# **Game Design Document: Incremental Museum Simulator**

# **Game Overview & Identity**

* **Working Titles:** Tide & Trove.  
* **Genre:** Incremental / Management Simulator  
* **Engine & Language:** Godot Engine (GDScript)  
* **Visual Style:** Stylized, charming mid-poly (smooth cel-shading, vibrant lighting, retaining distinct geometric shapes without being overly realistic).  
* **Core Premise:** You are an aspiring paleontologist with big dreams but zero budget. You buy an abandoned museum on a fossil-rich coastline, armed with only a shovel. You must dig, prepare, and display prehistoric wonders to save the cove from bankruptcy while managing daily staff wages and museum upkeep.

# **The Narrative Arc: The Secret of Ammonite Bay**

The narrative provides a compelling reason to continuously expand the museum beyond standard monetary gains.

## **Act 1: The Washed-Up Dream**

You arrive at the beach, spending your last dime on a boarded-up shack. You start with exactly zero money and no daily rent. The initial goal is pure rags-to-riches—mining gems and ores directly on the beach just to fund your first basic tools and museum exhibits.

## **Act 2: Beneath the Strata**

As you upgrade your tools and dig into the deeper coastal sea caves, you start uncovering massive, unrecognized bone fragments. The cove hides an undiscovered, apex prehistoric marine reptile.

## **Act 3: Saving the Cove**

A greedy corporate collector attempts to foreclose on the beach to strip-mine it. To protect the site, you must build a 5-star accredited museum, fully assemble the apex reptile, and secure permanent historical protection for the bay.

# **The Core Gameplay Loop & Dual Economy**

The game relies on a stress-free preparation phase balanced by a high-stakes financial economy. Time does not pass until you flip the "Open" sign, allowing you to strategize entirely at your own pace.

## **The Dual Economy Tension**

Every time you dig, you must make a strategic choice regarding your inventory management:

| Resource Type | Primary Usage | Financial Impact | Strategic Value |
| :---- | :---- | :---- | :---- |
| **Gems & Ores** | Sold immediately | Short-Term Cash | Jumpstarts your economy from zero, pays future employee wages, avoids debt, and funds basic tool upgrades. |
| **Fossils** | Displayed in museum | Long-Term Prestige | Permanently raises daily ticket revenue and customer attraction rates. |

## **The Daily Cycle (4-Stage State Machine)**

1. **Prep Phase (Time Paused):** You dig on the beach, wash and prep fossils in the lab, arrange exhibits, and purchase structural upgrades.  
2. **Open Phase (Time Flows):** You open the doors. Customers flood in, paying ticket fees, leaving trash/sand to clean, and triggering random events (such as school field trips).  
3. **Closing Phase:** Sunset arrives. The museum closes, and the ledger screen appears to deduct daily expenses (staff wages, expansion loans). Crossing a specific debt threshold triggers a "Game Over" bankruptcy.  
4. **Closing Phase (Daily Reviews & Ledger):** Sunset arrives and the museum closes. First, you read **Daily Customer Reviews** (e.g., *"The owner bullied me\!"*, *"Attractions were filthy\!"*, or *"Incredible fossil displays\!"*), which heavily impact your Museum Quality percentage based on your behavior, staff conduct, cleanliness, fun, and decorations. Next, the financial ledger deducts daily expenses (staff wages, expansion loans). Crossing a specific debt threshold triggers a "Game Over" bankruptcy.

# **Tool Progression, Excavation & The Skill Tree**

Digging up a fossil is a streamlined, satisfying process, backed by a robust skill tree that dictates your museum's growth.

## **Simplified Digging Mechanic**

To keep development scope manageable and avoid complicated terrain deformation, actual digging is simplified. The player approaches spawn nodes (like dirt mounds, sand patches, or cracked rocks) and presses an interact button. This triggers a quick digging animation and uses an RNG drop table to pop out gems, ores, or rock-encased fossils.

## **Unlockable Beach Zones & The Skill Tree**

Instead of multiple underground mine levels, progression is tied to an expansive **Skill Tree**. The coastline is large, but better areas are initially blocked off. You spend **Upgrade Points** on the Skill Tree to unlock access to these richer, rarer beach zones. The Skill Tree also features other essential upgrades:

* **Movement Speed:** Lets the player walk and sprint faster to optimize the Prep Phase.  
* **Base Ticket Price:** Ticket prices dynamically scale up directly through Skill Tree upgrades and overall Museum Quality.  
* **Better Equipment:** Triggers the tool shop across the street to start selling higher-tier gear.  
* **Backpack Capacity:** Increases how many items you can carry before needing to return to the museum.

## **The Across-the-Street Tool Shop**

* **Physical Storefront:** Better shovels and pickaxes are not bought from a simple screen menu—you must walk across the street from your cove to a physical **Equipment Shop** to purchase them with cash.  
* **Stock Unlocks:** The shop only carries basic gear until you purchase the "Better Equipment" skill tree upgrade.

## **Excavation Tools (The Outdoors)**

* **Shovels & Pickaxes:** Upgraded across multiple tiers at the shop to harvest different node types (loose sand vs. hard rock) much faster.  
* **Fossil Detector:** A specialized gadget that emits audio pings or visual indicators when you are walking over hidden underground fossils. This is essential for finding buried nodes that aren't visible on the surface\!

## **Preparation Tools (Indoor Lab)**

Raw, rock-encased fossils are brought to the indoor workbench, where you engage in a precision cleaning mini-game.

* **Air Scribes & Micro-Brushes:** Used to chip away the surrounding rock matrix without damaging the underlying bone. High precision yields a superior "Preservation Rating," which directly increases the ticket price customers are willing to pay.

# **Museum Attractions & Upgrades**

As revenue increases, you expand the abandoned shack into a massive educational empire through a multi-tier Upgrade Tree.

## **Top-Down Build Mode**

When expanding your museum or placing attractions, exhibits, concessions, and decorations, you can toggle **Build Mode**. This seamlessly shifts the camera to a clean **top-down perspective** over your museum floor plan, allowing you to easily place, rotate, and rearrange exhibits on a grid without first-person or third-person camera clutter.

* **Mega-Skeleton Podiums:** Combine 5 to 10 distinct bone finds to construct towering, multi-piece centerpieces (e.g., T-Rex, Mosasaur).  
* **Living Fossil Aquariums:** Saltwater tanks built to house living ancient species like horseshoe crabs and nautiluses. Visitors pay extra fees for feeding interactions.  
* **Junior Dino-Dig Pit:** An interactive sandbox attraction where children pay to dig up common duplicate fossils buried by the player.  
* **Geode Cracker & Gift Shop:** A retail counter to sell excess beach gems and ores, or crack open sealed geodes for paying tourists.  
* **Prehistoric Holo-Theaters:** High-end late-game installations that project animated visuals over completed skeletons, significantly extending guest visit duration.

# **Museum Quality, Star Rating & Upgrade Points**

Progression is tied directly to how well you build, maintain, and behave in your museum.

## **The Quality Meter (0% to 100%)**

Instead of earning stars passively, your Star Rating is driven by your **Museum Quality** percentage (from 0% to 100%), calculated from three core pillars:

* **Fun:** The variety and prestige of your fossil exhibits and interactive attractions.  
* **Decorations:** Aesthetic items, lighting, plants, and themed decor placed around the building.  
* **Cleanliness:** Keeping floors swept, trash bins emptied, and restrooms clean.

When your Quality reaches **100%**, your museum levels up by **Half a Star** (unlocking new tiers of upgrades), and the Quality progress bar resets with a tougher scaling threshold for the next half-star. Quality cannot drop below 0%, but low Quality drastically reduces customer spawn rates and drains your daily profits.

## **Daily Reviews & Physics Ragdoll Behavior**

At the end of every shift, guests post written **Daily Reviews** that heavily shift your Quality score:

* **Player Conduct:** You can physically interact with—and even hit or ragdoll—unruly guests or employees. However, assaulting innocent customers results in scathing reviews (e.g., *"The owner drop-kicked me near the gift shop\! 1/5"*), tanking your Quality.  
* **Rogue Employees:** Staff members can occasionally slack off or act harshly toward guests. If an employee bullies customers, you must either **fire them** on the spot or **teach them a lesson** (physically disciplining them or issuing a stern reprimand) before they ruin your daily reviews.

## **Earning Upgrade Points (Research & Mastery Points)**

While cash buys physical tools and pays bills, unlocking nodes on the **Upgrade Tree** (such as building expansions or the *Better Equipment* shop stock) requires **Upgrade Points**, earned in four ways:

* **1\. Half-Star Milestones:** Reaching 100% Quality and gaining a half-star awards a large bundle of Upgrade Points.  
* **2\. First-Time Fossil Discoveries:** Cleaning and cataloging a brand-new fossil species in your Curator's Field Guide for the first time grants Research Points.  
* **3\. 5-Star Daily Review Streaks:** Finishing a shift with overwhelmingly positive customer reviews awards a bonus Upgrade Point.  
* **4\. VIP & Critic Commendations:** Impressing Visiting Critics or completing School Field Trip trivia challenges rewards bonus points.

# **Guest Archetypes, Management & Open-Phase Incidents**

To keep the "Open Phase" lively and comical without making it overwhelmingly fast-paced, different types of guests visit your museum as your Star Rating grows, bringing unique rewards and chaos.

## **Special Customer Archetypes**

* **Standard Tourists (0+ Stars):** Everyday visitors who view exhibits, buy snacks, and leave standard feedback based on cleanliness and decor.  
* **Rowdy Kids (0.5+ Stars):** Occasionally throw loud **Tantrums** on the museum floor or try to climb Mega-Skeletons (*"Do Not Touch\!" Violations*). Tantrums annoy nearby guests and tank your Daily Reviews unless you calm them down with a gift shop plushie, distract them with a Dino-Dig Pit, or escort them out.  
* **Fossil Enthusiasts / Paleontology Nerds (1+ Star):** Inspect your Exhibit Plaques closely. If you customized the plaque with accurate Era, Diet, and Habitat tags (or hired a Research Assistant to do it), they leave massive bonus tip donations and glowing reviews; if left on the default auto-plaque, they simply enjoy the fossil like a standard tourist.  
* **Celebrities (Unlock at 1.5 Stars):** Arrive with flashy outfits and an entourage. Depending on their personality, a Celebrity either draws a **massive crowd surge** of fans (boosting ticket sales) or demands VIP space that scares regular customers away. Keeping them happy yields huge publicity bonuses.  
* **Museum Critics (Unlock at 2.0 Stars):** Carry clipboards and inspect every corner of your museum. Critics have **triple weight** on your Daily Review and can directly slash your overall Quality percentage if they spot trash, rude staff, or player violence. Treat them like royalty and keep the floor spotless when they arrive\!  
* **Souvenir Shoplifters (2.5+ Stars):** Sneaky visitors who try to pocket gems from your Gift Shop or chip pieces off low-security fossils. Catching them in the act lets you ragdoll them out the door to recover your merchandise without taking a review penalty.  
* **Rival Snoops / Corporate Spies (Story Intruders):** Agents sent by the greedy corporate collector who sneak in without a ticket to sabotage exhibits or steal layouts. They must be spotted and kicked out immediately\!

## **Amenities & Concessions**

Build stands to keep guests happy and extract extra cash:

* **Dino-Dog & Fossil Popcorn Stands:** Generates passive income but creates trash over time.  
* **Amber Lemonade Stand:** Keeps guests refreshed so they stay in the museum longer.  
* **Restrooms:** Essential for keeping the museum's cleanliness rating high.

## **Pacing & Automation (The Walkie-Talkie System)**

To ensure you have time to mine *during* the open shift without being overwhelmed:

* **Walkie-Talkie Alerts:** While digging on the beach or in the caves, a small UI walkie-talkie alerts you to museum incidents (such as a Critic arriving, a kid throwing a tantrum, or a rude employee). You can sprint back to handle it yourself or finish your mining trip for a minor penalty.  
* **Staff Hires:** As you expand, you can hire Janitors to auto-clean trash and Security Guards to automatically catch intruders and stop kids from touching exhibits—just watch out for harsh employees who mistreat guests and need to be disciplined or fired\!

# **Opt-In Educational Mechanics**

Real-world paleontology is woven into the game as an **optional, rewarding layer**. If you want to learn about prehistoric life, engaging with the educational features grants extra cash and bonuses; if you simply want to focus on managing a chaotic museum and digging for loot, you can bypass or automate them with zero penalties.

* **Optional Exhibit Plaque Builder:** When mounting an exhibit, it automatically receives a standard plaque that satisfies normal guests. Players who want an extra payout can manually select the Era, Diet, and Habitat tags for an "Educational Accuracy" bonus, or hire a **Paleontology Intern** to auto-fill plaques accurately.  
* **The Curator's Desk & Encyclopedia (Field Guide):** Inside your Prep Lab is a physical desk holding a massive, beautifully illustrated in-game encyclopedia. Cleaning a fossil unlocks its pages, containing real-world lore, habitat data, and human-size comparisons. You can sit at the desk and read it for hours, or—if you don't care about the facts—simply claim your discovery Upgrade Points with one click and walk away.  
* **Real Geological Strata:** Different beach zones and rock layers naturally reflect authentic geological eras—Cenozoic, Mesozoic, and Paleozoic—letting curious players learn which creatures lived together purely through visual discovery, without forced quizzes or text walls.

# **Audio & Music Direction**

The game features a dynamic music system that shifts based on the current gameplay phase to control pacing and atmosphere.

* **Main Menu & Prep Phase:** The soundtrack features relaxing, calm, and acoustic coastal tracks. This reinforces that time is paused, allowing the player to dig, prep fossils, and build exhibits without feeling rushed.  
* **Open Phase:** The moment the shift starts and the doors open, the music smoothly transitions into a slightly more intense, upbeat, and bustling track to match the active chaos of managing customers, incidents, and the ticking clock.  
* **Closing Phase:** The music fades back into a calm, reflective track as the sun sets and the daily financial ledger is reviewed.

# **Technical Architecture (Godot Integration)**

* **Save System:** Main Menu includes a "New Game" option supporting up to 10 distinct save slots, alongside a dynamic "Continue" button that automatically loads the most recent save file.  
* **Settings Menu:** Fully modular UI architecture featuring distinct configuration tabs:  
  * *Audio:* Separate master, music, and SFX volume sliders.  
  * *Gameplay:* Toggles for auto-cleaning features and customizable text display speed.  
  * *Graphics:* Resolution options, window modes, and shadow quality settings.  
  * *Controls:* Full remapping interface.  
* **Input Support:** Native Godot `InputMap` implementation enabling seamless, real-time switching between Keyboard/Mouse and Gamepad/Controller inputs.  
* **Pause Menu:** Accessible during any phase to review the daily financial ledger, inspect active debt status, or adjust game settings mid-day.

