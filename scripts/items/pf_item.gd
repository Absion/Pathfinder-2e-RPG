# pf_item.gd
class_name PFItem
extends PFEntity

enum ItemMaterial { STANDARD, WOOD, IRON, STEEL, COLD_IRON, SILVER, ADAMANTINE, MITHRAL, DRAGONHIDE, ORICHALCUM }
enum MaterialGrade { LOW, STANDARD, HIGH }

var item_material: ItemMaterial
var grade: MaterialGrade

var level: int
var base_level: int
var is_wielded: bool = false # NEW: Tracks if the item is in a hand or stowed
var is_weapon: bool = false

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
		   p_material: ItemMaterial = ItemMaterial.STANDARD, p_hardness: int = 0, p_hp: int = 0, p_bt: int = 0, 
		   p_grade: MaterialGrade = MaterialGrade.STANDARD, p_bulk: int = 1, 
		   p_bulk_reduction: int = 0, p_requires_investment: bool = false): # NEW
	super._init(p_name, p_traits)
	
	level = p_level
	base_level = p_level
	
	requires_investment = p_requires_investment
	
	# Convert the float input safely to copper integers
	set_price_from_gp(p_price_gp)
	base_price_cp = price_cp
	
	item_material = p_material
	grade = p_grade
	
	bulk_value = p_bulk
	base_bulk_value = p_bulk
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
