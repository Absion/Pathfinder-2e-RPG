# PATHFINDER 2E ENGINE: 2.5D TACTICAL RPG ARCHITECTURE
**If you are an AI assistant starting a new session, READ THIS FILE FIRST.**

## 1. Core Philosophies
1. **The Compendium Pattern (SQLite > .tres):** We do NOT use Godot `.tres` resource files for standard database entries. All static data (items, spells, classes, ancestries) is stored in a relational SQLite database (`res://db/pf2e_data.db`) and instantiated at runtime via `pf_database.gd`. 
2. **Enums Over Strings:** Everything uses strict integers and Enums (`PFEntity.ActionCost`, `PFEntity.Size`, `PFEntity.Distance`, etc.) to keep database queries lightning fast and memory safe.
3. **Single Source of Truth:** Actors do not hold redundant variables for equipped gear. If you need to know what an actor is holding or wearing, you MUST query their `PFInventory` component directly.
4. **Monster Optimization:** NPCs completely bypass expensive proficiency matrix calculations. If `is_monster = true`, they return hardcoded DCs, AC, and attacks directly from their `monster_stats` dictionary.

---

## 2. Rendering Pipeline & Perspective (2.5D HD-2D)
The game utilizes a "2.5D HD-2D" rendering pipeline, heavily inspired by titles like Triangle Strategy and Octopath Traveler.
* **Camera Rig (`PFCameraRig`):** A custom 3D gimbal camera using **Orthographic** projection to simulate an isometric perspective without distance distortion (Standard rotation: X: -30°, Y: 45°, Z: 0°). Supports WASD/Edge panning, mouse-drag rotation, and smooth zooming.
* **World Space & Grid (`PFCombatGrid`):** The environment is strictly 3D. The tactical grid is drawn using `MultiMeshInstance3D` to render thousands of dynamic tile highlights (movement bounds, AoE templates) in a single draw call. `PFCombatGrid` internally handles Pathfinder 2e diagonal distance math (5ft-10ft-5ft).
* **Entity Visualization:** Actors and interactive objects are rendered using `Sprite3D` nodes with `Billboard = Y-Billboard` and `Alpha Cut = Discard`. This ensures tokens constantly face the camera even when the rig rotates 360 degrees.
* **Programmatic UI (`PFActionMenu`):** Complex, highly dynamic battle UI (like the Action Menu) is built **programmatically via GDScript** rather than relying on brittle `.tscn` nodes. The UI exists on a separate `CanvasLayer` and uses explicit anchors (e.g., `set_anchors_and_offsets_preset`) to maintain flawless resolution scaling across the screen.

---

## 3. Database & Instantiation (`pf_database.gd`)
The SQLite database is the source of all game data. It contains tables for: `classes`, `spells`, `spell_variants`, `deities`, `weapons`, `shields`, `ancestries`, and `backgrounds`.
* JSON arrays stored in the database (e.g., traits, ability boosts, divine fonts) are parsed inside `pf_database.gd` getters.
* **Relational Magic:** Spells are split into `spells` (core identity) and `spell_variants` (relational table bound by `spell_id`). Variants dictate action cost (including `ONE_ROUND` / `TWO_ROUNDS`), range, targets, and damage dice for specific cast methods.
* **Instantiation:** When creating an item, call the factory methods (e.g., `PFDatabase.get_weapon("longsword")`). This returns a fully constructed GDScript object (`PFWeapon`, `PFShield`, etc.) ready to be added to an inventory.

---

## 4. Item & Equipment Architecture
All items inherit from `PFEntity` -> `PFItem`.
* **Economy:** The absolute source of truth for value is `price_cp` (copper pieces). floats are converted to copper upon initialization. Always use `PFInventory.format_copper_to_string(price_cp)` for UI displays.
* **Durability:** Items track `hardness`, `max_hp`, `current_hp`, and `broken_threshold`.
* **Runes:** Weapons and Armors handle runes via `.apply_fundamental_runes()`. Shields handle them via `.apply_reinforcing_rune()`. Applying a rune automatically recalculates the item's level, copper price, max HP/Hardness, and dynamically updates its `entity_name` (e.g., prepending "+1 Striking").
* **Shield Block:** Shield damage blocking logic resides in `PFShield.can_block(damage_type)`, checking against an array of `blockable_damage_types`.

---

## 5. Inventory & Hand Tracking (`PFInventory`)
The `PFInventory` class manages all bulk, economy, and equipment states.
* **Investment:** Magic items with `requires_investment = true` MUST be added to the `invested_items` array before they can be equipped/wielded. The `max_invested_items` limit is dynamic (default 10) and bypassed by monsters.
* **Hand Occupancy:** Hands are tracked via `held_main_hand`, `held_off_hand`, and `two_handed_item`. 
* **Wielding vs Holding:** A weapon must be passed through `.wield_item()` to be considered active for combat (`is_wielded = true`).
* **Buckler Logic:** Bucklers require a free hand or a hand holding a light (`bulk_value < 10`), non-weapon (`is_weapon = false`) object to be raised. This is calculated dynamically via `PFInventory.can_raise_shield()`.

---

## 6. Magic System (`PFSpellbook`)
Every `PFActor` instantiates a `PFSpellbook`.
* The spellbook holds hardcoded progression arrays mapping character levels to available spell slots based on their class type (None, Full Caster, Bounded Caster).
* Calculates max slots by adding base class slots + any `extra_slots` granted by feats.
* Spells are tracked in dedicated arrays: `known_spells`, `repertoire`, `prepared_spells`, `innate_spells`, and `signature_spells`.
* **Heightening:** `PFSpell` handles heightening math natively: `(cast_rank - base_spell_rank) / scaling_rules` applied to base damage.

---

## 7. AI Code Generation Directives
When generating GDScript for this project, you MUST adhere to the following rules:
1. **Never use `.tres` for data.** If asked to create a new weapon, spell, or class, write the SQL `INSERT` statement for `pf_database.gd`, do NOT generate a Godot Resource.
2. **Never duplicate equipment states.** If an actor attacks, check `actor.inventory.held_main_hand`. Do not create an `equipped_weapon` variable on the Actor.
3. **Use Vector3 for spatial logic.** Do not attempt to calculate 2D isometric grid conversions. Rely entirely on the 3D engine for RayCasting, distances, and areas of effect. 
4. **Use `price_cp` strictly.** Never do math with Gold Pieces (`gp`) outside of initial database seeding; all internal engine math operates on integers of copper.