# pf_actor.gd
# Represents any living, undead, or construct entity in the game: Players, NPCs, and Monsters.
class_name PFActor
extends PFEntity

# --- COMPONENT ---
var sheet: PFProficiencySheet

# --- MONSTER ARCHITECTURE ---
var is_monster: bool
var monster_stats: Dictionary = {} 

# --- EQUIPMENT ---
var equipped_armor: PFArmor
var equipped_shield: PFShield 
var auto_shield_block: bool = true 
var bonus_blockable_types: Array[PFDamage.Type] = [] 

# --- ACTIVE CONDITIONS ---
var conditions: Array[PFCondition] = []

# --- ABILITY MODIFIERS ---
var str_mod: int
var dex_mod: int
var con_mod: int
var int_mod: int
var wis_mod: int
var cha_mod: int

# --- HEALTH & DEFENSES ---
var max_hp: int
var current_hp: int
var temp_hp: int = 0

var immunities: Array[PFDamage.Type] = []

# Maps Damage Types to numerical values
var weaknesses: Dictionary = {} 
var resistances: Dictionary = {} 

# Maps Traits (like &"holy" or &"unholy") to numerical values
var trait_weaknesses: Dictionary = {} 
var trait_resistances: Dictionary = {} 

var fort_save: PFStat
var ref_save: PFStat
var will_save: PFStat

# --- MOVEMENT ---
var speed_land: int
var speed_fly: int
var speed_swim: int

# --- ACTION ECONOMY ---
var actions_remaining: int = 0
var reactions_remaining: int = 0
var attack_stacks: int = 0 

# Constructor
func _init(p_name: String, p_traits: Array[StringName], p_level: int, p_is_monster: bool,
		p_hp: int, p_fort: int, p_ref: int, p_will: int,
		p_str: int, p_dex: int, p_con: int, p_int: int, p_wis: int, p_cha: int,
		p_speed_land: int = 25, p_speed_fly: int = 0, p_speed_swim: int = 0):
	
	super._init(p_name, p_traits) 
	is_monster = p_is_monster
	
	sheet = PFProficiencySheet.new(p_level)
	
	max_hp = p_hp
	current_hp = p_hp
	
	fort_save = PFStat.new(p_fort)
	ref_save = PFStat.new(p_ref)
	will_save = PFStat.new(p_will)
	
	str_mod = p_str
	dex_mod = p_dex
	con_mod = p_con
	int_mod = p_int
	wis_mod = p_wis
	cha_mod = p_cha
	
	speed_land = p_speed_land
	speed_fly = p_speed_fly
	speed_swim = p_speed_swim

# ---------------------------------------------------------
# ACTIVE CONDITIONS ENGINE
# ---------------------------------------------------------

func apply_condition(new_condition: PFCondition) -> void:
	if not new_condition.on_apply(self):
		return

	for c in conditions:
		if c.condition_name == new_condition.condition_name:
			if new_condition.value > c.value:
				c.value = new_condition.value
				print("%s's %s worsens to %d!" % [entity_name, c.condition_name, c.value])
			return
			
	conditions.append(new_condition)
	print("%s is now %s %d!" % [entity_name, new_condition.condition_name, new_condition.value])

func get_condition_modifier(context: StringName) -> int:
	var total_mod = 0
	for c in conditions:
		if c.is_active:
			total_mod += c.get_modifier(context)
	return total_mod

# ---------------------------------------------------------
# THE UNIFIED MATH DELEGATES
# ---------------------------------------------------------

func get_ac() -> int:
	var base_ac = 10
	if is_monster:
		base_ac = monster_stats.get("ac", 10)
	else:
		var current_armor = equipped_armor
		if current_armor == null:
			# FIX: Added 0 (Level) and 0.0 (Price) to the fallback armor generation
			current_armor = PFArmor.new("Unarmored", [], 0, 0.0, PFArmor.Category.UNARMORED, PFArmor.Group.UNARMORED, 0, 99)
		
		var capped_dex = mini(dex_mod, current_armor.dex_cap)
		base_ac += capped_dex + current_armor.ac_bonus + sheet.get_armor_bonus(current_armor.category)
		
		if current_armor.is_broken():
			base_ac -= 2 
	
	return base_ac + get_condition_modifier(&"ac")

