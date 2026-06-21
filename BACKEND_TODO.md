# Pathfinder 2e Engine: Backend TODO & Roadmap

This document outlines the remaining Pathfinder 2e rules and logic systems required to bring the engine to full feature-completeness. They are ordered by **foundational priority**, meaning earlier tasks build the necessary infrastructure for later tasks.

## Phase 1: Spatial & Tactical Foundations
These features make positioning on the grid matter.
- [x] **Flanking System**: Raycasting math to determine if an enemy is flanked by two allies, automatically applying the *Off-Guard* condition.
- [x] **Cover System**: 3D raycasting collisions to determine *Lesser*, *Standard*, and *Greater* cover, automatically applying circumstance bonuses to AC and Reflex saves.
- [ ] **AoE Grids & Splash Damage**: Logic to calculate Cones, Bursts, Emanations, and Lines on the grid for spells and alchemical bombs.

## Phase 2: Action Diversity
These features give martial characters and skill-monkeys their tactical depth.
- [ ] **Athletics Maneuvers**: Implement `PFAction` subclasses for *Grapple*, *Trip*, *Shove*, and *Disarm*, hooking them into the UI and checking against Fortitude/Reflex DCs.
- [ ] **Social Combat Actions**: Implement *Demoralize*, *Feint*, *Bon Mot*, and *Create a Diversion* (rolling Intimidation/Deception against Will/Perception DCs).

## Phase 3: The Stealth Subsystem
This phase relies entirely on Phase 1's Cover mechanics.
- [ ] **Stealth States**: Manage the transitions between *Observed*, *Hidden*, *Undetected*, and *Unnoticed*.
- [ ] **Stealth Actions**: Implement *Hide*, *Sneak*, and *Seek*.
- [ ] **Advanced Senses**: Implement Darkvision, Low-light vision, Scent, and Tremorsense interactions with stealth.

## Phase 4: Advanced Magic
- [ ] **The Counteract Subsystem**: A unified manager for *Dispel Magic*, *Counterspell*, and treating severe diseases.
- [ ] **Sustained Spells**: Logic for spending actions to maintain a spell's effect or move its area (e.g., *Flaming Sphere*).
- [ ] **Focus Points**: Implement the 3-point focus pool, Focus Spells, and the *Refocus* exploration activity.

## Phase 5: Afflictions & Sub-Entities
- [ ] **Affliction Stages**: Implement the rigid "Stage" system for diseases and poisons, progressing stages on failed saving throws.
- [ ] **Minions & Familiars**: Action economy sharing (Command an Animal) for autonomous pets.
- [ ] **Swarms & Troops**: Specialized monster logic for area damage weaknesses and physical resistance.

## Phase 6: Items & Economy
- [ ] **Consumables**: Elixirs, Mutagens, and Talismans.
- [ ] **Magical Staves & Wands**: Tracking staff charges and wand overcharging.
- [ ] **Crafting Subsystem**: Downtime activity logic for crafting items from formulas.

## Phase 7: Deep Character Progression
- [ ] **Archetypes / Multiclassing**: Logic to select Dedication feats and merge spell slots across multiple traditions.
