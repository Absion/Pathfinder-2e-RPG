# pf_weapon.gd
## Offensive equipment used to make strikes against targets.
class_name PFWeapon
extends PFItem

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

# --- NEW PROPERTIES ---
var range_increment: int = 0
var volley_range: int = 0
var reload_value: int = 0
var hands_required: int = 1
var ammunition_type: PFEquipmentConstants.AmmunitionType = PFEquipmentConstants.AmmunitionType.NONE
var is_improvised: bool = false
var is_loaded: bool = false
var attachment: PFAttachment = null
var adjustment = null # Will be typed PFAdjustment when created
var property_runes: Array[PFEquipmentConstants.PropertyRune] = []

var linked_weapon_id: String = ""
var combination_data: Dictionary = {}
var is_alternate_form_active: bool = false
var injection_payload: PFItem = null

# Updated Constructor
func _init(p_name: String = "", p_traits: Array[StringName] = [], p_level: int = 1, p_price_gp: float = 0.0, 
		   p_weapon_type: PFEquipmentConstants.WeaponType = PFEquipmentConstants.WeaponType.MELEE, p_category: PFEquipmentConstants.WeaponCategory = PFEquipmentConstants.WeaponCategory.SIMPLE, p_group: PFEquipmentConstants.WeaponGroup = PFEquipmentConstants.WeaponGroup.NONE, 
		p_dice_amount: int = 1, p_die_faces: int = 4, p_damage_type: PFCombatConstants.DamageType = PFCombatConstants.DamageType.UNTYPED,
		p_material: PFEquipmentConstants.ItemMaterial = PFEquipmentConstants.ItemMaterial.STEEL, p_hardness: int = 5, p_hp: int = 20,
		p_deadly_die: int = 0, p_fatal_die: int = 0, 
		p_grade: PFEquipmentConstants.MaterialGrade = PFEquipmentConstants.MaterialGrade.STANDARD,
		p_range: int = 0, p_volley: int = 0, p_reload: int = 0, p_hands: int = 1, p_ammo: PFEquipmentConstants.AmmunitionType = PFEquipmentConstants.AmmunitionType.NONE):
	
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
	
	range_increment = p_range
	volley_range = p_volley
	reload_value = p_reload
	hands_required = p_hands
	ammunition_type = p_ammo
	
	# If a ranged weapon with no ammo type has reload 0 (like a bow or thrown weapon), it might still be considered "loaded" always, or it draws ammo as part of the strike.
	# We'll set is_loaded to true if reload is 0 to simplify logic.
	if reload_value == 0:
		is_loaded = true
		
	# Parse thrown trait for range increment if not set
	if range_increment == 0:
		for t in traits:
			var ts = String(t)
			if ts.begins_with("thrown "):
				var parts = ts.split(" ")
				if parts.size() > 1 and parts[1].is_valid_int():
					range_increment = parts[1].to_int()

func apply_fundamental_runes(potency: PFEquipmentConstants.PotencyRune, striking: PFEquipmentConstants.StrikingRune) -> void:
	if item_material != PFEquipmentConstants.ItemMaterial.STANDARD:
		if grade == PFEquipmentConstants.MaterialGrade.LOW and (potency > PFEquipmentConstants.PotencyRune.PLUS_ONE or striking > PFEquipmentConstants.StrikingRune.STRIKING):
			push_error("Low-grade precious materials can only hold up to +1 potency and basic striking runes.")
			return
		if grade == PFEquipmentConstants.MaterialGrade.STANDARD and (potency > PFEquipmentConstants.PotencyRune.PLUS_TWO or striking > PFEquipmentConstants.StrikingRune.GREATER):
			push_error("Standard-grade precious materials can only hold up to +2 potency and greater striking runes.")
			return

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

func add_property_rune(rune: PFEquipmentConstants.PropertyRune) -> bool:
	if property_runes.size() >= potency_bonus:
		print("    > [ERROR] Cannot add property rune! A weapon can only hold as many property runes as its potency bonus (Current limit: %d)." % potency_bonus)
		return false
		
	if property_runes.has(rune):
		print("    > [ERROR] Weapon already has this property rune!")
		return false
		
	property_runes.append(rune)
	print("    > Property rune added. Total runes: %d/%d" % [property_runes.size(), potency_bonus])
	return true

func set_versatile_type(new_type: PFCombatConstants.DamageType) -> void:
	if new_type == base_damage_type:
		active_damage_type = base_damage_type
		return
		
	var is_valid = false
	if new_type == PFCombatConstants.DamageType.SLASHING and has_trait(&"versatile_s"): is_valid = true
	elif new_type == PFCombatConstants.DamageType.BLUDGEONING and has_trait(&"versatile_b"): is_valid = true
	elif new_type == PFCombatConstants.DamageType.PIERCING and has_trait(&"versatile_p"): is_valid = true
	
	if not is_valid:
		for t in traits:
			var ts = String(t).to_lower()
			if ts.begins_with("modular"):
				if new_type == PFCombatConstants.DamageType.BLUDGEONING and "b" in ts: is_valid = true
				elif new_type == PFCombatConstants.DamageType.PIERCING and "p" in ts: is_valid = true
				elif new_type == PFCombatConstants.DamageType.SLASHING and "s" in ts: is_valid = true
	
	if is_valid: active_damage_type = new_type
	else: push_error("Weapon lacks required versatile or modular trait.")

func can_be_thrown() -> bool:
	for t in traits:
		if String(t).to_lower().begins_with("thrown"):
			return true
	return false

func get_thrown_range() -> int:
	for t in traits:
		var ts = String(t).to_lower()
		if ts.begins_with("thrown_"):
			var parts = ts.split("_")
			if parts.size() > 1 and parts[1].is_valid_int():
				return parts[1].to_int()
	return 0
