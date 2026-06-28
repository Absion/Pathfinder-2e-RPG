# PATHFINDER 2E ENGINE: 2.5D TACTICAL RPG ARCHITECTURE
**If you are an AI assistant starting a new session, READ THIS FILE FIRST.**

## 1. Core Design Pillars
All code written for this project must adhere to the following pillars:
1. **Readable**
2. **Testable**
3. **Understandable**
4. **Maintainable**
5. **Scalable**
6. **Extensible**
*(Compromises to these pillars should only be made for explicitly necessary performance optimizations or security constraints).*

---

## 2. Global Architecture: Contexts & Dependency Injection
To avoid a tangled web of global Autoloads, the project uses a **Context & Service** architecture:
1. **`PFGameRoot`**: The absolute top-level node. Keeps global state (current save file, master volume) and transitions between Contexts.
2. **Contexts**: Discrete game states (e.g., `PFMainMenuContext`, `PFCombatContext`, `PFOverworldContext`) that manage their own isolated rules and nodes.
3. **Services**: Managers (like `TurnManager`, `GridManager`) are instantiated as node children of a Context.
4. **Dependency Injection**: Services are built via `build_services()`, given their dependencies via `bind_services()`, and initialized via `setup()`.
5. **Autoload Exception**: `PFDatabase` remains a global Autoload *only* because it is a stateless reader of an SQLite database. No mutable game state is allowed in Autoloads.

---

## 3. Core Philosophies
1. **Absolute Data/Logic Separation (The Compendium Pattern):** Game logic (`.gd` scripts) must **never** contain hardcoded content. All classes, ancestries, weapons, UI strings, cutscene text, dialogue, descriptions, and **core systemic definitions (Sizes, Traits)** live exclusively within the relational SQLite database (`res://db/pf2e_data.db`). Code components only query, route, and render this data.
2. **Dynamic System Caching (StringNames over Enums):** To allow for infinite engine extensibility without rewriting code, foundational concepts (like `Size` or `Traits`) are not hardcoded Enums. They are loaded from the database at startup and cached in fast `StringName` dictionaries for high-speed logic routing. Strict integers and Enums are reserved only for immutable core logic (e.g., `PFEntity.ActionCost`, `PFEntity.Distance`).
3. **Single Source of Truth:** Actors do not hold redundant variables for equipped gear. If you need to know what an actor is holding or wearing, you MUST query their `PFInventory` component directly.
4. **Monster Optimization:** NPCs completely bypass expensive proficiency matrix calculations. Due to polymorphism, `PFNpc` instances natively return hardcoded DCs, AC, and attacks directly from their `monster_stats` dictionary without needing boolean flags.
5. **Open RPG Creative (ORC) License Compliance:** While we are implementing the Pathfinder 2e rule mechanics, we MUST AVOID using Paizo's proprietary Intellectual Property (IP). Do not include specific deities (e.g., Desna), unique lore-specific ancestries, or setting-specific locations/factions that are not covered under the open ORC license.
5. **Mandatory Documentation:** Every class and significant method MUST be prefixed with Godot 4 `##` docstrings so the editor can generate rich tooltips and in-editor documentation. Single-letter variables (`w`, `s`, `x` outside of coordinates) are strictly forbidden to ensure legibility.

---

## 4. Rendering Pipeline & Perspective (2.5D HD-2D)
The game utilizes a "2.5D HD-2D" rendering pipeline, heavily inspired by titles like Triangle Strategy and Octopath Traveler.
* **Camera Rig (`PFCameraRig`):** A custom 3D gimbal camera using **Orthographic** projection to simulate an isometric perspective without distance distortion (Standard rotation: X: -30°, Y: 45°, Z: 0°). Supports WASD/Edge panning, mouse-drag rotation, and smooth zooming.
* **World Space & Grid (`PFCombatGrid`):** The environment is strictly 3D. The tactical grid is drawn using `MultiMeshInstance3D` to render thousands of dynamic tile highlights (movement bounds, AoE templates) in a single draw call. `PFCombatGrid` internally handles Pathfinder 2e diagonal distance math (5ft-10ft-5ft).
* **Entity Visualization:** Actors and interactive objects are rendered using `Sprite3D` nodes with `Billboard = Y-Billboard` and `Alpha Cut = Discard`. This ensures tokens constantly face the camera even when the rig rotates 360 degrees.
* **Programmatic UI (`PFActionMenu`):** Complex, highly dynamic battle UI (like the Action Menu) is built **programmatically via GDScript** rather than relying on brittle `.tscn` nodes. The UI exists on a separate `CanvasLayer` and uses explicit anchors (e.g., `set_anchors_and_offsets_preset`) to maintain flawless resolution scaling across the screen. Use `Camera3D.unproject_position(Vector3)` to accurately project world coordinates onto health bars or floating text.

