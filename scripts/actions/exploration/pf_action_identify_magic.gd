# pf_action_identify_magic.gd
## Exploration action to discover the properties of a magical item.
## Also the primary way characters discover if an item is Cursed.
class_name PFActionIdentifyMagic
extends PFAction

func _init():
	super._init("Identify Magic", [&"exploration", &"concentrate", &"secret"], PFCombatConstants.ActionCost.TEN_MINUTES)

func execute(user: PFActor, target: Variant = null) -> Variant:
	if target == null:
		print("    > [ERROR] Must target an item to Identify Magic.")
		return false
		
	# Requires Arcana, Nature, Occultism, or Religion depending on the tradition
	# For simplicity, we roll the highest of those
	var best_mod = max(
		user.proficiency_sheet.get_skill_modifier(user, &"arcana"),
		user.proficiency_sheet.get_skill_modifier(user, &"nature"),
		user.proficiency_sheet.get_skill_modifier(user, &"occultism"),
		user.proficiency_sheet.get_skill_modifier(user, &"religion")
	)
	
	var roll = randi_range(1, 20)
	var total = roll + best_mod
	
	# Assume the DC is based on the item's level (using a generic DC by level function, approximated here)
	var dc = 14 + target.level # Simple approximation
	
	var is_cursed = target.traits.has(&"cursed")
	
	print("    > %s attempts to Identify %s..." % [user.entity_name, target.entity_name])
	
	if total >= dc + 10 or roll == 20: # Critical Success
		print("    > Critical Success! (%d vs DC %d)" % [total, dc])
		if is_cursed:
			print("    > %s discovers that %s is CURSED!" % [user.entity_name, target.entity_name])
		else:
			print("    > %s perfectly identifies all properties of %s." % [user.entity_name, target.entity_name])
		return true
	elif total >= dc: # Success
		print("    > Success! (%d vs DC %d)" % [total, dc])
		if is_cursed:
			# Typical success fails to reveal curses in PF2e, giving false info
			print("    > %s identifies the basic properties, completely unaware that it is cursed..." % user.entity_name)
		else:
			print("    > %s identifies the basic properties of %s." % [user.entity_name, target.entity_name])
		return true
	elif total <= dc - 10 or roll == 1: # Critical Failure
		print("    > Critical Failure! (%d vs DC %d)" % [total, dc])
		print("    > %s misidentifies the item completely!" % user.entity_name)
		return false
	else: # Failure
		print("    > Failure! (%d vs DC %d)" % [total, dc])
		print("    > %s cannot figure out the magic of %s and cannot try again for 1 day." % [user.entity_name, target.entity_name])
		return false
