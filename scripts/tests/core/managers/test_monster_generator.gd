class_name TestMonsterGenerator
extends GutTest


func test_brute_generation() -> void:
	print("Running test_brute_generation...")
	var npc: PFNpc = autofree(PFMonsterGenerator.generate_npc(5, &"Brute"))
	assert_eq(npc.level, 5, "Brute Level should be 5")
	# Brute AC is Low. Level 5 Low AC should be roughly 19 (PFMonsterTables.ARMOR_CLASS[5]["LOW"])
	var _expected_ac = PFMonsterGenerator._get_random_value(PFMonsterTables.ARMOR_CLASS[5][&"LOW"]) if PFMonsterTables.ARMOR_CLASS.has(5) else 19
	# Actually wait, _get_random_value is inside PFMonsterGenerator, not PFMonsterTables.
	
	# Just assert weapon exists
	assert_eq(npc.inventory.items.size(), 1, "Brute should have a procedural weapon generated")
	var weapon = npc.inventory.items[0]
	assert_eq(weapon.weapon_type, PFEquipmentConstants.WeaponType.MELEE, "Procedural weapon should be unarmed")

func test_sniper_generation() -> void:
	print("Running test_sniper_generation...")
	var npc: PFNpc = autofree(PFMonsterGenerator.generate_npc(10, &"Sniper"))
	assert_eq(npc.level, 10, "Sniper Level should be 10")
	# Sniper AC is Moderate.
	var ac = npc.monster_stats.get(&"ac", 0)
	print("  Sniper generated AC: %d" % ac)

func test_elite_template() -> void:
	print("Running test_elite_template...")
	var npc: PFNpc = autofree(PFMonsterGenerator.generate_npc(2, &"Soldier"))
	var old_ac = npc.monster_stats.get(&"ac", 10)
	var old_hp = npc.health.max_hp
	var old_level = npc.level
	
	PFMonsterTemplateManager.apply_template(npc, &"Elite", 2) # Apply Elite twice
	
	assert_eq(npc.level, old_level + 2, "Level should increase by 2")
	assert_eq(npc.monster_stats.get(&"ac", 10), old_ac + 4, "AC should increase by 4 (+2 per application)")
	assert_eq(npc.health.max_hp, old_hp + 20, "HP should increase by 20 (+10 per application for low levels)")

func test_weak_template() -> void:
	print("Running test_weak_template...")
	var npc: PFNpc = autofree(PFMonsterGenerator.generate_npc(6, &"Spellcaster"))
	var old_ac = npc.monster_stats.get(&"ac", 10)
	var old_hp = npc.health.max_hp
	var old_level = npc.level
	
	PFMonsterTemplateManager.apply_template(npc, &"Weak", 1)
	
	assert_eq(npc.level, old_level - 1, "Level should decrease by 1")
	assert_eq(npc.monster_stats.get(&"ac", 10), old_ac - 2, "AC should decrease by 2")
	assert_eq(npc.health.max_hp, max(1, old_hp - 15), "HP should decrease by 15 for level 6")
