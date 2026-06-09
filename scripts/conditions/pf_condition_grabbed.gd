# pf_condition_grabbed.gd
extends PFCondition

func on_apply(owner: PFActor) -> bool:
	if not owner.has_condition("off_guard"):
		var off_guard = PFCondition.create(&"off_guard")
		owner.apply_condition(off_guard)
		
	if not owner.has_condition("immobilized"):
		var immobilized = PFCondition.create(&"immobilized")
		owner.apply_condition(immobilized)
		
	return super(owner)

func on_remove(owner: PFActor) -> void:
	# Note: In a real system we'd use reference counting or source tracking.
	# For now, we assume if Grabbed falls off, we remove these.
	owner.remove_condition("immobilized")
	# Off-guard might be from flanking, but removing it directly is safe for prototype.
	owner.remove_condition("off_guard")
	super(owner)
