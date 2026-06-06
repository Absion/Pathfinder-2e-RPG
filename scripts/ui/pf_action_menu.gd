# pf_action_menu.gd
## The dynamic programmatic UI for selecting combat actions.
class_name PFActionMenu
extends Control

enum MenuPosition { TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT }
@export var menu_position: MenuPosition = MenuPosition.BOTTOM_RIGHT

var bound_actor: PFActor = null

# UI Elements
var name_label: Label
var level_label: Label
var hp_bar: ProgressBar
var hp_label: Label
var action_diamonds_label: Label
var margin_container: MarginContainer

func _ready():
	# Make the root control span the entire CanvasLayer without blocking mouse clicks
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	margin_container = MarginContainer.new()
	add_child(margin_container)
	
	var main_panel = PanelContainer.new()
	margin_container.add_child(main_panel)
	
	# Theme / StyleBox for the Main Panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#1a1a2e") # Dark Navy Blue
	style.bg_color.a = 0.95
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color("#a6a6b5") # Silver Border
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	main_panel.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 30)
	main_panel.add_child(hbox)
	
	# --- LEFT SIDE: CHARACTER INFO ---
	var left_vbox = VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(250, 0)
	left_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(left_vbox)
	
	var top_hbox = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 15)
	left_vbox.add_child(top_hbox)
	
	var portrait = TextureRect.new()
	portrait.texture = preload("res://icon.svg")
	portrait.custom_minimum_size = Vector2(64, 64)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	top_hbox.add_child(portrait)
	
	var name_vbox = VBoxContainer.new()
	name_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hbox.add_child(name_vbox)
	
	name_label = Label.new()
	name_label.text = "CHARACTER NAME"
	name_label.add_theme_font_size_override("font_size", 20)
	name_vbox.add_child(name_label)
	
	level_label = Label.new()
	level_label.text = "Lvl 1"
	level_label.add_theme_font_size_override("font_size", 14)
	level_label.add_theme_color_override("font_color", Color("#a6a6b5"))
	name_vbox.add_child(level_label)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	left_vbox.add_child(spacer)
	
	# HP Bar
	var hp_hbox = HBoxContainer.new()
	left_vbox.add_child(hp_hbox)
	
	var hp_title = Label.new()
	hp_title.text = "HP"
	hp_title.custom_minimum_size = Vector2(40, 0)
	hp_hbox.add_child(hp_title)
	
	hp_bar = ProgressBar.new()
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_bar.custom_minimum_size = Vector2(0, 16)
	hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hp_bar.show_percentage = false
	var hp_bg = StyleBoxFlat.new()
	hp_bg.bg_color = Color("#111111")
	var hp_fill = StyleBoxFlat.new()
	hp_fill.bg_color = Color("#2e8b57") # Forest Green
	hp_bar.add_theme_stylebox_override("background", hp_bg)
	hp_bar.add_theme_stylebox_override("fill", hp_fill)
	hp_hbox.add_child(hp_bar)
	
	hp_label = Label.new()
	hp_label.text = "0/0"
	hp_label.custom_minimum_size = Vector2(60, 0)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_hbox.add_child(hp_label)
	
	# Actions
	var action_hbox = HBoxContainer.new()
	left_vbox.add_child(action_hbox)
	
	var action_title = Label.new()
	action_title.text = "ACT"
	action_title.custom_minimum_size = Vector2(40, 0)
	action_hbox.add_child(action_title)
	
	action_diamonds_label = Label.new()
	action_diamonds_label.text = "♦ ♦ ♦"
	action_diamonds_label.add_theme_color_override("font_color", Color("#ffd700")) # Gold
	action_diamonds_label.add_theme_font_size_override("font_size", 20)
	action_hbox.add_child(action_diamonds_label)
	
	# --- MIDDLE DIVIDER ---
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(2, 0)
	divider.color = Color("#a6a6b5")
	divider.color.a = 0.5
	hbox.add_child(divider)
	
	# --- RIGHT SIDE: ACTIONS ---
	var right_vbox = VBoxContainer.new()
	right_vbox.custom_minimum_size = Vector2(150, 0)
	right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(right_vbox)
	
	var actions = ["MOVE", "STRIKE", "SPELLS", "INTERACT", "END TURN"]
	for action_name in actions:
		var btn = Button.new()
		btn.text = action_name
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# Button Styling
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color.TRANSPARENT
		normal_style.content_margin_left = 10
		normal_style.content_margin_top = 5
		normal_style.content_margin_bottom = 5
		
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color("#ffffff")
		hover_style.bg_color.a = 0.15
		hover_style.content_margin_left = 10
		hover_style.content_margin_top = 5
		hover_style.content_margin_bottom = 5
		
		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_stylebox_override("pressed", hover_style)
		btn.add_theme_stylebox_override("focus", normal_style)
		
		right_vbox.add_child(btn)
		
	_apply_position()

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
	name_label.text = bound_actor.entity_name.to_upper()
	
	if bound_actor.sheet:
		level_label.text = "Lvl %d" % bound_actor.level
	else:
		level_label.text = "Lvl ?"
	
	hp_bar.max_value = bound_actor.health.max_hp
	hp_bar.value = bound_actor.health.current_hp
	hp_label.text = "%d/%d" % [bound_actor.health.current_hp, bound_actor.health.max_hp]
	
	var diamonds = ""
	for i in range(bound_actor.action_economy.actions_remaining):
		diamonds += "♦ "
	for i in range(3 - bound_actor.action_economy.actions_remaining):
		diamonds += "♢ "
		
	action_diamonds_label.text = diamonds.strip_edges()
