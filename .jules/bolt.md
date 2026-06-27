## $(date +%Y-%m-%d) - Cache loop-invariant variables in Godot scripts
**Learning:** In GDScript, especially in heavily-called functions like grid occupancy checks (`is_space_occupied`), evaluating array allocations (`[]`) and method lookups (`has_trait`, `get_combatant_record`) inside loops over combatants can create unnecessary GC pressure and slowdowns.
**Action:** Extract and cache loop-invariant calculations outside of loops whenever possible to optimize tight loops in GDScript.
