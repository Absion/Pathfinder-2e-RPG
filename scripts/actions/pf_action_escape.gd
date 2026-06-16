# pf_action_escape.gd
## Allows a grabbed, immobilized, or restrained actor to roll an attack to break free.
class_name PFActionEscape
extends PFAction

func _init():
	super._init("Escape", [&"attack"], PFCombatConstants.ActionCost.ONE_ACTION)

func execute(user: PFActor, _target: PFActor = null) -> bool:
	if not super.execute(user, null): return false
	
	var highest_dc = 0
	var grabbed_cond = user.get_condition("grabbed")
	if grabbed_cond and grabbed_cond.source_dc > highest_dc:
		highest_dc = grabbed_cond.source_dc
		
	var restrained_cond = user.get_condition("restrained")
	if restrained_cond and restrained_cond.source_dc > highest_dc:
		highest_dc = restrained_cond.source_dc
		
	# In PF2e, Immobilized normally doesn't have an Escape unless explicitly stated (usually Grapple).
	# But just in case:
	var immob_cond = user.get_condition("immobilized")
	if immob_cond and immob_cond.source_dc > highest_dc:
		highest_dc = immob_cond.source_dc
		
	if highest_dc == 0:
		print("    > [ERROR] %s is not Grabbed or Restrained, or the DC is 0!" % user.entity_name)
		# We don't return false because they technically wasted the action trying to escape nothing.
		# Actually, standard rules say you can't use the action if you aren't grabbed.
		return false
		
	# You can use unarmed attack modifier, Acrobatics, or Athletics.
	var unarmed_mod = user.get_strike_bonus(PFWeapon.new_unarmed())
	var acro_mod = user.get_skill_bonus(&"acrobatics")
	var ath_mod = user.get_skill_bonus(&"athletics")
	
	var best_mod = maxi(unarmed_mod, maxi(acro_mod, ath_mod))
	
	# Apply MAP (Multiple Attack Penalty)
	var map_penalty = 0
	if user.action_economy.attack_stacks == 1:
		map_penalty = -5
	elif user.action_economy.attack_stacks >= 2:
		map_penalty = -10
		
	# Note: Unarmed attacks might be agile (-4/-8), but Acrobatics/Athletics are rarely agile unless specifically stated.
	# For simplicity, we use the standard MAP.
	
	var total_mod = best_mod + map_penalty
	var roll = PFDice.roll(1, 20).total + total_mod
	
	print("    > %s attempts to Escape (Mod: +%d, MAP: %d). Roll: %d vs DC %d" % [
		user.entity_name, best_mod, map_penalty, roll, highest_dc
	])
	
	var degree = PFGameMath.get_degree_of_success(roll, highest_dc)
	
	if degree >= PFCombatConstants.DegreeOfSuccess.SUCCESS:
		print("    > Escape Successful!")
		if grabbed_cond: user.remove_condition("grabbed")
		if restrained_cond: user.remove_condition("restrained")
		if immob_cond: user.remove_condition("immobilized")
		
		if degree == PFCombatConstants.DegreeOfSuccess.CRITICAL_SUCCESS:
			print("    > Critical Success! You can stride up to 5 feet.")
			# Mechanics for the free stride would be handled by UI prompting for movement.
	else:
		print("    > Escape Failed.")
		if degree == PFCombatConstants.DegreeOfSuccess.CRITICAL_FAILURE:
			print("    > Critical Failure! You cannot attempt to escape again this turn.")
			# Not mechanically enforced yet, but good for logs.
			
	user.action_economy.increment_attack()
	return true
