# pf_npc.gd
## An enemy or friendly non-player character, scaling via Game Master Guide monster rules.
class_name PFNpc
extends PFActor

# --- COMPONENTS ---
var attributes: PFAttributesComponent
var movement: PFMovementComponent
var senses: PFSensesComponent
var inventory: PFInventory
var spellbook: PFSpellbook

# --- NPC STATS ---
var monster_stats: Dictionary = {}
var size_id: StringName = &"medium"
var npc_spell_dc: int = 10
var npc_spell_attack: int = 0
var description: String = ""

func _init(p_name: String, p_traits: Array[StringName], p_level: int,
		p_hp: int, p_fort: int, p_ref: int, p_will: int,
		p_str: int, p_dex: int, p_con: int, p_int: int, p_wis: int, p_cha: int,
		p_speed_land: int = 25, p_speed_fly: int = 0, p_speed_swim: int = 0,
		p_speed_climb: int = 0, p_speed_burrow: int = 0,
		p_description: String = "", 
		p_has_spirit: bool = true):
			
	# Call PFActor initialization
	super._init(p_name, p_traits, p_level, p_hp)
	
	has_spirit = p_has_spirit
	description = p_description
	
	attributes = PFAttributesComponent.new()
	attributes.initialize(p_fort, p_ref, p_will, p_str, p_dex, p_con, p_int, p_wis, p_cha)
	add_child(attributes)
	
	movement = PFMovementComponent.new()
	movement.initialize(p_speed_land, p_speed_fly, p_speed_swim, p_speed_climb, p_speed_burrow)
	add_child(movement)
	
	senses = PFSensesComponent.new()
	senses.initialize()
	add_child(senses)
	
	inventory = PFInventory.new(self)
	spellbook = PFSpellbook.new(self)

# ---------------------------------------------------------
# THE UNIFIED MATH DELEGATES
# ---------------------------------------------------------

func get_ac() -> int:
	var base_ac = monster_stats.get("ac", 10)
	return base_ac + get_condition_modifier(&"ac")

func get_strike_bonus(weapon: PFWeapon) -> int:
	var base_bonus = monster_stats.get("attack", 0)
	
	if weapon and weapon.is_broken():
		base_bonus -= 2
		
	return base_bonus + get_condition_modifier(&"attack")

func get_class_dc() -> int:
	return monster_stats.get("dc", 10)

func get_spell_dc() -> int:
	return npc_spell_dc

func get_spell_attack() -> int:
	return npc_spell_attack

func get_strike_damage_bonus(weapon: PFWeapon) -> int:
	var dmg_bonus = monster_stats.get("damage", attributes.str_mod) 
		
	if weapon and weapon.is_broken():
		dmg_bonus -= 2
		
	return dmg_bonus

func get_skill_bonus(skill: StringName) -> int:
	var base_bonus = monster_stats.get(skill, 0)
	return base_bonus + get_condition_modifier(&"skill")

func get_ability_modifier(ability: StringName) -> int:
	match ability:
		&"STR": return attributes.str_mod
		&"DEX": return attributes.dex_mod
		&"CON": return attributes.con_mod
		&"INT": return attributes.int_mod
		&"WIS": return attributes.wis_mod
		&"CHA": return attributes.cha_mod
		_: return 0

func get_speed_land() -> int:
	var current_speed = movement.speed_land
	
	for item in inventory.worn_items + [inventory.held_main_hand, inventory.held_off_hand]:
		if item != null and "speed_penalty" in item:
			var penalty = item.speed_penalty
			if penalty < 0:
				if item is PFArmor and attributes.str_mod >= item.strength_req:
					penalty = mini(0, penalty + 5)
				current_speed += penalty
		
	current_speed += get_condition_modifier(&"speed")
	return maxi(5, current_speed)

func get_wielded_shield() -> PFShield:
	if inventory.held_off_hand is PFShield:
		return inventory.held_off_hand
	if inventory.held_main_hand is PFShield:
		return inventory.held_main_hand
	return null
