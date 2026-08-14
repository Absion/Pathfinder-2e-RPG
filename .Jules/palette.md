## 2024-06-27 - Programmatic UI Interaction Discoverability
**Learning:** In Godot 4, programmatic UI elements like `TextureRect` default to `MOUSE_FILTER_IGNORE` and `PanelContainer` lack proper cursor affordances by default, leading to undiscoverable tooltips and non-obvious clickable elements.
**Action:** When building data-driven UI components via script, explicitly set `mouse_filter = Control.MOUSE_FILTER_PASS` (for tooltips on images/icons) and `mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND` (for clickable containers/buttons) to ensure standard accessibility guidelines are met.
## 2026-06-28 - Programmatic UI Interaction Discoverability
**Learning:** In Godot 4, programmatic UI elements like `TextureRect` default to `MOUSE_FILTER_IGNORE` and `PanelContainer` lack proper cursor affordances and keyboard focus by default, leading to undiscoverable tooltips and non-obvious clickable elements that are inaccessible via keyboard.
**Action:** When building data-driven UI components via script, explicitly set `mouse_filter = Control.MOUSE_FILTER_PASS` (for tooltips), `mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND` (for clickable containers), and `focus_mode = Control.FOCUS_ALL` (to support keyboard navigation with Space/Enter handling) to ensure standard accessibility guidelines are met.
## 2026-06-30 - Visual Focus Feedback for Programmatic UI Containers
**Learning:** In Godot 4, programmatic UI containers (like `PanelContainer`) lack built-in visual focus feedback, even when `focus_mode` is enabled.
**Action:** Manually connect `focus_entered`, `focus_exited`, `mouse_entered`, and `mouse_exited` signals to visually indicate focus/hover states (e.g., by adjusting `modulate` color) to ensure interaction discoverability for keyboard and mouse navigation.
## 2024-07-01 - Focus Management for Dynamic Menus
**Learning:** In Godot 4 programmatic UI, when dynamically hiding/showing components (like submenus), keyboard users lose focus context if the focused element is hidden.
**Action:** Always store the name or reference of the button that opened the submenu. When closing the menu, manually re-apply `grab_focus()` to the original button. When opening, immediately apply `grab_focus()` to the newly revealed back button or first item. This adheres to WCAG focus discoverability standards.
## 2024-07-02 - Explicit Empty States for Dynamic Menus
**Learning:** In dynamically generated UI menus, leaving a container completely empty can cause confusion, as users might think the interface is broken rather than intentionally blank.
**Action:** Always include a check for an empty list (`get_child_count() == 0`) and append an explicitly disabled "No items available" indicator with a helpful tooltip.
## 2024-07-05 - Disabled State Clarification
**Learning:** In complex forms (like character creation), simply disabling a submit button without explanation leaves users guessing which required fields are missing, violating UX heuristics for error prevention and system status visibility.
**Action:** Always pair `disabled = true` states on critical action buttons with a clear, specific `tooltip_text` explaining exactly what needs to be completed to proceed. Ensure the tooltip is cleared when the button becomes enabled.
## 2024-07-06 - Dynamic Tooltips for Disabled UI Form Fields
**Learning:** In complex UI forms (like character creation), simply setting a submit button or cascading dropdown to `disabled = true` without explanation leaves users guessing which prerequisite fields are missing, violating heuristic guidelines for error prevention and system status visibility.
**Action:** When disabling interactive UI elements, always provide a clear, specific, and dynamically generated `tooltip_text` that lists exactly what is missing (e.g., using `PackedStringArray().join(", ")` in GDScript). Ensure the tooltip is reset to `""` when the element becomes enabled.

## 2026-07-14 - Visual Required Indicators and Auto-Focus
**Learning:** In Godot UI forms, required fields must be visually indicated proactively, and initial keyboard focus should be explicitly set via grab_focus() on the first interactive element to allow immediate keyboard interaction.
**Action:** Always append * to required field labels and call grab_focus() on the first input during form initialization.

## 2026-07-17 - [Cursor Affordance on Disabled Elements]
**Learning:** In Godot, UI elements that are initialized with a pointing hand cursor retain it even when `disabled = true`, creating false clickability affordances.
**Action:** Always manually reset `mouse_default_cursor_shape` to `Control.CURSOR_ARROW` alongside setting `disabled = true`.

## 2026-07-22 - Cursor Affordance on Initial Disabled States
**Learning:** In Godot UI, dynamically generated option buttons initialized as disabled retain the default pointing hand cursor from their factory method, creating false affordances on page load.
**Action:** When manually setting disabled = true during UI initialization for forms, always accompany it with mouse_default_cursor_shape = Control.CURSOR_ARROW to prevent user confusion.
## 2026-07-21 - LineEdit Interaction Feedback
**Learning:** In Godot 4, `LineEdit` nodes do not have clear buttons or blinking carets enabled by default, reducing input interaction quality.
**Action:** Always set `clear_button_enabled = true` and `caret_blink = true` when programmatically instantiating `LineEdit` for form inputs to match expected modern UX patterns.
## 2024-07-28 - Preventing Layout Shifts in Dynamic Forms
**Learning:** In Godot UI forms, dynamic sections collapse if left completely empty on initialization, causing jarring layout shifts when users begin interacting with earlier options that populate them.
**Action:** Prevent this by explicitly calling dynamic rebuild methods (e.g., `_rebuild_skills()`) within `_ready()` to render 'zero states' instead of relying entirely on reactive user input to build the initial structure.
## 2026-07-24 - Explicit Empty States in Godot Forms
**Learning:** Dynamic Godot UI sections completely collapse if left empty, causing major layout shifts when data is populated later.
**Action:** Always call dynamic rebuild methods (e.g., _rebuild_skills) in _ready() and render 'zero states' instead of returning early.

## 2024-07-29 - Default Options for Optional Dropdowns
**Learning:** In Godot UI forms, when creating optional dropdowns (OptionButton), omitting a default 'Unspecified' option forces the top-most valid choice to be selected by default, leading to accidental incorrect submissions.
**Action:** Always include a default '--- Select ---' item (mapped to an UNKNOWN or -1 value) as the first option to prevent users from accidentally submitting the default top-most value.

## 2026-08-12 - Disable OptionButton Placeholder
**Learning:** Dropdowns with a placeholder like '---' allow users to accidentally select an invalid or empty state if not disabled. Explicitly disabling index 0 ensures the placeholder acts only as a visual prompt.
**Action:** Always use `set_item_disabled(0, true)` when adding a placeholder text as the first item in Godot OptionButtons.
## 2024-08-15 - Prevent State Clobbering in Custom Focus Visuals
**Learning:** When manually implementing visual focus/hover states for Godot UI containers, connecting simple lambdas for enter/exit signals causes state clobbering (e.g., mouse exiting clears keyboard focus).
**Action:** Use a unified handler for all 4 mouse/focus signals that explicitly checks both `has_focus()` and `get_global_rect().has_point(get_global_mouse_position())` to determine the final visual state.