---

## 5. Database & Instantiation (`pf_database.gd`)
The SQLite database is the absolute source of truth for all content, systemic rules, and narrative data. 
* **Core Rule Tables:** `sizes` (defines grid footprint and bulk multipliers) and `traits` (defines UI tooltips and mechanical hook tags).
* **Mechanics Tables:** `classes`, `spells`, `spell_variants`, `deities`, `weapons`, `shields`, `ancestries`, and `backgrounds`.
* **Narrative & UI Tables:** `ui_strings`, `item_descriptions`, `dialogue_trees`, and `cutscenes`. UI components and dialogue managers must pull their text dynamically based on string IDs to support global localization and rapid editing.
* **JSON Parsing:** JSON arrays stored in the database (e.g., traits, ability boosts, divine fonts) are parsed inside `pf_database.gd` getters.
* **Relational Magic:** Spells are split into `spells` (core identity) and `spell_variants` (relational table bound by `spell_id`). Variants dictate action cost (including `ONE_ROUND` / `TWO_ROUNDS`), range, targets, and damage dice for specific cast methods.
* **Instantiation:** When creating an item or fetching dialogue, call the factory methods (e.g., `PFDatabase.get_weapon("longsword")` or `PFDatabase.get_string("ui_menu_start")`). This returns a fully constructed GDScript object ready for engine use.

---

## 6. Item & Equipment Architecture
All items inherit from `PFEntity` -> `PFItem`.
* **Economy:** The absolute source of truth for value is `price_cp` (copper pieces). Floats are converted to copper upon initialization. Always use `PFInventory.format_copper_to_string(price_cp)` for UI displays.
* **Durability:** Items track `hardness`, `max_hp`, `current_hp`, and `broken_threshold`.
* **Runes:** Weapons and Armors handle runes via `.apply_fundamental_runes()`. Shields handle them via `.apply_reinforcing_rune()`. Applying a rune automatically recalculates the item's level, copper price, max HP/Hardness, and dynamically updates its `entity_name` (e.g., prepending "+1 Striking").
* **Shield Block:** Shield damage blocking logic resides in `PFShield.can_block(damage_type)`, checking against an array of `blockable_damage_types`.
* **Consumables & Alchemy:** All consumables extend `PFConsumable`. Specialized alchemical classes (`PFAlchemicalBomb`, `PFAlchemicalElixir`, `PFAlchemicalPoison`) handle their distinct mechanics natively. For example, a `PFActionApplyPoison` moves the poison to a weapon's `injection_payload` which guarantees delivery upon a successful Strike.
* **Attachments:** Grafts, Spellhearts, Codas, and Firearm Customizations are handled as distinct subclasses that attach to standard entities or actors, granting conditional passive abilities, spells, or alternate strikes without requiring rigid subclasses of the base items.

---

