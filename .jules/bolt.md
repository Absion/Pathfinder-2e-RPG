## 2026-06-27 - Replaced UI polling with event-driven updates
**Learning:** Polling state variables in `_process` for UI updates wastes CPU and GC resources.
**Action:** Replace `_process` polling loops with signal-driven updates whenever `hp_changed`, `temp_hp_changed`, `actions_changed`, or `reactions_changed` emit.
## 2026-06-27 - Cache loop-invariant variables in Godot scripts
**Learning:** In GDScript, especially in heavily-called functions like grid occupancy checks (`is_space_occupied`), evaluating array allocations (`[]`) and method lookups (`has_trait`, `get_combatant_record`) inside loops over combatants can create unnecessary GC pressure and slowdowns.
**Action:** Extract and cache loop-invariant calculations outside of loops whenever possible to optimize tight loops in GDScript.
## 2026-06-28 - Avoid string-based node lookups in hot loops
**Learning:** Checking for node existence or fetching them with `has_node("String")` and `get_node("String")` inside frequent logic loops creates Godot tree traversal overhead and allocates strings, reducing GDScript performance.
**Action:** When accessing components (like senses) frequently, use property checks like `if "senses" in actor and actor.senses != null:` instead of relying on the scene tree methods to retrieve them.
