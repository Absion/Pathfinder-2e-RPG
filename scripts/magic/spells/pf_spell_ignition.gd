# pf_spell_ignition.gd
class_name PFIgnitionSpell
extends PFSpell

func _init(p_id: StringName = &"mock_ignition"):
	super._init(p_id)

func resolve_effect(_caster: PFActor, target: PFActor, degree: PFDice.Degree, rank: int) -> void:
	# Calculate heightened increments
	var increments = 0
	if scaling_rules > 0 and rank > base_spell_rank:
		increments = floor((rank - base_spell_rank) / float(scaling_rules))
		
	var final_damage_dice = damage_dice + (increments * scaling_dice)
	
	# 1. Base Damage Resolution
	if degree == PFDice.Degree.SUCCESS or degree == PFDice.Degree.CRIT_SUCCESS:
		var multiplier = 2.0 if degree == PFDice.Degree.CRIT_SUCCESS else 1.0
		var total_damage = 0
		for i in range(final_damage_dice): total_damage += PFDice.roll(1, die_faces).total
		total_damage = floor(total_damage * multiplier)
		print("    > %s deals %d %s damage to %s (Multiplier: %s)" % [entity_name, total_damage, PFCombatConstants.DamageType.keys()[damage_type], target.entity_name, multiplier])
		target.take_damage(total_damage, damage_type)
		
	# 2. Custom Persistent Damage Logic (Critical Hit only)
	if degree == PFDice.Degree.CRIT_SUCCESS:
		# Persistent damage heightened scales identically: +1d4 per increment
		var persistent_dice = 1 + increments
		print("    > Ignition ignites the target! They take %dd4 Persistent Fire damage." % persistent_dice)
		# Assuming we have a condition system, we would apply the condition here:
		# var condition = PFPersistentDamageCondition.new(PFCombatConstants.DamageType.FIRE, persistent_dice, 4)
		# target.apply_condition(condition)
