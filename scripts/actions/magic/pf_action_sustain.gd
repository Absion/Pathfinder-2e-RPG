# pf_action_sustain.gd
## Sustain an active spell for another turn.
class_name PFActionSustain
extends PFAction

# The spell we intend to sustain
var target_spell: PFSpell

func _init(spell: PFSpell):
	super._init("Sustain " + spell.entity_name, [&"concentrate"], PFCombatConstants.ActionCost.ONE_ACTION, 0)
	target_spell = spell

func execute(user: PFActor, target: Variant = null) -> Variant:
	if await check_trait_triggers(user):
		print("    > [DISRUPTED] Sustain action was disrupted!")
		return false
		
	var time_manager = PFContext.active_turn_manager
	if not time_manager:
		print("    > [ERROR] Cannot sustain spell outside of turn context.")
		return false
		
	if not time_manager.active_sustained_spells.has(user) or not time_manager.active_sustained_spells[user].has(target_spell):
		print("    > [ERROR] %s is not currently sustaining %s." % [user.entity_name, target_spell.entity_name])
		return false
		
	# Mark as sustained this turn
	if not time_manager.spells_sustained_this_turn.has(user):
		time_manager.spells_sustained_this_turn[user] = []
		
	if not time_manager.spells_sustained_this_turn[user].has(target_spell):
		time_manager.spells_sustained_this_turn[user].append(target_spell)
		
	target_spell.on_sustain(user, target)
	return true

