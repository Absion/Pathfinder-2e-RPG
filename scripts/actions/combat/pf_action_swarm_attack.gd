# pf_action_swarm_attack.gd
## Damages all enemies sharing the swarm's space. Requires a basic Reflex save.
class_name PFActionSwarmAttack
extends PFAction

var damage_amount: int
var damage_type: PFCombatConstants.DamageType
var save_dc: int

func _init(p_name: String, p_damage: int, p_type: PFCombatConstants.DamageType, p_dc: int, p_cost: PFCombatConstants.ActionCost = PFCombatConstants.ActionCost.ONE_ACTION):
	super._init(p_name, [&"attack"], p_cost)
	damage_amount = p_damage
	damage_type = p_type
	save_dc = p_dc
	
func execute(user: PFActor, _target: Variant = null):
	print("%s unleashes a Swarm Attack! (DC %d Reflex)" % [user.entity_name, save_dc])
	
	if not PFContext.active_turn_manager:
		return false
		
	var enemies = PFContext.active_turn_manager.get_enemies(user)
	var targets_hit = 0
	
	for enemy in enemies:
		# Swarms deal damage to enemies IN their space.
		var distance = PFCombatGrid.get_distance_pf2e(user.global_position, enemy.global_position)
		
		# If the distance is 0, they share a space. 
		# (We could also allow distance <= 5 if the swarm is large and occupies multiple tiles)
		var max_range = 0
		if user.size_id == &"large": max_range = 5
		elif user.size_id == &"huge": max_range = 10
		elif user.size_id == &"gargantuan": max_range = 15
		
		if distance <= max_range:
			targets_hit += 1
			_apply_swarm_damage(user, enemy)
			
	if targets_hit == 0:
		print("    > Nobody was in the swarm's space!")
		
	return true

func _apply_swarm_damage(_user: PFActor, enemy: PFActor):
	var save_mod = enemy.get_save_bonus(&"reflex")
	var roll = randi() % 20 + 1
	var total = roll + save_mod
	
	var degree = PFMathConstants.DegreeOfSuccess.FAIL
	if total >= save_dc + 10 or roll == 20: degree = PFMathConstants.DegreeOfSuccess.CRIT_SUCCESS
	elif total >= save_dc: degree = PFMathConstants.DegreeOfSuccess.SUCCESS
	elif total <= save_dc - 10 or roll == 1: degree = PFMathConstants.DegreeOfSuccess.CRIT_FAIL
	
	if roll == 20 and degree < PFMathConstants.DegreeOfSuccess.CRIT_SUCCESS: degree = (degree + 1) as PFMathConstants.DegreeOfSuccess
	elif roll == 1 and degree > PFMathConstants.DegreeOfSuccess.CRIT_FAIL: degree = (degree - 1) as PFMathConstants.DegreeOfSuccess
	
	print("    > %s rolled %d for Reflex Save (Total: %d vs DC %d) -> %s" % [enemy.entity_name, roll, total, save_dc, PFMathConstants.DegreeOfSuccess.keys()[degree]])
	
	var final_damage = damage_amount
	match degree:
		PFMathConstants.DegreeOfSuccess.CRIT_SUCCESS: final_damage = 0
		PFMathConstants.DegreeOfSuccess.SUCCESS: final_damage = floor(final_damage / 2.0)
		PFMathConstants.DegreeOfSuccess.CRIT_FAIL: final_damage *= 2
		
	if final_damage > 0:
		print("    > %s takes %d %s damage from the swarm!" % [enemy.entity_name, final_damage, PFCombatConstants.DamageType.keys()[damage_type]])
		enemy.take_damage(final_damage, damage_type, [&"area"]) # Swarm attacks are usually not 'area' effects themselves unless stated, but they do area damage.
	else:
		print("    > %s evades the swarm entirely!" % enemy.entity_name)
