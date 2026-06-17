# pf_action_activate_item.gd
## Action to activate a permanent item (wands, staves, rings).
class_name PFActionActivateItem
extends PFAction

var item: PFEquipment

func _init(p_item: PFEquipment):
	super._init("Activate " + p_item.entity_name, [&"manipulate"], PFCombatConstants.ActionCost.ONE_ACTION)
	item = p_item

func execute(user: PFActor, target: PFActor = null) -> Variant:
	# 1. Check for Reactive Strikes
	if await check_trait_triggers(user):
		print("    > [DISRUPTED] %s's attempt to activate %s was disrupted!" % [user.entity_name, item.entity_name])
		return false
		
	# 2. Check Investment
	if item.requires_investment and not user.inventory.invested_items.has(item):
		print("    > [ERROR] %s must be invested before it can be activated!" % item.entity_name)
		return false
		
	# 3. Check Cooldown
	if item.usage_cooldown != "" and item.usage_cooldown != "unlimited":
		# Ideally this would check PFTimeManager to see if the cooldown has elapsed.
		# For now, we simulate checking.
		pass
		
	print("    > %s activates %s!" % [user.entity_name, item.entity_name])
	
	# 4. Execute custom logic script if available
	if item.action_script_path != "":
		var custom_script = load(item.action_script_path)
		if custom_script:
			# If the script has an execute method, we call it.
			var inst = custom_script.new()
			if inst.has_method("execute_effect"):
				inst.execute_effect(user, target, item)
			else:
				print("    > [WARNING] %s has no execute_effect method!" % item.action_script_path)
				
	return true
