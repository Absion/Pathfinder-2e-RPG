# pf_entity.gd
# The absolute base class for everything in the engine.
class_name PFEntity
extends RefCounted 

enum Rarity { COMMON, UNCOMMON, RARE, UNIQUE }

var entity_name: String
var traits: Array[StringName]
var rarity: Rarity

# Updated Constructor: Added p_rarity with a default of COMMON
func _init(p_name: String, p_traits: Array[StringName] = [], p_rarity: Rarity = Rarity.COMMON):
	entity_name = p_name
	traits = p_traits
	rarity = p_rarity

func has_trait(trait_name: StringName) -> bool:
	return traits.has(trait_name)

# A universal setter so you can easily update rarity after creation
func set_rarity(new_rarity: Rarity) -> void:
	rarity = new_rarity

# --- UI HELPER ---
# This is perfect for when you build your UI to color-code text!
func get_rarity_color() -> Color:
	match rarity:
		Rarity.UNCOMMON: return Color.ORANGE 	# PF2e standard for Uncommon
		Rarity.RARE: return Color.DODGER_BLUE 	# PF2e standard for Rare
		Rarity.UNIQUE: return Color.PURPLE 		# PF2e standard for Unique
		_: return Color.WHITE					# Default for Common
