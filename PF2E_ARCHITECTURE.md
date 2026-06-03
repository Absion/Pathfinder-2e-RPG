# Pathfinder 2e System Architecture

This document tracks the core design rules and custom architecture for the Pathfinder 2e Godot engine. 
**If you are an AI assistant starting a new session, READ THIS FILE FIRST.**

## Core Philosophies
1. **Enums Over Strings:** Everything uses strict integers and Enums to keep database queries lightning fast.
2. **Relational Data:** Complex data (like Spell Variants) uses a relational database model via Godot SQLite.
3. **Monster Optimization:** NPCs completely bypass expensive proficiency matrix calculations. If `is_monster = true`, they just return hardcoded DCs and attacks.

## Database (SQLite)
The engine is powered by a local SQLite database (`res://db/pf2e_data.db`) initialized via `scripts/database/pf_database.gd`.
- `classes`: Tracks all class bases, including `spell_progression` (None, Full Caster, Bounded Caster).
- `spells`: The core spell identity.
- `spell_variants`: Relational table bound to `spells` via `spell_id`. Each variant corresponds to a specific action cost (e.g., 2 actions vs 3 actions vs 2 rounds) and dictates range, targets, damage dice, and applied conditions for that specific casting.

## Magic System (`PFSpellbook`)
- **Location:** `scripts/base/magic/pf_spellbook.gd`
- Every `PFActor` instantiates a `PFSpellbook` on `_init()`.
- The spellbook holds hardcoded progression arrays mapping character levels to available spell slots based on their class type.
- It dynamically calculates max slots by adding base class slots + any `extra_slots` granted by feats (like Arcane Tattoos).
- Spells are tracked in dedicated arrays/dictionaries: `known_spells`, `repertoire`, `prepared_spells`, `innate_spells`, and `signature_spells`.

## Entities & Actions
- **`PFEntity`**: The root of the system. Holds massive system-wide enums like `ActionCost` (now including `ONE_ROUND` and `TWO_ROUNDS`), `MagicTradition`, `Distance`, and `ScalingType`.
- **Heightening Math:** `PFSpell` natively handles calculating damage dice by taking the cast rank, subtracting the base spell rank, and applying the `scaling_rules` (e.g. dividing by 2 for +2 heightening) before adding it to the variant's base damage.
