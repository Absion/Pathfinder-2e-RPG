# pf_condition_dying.gd
extends PFCondition

func on_apply(owner: PFActor) -> bool:
	if owner.has_condition("unconscious"):
		# Dying always puts you unconscious
		pass
	else:
		var unconscious = PFCondition.create(&"unconscious")
		owner.apply_condition(unconscious)
		
	# Death logic check
	var doomed_val = 0
	if owner.has_condition("doomed"):
		doomed_val = owner.get_condition("doomed").value
		
	# If dying value reaches (4 - doomed_val), the actor dies.
	if self.value >= (4 - doomed_val):
		# Trigger death
		print("%s has died!" % owner.entity_name)
		if owner.health:
			owner.health.died.emit()
		# A real implementation would trigger a signal on the owner
		
	return super(owner)
