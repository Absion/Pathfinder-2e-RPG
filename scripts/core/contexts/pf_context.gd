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
static var condition_manager: PFConditionManager
static var active_turn_manager: PFTurnManager

## Initializes shared static services that persist across both Combat and Overworld contexts
static func init_shared_services() -> void:
	if detection_manager == null:
		detection_manager = PFDetectionManager.new()
		Engine.get_main_loop().root.add_child(detection_manager)
		
	if reaction_manager == null:
		reaction_manager = PFReactionManager.new()
		Engine.get_main_loop().root.add_child(reaction_manager)
		
	if environment_manager == null:
		environment_manager = PFEnvironmentManager.new()
		Engine.get_main_loop().root.add_child(environment_manager)
		
	if counteract_manager == null:
		counteract_manager = PFCounteractManager.new()
		Engine.get_main_loop().root.add_child(counteract_manager)
		
	if condition_manager == null:
		condition_manager = PFConditionManager.new()
		Engine.get_main_loop().root.add_child(condition_manager)

## Cleans up shared services to prevent state leakage between tests.
static func cleanup_shared_services() -> void:
	if is_instance_valid(detection_manager):
		if detection_manager.is_inside_tree():
			detection_manager.get_parent().remove_child(detection_manager)
		detection_manager.free()
	detection_manager = null
	
	if is_instance_valid(reaction_manager):
		if reaction_manager.is_inside_tree():
			reaction_manager.get_parent().remove_child(reaction_manager)
		reaction_manager.free()
	reaction_manager = null
	
	if is_instance_valid(environment_manager):
		if environment_manager.is_inside_tree():
			environment_manager.get_parent().remove_child(environment_manager)
		environment_manager.free()
	environment_manager = null
	
	if is_instance_valid(counteract_manager):
		if counteract_manager.is_inside_tree():
			counteract_manager.get_parent().remove_child(counteract_manager)
		counteract_manager.free()
	counteract_manager = null
	
	if is_instance_valid(condition_manager):
		if condition_manager.is_inside_tree():
			condition_manager.get_parent().remove_child(condition_manager)
		condition_manager.free()
	condition_manager = null
	
	active_party.clear()
	reserve_party.clear()
	active_turn_manager = null

## Ask the TimeManager to rest the entire party.
static func request_rest(hours: int = 8) -> void:
	var time_manager = PFTimeManager.get_instance()
	if time_manager:
		if hours >= 8:
			time_manager.rest_for_night()
		else:
			time_manager.advance_hours(hours)
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

