# pf_reaction_shield_block.gd
class_name PFReactionShieldBlock
extends RefCounted

## Condition to check if Shield Block can be used
static func condition(__trigger_actor: PFActor, event_data: Dictionary, listener: PFActor) -> bool:
	var damage = event_data.get(&"damage", 0)
	var type = event_data.get(&"type", PFCombatConstants.DamageType.UNTYPED)
	
	if damage <= 0:
		return false
		
	# Shield Block only works against Physical damage
	if type != PFCombatConstants.DamageType.BLUDGEONING and type != PFCombatConstants.DamageType.PIERCING and type != PFCombatConstants.DamageType.SLASHING:
		return false
		
	# Must have a shield equipped and raised
	var raised_cond = listener.get_condition(&"raised_shield")
	if not raised_cond or not "shield" in raised_cond:
		return false
		
	var shield = raised_cond.shield as PFShield
	if not shield or shield.is_broken():
		return false
		
	return true

## Executes the Shield Block
static func execute(__trigger_actor: PFActor, event_data: Dictionary, listener: PFActor) -> Dictionary:
	var damage = event_data.get(&"damage", 0)
	var _type = event_data.get(&"type", PFCombatConstants.DamageType.UNTYPED)
	
	var raised_cond = listener.get_condition(&"raised_shield")
	if not raised_cond or not "shield" in raised_cond:
		return event_data
		
	var shield = raised_cond.shield as PFShield
	if not shield:
		return event_data
		
	var hardness = shield.hardness
	
	print("    > [REACTION] Shield Block! Hardness %d reduces incoming damage." % hardness)
	
	# Damage is reduced by Hardness
	var remaining_damage = maxi(0, damage - hardness)
	
	# Both the shield and the player take the remaining damage
	if remaining_damage > 0:
		print("    > Shield takes %d damage!" % remaining_damage)
		shield.current_hp -= remaining_damage
		if shield.current_hp <= shield.broken_threshold:
			print("    > [WARNING] Your shield is Broken!")
			# Lower the shield automatically
			listener.remove_condition(&"raised_shield")
	
	# Mutate the event_data to pass the reduced damage back to the original strike logic
	event_data["damage"] = remaining_damage
	
	return event_data
