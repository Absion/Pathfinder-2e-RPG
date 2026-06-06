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
				died.emit()

var temp_hp: int = 0 :
	set(val):
		temp_hp = max(val, 0)
		temp_hp_changed.emit(temp_hp)

var immunities: Array[PFCombatConstants.DamageType] = []
var weaknesses: Dictionary = {} 
var resistances: Dictionary = {} 
var trait_weaknesses: Dictionary = {} 
var trait_resistances: Dictionary = {} 

func initialize(p_max_hp: int):
	max_hp = p_max_hp
	current_hp = max_hp

func apply_damage(amount: int, type: PFCombatConstants.DamageType = PFCombatConstants.DamageType.UNTYPED, tags: Array[StringName] = []) -> int:
	if immunities.has(type):
		return 0 # Completely immune
		
	var final_damage = amount
	
	# Handle Weaknesses
	if weaknesses.has(type):
		final_damage += weaknesses[type]
		
	for tag in tags:
		if trait_weaknesses.has(tag):
			final_damage += trait_weaknesses[tag]
			
	# Handle Resistances
	if resistances.has(type):
		final_damage = max(0, final_damage - resistances[type])
		
	for tag in tags:
		if trait_resistances.has(tag):
			final_damage = max(0, final_damage - trait_resistances[tag])
			
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
