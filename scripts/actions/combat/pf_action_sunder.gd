# pf_action_sunder.gd
## A custom or specialized action to strike and damage an opponent's held item.
class_name PFActionSunder
extends PFAction

var weapon: PFWeapon

func _init(p_weapon: PFWeapon):
	super._init("Sunder", [&"attack"], PFCombatConstants.ActionCost.ONE_ACTION)
	weapon = p_weapon

func is_usable(_user: PFActor) -> bool:
	if weapon == null:
		print("    > Must have a weapon to Sunder.")
		return false
	return true

func execute(user: PFActor, target: PFActor = null) -> Variant:
	if not target:
		print("    > Sunder requires a target!")
		return false
		
	if not target.inventory or (target.inventory.held_main_hand == null and target.inventory.held_off_hand == null and target.inventory.worn_items.is_empty()):
		print("    > Target has no items to sunder!")
		return false
		
	if await check_trait_triggers(user):
		return false # Disrupted
		
	# Increase MAP
	var map_penalty = user.action_economy.get_map_penalty(weapon)
	user.action_economy.increment_map()
	
	# Roll Attack vs Target Reflex DC
	var DiceMath = load("res://scripts/core/math/pf_dice_math.gd")
	var CombatMath = load("res://scripts/combat/pf_combat_math.gd")
	
	var atk_bonus = user.get_strike_bonus(weapon)
	var atk_roll = DiceMath.roll(20, 1)
	var total_atk = atk_roll + atk_bonus + map_penalty
	
	var target_dc = target.get_save_bonus(&"reflex") + 10
	var degree = CombatMath.get_degree_of_success(atk_roll, total_atk, target_dc)
	
	print("%s attempts to Sunder %s's item using %s! Roll: %d + %d + %d = %d vs Ref DC %d" % [
		user.entity_name, target.entity_name, weapon.entity_name,
		atk_roll, atk_bonus, map_penalty, total_atk, target_dc
	])
	
	if degree >= PFCombatConstants.DegreeOfSuccess.SUCCESS:
		var dmg_roll = DiceMath.roll(weapon.die_faces, weapon.damage_dice)
		var dmg_bonus = user.get_strike_damage_bonus(weapon)
		var total_dmg = dmg_roll + dmg_bonus
		
		# Crit doubles damage
		if degree == PFCombatConstants.DegreeOfSuccess.CRITICAL_SUCCESS:
			total_dmg *= 2
			
		# Find an item to damage. Prioritize shields, then weapons, then random worn items
		var target_item: PFItem = null
		if target.has_raised_shield and target.inventory.held_off_hand is PFShield:
			target_item = target.inventory.held_off_hand
		elif target.inventory.held_main_hand:
			target_item = target.inventory.held_main_hand
		elif target.inventory.worn_items.size() > 0:
			target_item = target.inventory.worn_items[0]
			
		if target_item:
			print("    > Sunder %s! Deals %d damage to %s." % [
				PFCombatConstants.DegreeOfSuccess.keys()[degree], total_dmg, target_item.entity_name
			])
			target_item.take_damage(total_dmg, weapon.damage_type, user)
		else:
			print("    > Failed to find a valid item to Sunder!")
	else:
		print("    > Sunder missed!")
		
	return true
