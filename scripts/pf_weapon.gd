# pf_weapon.gd
class_name PFWeapon
extends PFEntity

enum WeaponType { MELEE, RANGED }
enum Category { UNARMED, SIMPLE, MARTIAL, ADVANCED }
enum Group { BRAWLING, SWORD, BOW, KNIFE, CLUB, SPEAR, AXE, POLEARM, FLURRY, FIREARM, DART, SLING, SHIELD, NONE }

var weapon_type: WeaponType
var category: Category
var group: Group

var dice_amount: int
var die_faces: int
var base_damage_type: PFDamage.Type
var active_damage_type: PFDamage.Type # The damage type currently being used

# Advanced Traits
var deadly_die: int
var fatal_die: int

func _init(p_name: String, p_traits: Array[StringName], 
		p_type: WeaponType, p_category: Category, p_group: Group,
		p_dice_amount: int, p_die_faces: int, p_damage_type: PFDamage.Type,
		p_deadly_die: int = 0, p_fatal_die: int = 0):
	
	super._init(p_name, p_traits)
	
	weapon_type = p_type
	category = p_category
	group = p_group
	
	dice_amount = p_dice_amount
	die_faces = p_die_faces
	base_damage_type = p_damage_type
	active_damage_type = p_damage_type # Defaults to base
	
	deadly_die = p_deadly_die
	fatal_die = p_fatal_die

# This is what you would call when a player clicks a UI button to switch their grip
func set_versatile_type(new_type: PFDamage.Type) -> void:
	if new_type == base_damage_type:
		active_damage_type = base_damage_type
		return
		
	# Check if they possess the correct trait to make the switch
	var is_valid = false
	if new_type == PFDamage.Type.SLASHING and has_trait(&"versatile_s"): is_valid = true
	elif new_type == PFDamage.Type.BLUDGEONING and has_trait(&"versatile_b"): is_valid = true
	elif new_type == PFDamage.Type.PIERCING and has_trait(&"versatile_p"): is_valid = true
	
	if is_valid:
		active_damage_type = new_type
		print("[%s] Grip shifted! Now dealing %s damage." % [entity_name, PFDamage.get_type_name(new_type)])
	else:
		push_error("Weapon does not have the required versatile trait to switch to " + PFDamage.get_type_name(new_type))
