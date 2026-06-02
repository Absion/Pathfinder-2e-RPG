# pf_actor.gd
class_name PFActor
extends PFEntity

enum Size { TINY, SMALL, MEDIUM, LARGE, HUGE, GARGANTUAN }
enum Vision { NORMAL, LOW_LIGHT, DARKVISION }

enum Gender { UNKNOWN, MALE, FEMALE, NON_BINARY, CONSTRUCT }
enum Region { UNKNOWN, LINVARRE, ABSALOM, ANDORAN, CHELIAX, TALDOR, QADIRA }

# --- COMPONENTS ---
var sheet: PFProficiencySheet
var inventory: PFInventory

# --- LORE & BACKGROUND ---
var description: String
var gender: Gender = Gender.UNKNOWN
var birthplace: Region = Region.UNKNOWN
var nationality: Region = Region.UNKNOWN
var languages: Array[PFLanguage.Type] = []
var ancestry: PFAncestry
var bonus_language_slots: int = 0
var available_bonus_languages: Array[PFLanguage.Type] = []

# --- BIOMETRICS & SENSES ---
var size: Size = Size.MEDIUM
var vision: Vision = Vision.NORMAL
var senses: Array[PFSense] = []

# --- ARCHITECTURE ---
var is_monster: bool
var monster_stats: Dictionary = {} 
#For testing TODO Remove
var auto_shield_block: bool = true 
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
var weaknesses: Dictionary = {} 
var resistances: Dictionary = {} 
var trait_weaknesses: Dictionary = {} 
var trait_resistances: Dictionary = {} 
var fort_save: PFStat
var ref_save: PFStat
var will_save: PFStat

# --- MOVEMENT ---
var speed_land: int
var speed_fly: int
var speed_swim: int
var speed_climb: int 
var speed_burrow: int

# --- ACTION ECONOMY ---
var actions_remaining: int = 0
var reactions_remaining: int = 1
var attack_stacks: int = 0 

func _init(p_name: String, p_traits: Array[StringName], p_level: int, p_is_monster: bool,
		p_hp: int, p_fort: int, p_ref: int, p_will: int,
		p_str: int, p_dex: int, p_con: int, p_int: int, p_wis: int, p_cha: int,
		p_speed_land: int = 25, p_speed_fly: int = 0, p_speed_swim: int = 0,
		p_speed_climb: int = 0, p_speed_burrow: int = 0,
		p_description: String = "", 
		p_gender: Gender = Gender.UNKNOWN, 
		p_birthplace: Region = Region.UNKNOWN, 
		p_nationality: Region = Region.UNKNOWN):
	
	super._init(p_name, p_traits) 
	is_monster = p_is_monster
	description = p_description
	gender = p_gender
	birthplace = p_birthplace
	nationality = p_nationality
	
	sheet = PFProficiencySheet.new(p_level)
	inventory = PFInventory.new(self)
	
	max_hp = p_hp
	current_hp = p_hp
	
	# Default Senses
	senses.append_array([
		PFSense.new(PFSense.Type.VISION, PFSense.Acuity.PRECISE),
		PFSense.new(PFSense.Type.TOUCH, PFSense.Acuity.PRECISE),
		PFSense.new(PFSense.Type.HEARING, PFSense.Acuity.IMPRECISE),
		PFSense.new(PFSense.Type.SCENT, PFSense.Acuity.VAGUE),
		PFSense.new(PFSense.Type.TASTE, PFSense.Acuity.VAGUE)
	])
	
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
	speed_climb = p_speed_climb
	speed_burrow = p_speed_burrow

# ---------------------------------------------------------
# DATA SETTERS & BACKGROUND
# ---------------------------------------------------------

func set_description(new_description: String) -> void:
	description = new_description

func set_biography(new_gender: Gender, new_birthplace: Region, new_nationality: Region) -> void:
	gender = new_gender
	birthplace = new_birthplace
	nationality = new_nationality
	print("    > %s's biography updated: Gender [%s], Birthplace [%s], Nationality [%s]." % [
		entity_name, 
		Gender.keys()[gender], 
		Region.keys()[birthplace], 
		Region.keys()[nationality]
	])

func apply_ancestry(new_ancestry: PFAncestry) -> void:
	ancestry = new_ancestry
	
	max_hp += ancestry.hp 
	current_hp = max_hp
	size = ancestry.size
	
