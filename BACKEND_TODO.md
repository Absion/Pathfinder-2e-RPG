# Pathfinder 2e Engine: Backend TODO & Roadmap

This document outlines the remaining Pathfinder 2e rules and logic systems required to bring the engine to full feature-completeness. They are ordered by **foundational priority**, meaning earlier tasks build the necessary infrastructure for later tasks.

## Phase 1: Spatial & Tactical Foundations
These features make positioning on the grid matter.
- [x] **Flanking System**: Raycasting math to determine if an enemy is flanked by two allies, automatically applying the *Off-Guard* condition.
- [x] **Cover System**: 3D raycasting collisions to determine *Lesser*, *Standard*, and *Greater* cover, automatically applying circumstance bonuses to AC and Reflex saves.
- [x] **AoE Grids & Splash Damage**: Logic to calculate Cones, Bursts, Emanations, and Lines on the grid for spells and alchemical bombs.

## Phase 2: Action Diversity
These features give martial characters and skill-monkeys their tactical depth.
- [x] **Athletics Maneuvers**: Implement `PFAction` subclasses for *Grapple*, *Trip*, *Shove*, and *Disarm*, hooking them into the UI and checking against Fortitude/Reflex DCs.
- [x] **Social Combat Actions**: Implement *Demoralize*, *Feint*, *Bon Mot*, *Create a Diversion*, and *Battle Medicine* (rolling Intimidation/Deception/Medicine against Will/Perception/Flat DCs).

## Phase 3: The Stealth Subsystem
This phase relies entirely on Phase 1's Cover mechanics.
- [x] **Stealth States**: Manage the transitions between *Observed*, *Hidden*, *Undetected*, and *Unnoticed*.
- [x] **Stealth Actions**: Implement *Hide*, *Sneak*, and *Seek*.
- [x] **Advanced Senses**: Implement Darkvision, Low-light vision, Scent, and Tremorsense interactions with stealth.

## Phase 4: Advanced Magic
- [x] **The Counteract Subsystem**: A unified manager for *Dispel Magic*, *Counterspell*, and treating severe diseases.
- [x] **Sustained Spells**: Logic for spending actions to maintain a spell's effect or move its area (e.g., *Flaming Sphere*).
- [x] **Focus Points**: Implement the 3-point focus pool, Focus Spells, and the *Refocus* exploration activity.

## Phase 5: Afflictions & Sub-Entities
- [x] **Affliction Stages**: Implement the rigid "Stage" system for diseases and poisons, progressing stages on failed saving throws.
- [x] **Minions & Familiars**: Action economy sharing (Command an Animal) for autonomous pets.
- [x] **Swarms & Troops**: Specialized monster logic for area damage weaknesses and physical resistance.

## Phase 6: Items & Economy
- [x] **Interact & Carry States**: Differentiate between *Held*, *Worn*, and *Stowed* items, and implement the `PFActionInteract` to enforce the action economy (e.g., 1 action to draw, 2 to retrieve from backpack, 0 to release/drop).
- [x] **Item Damage**: Implement item durability, Hardness, and the *Broken* condition mechanics.
- [x] **Consumables**: Elixirs, Mutagens, and Talismans.
- [x] **Magical Staves & Wands**: Tracking staff charges and wand overcharging.
- [x] **Crafting Subsystem**: Downtime activity logic for crafting items from formulas.

## Phase 7: Deep Character Progression
- [x] **Archetypes / Multiclassing**: Logic to select Dedication feats and merge spell slots across multiple traditions.
- [x] **Codas**: Instrument attachments that grant bards unique abilities and spells.
- [x] **Spellhearts**: Magical attachments for armor/weapons that grant cantrips and passive effects.
- [x] **Alchemical Items**: Handling bombs, elixirs, tools, and poisons with their specific craft/use rules.
- [x] **Banners**: Aura-emitting held items that grant persistent bonuses to allies.
- [x] **Grafts**: Body modifications and augmentations.
- [x] **Grimoires**: Specialized spellbooks that grant benefits when preparing spells from them.
- [x] **Firearm Customizations**: Scopes, bayonets, and custom grips.
- [x] **Cursed Items**: Items with negative effects that cannot be easily unequipped.
- [x] **Tattoos**: Magical skin modifications with item investiture logic.

## Phase 8: Game Loop & Daily Preparation
- [x] **Daily Preparation Manager**: Create a unified manager (`PFDailyPrepManager`) for the Morning Rest cycle. 
  - Allows actors to explicitly prepare their spells in their spellbook.
  - Allows Prepared Casters to expend slots to charge magical staves.
  - Resets Focus Points, Hit Points, and handles temporary item generation (Alchemist infusions, snare crafting).

## Phase 9: Active Conditions and Effect Tracking
- [x] **Condition Manager (`PFConditionManager`)**: Centralize logic for ticking, expiring, and handling overlapping conditions.
- [x] **Persistent Damage**: Robust logic for triggering persistent damage at the end of a turn and resolving recovery flat checks.
- [x] **Affliction Ticking**: Hooking poison/disease progression into turn phases or time progression.

## Phase 10: The Inventory Subsystem
- [x] **Encumbrance**: Bulk calculation and application of the Encumbered condition.
- [x] **Containers**: Backpacks, bags of holding, and retrieving items from within containers.
- [x] **Investiture**: 10-item limit for invested magical items.
- [x] **Coins & Wealth**: Tracking CP, SP, GP, PP.
