# pf_action_strike.gd
# The core attack action for the engine.
## Standard offensive attack action using an equipped weapon or unarmed attack.
class_name PFActionStrike
extends PFAction

var weapon: PFWeapon
var intent_nonlethal: bool = false
var active_versatile_type: PFCombatConstants.DamageType = PFCombatConstants.DamageType.UNTYPED

func _init(p_weapon: PFWeapon, p_intent_nonlethal: bool = false, p_versatile_type: PFCombatConstants.DamageType = PFCombatConstants.DamageType.UNTYPED):
	var initial_traits: Array[StringName] = [&"attack"]
	initial_traits.append_array(p_weapon.traits)
	
	weapon = p_weapon
	intent_nonlethal = p_intent_nonlethal
	active_versatile_type = p_versatile_type
	
	super._init("Strike with " + p_weapon.entity_name, initial_traits, PFCombatConstants.ActionCost.ONE_ACTION, 1)

func execute(user: PFActor, target: PFActor = null) -> bool:
	if target == null:
		print("Strike failed: No target.")
		return false
		
	var inv = user.get("inventory") as PFInventory
	if inv:
		if weapon.hands_required == 2 and inv.two_handed_item != weapon:
			print("    > [ERROR] %s requires two hands, but is not being held with two hands!" % weapon.entity_name)
			return false
		elif weapon.hands_required == 1 and inv.held_main_hand != weapon and inv.held_off_hand != weapon and inv.two_handed_item != weapon:
			if not weapon.has_trait(&"free-hand") and not weapon.has_trait(&"unarmed"):
				print("    > [ERROR] %s must be held to strike!" % weapon.entity_name)
				return false
			
	if weapon.weapon_type == PFEquipmentConstants.WeaponType.RANGED and weapon.ammunition_type != PFEquipmentConstants.AmmunitionType.NONE:
		if not weapon.is_loaded:
			print("    > [ERROR] %s is not loaded!" % weapon.entity_name)
			return false
		if not weapon.has_trait(&"repeating"):
			weapon.is_loaded = false # Unload after firing
		
		# Capacity hint
		for t in weapon.traits:
			if String(t).begins_with("capacity "):
				print("    > Note: Weapon has the %s trait. Use an Interact action to switch to the next loaded chamber before firing again!" % String(t))
		
	# ---------------------------------------------------------
	# 1. CALCULATE ATTACK BONUS & MAP
	# ---------------------------------------------------------
	
	var base_attack_bonus = user.get_strike_bonus(weapon)
	
	if weapon.is_improvised:
		base_attack_bonus -= 2
		print("    > Improvised weapon penalty: -2")
		
	if weapon.has_trait(&"sweep"):
		if user.has_meta("last_sweep_target") and user.get_meta("last_sweep_target") != target.get_instance_id():
			base_attack_bonus += 1
			print("    > Sweep trait triggers! +1 circumstance bonus to attack.")
		user.set_meta("last_sweep_target", target.get_instance_id())
		
	if weapon.has_trait(&"backswing") and user.has_meta("backswing_active") and user.get_meta("backswing_active"):
		base_attack_bonus += 1
		print("    > Backswing trait triggers! +1 circumstance bonus.")
	user.set_meta("backswing_active", false)

	# Nonlethal Checks
	if weapon.has_trait(&"nonlethal") and not intent_nonlethal:
		base_attack_bonus -= 2
		print("    > Lethal attack with nonlethal weapon penalty: -2")
	elif not weapon.has_trait(&"nonlethal") and intent_nonlethal:
		base_attack_bonus -= 2
		print("    > Nonlethal attack with lethal weapon penalty: -2")

	# Range & Volley Penalties
	var range_penalty = 0
	var dist_ft = user.global_position.distance_to(target.global_position)
	
	if weapon.weapon_type == PFEquipmentConstants.WeaponType.MELEE and not weapon.has_trait(&"thrown"):
		var base_reach = 5
		for t in weapon.traits:
			var ts = String(t)
			if ts == "reach":
				base_reach = 10
			elif ts.begins_with("reach "):
				var parts = ts.split(" ")
				if parts.size() > 1 and parts[1].is_valid_int():
					base_reach = parts[1].to_int()
		if dist_ft > base_reach:
			print("    > [ERROR] Target is out of melee reach (%d ft > %d ft)!" % [dist_ft, base_reach])
			return false
	elif weapon.weapon_type == PFEquipmentConstants.WeaponType.RANGED or weapon.has_trait(&"thrown"):
		if weapon.range_increment > 0:
			var increments = int(dist_ft / weapon.range_increment)
			if increments > 0:
				range_penalty = -2 * increments
				print("    > Range Increment Penalty: %d" % range_penalty)
				if increments > 6:
					print("    > [ERROR] Target is beyond maximum range!")
					return false
		if weapon.volley_range > 0 and dist_ft < weapon.volley_range:
			range_penalty -= 2
			print("    > Volley Penalty (Too close!): -2")
			
	base_attack_bonus += range_penalty
	
	var base_map = -5
	var db_inst = PFDatabase.get_instance()
	for t in weapon.traits:
		var trait_data = db_inst.get_trait_data(t) if db_inst else {}
		if trait_data and trait_data.get("mechanic_hook") == "modifies_map":
			# Use the positive hook value as a penalty (e.g., agile provides 4, penalty is -4)
			base_map = -trait_data.get("hook_value", 4)
			
	var map_penalty = mini(user.action_economy.attack_stacks, 2) * base_map
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
	
	if degree == PFMathConstants.DegreeOfSuccess.FAIL or degree == PFMathConstants.DegreeOfSuccess.CRIT_FAIL:
		print("    Miss.")
		if weapon.has_trait(&"backswing"):
			user.set_meta("backswing_active", true)
			
		if degree == PFMathConstants.DegreeOfSuccess.CRIT_FAIL and weapon.has_trait(&"cobbled"):
			print("    > [CRITICAL FAILURE] Cobbled weapon misfires and becomes broken!")
			weapon.current_hp = mini(weapon.current_hp, weapon.broken_threshold)
			
		return true

	# ---------------------------------------------------------
	# 3. ADVANCED DAMAGE RESOLUTION
	# ---------------------------------------------------------
	
	var final_damage_type = weapon.active_damage_type
	if active_versatile_type != PFCombatConstants.DamageType.UNTYPED:
		var has_versatile = false
		for t in weapon.traits:
			var ts = String(t)
			if ts.begins_with("versatile"):
				var parts = ts.split(" ")
				if parts.size() > 1:
					var v_type = parts[1].to_lower()
					var mapped_type = PFCombatConstants.DamageType.UNTYPED
					match v_type:
						"b": mapped_type = PFCombatConstants.DamageType.BLUDGEONING
						"p": mapped_type = PFCombatConstants.DamageType.PIERCING
						"s": mapped_type = PFCombatConstants.DamageType.SLASHING
					if mapped_type == active_versatile_type:
						has_versatile = true
						break
		if has_versatile:
			final_damage_type = active_versatile_type
			print("    > Versatile trait active! Damage type changed to %s." % PFCombatConstants.DamageType.keys()[final_damage_type])
			
	if weapon.has_trait(&"concussive") and final_damage_type == PFCombatConstants.DamageType.PIERCING:
		var resists_p = target.resistances.has(PFCombatConstants.DamageType.PIERCING) or target.immunities.has(PFCombatConstants.DamageType.PIERCING)
		var weak_b = target.weaknesses.has(PFCombatConstants.DamageType.BLUDGEONING)
		
		if resists_p or weak_b:
			final_damage_type = PFCombatConstants.DamageType.BLUDGEONING
			print("    > Concussive Trait triggers: Projectile shatters, dealing Bludgeoning instead!")

	var current_die_faces = weapon.die_faces
	var parsed_fatal_die = weapon.fatal_die
	var is_fatal_crit = false
	
	for t in weapon.traits:
		var ts = String(t)
		if ts.begins_with("fatal d") and not ts.begins_with("fatal aim"):
			var parts = ts.split(" d")
			if parts.size() > 1 and parts[1].is_valid_int():
				parsed_fatal_die = parts[1].to_int()
		elif ts.begins_with("fatal aim d"):
			var inv_check = user.get("inventory") as PFInventory
			if inv_check and inv_check.two_handed_item == weapon:
				var parts = ts.split(" d")
				if parts.size() > 1 and parts[1].is_valid_int():
					parsed_fatal_die = parts[1].to_int()

	var is_mounted = user.has_condition("mounted")
	var jousting_die = 0
	
	if degree == PFMathConstants.DegreeOfSuccess.CRIT_SUCCESS and parsed_fatal_die > 0:
		current_die_faces = parsed_fatal_die
		is_fatal_crit = true
		print("    > Fatal Trait triggers: Base die upgraded to d%d!" % parsed_fatal_die)
	else:
		var two_hand_trait = ""
		for t in weapon.traits:
			if String(t).begins_with("two-hand"):
				two_hand_trait = String(t)
				break
		
		if two_hand_trait != "":
			var inv_check = user.get("inventory") as PFInventory
			if inv_check and inv_check.two_handed_item == weapon:
				var parts = two_hand_trait.split(" d")
				if parts.size() > 1 and parts[1].is_valid_int():
					current_die_faces = parts[1].to_int()
				else:
					current_die_faces += 2 # Fallback if just "two-hand"
				print("    > Two-Hand trait triggers! Base die upgraded to d%d." % current_die_faces)
				
		if is_mounted:
			for t in weapon.traits:
				var ts = String(t)
				if ts.begins_with("jousting d"):
					var parts = ts.split(" d")
					if parts.size() > 1 and parts[1].is_valid_int():
						jousting_die = parts[1].to_int()
						
			if jousting_die > current_die_faces:
				current_die_faces = jousting_die
				print("    > Jousting Trait triggers! Base die upgraded to d%d." % current_die_faces)
				
	var damage_result = PFDice.roll(weapon.dice_amount, current_die_faces)
	var damage_stat = user.get_strike_damage_bonus(weapon)
	
	if is_mounted and weapon.has_trait(&"jousting"):
		damage_stat += weapon.dice_amount
		print("    > Jousting Trait triggers! +%d damage." % weapon.dice_amount)
	
	if weapon.has_trait(&"forceful"):
		if user.action_economy.attack_stacks >= 2:
			var forceful_bonus = weapon.dice_amount * 2
			damage_stat += forceful_bonus
			print("    > Forceful trait triggers! +%d damage." % forceful_bonus)
		elif user.action_economy.attack_stacks == 1:
			var forceful_bonus = weapon.dice_amount
			damage_stat += forceful_bonus
			print("    > Forceful trait triggers! +%d damage." % forceful_bonus)
			
	if weapon.has_trait(&"backstabber") and target.has_condition("off_guard"):
		var backstabber_dmg = 1 if weapon.potency_bonus < 3 else 2
		damage_stat += backstabber_dmg
		print("    > Backstabber trait triggers! +%d precision damage." % backstabber_dmg)
	
	var base_total = damage_result.total + damage_stat
	var dice_str = str(damage_result.faces)

	# ---------------------------------------------------------
	# 4. APPLY MULTIPLIERS & EXTRA DICE
	# ---------------------------------------------------------
	if degree == PFMathConstants.DegreeOfSuccess.CRIT_SUCCESS:
		print("    *** CRITICAL HIT! ***")
		
		if user.has_method("has_critical_specialization") and user.has_critical_specialization(weapon.group):
			print("    *** CRITICAL SPECIALIZATION TRIGGERED! ***")
			_apply_critical_specialization(target)
			
		print("    Base Rolled: %sd%d %s = %d + %d = %d Base Damage" % [weapon.dice_amount, current_die_faces, dice_str, damage_result.total, damage_stat, base_total])
		
		var crit_damage = base_total * 2
		print("    Base Crit Damage: (%d Base) x 2 = %d" % [base_total, crit_damage])
		
		if is_fatal_crit:
			var extra_fatal = PFDice.roll(1, parsed_fatal_die).total
			crit_damage += extra_fatal
			print("    > +Fatal Die (1d%d): %d" % [parsed_fatal_die, extra_fatal])
			
		var parsed_deadly_die = weapon.deadly_die
		for t in weapon.traits:
			if String(t).begins_with("deadly d"):
				var parts = String(t).split(" d")
				if parts.size() > 1 and parts[1].is_valid_int():
					parsed_deadly_die = parts[1].to_int()
					
		if parsed_deadly_die > 0:
			var deadly_dice_count = 1
			if weapon.dice_amount == 2: deadly_dice_count = 1
			elif weapon.dice_amount == 3: deadly_dice_count = 2
			elif weapon.dice_amount == 4: deadly_dice_count = 3
			
			var extra_deadly = PFDice.roll(deadly_dice_count, parsed_deadly_die).total
			crit_damage += extra_deadly
			print("    > +Deadly Trait triggers: %dd%d (%d) added after doubling!" % [deadly_dice_count, parsed_deadly_die, extra_deadly])
			
		if weapon.weapon_type == PFEquipmentConstants.WeaponType.MELEE and weapon.has_trait(&"critical fusion"):
			var fusion_dmg = weapon.dice_amount * 2
			crit_damage += fusion_dmg
			print("    > Critical Fusion Trait triggers: +%d precision damage added!" % fusion_dmg)
			
		var traits_with_crit = weapon.traits.duplicate()
		if not traits_with_crit.has(&"critical"):
			traits_with_crit.append(&"critical")
		if intent_nonlethal:
			traits_with_crit.append(&"nonlethal")
			
		# Send final damage to the target, passing the weapon traits for Sanctification/Material checks!
		target.take_damage(crit_damage, final_damage_type, traits_with_crit)
		
	elif degree == PFMathConstants.DegreeOfSuccess.SUCCESS:
		print("    * HIT! *")
		print("    Damage Rolled: %sd%d %s = %d + %d = %d Total Damage." % [weapon.dice_amount, current_die_faces, dice_str, damage_result.total, damage_stat, base_total])
		
		var traits_with_hit = weapon.traits.duplicate()
		if intent_nonlethal:
			traits_with_hit.append(&"nonlethal")
			
		# Send final damage to the target, passing the weapon traits!
		target.take_damage(base_total, final_damage_type, traits_with_hit)
			
	if weapon.has_trait(&"splash") and degree != PFMathConstants.DegreeOfSuccess.CRIT_FAIL:
		var splash_dmg = 0
		for t in weapon.traits:
			var ts = String(t)
			if ts.begins_with("splash "):
				var parts = ts.split(" ")
				if parts.size() > 1 and parts[1].is_valid_int():
					splash_dmg = parts[1].to_int()
		if splash_dmg == 0:
			splash_dmg = weapon.dice_amount # Default
			
		print("    > Splash trait triggers! Target takes %d splash damage." % splash_dmg)
		target.take_damage(splash_dmg, final_damage_type, weapon.traits)
		
	if weapon.has_trait(&"injection") and weapon.injection_payload != null:
		print("    > Injection Trait triggers! Delivering payload: %s" % weapon.injection_payload.entity_name)
		# TODO: We would apply the poison/potion effect to the target here
		weapon.injection_payload = null
		
	return true

