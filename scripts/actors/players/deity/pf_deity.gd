# pf_deity.gd
class_name PFDeity
extends PFEntity

var category: String
var edicts: Array[String]
var anathema: Array[String]
var areas_of_concern: Array[String]
var religious_symbol: String
var sacred_animal: String
var sacred_colors: Array[String]
var pantheons: Array[String]

# Mechanical Benefits
var divine_attributes: Array[StringName]
var divine_font: Array[String] # e.g. ["harm", "heal"]
var divine_sanctification: String
var divine_skill: StringName
var favored_weapon: String
var domains: Array[String]
var alternate_domains: Array[String]
var cleric_spells: Dictionary # e.g. { 1: "illusory_object", 4: "creation" }

# Boons and Curses
var boon_minor: String
var boon_moderate: String
var boon_major: String
var curse_minor: String
var curse_moderate: String
var curse_major: String

func _init(p_name: String = "", p_traits: Array[StringName] = [], p_rarity: PFEntity.Rarity = PFEntity.Rarity.COMMON):
	super._init(p_name, p_traits, p_rarity)
