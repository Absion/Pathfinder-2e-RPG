# pf_armor.gd
## Protective gear granting AC bonuses and applying dex caps.
class_name PFArmor
extends PFItem 

# Format: [AC Bonus, RuneLevel, PriceCP, Prefix]
const POTENCY_STATS = {
	PFEquipmentConstants.PotencyRune.NONE: [0, 0, 0, ""],
	PFEquipmentConstants.PotencyRune.PLUS_ONE: [1, 5, 16000, "+1 "],      # 160.0 gp -> 16000 cp
	PFEquipmentConstants.PotencyRune.PLUS_TWO: [2, 11, 106000, "+2 "],    # 1060.0 gp -> 106000 cp
	PFEquipmentConstants.PotencyRune.PLUS_THREE: [3, 18, 2056000, "+3 "]  # 20560.0 gp -> 2056000 cp
}

# Format: [Save Bonus, RuneLevel, PriceCP, Prefix]
const RESILIENT_STATS = {
	PFEquipmentConstants.ResilientRune.NONE: [0, 0, 0, ""],
	PFEquipmentConstants.ResilientRune.RESILIENT: [1, 8, 34000, "Resilient "],         # 340.0 gp -> 34000 cp
	PFEquipmentConstants.ResilientRune.GREATER: [2, 14, 434000, "Greater Resilient "], # 4340.0 gp -> 434000 cp
	PFEquipmentConstants.ResilientRune.MAJOR: [3, 20, 4944000, "Major Resilient "]     # 49440.0 gp -> 4944000 cp
}

var category: PFEquipmentConstants.ArmorCategory
var group: PFEquipmentConstants.ArmorGroup

var resilient_bonus: int = 0
var ac_bonus: int
var dex_cap: int
var check_penalty: int
var speed_penalty: int
var strength_req: int

var base_name: String
var base_ac_bonus: int

var property_runes: Array[PFEquipmentConstants.PropertyRune] = []
var potency_bonus: int = 0

var attachment: PFAttachment = null
var adjustment = null # Will be typed PFAdjustment when created

# Updated constructor: Added p_price_gp
func _init(p_name: String = "", p_traits: Array[StringName] = [], p_level: int = 1, p_price_gp: float = 0.0,
		p_category: PFEquipmentConstants.ArmorCategory = PFEquipmentConstants.ArmorCategory.UNARMORED, p_group: PFEquipmentConstants.ArmorGroup = PFEquipmentConstants.ArmorGroup.UNARMORED,
		p_ac_bonus: int = 0, p_dex_cap: int = 0,
		p_check_penalty: int = 0, p_speed_penalty: int = 0, p_strength_req: int = 0,
		p_material: PFEquipmentConstants.ItemMaterial = PFEquipmentConstants.ItemMaterial.STEEL, p_hardness: int = 5, p_hp: int = 20,
		p_grade: PFEquipmentConstants.MaterialGrade = PFEquipmentConstants.MaterialGrade.STANDARD):
	
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
	
	apply_material_stats()

func apply_material_stats() -> void:
	super.apply_material_stats()
	
	if item_material == PFEquipmentConstants.ItemMaterial.MITHRAL:
		check_penalty = mini(0, check_penalty + 1)
		speed_penalty = mini(0, speed_penalty + 5)
		bulk_value = maxi(0, bulk_value - 1)
		base_bulk_value = bulk_value

func add_property_rune(rune: PFEquipmentConstants.PropertyRune) -> bool:
	if property_runes.size() >= potency_bonus:
		print("    > [ERROR] Cannot add property rune! Armor can only hold as many property runes as its potency bonus (Current limit: %d)." % potency_bonus)
		return false
		
	if property_runes.has(rune):
		print("    > [ERROR] Armor already has this property rune!")
		return false
		
	property_runes.append(rune)
	print("    > Property rune added. Total runes: %d/%d" % [property_runes.size(), potency_bonus])
	return true

func apply_fundamental_runes(potency: PFEquipmentConstants.PotencyRune, resilient: PFEquipmentConstants.ResilientRune) -> void:
	if item_material != PFEquipmentConstants.ItemMaterial.STANDARD:
		if grade == PFEquipmentConstants.MaterialGrade.LOW and (potency > PFEquipmentConstants.PotencyRune.PLUS_ONE or resilient > PFEquipmentConstants.ResilientRune.RESILIENT):
			push_error("Low-grade precious materials can only hold up to +1 potency and basic resilient runes.")
			return
		if grade == PFEquipmentConstants.MaterialGrade.STANDARD and (potency > PFEquipmentConstants.PotencyRune.PLUS_TWO or resilient > PFEquipmentConstants.ResilientRune.GREATER):
			push_error("Standard-grade precious materials can only hold up to +2 potency and greater resilient runes.")
			return

	var pot_stats = POTENCY_STATS[potency]
	var res_stats = RESILIENT_STATS[resilient]
	
	ac_bonus = base_ac_bonus + pot_stats[0] 
	potency_bonus = pot_stats[0]
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
