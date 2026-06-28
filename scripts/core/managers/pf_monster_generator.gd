class_name PFMonsterGenerator
extends Object

## Generates a random NPC based on a given level and roadmap.
static func generate_npc(level: int, roadmap_name: String = "Brute") -> PFNpc:
	# 1. Fetch tables and roadmap
	if not PFMonsterTables.ABILITY_MODIFIERS.has(level):
		push_error("Level %d out of bounds for monster generation!" % level)
		level = clamp(level, -1, 24)
		
	var roadmap: Dictionary = PFMonsterRoadmaps.get_roadmap(roadmap_name)
	
	# 2. Extract values based on roadmap brackets
	var hp_bracket = roadmap.get("hp", &"MODERATE")
	var hp = _get_random_value(PFMonsterTables.HIT_POINTS[level][hp_bracket])
	
	var ac_bracket = roadmap.get("ac", &"MODERATE")
	var ac = _get_random_value(PFMonsterTables.ARMOR_CLASS[level][ac_bracket])
	
	var fort_bracket = roadmap.get("fort", &"MODERATE")
	var fort = _get_random_value(PFMonsterTables.PERCEPTION_AND_SAVES[level][fort_bracket])
	
	var ref_bracket = roadmap.get("ref", &"MODERATE")
	var ref = _get_random_value(PFMonsterTables.PERCEPTION_AND_SAVES[level][ref_bracket])
	
	var wil_bracket = roadmap.get("wil", &"MODERATE")
	var wil = _get_random_value(PFMonsterTables.PERCEPTION_AND_SAVES[level][wil_bracket])
	
	var per_bracket = roadmap.get("per", &"MODERATE")
	var per = _get_random_value(PFMonsterTables.PERCEPTION_AND_SAVES[level][per_bracket])
	
	var str_bracket = roadmap.get("str", &"MODERATE")
	var str_val = _get_random_value(PFMonsterTables.ABILITY_MODIFIERS[level][str_bracket])
	
	var dex_bracket = roadmap.get("dex", &"MODERATE")
	var dex_val = _get_random_value(PFMonsterTables.ABILITY_MODIFIERS[level][dex_bracket])
	
	var con_bracket = roadmap.get("con", &"MODERATE")
	var con_val = _get_random_value(PFMonsterTables.ABILITY_MODIFIERS[level][con_bracket])
	
	var int_bracket = roadmap.get("int", &"MODERATE")
	var int_val = _get_random_value(PFMonsterTables.ABILITY_MODIFIERS[level][int_bracket])
	
	var wis_bracket = roadmap.get("wis", &"MODERATE")
	var wis_val = _get_random_value(PFMonsterTables.ABILITY_MODIFIERS[level][wis_bracket])
	
	var cha_bracket = roadmap.get("cha", &"MODERATE")
	var cha_val = _get_random_value(PFMonsterTables.ABILITY_MODIFIERS[level][cha_bracket])
	
	# Speeds
	var land_speed = 25
	var fly_speed = 0
	var abilities = roadmap.get("abilities", [])
	if &"fast_land_speed" in abilities:
		land_speed = 35
	if &"fly_speed" in abilities:
		fly_speed = 30
		
	var traits: Array[StringName] = []
	if &"undead" in abilities:
		traits.append(&"undead")
	if "animal" in abilities or roadmap_name.ends_with("Beast"):
		traits.append(&"animal")
	else:
		traits.append(&"humanoid")
		
	# Create NPC
	var base_id = roadmap_name.to_lower().replace(" ", "_")
	var npc_name = roadmap_name + " NPC"
	
	var npc = PFNpc.new(base_id, npc_name, traits, level,
		hp, fort, ref, wil,
		str_val, dex_val, con_val, int_val, wis_val, cha_val,
		land_speed, fly_speed, 0, 0, 0,
		"A randomly generated %s." % roadmap_name, true)
		
	# Set non-init stats directly onto dictionary
	npc.monster_stats["ac"] = ac
	npc.monster_stats["perception"] = per
	
	# Strike logic
	var strike_bonus_bracket = roadmap.get("strikeBonus", "MODERATE")
	var strike_bonus = _get_random_value(PFMonsterTables.STRIKE_BONUS[level][strike_bonus_bracket])
	
	var strike_damage_bracket = roadmap.get("strikeDamage", "MODERATE")
	var strike_damage_expr = PFMonsterTables.STRIKE_DAMAGE[level][strike_damage_bracket]
	
	# Parse damage expression (e.g., "2d6+5")
	var damage_dice = 1
	var damage_sides = 6
	var damage_flat = 0
	
	if "d" in strike_damage_expr:
		var parts = strike_damage_expr.split("d")
		damage_dice = parts[0].to_int()
		var sub_parts = parts[1].split("+")
		damage_sides = sub_parts[0].to_int()
		if sub_parts.size() > 1:
			damage_flat = sub_parts[1].to_int()
			
	var base_weapon = PFWeapon.new()
	base_weapon.weapon_type = PFEquipmentConstants.WeaponType.MELEE
	base_weapon.dice_amount = damage_dice
	base_weapon.die_faces = damage_sides
	base_weapon.flat_damage_bonus = damage_flat
	base_weapon.entity_name = "Strike"
	
	npc.inventory.add_item(base_weapon)
	
	# Store the explicit attack bonus we want this weapon to use.
	npc.monster_stats["attack"] = strike_bonus
	
	if &"sneak_attack" in abilities:
		npc.monster_stats["sneak_attack_dice"] = max(1, ceili(float(level) / 3.0))
		
	# Spellcasting
	if roadmap.get("spellcasting", "") != "":
		var spell_dc_bracket = roadmap.get("spellcasting")
		var spell_dc = _get_random_value(PFMonsterTables.SPELLCASTING[level][spell_dc_bracket])
		npc.npc_spell_dc = spell_dc
		npc.npc_spell_attack = spell_dc - 10 # PF2e spell attack is DC - 10 typically
		
	return npc

## Helper to resolve possible arrays like [4, 3] to a single integer
static func _get_random_value(value: Variant) -> int:
	if typeof(value) == TYPE_ARRAY:
		# Return a random value from the array bounds (min to max inclusive)
		var min_val = value[1] if value[1] < value[0] else value[0]
		var max_val = value[0] if value[0] > value[1] else value[1]
		return randi_range(min_val, max_val)
	return int(value)