## 7. Bulk, Sizing & Encumbrance (Perceived Bulk Matrix)
The Engine strictly handles physical sizes and weights without manually adjusting base item stats, deriving logic dynamically from the `sizes` database table:
* **Item Sizing:** All items have a physical `size_id` (e.g., `"medium"`, `"large"`). Larger items scale mathematically based on the definitions in the database. Buying prices remain standard.
* **Perceived Bulk:** An actor's size dynamically alters how they experience an item's weight. A `"large"` PC inherently divides the bulk of standard-sized items by 10, experiencing them as `1L` (Light bulk).
* **Equipment Bounds:** `PFInventory` enforces physical restraints. Armor must be the *exact* size of the wearer (Small and Medium are mathematically interchangeable). Weapons can be wielded if they are 1 size larger, but the Engine dynamically injects the `clumsy 1` condition natively onto the wielder.
* **Encumbrance Threshold:** When total bulk crosses `(5 + STR modifier)`, the actor automatically receives the `Encumbered` and `Clumsy 1` conditions via the condition manager.
* **Containers & Nested Bulk:** Containers like backpacks dynamically reduce the total bulk of items stored within them. `PFInventory.get_total_bulk()` recursively calculates this by summing all items and applying container reductions.
* **Investiture:** Actors can only invest up to 10 magic items. This is enforced directly within `PFInventory.invest_item()`.

---

## 8. Composition Over Inheritance (Inventory & Entities)
The engine heavily favors **Composition**

### 1. Hybrid Inheritance Architecture (Actors)
Pathfinder is a game of highly specific rules where Players and Monsters operate on entirely different mathematical chassis (Proficiency vs GMG Scaling). 

To cleanly separate this logic while maintaining flexibility, the engine uses **Hybrid Inheritance**.
`PFActor` is the base class for any targetable entity. It extends `Node3D`. It handles core logic like `health`, `action_economy`, and `conditions`.

* **Dynamic Condition Stacking:** The Engine prevents illegal status stacking natively. `apply_condition` appends all statuses (retaining history). When an actor requests their current penalty via `get_condition_modifier()`, the Engine isolates the single strongest bonus and single strongest penalty of that type, ignoring all duplicates or weaker modifiers.

It branches into strictly typed subclasses:
* **`PFPlayerCharacter`**: Guaranteed to contain a `PFProficiencySheet`, `PFInventory`, and `PFSpellbook`. Calculates stats based on deep Pathfinder math.
* **`PFNpc`**: Lightweight containers for Monsters and Minions. Calculates stats via direct `monster_stats` dictionaries using GMG scaling rules.
* **`PFConstruct`**: Entities like doors and pillars that have `health` but no `action_economy` or `inventory`.

* **Investment:** Magic items with `requires_investment = true` MUST be added to the `invested_items` array before they can be equipped/wielded. The `max_invested_items` limit is dynamic (default 10) and bypassed by monsters.
* **Hand Occupancy:** Hands are tracked via `held_main_hand`, `held_off_hand`, and `two_handed_item`. 
* **Wielding vs Holding:** A weapon must be passed through `.wield_item()` to be considered active for combat (`is_wielded = true`).
* **Buckler Logic:** Bucklers require a free hand or a hand holding a light (`bulk_value < 10`), non-weapon (`is_weapon = false`) object to be raised. This is calculated dynamically via `PFInventory.can_raise_shield()`.

---

## 9. Magic System (`PFSpellbook`)
Every `PFActor` instantiates a `PFSpellbook`.
* The spellbook holds hardcoded progression arrays mapping character levels to available spell slots based on their class type (None, Full Caster, Bounded Caster).
* Calculates max slots by adding base class slots + any `extra_slots` granted by feats.
* Spells are tracked in dedicated arrays: `known_spells`, `repertoire`, `prepared_spells`, `innate_spells`, and `signature_spells`.
* **Heightening:** `PFSpell` handles heightening math natively: `(cast_rank - base_spell_rank) / scaling_rules` applied to base damage.

---

## 10. Environmental Asset Architecture (2D vs. 3D Rules)
The game uses a strict framework to determine when an environmental object should be a 3D model versus a 2D sprite. 

### Rule 1: The Terrain (Strict 3D)
* **Condition:** The object represents the floor, cliffs, stairs, or fundamental grid geometry.
* **Node Structure:** Must use `GridMap` or `MeshInstance3D`.
* **Reasoning:** Pathfinder 2e relies heavily on elevation and grid movement. The ground must be mathematically 3D to support accurate pathfinding, distance metrics, and vertical line of sight.

