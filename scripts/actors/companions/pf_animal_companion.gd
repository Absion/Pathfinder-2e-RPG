# pf_animal_companion.gd
# Represents a combat-capable animal minion with derived stats scaling from its master.
## Represents an animal companion bound to a player character.
class_name PFAnimalCompanion
extends PFMinion

# --- LORE & BACKGROUND ---
var companion_type: String

# --- INITIALIZATION ---
func _init(p_name: String, p_master: PFActor, p_type: String, p_level: int,
		p_hp: int, p_fort: int, p_ref: int, p_will: int,
		p_str: int, p_dex: int, p_con: int, p_int: int, p_wis: int, p_cha: int,
		p_speed_land: int = 25):
	
	var traits: Array[StringName] = [&"animal"]
	
	super._init(p_name, p_master, traits, p_level, p_hp, p_fort, p_ref, p_will, p_str, p_dex, p_con, p_int, p_wis, p_cha, p_speed_land)
	companion_type = p_type
	
# --- MINION ACTIONS ---
func support_benefit() -> void:
	if action_economy.actions_remaining > 0:
		action_economy.actions_remaining -= 1
		print("    > %s uses their %s Support Benefit!" % [entity_name, companion_type])
	else:
		print("    > %s has no actions left to Support." % entity_name)

func advanced_maneuver() -> void:
	if action_economy.actions_remaining > 0:
		action_economy.actions_remaining -= 1
		print("    > %s uses their %s Advanced Maneuver!" % [entity_name, companion_type])
	else:
		print("    > %s has no actions left for Advanced Maneuver." % entity_name)

# --- STATS ---
func update_stats_from_master() -> void:
	# Companion scales with master level
	level = master.level
	print("    > %s updates stats to match master's level %d." % [entity_name, level])
