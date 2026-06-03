# pf_entity.gd
# The absolute base class for everything in the engine.
class_name PFEntity
extends RefCounted 

enum Rarity { COMMON, UNCOMMON, RARE, UNIQUE }
enum Size { TINY, SMALL, MEDIUM, LARGE, HUGE, GARGANTUAN }
enum Vision { NORMAL, LOW_LIGHT, DARKVISION }

# --- SYSTEM WIDE CONSTANTS ---
enum ActionCost { NONE = 0, FREE = 1, REACTION = 2, ONE_ACTION = 3, TWO_ACTIONS = 4, THREE_ACTIONS = 5, ONE_ROUND = 6, TWO_ROUNDS = 7, ONE_MINUTE = 8, TEN_MINUTES = 9, ONE_HOUR = 10 }
enum MagicTradition { NONE = 0, ARCANE = 1, DIVINE = 2, OCCULT = 3, PRIMAL = 4 }
enum CasterType { NONE = 0, PREPARED = 1, SPONTANEOUS = 2, BOTH = 3 }
enum ScalingType { NONE = 0, PLUS_ONE = 1, PLUS_TWO = 2, PLUS_THREE = 3, PLUS_FOUR = 4 }
enum SpellCategory { SPELL = 0, CANTRIP = 1, FOCUS = 2 }
enum SpellProgression { NONE = 0, FULL_CASTER = 1, BOUNDED_CASTER = 2 }

enum Distance {
	TOUCH = 0,
	FT_5 = 5,
	FT_10 = 10,
	FT_15 = 15,
	FT_20 = 20,
	FT_25 = 25,
	FT_30 = 30,
	FT_40 = 40,
	FT_50 = 50,
	FT_60 = 60,
	FT_80 = 80,
	FT_90 = 90,
	FT_100 = 100,
	FT_120 = 120,
	FT_500 = 500,
	FT_1000 = 1000,
	MILE_1 = 5280,
	UNLIMITED = 999999
}

var entity_name: String
var traits: Array[StringName]
var rarity: Rarity

# Updated Constructor: Added p_rarity with a default of COMMON
func _init(p_name: String = "", p_traits: Array[StringName] = [], p_rarity: Rarity = Rarity.COMMON):
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
