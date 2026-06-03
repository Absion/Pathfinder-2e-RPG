# Pathfinder 2e Godot Engine

This is a custom-built, data-driven Pathfinder 2e engine implemented in Godot 4 using GDScript and a local SQLite database.

## System Architecture

The engine is built around a highly relational, data-first architecture. It prioritizes using strict Enums (like `ActionCost`, `MagicTradition`, `Distance`) to keep memory low and database queries lightning fast.

Here is a high-level view of the core engine components and their relationships:

```mermaid
classDiagram
    %% Core Entities
    class PFEntity {
        <<Base Class>>
        +String entity_name
        +Array traits
        +Rarity rarity
    }
    
    class PFDatabase {
        <<Singleton>>
        +SQLite db
        +get_pf_spell(id) PFSpell
        +get_pf_class(id) PFClass
    }

    %% Actors
    class PFActor {
        +int max_hp
        +PFProficiencySheet sheet
        +PFInventory inventory
        +PFSpellbook spellbook
        +get_spell_dc() int
        +get_spell_attack() int
    }
    PFEntity <|-- PFActor
    
    class PFPlayerActor {
        +PFClass actor_class
        +PFAncestry ancestry
    }
    PFActor <|-- PFPlayerActor

    %% Sub-Systems
    class PFSpellbook {
        <<Manager>>
        +Array known_spells
        +Dictionary repertoire
        +Dictionary prepared_spells
        +get_max_slots(rank) int
    }
    PFActor *-- PFSpellbook : owns

    class PFInventory {
        <<Manager>>
        +Array items
        +int copper_pieces
        +get_total_bulk() int
    }
    PFActor *-- PFInventory : owns

    %% Magic
    class PFSpell {
        +int base_spell_rank
        +Array traditions
        +Array variants
        +get_damage_dice(actions) int
    }
    PFEntity <|-- PFSpell
    
    class PFSpellVariant {
        <<Resource>>
        +ActionCost action_cost
        +Distance spell_range
        +int damage_dice
        +Array applied_conditions
    }
    PFSpell *-- PFSpellVariant : contains

    %% Items
    class PFItem {
        +int bulk
        +int price_cp
    }
    PFEntity <|-- PFItem
    
    class PFWeapon {
        +int damage_dice
        +int damage_faces
    }
    PFItem <|-- PFWeapon
```

## Highlights
- **Database Driven:** `PFDatabase` seeds and queries a local `pf2e_data.db` SQLite file. Schema changes are strictly managed.
- **Relational Spell Variants:** Spells dynamically morph their behavior (range, damage, conditions) based on the number of actions used to cast them, handled cleanly by the `PFSpellVariant` object.
- **Master Spellbook:** A single `PFSpellbook` manager tracks complex multi-class spell progressions, feats, innate spells, and extra slots simultaneously.
- **Monster Optimization:** NPCs completely bypass expensive proficiency matrix calculations for instantaneous processing.
