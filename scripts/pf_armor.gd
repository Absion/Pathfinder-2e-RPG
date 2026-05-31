# pf_armor.gd
class_name PFArmor
extends PFItem 

enum Category { UNARMORED, LIGHT, MEDIUM, HEAVY }
enum Group { UNARMORED, CLOTH, LEATHER, CHAIN, COMPOSITE, PLATE }

enum PotencyRune { NONE, PLUS_ONE, PLUS_TWO, PLUS_THREE }
enum ResilientRune { NONE, RESILIENT, GREATER, MAJOR }

# Format: [AC Bonus, RuneLevel, PriceGP, Prefix]
const POTENCY_STATS = {
	PotencyRune.NONE: [0, 0, 0.0, ""],
	PotencyRune.PLUS_ONE: [1, 5, 160.0, "+1 "],
	PotencyRune.PLUS_TWO: [2, 11, 1060.0, "+2 "],
	PotencyRune.PLUS_THREE: [3, 18, 20560.0, "+3 "]
}

# Format: [Save Bonus, RuneLevel, PriceGP, Prefix]
const RESILIENT_STATS = {
	ResilientRune.NONE: [0, 0, 0.0, ""],
	ResilientRune.RESILIENT: [1, 8, 340.0, "Resilient "],
	ResilientRune.GREATER: [2, 14, 4340.0, "Greater Resilient "],
	ResilientRune.MAJOR: [3, 20, 49440.0, "Major Resilient "]
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
	
	ac_bonus = base_ac_bonus + pot_stats[0] # Upgrades AC globally!
	resilient_bonus = res_stats[0] # Ready for when we build Saving Throws!
	
	level = maxi(base_level, maxi(pot_stats[1], res_stats[1]))
	price_gp = base_price_gp + pot_stats[2] + res_stats[2]
	
	entity_name = pot_stats[3] + res_stats[3] + base_name
	print("    > %s created! [Level %d | Price: %s gp | AC: +%d | Saves: +%d]" % [entity_name, level, price_gp, ac_bonus, resilient_bonus])
