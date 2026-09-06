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

func execute(user: PFActor, target: Variant = null) -> bool:
	if target == null:
		print("Strike failed: No target.")
		return false
		
	if PFContext.detection_manager:
		if not PFContext.detection_manager.roll_flat_check_for_targeting(user, target):
			print("    > Strike automatically fails due to concealment/invisibility.")
			# Still costs an action and MAP, so we don't return false directly without charging it.
			# But wait, PFAction's base execute() already burned the action. So returning true is fine
			# but we don't want to deal damage. Actually, we should just abort the rest of the method.
			# If we return true here, it means "the action was performed (but missed)".
			user.action_economy.increment_attack()
			return true
		
	var inventory = user.get(&"inventory") as PFInventory
	if inventory:
		if weapon.hands_required == 2 and inventory.two_handed_item != weapon:
			print("    > [ERROR] %s requires two hands, but is not being held with two hands!" % weapon.entity_name)
			return false
		elif weapon.hands_required == 1 and inventory.held_main_hand != weapon and inventory.held_off_hand != weapon and inventory.two_handed_item != weapon:
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
		if user.has_meta(&"last_sweep_target") and user.get_meta(&"last_sweep_target") != target.get_instance_id():
			base_attack_bonus += 1
			print("    > Sweep trait triggers! +1 circumstance bonus to attack.")
		user.set_meta(&"last_sweep_target", target.get_instance_id())
		
	if weapon.has_trait(&"backswing") and user.has_meta(&"backswing_active") and user.get_meta(&"backswing_active"):
		base_attack_bonus += 1
		print("    > Backswing trait triggers! +1 circumstance bonus.")
	user.set_meta(&"backswing_active", false)

	# Nonlethal Checks
	if weapon.has_trait(&"nonlethal") and not intent_nonlethal:
		base_attack_bonus -= 2
		print("    > Lethal attack with nonlethal weapon penalty: -2")
	elif not weapon.has_trait(&"nonlethal") and intent_nonlethal:
		base_attack_bonus -= 2
		print("    > Nonlethal attack with lethal weapon penalty: -2")

	# Range & Volley Penalties
	var range_penalty = 0
	var dist_sq = 0.0
	if user.is_inside_tree() and target.is_inside_tree():
		dist_sq = user.global_position.distance_squared_to(target.global_position)
	
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
		if dist_sq > (base_reach * base_reach):
			# ⚡ Bolt: Use native distance_squared_to instead of distance_to to avoid expensive sqrt calls
			print("    > [ERROR] Target is out of melee reach (%d ft > %d ft)!" % [sqrt(dist_sq), base_reach])
			return false
	elif weapon.weapon_type == PFEquipmentConstants.WeaponType.RANGED or weapon.has_trait(&"thrown"):
		var dist_ft = sqrt(dist_sq) if dist_sq > 0.0 else 0.0
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
	
	# Aquatic Combat Rules
	if PFContext.environment_manager and PFContext.environment_manager.is_underwater:
		# Check if the weapon naturally lacks the aquatic/underwater trait (if those existed)
		# For now, apply -2 to Bludgeoning and Slashing.
		if weapon.active_damage_type == PFCombatConstants.DamageType.BLUDGEONING or weapon.active_damage_type == PFCombatConstants.DamageType.SLASHING:
			# If the actor lacks a swim speed, they take a -2 penalty
			var has_swim_speed = false
			# TODO: check actor.speeds once implemented
			if not has_swim_speed:
				base_attack_bonus -= 2
				print("    > Aquatic Combat Penalty: -2 to hit with Bludgeoning/Slashing weapons underwater.")
	
	var base_map = -5
	var db_inst = PFDatabase.get_instance()
	for t in weapon.traits:
		var trait_data = db_inst.get_trait_data(t) if db_inst else {}
		if trait_data and trait_data.get(&"mechanic_hook") == "modifies_map":
			# Use the positive hook value as a penalty (e.g., agile provides 4, penalty is -4)
			base_map = -trait_data.get(&"hook_value", 4)
			
	var map_penalty = mini(user.action_economy.attack_stacks, 2) * base_map
	# --- SPATIAL MATH (FLANKING & COVER) ---
	var injected_off_guard: PFCondition = null
	var injected_cover: PFCondition = null
	
	if weapon.weapon_type == PFEquipmentConstants.WeaponType.MELEE or weapon.has_trait(&"unarmed"):
		var is_flanking_target = false
		if PFContext.active_turn_manager:
			var allies = PFContext.active_turn_manager.get_allies(user)
			for ally in allies:
				if PFSpatialMath.is_flanking(user, target, ally):
					is_flanking_target = true
					break
		
		if is_flanking_target:
			injected_off_guard = PFCondition.create("off-guard")
			if injected_off_guard:
				target.apply_condition(injected_off_guard)
				print("    > Tactical Advantage: Flanking! Target is Off-Guard.")
	
	if weapon.weapon_type == PFEquipmentConstants.WeaponType.RANGED or weapon.has_trait(&"thrown"):
		var space_state = user.get_world_3d().direct_space_state if user.is_inside_tree() else null
		if space_state:
			var cover_level = PFSpatialMath.get_cover_level(user, target, space_state)
			if cover_level == PFCombatConstants.CoverType.LESSER:
				injected_cover = PFCondition.create("lesser_cover")
				print("    > Tactical Disadvantage: Lesser Cover grants +1 AC.")
			elif cover_level == PFCombatConstants.CoverType.STANDARD:
				injected_cover = PFCondition.create("standard_cover")
				print("    > Tactical Disadvantage: Standard Cover grants +2 AC.")
			elif cover_level == PFCombatConstants.CoverType.GREATER:
				injected_cover = PFCondition.create("greater_cover")
				print("    > Tactical Disadvantage: Greater Cover grants +4 AC.")
				
			if injected_cover:
				target.apply_condition(injected_cover)

	var total_attack_bonus = base_attack_bonus + map_penalty 
	
	# ---------------------------------------------------------
	# 2. ROLL TO HIT
	# ---------------------------------------------------------
	
	var nat_roll = PFDice.roll_d20()
	var roll_total = nat_roll + total_attack_bonus
	var target_ac = target.get_ac()
	var degree = PFDice.determine_success(roll_total, target_ac, nat_roll)
	
	# Clean up temporary spatial conditions immediately after calculating success
	if injected_off_guard:
		target.remove_condition(&"off-guard")
	if injected_cover:
		target.remove_condition(StringName(injected_cover.entity_name))

	
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
			user.set_meta(&"backswing_active", true)
			
		if degree == PFMathConstants.DegreeOfSuccess.CRIT_FAIL and weapon.has_trait(&"cobbled"):
			print("    > [CRITICAL FAILURE] Cobbled weapon misfires and becomes broken!")
			weapon.current_hp = mini(weapon.current_hp, weapon.broken_threshold)
			
		# Splash damage applies on a normal miss
		if degree == PFMathConstants.DegreeOfSuccess.FAIL and weapon.has_trait(&"splash"):
			var miss_splash_dmg = weapon.get("splash_damage")
			if miss_splash_dmg == null:
				miss_splash_dmg = weapon.dice_amount
			print("    > Splash trait! %d splash damage added to target on miss." % miss_splash_dmg)
			target.health.apply_damage(miss_splash_dmg, weapon.active_damage_type)
			
		_handle_thrown_consumption(user, target, weapon)
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
			var inv_check = user.get(&"inventory") as PFInventory
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
			var inv_check = user.get(&"inventory") as PFInventory
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
	
	if "flat_damage_bonus" in weapon:
		damage_stat += weapon.flat_damage_bonus
	
	var has_splash = weapon.has_trait(&"splash")
	if has_splash:
		damage_stat = 0 # Splash weapons don't add Strength modifier to damage roll
	
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

	var splash_dmg = 0
	if has_splash:
		if "splash_damage" in weapon:
			splash_dmg = weapon.splash_damage
		else:
			splash_dmg = weapon.dice_amount # Default fallback

	if has_splash and degree != PFMathConstants.DegreeOfSuccess.CRIT_FAIL:
		print("    > Splash trait! %d splash damage added to target." % splash_dmg)

	# ---------------------------------------------------------
	# 4. APPLY MULTIPLIERS & EXTRA DICE
	# ---------------------------------------------------------
	if degree == PFMathConstants.DegreeOfSuccess.CRIT_SUCCESS:
		print("    *** CRITICAL HIT! ***")
		
		if user.has_critical_specialization(weapon.group):
			print("    *** CRITICAL SPECIALIZATION TRIGGERED! ***")
			_apply_critical_specialization(user, target)
			
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
			
		if has_splash:
			crit_damage += splash_dmg # Splash damage is NOT multiplied on a critical hit
			
		var traits_with_crit = weapon.traits.duplicate()
		if not traits_with_crit.has(&"critical"):
			traits_with_crit.append(&"critical")
		if intent_nonlethal:
			traits_with_crit.append(&"nonlethal")
			
		# Send final damage to the target, passing the weapon traits for Sanctification/Material checks!
		if PFContext.reaction_manager:
			var event_data = {"damage": crit_damage, "type": final_damage_type, "traits": traits_with_crit, "source_weapon": weapon}
			event_data = await PFContext.reaction_manager.notify_event(PFCombatConstants.ReactionTriggers.BEFORE_TAKE_DAMAGE, user, event_data)
			crit_damage = event_data.get(&"damage", crit_damage)
			final_damage_type = event_data.get(&"type", final_damage_type)
			
		target.take_damage(crit_damage, final_damage_type, traits_with_crit)
	elif degree == PFMathConstants.DegreeOfSuccess.SUCCESS:
		print("    * HIT! *")
		print("    Damage Rolled: %sd%d %s = %d + %d = %d Total Damage." % [weapon.dice_amount, current_die_faces, dice_str, damage_result.total, damage_stat, base_total])
		
		var traits_with_hit = weapon.traits.duplicate()
		if intent_nonlethal:
			traits_with_hit.append(&"nonlethal")
			
		# Send final damage to the target, passing the weapon traits!
		if PFContext.reaction_manager:
			var event_data = {"damage": base_total, "type": final_damage_type, "traits": traits_with_hit, "source_weapon": weapon}
			event_data = await PFContext.reaction_manager.notify_event(PFCombatConstants.ReactionTriggers.BEFORE_TAKE_DAMAGE, user, event_data)
			base_total = event_data.get(&"damage", base_total)
			final_damage_type = event_data.get(&"type", final_damage_type)
			
		if has_splash:
			base_total += splash_dmg
			
		target.take_damage(base_total, final_damage_type, traits_with_hit)
		
	elif degree == PFMathConstants.DegreeOfSuccess.FAIL:
		if has_splash:
			# On a failure, the splash weapon still deals splash damage to the primary target
			target.take_damage(splash_dmg, final_damage_type, weapon.traits)
			
	# Splash AoE effect to OTHER creatures (Only on Success or Critical Success)
	if has_splash and (degree == PFMathConstants.DegreeOfSuccess.SUCCESS or degree == PFMathConstants.DegreeOfSuccess.CRIT_SUCCESS):
		var splash_radius = 5.0
		# Bomb Specialization increases splash radius to 10 feet
		if user.has_critical_specialization(weapon.group) and weapon.group == PFEquipmentConstants.WeaponGroup.BOMB:
			splash_radius = 10.0
			
		var space_state = target.get_world_3d().direct_space_state if target.is_inside_tree() else null
		if space_state:
			var splash_targets = PFSpatialMath.get_splash_targets(space_state, target.position, splash_radius)
			for splash_target in splash_targets:
				if splash_target != target:
					print("    > Splash hits %s for %d splash damage!" % [splash_target.entity_name, splash_dmg])
					splash_target.take_damage(splash_dmg, final_damage_type, weapon.traits)
			
	if weapon.injection_payload != null:
		if weapon.has_trait(&"injection"):
			print("    > Injection Trait triggers! Delivering payload: %s" % weapon.injection_payload.entity_name)
		
		if weapon.injection_payload.has_method(&"_apply_affliction"):
			var poison = weapon.injection_payload
			print("    > The %s delivers %s into %s!" % [weapon.entity_name, poison.entity_name, target.entity_name])
			poison._apply_affliction(target)
		else:
			print("    > The %s delivers its payload into %s!" % [weapon.entity_name, target.entity_name])
			
		weapon.injection_payload = null
		
	_handle_thrown_consumption(user, target, weapon)
	return true

