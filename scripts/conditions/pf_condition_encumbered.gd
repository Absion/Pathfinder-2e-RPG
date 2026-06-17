# pf_condition_encumbered.gd
## You are carrying more weight than you can manage. You're clumsy 1 and take a 10-foot penalty to all your Speeds.
class_name PFConditionEncumbered
extends PFCondition

var speed_penalty: int = -10

func on_apply(owner: PFActor) -> bool:
	print("%s becomes encumbered!" % owner.entity_name)
	
	# Apply clumsy 1
	if not owner.has_condition("clumsy"):
		var clumsy = PFCondition.create(&"clumsy", 1)
		owner.add_condition(clumsy)
	else:
		# If they are already clumsy, encumbered doesn't overwrite a higher clumsy,
		# but if they are clumsy 1, it just stacks via max().
		# For now, PF2e says you are Clumsy 1. So if they aren't clumsy, we add it.
		# If they are, it's fine.
		pass
		
	# The speed penalty will be applied dynamically in get_speed_land() by looking for "encumbered"
	# Or we can add a PFModifier if speed uses PFStat. Currently speed does not use PFStat.
	# So we just let PFActor/PFMovementComponent handle the -10 if "encumbered" is present.
	
	return true

func get_modifier(context: StringName) -> int:
	if context == &"speed":
		return speed_penalty
	return 0

func on_remove(owner: PFActor) -> void:
	print("%s is no longer encumbered." % owner.entity_name)
	
	# Clean up clumsy if it was applied by this
	# (In a full implementation, conditions track their sources so we don't remove 
	# a Clumsy condition applied by a spell, but for now we just remove it if it's 1).
	var c = owner.get_condition("clumsy")
	if c and c.value == 1:
		owner.remove_condition("clumsy")
