# pf_item.gd
class_name PFItem
extends PFEntity

enum ItemMaterial { STANDARD, WOOD, IRON, STEEL, COLD_IRON, SILVER, ADAMANTINE, MITHRAL, DRAGONHIDE, ORICHALCUM }
enum MaterialGrade { LOW, STANDARD, HIGH }

var item_material: ItemMaterial
var grade: MaterialGrade

var level: int
var base_level: int

var price_gp: float
var base_price_gp: float

var hardness: int
var max_hp: int
var current_hp: int
var broken_threshold: int

# Updated Constructor: p_price_gp added!
func _init(p_name: String, p_traits: Array[StringName], p_level: int, p_price_gp: float, p_material: ItemMaterial, p_hardness: int, p_hp: int, p_bt: int = 0, p_grade: MaterialGrade = MaterialGrade.STANDARD):
	super._init(p_name, p_traits)
	
	level = p_level
	base_level = p_level
	price_gp = p_price_gp
	base_price_gp = p_price_gp
	
	item_material = p_material
	grade = p_grade
	hardness = p_hardness
	max_hp = p_hp
	current_hp = p_hp
	
	broken_threshold = p_bt if p_bt > 0 else int(max_hp / 2)

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
