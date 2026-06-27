# pf_action_menu.gd
## The dynamic programmatic UI for selecting combat actions.
class_name PFActionMenu
extends Control

enum MenuPosition { TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT }
@export var menu_position: MenuPosition = MenuPosition.BOTTOM_RIGHT

var bound_actor: PFActor = null

# UI Elements
var margin_container: MarginContainer

var main_menu_vbox: VBoxContainer
var submenu_vbox: VBoxContainer

var name_label: Label
var hp_label: Label
var conditions_hbox: HBoxContainer
var action_icons: Array[TextureRect] = []
var reaction_icon: TextureRect
var portrait: TextureRect

var action_texture: Texture2D = preload("res://assets/ui/icons/actions/Action.webp")
var reaction_texture: Texture2D = preload("res://assets/ui/icons/actions/Reaction.webp")

func _ready():
	# Make the root control span the entire CanvasLayer without blocking mouse clicks
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var global_theme = preload("res://assets/ui/theme/pf_global_theme.tres")
	theme = global_theme
	
	margin_container = MarginContainer.new()
	add_child(margin_container)
	
	var main_panel = PanelContainer.new()
	margin_container.add_child(main_panel)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	main_panel.add_child(hbox)
	
	# --- LEFT SIDE: ACTIONS & SUBMENUS ---
	var left_panel = Control.new()
	left_panel.custom_minimum_size = Vector2(160, 0)
	hbox.add_child(left_panel)
	
	main_menu_vbox = VBoxContainer.new()
	main_menu_vbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	main_menu_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	left_panel.add_child(main_menu_vbox)
	
	submenu_vbox = VBoxContainer.new()
	submenu_vbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	submenu_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	submenu_vbox.hide()
	left_panel.add_child(submenu_vbox)
	
	_build_main_menu()
	
	# --- MIDDLE DIVIDER ---
	var divider1 = ColorRect.new()
	divider1.custom_minimum_size = Vector2(2, 0)
	divider1.color = Color("#a6a6b5")
	divider1.color.a = 0.5
	hbox.add_child(divider1)
	
	# --- MIDDLE SIDE: CHARACTER INFO ---
	var mid_vbox = VBoxContainer.new()
	mid_vbox.custom_minimum_size = Vector2(200, 0)
	mid_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(mid_vbox)
	
	name_label = Label.new()
	name_label.text = "CHARACTER NAME"
	name_label.add_theme_font_size_override("font_size", 20)
	mid_vbox.add_child(name_label)
	
	hp_label = Label.new()
	hp_label.text = "0/0 HP"
	hp_label.add_theme_font_size_override("font_size", 16)
	hp_label.add_theme_color_override("font_color", Color("#a6a6b5"))
	mid_vbox.add_child(hp_label)
	
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 5)
	mid_vbox.add_child(spacer1)
	
	# Conditions Button / Bar
	var conditions_panel = PanelContainer.new()
	conditions_panel.theme_type_variation = &"ConditionPanel"
	conditions_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	conditions_panel.tooltip_text = "View Conditions"
	mid_vbox.add_child(conditions_panel)
	
	conditions_hbox = HBoxContainer.new()
	conditions_hbox.custom_minimum_size = Vector2(0, 32)
	conditions_panel.add_child(conditions_hbox)
	
	# Optional: make the condition panel clickable
	conditions_panel.gui_input.connect(_on_conditions_gui_input)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	mid_vbox.add_child(spacer2)
	
	# Action Tracker (Diamonds)
	var tracker_hbox = HBoxContainer.new()
	tracker_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tracker_hbox.add_theme_constant_override("separation", 10)
	mid_vbox.add_child(tracker_hbox)
	
	for i in range(3):
		var act_icon = TextureRect.new()
		act_icon.texture = action_texture
		act_icon.custom_minimum_size = Vector2(32, 32)
		act_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		act_icon.mouse_filter = Control.MOUSE_FILTER_PASS
		tracker_hbox.add_child(act_icon)
		action_icons.append(act_icon)
		
	var spacer_tracker = Control.new()
	spacer_tracker.custom_minimum_size = Vector2(10, 0)
	tracker_hbox.add_child(spacer_tracker)
	
	reaction_icon = TextureRect.new()
	reaction_icon.texture = reaction_texture
	reaction_icon.custom_minimum_size = Vector2(32, 32)
	reaction_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reaction_icon.mouse_filter = Control.MOUSE_FILTER_PASS
	tracker_hbox.add_child(reaction_icon)
	
	# --- MIDDLE DIVIDER 2 ---
	var divider2 = ColorRect.new()
	divider2.custom_minimum_size = Vector2(2, 0)
	divider2.color = Color("#a6a6b5")
	divider2.color.a = 0.5
	hbox.add_child(divider2)
	
	# --- RIGHT SIDE: PORTRAIT ---
	portrait = TextureRect.new()
	portrait.texture = preload("res://icon.svg")
	portrait.custom_minimum_size = Vector2(128, 128) # Updated size based on mock
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(portrait)
		
	_apply_position()

func _build_main_menu():
	for child in main_menu_vbox.get_children():
		child.queue_free()
		
	var actions = ["MOVE", "STRIKE", "MAGIC", "ITEM", "ACTIONS"]
	for action_name in actions:
		var btn = _create_styled_button(action_name)
		btn.pressed.connect(func(): _open_submenu(action_name))
		main_menu_vbox.add_child(btn)

func _create_styled_button(text: String) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return btn

