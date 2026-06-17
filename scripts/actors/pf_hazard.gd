# pf_hazard.gd
## Represents a Trap, Environmental Hazard, or Haunt.
class_name PFHazard
extends PFActor

enum Complexity {
	SIMPLE,
	COMPLEX
}

var complexity: Complexity = Complexity.SIMPLE
var stealth_dc: int = 10
var stealth_min_proficiency: int = PFMathConstants.ProficiencyRank.UNTRAINED

# Array of dictionaries:
# [{"skill": &"thievery", "dc": 22, "successes_needed": 1, "successes_achieved": 0}]
var disable_methods: Array = []

var is_disabled: bool = false
var is_broken: bool = false
var is_destroyed: bool = false
var is_triggered: bool = false

signal hazard_triggered(hazard: PFHazard)
signal hazard_disabled(hazard: PFHazard)

func _init(p_name: String, p_traits: Array[StringName], p_level: int, p_hp: int, p_hardness: int = 0):
	# Hazards do not normally have Fort/Ref/Will stats inherently tracked like a character sheet,
	# but they can make saves if needed. They are mostly targeted objects.
	super._init(p_name, p_traits, p_level, p_hp)
	
	health.hardness = p_hardness
	has_spirit = p_traits.has(&"haunt")
	
	health.hp_changed.connect(_on_hp_changed)

func _on_hp_changed(current_hp: int, max_hp: int) -> void:
	if current_hp <= 0 and not is_destroyed:
		is_destroyed = true
		is_disabled = true
		hazard_disabled.emit(self)
		print("    > [Hazard] %s has been destroyed!" % entity_name)
	# Basic broken threshold logic: Usually at half HP
	elif current_hp <= max_hp / 2 and not is_broken:
		is_broken = true
		print("    > [Hazard] %s is now broken." % entity_name)

func trigger() -> void:
	if is_disabled or is_destroyed:
		return
		
	is_triggered = true
	print("    > [Hazard] %s is TRIGGERED!" % entity_name)
	hazard_triggered.emit(self)
	
	if complexity == Complexity.SIMPLE:
		# Simple hazards trigger once and then usually become disabled or need manual resetting
		pass
	elif complexity == Complexity.COMPLEX:
		# Complex hazards roll initiative and enter combat
		print("    > [Hazard] %s rolls initiative!" % entity_name)
		
func attempt_disable(skill_used: StringName, degree_of_success: int) -> bool:
	if is_disabled or is_destroyed:
		return false
		
	for method in disable_methods:
		if method.get("skill", &"") == skill_used:
			# Matched a valid disable skill!
			if degree_of_success == PFCombatConstants.DegreeOfSuccess.CRITICAL_SUCCESS:
				method["successes_achieved"] += 2
			elif degree_of_success == PFCombatConstants.DegreeOfSuccess.SUCCESS:
				method["successes_achieved"] += 1
			elif degree_of_success == PFCombatConstants.DegreeOfSuccess.CRITICAL_FAILURE:
				# Oh no!
				trigger()
				return false
				
			var needed = method.get("successes_needed", 1)
			if method["successes_achieved"] >= needed:
				is_disabled = true
				hazard_disabled.emit(self)
				print("    > [Hazard] %s has been disabled successfully!" % entity_name)
				return true
				
			print("    > [Hazard] %s disabled progress: %d/%d" % [entity_name, method["successes_achieved"], needed])
			return false
			
	print("    > [Hazard] %s cannot be disabled using %s." % [entity_name, skill_used])
	return false

# Override PFActor unified math methods to return baseline hazard stats
func get_ac() -> int:
	return 10 + level # Placeholder basic scaling, real hazards pull from their DB statblock
	
func get_save_bonus(save_type: StringName) -> int:
	return level # Placeholder basic scaling
