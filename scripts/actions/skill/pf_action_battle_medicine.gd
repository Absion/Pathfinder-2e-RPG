# pf_action_battle_medicine.gd
class_name PFActionBattleMedicine
extends PFAction

func _init():
	super._init("Battle Medicine", [&"healing", &"manipulate"], PFCombatConstants.ActionCost.ONE_ACTION, 1)

func execute(user: PFActor, target: Variant = null) -> bool:
	if not target:
		print("    > [ERROR] No target for Battle Medicine!")
		return false
		
	var distance_sq = user.global_position.distance_squared_to(target.global_position)
	if distance_sq > 25.0:
		print("    > [ERROR] Target is not adjacent (%d ft > 5 ft)!" % sqrt(distance_sq))
		return false
		
	# Requires a free hand (simplified check)
	var free_hands = 2
	var inventory = user.get(&"inventory") as PFInventory
	if inventory:
		if inventory.held_main_hand: free_hands -= 1
		if inventory.held_off_hand: free_hands -= 1
		if inventory.two_handed_item: free_hands -= 2
		
	if free_hands <= 0:
		print("    > [ERROR] You need at least one free hand to use Battle Medicine!")
		return false
		
	var immunity_key = StringName("battle_medicine_" + str(user.get_instance_id()))
	if target.has_immunity(immunity_key):
		print("    > %s is immune to %s's Battle Medicine for today!" % [target.entity_name, user.entity_name])
		return false
			
	var base_bonus = user.get_skill_bonus(&"medicine") if user.has_method(&"get_skill_bonus") else 0
	
	var nat_roll = PFDice.roll_d20()
	var roll_total = nat_roll + base_bonus
	
	# Assuming standard DC 15 for Trained Battle Medicine
	var target_dc = 15 
	
	var degree = PFDice.determine_success(roll_total, target_dc, nat_roll)
	
	print("\n>>> %s uses Battle Medicine on %s!" % [user.entity_name, target.entity_name])
	print("    Medicine Roll: %d + Bonus: %d = Total: %d vs DC %d" % [nat_roll, base_bonus, roll_total, target_dc])
	
	match degree:
		PFMathConstants.DegreeOfSuccess.CRIT_SUCCESS:
			var heal_amt = PFDice.roll(4, 8).total
			print("    *** CRITICAL SUCCESS! ***")
			print("    > Healed for %d HP!" % heal_amt)
			target.health.heal(heal_amt)
		PFMathConstants.DegreeOfSuccess.SUCCESS:
			var heal_amt = PFDice.roll(2, 8).total
			print("    * SUCCESS! *")
			print("    > Healed for %d HP!" % heal_amt)
			target.health.heal(heal_amt)
		PFMathConstants.DegreeOfSuccess.FAIL:
			print("    You fail to dress the wound properly. No HP is recovered.")
		PFMathConstants.DegreeOfSuccess.CRIT_FAIL:
			var dmg_amt = PFDice.roll(1, 8).total
			print("    [CRITICAL FAILURE]")
			print("    > You accidentally aggravate the wound, dealing %d damage!" % dmg_amt)
			target.health.take_damage(dmg_amt, PFCombatConstants.DamageType.UNTYPED)
			
	# Target is immune for 1 day (14400 rounds)
	target.add_immunity(immunity_key, 14400)
	return true

