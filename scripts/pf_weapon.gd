# pf_weapon.gd
class_name PFWeapon
extends PFItem 

enum WeaponType { MELEE, RANGED }
enum Category { UNARMED, SIMPLE, MARTIAL, ADVANCED }
enum Group { BRAWLING, SWORD, BOW, KNIFE, CLUB, SPEAR, AXE, POLEARM, FLURRY, FIREARM, DART, SLING, SHIELD, NONE }

enum PotencyRune { NONE, PLUS_ONE, PLUS_TWO, PLUS_THREE }
enum StrikingRune { NONE, STRIKING, GREATER, MAJOR }

# Format: [Attack Bonus, RuneLevel, PriceGP, Prefix]
const POTENCY_STATS = {
	PotencyRune.NONE: [0, 0, 0.0, ""],
	PotencyRune.PLUS_ONE: [1, 2, 35.0, "+1 "],
	PotencyRune.PLUS_TWO: [2, 10, 930.0, "+2 "],
	PotencyRune.PLUS_THREE: [3, 16, 8935.0, "+3 "]
}

# Format: [Extra Dice, RuneLevel, PriceGP, Prefix]
const STRIKING_STATS = {
	StrikingRune.NONE: [0, 0, 0.0, ""],
	StrikingRune.STRIKING: [1, 4, 65.0, "Striking "],
	StrikingRune.GREATER: [2, 12, 1065.0, "Greater Striking "],
	StrikingRune.MAJOR: [3, 19, 31065.0, "Major Striking "]
}

var weapon_type: WeaponType
var category: Category
var group: Group

var potency_bonus: int = 0
var dice_amount: int
var die_faces: int
var base_damage_type: PFDamage.Type
var active_damage_type: PFDamage.Type 
var deadly_die: int
var fatal_die: int

# Track bases to prevent infinite stacking
var base_name: String
var base_dice_amount: int

# Updated Constructor: Added p_price_gp
func _init(p_name: String, p_traits: Array[StringName], p_level: int, p_price_gp: float,
		p_type: WeaponType, p_category: Category, p_group: Group,
		p_dice_amount: int, p_die_faces: int, p_damage_type: PFDamage.Type,
		p_material: PFItem.ItemMaterial = PFItem.ItemMaterial.STEEL, p_hardness: int = 5, p_hp: int = 20,
		p_deadly_die: int = 0, p_fatal_die: int = 0, 
		p_grade: PFItem.MaterialGrade = PFItem.MaterialGrade.STANDARD):
	
	super._init(p_name, p_traits, p_level, p_price_gp, p_material, p_hardness, p_hp, 0, p_grade)
	
	base_name = p_name
	base_dice_amount = p_dice_amount
	
	weapon_type = p_type
	category = p_category
	group = p_group
	dice_amount = p_dice_amount
	die_faces = p_die_faces
	base_damage_type = p_damage_type
	active_damage_type = p_damage_type 
	deadly_die = p_deadly_die
	fatal_die = p_fatal_die

func apply_fundamental_runes(potency: PotencyRune, striking: StrikingRune) -> void:
	var pot_stats = POTENCY_STATS[potency]
	var str_stats = STRIKING_STATS[striking]
	
	potency_bonus = pot_stats[0]
	dice_amount = base_dice_amount + str_stats[0] # Striking automatically adds dice!
	
	level = maxi(base_level, maxi(pot_stats[1], str_stats[1]))
	price_gp = base_price_gp + pot_stats[2] + str_stats[2]
	
	entity_name = pot_stats[3] + str_stats[3] + base_name
	print("    > %s created! [Level %d | Price: %s gp | Bonus: +%d | Dmg: %dd%d]" % [entity_name, level, price_gp, potency_bonus, dice_amount, die_faces])

func set_versatile_type(new_type: PFDamage.Type) -> void:
	if new_type == base_damage_type:
		active_damage_type = base_damage_type
		return
		
	var is_valid = false
	if new_type == PFDamage.Type.SLASHING and has_trait(&"versatile_s"): is_valid = true
	elif new_type == PFDamage.Type.BLUDGEONING and has_trait(&"versatile_b"): is_valid = true
	elif new_type == PFDamage.Type.PIERCING and has_trait(&"versatile_p"): is_valid = true
	
	if is_valid: active_damage_type = new_type
	else: push_error("Weapon lacks required versatile trait.")
