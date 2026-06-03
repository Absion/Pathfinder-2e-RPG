# pf_familiar.gd
# Represents a mystical minion focused on utility rather than combat. Derived stats scale off master's level.
class_name PFFamiliar
extends PFMinion

# --- ABILITIES ---
var familiar_abilities: Array[String] = []
var master_abilities: Array[String] = []

# --- INITIALIZATION ---
func _init(p_name: String, p_master: PFActor):
	var traits: Array[StringName] = [&"animal"] # Familiars can be animals or other types, usually tiny
	
	# Pass base stats. HP is 5 * master level. Base saves will be derived in update_stats_from_master.
	super._init(p_name, p_master, traits, p_master.sheet.level, true, 
		5 * p_master.sheet.level, # HP
		0, 0, 0, # Saves
		-4, 3, 0, -4, 0, 0, # Arbitrary stat array for a tiny creature
		25)
	
	size = Size.TINY
	update_stats_from_master()
	
# --- STATS ---
func update_stats_from_master() -> void:
	sheet.level = master.sheet.level
	max_hp = 5 * master.sheet.level
	current_hp = mini(current_hp, max_hp)
	
	# For now, derive spellcasting mod from highest mental stat of master
	var spellcasting_mod = max(master.int_mod, max(master.wis_mod, master.cha_mod))
	
	# Saves and AC usually equal master level + spellcasting mod
	fort_save.base_value = master.sheet.level + spellcasting_mod
	ref_save.base_value = master.sheet.level + spellcasting_mod
	will_save.base_value = master.sheet.level + spellcasting_mod
	
	print("    > %s updates HP (%d) and Saves to match master's spellcasting mod (+%d)." % [entity_name, max_hp, spellcasting_mod])
