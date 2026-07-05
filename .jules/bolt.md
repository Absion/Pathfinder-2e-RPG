## 2026-06-27 - Replaced UI polling with event-driven updates
**Learning:** Polling state variables in `_process` for UI updates wastes CPU and GC resources.
**Action:** Replace `_process` polling loops with signal-driven updates whenever `hp_changed`, `temp_hp_changed`, `actions_changed`, or `reactions_changed` emit.
## 2026-06-27 - Cache loop-invariant variables in Godot scripts
**Learning:** In GDScript, especially in heavily-called functions like grid occupancy checks (`is_space_occupied`), evaluating array allocations (`[]`) and method lookups (`has_trait`, `get_combatant_record`) inside loops over combatants can create unnecessary GC pressure and slowdowns.
**Action:** Extract and cache loop-invariant calculations outside of loops whenever possible to optimize tight loops in GDScript.
## 2026-06-28 - Avoid string-based node lookups in hot loops
**Learning:** Checking for node existence or fetching them with `has_node("String")` and `get_node("String")` inside frequent logic loops creates Godot tree traversal overhead and allocates strings, reducing GDScript performance.
**Action:** When accessing components (like senses) frequently, use property checks like `if "senses" in actor and actor.senses != null:` instead of relying on the scene tree methods to retrieve them.
## 2026-07-01 - Avoid internal array allocations in GDScript tight loops
**Learning:** Instantiating temporary arrays `[]` inside hot loop functions like `is_space_occupied` produces significant GC overhead and heap allocation pressure.
**Action:** When calculating mathematical bounds or positions (like target cell checking) inside highly repetitive functions, expand the logic to calculate coordinates manually and inline instead of storing objects/vectors in an array to iterate over later.
## 2026-07-02 - Cache Database Singleton Instance
**Learning:** Frequent calls to `PFDatabase.get_instance()` were performing string-based scene tree traversals (`has_node` and `get_node`) which are slow and allocate memory.
**Action:** Implemented a static cache variable `_instance_cache` in `PFDatabase` and used `is_instance_valid` to ensure safety. Replaced manual scene tree lookups in hot paths (like `PFItem._init`) with the cached getter.
## 2026-07-05 - Squared Distance Over distance_to
**Learning:** In GDScript, inside tight calculation loops, using `distance_to` allocates implicit vectors and performs a costly `sqrt` operation. Furthermore, creating a new array via assignment (`ties = [i]`) causes unnecessary heap allocation per reassignment.
**Action:** Use inline math (`dx * dx + dy * dy + dz * dz`) for squared distance comparisons, and recycle arrays using `.clear()` and `.append()` to minimize Garbage Collection overhead in grid loops.
