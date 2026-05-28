# pf_actor.gd
# Represents any living (or undead) thing in the game.
class_name PFActor
extends PFEntity

# --- Ability Modifiers ---
var str_mod: int
var dex_mod: int
var con_mod: int
var int_mod: int
var wis_mod: int
var cha_mod: int

# --- Health & Damage Modifiers ---
var max_hp: int
var current_hp: int
var temp_hp: int = 0 

# Immunities are an Array because they don't have numerical values. You are either immune or you aren't.
var immunities: Array[PFDamage.Type] = []
# Weaknesses and Resistances are Dictionaries mapping the Damage Type to a numerical value.
# Example: { PFDamage.Type.FIRE: 5 } means "Weakness 5 to Fire"
var weaknesses: Dictionary = {} 
var resistances: Dictionary = {} 

# --- Core Stats ---
var ac: PFStat
var fort_save: PFStat
var ref_save: PFStat
var will_save: PFStat

# --- Movement Speeds (in feet) ---
var speed_land: int
var speed_fly: int
var speed_swim: int

# --- Action Economy variables ---
var actions_remaining: int = 0
var reactions_remaining: int = 0
var attack_stacks: int = 0

# Constructor
func _init(p_name: String, p_traits: Array[StringName], 
		p_hp: int, p_ac: int, p_fort: int, p_ref: int, p_will: int,
		p_str: int, p_dex: int, p_con: int, p_int: int, p_wis: int, p_cha: int,
		p_speed_land: int = 25, p_speed_fly: int = 0, p_speed_swim: int = 0):
	
	super._init(p_name, p_traits) 
	
	max_hp = p_hp
	current_hp = p_hp
	
	ac = PFStat.new(p_ac)
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

# --- Utility Functions ---
func get_modifier(ability: StringName) -> int:
	match ability:
		&"STR": return str_mod
		&"DEX": return dex_mod
		&"CON": return con_mod
		&"INT": return int_mod
		&"WIS": return wis_mod
		&"CHA": return cha_mod
		_:
			push_error("Invalid ability modifier requested: " + ability)
			return 0

func start_turn() -> void:
	actions_remaining = 3
	reactions_remaining = 1
	attack_stacks = 0 
	print("\n--- %s starts their turn! (3 Actions) ---" % entity_name)

func use_action(action: PFAction, target: PFActor = null) -> void:
	var cost_val = 0
	if action.cost == PFAction.CostType.ONE: cost_val = 1
	elif action.cost == PFAction.CostType.TWO: cost_val = 2
	elif action.cost == PFAction.CostType.THREE: cost_val = 3
	
	if actions_remaining < cost_val:
		print("%s doesn't have enough actions for %s." % [entity_name, action.entity_name])
		return
		
	actions_remaining -= cost_val
	print("[%s spends %d action(s). %d remaining]" % [entity_name, cost_val, actions_remaining])
	
	var success = action.execute(self, target)
	
	if success:
		attack_stacks += action.map_weight

func execute_subordinate_action(action: PFAction, target: PFActor = null) -> void:
	print("  > [Subordinate Action] %s performs %s" % [entity_name, action.entity_name])
	var success = action.execute(self, target)
	if success:
		attack_stacks += action.map_weight

# --- Damage & Healing Handling ---

func grant_temp_hp(amount: int) -> void:
	if amount > temp_hp:
		temp_hp = amount
		print("%s gains %d Temporary HP! (Total Temp HP: %d)" % [entity_name, amount, temp_hp])

# UPDATED: Now requires a damage type, and processes Immunity, Weakness, and Resistance!
func take_damage(amount: int, damage_type: PFDamage.Type = PFDamage.Type.UNTYPED) -> void:
	var final_damage = amount
	var type_name = PFDamage.get_type_name(damage_type)
	
	# 1. Immunity Check (Completely negates damage)
	if immunities.has(damage_type):
		print("    > %s is IMMUNE to %s damage! They take 0 damage." % [entity_name, type_name])
		return
		
	# 2. Weakness Check (Adds flat damage)
	if weaknesses.has(damage_type):
		var weak_val = weaknesses[damage_type]
		final_damage += weak_val
		print("    > %s's WEAKNESS to %s adds %d damage!" % [entity_name, type_name, weak_val])
		
	# 3. Resistance Check (Subtracts flat damage)
	if resistances.has(damage_type):
		var resist_val = resistances[damage_type]
		final_damage -= resist_val
		print("    > %s's RESISTANCE to %s reduces damage by %d!" % [entity_name, type_name, resist_val])
	
	# Ensure resistance didn't drop damage below 0
	final_damage = maxi(0, final_damage)
	
	if final_damage == 0:
		print("    > The attack deals no damage to %s." % entity_name)
		return
	
	# 4. Route through Temp HP first
	if temp_hp > 0:
		if temp_hp >= final_damage:
			temp_hp -= final_damage
			print("%s's Temp HP absorbs %d damage! (Temp HP left: %d)" % [entity_name, final_damage, temp_hp])
			final_damage = 0
		else:
			print("%s's Temp HP absorbs %d damage, but the shield shatters!" % [entity_name, temp_hp])
			final_damage -= temp_hp
			temp_hp = 0
			
	# 5. Apply remaining damage to actual HP
	if final_damage > 0:
		current_hp -= final_damage
		current_hp = maxi(0, current_hp)
		print(">> %s takes %d final %s damage! HP: %d/%d" % [entity_name, final_damage, type_name, current_hp, max_hp])

func heal(amount: int) -> void:
	current_hp += amount
	current_hp = mini(max_hp, current_hp)
	print("%s heals %d! HP: %d/%d" % [entity_name, amount, current_hp, max_hp])
