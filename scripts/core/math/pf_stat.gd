# pf_stat.gd
# Manages a single statistic (like AC or Fortitude Save) and calculates its final value.
## A tracked numerical statistic that calculates modifiers dynamically.
class_name PFStat
extends RefCounted

var base_value: int
var modifiers: Array[PFModifier] = [] # Holds all current buffs/debuffs

func _init(p_base: int):
	base_value = p_base

# Adds a new buff/debuff to this stat.
func add_modifier(modifier: PFModifier) -> void:
	modifiers.append(modifier)

# Removes a modifier based on where it came from. 
# Example: remove_modifier_by_source("Bless Spell") when the spell duration ends.
func remove_modifier_by_source(source_name: String) -> void:
	# .filter keeps only the items that return true (i.e., they don't match the source_name)
	modifiers = modifiers.filter(func(m): return m.source != source_name)

# THE MAGIC MATH FUNCTION: This calculates the strict PF2e stacking rules automatically.
func get_total() -> int:
	var total = base_value
	
	# Variables to track the highest bonus of each type
	var highest_circumstance = 0
	var highest_status = 0
	var highest_item = 0
	
	# Variables to track the worst penalty of each type. 
	# In PF2e, penalties and bonuses of the same type are tracked separately.
	var lowest_circumstance = 0
	var lowest_status = 0
	var lowest_item = 0

	# Loop through all active modifiers
	for modifier in modifiers:
		if modifier.type == PFMathConstants.ModifierType.UNTYPED:
			# Untyped modifiers (like a shield's penalty to speed) always stack
			total += modifier.value
			
		elif modifier.type == PFMathConstants.ModifierType.CIRCUMSTANCE:
			if modifier.value > 0: 
				# maxi() returns the higher of two numbers. This ensures we only keep the highest bonus.
				highest_circumstance = maxi(highest_circumstance, modifier.value)
			else: 
				# mini() returns the lower of two numbers (e.g., -2 is lower than -1).
				lowest_circumstance = mini(lowest_circumstance, modifier.value)
				
		elif modifier.type == PFMathConstants.ModifierType.STATUS:
			if modifier.value > 0: highest_status = maxi(highest_status, modifier.value)
			else: lowest_status = mini(lowest_status, modifier.value)
			
		elif modifier.type == PFMathConstants.ModifierType.ITEM:
			if modifier.value > 0: highest_item = maxi(highest_item, modifier.value)
			else: lowest_item = mini(lowest_item, modifier.value)

	# Apply the highest bonus and worst penalty of each type to the total
	total += highest_circumstance + lowest_circumstance
	total += highest_status + lowest_status
	total += highest_item + lowest_item
	
	return total