# Apply all inherited movement speeds
	speed_land = ancestry.speed
	if ancestry.speed_fly > 0:
		speed_fly = ancestry.speed_fly
	if ancestry.speed_swim > 0:
		speed_swim = ancestry.speed_swim
	if ancestry.speed_climb > 0:
		speed_climb = ancestry.speed_climb
	if ancestry.speed_burrow > 0:
		speed_burrow = ancestry.speed_burrow
		
	vision = ancestry.vision
	
	# NEW: Feed the Ancestry's special granted items straight into the inventory
	for item in ancestry.granted_items:
		inventory.add_item(item)
	
	# NEW: Grant starting wealth!
	if ancestry.starting_gold > 0:
		inventory.add_currency(ancestry.starting_gold)
	
	# NEW: In the future, this is where you would process granted_abilities
	# for ability in ancestry.granted_abilities:
	#     add_ability(ability)
	
	for sense in ancestry.additional_senses:
		grant_sense(sense.type, sense.acuity, sense.range_ft)
	
	for lang in ancestry.known_languages:
		if not languages.has(lang):
			languages.append(lang)
			
	bonus_language_slots = maxi(0, int_mod)
	
	available_bonus_languages = ancestry.bonus_language_options.duplicate()
	for common_lang in PFLanguage.get_all_common_languages():
		if not available_bonus_languages.has(common_lang) and not languages.has(common_lang):
			available_bonus_languages.append(common_lang)
			
	for t in ancestry.traits:
		if not traits.has(t):
			traits.append(t)
			
	print("    > %s is now a %s!" % [entity_name, ancestry.entity_name])
	
	# Optional debug prints to verify special speeds transferred correctly
	if speed_fly > 0: print("    > Gained Fly Speed: %d ft." % speed_fly)
	if speed_swim > 0: print("    > Gained Swim Speed: %d ft." % speed_swim)
	if speed_climb > 0: print("    > Gained Climb Speed: %d ft." % speed_climb)

func add_bonus_language_option(lang: PFLanguage.Type) -> void:
	if not languages.has(lang) and not available_bonus_languages.has(lang):
		available_bonus_languages.append(lang)
		print("    > %s gained access to select %s!" % [entity_name, PFLanguage.Type.keys()[lang]])

func learn_language(lang: PFLanguage.Type) -> void:
	if not languages.has(lang):
		languages.append(lang)
		print("    > %s learned %s!" % [entity_name, PFLanguage.Type.keys()[lang]])
		
		if available_bonus_languages.has(lang):
			available_bonus_languages.erase(lang)

# Safely adds a new sense or upgrades an existing one
func grant_sense(sense_type: PFSense.Type, acuity: PFSense.Acuity, range_ft: int = 0) -> void:
	# Check if the actor already has this sense
	for s in senses:
		if s.type == sense_type:
			var upgraded = false
			# Upgrade Acuity if the new one is better (Precise < Imprecise < Vague mathematically in the enum)
			if acuity < s.acuity: 
				s.acuity = acuity
				upgraded = true
			# Upgrade Range if the new one is longer (or if the new one is unlimited [0])
			if range_ft == 0 or (s.range_ft != 0 and range_ft > s.range_ft):
				s.range_ft = range_ft
				upgraded = true
				
			if upgraded:
				print("    > %s's %s upgraded to: %s" % [entity_name, PFSense.Type.keys()[sense_type], s.get_sense_string()])
			return

	# If they don't have it, add it completely fresh
	var new_sense = PFSense.new(sense_type, acuity, range_ft)
	senses.append(new_sense)
	print("    > %s gained a new sense: %s" % [entity_name, new_sense.get_sense_string()])

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
		var armor = inventory.worn_items.filter(func(i): return i is PFArmor).front()
		if not armor: armor = PFArmor.new("Unarmored", [], 0, 0.0, PFArmor.Category.UNARMORED, PFArmor.Group.UNARMORED, 0, 99)
		
		var capped_dex = mini(dex_mod, armor.dex_cap)
		base_ac += capped_dex + armor.ac_bonus + sheet.get_armor_bonus(armor.category)
		if armor.is_broken(): base_ac -= 2 
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
	
	# Check inventory for armor or shields with speed penalties
	for item in inventory.worn_items + [inventory.held_main_hand, inventory.held_off_hand]:
		if item != null and item.has_method("get_speed_penalty"): # Or just check 'is PFArmor or PFShield'
			var penalty = item.speed_penalty
			if penalty < 0:
				if item is PFArmor and str_mod >= item.strength_req:
					penalty = mini(0, penalty + 5)
				current_speed += penalty
		
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
	# 1. Identify active shield
	var wielded_shield = [inventory.held_main_hand, inventory.held_off_hand, inventory.two_handed_item].filter(func(i): return i is PFShield and i.is_wielded).front()
			
	# 2. Shield Block Check
	var has_raised_shield = conditions.any(func(c): return c is PFConditionRaisedShield and c.is_active)
			
	if wielded_shield and wielded_shield.can_block(damage_type) and has_raised_shield and reactions_remaining > 0 and auto_shield_block and not wielded_shield.is_destroyed():
		reactions_remaining -= 1
		var damage_through_shield = maxi(0, final_damage - wielded_shield.hardness)
		wielded_shield.take_item_damage(final_damage)
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
