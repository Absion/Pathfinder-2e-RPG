# pf_action_strike.gd
# The core attack action for the engine.
class_name PFActionStrike
extends PFAction

var weapon: PFWeapon

func _init(p_weapon: PFWeapon):
	var initial_traits: Array[StringName] = [&"attack"]
	initial_traits.append_array(p_weapon.traits)
	
	weapon = p_weapon
	super._init("Strike with " + p_weapon.entity_name, initial_traits, CostType.ONE, 1)

func execute(user: PFActor, target: PFActor = null) -> bool:
	if target == null:
		print("Strike failed: No target.")
		return false
		
	# ---------------------------------------------------------
	# 1. CALCULATE ATTACK BONUS & MAP
	# ---------------------------------------------------------
	
	var base_attack_bonus = user.get_strike_bonus(weapon)
	var map_penalty = mini(user.attack_stacks, 2) * (-4 if has_trait(&"agile") else -5)
	var total_attack_bonus = base_attack_bonus + map_penalty 
	
	# ---------------------------------------------------------
	# 2. ROLL TO HIT
	# ---------------------------------------------------------
	
	var nat_roll = PFDice.roll_d20()
	var roll_total = nat_roll + total_attack_bonus
	var target_ac = target.get_ac()
	var degree = PFDice.determine_success(roll_total, target_ac, nat_roll)
	
	var roll_string = ""
	if nat_roll == 20:
		roll_string = "20 (Natural 20)"
	elif nat_roll == 1:
		roll_string = "1 (Natural 1)"
	else:
		roll_string = "%d (1d20)" % nat_roll
	
	print("\n>>> %s attacks %s with %s!" % [user.entity_name, target.entity_name, weapon.entity_name])
	print("    Attack Roll: %s + Bonus: %d + MAP: %d = Total: %d vs AC %d" % [roll_string, base_attack_bonus, map_penalty, roll_total, target_ac])
	
	if degree == PFDice.Degree.FAIL or degree == PFDice.Degree.CRIT_FAIL:
		print("    Miss.")
		return true

	# ---------------------------------------------------------
	# 3. ADVANCED DAMAGE RESOLUTION
	# ---------------------------------------------------------
	
	var final_damage_type = weapon.active_damage_type
	if has_trait(&"concussive") and final_damage_type == PFDamage.Type.PIERCING:
		var resists_p = target.resistances.has(PFDamage.Type.PIERCING) or target.immunities.has(PFDamage.Type.PIERCING)
		var weak_b = target.weaknesses.has(PFDamage.Type.BLUDGEONING)
		
		if resists_p or weak_b:
			final_damage_type = PFDamage.Type.BLUDGEONING
			print("    > Concussive Trait triggers: Projectile shatters, dealing Bludgeoning instead!")

	var current_die_faces = weapon.die_faces
	if degree == PFDice.Degree.CRIT_SUCCESS and weapon.fatal_die > 0:
		current_die_faces = weapon.fatal_die
		print("    > Fatal Trait triggers: Base die upgraded to d%d!" % weapon.fatal_die)

	var damage_result = PFDice.roll(weapon.dice_amount, current_die_faces)
	var damage_stat = user.get_strike_damage_bonus(weapon)
	
	var base_total = damage_result.total + damage_stat
	var dice_str = str(damage_result.faces)

	# ---------------------------------------------------------
	# 4. APPLY MULTIPLIERS & EXTRA DICE
	# ---------------------------------------------------------
	if degree == PFDice.Degree.CRIT_SUCCESS:
		print("    *** CRITICAL HIT! ***")
		print("    Base Rolled: %sd%d %s = %d + %d = %d Base Damage" % [weapon.dice_amount, current_die_faces, dice_str, damage_result.total, damage_stat, base_total])
		
		var crit_damage = base_total * 2
		print("    Base Crit Damage: (%d Base) x 2 = %d" % [base_total, crit_damage])
		
		if weapon.fatal_die > 0:
			var extra_fatal = PFDice.roll(1, weapon.fatal_die).total
			crit_damage += extra_fatal
			print("    > +Fatal Die (1d%d): %d" % [weapon.fatal_die, extra_fatal])
			
		if weapon.deadly_die > 0:
			var extra_deadly = PFDice.roll(1, weapon.deadly_die).total
			crit_damage += extra_deadly
			print("    > +Deadly Die (1d%d): %d" % [weapon.deadly_die, extra_deadly])
			
		# Send final damage to the target, passing the weapon traits for Sanctification/Material checks!
		target.take_damage(crit_damage, final_damage_type, weapon.traits)
		
	elif degree == PFDice.Degree.SUCCESS:
		print("    * HIT! *")
		print("    Damage Rolled: %sd%d %s = %d + %d = %d Total Damage." % [weapon.dice_amount, current_die_faces, dice_str, damage_result.total, damage_stat, base_total])
		
		# Send final damage to the target, passing the weapon traits!
		target.take_damage(base_total, final_damage_type, weapon.traits)
			
	return true
