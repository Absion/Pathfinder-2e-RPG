# pf_troop.gd
## A singular entity composed of many intelligent creatures. Features specialized health tracking and area attacks.
class_name PFTroop
extends PFNpc

func _init(p_base_id: StringName, p_name: String, p_traits: Array[StringName], p_level: int,
		p_hp: int, p_fort: int, p_ref: int, p_will: int,
		p_str: int, p_dex: int, p_con: int, p_int: int, p_wis: int, p_cha: int,
		p_speed_land: int = 25, p_speed_fly: int = 0, p_speed_swim: int = 0,
		p_speed_climb: int = 0, p_speed_burrow: int = 0,
		p_description: String = "", 
		p_has_spirit: bool = true):
			
	if not p_traits.has(&"troop"):
		p_traits.append(&"troop")
		
	super._init(p_base_id, p_name, p_traits, p_level, p_hp, p_fort, p_ref, p_will, p_str, p_dex, p_con, p_int, p_wis, p_cha, p_speed_land, p_speed_fly, p_speed_swim, p_speed_climb, p_speed_burrow, p_description, p_has_spirit)
	
	# Troops are inherently immune to several conditions that target single creatures
	add_immunity(&"grabbed")
	add_immunity(&"prone")
	add_immunity(&"restrained")
	
	# NOTE: Troops natively take extra damage from area and splash damage.
	# This should be mapped by the database when constructing the Troop by adding to health.trait_weaknesses
