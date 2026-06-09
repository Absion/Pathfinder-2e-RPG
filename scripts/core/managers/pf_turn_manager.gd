# pf_turn_manager.gd
## Manages combat initiative, turn order, and round tracking.
class_name PFTurnManager
extends Node

signal encounter_started
signal turn_started(actor: PFActor)
signal turn_ended(actor: PFActor)
signal round_advanced(round_number: int)

class CombatantRecord extends RefCounted:
	var actor: PFActor
	var is_enemy: bool
	var initiative_roll: int
	var initiative_modifier: int
	var initiative_skill: StringName
	var force_first: bool = false
	var force_last: bool = false
	
	func _init(p_actor: PFActor, p_is_enemy: bool = false, p_skill: StringName = &"perception"):
		actor = p_actor
		is_enemy = p_is_enemy
		initiative_skill = p_skill
		initiative_roll = 0
		initiative_modifier = 0

var combatants: Array[CombatantRecord] = []
var current_turn_index: int = -1
var round_number: int = 0
var in_encounter: bool = false

func add_combatant(actor: PFActor, is_enemy: bool = false, skill: StringName = &"perception") -> void:
	# Check if they are already in the array
	for c in combatants:
		if c.actor == actor:
			return
			
	combatants.append(CombatantRecord.new(actor, is_enemy, skill))

func roll_initiative() -> void:
	for c in combatants:
		# Base skill modifier + any specific status/circumstance bonuses to "initiative" (e.g. from Scouting)
		c.initiative_modifier = c.actor.get_skill_bonus(c.initiative_skill) + c.actor.get_condition_modifier(&"initiative")
		c.initiative_roll = randi_range(1, 20) + c.initiative_modifier
		
		# Check for feats or conditions that force first/last
		if c.actor.has_condition("initiative_first"):
			c.force_first = true
		if c.actor.has_condition("initiative_last"):
			c.force_last = true
			
		print("    > %s rolled %d for Initiative using %s" % [c.actor.entity_name, c.initiative_roll, c.initiative_skill])
		
	# Sort descending
	combatants.sort_custom(_compare_initiative)

func _compare_initiative(a: CombatantRecord, b: CombatantRecord) -> bool:
	# Force First overrides
	if a.force_first and not b.force_first: return true
	if b.force_first and not a.force_first: return false
	
	# Force Last overrides
	if a.force_last and not b.force_last: return false
	if b.force_last and not a.force_last: return true
	
	if a.initiative_roll != b.initiative_roll:
		return a.initiative_roll > b.initiative_roll
		
	if a.initiative_modifier != b.initiative_modifier:
		return a.initiative_modifier > b.initiative_modifier
		
	if a.is_enemy != b.is_enemy:
		# Enemies win ties
		return a.is_enemy
		
	# Random tie breaker if perfectly tied and same faction
	return randi() % 2 == 0

func start_encounter() -> void:
	if combatants.is_empty():
		return
		
	in_encounter = true
	round_number = 1
	current_turn_index = 0
	encounter_started.emit()
	print("--- ENCOUNTER STARTED! Round 1 ---")
	
	_start_current_turn()

func next_turn() -> void:
	if not in_encounter or combatants.is_empty():
		return
		
	var current_actor = combatants[current_turn_index].actor
	
	# End current turn
	print("--- %s ends their turn. ---" % current_actor.entity_name)
	if current_actor.has_method("end_turn"):
		current_actor.end_turn()
	turn_ended.emit(current_actor)
	
	# Advance index
	current_turn_index += 1
	
	# Round rollover
	if current_turn_index >= combatants.size():
		current_turn_index = 0
		round_number += 1
		print("--- ROUND %d ---" % round_number)
		round_advanced.emit(round_number)
		
	_start_current_turn()

func _start_current_turn() -> void:
	var current_actor = combatants[current_turn_index].actor
	print("--- %s starts their turn. ---" % current_actor.entity_name)
	
	# Fire actor's internal start turn hooks (conditions, action refresh)
	if current_actor.has_method("start_turn"):
		current_actor.start_turn()
		
	turn_started.emit(current_actor)

func get_current_actor() -> PFActor:
	if not in_encounter or current_turn_index < 0 or current_turn_index >= combatants.size():
		return null
	return combatants[current_turn_index].actor
