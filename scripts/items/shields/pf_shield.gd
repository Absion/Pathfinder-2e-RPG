# pf_shield.gd
class_name PFShield
extends PFItem

enum ReinforcingRune { NONE, MINOR, LESSER, MODERATE, GREATER, MAJOR, SUPREME }

# Format: { RuneTier: [HardnessBonus, HPBonus, BTBonus, "Prefix", RuneLevel, PriceCP] }
const RUNE_STATS = {
	ReinforcingRune.NONE: [0, 0, 0, "", 0, 0],
	ReinforcingRune.MINOR: [3, 44, 22, "Minor Reinforcing ", 4, 7500],       # 75.0 gp -> 7500 cp
	ReinforcingRune.LESSER: [5, 76, 38, "Lesser Reinforcing ", 7, 34000],    # 340.0 gp -> 34000 cp
	ReinforcingRune.MODERATE: [7, 108, 54, "Moderate Reinforcing ", 10, 100000], # 1000.0 gp -> 100000 cp
	ReinforcingRune.GREATER: [10, 132, 66, "Greater Reinforcing ", 13, 300000], # 3000.0 gp -> 300000 cp
	ReinforcingRune.MAJOR: [13, 164, 82, "Major Reinforcing ", 16, 1000000],   # 10000.0 gp -> 1000000 cp
	ReinforcingRune.SUPREME: [15, 196, 98, "Supreme Reinforcing ", 19, 4000000] # 40000.0 gp -> 4000000 cp
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

func _init(p_name: String = "", p_level: int = 1, p_price_gp: float = 0.0, p_ac_bonus: int = 0, 
		   p_hardness: int = 0, p_hp: int = 0, p_bt: int = 0, p_speed_penalty: int = 0, 
		   p_material: PFItem.ItemMaterial = PFItem.ItemMaterial.WOOD, 
		   p_grade: PFItem.MaterialGrade = PFItem.MaterialGrade.STANDARD,
		   p_extra_blockable_types: Array[PFDamage.Type] = []): # NEW
	
	super._init(p_name, [], p_level, p_price_gp, p_material, p_hardness, p_hp, p_bt, p_grade)
	
	ac_bonus = p_ac_bonus
	speed_penalty = p_speed_penalty
	
	base_name = p_name
	base_hardness = p_hardness
	base_max_hp = p_hp
	base_broken_threshold = broken_threshold 
	
	for d_type in p_extra_blockable_types:
		add_blockable_type(d_type)

# Helper to add types dynamically (e.g., from Feats or Enchantments)
func add_blockable_type(d_type: PFDamage.Type) -> void:
	if not blockable_damage_types.has(d_type):
		blockable_damage_types.append(d_type)

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
	
	# Update the copper price
	price_cp = base_price_cp + stats[5]
	
	entity_name = stats[3] + base_name
	
	# Use get_price_string() for the debug print
	print("    > %s created! [Level %d | Price: %s | Hardness: %d | HP: %d]" % [
		entity_name, 
		level, 
		get_price_string(), 
		hardness, 
		max_hp
	])

func get_bash_weapon() -> PFWeapon:
	# The PFWeapon constructor receives 0.0, 
	# which set_price_from_gp() will correctly convert to 0 cp.
	return PFWeapon.new(entity_name + " Bash", [&"agile"], level, 0.0,
		PFWeapon.WeaponType.MELEE, PFWeapon.Category.MARTIAL, PFWeapon.Group.SHIELD, 
		1, 4, PFDamage.Type.BLUDGEONING, 
		item_material, hardness, max_hp, 0, 0, grade)
