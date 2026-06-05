# combat_test.gd
extends Node

func _ready():
	print("==================================================")
	print("   PATHFINDER 2E ENGINE: UNIFIED SYSTEMS TEST")
	print("==================================================")
	
	# ---------------------------------------------------------
	# 1. SETUP ACTORS
	# ---------------------------------------------------------
	print("\n--- TEST: ACTOR CREATION ---")
	
	# Initialize Database for test
	var pf_db = preload("res://scripts/database/pf_database.gd").new()
	pf_db._ready()
	
	var hero = PFActor.new("Valeros", [&"humanoid", &"human"], 5, false, 
		68, 12, 9, 10,  # HP, Fort, Ref, Will
		4, 2, 3, 0, 1, 1 # STR, DEX, CON, INT, WIS, CHA
	)
	
	# Apply DB data
	hero.apply_ancestry(pf_db.get_ancestry("human"))
	hero.apply_background(pf_db.get_background("farmhand"))
	hero.apply_class(pf_db.get_pf_class("fighter"))
	
	var abadar = pf_db.get_pf_deity("abadar")
	if abadar:
		hero.apply_deity(abadar)
		print("Abadar Cleric Spells: ", abadar.cleric_spells)
	
	hero.auto_shield_block = true
	
	var orc = PFActor.new("Orc Brute", [&"humanoid", &"orc"], 5, true, 
		75, 14, 8, 8, 
		5, 1, 4, -1, 0, -1
	)
	orc.monster_stats = {"ac": 21, "attack": 15, "damage": 12}
	
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
		PFItem.ItemMaterial.STANDARD, 1, 5, 0, PFItem.MaterialGrade.STANDARD, 1, 0, true)
	
	# Create Weapons & Armor
	var breastplate = PFArmor.new("Breastplate", [], 1, 8.0, PFArmor.Category.MEDIUM, PFArmor.Group.PLATE, 4, 1, -5, 16)
	var longsword = pf_db.get_weapon("longsword")
	var dagger = PFWeapon.new("Dagger", [&"agile", &"finesse", &"thrown_10"], 1, 0.2, PFWeapon.WeaponType.MELEE, PFWeapon.Category.SIMPLE, PFWeapon.Group.KNIFE, 1, 4, PFDamage.Type.PIERCING, PFItem.ItemMaterial.STEEL, 3, 12)
	
	# Create Shields
	var buckler = pf_db.get_shield("buckler")
	
	var steel_shield = pf_db.get_shield("steel_shield")
	# Test the dynamic reinforcing rune logic
	steel_shield.apply_reinforcing_rune(PFShield.ReinforcingRune.MINOR)
	
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
	var potion = PFItem.new("Healing Potion", [&"consumable"], 1, 4.0, PFItem.ItemMaterial.STEEL, 1, 2)
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
	hero.take_damage(20, PFDamage.Type.SLASHING)
	
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
	var bear = PFAnimalCompanion.new("Barnaby", hero, "Bear", hero.sheet.level, 30, 8, 6, 6, 3, 2, 3, -4, 1, 0, 25)
	
	print("%s (Familiar) Max HP: %d" % [familiar.entity_name, familiar.max_hp])
	print("%s (Companion) Level updates to master's level: %d" % [bear.entity_name, bear.sheet.level])
	
	familiar.start_turn()
	bear.start_turn()
	print("Familiar actions at turn start: ", familiar.actions_remaining)
	
	print("\nAction: Hero Commands the Bear...")
	hero.actions_remaining -= 1
	bear.receive_command()
	
	print("Bear actions after command: ", bear.actions_remaining)
	bear.support_benefit()
	
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
	
	# Initialize Camera Rig
	var camera_rig = PFCameraRig.new()
	add_child(camera_rig)
	
	# Set the blue cube as the tracked target
	camera_rig.tracked_target = player_mesh
	camera_rig.focus_on_position(player_mesh.global_position, true)
	
	# Initialize Combat Grid
	var combat_grid = PFCombatGrid.new()
	add_child(combat_grid)
	
	# Draw the massive faint background grid for combat
	combat_grid.draw_base_grid(50, 50)
	
	# Test drawing a 3x3 Movement range around the player
	var move_tiles: Array[Vector3] = []
	for x in range(-2, 3):
		for z in range(-2, 3):
			# Skip the exact tile the player is standing on (0,0)
			if x == 0 and z == 0: continue
			move_tiles.append(Vector3(x, 0, z))
			
	combat_grid.highlight_tiles(move_tiles, PFCombatGrid.HighlightColor.MOVEMENT_BLUE)
	
	# Test the cursor
	combat_grid.update_cursor(Vector3(2, 0, 1))
	
	# Initialize UI
	var ui_canvas = CanvasLayer.new()
	add_child(ui_canvas)
	
	var action_menu = PFActionMenu.new()
	ui_canvas.add_child(action_menu)
	action_menu.bind_to_actor(hero)
	
	print("Camera Rig, Combat Grid, and Action Menu added!")
