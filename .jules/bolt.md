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
## 2026-07-06 - distance_squared_to over distance_to and inline math
**Learning:** In GDScript, inside tight loops (like checking aura overlap), using `distance_to` allocates implicit vectors and performs a costly `sqrt` operation. While inline math (`dx * dx + dy * dy + dz * dz`) avoids this, doing multiple property accesses inside the interpreted GDScript VM is typically slower than calling a single heavily optimized native C++ built-in method like `distance_squared_to`. Additionally, `distance_squared_to` safely handles both 2D and 3D vectors via duck-typing, unlike manual `.z` property access which would crash on a `Vector2`.
**Action:** Use Godot's native `distance_squared_to` method instead of `distance_to` or inline math for distance checks to minimize Garbage Collection overhead and maintain 2D/3D safety in grid loops.
## 2026-07-08 - Use distance_squared_to over inline math property accesses
**Learning:** In Godot (GDScript), calling highly optimized native C++ built-in methods (like `distance_squared_to` for vector math) is significantly faster than interpreting multiple discrete arithmetic operations and property accesses within a GDScript `for` loop, while maintaining 2D/3D compatibility.
**Action:** Replace manually inlined vector distance math with `distance_squared_to`, precalculating differences outside loops when applicable.
## 2026-07-09 - Avoid rounding and property access inside hot combat grid loops
**Learning:** Checking for space occupancy (`is_space_occupied`) is a hot path inside combat grid pathfinding. Extracting static vectors' positional X/Z rounds and actor Y bounds significantly reduces GC overhead inside `for` blocks compared to doing math on every overlap evaluation.
**Action:** When implementing grid loop logic, cache loop-invariant mathematical outcomes (like target rounding or `global_position.y`) ahead of internal checking sequences to limit GDScript engine operations.
## 2026-07-10 - Cache node properties before tight loops
**Learning:** In GDScript, reading a property like `global_position` from a Node involves crossing the GDScript-to-C++ boundary and executing getter logic. Doing this repeatedly inside a loop incurs unnecessary overhead.
**Action:** Cache Node properties (like position vectors) into local variables prior to executing tight loops to maximize performance.
## 2026-07-11 - Cache moving troop segments before grid intersection loops
**Learning:** Inside `is_space_occupied`, resolving absolute target coordinates for moving troop segments involves repeated `round` and addition operations that were being executed per-segment of every actor on the grid.
**Action:** Extract and cache the absolute target positions of the mover's segments as arrays outside the main `for record in combatants` loop to minimize VM operation counts and GC pressure inside hot loops.
## 2026-07-13 - Lazily evaluate expensive loop-invariant operations
**Learning:** In GDScript, inside hot path loops (like iterating through senses in `PFDetectionManager`), calculating distance checks like `distance_squared_to` on every iteration incurs unnecessary overhead when the calculation is loop-invariant (the observer and target don't move during the evaluation). However, calculating it strictly *before* the loop might be unnecessary if an early break/continue occurs.
**Action:** Use lazy evaluation for expensive loop-invariant operations by initializing a sentinel value (e.g., `-1.0`) outside the loop and calculating it only when first needed inside the loop, preventing redundant calculations and unnecessary C++ boundary crossings.
## 2024-07-21 - [Singleton Pattern for Root Node]
**Learning:** Checking for node existence with `has_node` and retrieving it via `get_node` on Engine.get_main_loop().root during runtime incurs expensive scene tree traversal overhead.
**Action:** Implement static instance caching on globally accessed nodes to avoid overhead and reuse the instance.

## 2024-07-24 - Avoid dictionary.keys() inside loops
**Learning:** In Godot 4, calling `dictionary.keys()` creates and returns a brand new Array. When used inside iteration loops, especially O(N²) relational evaluations like the detection matrix, this causes repeated heap allocations and severe Garbage Collection pressure.
**Action:** Iterate directly over the dictionary (e.g., `for key in my_dict:`) which traverses the keys natively without allocating a temporary Array.
## 2026-07-27 - Never optimize Enum `.keys()` reverse lookups in GDScript
**Learning:** In GDScript, Godot Enums are implemented as dictionaries that map `StringName` keys to integer values. To perform a reverse lookup (getting the string name given the integer value), the idiom is `Enum.keys()[integer_value]`. Trying to optimize this by removing `.keys()` (e.g., `Enum[integer_value]`) will cause a runtime crash because the dictionary does not have integer keys.
**Action:** When optimizing dictionary iterations (e.g., changing `for key in dict.keys():` to `for key in dict:`), carefully audit the code to ensure you are not accidentally replacing enum reverse lookups.
## 2026-08-08 - Avoid string-based reflection (has_method) in hot loops
**Learning:** In GDScript, using reflection methods like `has_method("string")` inside tight loops (like aura processing) forces Godot to perform expensive string allocations and hash lookups on every iteration, causing significant overhead.
**Action:** Extract and cache string-based reflection checks (`has_method`) outside of iterative loops to minimize Godot VM boundary crossings.
## 2024-08-14 - Optimization of Dictionary keys usage in for loops
**Learning:** Calling Dictionary.keys() in Godot 4 allocates and returns a new Array, causing unnecessary heap allocations and garbage collection pressure in hot loops.
**Action:** Always iterate directly over the dictionary (e.g., `for key in my_dict:`) rather than using `.keys()` to avoid unnecessary allocations.
## 2024-08-14 - Optimization of String-based reflection checks
**Learning:** Passing standard string literals to reflection methods like `has_method()` causes overhead by allocating, hashing, and converting the String into a StringName on every execution.
**Action:** Always pass `StringName` literals (e.g., `&"method_name"`) instead of standard `String` literals to bypass the overhead.
## 2023-10-25 - Cache Godot properties for heavy spatial math
**Learning:** In GDScript, accessing built-in Node properties (like `position` or `global_position`) crosses the GDScript-to-C++ boundary. When these properties are accessed multiple times in mathematical functions like `is_flanking()`, it creates unnecessary overhead.
**Action:** Always extract and cache node properties into local variables before executing spatial operations or tight loops to minimize redundant C++ property accesses.
## 2026-08-31 - Avoid JSON.new() and .parse() for simple data parsing
**Learning:** In Godot 4, instantiating `JSON.new()` and calling `.parse()` allocates unnecessary objects and increases Garbage Collection pressure for simple JSON string parsing.
**Action:** Use the static method `JSON.parse_string()` instead to avoid object allocations when parsing simple JSON strings.
