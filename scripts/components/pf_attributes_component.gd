# pf_attributes_component.gd
## Stores and calculates core ability modifiers (STR, DEX, etc.).
class_name PFAttributesComponent
extends Node

# --- ABILITY MODIFIERS ---
var str_mod: int
var dex_mod: int
var con_mod: int
var int_mod: int
var wis_mod: int
var cha_mod: int

# --- DEFENSES ---
var fort_save: PFStat
var ref_save: PFStat
var will_save: PFStat

func initialize(p_fort: int, p_ref: int, p_will: int, p_str: int, p_dex: int, p_con: int, p_int: int, p_wis: int, p_cha: int) -> void:
	fort_save = PFStat.new(p_fort)
	ref_save = PFStat.new(p_ref)
	will_save = PFStat.new(p_will)
	
	str_mod = p_str
	dex_mod = p_dex
	con_mod = p_con
	int_mod = p_int
	wis_mod = p_wis
	cha_mod = p_cha

func get_ability_modifier(attr: StringName) -> int:
	match attr:
		&"STR": return str_mod
		&"DEX": return dex_mod
		&"CON": return con_mod
		&"INT": return int_mod
		&"WIS": return wis_mod
		&"CHA": return cha_mod
		_: return 0
