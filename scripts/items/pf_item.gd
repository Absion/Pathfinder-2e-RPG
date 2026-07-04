# pf_item.gd
## Base class for all physical items in the game world.
class_name PFItem
extends PFEntity # Force Reparse

var item_material: PFEquipmentConstants.ItemMaterial
var grade: PFEquipmentConstants.MaterialGrade

var level: int
var base_level: int
var carry_state: PFEquipmentConstants.CarryState = PFEquipmentConstants.CarryState.DROPPED
var stowed_container: PFItem = null # If STOWED, what container is it in?
var is_weapon: bool = false
var is_temporary: bool = false # Used for daily crafted items like infusions

var size_id: StringName = &"medium"

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
var is_specific_magic: bool = false
var granted_actions: Array[StringName] = []

func add_granted_action(action_id: StringName) -> void:
	granted_actions.append(action_id)

# Updated Constructor
func _init(p_name: String = "", p_traits: Array[StringName] = [], p_level: int = 1, p_price_gp: float = 0.0, 
		   p_material: PFEquipmentConstants.ItemMaterial = PFEquipmentConstants.ItemMaterial.STANDARD, p_hardness: int = 0, p_hp: int = 0, p_bt: int = 0, 
		   p_grade: PFEquipmentConstants.MaterialGrade = PFEquipmentConstants.MaterialGrade.STANDARD, p_bulk: int = 1, 
		   p_bulk_reduction: int = 0, p_requires_investment: bool = false, p_size_id: StringName = &"medium"): # NEW
	super._init(p_name, p_traits)
	
	size_id = p_size_id
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
	var eff_size = 1
	var pf_db = PFDatabase.get_instance()
	if pf_db:
		var size_data = pf_db.get_size_data(size_id)
		eff_size = size_data.get(&"effective_size", 1) if size_data else 1
	
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
	
	broken_threshold = p_bt if p_bt > 0 else int(max_hp / 2.0)
	
	apply_material_stats()

func apply_material_stats() -> void:
	if item_material == PFEquipmentConstants.ItemMaterial.STANDARD:
		return
		
	# Overwrite Hardness, HP, and BT based on material and grade
	match item_material:
		PFEquipmentConstants.ItemMaterial.ADAMANTINE:
			if grade == PFEquipmentConstants.MaterialGrade.LOW:
				hardness = 10; max_hp = 40
			elif grade == PFEquipmentConstants.MaterialGrade.STANDARD:
				hardness = 14; max_hp = 56
			elif grade == PFEquipmentConstants.MaterialGrade.HIGH:
				hardness = 17; max_hp = 68
		PFEquipmentConstants.ItemMaterial.COLD_IRON, PFEquipmentConstants.ItemMaterial.SILVER:
			if grade == PFEquipmentConstants.MaterialGrade.LOW:
				hardness = 5; max_hp = 20
			elif grade == PFEquipmentConstants.MaterialGrade.STANDARD:
				hardness = 9; max_hp = 36
			elif grade == PFEquipmentConstants.MaterialGrade.HIGH:
				hardness = 13; max_hp = 52
		PFEquipmentConstants.ItemMaterial.MITHRAL:
			if grade == PFEquipmentConstants.MaterialGrade.LOW:
				hardness = 5; max_hp = 20
			elif grade == PFEquipmentConstants.MaterialGrade.STANDARD:
				hardness = 9; max_hp = 36
			elif grade == PFEquipmentConstants.MaterialGrade.HIGH:
				hardness = 13; max_hp = 52
		PFEquipmentConstants.ItemMaterial.DRAGONHIDE:
			if grade == PFEquipmentConstants.MaterialGrade.STANDARD:
				hardness = 8; max_hp = 32
			elif grade == PFEquipmentConstants.MaterialGrade.HIGH:
				hardness = 12; max_hp = 48
				
	broken_threshold = int(max_hp / 2.0)
	current_hp = max_hp
	
	# Automatically inject the material name as a trait for weakness/resistance bypassing
	var mat_trait = StringName(PFEquipmentConstants.ItemMaterial.keys()[item_material].to_lower())
	if not traits.has(mat_trait):
		traits.append(mat_trait)

# ---------------------------------------------------------
# ECONOMY HELPERS
# ---------------------------------------------------------

func set_price_from_gp(gp_float: float) -> void:
	price_cp = int(round(gp_float * 100.0))

func get_price_string() -> String:
	@warning_ignore("integer_division")
	var gp = price_cp / 100
	@warning_ignore("integer_division")
	var sp = (price_cp % 100) / 10
	var cp = price_cp % 10
	var parts = []
	if gp > 0: parts.append(str(gp) + " gp")
	if sp > 0: parts.append(str(sp) + " sp")
	if cp > 0 or parts.is_empty(): parts.append(str(cp) + " cp")
	return " ".join(parts)

func get_selling_price_cp() -> int:
	var multiplier = 1.0
	var eff_size = 1
	var pf_db = PFDatabase.get_instance()
	if pf_db:
		var size_data = pf_db.get_size_data(size_id)
		eff_size = size_data.get(&"effective_size", 1) if size_data else 1
	
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
	return current_hp <= broken_threshold

func get_cost_in_gp() -> float:
	return price_cp / 100.0

func is_destroyed() -> bool:
	return current_hp <= 0
