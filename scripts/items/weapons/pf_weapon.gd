# pf_weapon.gd
## Offensive equipment used to make strikes against targets.
class_name PFWeapon
extends PFItem # Force Reparse 

# Format: [Attack Bonus, RuneLevel, PriceCP, Prefix]
const POTENCY_STATS = {
	PFEquipmentConstants.PotencyRune.NONE: [0, 0, 0, ""],
	PFEquipmentConstants.PotencyRune.PLUS_ONE: [1, 2, 3500, "+1 "],      # 35.0 gp -> 3500 cp
	PFEquipmentConstants.PotencyRune.PLUS_TWO: [2, 10, 93000, "+2 "],    # 930.0 gp -> 93000 cp
	PFEquipmentConstants.PotencyRune.PLUS_THREE: [3, 16, 893500, "+3 "]  # 8935.0 gp -> 893500 cp
}

# Format: [Extra Dice, RuneLevel, PriceCP, Prefix]
const STRIKING_STATS = {
	PFEquipmentConstants.StrikingRune.NONE: [0, 0, 0, ""],
	PFEquipmentConstants.StrikingRune.STRIKING: [1, 4, 6500, "Striking "],          # 65.0 gp -> 6500 cp
	PFEquipmentConstants.StrikingRune.GREATER: [2, 12, 106500, "Greater Striking "], # 1065.0 gp -> 106500 cp
	PFEquipmentConstants.StrikingRune.MAJOR: [3, 19, 3106500, "Major Striking "]     # 31065.0 gp -> 3106500 cp
}

var weapon_type: PFEquipmentConstants.WeaponType
var category: PFEquipmentConstants.WeaponCategory
var group: PFEquipmentConstants.WeaponGroup

var potency_bonus: int = 0
var dice_amount: int
var die_faces: int
var base_damage_type: PFCombatConstants.DamageType
var active_damage_type: PFCombatConstants.DamageType 
var deadly_die: int
var fatal_die: int

# Track bases to prevent infinite stacking
var base_name: String
var base_dice_amount: int

# Updated Constructor: Added p_price_gp
func _init(p_name: String = "", p_traits: Array[StringName] = [], p_level: int = 1, p_price_gp: float = 0.0, 
		   p_weapon_type: PFEquipmentConstants.WeaponType = PFEquipmentConstants.WeaponType.MELEE, p_category: PFEquipmentConstants.WeaponCategory = PFEquipmentConstants.WeaponCategory.SIMPLE, p_group: PFEquipmentConstants.WeaponGroup = PFEquipmentConstants.WeaponGroup.NONE, 
		p_dice_amount: int = 1, p_die_faces: int = 4, p_damage_type: PFCombatConstants.DamageType = PFCombatConstants.DamageType.UNTYPED,
		p_material: PFEquipmentConstants.ItemMaterial = PFEquipmentConstants.ItemMaterial.STEEL, p_hardness: int = 5, p_hp: int = 20,
		p_deadly_die: int = 0, p_fatal_die: int = 0, 
		p_grade: PFEquipmentConstants.MaterialGrade = PFEquipmentConstants.MaterialGrade.STANDARD):
	
	super._init(p_name, p_traits, p_level, p_price_gp, p_material, p_hardness, p_hp, 0, p_grade)
	
	base_name = p_name
	base_dice_amount = p_dice_amount
	
	weapon_type = p_weapon_type
	category = p_category
	group = p_group
	dice_amount = p_dice_amount
	die_faces = p_die_faces
	base_damage_type = p_damage_type
	active_damage_type = p_damage_type 
	deadly_die = p_deadly_die
	fatal_die = p_fatal_die

func apply_fundamental_runes(potency: PFEquipmentConstants.PotencyRune, striking: PFEquipmentConstants.StrikingRune) -> void:
	var pot_stats = POTENCY_STATS[potency]
	var str_stats = STRIKING_STATS[striking]
	
	potency_bonus = pot_stats[0]
	dice_amount = base_dice_amount + str_stats[0] 
	
	level = maxi(base_level, maxi(pot_stats[1], str_stats[1]))
	
	# Update the copper price
	price_cp = base_price_cp + pot_stats[2] + str_stats[2]
	
	entity_name = pot_stats[3] + str_stats[3] + base_name
	
	# Use get_price_string() for the debug print
	print("    > %s created! [Level %d | Price: %s | Bonus: +%d | Dmg: %dd%d]" % [
		entity_name, 
		level, 
		get_price_string(), 
		potency_bonus, 
		dice_amount, 
		die_faces
	])

func set_versatile_type(new_type: PFCombatConstants.DamageType) -> void:
	if new_type == base_damage_type:
		active_damage_type = base_damage_type
		return
		
	var is_valid = false
	if new_type == PFCombatConstants.DamageType.SLASHING and has_trait(&"versatile_s"): is_valid = true
	elif new_type == PFCombatConstants.DamageType.BLUDGEONING and has_trait(&"versatile_b"): is_valid = true
	elif new_type == PFCombatConstants.DamageType.PIERCING and has_trait(&"versatile_p"): is_valid = true
	
	if is_valid: active_damage_type = new_type
	else: push_error("Weapon lacks required versatile trait.")
