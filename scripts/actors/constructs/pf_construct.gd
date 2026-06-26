# pf_construct.gd
## Represents inanimate objects that can be targeted and damaged, like doors, walls, or pillars.
class_name PFConstruct
extends PFActor

var hardness: int = 0
var broken_threshold: int = 0

func _init(p_name: String, p_traits: Array[StringName], p_hp: int, p_hardness: int, p_bt: int):
	# Basic constructs don't usually have a level, so we default to 0
	super._init(p_name, p_traits, 0, p_hp)
	hardness = p_hardness
	broken_threshold = p_bt
	
	# Constructs implicitly have the construct trait
	if not has_trait(&"construct"):
		traits.append(&"construct")

# Constructs don't take standard turns
func start_turn() -> void:
	pass

func end_turn() -> void:
	pass

# Provide a base AC for an inanimate object (usually 10, modified by size/circumstance)
func get_ac() -> int:
	return 10 + get_condition_modifier(&"ac")

# Override take_damage to apply hardness before passing to the base health component
func take_damage(amount: int, damage_type: PFCombatConstants.DamageType = PFCombatConstants.DamageType.UNTYPED, effect_traits: Array[StringName] = [], source_actor: PFActor = null, target_position: Vector3 = Vector3.INF) -> void:
	# Constructs apply hardness to damage before resistances
	var final_damage = maxi(0, amount - hardness)
	if final_damage > 0:
		super.take_damage(final_damage, damage_type, effect_traits, source_actor, target_position)
		
		# Check for the Broken condition
		if health.current_hp <= broken_threshold and not has_condition("broken"):
			apply_condition(PFCondition.create(&"broken", 1))
	else:
		print("    > The %s's hardness (%d) completely absorbs the impact!" % [entity_name, hardness])
