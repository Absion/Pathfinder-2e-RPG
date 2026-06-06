# pf_familiar.gd
# Represents a mystical minion focused on utility rather than combat. Derived stats scale off master's level.
## Represents a magical familiar with specific abilities and masters.
class_name PFFamiliar
extends PFMinion

# --- ABILITIES ---
var familiar_abilities: Array[String] = []
var master_abilities: Array[String] = []

# --- INITIALIZATION ---
func _init(p_name: String, p_master: PFActor):
	var traits: Array[StringName] = [&"animal"] # Familiars can be animals or other types, usually tiny
	
	# Pass base stats. HP is 5 * master level. Base saves will be derived in update_stats_from_master.
	super._init(p_name, p_master, traits, p_master.level, 
		5 * p_master.level, # HP
		0, 0, 0, # Saves
		-4, 3, 0, -4, 0, 0, # Arbitrary stat array for a tiny creature
		25)
	
	size = PFBiographyConstants.Size.TINY
	update_stats_from_master()
	
# --- STATS ---
func update_stats_from_master() -> void:
	level = master.level
	health.max_hp = 5 * master.level
	health.current_hp = mini(health.current_hp, health.max_hp)
	
	# For now, derive spellcasting mod from highest mental stat of master
	var spellcasting_mod = max(master.attributes.int_mod, max(master.attributes.wis_mod, master.attributes.cha_mod))
	
	# Saves and AC usually equal master level + spellcasting mod
	attributes.fort_save.base_value = master.level + spellcasting_mod
	attributes.ref_save.base_value = master.level + spellcasting_mod
	attributes.will_save.base_value = master.level + spellcasting_mod
	
	print("    > %s updates HP (%d) and Saves to match master's spellcasting mod (+%d)." % [entity_name, health.max_hp, spellcasting_mod])
