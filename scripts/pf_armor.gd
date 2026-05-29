# pf_armor.gd
# Represents an equippable piece of armor. Inherits from PFEntity for traits (like "noisy" or "flexible").
class_name PFArmor
extends PFEntity

enum Category { UNARMORED, LIGHT, MEDIUM, HEAVY }
enum Group { UNARMORED, CLOTH, LEATHER, CHAIN, COMPOSITE, PLATE }

var category: Category
var group: Group

var ac_bonus: int
var dex_cap: int
var check_penalty: int
var speed_penalty: int
var strength_req: int

# Constructor
func _init(p_name: String, p_traits: Array[StringName], 
		p_category: Category, p_group: Group,
		p_ac_bonus: int, p_dex_cap: int,
		p_check_penalty: int = 0, p_speed_penalty: int = 0, p_strength_req: int = 0):
	
	super._init(p_name, p_traits)
	
	category = p_category
	group = p_group
	
	ac_bonus = p_ac_bonus
	dex_cap = p_dex_cap
	check_penalty = p_check_penalty
	speed_penalty = p_speed_penalty
	strength_req = p_strength_req
