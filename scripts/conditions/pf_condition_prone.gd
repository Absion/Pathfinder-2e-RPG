# pf_condition_prone.gd
extends PFCondition

func on_apply(owner: PFActor) -> bool:
	if not owner.has_condition("off_guard"):
		var off_guard = PFCondition.create(&"off_guard")
		owner.apply_condition(off_guard)
	return super(owner)

func on_remove(owner: PFActor) -> void:
	# Taking the stand action removes this condition
	owner.remove_condition("off_guard")
	super(owner)
