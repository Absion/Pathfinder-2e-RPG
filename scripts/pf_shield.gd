# pf_shield.gd
class_name PFShield
extends PFItem

enum ReinforcingRune { NONE, MINOR, LESSER, MODERATE, GREATER, MAJOR, SUPREME }

# Format: { RuneTier: [Hardness, HP, BT, "Prefix", RuneLevel, PriceGP] }
const RUNE_STATS = {
	ReinforcingRune.NONE: [0, 0, 0, "", 0, 0.0],
	ReinforcingRune.MINOR: [3, 44, 22, "Minor Reinforcing ", 4, 75.0],
	ReinforcingRune.LESSER: [5, 76, 38, "Lesser Reinforcing ", 7, 340.0],
	ReinforcingRune.MODERATE: [7, 108, 54, "Moderate Reinforcing ", 10, 1000.0],
	ReinforcingRune.GREATER: [10, 132, 66, "Greater Reinforcing ", 13, 3000.0],
	ReinforcingRune.MAJOR: [13, 164, 82, "Major Reinforcing ", 16, 10000.0],
	ReinforcingRune.SUPREME: [15, 196, 98, "Supreme Reinforcing ", 19, 40000.0]
}

var ac_bonus: int
var speed_penalty: int

var blockable_damage_types: Array[PFDamage.Type] = [
	PFDamage.Type.SLASHING, 
	PFDamage.Type.BLUDGEONING, 
	PFDamage.Type.PIERCING
]

var base_name: String
var active_rune: ReinforcingRune = ReinforcingRune.NONE
var base_hardness: int
var base_max_hp: int
var base_broken_threshold: int

func _init(p_name: String, p_level: int, p_price_gp: float, p_ac_bonus: int, p_hardness: int, p_hp: int, p_bt: int = 0, p_speed_penalty: int = 0, p_material: PFItem.ItemMaterial = PFItem.ItemMaterial.WOOD, p_grade: PFItem.MaterialGrade = PFItem.MaterialGrade.STANDARD):
	
	super._init(p_name, [], p_level, p_price_gp, p_material, p_hardness, p_hp, p_bt, p_grade)
	
	ac_bonus = p_ac_bonus
	speed_penalty = p_speed_penalty
	
	base_name = p_name
	base_hardness = p_hardness
	base_max_hp = p_hp
	base_broken_threshold = broken_threshold 

func can_block(damage_type: PFDamage.Type) -> bool:
	return damage_type in blockable_damage_types

func apply_reinforcing_rune(rune: ReinforcingRune) -> void:
	active_rune = rune
	var stats = RUNE_STATS[rune]
	
	hardness = base_hardness + stats[0]
	max_hp = base_max_hp + stats[1]
	broken_threshold = base_broken_threshold + stats[2]
	current_hp = max_hp 
	
	level = maxi(base_level, stats[4])
	price_gp = base_price_gp + stats[5]
	
	entity_name = stats[3] + base_name
	
	print("    > %s created! [Level %d | Price: %s gp | Hardness: %d | HP: %d]" % [entity_name, level, price_gp, hardness, max_hp])

func get_bash_weapon() -> PFWeapon:
	# FIX: Added 0.0 as the 4th argument so the weapon correctly processes the gold cost!
	return PFWeapon.new(entity_name + " Bash", [&"agile"], level, 0.0,
		PFWeapon.WeaponType.MELEE, PFWeapon.Category.MARTIAL, PFWeapon.Group.SHIELD, 
		1, 4, PFDamage.Type.BLUDGEONING, 
		item_material, hardness, max_hp, 0, 0, grade)
