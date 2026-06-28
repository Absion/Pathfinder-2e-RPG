# pf_familiar.gd
# Represents a mystical minion focused on utility rather than combat. Derived stats scale off master's level.
## Represents a magical familiar with specific abilities and masters.
class_name PFFamiliar
extends PFMinion

# --- ABILITIES ---
var max_abilities: int = 2
var required_abilities_discount: int = 0
var familiar_abilities: Array[StringName] = []
var master_abilities: Array[StringName] = []

# --- SPECIFIC FAMILIARS ---
var is_specific_familiar: bool = false
var specific_familiar_id: StringName = &""

# --- INITIALIZATION ---
func _init(p_name: String, p_master: PFActor):
	var init_traits: Array[StringName] = [&"animal", &"minion"]
	
	super._init(p_name, p_master, init_traits, p_master.level, 5 * p_master.level, 0, 0, 0, -4, 3, 0, -4, 0, 0, 25)
	
	size_id = &"tiny"
	update_stats_from_master()
	
# --- STATS ---
func update_stats_from_master() -> void:
	level = master.level
	health.max_hp = 5 * master.level
	health.current_hp = mini(health.current_hp, health.max_hp)
	
	print("    > %s updates HP (%d)." % [entity_name, health.max_hp])

# ---------------------------------------------------------
# THE UNIFIED MATH DELEGATES (OVERRIDE)
# ---------------------------------------------------------

func _get_master_spellcasting_mod() -> int:
	if master.has_method(&"get_spellcasting_mod"):
		return master.get_spellcasting_mod()
	return 0

func get_ac() -> int:
	# Familiar AC = 10 + master's level + master's spellcasting modifier
	var base_ac = 10 + master.level + _get_master_spellcasting_mod()
	return base_ac + get_condition_modifier(&"ac")

func get_strike_bonus(weapon: PFWeapon) -> int:
	# Familiar attacks = master's level + master's spellcasting modifier
	var base_bonus = master.level + _get_master_spellcasting_mod()
	
	if weapon and weapon.is_broken():
		base_bonus -= 2
		
	return base_bonus + get_condition_modifier(&"attack")

func get_spell_dc() -> int:
	return 10 + master.level + _get_master_spellcasting_mod()

func get_spell_attack() -> int:
	return master.level + _get_master_spellcasting_mod()

func get_skill_bonus(skill: StringName) -> int:
	var base_bonus = master.level
	# Acrobatics and Stealth use level + spellcasting modifier
	if skill == &"acrobatics" or skill == &"stealth":
		base_bonus += _get_master_spellcasting_mod()
		
	return base_bonus + get_condition_modifier(&"skill")

func get_save_modifier(save_type: StringName) -> int:
	# Familiar saves = master's level + master's spellcasting modifier
	var base_save = master.level + _get_master_spellcasting_mod()
	return base_save + get_condition_modifier(&"save")

# ---------------------------------------------------------
# SPECIFIC FAMILIARS
# ---------------------------------------------------------

func apply_specific_familiar(db_id: StringName) -> bool:
	var database = PFDatabase.get_instance()
	if not database:
		push_error("PFFamiliar: Database missing.")
		return false
		
	var data = database.get_specific_familiar(db_id)
	if data.is_empty():
		return false
		
	var effective_max_abilities = max_abilities + required_abilities_discount
	if effective_max_abilities < data["required_abilities"]:
		push_warning("PFFamiliar: Master does not have enough max abilities (%d) for %s (Requires %d)." % [effective_max_abilities, data["name"], data["required_abilities"]])
		return false
		
	# Lock into specific familiar
	is_specific_familiar = true
	specific_familiar_id = db_id
	entity_name = str(data["name"])
	
	# Reset generic abilities but keep track of how many we spent
	familiar_abilities.clear()
	master_abilities.clear()
	
	if data["granted_abilities"] and data["granted_abilities"] != "":
		var parsed = JSON.parse_string(data["granted_abilities"])
		if parsed:
			for a in parsed: familiar_abilities.append(StringName(a))
			
	if data["unique_abilities"] and data["unique_abilities"] != "":
		var parsed = JSON.parse_string(data["unique_abilities"])
		if parsed:
			for a in parsed: familiar_abilities.append(StringName(a))
			
	if data["traits"] and data["traits"] != "":
		var parsed = JSON.parse_string(data["traits"])
		if parsed:
			for t in parsed: traits.append(StringName(t))
			
	print("%s is now a Specific Familiar: %s!" % [master.entity_name, entity_name])
	return true

