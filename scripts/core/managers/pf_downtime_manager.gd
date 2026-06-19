# pf_downtime_manager.gd
class_name PFDowntimeManager
extends Node

## Tracks active downtime activities for actors
## Dictionary: { actor: { type: "crafting", days_remaining: 2, data: {} } }
var active_tasks: Dictionary = {}

func _ready() -> void:
	if PFTimeManager.get_instance():
		PFTimeManager.get_instance().day_passed.connect(_on_day_passed)
		
func _on_day_passed() -> void:
	var completed_actors = []
	
	for actor in active_tasks.keys():
		var task = active_tasks[actor]
		task.days_remaining -= 1
		
		if task.days_remaining <= 0:
			_complete_task(actor, task)
			completed_actors.append(actor)
			
	for actor in completed_actors:
		active_tasks.erase(actor)
		actor.set_meta(&"is_busy", false)
		
func begin_crafting(actor: PFActor, item_id: StringName, item_level: int) -> bool:
	if actor.get_meta(&"is_busy", false):
		print("    > [Downtime] %s is already busy." % actor.entity_name)
		return false
		
	# Needs to be at least Trained in Crafting (ignoring specific feats for basic backend mock)
	var crafting_rank = actor.sheet.get_skill_rank(&"crafting")
	if crafting_rank < PFMathConstants.ProficiencyRank.TRAINED:
		print("    > [Downtime] %s fails to start Crafting (requires Trained in Crafting)." % actor.entity_name)
		return false
		
	# Roll Crafting check vs Item Level DC
	var dc = PFGameMath.get_dc_by_level(item_level)
	var roll = PFDice.roll(1, 20).total + actor.get_skill_bonus(&"crafting")
	var degree = PFGameMath.get_degree_of_success(roll, dc)
	
	if degree == PFCombatConstants.DegreeOfSuccess.CRITICAL_FAILURE:
		print("    > [Downtime] %s critically failed to craft %s (ruined materials)." % [actor.entity_name, item_id])
		return false
		
	var days = 2
	if degree == PFCombatConstants.DegreeOfSuccess.CRITICAL_SUCCESS:
		days = 1
		
	print("    > [Downtime] %s starts Crafting %s. Setup takes %d days." % [actor.entity_name, item_id, days])
	
	active_tasks[actor] = {
		"type": "crafting",
		"days_remaining": days,
		"data": { "item": item_id, "degree": degree }
	}
	actor.set_meta(&"is_busy", true)
	return true
	
func begin_earn_income(actor: PFActor, skill: StringName, task_level: int, days: int) -> bool:
	if actor.get_meta(&"is_busy", false): return false
	if days <= 0: return false
	
	print("    > [Downtime] %s starts Earn Income (%s) for %d days." % [actor.entity_name, skill, days])
	
	active_tasks[actor] = {
		"type": "earn_income",
		"days_remaining": days,
		"data": { "skill": skill, "task_level": task_level }
	}
	actor.set_meta(&"is_busy", true)
	return true
	
func begin_retraining(actor: PFActor, swap_out: StringName, swap_in: StringName, days: int) -> bool:
	if actor.get_meta(&"is_busy", false): return false
	if days <= 0: return false
	
	print("    > [Downtime] %s starts Retraining (%s -> %s) for %d days." % [actor.entity_name, swap_out, swap_in, days])
	
	active_tasks[actor] = {
		"type": "retraining",
		"days_remaining": days,
		"data": { "out": swap_out, "in": swap_in }
	}
	actor.set_meta(&"is_busy", true)
	return true
	
func _complete_task(actor: PFActor, task: Dictionary) -> void:
	match task.type:
		"crafting":
			var item = task.data.item
			print("    > [Downtime] %s has successfully finished crafting %s!" % [actor.entity_name, item])
			# Would add to inventory and deduct remaining gold
		"earn_income":
			var skill = task.data.skill
			var t_level = task.data.task_level
			# Roll check
			var dc = PFGameMath.get_dc_by_level(t_level)
			var roll = PFDice.roll(1, 20).total + actor.get_skill_bonus(skill)
			var degree = PFGameMath.get_degree_of_success(roll, dc)
			
			if degree >= PFCombatConstants.DegreeOfSuccess.SUCCESS:
				# Arbitrary gold reward for the mock
				var gold = t_level * 5
				if degree == PFCombatConstants.DegreeOfSuccess.CRITICAL_SUCCESS: gold *= 2
				print("    > [Downtime] %s successfully earned %d gold!" % [actor.entity_name, gold])
				actor.inventory.copper_pieces += gold * 100 # converting to copper
			else:
				print("    > [Downtime] %s failed to earn any income." % actor.entity_name)
		"retraining":
			print("    > [Downtime] %s finished retraining %s into %s!" % [actor.entity_name, task.data.out, task.data.in])
			# Logic to update progression_history and actor traits
