# pf_action_treat_wounds.gd
class_name PFActionTreatWounds
extends PFAction

func _init():
	# While normally a 10-minute exploration activity, we define it here as a combat action
	# purely for testing and UI demonstration purposes.
	super._init("Treat Wounds", [&"exploration", &"healing", &"manipulate"], PFCombatConstants.ActionCost.FREE, 1)

func execute(user: PFActor, target: Variant = null) -> bool:
	if not target:
		print("    > [ERROR] No target for Treat Wounds!")
		return false
		
	var distance_sq = user.global_position.distance_squared_to(target.global_position)
	if distance_sq > 25.0:
		print("    > [ERROR] Target is not adjacent (%d ft > 5 ft)!" % sqrt(distance_sq))
		return false
		
	# Requires two free hands and healer's tools (simplified check)
	var free_hands = 2
	var inventory = user.get(&"inventory") as PFInventory
	if inventory:
		if inventory.held_main_hand: free_hands -= 1
		if inventory.held_off_hand: free_hands -= 1
		if inventory.two_handed_item: free_hands -= 2
		
	if free_hands < 2:
		print("    > [ERROR] You need two free hands to use Treat Wounds!")
		return false
		
	var immunity_key = StringName("treat_wounds_" + str(target.get_instance_id()))
	if target.has_immunity(immunity_key):
		print("    > %s is recently treated and temporarily immune to further Treat Wounds!" % target.entity_name)
		return false
			
	var base_bonus = user.get_skill_bonus(&"medicine") if user.has_method(&"get_skill_bonus") else 0
	
	var nat_roll = PFDice.roll_d20()
	var roll_total = nat_roll + base_bonus
	
	# Assuming standard DC 15 for Trained Treat Wounds.
	# Real implementation would allow the player to choose DC 15/20/30/40.
	var target_dc = 15 
	
	var degree = PFDice.determine_success(roll_total, target_dc, nat_roll)
	
	print("\n>>> %s spends 10 minutes Treating Wounds on %s!" % [user.entity_name, target.entity_name])
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
			
	# Continual Recovery Feat Check
	# Continual Recovery reduces immunity from 1 hour to 10 minutes.
	# 1 hour = 600 rounds (or 60 minutes)
	# 10 minutes = 100 rounds (or 10 minutes)
	var immunity_duration = 600
	if user.has_passive_feature(&"continual_recovery"):
		print("    > (Continual Recovery: Immunity reduced to 10 minutes!)")
		immunity_duration = 100
		
	target.add_immunity(immunity_key, immunity_duration)
	return true

