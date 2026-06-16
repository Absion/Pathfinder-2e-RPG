# pf_action_maneuver.gd
## Base class for athletic maneuvers like Grapple, Shove, Trip, and Disarm
class_name PFActionManeuver
extends PFAction

enum ManeuverType {
	GRAPPLE,
	SHOVE,
	TRIP,
	DISARM
}

var maneuver_type: ManeuverType
var weapon: PFWeapon

func _init(p_type: ManeuverType, p_weapon: PFWeapon = null):
	maneuver_type = p_type
	weapon = p_weapon
	
	var initial_traits: Array[StringName] = [&"attack"]
	var type_name = ManeuverType.keys()[p_type].to_lower().capitalize()
	super._init(type_name, initial_traits, PFCombatConstants.ActionCost.ONE_ACTION, 1)

func execute(user: PFActor, target: PFActor = null) -> bool:
	if not target:
		print("    > [ERROR] No target for maneuver!")
		return false
		
	# Distance check
	var dist_ft = user.global_position.distance_to(target.global_position)
	var reach = 5
	var maneuver_trait = ManeuverType.keys()[maneuver_type].to_lower()
	
	if weapon and weapon.has_trait(StringName(maneuver_trait)):
		for t in weapon.traits:
			var ts = String(t)
			if ts == "reach":
				reach = 10
			elif ts.begins_with("reach "):
				var parts = ts.split(" ")
				if parts.size() > 1 and parts[1].is_valid_int():
					reach = parts[1].to_int()
					
	if dist_ft > reach:
		print("    > [ERROR] Target is out of reach (%d ft > %d ft)!" % [dist_ft, reach])
		return false

	var base_bonus = 0
	if user.has_method("get_maneuver_bonus"):
		base_bonus = user.get_maneuver_bonus(StringName(maneuver_trait), weapon)
	else:
		# Fallback if method doesn't exist
		var inv = user.get("inventory") as PFInventory
		var free_hands = 2
		if inv:
			if inv.held_main_hand: free_hands -= 1
			if inv.held_off_hand: free_hands -= 1
			if inv.two_handed_item: free_hands -= 2
			
		if free_hands <= 0 and not (weapon and weapon.has_trait(StringName(maneuver_trait))):
			print("    > [ERROR] You need at least one free hand to %s!" % maneuver_trait)
			return false
			
		base_bonus = user.get_skill_bonus(&"athletics") if user.has_method("get_skill_bonus") else 0

	var map_penalty = mini(user.action_economy.attack_stacks, 2) * -5
	var total_bonus = base_bonus + map_penalty
	
	var nat_roll = PFDice.roll_d20()
	var roll_total = nat_roll + total_bonus
	
	var target_dc = 10
	if maneuver_type == ManeuverType.GRAPPLE or maneuver_type == ManeuverType.SHOVE:
		if target.get("attributes"):
			target_dc = 10 + target.attributes.fort_save.get_total()
	elif maneuver_type == ManeuverType.TRIP or maneuver_type == ManeuverType.DISARM:
		if target.get("attributes"):
			target_dc = 10 + target.attributes.ref_save.get_total()
			
	var degree = PFDice.determine_success(roll_total, target_dc, nat_roll)
	
	print("\n>>> %s attempts to %s %s!" % [user.entity_name, maneuver_trait, target.entity_name])
	print("    Athletics Roll: %d + Bonus: %d + MAP: %d = Total: %d vs DC %d" % [nat_roll, base_bonus, map_penalty, roll_total, target_dc])
	
	match degree:
		PFMathConstants.DegreeOfSuccess.CRIT_SUCCESS:
			print("    *** CRITICAL SUCCESS! ***")
			_apply_effect(target, true)
		PFMathConstants.DegreeOfSuccess.SUCCESS:
			print("    * SUCCESS! *")
			_apply_effect(target, false)
		PFMathConstants.DegreeOfSuccess.FAIL:
			print("    Miss.")
		PFMathConstants.DegreeOfSuccess.CRIT_FAIL:
			print("    [CRITICAL FAILURE]")
			if maneuver_type == ManeuverType.TRIP:
				print("    > %s loses balance and falls prone!" % user.entity_name)
				user.conditions.append(PFCondition.create(&"prone"))
			elif maneuver_type == ManeuverType.DISARM:
				print("    > %s fumbles and falls off-balance." % user.entity_name)
				user.conditions.append(PFCondition.create(&"off_guard"))

	return true

func _apply_effect(target: PFActor, is_crit: bool) -> void:
	match maneuver_type:
		ManeuverType.GRAPPLE:
			if is_crit:
				print("    > Target is Restrained!")
				target.conditions.append(PFCondition.create(&"restrained"))
			else:
				print("    > Target is Grabbed!")
				target.conditions.append(PFCondition.create(&"grabbed"))
		ManeuverType.SHOVE:
			var dist = 10 if is_crit else 5
			print("    > Target is pushed back %d feet!" % dist)
		ManeuverType.TRIP:
			print("    > Target falls Prone!")
			target.conditions.append(PFCondition.create(&"prone"))
			if is_crit:
				print("    > Target takes 1d6 bludgeoning damage!")
				target.take_damage(PFDice.roll(1, 6).total, PFCombatConstants.DamageType.BLUDGEONING)
		ManeuverType.DISARM:
			if is_crit:
				print("    > Target drops their weapon!")
			else:
				print("    > Target's grip is weakened (-2 circumstance penalty to attacks with the weapon until start of their next turn).")
