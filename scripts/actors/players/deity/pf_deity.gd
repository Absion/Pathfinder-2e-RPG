# pf_deity.gd
## A divine entity granting domains, edicts, and anathemas to its followers.
class_name PFDeity
extends PFEntity



var title: String
var category: String
var edicts: Array[StringName]
var anathema: Array[StringName]

var religious_symbol: String
var sacred_animal: String
var sacred_colors: Array[String]


# Mechanical Benefits
var divine_attributes: Array[StringName]
var divine_font: Array[String] # e.g. ["harm", "heal"]
var divine_sanctification: PFBiographyConstants.DivineSanctification = PFBiographyConstants.DivineSanctification.NONE
var divine_skill: StringName
var favored_weapon: StringName
var domains: Array[String]
var alternate_domains: Array[String]
var cleric_spells: Dictionary # e.g. { 1: "illusory_object", 4: "creation" }

# Boons and Curses
var boon_minor: PFDivineBoon
var boon_moderate: PFDivineBoon
var boon_major: PFDivineBoon
var curse_minor: PFDivineBoon
var curse_moderate: PFDivineBoon
var curse_major: PFDivineBoon

func _init(p_name: String = "", p_traits: Array[StringName] = [], p_rarity: PFBiographyConstants.Rarity = PFBiographyConstants.Rarity.COMMON):
	super._init(p_name, p_traits, p_rarity)
