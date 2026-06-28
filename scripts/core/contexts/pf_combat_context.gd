# pf_combat_context.gd
## Manages the tactical turn-based combat loop and initiative.
class_name PFCombatContext
extends PFContext

var grid_manager: PFCombatGrid
var turn_manager: PFTurnManager
var camera_rig: PFCameraRig
var ui_layer: CanvasLayer
var action_menu: PFActionMenu
var active_hero: PFActor

func build_services() -> void:
	# Instantiate our core combat services
	grid_manager = PFCombatGrid.new()
	grid_manager.name = "GridManager"
	add_child(grid_manager)
	
	# Create Camera Rig
	camera_rig = PFCameraRig.new()
	camera_rig.name = "CameraRig"
	add_child(camera_rig)
	
	# Create Turn Manager
	turn_manager = PFTurnManager.new()
	turn_manager.name = "TurnManager"
	add_child(turn_manager)
	PFContext.active_turn_manager = turn_manager
	
	# Create a CanvasLayer strictly for combat UI
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	add_child(ui_layer)
	
	action_menu = PFActionMenu.new()
	ui_layer.add_child(action_menu)

func bind_services() -> void:
	turn_manager.turn_started.connect(func(actor: PFActor):
		if active_hero and (actor == active_hero or (actor is PFMinion and actor.master == active_hero)):
			action_menu.bind_to_actor(actor)
	)

func setup() -> void:
	print("Combat Context Setup Complete!")
	grid_manager.draw_base_grid(50, 50)

func enter_context(args: Dictionary = {}) -> void:
	print("Entering Combat Context...")
	build_services()
	bind_services()
	
	if args.has(&"hero"):
		active_hero = args["hero"]
		action_menu.bind_to_actor(active_hero)
		
	if args.has(&"player_mesh"):
		camera_rig.tracked_target = args["player_mesh"]
		camera_rig.focus_on_position(args["player_mesh"].global_position, true)
		
	setup()

func exit_context() -> void:
	print("Exiting Combat Context...")
	PFContext.active_turn_manager = null
	# Clean up logic
	for child in get_children():
		child.queue_free()