### Rule 2: The Elevation & Interior Rule (Strict 3D)
* **Condition:** A character can stand ON TOP OF the object (e.g., stacked crates, a balcony, a wagon) or go INSIDE the object (e.g., a tavern, a castle).
* **Node Structure:** `MeshInstance3D` + `StaticBody3D`. Apply a 2D pixel-art texture to the 3D material to match the aesthetic.
* **Reasoning:** Characters standing on flat 2D sprites create catastrophic depth illusions. Complex stacking or interior navigation requires structural 3D collision boundaries.

### Rule 3: The Cover Rule / 2.5D Hybrid Trick (2D Art + 3D Physics)
* **Condition:** The object blocks movement or provides mechanical PF2e cover (e.g., standard +2 AC), but is generally symmetrical/radial and characters cannot stand on top of it (e.g., trees, boulders, individual barrels, lampposts).
* **Node Structure:** A `StaticBody3D` root containing:
    1. `CollisionShape3D` (Usually a CylinderShape3D or SphereShape3D to handle 3D RayCast interceptions for cover math).
    2. `Sprite3D` (The 2D artwork, set to `Y-Billboard` and `Alpha Cut = Discard`).
* **Reasoning:** This allows the 3D engine to accurately evaluate Line of Effect and Line of Sight for ranged attacks, while keeping the asset pipeline incredibly lean.

### Rule 4: The Set Dressing Rule (Pure 2D)
* **Condition:** The object is purely visual, does not block movement, and provides no cover mechanics (e.g., small rugs, scattered papers, wall banners).
* **Node Structure:** `Sprite3D` only (No physics bodies). For floor-based items, set the Sprite3D rotation to lay flat on the X/Z plane instead of using billboard flags.

---

## 11. Asset Management & Dynamic Loading (Implicit Paths)
To keep the SQLite database lightweight and highly performant, we never store raw image data (BLOBs) or absolute string file paths in database tables. The engine relies on an "Implicit Path" architecture to link 2D assets.

### The Naming Convention Rule
The file name of the 2D asset (`.png` or `.webp`) MUST identically match the `id` string of the corresponding entry in the SQLite database.
* **Database `id`:** `"orc_brute"` -> Folder/File base: `orc_brute`
* **Database `id`:** `"steel_shield"` -> File: `steel_shield.png`

### Strict Directory Structure
Assets are grouped into standardized directory trees. Factory methods construct loading paths dynamically based on asset categories:
* **Monsters/NPCs:** `res://assets/sprites/actors/`
* **Weapons:** `res://assets/sprites/weapons/`
* **Armor/Shields:** `res://assets/sprites/armor/`
* **Items/Loot:** `res://assets/sprites/items/`

### Factory Instantiation & Fallbacks
When a factory method constructs an object from an SQLite database query, it dynamically attempts to verify the file path. It must check resource availability using `ResourceLoader.exists()` and swap to a system placeholder if the graphic asset is unbaked to prevent crashes.

---

## 12. The Archetypal Rig System (PC Paper Dolls)
To support a modular equipment appearance system without drawing unique frames for every combination of ancestry and weapon, player characters utilize a **Rig-Based Archetype System** grouped by animation stance.

### The Archetype Matrix
Every PC is assigned a visual rig comprised of two variables: **Posture** and **Physique**.

1. **Posture (The Animation Rig):** Dictates the idle stance and combat loops. All characters sharing a Posture share identical pixel coordinates for hand, neck, and footprint attachments.
   * *Standard:* Balanced, classic hero posture.
   * *Elegant:* Upright, formal, or magic-oriented stance.
   * *Savage:* Wide-set, hunched, aggressive stance.
2. **Physique (The Strength Morph):** Dynamically swapped based on the character's physical attributes (e.g., Strength score tiers).
   * *Skinny / Lean*
   * *Default*
   * *Muscular*

### Bipedal Scale Uniformity & Non-Standard Anatomies
* **Standard Scaling:** Ancestries sharing standard bipedal anatomy but differing in mechanical size do not get custom sprites. The engine applies a uniform `scale` adjustment to the root `Node3D`. For example, if a character uses a Large form with the Savage posture, the system handles the size difference computationally without needing new hand-drawn frames.
* To counter automatic child scaling (such as a Small character holding a Medium weapon), weapons compute a local inverse modifier: `Child_Weapon_Scale = Target_Weapon_Size_Scale / Actor_Root_Scale`.
* **Unique Exceptions:** Radically non-bipedal or asymmetrical characters (e.g., Centaurs, Sprites) are exempt from the archetype system. They maintain completely standalone sprite sheets and custom layers.
* **PC vs Monster Split:** Monsters utilize **Baked Sprites**. Their weapons and armor are drawn directly onto their flat base image. The inventory component still manages their mathematical calculations, but their visible asset frame does not update upon receiving equipment.

