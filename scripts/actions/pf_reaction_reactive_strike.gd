# pf_reaction_reactive_strike.gd
class_name PFReactionReactiveStrike
extends RefCounted

static func condition(listener: PFActor, trigger_actor: PFActor, event_data: Dictionary) -> bool:
	if trigger_actor == listener:
		return false
		
	# Determine if listener has a melee weapon
	var weapon = PFWeapon.new("Fist", [&"agile", &"finesse", &"nonlethal", &"unarmed"], 1, 0, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.UNARMED, PFEquipmentConstants.WeaponGroup.BRAWLING, 1, 4, PFCombatConstants.DamageType.BLUDGEONING)
	var inv = listener.get(&"inventory") as PFInventory
	if inv and inv.held_main_hand and inv.held_main_hand is PFWeapon and inv.held_main_hand.weapon_type == PFEquipmentConstants.WeaponType.MELEE:
		weapon = inv.held_main_hand
	
	var reach = 5
	for t in weapon.traits:
		var ts = String(t)
		if ts == "reach":
			reach = 10
		elif ts.begins_with("reach "):
			var parts = ts.split(" ")
			if parts.size() > 1 and parts[1].is_valid_int():
				reach = parts[1].to_int()
				
	# If the trigger is ON_LEAVE_SQUARE, we check the distance to the square they left
	if event_data.has(&"trigger_type") and event_data["trigger_type"] == PFCombatConstants.ReactionTriggers.ON_LEAVE_SQUARE:
		var from_pos = event_data.get(&"from_position", trigger_actor.global_position)
		var dist_ft = listener.global_position.distance_to(from_pos)
		if dist_ft > reach:
			return false
	else:
		# Check reach to their current position
		var dist_ft = listener.global_position.distance_to(trigger_actor.global_position)
		if dist_ft > reach:
			return false
		
	return true

static func execute(listener: PFActor, trigger_actor: PFActor, event_data: Dictionary) -> Dictionary:
	print("    > [REACTION] %s uses Reactive Strike against %s!" % [listener.entity_name, trigger_actor.entity_name])
	
	# Reactive Strike is a free Strike action that doesn't increase MAP.
	var weapon = PFWeapon.new("Fist", [&"agile", &"finesse", &"nonlethal", &"unarmed"], 1, 0, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.UNARMED, PFEquipmentConstants.WeaponGroup.BRAWLING, 1, 4, PFCombatConstants.DamageType.BLUDGEONING)
	var inv = listener.get(&"inventory") as PFInventory
	if inv and inv.held_main_hand and inv.held_main_hand is PFWeapon:
		weapon = inv.held_main_hand
		
	var strike_action = PFActionStrike.new(weapon)
	
	# Store the current MAP
	var current_map = listener.action_economy.attack_stacks
	
	# Force MAP to 0 for this strike
	listener.action_economy.attack_stacks = 0
	
	# In a real async flow, we await this
	await strike_action.execute(listener, trigger_actor)
	
	# Restore MAP
	listener.action_economy.attack_stacks = current_map
	
	# Event data is unchanged
	return event_data