func _apply_critical_specialization(target: PFActor) -> void:
	match weapon.group:
		PFEquipmentConstants.WeaponGroup.SWORD:
			var off_guard = PFCondition.new(&"off_guard")
			target.apply_condition(off_guard)
			print("    > Sword Specialization: Target is Off-Guard until start of your next turn!")
		PFEquipmentConstants.WeaponGroup.BOW:
			var immobilized = PFCondition.new(&"immobilized")
			target.apply_condition(immobilized)
			print("    > Bow Specialization: Target is Immobilized!")
		PFEquipmentConstants.WeaponGroup.CLUB:
			print("    > Club Specialization: Target is knocked 10 feet away!")
		PFEquipmentConstants.WeaponGroup.SPEAR:
			var clumsy = PFCondition.new(&"clumsy")
			clumsy.value = 1
			target.apply_condition(clumsy)
			print("    > Spear Specialization: Target is Clumsy 1 until start of your next turn!")
		PFEquipmentConstants.WeaponGroup.AXE:
			print("    > Axe Specialization: You may deal damage to an adjacent enemy!")
		PFEquipmentConstants.WeaponGroup.FIREARM:
			print("    > Firearm Specialization: Target must succeed at a Fortitude save or be stunned 1!")
		PFEquipmentConstants.WeaponGroup.DART:
			print("    > Dart Specialization: Target takes persistent bleed damage!")
		PFEquipmentConstants.WeaponGroup.KNIFE:
			print("    > Knife Specialization: Target takes persistent bleed damage!")
		_:
			print("    > (No critical specialization effect implemented for this group yet).")