---

## 13. Anatomy, Silhouettes, and Gendered Physiques
To ensure high-fidelity apparel fitting, the engine enforces a strict Gendered Silhouette system. Because male and female silhouettes alter the outer pixel boundaries of the torso and limbs, armor layers must match the silhouette perfectly.

### The Silhouette Suffix Convention
The `Physique` definition incorporates a gender/silhouette suffix, applied rigidly to all base bodies and apparel overlays.
* **Format:** `[item_id]_[posture]_[physique]_[silhouette].png`
* **Base Body:** `body_human_savage_muscular_m.png` / `body_orc_savage_muscular_f.png`
* **Armor Overlay:** `steel_breastplate_savage_muscular_m.png` / `steel_breastplate_savage_muscular_f.png`
* *Weapon Exemption:* Because hand coordinates are completely locked by the character's chosen *Posture*, weapons do not feature silhouette suffixes.

### The Protrusion Layering System
Anatomical additions extending outside standard armor spaces (Horns, Tails, Beast Hair) reside on independent sprite layers stacked above the base body. Equipment in the database utilizes metadata tags (e.g., `hides_hair`, `hides_horns`). When a full-face helm or heavy cowl is assigned, the engine reads the tag and toggles the `visible` parameter of the corresponding protrusion layer to false to halt visual clipping.

---

## 14. Shader-Driven Materials & Runes
To prevent exponential asset bloat from multiplying weapons and armor by Pathfinder's material types and property runes, the visual system relies heavily on `ShaderMaterial` processing.

### The Grayscale Base Rule
All equipment sprite sheets are drawn by artists using high-contrast grayscale or generic steel values. True colorization, specular shine, and magical traits are pushed programmatically to the GPU via shader parameters.

### Material & Rune Parameter Passes
* **Material Tinting:** The renderer maps `PFItem.ItemMaterial` to specific color vectors (e.g., Dark blue-black for Cold Iron, high-specular pale blue for Silver, deep shimmering green for Adamantine).
* **Property Runes:** Magic effects leverage noise textures and emissions bounded within the sprite's alpha channel mask:
    * *Flaming:* Vertical scrolling noise multiplied by hot red-orange emission.
    * *Shadow:* Negative emission mask with a trailing black smoke particle emitter.
    * *Astral:* Panning cosmic star texture blended across the active weapon fragments.

---

## 15. Data-Driven Logic Bridging (Traits & Conditions)
To ensure the engine remains entirely data-driven, game logic components handle systemic rules (Traits, Conditions, Weapon Properties) using three distinct bridging patterns rather than hardcoded booleans.

### Pattern 1: The Tag & Hook System (Static Rule Alteration)
For traits that alter foundational math (e.g., Agile, Finesse), the `traits` database table utilizes `mechanic_hook` and `hook_value` columns.
* GDScript does not check `if trait == "agile"`. 
* GDScript checks `if trait.mechanic_hook == "modifies_map"` and applies the database-defined `hook_value`.

### Pattern 2: The Modifier Matrix (Standardized Conditions)
Conditions that apply numerical buffs or debuffs (e.g., Frightened, Clumsy, Inspire Courage) are fully parameterized in the `conditions` table.
* **Columns:** `modifier_type` (Status, Circumstance, Item), `target_stat` (AC, Will, Str_Checks, All), and `multiplier`.
* The `PFProficiencySheet` dynamically reads these columns and applies the math automatically. No condition-specific GDScript is written for numerical modifiers.
* **PFAttributesComponent & PFStat:** Under the hood, stats like `ac_modifiers`, `attack_modifiers`, and saving throws are managed by `PFStat` objects inside the `PFAttributesComponent`. A `PFStat` holds an array of `PFModifier`s, automatically stacking rules (like only keeping the highest circumstance bonus). Tests should use `add_modifier(PFModifier)` to simulate buffs/debuffs or force hits rather than hacking a monster's base AC directly.

