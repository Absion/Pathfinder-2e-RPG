# pf_context.gd
## Base class for global game states (combat, exploration, menus).
class_name PFContext
extends Node

# Emitted when this context wants the GameRoot to transition to another context
@warning_ignore("unused_signal")
signal request_context_change(context_name: String, args: Dictionary)

# Global Shared State
static var active_party: Array[PFActor] = []
static var reserve_party: Array[PFActor] = []
static var root_node: Node
static var detection_manager: PFDetectionManager
static var reaction_manager: PFReactionManager
static var environment_manager: PFEnvironmentManager
static var counteract_manager: PFCounteractManager
static var active_turn_manager: PFTurnManager

## Initializes shared static services that persist across both Combat and Overworld contexts
static func init_shared_services() -> void:
	if detection_manager == null:
		detection_manager = PFDetectionManager.new()
		Engine.get_main_loop().root.add_child.call_deferred(detection_manager)
		
	if reaction_manager == null:
		reaction_manager = PFReactionManager.new()
		Engine.get_main_loop().root.add_child.call_deferred(reaction_manager)
		
	if environment_manager == null:
		environment_manager = PFEnvironmentManager.new()
		Engine.get_main_loop().root.add_child.call_deferred(environment_manager)
		
	if counteract_manager == null:
		counteract_manager = PFCounteractManager.new()
		Engine.get_main_loop().root.add_child.call_deferred(counteract_manager)

## Ask the TimeManager to rest the entire party.
static func request_rest(hours: int = 8) -> void:
	var tm = PFTimeManager.get_instance()
	if tm:
		if hours >= 8:
			tm.rest_for_night()
		else:
			tm.advance_hours(hours)
	else:
		print("    > [ERROR] PFTimeManager is not initialized!")

# Lifecycle methods
func build_services() -> void:
	pass

func bind_services() -> void:
	pass

func setup() -> void:
	pass

func enter_context(_args: Dictionary = {}) -> void:
	PFContext.init_shared_services()
	pass

func exit_context() -> void:
	pass
