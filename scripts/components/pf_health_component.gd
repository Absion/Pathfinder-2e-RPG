# pf_health_component.gd
## Tracks hit points, temporary hit points, and dying rules.
class_name PFHealthComponent
extends PFComponent

signal hp_changed(current_hp: int, max_hp: int)
signal temp_hp_changed(current_temp_hp: int)
signal died

@export var max_hp: int = 10 : 
	set(val):
		max_hp = val
		hp_changed.emit(current_hp, max_hp)

var current_hp: int = 10 :
	set(val):
		var old_hp = current_hp
		current_hp = clampi(val, 0, max_hp)
		if current_hp != old_hp:
			hp_changed.emit(current_hp, max_hp)
			if current_hp == 0:
				var parent = get_parent()
				if parent is PFActor:
					if _last_damage_was_nonlethal:
						parent.apply_condition(PFCondition.create(&"unconscious", 1))
						# Nonlethal doesn't cause death or dying
					elif parent is PFPlayerCharacter:
						var wounded_val = 0
						if parent.has_condition("wounded"):
							wounded_val = parent.get_condition("wounded").value
						var dying_val = 1 + wounded_val
						parent.apply_condition(PFCondition.create(&"dying", dying_val))
					else:
						parent.apply_condition(PFCondition.create(&"dead", 1))
						died.emit()
				else:
					died.emit()

var _last_damage_was_nonlethal: bool = false

var temp_hp: int = 0 :
	set(val):
		temp_hp = max(val, 0)
		temp_hp_changed.emit(temp_hp)

var hardness: int = 0

var immunities: Array[PFCombatConstants.DamageType] = []
var weaknesses: Dictionary = {} 
var resistances: Dictionary = {} 
var trait_weaknesses: Dictionary = {} 
var trait_resistances: Dictionary = {} 

func initialize(p_max_hp: int):
	max_hp = p_max_hp
	current_hp = max_hp

func apply_damage(amount: int, type: PFCombatConstants.DamageType = PFCombatConstants.DamageType.UNTYPED, tags: Array[StringName] = []) -> int:
	var triggered_immunity = false
	var triggered_weakness = false
	var triggered_resistance = false
	
	if immunities.has(type):
		triggered_immunity = true
		return 0 # Completely immune
		
	var final_damage = amount
	_last_damage_was_nonlethal = tags.has(&"nonlethal")
	
	# Handle Weaknesses
	if weaknesses.has(type):
		triggered_weakness = true
		final_damage += weaknesses[type]
		
	for tag in tags:
		if trait_weaknesses.has(tag):
			triggered_weakness = true
			final_damage += trait_weaknesses[tag]
			
	# Handle Resistances
	if resistances.has(type):
		triggered_resistance = true
		final_damage = max(0, final_damage - resistances[type])
		
	for tag in tags:
		if trait_resistances.has(tag):
			triggered_resistance = true
			final_damage = max(0, final_damage - trait_resistances[tag])
			
	# Apply Hardness (objects/hazards/shields)
	if hardness > 0:
		# Note: Certain energy types might bypass hardness entirely depending on exact GM rules,
		# but by default hardness reduces all damage.
		final_damage = max(0, final_damage - hardness)
		if final_damage == 0:
			return 0
			
	# Passive Bestiary Discovery/Un-discovery
	var parent = get_parent()
	if parent is PFNpc and parent.base_id != &"":
		var db = PFDatabase.get_instance()
		if db:
			var knowledge = db.get_player_knowledge(parent.base_id)
			if not knowledge.is_empty():
				var type_str = PFCombatConstants.DamageType.keys()[type].to_lower()
				
				# Weakness Check
				if triggered_weakness:
					if knowledge.get(&"state_weaknesses", 0) != 1: # 1 is KNOWN
						db.update_player_knowledge(parent.base_id, {"state_weaknesses": 1})
						print("    > [Bestiary Discovery] You discovered %s is weak to %s!" % [parent.entity_name, type_str])
				else:
					var false_data_str = knowledge.get(&"false_data", "{}")
					var false_data = JSON.parse_string(false_data_str) if false_data_str else {}
					if false_data.has(&"weaknesses"):
						for w in false_data["weaknesses"]:
							if w.has(&"type") and w["type"] == type_str:
								print("    > [Bestiary Discovery] You realize the supposed weakness to %s was false!" % type_str)
								false_data.erase("weaknesses")
								db.update_player_knowledge(parent.base_id, {
									"state_weaknesses": 0,
									"false_data": JSON.stringify(false_data)
								})
								break
				
				# Similar checks could be added for Resistance and Immunity
	
	# Apply to temp hp first
	if temp_hp > 0:
		if final_damage <= temp_hp:
			temp_hp -= final_damage
			final_damage = 0
		else:
			final_damage -= temp_hp
			temp_hp = 0
			
	current_hp -= final_damage
	return final_damage

func heal(amount: int):
	current_hp += amount