### Pattern 3: The Strategy Pattern (Complex Behaviors)
For conditions or traits that inject new behaviors, turn-based triggers, or action restrictions (e.g., Persistent Damage, Fascinated, Stunned), the database utilizes a `script_path` column.
* The engine dynamically loads the isolated `.gd` script path provided by the database and attaches it to the `PFActor` as a child node.
* These injected scripts listen for Context signals (e.g., `on_turn_end`, `on_action_attempted`) to execute their highly specific logic.

---

## 16. Engine Subsystems (Core Managers)
The backend operates heavily on specialized, stateless managers to process game logic rules correctly. AI agents should utilize these managers instead of cramming logic into `PFActor` or context nodes.
* **`PFLevelUpManager`**: Handles all character progression, sandbox-validating choices, and creating audit logs for Retraining.
* **`PFTimeManager`**: Advances the calendar and coordinates time passing.
* **`PFTurnManager`**: Oversees combat encounters, rolling initiative, handling turn order, and distributing turn start/end signals to the ConditionManager.
* **`PFDowntimeManager`**: Tracks and executes daily downtime activities (Earn Income, Crafting, Retraining).
* **`PFDailyPrepManager`**: Handles long-term rests, daily spell/focus point recovery, and temporary item generation/clearing (like Alchemist infusions).
* **`PFConditionManager`**: Dedicated logic for safely applying, ticking down, or resolving conditions on actors.
* **`PFReactionManager`**: Broadcasts reaction events (e.g. `BEFORE_TAKE_DAMAGE`, `ON_MOVE`) and handles interruption prioritization (e.g. Shield Block, Attack of Opportunity).
* **`PFDetectionManager`**: Optimized Matrix tracking Stealth, unobserved status, cover, and line of sight.

---

## 17. AI Code Generation Directives
When generating GDScript for this project, you MUST adhere to the following rules:
1. **Never use `.tres` for data.** If asked to create a new weapon, spell, or class, write the SQL `INSERT` statement for `pf_database.gd`, do NOT generate a Godot Resource.
2. **Never hardcode strings or core definitions.** Do not generate GDScript containing hardcoded dialogue, item lore, UI strings, or core mechanic tags (like Sizes or Traits). All systemic rules and narrative text MUST be queried from the SQLite database.
3. **Call Down, Signal Up.** Parent nodes call methods on their children. Child nodes NEVER reference their parents (`get_parent()` is banned for game logic). Children communicate exclusively upwards via `Signals`.
4. **Favor Composition.** Never add sprawling variables (like `is_poisoned` or `max_mana`) to `PFActor`. Create a modular component node instead.
5. **Use Vector3 for spatial logic.** Do not attempt to calculate 2D isometric grid conversions. Rely entirely on the 3D engine for RayCasting, distances, and areas of effect. 
6. **Use `price_cp` strictly.** Never do math with Gold Pieces (`gp`) outside of initial database seeding; all internal engine math operates on integers of copper.
7. **Pass Shader Parameters Programmatically.** When equipment loads, update its materials dynamically via `.set_shader_parameter()`. Never generate hardcoded materials per variant.
8. **Prevent Test Memory Leaks (Gut):** When writing Gut tests, you MUST wrap manually instantiated Nodes in `autofree()` or use `add_child_autofree()` to ensure they are cleaned up. For global singletons, use synchronous `add_child` (not `call_deferred`) and ensure they are removed and `.free()`'d in `after_all`.
9. **Godot 4 Global Classes.** Do not `preload()` scripts that use the `class_name` keyword (e.g., `const PFActor = preload(...)`). Godot 4 automatically registers `class_name` scripts globally; manually preloading them causes shadowing warnings and IDE confusion.
10. **Underscore Unused Virtual Parameters.** When defining virtual methods in base classes (like `PFAction.execute()`) that don't utilize their parameters, you MUST prefix the parameter with an underscore (e.g., `_target`) to suppress Godot 4 unused variable warnings while maintaining the correct signature for subclasses.
11. **Global UI Themes.** Never hardcode StyleBox generation or generic colors (like Color('#1a1a2e')) inside individual UI scripts. All UI controls MUST rely on res://assets/ui/theme/pf_global_theme.tres to ensure a cohesive and easily updatable visual aesthetic across the entire engine.
12. **Test Logic Integrity:** Tests must be written to ensure game logic works according to the actual PF2e rules as they should work (e.g., using legal character creation steps rather than hacking internal arrays). When a test fails or throws warnings, look at fixing the underlying broken logic first to ensure that is the root issue before ever modifying the test just to make it green.
13. **Fix Orphan Warnings:** Always fix any orphan node warnings during unit test execution along with standard errors. Use `.free()` instead of `.queue_free()` in the `after_each` block if nodes are instantiated but never added to the SceneTree, to ensure GUT correctly clears them before counting orphans.
14. **Do Not Override Scripts Dynamically in Tests:** When writing Gut tests, never mock methods by creating a `GDScript.new()` and calling `.set_script()` on an instantiated node. This completely severs Godot's internal C++ type casting (causing `Invalid type in function` errors where it expects a subclass but receives a base `Node3D`). Instead, either use Gut's native `double()` and `stub()` features, or implement standard metadata backdoors in the actual game logic (e.g., `if actor.has_meta("test_flat_check"): roll = actor.get_meta("test_flat_check")`).
15. **Backend State vs. UI Choices (No Auto-Choices):** Internal backend hooks (like `_on_rested_for_night`) should never automatically execute complex rules that require player agency (e.g., automatically spending the highest spell slot to charge a staff, or automatically preparing spells). The backend should simply clear/reset the state (e.g., setting staff charges to 0), and expose an explicit method (e.g., `prepare_staff(actor, base_charges, expend_slot_rank)`) that the UI or a Manager layer calls *after* the player makes a choice. The backend manages the strict mathematical rules; the UI authorizes the inputs.