func get_strike_bonus(weapon: PFWeapon) -> int:
	var base_bonus = 0
	if is_monster:
		base_bonus = monster_stats.get("attack", 0)
	else:
		var stat_mod = dex_mod if weapon.weapon_type == PFWeapon.WeaponType.RANGED else str_mod
		if weapon.has_trait(&"finesse") and dex_mod > str_mod:
			stat_mod = dex_mod
		base_bonus = stat_mod + sheet.get_weapon_bonus(weapon.category)
		base_bonus += weapon.potency_bonus 
		
	if weapon.is_broken():
		base_bonus -= 2
		
	return base_bonus + get_condition_modifier(&"attack")

func get_strike_damage_bonus(weapon: PFWeapon) -> int:
	var dmg_bonus = 0
	if is_monster:
		dmg_bonus = monster_stats.get("damage", str_mod) 
	elif weapon.weapon_type == PFWeapon.WeaponType.MELEE:
		dmg_bonus = str_mod 
		
	if weapon.is_broken():
		dmg_bonus -= 2
		
	return dmg_bonus

func get_skill_bonus(skill: StringName) -> int:
	var base_bonus = 0
	if is_monster:
		base_bonus = monster_stats.get(skill, 0)
	else:
		var ability = PFProficiency.get_skill_ability(skill)
		var ability_mod = get_modifier(ability)
		var rank = sheet.skills.get(skill, PFProficiency.Rank.UNTRAINED)
		base_bonus = ability_mod + PFProficiency.calculate_bonus(rank, sheet.level)
		
	return base_bonus + get_condition_modifier(&"skill")

func get_modifier(ability: StringName) -> int:
	match ability:
		&"STR": return str_mod
		&"DEX": return dex_mod
		&"CON": return con_mod
		&"INT": return int_mod
		&"WIS": return wis_mod
		&"CHA": return cha_mod
		_: return 0

func get_speed_land() -> int:
	var current_speed = speed_land
	
	if equipped_armor != null and equipped_armor.speed_penalty < 0:
		var armor_penalty = equipped_armor.speed_penalty
		if str_mod >= equipped_armor.strength_req:
			armor_penalty = mini(0, armor_penalty + 5)
		current_speed += armor_penalty
		
	if equipped_shield != null and equipped_shield.speed_penalty < 0:
		current_speed += equipped_shield.speed_penalty
		
	current_speed += get_condition_modifier(&"speed")
	return maxi(5, current_speed)

# ---------------------------------------------------------
# ACTION ECONOMY & TURN HOOKS
# ---------------------------------------------------------

func start_turn() -> void:
	actions_remaining = 3
	reactions_remaining = 1
	attack_stacks = 0 
	print("\n--- %s starts their turn! (3 Actions) ---" % entity_name)
	
	for c in conditions:
		if c.is_active: c.on_turn_start(self)
	conditions = conditions.filter(func(c): return c.is_active)

func use_action(action: PFAction, target: PFActor = null) -> void:
	var cost_val = action.cost
	
	if actions_remaining < cost_val:
		print("%s doesn't have enough actions for %s." % [entity_name, action.entity_name])
		return
		
	actions_remaining -= cost_val
	print("[%s spends %d action(s). %d remaining]" % [entity_name, cost_val, actions_remaining])
	
	if action.execute(self, target):
		attack_stacks += action.map_weight

func execute_subordinate_action(action: PFAction, target: PFActor = null) -> void:
	print("  > [Subordinate Action] %s performs %s" % [entity_name, action.entity_name])
	if action.execute(self, target):
		attack_stacks += action.map_weight

func end_turn() -> void:
	print("\n--- %s ends their turn. ---" % entity_name)
	
	for c in conditions:
		if c.is_active: c.on_turn_end(self)
	conditions = conditions.filter(func(c): return c.is_active)

# ---------------------------------------------------------
# HEALTH & DAMAGE LOGIC
# ---------------------------------------------------------

func grant_temp_hp(amount: int) -> void:
	if amount > temp_hp:
		temp_hp = amount
		print("%s gains %d Temporary HP! (Total Temp HP: %d)" % [entity_name, amount, temp_hp])

