# pf_action_fall.gd
## An environmental/forced action representing an actor falling.
class_name PFActionFall
extends PFAction

var distance: int
var has_edge: bool
var edge_dc: int

func _init(p_distance: int, p_has_edge: bool = false, p_edge_dc: int = 15):
	# Falling doesn't cost an action natively, it's forced.
	super._init("Fall", [&"move"], PFCombatConstants.ActionCost.NONE)
	distance = p_distance
	has_edge = p_has_edge
	edge_dc = p_edge_dc

func execute(user: PFActor, _target: PFActor = null) -> bool:
	print("    > %s is falling %d feet!" % [user.entity_name, distance])
	
	var event_data = {
		"trigger_type": PFCombatConstants.ReactionTriggers.ON_FALL,
		"falling_actor": user,
		"distance": distance,
		"has_edge": has_edge,
		"edge_dc": edge_dc,
		"fall_halted": false,
		"fall_damage_multiplier": 1.0,
		"distance_fallen_so_far": distance / 2 # Simulating they fall past an edge halfway down
	}
	
	if PFContext.reaction_manager:
		event_data = await PFContext.reaction_manager.notify_event(PFCombatConstants.ReactionTriggers.ON_FALL, user, event_data)
		
	if event_data.get("fall_halted", false):
		var fall_dist = event_data.get("distance_fallen_so_far", 0)
		print("    > %s's fall was halted after falling %d feet!" % [user.entity_name, fall_dist])
		var dmg_mult = event_data.get("fall_damage_multiplier", 1.0)
		_apply_fall_damage(user, fall_dist, dmg_mult)
	else:
		print("    > %s hits the ground!" % user.entity_name)
		_apply_fall_damage(user, distance, 1.0)
		user.apply_condition(PFCondition.create(&"prone"))
		
	return true

func _apply_fall_damage(user: PFActor, dist: int, multiplier: float) -> void:
	if dist < 5 or multiplier <= 0.0:
		return
	
	# PF2e Fall Damage: Bludgeoning damage equal to half the distance fallen.
	var dmg = floori(dist / 2.0) * multiplier
	if dmg > 0:
		print("    > %s takes %d bludgeoning damage from the fall." % [user.entity_name, dmg])
		user.take_damage(dmg, PFCombatConstants.DamageType.BLUDGEONING)