---

## 18. Memory Management & Orphans
To maintain engine stability and avoid memory leaks during both runtime and Gut testing, strict memory management rules apply:
1. **Gut Test Cleanup (Orphans):** Gut tracks all orphaned nodes. If you instantiate a `Node` (e.g., `PFNpc.new()`) inside a test, you must wrap it in `autofree()`. If you need to add it to the scene tree, use `add_child_autofree()`.
2. **Singleton State Bleed:** Services initialized via `PFContext.init_shared_services()` persist. They MUST be cleaned up using `PFContext.cleanup_shared_services()` in a test's `after_all()` block. 
3. **Synchronous Teardown:** When tearing down singletons or tests, use `.free()` after `remove_child()`. Do not use `.queue_free()` for test teardowns, as Gut checks orphans synchronously before the frame ends, leading to false positives and potential Signal 11 crashes if deferred methods fire on freed objects.
4. **Avoid RefCounted Cycles:** Godot handles `RefCounted` objects via reference counting, not a garbage collector. If Object A holds a strong reference to Object B, and Object B holds a strong reference to Object A, a cyclic reference occurs and the memory will leak forever. If two `RefCounted` objects must know about each other, one side MUST use a `WeakRef` (e.g., `weakref(parent_object)`) to break the cycle.ne.

## 19. Testing & Validation
### Unit Testing Philosophy
- **Component-Level Isolation**: Test files must be scoped to a single script or specific component (e.g., 	est_coda.gd for pf_coda.gd, 	est_firearm_customization.gd for pf_firearm_customization.gd). Do NOT create monolithic test files (like 	est_phase_7.gd).
- **Runtime Compilation Checks**: Because GDScript is dynamically compiled at runtime, unit tests MUST instantiate the exact objects and perform actions that trigger core logic paths. This is required to catch signature mismatches (like execute(PFActor) vs execute(Variant)) and type narrowing/conversion errors that the static language server complains about but the headless test runner normally ignores until execution.
- **Robustness Over Coverage**: Focus tests on the edges of composition (e.g., attach logic, traits integration, aura registration). Ensure that tests verify not only the positive cases but gracefully handle error paths without crashing the test runner.