func heal(amount: int, heal_type: PFDamage.Type = PFDamage.Type.UNTYPED) -> void:
	if has_trait(&"construct") and (heal_type == PFDamage.Type.VITALITY or heal_type == PFDamage.Type.VOID):
		print("    > %s is a Construct and ignores Vitality/Void healing." % entity_name)
		return
		
	var has_void_healing = has_trait(&"undead") or has_trait(&"void_healing")
	
	if heal_type == PFDamage.Type.VITALITY and has_void_healing:
		print("    > %s is harmed by Vitality! Reversing heal to damage." % entity_name)
		take_damage(amount, PFDamage.Type.VITALITY)
		return
	elif heal_type == PFDamage.Type.VOID and not has_void_healing:
		print("    > %s is harmed by Void! Reversing heal to damage." % entity_name)
		take_damage(amount, PFDamage.Type.VOID)
		return

	current_hp += amount
	current_hp = mini(max_hp, current_hp) 
	print("%s heals %d! HP: %d/%d" % [entity_name, amount, current_hp, max_hp])

func take_damage(amount: int, damage_type: PFDamage.Type = PFDamage.Type.UNTYPED, effect_traits: Array[StringName] = []) -> void:
	var type_name = PFDamage.get_type_name(damage_type)
	
	if has_trait(&"construct") and (damage_type == PFDamage.Type.VITALITY or damage_type == PFDamage.Type.VOID):
		print("    > %s is a Construct and ignores Vitality/Void effects." % entity_name)
		return

	var has_void_healing = has_trait(&"undead") or has_trait(&"void_healing")
	
	if damage_type == PFDamage.Type.VITALITY and not has_void_healing:
		print("    > %s is a living creature and immune to Vitality damage." % entity_name)
		return
	elif damage_type == PFDamage.Type.VOID and has_void_healing:
		print("    > %s absorbs the Void damage as healing!" % entity_name)
		heal(amount, PFDamage.Type.VOID)
		return

	if immunities.has(damage_type):
		print("    > %s is IMMUNE to %s damage! They take 0 damage." % [entity_name, type_name])
		return

	var final_damage = amount

	var total_weakness_damage = 0
	if weaknesses.has(damage_type):
		total_weakness_damage += weaknesses[damage_type]
		print("    > Weakness to %s adds %d damage!" % [type_name, weaknesses[damage_type]])
	
	for t in effect_traits:
		if trait_weaknesses.has(t):
			total_weakness_damage += trait_weaknesses[t]
			print("    > Weakness to '%s' adds %d damage!" % [t, trait_weaknesses[t]])
			
	if total_weakness_damage > 0:
		final_damage += total_weakness_damage
		print("    > Total Weakness Bonus Applied: +%d damage!" % total_weakness_damage)

	var highest_resistance = 0
	if resistances.has(damage_type):
		highest_resistance = resistances[damage_type]
		
	for t in effect_traits:
		if trait_resistances.has(t):
			highest_resistance = maxi(highest_resistance, trait_resistances[t])
			
	if highest_resistance > 0:
		final_damage -= highest_resistance
		print("    > RESISTANCE triggered! Reduces damage by %d!" % highest_resistance)

	final_damage = maxi(0, final_damage)
	
	if final_damage == 0:
		print("    > The attack deals no damage to %s." % entity_name)
		return

	# ---------------------------------------------------------
	# SHIELD BLOCK REACTION INTERCEPT
	# ---------------------------------------------------------
	var has_raised_shield = false
	for c in conditions:
		if c is PFConditionRaisedShield and c.is_active:
			has_raised_shield = true
			break
			
	var is_blockable = equipped_shield != null and (equipped_shield.can_block(damage_type) or bonus_blockable_types.has(damage_type))
			
	if is_blockable and has_raised_shield and reactions_remaining > 0 and auto_shield_block and not equipped_shield.is_destroyed():
		reactions_remaining -= 1
		print("\n    >>> REACTION: %s uses SHIELD BLOCK! <<<" % entity_name)
		
		var shield_hardness = equipped_shield.hardness
		var damage_through_shield = maxi(0, final_damage - shield_hardness)
		
		equipped_shield.take_item_damage(final_damage)
		final_damage = damage_through_shield
		
		if final_damage == 0:
			print("    > The Shield completely absorbed the impact!")
			return

	if temp_hp > 0:
		if temp_hp >= final_damage:
			temp_hp -= final_damage
			print("%s's Temp HP absorbs %d damage! (Temp HP left: %d)" % [entity_name, final_damage, temp_hp])
			final_damage = 0
		else:
			print("%s's Temp HP absorbs %d damage, but the shield shatters!" % [entity_name, temp_hp])
			final_damage -= temp_hp
			temp_hp = 0
			
	if final_damage > 0:
		current_hp -= final_damage
		current_hp = maxi(0, current_hp) 
		print(">> %s takes %d final %s damage! HP: %d/%d\n" % [entity_name, final_damage, type_name, current_hp, max_hp])
