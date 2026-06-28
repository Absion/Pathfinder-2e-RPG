extends Node
class_name PFConditionManager

static var _instance: PFConditionManager

static func get_instance() -> PFConditionManager:
	return _instance

func _enter_tree() -> void:
	if _instance == null:
		_instance = self
	else:
		push_warning("PFConditionManager already exists, freeing duplicate.")
		queue_free()

func _exit_tree() -> void:
	if _instance == self:
		_instance = null

# ---------------------------------------------------------
# TURN HOOKS (DURATION & TICKING)
# ---------------------------------------------------------

func tick_turn_started(actor: PFActor) -> void:
	# Tick durations down and execute start-of-turn hooks
	for i in range(actor.conditions.size() - 1, -1, -1):
		var c = actor.conditions[i]
		if c.is_active:
			c.on_turn_start(actor)
			
			if c.duration_turns > 0:
				c.duration_turns -= 1
				if c.duration_turns <= 0:
					c.is_active = false
					print("    > [%s] has expired on %s!" % [c.condition_name, actor.entity_name])
	
	_cleanup_inactive_conditions(actor)

func tick_turn_ended(actor: PFActor) -> void:
	# Execute end-of-turn hooks (Persistent Damage, Afflictions)
	for i in range(actor.conditions.size() - 1, -1, -1):
		var c = actor.conditions[i]
		if c.is_active:
			c.on_turn_end(actor)
			
	_cleanup_inactive_conditions(actor)

func _cleanup_inactive_conditions(actor: PFActor) -> void:
	var needs_cleanup = true
	while needs_cleanup:
		needs_cleanup = false
		for i in range(actor.conditions.size() - 1, -1, -1):
			if not actor.conditions[i].is_active:
				var c = actor.conditions[i]
				actor.conditions.remove_at(i)
				c.on_remove(actor)
				print("%s is no longer %s!" % [actor.entity_name, c.condition_name])
				needs_cleanup = true
				break

# ---------------------------------------------------------
# CONDITION MODIFICATION API
# ---------------------------------------------------------

func apply_condition(actor: PFActor, new_condition: PFCondition) -> void:
	# Check if condition already exists
	for c in actor.conditions:
		if c.condition_id == new_condition.condition_id:
			# Condition exists. Max stacking rule.
			if new_condition.value > c.value:
				c.value = new_condition.value
				print("%s %s worsened to %d!" % [actor.entity_name, c.condition_name, c.value])
			else:
				print("%s is already %s %d or higher." % [actor.entity_name, c.condition_name, c.value])
				
			# Refresh duration if the new one is longer or permanent
			if new_condition.duration_turns == -1 or new_condition.duration_turns > c.duration_turns:
				c.duration_turns = new_condition.duration_turns
			return
			
	if not new_condition.on_apply(actor):
		return

	actor.conditions.append(new_condition)
	print("%s is now %s %d!" % [actor.entity_name, new_condition.condition_name, new_condition.value])

func remove_condition(actor: PFActor, condition_id: StringName) -> void:
	for i in range(actor.conditions.size() - 1, -1, -1):
		if actor.conditions[i].condition_id == condition_id:
			actor.conditions[i].is_active = false
			_cleanup_inactive_conditions(actor)
			return

func reduce_condition(actor: PFActor, condition_id: StringName, amount: int = 1) -> void:
	for i in range(actor.conditions.size() - 1, -1, -1):
		if actor.conditions[i].condition_id == condition_id:
			actor.conditions[i].value -= amount
			if actor.conditions[i].value <= 0:
				actor.conditions[i].is_active = false
				_cleanup_inactive_conditions(actor)
			else:
				print("%s's %s reduced to %d." % [actor.entity_name, actor.conditions[i].condition_name, actor.conditions[i].value])
			return

func has_condition(actor: PFActor, condition_id: StringName) -> bool:
	for c in actor.conditions:
		if c.condition_id == condition_id and c.is_active:
			return true
	return false

func get_condition(actor: PFActor, condition_id: StringName) -> PFCondition:
	for c in actor.conditions:
		if c.condition_id == condition_id and c.is_active:
			return c
	return null

func get_condition_modifier(actor: PFActor, context: StringName) -> int:
	var highest_status_bonus = 0
	var highest_circumstance_bonus = 0
	var highest_item_bonus = 0
	
	var highest_status_penalty = 0
	var highest_circumstance_penalty = 0
	var highest_item_penalty = 0
	
	var untyped_sum = 0
	
	for c in actor.conditions:
		if c.is_active:
			var modifier = c.get_modifier(context)
			if modifier == 0: continue
			
			if c.modifier_type == "status":
				if modifier > 0: highest_status_bonus = maxi(highest_status_bonus, modifier)
				else: highest_status_penalty = mini(highest_status_penalty, modifier)
			elif c.modifier_type == "circumstance":
				if modifier > 0: highest_circumstance_bonus = maxi(highest_circumstance_bonus, modifier)
				else: highest_circumstance_penalty = mini(highest_circumstance_penalty, modifier)
			elif c.modifier_type == "item":
				if modifier > 0: highest_item_bonus = maxi(highest_item_bonus, modifier)
				else: highest_item_penalty = mini(highest_item_penalty, modifier)
			else:
				untyped_sum += modifier
				
	return highest_status_bonus + highest_circumstance_bonus + highest_item_bonus + \
		   highest_status_penalty + highest_circumstance_penalty + highest_item_penalty + \
		   untyped_sum
