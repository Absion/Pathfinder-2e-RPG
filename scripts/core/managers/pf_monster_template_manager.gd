class_name PFMonsterTemplateManager
extends Object

## Applies a Pathfinder 2e Monster Template to an NPC.
## Currently supports Elite and Weak adjustments.
static func apply_template(npc: PFNpc, template_name: StringName, apply_multiple_times: int = 1) -> void:
	if apply_multiple_times <= 0: return
	
	for i in range(apply_multiple_times):
		match template_name:
			&"Elite":
				_apply_elite_adjustment(npc)
			&"Weak":
				_apply_weak_adjustment(npc)
			_:
				push_warning("Template %s not implemented!" % template_name)
				return

static func _apply_elite_adjustment(npc: PFNpc) -> void:
	var old_level = npc.level
	npc.level += 1
	
	# +2 to AC, Attack, DC, Saves, Perception, Skills
	npc.monster_stats["ac"] = npc.monster_stats.get(&"ac", 10) + 2
	npc.monster_stats["attack"] = npc.monster_stats.get(&"attack", 0) + 2
	npc.npc_spell_dc += 2
	npc.npc_spell_attack += 2
	npc.monster_stats["perception"] = npc.monster_stats.get(&"perception", 0) + 2
	
	# Saves
	if npc.attributes.fort_save: npc.attributes.fort_save.base_value += 2
	if npc.attributes.ref_save: npc.attributes.ref_save.base_value += 2
	if npc.attributes.will_save: npc.attributes.will_save.base_value += 2
	
	# Damage +2
	for item in npc.inventory.items:
		if item is PFWeapon:
			item.flat_damage_bonus += 2
			
	# HP adjustments based on the starting level (old_level)
	var hp_adj = 0
	if old_level <= 4:
		hp_adj = 10
	elif old_level <= 14:
		hp_adj = 15
	elif old_level <= 20:
		hp_adj = 20
	else:
		hp_adj = 30
		
	npc.health.max_hp += hp_adj
	npc.health.current_hp += hp_adj

static func _apply_weak_adjustment(npc: PFNpc) -> void:
	var old_level = npc.level
	npc.level -= 1
	
	# -2 to AC, Attack, DC, Saves, Perception, Skills
	npc.monster_stats["ac"] = npc.monster_stats.get(&"ac", 10) - 2
	npc.monster_stats["attack"] = npc.monster_stats.get(&"attack", 0) - 2
	npc.npc_spell_dc -= 2
	npc.npc_spell_attack -= 2
	npc.monster_stats["perception"] = npc.monster_stats.get(&"perception", 0) - 2
	
	# Saves
	if npc.attributes.fort_save: npc.attributes.fort_save.base_value -= 2
	if npc.attributes.ref_save: npc.attributes.ref_save.base_value -= 2
	if npc.attributes.will_save: npc.attributes.will_save.base_value -= 2
	
	# Damage -2
	for item in npc.inventory.items:
		if item is PFWeapon:
			item.flat_damage_bonus = max(0, item.flat_damage_bonus - 2)
			
	# HP adjustments based on the starting level (old_level)
	var hp_adj = 0
	if old_level <= 4:
		hp_adj = 10
	elif old_level <= 14:
		hp_adj = 15
	elif old_level <= 20:
		hp_adj = 20
	else:
		hp_adj = 30
		
	npc.health.max_hp = max(1, npc.health.max_hp - hp_adj)
	npc.health.current_hp = max(1, npc.health.current_hp - hp_adj)
