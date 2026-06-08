# combat_test.gd
extends Node

func _ready():
	print("==================================================")
	print("==================================================")
	# 1. SETUP ACTORS
	# ---------------------------------------------------------
	print("\n--- TEST: ACTOR CREATION ---")
	
	# Initialize Database for test
	var pf_db = PFDatabase.get_instance()
	if pf_db == null:
		pf_db = preload("res://scripts/database/pf_database.gd").new()
		pf_db.name = "PFDB"
		get_tree().root.add_child(pf_db)
		pf_db._ready()
	
	var hero = PFPlayerCharacter.new("Valeros", [&"humanoid", &"human"], 5, 
		68, 12, 9, 10,  # HP, Fort, Ref, Will
		4, 2, 3, 0, 1, 1 # STR, DEX, CON, INT, WIS, CHA
	)
	
	# Apply DB data
	hero.apply_ancestry(pf_db.get_ancestry("human"))
	hero.apply_background(pf_db.get_background("farmhand"))
	hero.apply_class(&"wizard")
	
	var abadar = pf_db.get_pf_deity("abadar")
	if abadar:
		hero.apply_deity(abadar)
		print("Abadar Cleric Spells: ", abadar.cleric_spells)
	
	add_child(hero)
	
	var orc = PFNpc.new("Orc Brute", [&"humanoid", &"orc"], 5, 
		75, 14, 8, 8, 
		5, 1, 4, -1, 0, -1
	)
	orc.monster_stats = {"ac": 21, "attack": 15, "damage": 12}
	add_child(orc)
	
	# ---------------------------------------------------------
	# 1.5. TEST BELIEFS AND LORES
	# ---------------------------------------------------------
	print("\n--- TEST: DATA-DRIVEN BELIEFS & LORES ---")
	
	print("Hero Beliefs (Edicts): ", hero.edicts)
	print("Hero Beliefs (Anathemas): ", hero.anathema)
	
	if hero.anathema.has(&"steal"):
		print("SUCCESS: Hero correctly inherited the 'steal' anathema from Abadar!")
	else:
		push_error("FAIL: Hero is missing Abadar's 'steal' anathema!")
		
	print("Hero's base Athletics modifier (STR): ", hero.get_skill_bonus(&"athletics"))
	print("Hero's base Custom Lore modifier (INT): ", hero.get_skill_bonus(&"custom_lore"))
	
	hero.sheet.set_skill_rank(&"athletics", PFMathConstants.ProficiencyRank.TRAINED)
	hero.sheet.set_skill_rank(&"custom_lore", PFMathConstants.ProficiencyRank.EXPERT)
	
	print("Hero's Trained Athletics modifier: ", hero.get_skill_bonus(&"athletics"))
	print("Hero's Expert Custom Lore modifier: ", hero.get_skill_bonus(&"custom_lore"))
	
	print("\n--- TEST: DATA-DRIVEN HERITAGES ---")
	print("Hero Vision before Heritage: ", hero.senses.vision)
	print("Hero Traits before Heritage: ", hero.traits)
	
	var half_elf = pf_db.get_heritage("half_elf")
	if half_elf:
		hero.apply_heritage(half_elf)
		print("Hero Vision after Heritage: ", hero.senses.vision)
		print("Hero Traits after Heritage: ", hero.traits)
		if hero.senses.vision == PFBiographyConstants.Vision.LOW_LIGHT and hero.traits.has(&"elf"):
			print("SUCCESS: Hero properly inherited Half-Elf vision and traits!")
		else:
			push_error("FAIL: Hero failed to inherit Half-Elf properties!")
	
	# ---------------------------------------------------------
	# 2. SETUP ITEMS & ECONOMY
	# ---------------------------------------------------------
	print("\n--- TEST: ECONOMY & ITEM INSTANTIATION ---")
	
	# Give the hero some starting cash
	hero.inventory.add_currency(50, 20, 50, 5) # 50gp, 20sp, 50cp, 5pp
	print("Total wealth in copper: ", hero.inventory.get_total_wealth_in_copper())
	print("Formatted Wealth: ", PFInventory.format_copper_to_string(hero.inventory.get_total_coin_value_in_copper()))
	
	# Create a Magic Cloak (Requires Investment)
	# (p_name, p_traits, p_level, p_price_gp, p_material, p_hardness, p_hp, p_bt, p_grade, p_bulk, p_bulk_reduction, p_requires_investment)
	var cloak_of_elvenkind = PFItem.new("Cloak of Elvenkind", [&"magical", &"invested"], 4, 50.0, 
		PFEquipmentConstants.ItemMaterial.STANDARD, 1, 5, 0, PFEquipmentConstants.MaterialGrade.STANDARD, 1, 0, true)
	
	# Create Weapons & Armor
	var breastplate = PFArmor.new("Breastplate", [], 1, 8.0, PFEquipmentConstants.ArmorCategory.MEDIUM, PFEquipmentConstants.ArmorGroup.PLATE, 4, 1, -5, 16)
	var longsword = pf_db.get_weapon("longsword")
	var dagger = PFWeapon.new("Dagger", [&"agile", &"finesse", &"thrown_10"], 1, 0.2, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.SIMPLE, PFEquipmentConstants.WeaponGroup.KNIFE, 1, 4, PFCombatConstants.DamageType.PIERCING, PFEquipmentConstants.ItemMaterial.STEEL, 3, 12)
	
	# Create Shields
	var buckler = pf_db.get_shield("buckler")
	
	var steel_shield = pf_db.get_shield("steel_shield")
	# Test the dynamic reinforcing rune logic
	steel_shield.apply_reinforcing_rune(PFEquipmentConstants.ReinforcingRune.MINOR)
	
	# ---------------------------------------------------------
	# 3. TEST INVESTMENT MECHANICS
	# ---------------------------------------------------------
	print("\n--- TEST: INVESTMENT LOGIC ---")
	hero.inventory.add_item(cloak_of_elvenkind)
	
	# Attempt to equip without investing (Should fail/warn)
	hero.inventory.equip_item(cloak_of_elvenkind) 
	
	# Invest and successfully equip
	hero.inventory.invest_item(cloak_of_elvenkind)
	hero.inventory.equip_item(cloak_of_elvenkind)
	
	# Test dynamic investment limit
	hero.inventory.set_max_invested_items(12)
	
	# ---------------------------------------------------------
	# 4. TEST BUCKLER & HAND OCCUPANCY
	# ---------------------------------------------------------
	print("\n--- TEST: HAND TRACKING & BUCKLERS ---")
	hero.inventory.equip_item(breastplate)
	var raise_shield = PFActionRaiseShield.new()
	
	hero.start_turn() # <--- FIX: Give Valeros his 3 actions!
	
	# Scenario A: Wield Buckler and Longsword
	hero.inventory.wield_item(buckler, false) # Off-hand
	hero.inventory.wield_item(longsword, true) # Main-hand
	
	print("Action: Hero tries to raise buckler while holding a weapon...")
	hero.use_action(raise_shield) # Should FAIL (Hand occupied by weapon)
	
	# Scenario B: Drop sword, hold a light non-weapon (e.g., a potion)
	var potion = PFItem.new("Healing Potion", [&"consumable"], 1, 4.0, PFEquipmentConstants.ItemMaterial.STEEL, 1, 2)
	potion.bulk_value = 0 # Light item
	
	hero.inventory.release_item(true) # Drop sword
	hero.inventory.hold_item(potion, true) # Hold potion in main hand
	
	print("\nAction: Hero tries to raise buckler while holding a potion...")
	hero.use_action(raise_shield) # Should SUCCEED (Hand holds a non-weapon light object)
	
	hero.end_turn() # <--- FIX: Cleans up the turn and removes the raised shield condition
	
	# ---------------------------------------------------------
	# 5. TEST FULL COMBAT & SHIELD BLOCK
	# ---------------------------------------------------------
	print("\n--- TEST: COMBAT & SHIELD BLOCK REACTION ---")
	# Equip the reinforced Steel Shield and the Longsword
	hero.inventory.wield_item(steel_shield, false)
	hero.inventory.wield_item(longsword, true)
	
	hero.start_turn()
	print("Hero AC before raising shield: ", hero.get_ac())
	hero.use_action(raise_shield) # Should SUCCEED
	print("Hero AC after raising shield: ", hero.get_ac())
	hero.end_turn()
	
	print("\n--- MONSTER TURN ---")
	orc.start_turn()
	# Orc attacks hero (Bypassing attack roll logic to force damage for the test)
	print("%s violently strikes %s!" % [orc.entity_name, hero.entity_name])
	
	# Trigger take_damage (Should intercept via Shield Block since auto_shield_block is true and shield is raised)
	hero.take_damage(20, PFCombatConstants.DamageType.SLASHING)
	
	# Check shield state
	print("\n--- POST-COMBAT SHIELD STATUS ---")
	print("%s HP: %d / %d" % [steel_shield.entity_name, steel_shield.current_hp, steel_shield.max_hp])
	if steel_shield.is_broken():
		print("The shield is BROKEN!")
	elif steel_shield.is_destroyed():
		print("The shield is DESTROYED!")
	else:
		print("The shield is still intact.")

	# ---------------------------------------------------------
	# 6. TEST MINIONS (FAMILIARS & ANIMAL COMPANIONS)
	# ---------------------------------------------------------
	print("\n--- TEST: MINIONS (FAMILIARS & ANIMAL COMPANIONS) ---")
	
	var familiar = PFFamiliar.new("Po", hero)
	print("%s (Familiar) Max HP: %d, AC: %d" % [familiar.entity_name, familiar.health.max_hp, familiar.get_ac()])
	print("%s Acrobatics: +%d, Athletics: +%d" % [familiar.entity_name, familiar.get_skill_bonus(&"acrobatics"), familiar.get_skill_bonus(&"athletics")])
	
	print("\n--- TEST: SPECIFIC FAMILIARS ---")
	print("Attempting to transform into Faerie Dragon (Requires 3 abilities)...")
	var success = familiar.apply_specific_familiar(&"faerie_dragon")
	if not success:
		print("Failed! As expected, Po only has 2 max abilities.")
		print("Upgrading max_abilities to 4 (e.g. Witch or Improved Familiar Feat)...")
		familiar.max_abilities = 4
		success = familiar.apply_specific_familiar(&"faerie_dragon")
		if success:
			print("Success! Po is now a Faerie Dragon.")
			print("Familiar Abilities: ", familiar.familiar_abilities)
			print("Traits: ", familiar.traits)
	
	print("\n--- TEST: DATA-DRIVEN ANIMAL COMPANION SCALING ---")
	print("Direct DB Fetch for Bear: ", pf_db.get_animal_companion_data(&"bear"))
	
	var bear = PFAnimalCompanion.new("Barnaby", hero, &"bear")
	if bear.base_data.is_empty():
		push_error("FATAL: Bear base_data is empty in combat_test.gd! Skipping bear tests.")
	else:
		print("%s the %s starts at Level %d." % [bear.entity_name, bear.base_data["name"], bear.level])
		print("%s Max HP: %d (Base 8 + (6 + %d) * %d)" % [bear.entity_name, bear.health.max_hp, bear.base_data["con_mod"], bear.level])
		print("%s STR Mod: %d, Unarmed Proficiency: %s" % [bear.entity_name, bear.attributes.strength, PFMathConstants.ProficiencyRank.keys()[bear.sheet.weapon_proficiencies.get(PFEquipmentConstants.WeaponCategory.UNARMED, 0)]])
		
		bear.set_stage(PFAnimalCompanion.CompanionStage.MATURE)
		print("%s Max HP after Mature: %d" % [bear.entity_name, bear.health.max_hp])
		print("%s STR Mod after Mature: %d, Unarmed Proficiency: %s" % [bear.entity_name, bear.attributes.strength, PFMathConstants.ProficiencyRank.keys()[bear.sheet.weapon_proficiencies.get(PFEquipmentConstants.WeaponCategory.UNARMED, 0)]])
		
		bear.set_stage(PFAnimalCompanion.CompanionStage.SAVAGE)
		print("%s Max HP after Savage: %d" % [bear.entity_name, bear.health.max_hp])
		print("%s STR Mod after Savage: %d, Unarmed Proficiency: %s" % [bear.entity_name, bear.attributes.strength, PFMathConstants.ProficiencyRank.keys()[bear.sheet.weapon_proficiencies.get(PFEquipmentConstants.WeaponCategory.UNARMED, 0)]])
		
		familiar.start_turn()
		bear.start_turn()
		print("\nFamiliar actions at turn start: ", familiar.action_economy.actions_remaining)
		
		print("\nAction: Hero Commands the Bear...")
		hero.action_economy.actions_remaining -= 1
		bear.receive_command()
		
		print("Bear actions after command: ", bear.action_economy.actions_remaining)
		bear.support_benefit()
		bear.advanced_maneuver()
		
	print("\n--- TEST: CLASSES & SPELLCASTING ---")
	print("Attempting to apply Wizard class to Valeros...")
	hero.apply_class(&"wizard")
	
	if hero.actor_class:
		print("Valeros is now a level %d %s!" % [hero.level, hero.actor_class.entity_name])
		print("Spellbook initialized? ", hero.spellbook != null)
		if hero.spellbook:
			print("Max Slots for Rank 1: ", hero.spellbook.get_max_slots(1))
			print("Max Slots for Rank 2: ", hero.spellbook.get_max_slots(2))
			print("Max Slots for Rank 3: ", hero.spellbook.get_max_slots(3))
			
			var shield_spell = PFSpell.new(&"shield")
			var fireball_spell = PFSpell.new(&"fireball")
			
			hero.spellbook.cantrips.append(shield_spell)
			hero.spellbook.repertoire[3] = [fireball_spell]
			
			print("Casting Shield...")
			hero.spellbook.cast_spell(shield_spell)
			
			print("Casting Fireball at Rank 3...")
			hero.spellbook.cast_spell(fireball_spell)
			print("Casting Fireball again at Rank 3...")
			hero.spellbook.cast_spell(fireball_spell)
			print("Casting Fireball one more time at Rank 3...")
			hero.spellbook.cast_spell(fireball_spell)
	
	# ---------------------------------------------------------
	# 7. SETUP VISUAL 3D ENVIRONMENT FOR CAMERA TEST
	# ---------------------------------------------------------
	print("\n--- TEST: 3D CAMERA RIG INITIALIZATION ---")
	
	# Create a Floor
	var floor_mesh = CSGBox3D.new()
	floor_mesh.size = Vector3(50, 1, 50)
	floor_mesh.position = Vector3(0, -0.5, 0)
	
	# Create a simple checkerboard-like material for visual reference
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.2, 0.5, 0.2)
	floor_mesh.material = floor_mat
	add_child(floor_mesh)
	
	# Create a Medium Player Token (Billboard Sprite) - Fits in 1 Square
	var player_mesh = Sprite3D.new()
	player_mesh.texture = preload("res://icon.svg")
	player_mesh.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y # Always face camera horizontally
	player_mesh.pixel_size = 0.015 # Scale the texture to fit
	player_mesh.position = Vector3(0, 1.0, 0) # Standing on tile (0, 0)
	player_mesh.modulate = Color(0.5, 0.8, 1.0) # Tint Light Blue
	add_child(player_mesh)
	
	# Create a Large Monster Token (Billboard Sprite) - Fits in 4 Squares
	var large_monster = Sprite3D.new()
	large_monster.texture = preload("res://icon.svg")
	large_monster.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	large_monster.pixel_size = 0.03 # Double size
	large_monster.position = Vector3(2.5, 2.0, 2.5) # Centered over 4 tiles
	large_monster.modulate = Color(1.0, 0.4, 0.4) # Tint Red
	add_child(large_monster)
	
	# Lighting
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 45, 0)
	light.shadow_enabled = true
	add_child(light)
	
	# Initialize Game Root
	var game_root = PFGameRoot.new()
	add_child(game_root)
	
	# Register our new Combat Context
	var combat_context = PFCombatContext.new()
	combat_context.name = "CombatContext"
	game_root.contexts["CombatContext"] = combat_context
	
	# Transition into it, passing the necessary test data
	game_root.transition_to_context("CombatContext", {
		"hero": hero,
		"player_mesh": player_mesh
	})
	
	# We still highlight the tiles here for visual testing, 
	# but we ask the context's grid manager to do it
	var move_tiles: Array[Vector3] = []
	for x in range(-2, 3):
		for z in range(-2, 3):
			if x == 0 and z == 0: continue
			move_tiles.append(Vector3(x, 0, z))
			
	combat_context.grid_manager.highlight_tiles(move_tiles, PFCombatGrid.HighlightColor.MOVEMENT_BLUE)
	combat_context.grid_manager.update_cursor(Vector3(2, 0, 1))
	
	print("Game Root initialized and transitioned to Combat Context!")
