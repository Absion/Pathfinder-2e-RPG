# pf_game_root.gd
## The absolute top-level node managing global state and context transitions.
class_name PFGameRoot
extends Node

static var _instance_cache: PFGameRoot = null

static func get_instance() -> PFGameRoot:
	if _instance_cache != null and is_instance_valid(_instance_cache):
		return _instance_cache

	var ml = Engine.get_main_loop()
	if ml:
		if ml.root.has_node("PFGameRoot"):
			_instance_cache = ml.root.get_node("PFGameRoot") as PFGameRoot
			return _instance_cache
	return null

var current_context: PFContext = null
var contexts: Dictionary = {}

func _ready():
	_register_contexts()
	# Default to Main Menu, or Combat for testing
	transition_to_context("CombatContext")

func _register_contexts():
	contexts["CombatContext"] = PFCombatContext.new()

func transition_to_context(context_name: String, args: Dictionary = {}):
	if current_context:
		current_context.exit_context()
		remove_child(current_context)
		
	if contexts.has(context_name):
		current_context = contexts[context_name]
		add_child(current_context)
		current_context.enter_context(args)
	else:
		push_error("Context %s not found!" % context_name)

func _on_context_request_change(new_context: String, args: Dictionary):
	transition_to_context(new_context, args)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for context in contexts.values():
			if is_instance_valid(context) and not context.is_inside_tree():
				context.free()
