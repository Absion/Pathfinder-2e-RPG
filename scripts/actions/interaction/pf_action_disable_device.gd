# pf_action_disable_device.gd
## Allows a character to attempt to disable a hazard using a specific skill.
class_name PFActionDisableDevice
extends PFAction

# The specific skill chosen by the user to roll against the hazard
var selected_skill: StringName = &"thievery"

func _init():
	# Usually takes 2 actions
	super._init("Disable a Device", [&"manipulate"], PFCombatConstants.ActionCost.TWO_ACTIONS)

func execute(user: PFActor, target: PFActor = null) -> bool:
	if not super.execute(user, target): return false
	
	if not target or not target is PFHazard:
		print("    > [Disable a Device] You can only use this on a Hazard!")
		return false
		
	var hazard: PFHazard = target
	
	if hazard.is_disabled or hazard.is_destroyed:
		print("    > [Disable a Device] %s is already disabled or destroyed." % hazard.entity_name)
		return false
		
	# Find the DC for the selected skill
	var target_dc = -1
	for method in hazard.disable_methods:
		if method.get(&"skill", &"") == selected_skill:
			target_dc = method.get(&"dc", 10)
			break
			
	if target_dc == -1:
		print("    > [Disable a Device] You cannot use %s to disable %s!" % [str(selected_skill).capitalize(), hazard.entity_name])
		return false
		
	var modifier = user.get_skill_bonus(selected_skill)
	var roll = PFDice.roll(1, 20).total + modifier
	print("    > %s rolls %s to Disable %s: %d vs DC %d" % [user.entity_name, str(selected_skill).capitalize(), hazard.entity_name, roll, target_dc])
	
	var degree = PFGameMath.get_degree_of_success(roll, target_dc)
	hazard.attempt_disable(selected_skill, degree)
	
	return true
