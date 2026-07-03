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
## 2024-07-04 - Handling Empty States in Programmatic UI Menus
**Learning:** When building dynamically generated UI menus in Godot 4, not handling empty states can lead to confusing blank interfaces for the user if a menu category has no items.
**Action:** Explicitly handle empty states by checking the child container's count (e.g., `get_child_count() == 0`) and appending a disabled placeholder button with a helpful tooltip to avoid confusing blank interfaces.
