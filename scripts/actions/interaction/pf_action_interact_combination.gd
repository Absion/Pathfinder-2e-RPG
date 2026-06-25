# pf_action_interact_combination.gd
class_name PFActionInteractCombination
extends PFAction

var weapon: PFWeapon

func _init(p_weapon: PFWeapon):
	weapon = p_weapon
	super._init("Interact (Toggle Combination Weapon)", [&"manipulate"], PFCombatConstants.ActionCost.ONE_ACTION, 1)

func execute(user: PFActor, _target: PFActor = null) -> bool:
	if not weapon:
		return false
		
	if weapon.linked_weapon_id == "" or weapon.combination_data.is_empty():
		print("    > [ERROR] This is not a valid combination weapon!")
		return false
		
	var inv = user.get(&"inventory") as PFInventory
	if inv:
		if inv.held_main_hand != weapon and inv.held_off_hand != weapon and inv.two_handed_item != weapon:
			print("    > [ERROR] You must be holding the weapon to toggle its form!")
			return false
			
	# Swap the stats
	if not weapon.is_alternate_form_active:
		print("    > Toggling %s to its alternate form..." % weapon.entity_name)
		_apply_stats_from_row(weapon.combination_data)
		weapon.is_alternate_form_active = true
	else:
		print("    > Toggling %s back to its primary form..." % weapon.entity_name)
		# To toggle back, we need to re-query the base weapon stats or store them.
		# Since the DB provides the fresh base stats, we can query it quickly.
		var db = PFDatabase.get_instance()
		if db:
			db.query("SELECT * FROM weapons WHERE name = '" + weapon.base_name + "'") # or keep original ID if stored
			if db.query_result.size() > 0:
				_apply_stats_from_row(db.query_result[0])
		weapon.is_alternate_form_active = false
		
	return true

func _apply_stats_from_row(row: Dictionary) -> void:
	weapon.weapon_type = row.get(&"weapon_type", weapon.weapon_type)
	weapon.category = row.get(&"category", weapon.category)
	weapon.group = row.get(&"group_type", weapon.group)
	
	# Read current striking bonus
	var striking_bonus = weapon.dice_amount - weapon.base_dice_amount
	
	weapon.base_dice_amount = row.get(&"damage_dice", weapon.base_dice_amount)
	weapon.dice_amount = weapon.base_dice_amount + striking_bonus
		
	# Swap stats
	weapon.die_faces = row.get(&"damage_faces", weapon.die_faces)
	weapon.base_damage_type = row.get(&"damage_type", weapon.base_damage_type)
	weapon.active_damage_type = weapon.base_damage_type
	
	weapon.range_increment = row.get(&"range_increment", 0)
	weapon.volley_range = row.get(&"volley_range", 0)
	weapon.reload_value = row.get(&"reload_value", 0)
	weapon.hands_required = row.get(&"hands_required", 1)
	weapon.ammunition_type = row.get(&"ammunition_type", 0)
	
	var traits_array: Array[StringName] = []
	if row.has(&"traits") and row["traits"] != "":
		var split = row["traits"].split(",")
		for t in split:
			traits_array.append(StringName(t.strip_edges()))
	weapon.traits = traits_array
