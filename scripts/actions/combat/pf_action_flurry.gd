# pf_action_flurry.gd
# Validates using the new strict Weapon Category and Group Enums.
## Implements the Monk's Flurry of Blows action, allowing two strikes for one action.
class_name PFActionFlurry
extends PFAction

var weapon: PFWeapon
var has_monastic_weaponry: bool
var in_monastic_archer_stance: bool

func _init(p_weapon: PFWeapon, p_has_monastic_weaponry: bool = false, p_in_monastic_archer_stance: bool = false):
	super._init("Flurry of Blows", [&"flourish"], PFCombatConstants.ActionCost.ONE_ACTION)
	weapon = p_weapon
	has_monastic_weaponry = p_has_monastic_weaponry
	in_monastic_archer_stance = p_in_monastic_archer_stance

func execute(user: PFActor, target: Variant = null) -> bool:
	if target == null:
		return false
		
	var is_valid = false
	var error_message = ""
		
	# --- STRICT ENUM VALIDATION BRANCHING ---
	
	if in_monastic_archer_stance:
		# We check the strict Group Enum rather than an arbitrary trait
		var is_bow_group = weapon.group == PFEquipmentConstants.WeaponGroup.BOW
		var is_specific_bow = weapon.entity_name == "Longbow" or weapon.entity_name == "Shortbow"
		var is_monk_bow = is_bow_group and weapon.has_trait(&"monk")
		
		if is_specific_bow or is_monk_bow:
			is_valid = true
		else:
			error_message = "Rules Violation: In Monastic Archer Stance, you can only use Longbows, Shortbows, or Bows with the Monk trait."
			
	else:
		# We check the strict Category Enum for Unarmed attacks
		var is_unarmed_category = weapon.category == PFEquipmentConstants.WeaponCategory.UNARMED
		var is_valid_monk_weapon = weapon.has_trait(&"monk") and has_monastic_weaponry
		
		if is_unarmed_category or is_valid_monk_weapon:
			is_valid = true
		else:
			error_message = "Rules Violation: Flurry of Blows requires an Unarmed weapon, or a monk weapon combined with the Monastic Weaponry feat."
			
	# --- EXECUTION ---
	
	if not is_valid:
		print("    > [ERROR] " + error_message)
		return false
		
	print("%s unleashes a Flurry of Blows using their %s!" % [user.entity_name, weapon.entity_name])
	
	var subordinate_strike = PFActionStrike.new(weapon) 
	await user.execute_subordinate_action(subordinate_strike, target)
	await user.execute_subordinate_action(subordinate_strike, target)
	
	return true
