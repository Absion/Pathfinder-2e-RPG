# pf_npc.gd
## An enemy or friendly non-player character, scaling via Game Master Guide monster rules.
class_name PFNpc
extends PFActor

# --- DISPOSITION ---
enum Attitude {
	HOSTILE,
	UNFRIENDLY,
	INDIFFERENT,
	FRIENDLY,
	HELPFUL
}

# --- COMPONENTS ---
var attributes: PFAttributesComponent
var movement: PFMovementComponent
var senses: PFSensesComponent
var inventory: PFInventory
var spellbook: PFSpellbook

# --- NPC STATS ---
var base_id: StringName = &""
var monster_stats: Dictionary = {}
var size_id: StringName = &"medium"
var npc_spell_dc: int = 10
var npc_spell_attack: int = 0
var description: String = ""
var disposition: Attitude = Attitude.INDIFFERENT

func _init(p_base_id: StringName, p_name: String, p_traits: Array[StringName], p_level: int,
		p_hp: int, p_fort: int, p_ref: int, p_will: int,
		p_str: int, p_dex: int, p_con: int, p_int: int, p_wis: int, p_cha: int,
		p_speed_land: int = 25, p_speed_fly: int = 0, p_speed_swim: int = 0,
		p_speed_climb: int = 0, p_speed_burrow: int = 0,
		p_description: String = "", 
		p_has_spirit: bool = true):
			
	# Call PFActor initialization
	super._init(p_name, p_traits, p_level, p_hp)
	
	base_id = p_base_id
	has_spirit = p_has_spirit
	description = p_description
	
	attributes = PFAttributesComponent.new()
	attributes.is_npc = true
	attributes.initialize(p_fort, p_ref, p_will)
	# Apply raw monster stats directly as linear free boosts
	if p_str != 0:
		for i in range(abs(p_str)):
			if p_str > 0: attributes.apply_free_boost(&"str")
			else: attributes.apply_voluntary_flaw(&"str")
	if p_dex != 0:
		for i in range(abs(p_dex)):
			if p_dex > 0: attributes.apply_free_boost(&"dex")
			else: attributes.apply_voluntary_flaw(&"dex")
	if p_con != 0:
		for i in range(abs(p_con)):
			if p_con > 0: attributes.apply_free_boost(&"con")
			else: attributes.apply_voluntary_flaw(&"con")
	if p_int != 0:
		for i in range(abs(p_int)):
			if p_int > 0: attributes.apply_free_boost(&"int")
			else: attributes.apply_voluntary_flaw(&"int")
	if p_wis != 0:
		for i in range(abs(p_wis)):
			if p_wis > 0: attributes.apply_free_boost(&"wis")
			else: attributes.apply_voluntary_flaw(&"wis")
	if p_cha != 0:
		for i in range(abs(p_cha)):
			if p_cha > 0: attributes.apply_free_boost(&"cha")
			else: attributes.apply_voluntary_flaw(&"cha")
	
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
# THE UNIFIED MATH DELEGATES (OVERRIDES)
# ---------------------------------------------------------

# --- DISPOSITION LOGIC ---
func set_disposition(new_attitude: Attitude) -> void:
	if disposition != new_attitude:
		disposition = new_attitude
		print("    > [Disposition] %s is now %s towards the party." % [entity_name, Attitude.keys()[disposition]])

func set_combat_hostile() -> void:
	# Forces an NPC to become hostile when explicitly spawned into a combat scenario
	set_disposition(Attitude.HOSTILE)

func get_ac() -> int:
	var base_ac = monster_stats.get(&"ac", 10)
	for item in inventory.worn_items:
		if item is PFArmor and item.is_broken():
			base_ac -= 2
			break
	return base_ac + attributes.ac_modifiers.get_total()

func get_strike_bonus(weapon: PFWeapon) -> int:
	var base_bonus = monster_stats.get(&"attack", 0)
	
	if weapon and weapon.is_broken():
		base_bonus -= 2
		
	return base_bonus + attributes.attack_modifiers.get_total()

func get_class_dc() -> int:
	return monster_stats.get(&"dc", 10)

func get_spell_dc() -> int:
	return npc_spell_dc

func get_spell_attack() -> int:
	return npc_spell_attack

func get_save_bonus(save_type: StringName) -> int:
	var base_save = 0
	match save_type.to_lower():
		"fortitude", "fort": base_save = attributes.fort_save.get_total()
		"reflex", "ref": base_save = attributes.ref_save.get_total()
		"will": base_save = attributes.will_save.get_total()
		
	return base_save

func get_skill_dc(skill_name: StringName) -> int:
	# NPCs should ideally read this from their stat block
	return monster_stats.get(str(skill_name).to_lower() + "_dc", 10)

func get_strike_damage_bonus(weapon: PFWeapon) -> int:
	var dmg_bonus = monster_stats.get(&"damage", attributes.str_mod) 
		
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

func get_weaknesses() -> Array:
	return monster_stats.get(&"weaknesses", [])

func get_resistances() -> Array:
	return monster_stats.get(&"resistances", [])

func get_immunities() -> Array:
	return monster_stats.get(&"immunities", [])

func get_special_abilities() -> Array:
	return monster_stats.get(&"special_abilities", [])
