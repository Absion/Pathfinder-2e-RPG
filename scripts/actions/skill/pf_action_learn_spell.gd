# pf_action_learn_spell.gd
class_name PFActionLearnSpell
extends PFAction

var target_spell: PFSpell

func _init(spell: PFSpell):
	target_spell = spell
	super._init("Learn " + spell.entity_name, [&"exploration", &"manipulate"], PFCombatConstants.ActionCost.ONE_HOUR)

func get_cost_gp() -> int:
	match target_spell.base_spell_rank:
		1: return 2
		2: return 6
		3: return 16
		4: return 36
		5: return 70
		6: return 140
		7: return 300
		8: return 650
		9: return 1500
		10: return 7000
		_: return 2

func get_dc() -> int:
	match target_spell.base_spell_rank:
		1: return 15
		2: return 18
		3: return 20
		4: return 23
		5: return 26
		6: return 28
		7: return 31
		8: return 34
		9: return 36
		10: return 39
		_: return 15

func estimate(user: PFPlayerCharacter) -> Dictionary:
	var cost_gp = get_cost_gp()
	var dc = get_dc()
	var time_hours = target_spell.base_spell_rank
	
	var best_bonus = maxi(
		user.sheet.get_skill_bonus(&"arcana", user.level),
		maxi(
			user.sheet.get_skill_bonus(&"nature", user.level),
			maxi(
				user.sheet.get_skill_bonus(&"occultism", user.level),
				user.sheet.get_skill_bonus(&"religion", user.level)
			)
		)
	)
	
	# Calculate success chance on a d20 (1-20)
	var chance = 0.0
	for roll in range(1, 21):
		var total = roll + best_bonus
		var degree = PFDice.determine_success(total, dc, roll)
		if degree == PFDice.Degree.SUCCESS or degree == PFDice.Degree.CRIT_SUCCESS:
			chance += 5.0
			
	return {
		"time_hours": time_hours,
		"cost_gp": cost_gp,
		"dc": dc,
		"success_chance_pct": chance
	}

func execute(user: PFActor, _target: Variant = null) -> bool:
	if not user is PFPlayerCharacter:
		return false
		
	var player = user as PFPlayerCharacter
	var est = estimate(player)
	
	if player.inventory.gold < est["cost_gp"]:
		print("    > [ERROR] %s does not have enough GP to learn %s (Requires %s GP)" % [player.entity_name, target_spell.entity_name, est["cost_gp"]])
		return false
		
	player.inventory.gold -= est["cost_gp"]
	
	var best_bonus = maxi(
		player.sheet.get_skill_bonus(&"arcana", player.level),
		maxi(
			player.sheet.get_skill_bonus(&"nature", player.level),
			maxi(
				player.sheet.get_skill_bonus(&"occultism", player.level),
				player.sheet.get_skill_bonus(&"religion", player.level)
			)
		)
	)
	
	var d20 = PFDice.roll_d20()
	var total = d20 + best_bonus
	var degree = PFDice.determine_success(total, est["dc"], d20)
	
	if degree == PFDice.Degree.SUCCESS or degree == PFDice.Degree.CRIT_SUCCESS:
		print("    > %s rolled a %d vs DC %d and successfully learned %s! (Spent %d GP)" % [player.entity_name, total, est["dc"], target_spell.entity_name, est["cost_gp"]])
		player.spellbook.learn_spell(target_spell)
		return true
	else:
		print("    > %s rolled a %d vs DC %d and failed to learn %s. (Materials wasted, Spent %d GP)" % [player.entity_name, total, est["dc"], target_spell.entity_name, est["cost_gp"]])
		return false