func _open_submenu(menu_name: String):
	for child in submenu_vbox.get_children():
		child.queue_free()
		
	var back_btn = _create_styled_button("<- BACK")
	back_btn.add_theme_color_override("font_color", Color("#ffd700"))
	back_btn.pressed.connect(_close_submenu)
	submenu_vbox.add_child(back_btn)
	
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 1)
	divider.color = Color("#555555")
	submenu_vbox.add_child(divider)
	
	# Scroll container for many actions
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	submenu_vbox.add_child(scroll)
	
	var scroll_vbox = VBoxContainer.new()
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scroll_vbox)
	
	if menu_name == "MOVE":
		var stride = _create_styled_button("Stride")
		scroll_vbox.add_child(stride)
		var step = _create_styled_button("Step")
		scroll_vbox.add_child(step)
	elif menu_name == "STRIKE":
		var strike1 = _create_styled_button("Unarmed Strike")
		scroll_vbox.add_child(strike1)
	elif menu_name == "MAGIC":
		var s1 = _create_styled_button("No Spells Prepared")
		scroll_vbox.add_child(s1)
	elif menu_name == "ACTIONS":
		var a1 = _create_styled_button("Grapple")
		scroll_vbox.add_child(a1)
		var a2 = _create_styled_button("Trip")
		scroll_vbox.add_child(a2)
		var a3 = _create_styled_button("Shove")
		scroll_vbox.add_child(a3)
		var a4 = _create_styled_button("Disarm")
		scroll_vbox.add_child(a4)
		var a5 = _create_styled_button("Demoralize")
		scroll_vbox.add_child(a5)
		var a6 = _create_styled_button("Feint")
		scroll_vbox.add_child(a6)
		var a7 = _create_styled_button("Bon Mot")
		scroll_vbox.add_child(a7)
		var a8 = _create_styled_button("Create a Diversion")
		scroll_vbox.add_child(a8)
		var a9 = _create_styled_button("Battle Medicine")
		scroll_vbox.add_child(a9)
		
	main_menu_vbox.hide()
	submenu_vbox.show()

func _close_submenu():
	submenu_vbox.hide()
	main_menu_vbox.show()

func _on_conditions_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Expanded condition view!")

func _apply_position():
	# Clear old margins
	margin_container.remove_theme_constant_override("margin_left")
	margin_container.remove_theme_constant_override("margin_right")
	margin_container.remove_theme_constant_override("margin_top")
	margin_container.remove_theme_constant_override("margin_bottom")
	
	match menu_position:
		MenuPosition.TOP_LEFT:
			margin_container.set_anchors_and_offsets_preset(PRESET_TOP_LEFT)
			margin_container.grow_horizontal = Control.GROW_DIRECTION_END
			margin_container.grow_vertical = Control.GROW_DIRECTION_END
			margin_container.add_theme_constant_override("margin_left", 40)
			margin_container.add_theme_constant_override("margin_top", 40)
		MenuPosition.TOP_RIGHT:
			margin_container.set_anchors_and_offsets_preset(PRESET_TOP_RIGHT)
			margin_container.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			margin_container.grow_vertical = Control.GROW_DIRECTION_END
			margin_container.add_theme_constant_override("margin_right", 40)
			margin_container.add_theme_constant_override("margin_top", 40)
		MenuPosition.BOTTOM_LEFT:
			margin_container.set_anchors_and_offsets_preset(PRESET_BOTTOM_LEFT)
			margin_container.grow_horizontal = Control.GROW_DIRECTION_END
			margin_container.grow_vertical = Control.GROW_DIRECTION_BEGIN
			margin_container.add_theme_constant_override("margin_left", 40)
			margin_container.add_theme_constant_override("margin_bottom", 40)
		MenuPosition.BOTTOM_RIGHT:
			margin_container.set_anchors_and_offsets_preset(PRESET_BOTTOM_RIGHT)
			margin_container.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			margin_container.grow_vertical = Control.GROW_DIRECTION_BEGIN
			margin_container.add_theme_constant_override("margin_right", 40)
			margin_container.add_theme_constant_override("margin_bottom", 40)

func bind_to_actor(actor: PFActor):
	bound_actor = actor
	_update_ui()

func _process(_delta):
	# Continuously poll actor stats so the UI always matches perfectly
	if bound_actor:
		_update_ui()

func _update_ui():
	name_label.text = bound_actor.entity_name
	
	# Dynamically check temp HP
	var temp_hp = 0
	if "temp_hp" in bound_actor.health:
		temp_hp = bound_actor.health.temp_hp
		
	if temp_hp > 0:
		hp_label.text = "%d/%d HP (+%d Temp)" % [bound_actor.health.current_hp, bound_actor.health.max_hp, temp_hp]
	else:
		hp_label.text = "%d/%d HP" % [bound_actor.health.current_hp, bound_actor.health.max_hp]
	
	# Update Action Trackers (Dim them if spent)
	var actions_rem = bound_actor.action_economy.actions_remaining
	for i in range(3):
		if i < actions_rem:
			action_icons[i].modulate = Color.WHITE
			action_icons[i].tooltip_text = "Action (Available)"
		else:
			action_icons[i].modulate = Color(0.3, 0.3, 0.3, 0.5) # Dark Grey, semi-transparent
			action_icons[i].tooltip_text = "Action (Spent)"
			
	var reactions_rem = bound_actor.action_economy.reactions_remaining
	if reactions_rem > 0:
		reaction_icon.modulate = Color.WHITE
		reaction_icon.tooltip_text = "Reaction (Available)"
	else:
		reaction_icon.modulate = Color(0.3, 0.3, 0.3, 0.5)
		reaction_icon.tooltip_text = "Reaction (Spent)"
		
	# Check Portrait
	if "portrait" in bound_actor and bound_actor.portrait != null:
		portrait.texture = bound_actor.portrait
