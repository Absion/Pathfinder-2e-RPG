# pf_item.gd
## Base class for all physical items in the game world.
class_name PFItem
extends PFEntity # Force Reparse

var item_material: PFEquipmentConstants.ItemMaterial
var grade: PFEquipmentConstants.MaterialGrade

var level: int
var base_level: int
var is_wielded: bool = false # NEW: Tracks if the item is in a hand or stowed
var is_weapon: bool = false

var size: PFBiographyConstants.Size = PFBiographyConstants.Size.MEDIUM

# --- ECONOMY ---
# The absolute source of truth for the item's value (1 gp = 100 cp)
var price_cp: int
var base_price_cp: int

# --- INVENTORY & WEIGHT ---
# 10 Units = 1 Bulk, 1 Unit = 1 Light Bulk, 0 = Negligible
var bulk_value: int
var base_bulk_value: int
# Used if this item is a container (e.g. a Backpack ignores the first 2 Bulk / 20 units inside it)
var bulk_reduction_value: int = 0 

# --- DURABILITY ---
var hardness: int
var max_hp: int
var current_hp: int
var broken_threshold: int

# --- MAGIC PROPERTIES ---
var requires_investment: bool = false # NEW

# Updated Constructor
func _init(p_name: String = "", p_traits: Array[StringName] = [], p_level: int = 1, p_price_gp: float = 0.0, 
		   p_material: PFEquipmentConstants.ItemMaterial = PFEquipmentConstants.ItemMaterial.STANDARD, p_hardness: int = 0, p_hp: int = 0, p_bt: int = 0, 
		   p_grade: PFEquipmentConstants.MaterialGrade = PFEquipmentConstants.MaterialGrade.STANDARD, p_bulk: int = 1, 
		   p_bulk_reduction: int = 0, p_requires_investment: bool = false, p_size: PFBiographyConstants.Size = PFBiographyConstants.Size.MEDIUM): # NEW
	super._init(p_name, p_traits)
	
	size = p_size
	level = p_level
	base_level = p_level
	
	requires_investment = p_requires_investment
	
	# Convert the float input safely to copper integers
	set_price_from_gp(p_price_gp)
	base_price_cp = price_cp
	
	item_material = p_material
	grade = p_grade
	
	bulk_value = p_bulk
	
	# Scale bulk natively based on the size of the item
	var eff_size = PFBiographyConstants.get_effective_size(size)
	if eff_size == 0: # Tiny
		bulk_value = int(bulk_value * 0.5)
	elif eff_size == 2: # Large
		bulk_value = bulk_value * 2
	elif eff_size >= 3: # Huge/Gargantuan
		bulk_value = bulk_value * 4
		
	base_bulk_value = bulk_value
	bulk_reduction_value = p_bulk_reduction
	
	hardness = p_hardness
	max_hp = p_hp
	current_hp = p_hp
	
	broken_threshold = p_bt if p_bt > 0 else int(max_hp / 2)

# ---------------------------------------------------------
# ECONOMY HELPERS
# ---------------------------------------------------------

func set_price_from_gp(gp_float: float) -> void:
	price_cp = int(round(gp_float * 100.0))

func get_price_string() -> String:
	return PFInventory.format_copper_to_string(price_cp)

func get_selling_price_cp() -> int:
	var multiplier = 1.0
	var eff_size = PFBiographyConstants.get_effective_size(size)
	if eff_size == 2: multiplier = 2.0
	elif eff_size >= 3: multiplier = 4.0
	# Base selling price is usually 50% of buying price.
	return int(base_price_cp * multiplier * 0.5)

# ---------------------------------------------------------
# DURABILITY & DAMAGE
# ---------------------------------------------------------

func take_item_damage(amount: int) -> void:
	if is_destroyed(): return
	
	var damage_taken = maxi(0, amount - hardness)
	
	if damage_taken > 0:
		current_hp -= damage_taken
		current_hp = maxi(0, current_hp)
		
		print("    > %s takes %d damage (Hardness %d absorbed %d). Item HP: %d/%d" % [entity_name, damage_taken, hardness, amount - damage_taken, current_hp, max_hp])
		
		if is_destroyed():
			print("    > %s is DESTROYED!" % entity_name)
		elif current_hp == broken_threshold or (current_hp < broken_threshold + damage_taken and is_broken()):
			print("    > %s is BROKEN! (-2 penalty to its stats)" % entity_name)
	else:
		print("    > %s's Hardness completely absorbed the blow." % entity_name)

func is_broken() -> bool:
	return current_hp <= broken_threshold and current_hp > 0

func is_destroyed() -> bool:
	return current_hp <= 0