func _apply_critical_specialization(user: PFActor, target: PFActor) -> void:
	match weapon.group:
		PFEquipmentConstants.WeaponGroup.AXE:
			print("    > Axe Specialization: You may deal damage equal to 1 weapon damage die to an adjacent enemy!")
		PFEquipmentConstants.WeaponGroup.BOMB:
			print("    > Bomb Specialization: Splash radius increased to 10 feet!")
		PFEquipmentConstants.WeaponGroup.BOW:
			target.apply_condition(PFCondition.create(&"immobilized"))
			print("    > Bow Specialization: Target is Immobilized!")
		PFEquipmentConstants.WeaponGroup.BRAWLING:
			var save_mod = target.get_save_bonus(&"fortitude")
			var roll = PFDice.roll_d20()
			var total = roll + save_mod
			var dc = user.get_class_dc() if user.has_method(&"get_class_dc") else 10
			var degree = PFDice.determine_success(total, dc, roll)
			if degree == PFMathConstants.DegreeOfSuccess.FAIL or degree == PFMathConstants.DegreeOfSuccess.CRIT_FAIL:
				var slowed = PFCondition.create(&"slowed")
				slowed.value = 1
				target.apply_condition(slowed)
				print("    > Brawling Specialization (Rolled %d vs DC %d): Target failed Fort save and is Slowed 1!" % [total, dc])
			else:
				print("    > Brawling Specialization (Rolled %d vs DC %d): Target succeeded Fort save." % [total, dc])
		PFEquipmentConstants.WeaponGroup.CLUB:
			print("    > Club Specialization: Target is knocked up to 10 feet away!")
		PFEquipmentConstants.WeaponGroup.CROSSBOW, PFEquipmentConstants.WeaponGroup.DART, PFEquipmentConstants.WeaponGroup.KNIFE:
			var pd = PFCondition.new(&"persistent_damage", weapon.dice_amount)
			pd.target_stat = "bleed"
			target.apply_condition(pd)
			print("    > %s Specialization: Target takes %dd6 persistent bleed damage!" % [PFEquipmentConstants.WeaponGroup.keys()[weapon.group].capitalize(), weapon.dice_amount])
		PFEquipmentConstants.WeaponGroup.FIREARM, PFEquipmentConstants.WeaponGroup.SLING:
			var save_mod = target.get_save_bonus(&"fortitude")
			var roll = PFDice.roll_d20()
			var total = roll + save_mod
			var dc = user.get_class_dc() if user.has_method(&"get_class_dc") else 10
			var degree = PFDice.determine_success(total, dc, roll)
			if degree == PFMathConstants.DegreeOfSuccess.FAIL or degree == PFMathConstants.DegreeOfSuccess.CRIT_FAIL:
				var stunned = PFCondition.create(&"stunned")
				stunned.value = 1
				target.apply_condition(stunned)
				print("    > %s Specialization (Rolled %d vs DC %d): Target failed Fort save and is Stunned 1!" % [PFEquipmentConstants.WeaponGroup.keys()[weapon.group].capitalize(), total, dc])
			else:
				print("    > %s Specialization (Rolled %d vs DC %d): Target succeeded Fort save." % [PFEquipmentConstants.WeaponGroup.keys()[weapon.group].capitalize(), total, dc])
		PFEquipmentConstants.WeaponGroup.FLAIL, PFEquipmentConstants.WeaponGroup.HAMMER:
			target.apply_condition(PFCondition.create(&"prone"))
			print("    > %s Specialization: Target is knocked Prone!" % PFEquipmentConstants.WeaponGroup.keys()[weapon.group].capitalize())
		PFEquipmentConstants.WeaponGroup.PICK:
			var pick_dmg = 2 * weapon.dice_amount
			print("    > Pick Specialization: Deal %d additional damage!" % pick_dmg)
			target.take_damage(pick_dmg, weapon.active_damage_type, weapon.traits)
		PFEquipmentConstants.WeaponGroup.POLEARM:
			print("    > Polearm Specialization: Target is moved 5 feet!")
		PFEquipmentConstants.WeaponGroup.SHIELD:
			print("    > Shield Specialization: Target is pushed back 5 feet!")
		PFEquipmentConstants.WeaponGroup.SPEAR:
			var clumsy = PFCondition.create(&"clumsy")
			clumsy.value = 1
			target.apply_condition(clumsy)
			print("    > Spear Specialization: Target is Clumsy 1 until start of your next turn!")
		PFEquipmentConstants.WeaponGroup.SWORD:
			target.apply_condition(PFCondition.create(&"off_guard"))
			print("    > Sword Specialization: Target is Off-Guard until start of your next turn!")
		_:
			print("    > (No critical specialization effect implemented for this group yet).")

func _handle_thrown_consumption(user: PFActor, target: PFActor, thrown_weapon: PFWeapon) -> void:
	if not thrown_weapon.has_trait(&"thrown"):
		return
		
	if thrown_weapon.has_trait(&"returning"):
		print("    > The returning rune instantly flies the %s back into %s's hand!" % [thrown_weapon.entity_name, user.entity_name])
		return
		
	user.inventory.unequip_item(thrown_weapon)
	user.inventory.items.erase(thrown_weapon)
	
	if thrown_weapon.has_trait(&"consumable"):
		print("    > %s was consumed on impact." % [thrown_weapon.entity_name])
	else:
		print("    > %s was thrown and drops to the ground in %s's space." % [thrown_weapon.entity_name, target.entity_name])
		if target and target.inventory:
			target.inventory.add_item(thrown_weapon)
		thrown_weapon.carry_state = PFEquipmentConstants.CarryState.DROPPED
