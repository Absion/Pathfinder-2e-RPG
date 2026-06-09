# pf_condition_unconscious.gd
extends PFCondition

func on_apply(owner: PFActor) -> bool:
	if not owner.has_condition("prone"):
		var prone = PFCondition.create(&"prone")
		owner.apply_condition(prone)
		
	if not owner.has_condition("off_guard"):
		var off_guard = PFCondition.create(&"off_guard")
		owner.apply_condition(off_guard)
		
	if not owner.has_condition("blinded"):
		var blinded = PFCondition.create(&"blinded")
		owner.apply_condition(blinded)
		
	return super(owner)

func on_remove(owner: PFActor) -> void:
	owner.remove_condition("blinded")
	# Off-guard and prone might stay, but we clean them up for now
	owner.remove_condition("off_guard")
	super(owner)
