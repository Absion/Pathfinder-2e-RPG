# pf_condition_affliction.gd
class_name PFConditionAffliction
extends PFCondition

var current_stage: int = 1
var max_stage: int = 1
var save_dc: int = 10
var save_stat: StringName = &"fortitude"
var stage_interval: int = 1
var rounds_until_save: int = 1

var stages_data: Array = []
var active_sub_conditions: Array = [] # Track conditions applied by the affliction

func _init(p_id: StringName, p_initial_value: int = 1, p_source_dc: int = 0):
	var db_inst = PFDatabase.get_instance()
	var data: Dictionary = {}
	if db_inst:
		data = db_inst.get_affliction_data(p_id)
		
	if data:
		condition_name = data.get(&"name", str(p_id))
		save_dc = data.get(&"dc", 10)
		save_stat = data.get(&"saving_throw_stat", &"fortitude")
		max_stage = data.get(&"max_stage", 1)
		stage_interval = data.get(&"stage_interval", 1)
		var stages_json = data.get(&"stages", "[]")
		var parsed = JSON.parse_string(stages_json)
		if parsed != null:
			stages_data = parsed
	else:
		condition_name = str(p_id)
		
	# Afflictions don't use standard modifier logic by default, but we pass properties to super
	super._init(p_id, p_initial_value, p_source_dc)
	
	# Override if source_dc was explicitly passed (e.g., heightened spell DC)
	if p_source_dc > 0:
		save_dc = p_source_dc
		
	rounds_until_save = stage_interval
	current_stage = p_initial_value

func on_apply(owner: PFActor) -> bool:
	# When applied, immediately enact the effects of the current stage
	_apply_stage_effects(owner)
	return true

func on_remove(owner: PFActor) -> void:
	# Cleanup sub-conditions when the affliction is cured/removed
	_remove_sub_conditions(owner)

func on_turn_end(owner: PFActor) -> void:
	rounds_until_save -= 1
	if rounds_until_save <= 0:
		rounds_until_save = stage_interval
		_prompt_saving_throw(owner)

func _prompt_saving_throw(owner: PFActor) -> void:
	# Fast-forward saving throws in automation, or use the TurnManager for player prompts
	print("    > [AFFLICTION] %s must make a %s save against %s (DC %d)..." % [owner.entity_name, save_stat, condition_name, save_dc])
	
	var save_mod = owner.get_saving_throw(save_stat)
	# For automation/tests, we roll automatically.
	# In a real game, this might yield to UI.
	var roll = randi() % 20 + 1
	var total = roll + save_mod
	
	var degree = PFMathConstants.DegreeOfSuccess.FAIL
	if total >= save_dc + 10 or roll == 20:
		degree = PFMathConstants.DegreeOfSuccess.CRIT_SUCCESS
	elif total >= save_dc:
		degree = PFMathConstants.DegreeOfSuccess.SUCCESS
	elif total <= save_dc - 10 or roll == 1:
		degree = PFMathConstants.DegreeOfSuccess.CRIT_FAIL
		
	# Nat 20 bumps up one degree, Nat 1 bumps down one degree
	if roll == 20 and degree < PFMathConstants.DegreeOfSuccess.CRIT_SUCCESS:
		degree = (degree + 1) as PFMathConstants.DegreeOfSuccess
	elif roll == 1 and degree > PFMathConstants.DegreeOfSuccess.CRIT_FAIL:
		degree = (degree - 1) as PFMathConstants.DegreeOfSuccess
		
	match degree:
		PFMathConstants.DegreeOfSuccess.CRIT_SUCCESS:
			print("    > [CRIT SUCCESS] %s reduces %s by 2 stages!" % [owner.entity_name, condition_name])
			_change_stage(owner, current_stage - 2)
		PFMathConstants.DegreeOfSuccess.SUCCESS:
			print("    > [SUCCESS] %s reduces %s by 1 stage." % [owner.entity_name, condition_name])
			_change_stage(owner, current_stage - 1)
		PFMathConstants.DegreeOfSuccess.FAIL:
			print("    > [FAILURE] %s advances %s by 1 stage!" % [owner.entity_name, condition_name])
			_change_stage(owner, current_stage + 1)
		PFMathConstants.DegreeOfSuccess.CRIT_FAIL:
			print("    > [CRIT FAILURE] %s advances %s by 2 stages!!" % [owner.entity_name, condition_name])
			_change_stage(owner, current_stage + 2)

func _change_stage(owner: PFActor, new_stage: int) -> void:
	var old_stage = current_stage
	current_stage = clampi(new_stage, 0, max_stage)
	
	if current_stage <= 0:
		print("    > %s has recovered from %s!" % [owner.entity_name, condition_name])
		owner.remove_condition(condition_id)
		return
		
	if current_stage != old_stage:
		print("    > %s is now at Stage %d of %s." % [owner.entity_name, current_stage, condition_name])
		_remove_sub_conditions(owner)
		_apply_stage_effects(owner)

func _remove_sub_conditions(owner: PFActor) -> void:
	for sub_cond_id in active_sub_conditions:
		owner.remove_condition(sub_cond_id)
	active_sub_conditions.clear()

func _apply_stage_effects(owner: PFActor) -> void:
	var stage_idx = current_stage - 1
	if stage_idx < 0 or stage_idx >= stages_data.size():
		return
		
	var stage_data = stages_data[stage_idx]
	
	# Apply Damage
	if stage_data.has("damage"):
		var dmg_str = stage_data["damage"]
		var dmg_type = stage_data.get("damage_type", "untyped")
		# Simple dice parser for tests
		var parts = dmg_str.split("d")
		var damage_amount = 0
		if parts.size() == 2:
			var count = parts[0].to_int()
			var sides = parts[1].to_int()
			for i in range(count):
				damage_amount += (randi() % sides) + 1
		else:
			damage_amount = dmg_str.to_int()
			
		var damage_enum = PFCombatConstants.DamageType.UNTYPED
		if dmg_type == "poison": damage_enum = PFCombatConstants.DamageType.POISON
			
		print("    > %s takes %d %s damage from %s." % [owner.entity_name, damage_amount, dmg_type, condition_name])
		owner.take_damage(damage_amount, damage_enum)
		
	# Apply Conditions
	if stage_data.has("conditions"):
		for cond_def in stage_data["conditions"]:
			var cid = cond_def["id"]
			var cval = cond_def.get("value", 1)
			
			var new_cond = PFCondition.create(cid, cval)
			owner.conditions.append(new_cond)
			active_sub_conditions.append(cid)
			print("    > %s is afflicted with %s %d." % [owner.entity_name, str(cid).capitalize(), cval])
