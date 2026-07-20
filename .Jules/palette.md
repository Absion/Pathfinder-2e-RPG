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
