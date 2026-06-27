# pf_action_stride.gd
## Standard movement action up to the actor's speed.
class_name PFActionStride
extends PFAction

func _init():
	# A Stride costs 1 action and has the "move" trait.
	super._init("Stride", [&"move"], PFCombatConstants.ActionCost.ONE_ACTION)

func execute(user: PFActor, _target: Variant = null):
	# In a real game, this would interface with your grid movement system.
	if PFContext.reaction_manager:
		await PFContext.reaction_manager.notify_event(PFCombatConstants.ReactionTriggers.ON_LEAVE_SQUARE, user, {
			"trigger_type": PFCombatConstants.ReactionTriggers.ON_LEAVE_SQUARE,
			"from_position": user.global_position
		})
		
	var terrain_multiplier = 1.0
	if PFContext.environment_manager:
		if PFContext.environment_manager.current_terrain == PFEnvironmentConstants.TerrainType.DIFFICULT:
			terrain_multiplier = 2.0
		elif PFContext.environment_manager.current_terrain == PFEnvironmentConstants.TerrainType.GREATER_DIFFICULT:
			terrain_multiplier = 3.0
			
	if terrain_multiplier > 1.0:
		print("%s moves to a new location. (Terrain Multiplier: x%.1f)" % [user.entity_name, terrain_multiplier])
	else:
		print("%s moves to a new location." % user.entity_name)
	return true
