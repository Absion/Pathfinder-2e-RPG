# pf_condition_persistent.gd
## Deals damage automatically at the end of the actor's turn.
class_name PFConditionPersistent
extends PFCondition

var damage_type: PFCombatConstants.DamageType
var dice_amount: int
var die_faces: int

# NEW: Handles critical hits and variable DCs
var damage_multiplier: int
var recovery_dc: int 

# Updated Constructor
func _init(p_type: PFCombatConstants.DamageType, p_dice: int, p_faces: int, p_multiplier: int = 1, p_dc: int = 15):
	damage_type = p_type
	dice_amount = p_dice
	die_faces = p_faces
	damage_multiplier = p_multiplier
	recovery_dc = p_dc
	
	var type_name = PFDamage.get_type_name(damage_type)
	var condition_title = "Persistent " + type_name
	
	# The Stacking Trick: We multiply the max potential damage by the crit multiplier
	var max_damage_potential = (p_dice * p_faces) * damage_multiplier 
	
	super._init(condition_title, max_damage_potential)

# NEW: Reject the condition if the owner is immune!
func on_apply(owner: PFActor) -> bool:
	if owner.immunities.has(damage_type):
		print("    > %s is IMMUNE to %s! The persistent damage fails to take hold." % [owner.entity_name, PFDamage.get_type_name(damage_type)])
		return false
	return true

# NEW: Allows manual/immediate recovery attempts (like Assisted Recovery)
func attempt_recovery(dc: int) -> bool:
	if not is_active:
		return true # Already cured!

	var flat_check = PFDice.roll_d20()
	if flat_check >= dc:
		is_active = false
		print("    > Flat Recovery Check: %d vs DC %d (SUCCESS). The %s ends!" % [flat_check, dc, condition_name])
		return true
	else:
		print("    > Flat Recovery Check: %d vs DC %d (FAILURE). The %s continues." % [flat_check, dc, condition_name])
		return false

# Overriding the end-of-turn hook
func on_turn_end(owner: PFActor) -> void:
	var dmg_roll = PFDice.roll(dice_amount, die_faces).total
	var total_damage = dmg_roll * damage_multiplier
	
	print("\n    > [%s] triggers on %s! Rolling %sd%d x%d..." % [condition_name, owner.entity_name, dice_amount, die_faces, damage_multiplier])
	owner.take_damage(total_damage, damage_type)
	
	if owner.current_hp <= 0:
		is_active = false
		return
		
	# Call our new function using the base recovery_dc (which defaults to 15)
	attempt_recovery(recovery_dc)
