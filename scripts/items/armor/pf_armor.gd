# pf_armor.gd
class_name PFArmor
extends PFItem 

enum Category { UNARMORED, LIGHT, MEDIUM, HEAVY }
enum Group { UNARMORED, CLOTH, LEATHER, CHAIN, COMPOSITE, PLATE }

enum PotencyRune { NONE, PLUS_ONE, PLUS_TWO, PLUS_THREE }
enum ResilientRune { NONE, RESILIENT, GREATER, MAJOR }

# Format: [AC Bonus, RuneLevel, PriceCP, Prefix]
const POTENCY_STATS = {
	PotencyRune.NONE: [0, 0, 0, ""],
	PotencyRune.PLUS_ONE: [1, 5, 16000, "+1 "],      # 160.0 gp -> 16000 cp
	PotencyRune.PLUS_TWO: [2, 11, 106000, "+2 "],    # 1060.0 gp -> 106000 cp
	PotencyRune.PLUS_THREE: [3, 18, 2056000, "+3 "]  # 20560.0 gp -> 2056000 cp
}

# Format: [Save Bonus, RuneLevel, PriceCP, Prefix]
const RESILIENT_STATS = {
	ResilientRune.NONE: [0, 0, 0, ""],
	ResilientRune.RESILIENT: [1, 8, 34000, "Resilient "],         # 340.0 gp -> 34000 cp
	ResilientRune.GREATER: [2, 14, 434000, "Greater Resilient "], # 4340.0 gp -> 434000 cp
	ResilientRune.MAJOR: [3, 20, 4944000, "Major Resilient "]     # 49440.0 gp -> 4944000 cp
}

var category: Category
var group: Group

var resilient_bonus: int = 0
var ac_bonus: int
var dex_cap: int
var check_penalty: int
var speed_penalty: int
var strength_req: int

var base_name: String
var base_ac_bonus: int

# Updated constructor: Added p_price_gp
func _init(p_name: String, p_traits: Array[StringName], p_level: int, p_price_gp: float,
		p_category: Category, p_group: Group,
		p_ac_bonus: int, p_dex_cap: int,
		p_check_penalty: int = 0, p_speed_penalty: int = 0, p_strength_req: int = 0,
		p_material: PFItem.ItemMaterial = PFItem.ItemMaterial.STEEL, p_hardness: int = 5, p_hp: int = 20,
		p_grade: PFItem.MaterialGrade = PFItem.MaterialGrade.STANDARD):
	
	super._init(p_name, p_traits, p_level, p_price_gp, p_material, p_hardness, p_hp, 0, p_grade)
	
	base_name = p_name
	base_ac_bonus = p_ac_bonus
	
	category = p_category
	group = p_group
	ac_bonus = p_ac_bonus
	dex_cap = p_dex_cap
	check_penalty = p_check_penalty
	speed_penalty = p_speed_penalty
	strength_req = p_strength_req

func apply_fundamental_runes(potency: PotencyRune, resilient: ResilientRune) -> void:
	var pot_stats = POTENCY_STATS[potency]
	var res_stats = RESILIENT_STATS[resilient]
	
	ac_bonus = base_ac_bonus + pot_stats[0] 
	resilient_bonus = res_stats[0] 
	
	level = maxi(base_level, maxi(pot_stats[1], res_stats[1]))
	
	# Update the copper price
	price_cp = base_price_cp + pot_stats[2] + res_stats[2]
	
	entity_name = pot_stats[3] + res_stats[3] + base_name
	
	# Use our helper to show the price in a readable format
	print("    > %s created! [Level %d | Price: %s | AC: +%d | Saves: +%d]" % [
		entity_name, 
		level, 
		get_price_string(), 
		ac_bonus, 
		resilient_bonus
	])
