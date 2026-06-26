# pf_attributes_component.gd
## Stores and calculates core ability modifiers (STR, DEX, etc.).
class_name PFAttributesComponent
extends Node

# --- ABILITY MODIFIERS ---
var str_mod: int:
	get: return _calculate_mod(&"str")
var dex_mod: int:
	get: return _calculate_mod(&"dex")
var con_mod: int:
	get: return _calculate_mod(&"con")
var int_mod: int:
	get: return _calculate_mod(&"int")
var wis_mod: int:
	get: return _calculate_mod(&"wis")
var cha_mod: int:
	get: return _calculate_mod(&"cha")

# --- DEFENSES ---
var fort_save: PFStat
var ref_save: PFStat
var will_save: PFStat

# --- TEMPORARY MODIFIERS (Buffs/Debuffs) ---
var attack_modifiers: PFStat
var dc_modifiers: PFStat
var ac_modifiers: PFStat

# --- ABC BOOST TRACKING ---
var is_npc: bool = false
var use_alternate_ancestry_boosts: bool = false
var boosts: Dictionary = {
	"ancestry": [],
	"background": [],
	"class": [],
	"level": [],
	"free": [],
	"voluntary_flaws": [] # Negative
}

func initialize(p_fort: int, p_ref: int, p_will: int) -> void:
	fort_save = PFStat.new(p_fort)
	ref_save = PFStat.new(p_ref)
	will_save = PFStat.new(p_will)
	attack_modifiers = PFStat.new(0)
	dc_modifiers = PFStat.new(0)
	ac_modifiers = PFStat.new(0)

## Validates and applies an ancestry boost. If it overlaps with an existing ancestry boost (and it's not the alternate rule), returns false.
func apply_ancestry_boost(stat: StringName, is_voluntary_flaw_boost: bool = false) -> bool:
	if stat == &"": return false
	
	if use_alternate_ancestry_boosts:
		if boosts["ancestry"].has(stat):
			push_warning("Alternate ancestry allows 2 free boosts, but they cannot overlap on " + str(stat))
			return false
	else:
		if boosts["ancestry"].has(stat):
			push_warning("Cannot apply multiple ancestry boosts to the same stat: " + str(stat))
			return false
			
	if is_voluntary_flaw_boost:
		# The extra boost from voluntary flaws cannot overlap with a standard ancestry boost
		if boosts["ancestry"].has(stat):
			push_warning("Voluntary flaw boost cannot be applied to a stat already receiving an ancestry boost: " + str(stat))
			return false
			
	boosts["ancestry"].append(stat)
	return true

func apply_voluntary_flaw(stat: StringName) -> void:
	boosts["voluntary_flaws"].append(stat)

func apply_background_boost(stat: StringName) -> bool:
	if stat == &"": return false
	if boosts["background"].has(stat):
		push_warning("Background boosts cannot overlap on " + str(stat))
		return false
	boosts["background"].append(stat)
	return true

func apply_class_boost(stat: StringName) -> void:
	if stat != &"":
		boosts["class"].append(stat)

func apply_free_boost(stat: StringName) -> bool:
	if stat == &"": return false
	if not is_npc and boosts["free"].has(stat):
		push_warning("Level 1 free boosts cannot overlap on " + str(stat))
		return false
	boosts["free"].append(stat)
	return true

func apply_level_boost(level: int, stat: StringName) -> bool:
	if stat == &"": return false
	# At level 5, 10, 15, 20, you get 4 boosts. They cannot overlap within the same level step.
	# We can store them as "level_5_str", etc., or just track the count properly.
	var level_key = str(level) + "_" + str(stat)
	if boosts["level"].has(level_key):
		push_warning("Cannot apply multiple level " + str(level) + " boosts to " + str(stat))
		return false
	boosts["level"].append(level_key)
	return true

## Helper to calculate the raw number of boosts applied to a stat.
func _get_total_boosts(stat: StringName) -> int:
	var total_boosts = 0
	
	for b in boosts["ancestry"]: if b == stat: total_boosts += 1
	for b in boosts["background"]: if b == stat: total_boosts += 1
	for b in boosts["class"]: if b == stat: total_boosts += 1
	for b in boosts["free"]: if b == stat: total_boosts += 1
	
	for b in boosts["level"]: 
		if str(b).ends_with(str(stat)): 
			total_boosts += 1
			
	for f in boosts["voluntary_flaws"]: if f == stat: total_boosts -= 1
	
	return total_boosts

## Calculates the final modifier using the Remaster math.
func _calculate_mod(stat: StringName) -> int:
	var total_boosts = _get_total_boosts(stat)
	
	if is_npc:
		return total_boosts
		
	if total_boosts <= 4:
		return total_boosts
	else:
		return 4 + floor((total_boosts - 4) / 2.0)

## UI Helper: Returns true if the stat has an odd number of boosts above +4,
## meaning it's "halfway" to the next modifier increase.
func has_partial_boost(stat: StringName) -> bool:
	var total_boosts = _get_total_boosts(stat)
	if total_boosts <= 4:
		return false
	return (total_boosts % 2) != 0

func get_ability_modifier(attr: StringName) -> int:
	match attr.to_lower():
		&"str": return str_mod
		&"dex": return dex_mod
		&"con": return con_mod
		&"int": return int_mod
		&"wis": return wis_mod
		&"cha": return cha_mod
		_: return 0
