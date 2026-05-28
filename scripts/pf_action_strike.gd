# pf_action_strike.gd
# A standard attack action. Uses a PFWeapon to determine the math, stats, 
# and damage logic (including advanced traits like Fatal and Concussive).
class_name PFActionStrike
extends PFAction

var weapon: PFWeapon

# Constructor
func _init(p_weapon: PFWeapon):
	# All strikes start with the "attack" trait
	var initial_traits: Array[StringName] = [&"attack"]
	
	# We dynamically pull all the traits from the weapon itself!
	# This ensures if the weapon is agile, the Strike becomes agile.
	initial_traits.append_array(p_weapon.traits)
	
	weapon = p_weapon
	
	# Costs ONE action, and generates 1 MAP stack upon completion
	super._init("Strike with " + p_weapon.entity_name, initial_traits, CostType.ONE, 1)

# Executes the strike logic against a target
func execute(user: PFActor, target: PFActor = null) -> bool:
	if target == null:
		print("Strike failed: No target.")
		return false
		
	# ---------------------------------------------------------
	# 1. ATTACK STAT DETERMINATION
	# ---------------------------------------------------------
	var str_mod = user.get_modifier(&"STR")
	var dex_mod = user.get_modifier(&"DEX")
	var attack_stat: int
	
	if weapon.weapon_type == PFWeapon.WeaponType.RANGED:
		# Ranged weapons always use Dexterity to hit
		attack_stat = dex_mod 
	else:
		# Melee weapons default to Strength
		attack_stat = str_mod
		# Finesse override: Use DEX instead if it is higher than STR
		if has_trait(&"finesse") and dex_mod > str_mod:
			attack_stat = dex_mod
			
	# ---------------------------------------------------------
	# 2. CALCULATE ATTACK BONUS & MAP
	# ---------------------------------------------------------
	# PF2e Rule: MAP caps at 2 stacks. Agile weapons suffer -4 instead of -5.
	var map_penalty = mini(user.attack_stacks, 2) * (-4 if has_trait(&"agile") else -5)
	
	# In a full game, you would also add Proficiency (Level + 2/4/6/8) here.
	var total_attack_bonus = attack_stat + map_penalty 
	
	# ---------------------------------------------------------
	# 3. ROLL TO HIT
	# ---------------------------------------------------------
	var nat_roll = PFDice.roll_d20()
	var roll_total = nat_roll + total_attack_bonus
	var target_ac = target.ac.get_total()
	var degree = PFDice.determine_success(roll_total, target_ac, nat_roll)
	
	print("\n>>> %s attacks %s with %s!" % [user.entity_name, target.entity_name, weapon.entity_name])
	print("    Attack Roll: %d (Nat %d) + Stat: %d + MAP: %d = Total: %d vs AC %d" % [nat_roll, nat_roll, attack_stat, map_penalty, roll_total, target_ac])
	
	if degree == PFDice.Degree.FAIL or degree == PFDice.Degree.CRIT_FAIL:
		print("    Miss.")
		return true

	# ---------------------------------------------------------
	# 4. ADVANCED DAMAGE RESOLUTION
	# ---------------------------------------------------------
	
	# --- Concussive Trait Logic ---
	var final_damage_type = weapon.active_damage_type
	if has_trait(&"concussive") and final_damage_type == PFDamage.Type.PIERCING:
		# Does the target resist Piercing OR are they weak to Bludgeoning?
		var resists_p = target.resistances.has(PFDamage.Type.PIERCING) or target.immunities.has(PFDamage.Type.PIERCING)
		var weak_b = target.weaknesses.has(PFDamage.Type.BLUDGEONING)
		
		if resists_p or weak_b:
			final_damage_type = PFDamage.Type.BLUDGEONING
			print("    > Concussive Trait triggers: Bullet shatters, dealing Bludgeoning instead!")

	# --- Fatal Trait Logic ---
	# Upgrades the base die to the Fatal die size on a critical hit
	var current_die_faces = weapon.die_faces
	if degree == PFDice.Degree.CRIT_SUCCESS and weapon.fatal_die > 0:
		current_die_faces = weapon.fatal_die
		print("    > Fatal Trait triggers: Base die upgraded to d%d!" % weapon.fatal_die)

	# --- Base Damage Roll ---
	var damage_result = PFDice.roll(weapon.dice_amount, current_die_faces)
	
	# Melee weapons add STR to damage. Ranged weapons add 0 (unless they have Propulsive/Thrown, which you can add later!)
	var damage_stat = str_mod if weapon.weapon_type == PFWeapon.WeaponType.MELEE else 0
	var base_total = damage_result.total + damage_stat
	var dice_str = str(damage_result.faces)

	# ---------------------------------------------------------
	# 5. APPLY MULTIPLIERS & EXTRA DICE
	# ---------------------------------------------------------
	if degree == PFDice.Degree.CRIT_SUCCESS:
		print("    *** CRITICAL HIT! ***")
		print("    Base Rolled: %sd%d %s = %d + %d = %d Base Damage" % [weapon.dice_amount, current_die_faces, dice_str, damage_result.total, damage_stat, base_total])
		
		# Standard PF2e Crit Rule: Double the base damage
		var crit_damage = base_total * 2
		print("    Base Crit Damage: (%d Base) x 2 = %d" % [base_total, crit_damage])
		
		# Fatal Rule: Adds one extra un-doubled die of the Fatal size
		if weapon.fatal_die > 0:
			var extra_fatal = PFDice.roll(1, weapon.fatal_die).total
			crit_damage += extra_fatal
			print("    > +Fatal Die (1d%d): %d" % [weapon.fatal_die, extra_fatal])
			
		# Deadly Rule: Adds one extra un-doubled die of the Deadly size
		if weapon.deadly_die > 0:
			var extra_deadly = PFDice.roll(1, weapon.deadly_die).total
			crit_damage += extra_deadly
			print("    > +Deadly Die (1d%d): %d" % [weapon.deadly_die, extra_deadly])
			
		# Send final damage to the target
		target.take_damage(crit_damage, final_damage_type)
		
	elif degree == PFDice.Degree.SUCCESS:
		print("    * HIT! *")
		print("    Damage Rolled: %sd%d %s = %d + %d = %d Total Damage." % [weapon.dice_amount, current_die_faces, dice_str, damage_result.total, damage_stat, base_total])
		
		# Send final damage to the target
		target.take_damage(base_total, final_damage_type)
			
	return true
