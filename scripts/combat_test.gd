extends Node

func _ready():
	# Ensure the dice rolls are different every time we run the game
	randomize() 
	
	print("\n" + "=" . repeat(50))
	print("PATHFINDER 2E ENGINE: COMPREHENSIVE COMBAT TEST")
	print("=" . repeat(50))
	
	# ---------------------------------------------------------
	# PHASE 1: THE MAGIC ITEM SHOP
	# ---------------------------------------------------------
	print("\n=== PHASE 1: FORGING & EQUIPPING ===")
	
	# Create a Level 10 Champion (High STR, Med DEX)
	var paladin = PFActor.new("Kaelen the Pure", [&"humanoid", &"human"], 10, false, 140, 19, 15, 17, 5, 2, 4, 0, 2, 4)
	
	# Create Base Items
	var sword = PFWeapon.new("Longsword", [&"versatile_p", &"holy"], 0, 1.0, PFWeapon.WeaponType.MELEE, PFWeapon.Category.MARTIAL, PFWeapon.Group.SWORD, 1, 8, PFDamage.Type.SLASHING)
	var armor = PFArmor.new("Full Plate", [&"bulwark"], 2, 30.0, PFArmor.Category.HEAVY, PFArmor.Group.PLATE, 6, 0, -3, -10, 4)
	var shield = PFShield.new("Fortress Shield", 1, 20.0, 3, 6, 24, 12, -10, PFItem.ItemMaterial.STEEL)
	
	# Apply Runes (This automatically upgrades Names, HP, Damage, Attack, AC, Level, and Price!)
	sword.apply_fundamental_runes(PFWeapon.PotencyRune.PLUS_TWO, PFWeapon.StrikingRune.GREATER) # Now 3d8!
	armor.apply_fundamental_runes(PFArmor.PotencyRune.PLUS_TWO, PFArmor.ResilientRune.GREATER)
	shield.apply_reinforcing_rune(PFShield.ReinforcingRune.MODERATE) # Now HP 132!
	
	# Equip to Paladin
	paladin.equipped_armor = armor
	paladin.equipped_shield = shield
	
	# Display final character stats
	print("\n-- Kaelen's Final Loadout --")
	print("Weapon: %s (Level %d, %s gp)" % [sword.entity_name, sword.level, sword.price_gp])
	print("Armor: %s (Level %d, %s gp)" % [armor.entity_name, armor.level, armor.price_gp])
	print("Shield: %s (Level %d, %s gp)" % [shield.entity_name, shield.level, shield.price_gp])
	print("Max Speed: %dft (Armor penalty offset by STR, Shield penalty remains)" % paladin.get_speed_land())
	print("Base AC: %d" % paladin.get_ac())
	print("Attack Bonus: +%d" % paladin.get_strike_bonus(sword))

	# ---------------------------------------------------------
	# PHASE 2: INITIALIZING THE MONSTER
	# ---------------------------------------------------------
	print("\n=== PHASE 2: A TERRIFYING FOE APPEARS ===")
	
	var vampire = PFActor.new("Vampire Lord", [&"undead", &"vampire"], 11, true, 180, 21, 23, 20, 6, 7, 4, 5, 4, 6)
	vampire.monster_stats["ac"] = 30
	vampire.monster_stats["attack"] = 24
	
	# The Vampire is weak to Holy, Slashing, and Fire!
	vampire.trait_weaknesses[&"holy"] = 10
	vampire.weaknesses[PFDamage.Type.SLASHING] = 5
	vampire.weaknesses[PFDamage.Type.FIRE] = 10
	
	var claws = PFWeapon.new("Vampiric Claws", [&"agile", &"finesse"], 0, 0, PFWeapon.WeaponType.MELEE, PFWeapon.Category.UNARMED, PFWeapon.Group.BRAWLING, 2, 8, PFDamage.Type.SLASHING)
	
	print("%s descends! (AC %d)" % [vampire.entity_name, vampire.get_ac()])

	# ---------------------------------------------------------
	# PHASE 3: COMBAT & ACTION ECONOMY
	# ---------------------------------------------------------
	print("\n=== PHASE 3: COMBAT INITIATED ===")
	
	paladin.start_turn()
	
	# ACTION 1: Raise Shield
	var raise = PFActionRaiseShield.new()
	paladin.use_action(raise)
	print("-> Kaelen's AC with raised shield is now: %d" % paladin.get_ac())
	
	# ACTION 2: Strike with the +2 Greater Striking Holy Longsword
	var strike = PFActionStrike.new(sword)
	paladin.use_action(strike, vampire) 
	# (Engine note: This will trigger BOTH Slashing and Holy weaknesses, stacking them!)
	
	# ACTION 3: Strike with the Shield Bash! 
	# (Demonstrates Agile MAP penalty, which should be -4 instead of -5)
	var bash = PFActionStrike.new(paladin.equipped_shield.get_bash_weapon())
	paladin.use_action(bash, vampire)
	
	paladin.end_turn()

	# ---------------------------------------------------------
	# PHASE 4: DEBUFFS & REACTION TRIGGERS
	# ---------------------------------------------------------
	print("\n=== PHASE 4: THE VAMPIRE STRIKES BACK ===")
	
	vampire.start_turn()
	
	# Apply Frightened to Kaelen to test dynamic condition debuffs
	print("\n-- The Vampire uses terrifying presence! --")
	var fear = PFConditionFrightened.new(2)
	paladin.apply_condition(fear)
	print("-> Kaelen's AC plummets to: %d" % paladin.get_ac())
	
	# ACTION 1: The Vampire strikes!
	var vamp_strike = PFActionStrike.new(claws)
	vampire.use_action(vamp_strike, paladin)
	# (Engine note: Because Kaelen is frightened, his AC is lower, making a hit/crit more likely. 
	# Because his shield is raised, the engine will trigger SHIELD BLOCK and damage the shield!)
	
	vampire.end_turn() # Frightened ticks down to 1 here!

	# ---------------------------------------------------------
	# PHASE 5: ADVANCED HEALING & PERSISTENT DAMAGE
	# ---------------------------------------------------------
	print("\n=== PHASE 5: VITALITY INVERSION & PERSISTENT DAMAGE ===")
	
	print("\n-- A Cleric casts a 3-Action Heal (Vitality) in the area! --")
	var heal_roll = PFDice.roll(4, 8).total # 4th rank heal
	
	# Kaelen is living, so he heals normally
	paladin.heal(heal_roll, PFDamage.Type.VITALITY)
	
	# Vampire is Undead, so the engine inverts it to Damage!
	vampire.heal(heal_roll, PFDamage.Type.VITALITY)
	
	print("\n-- The Cleric throws Alchemist Fire at the Vampire! --")
	# Applies Persistent Fire Damage (which triggers the Vampire's Fire Weakness)
	var burning = PFConditionPersistent.new(PFDamage.Type.FIRE, 1, 6)
	vampire.apply_condition(burning)
	
	print("\n-- End of Round 2 --")
	# Ending the Vampire's turn will trigger the persistent fire damage and the flat check!
	vampire.end_turn()
	
	print("\n" + "=" . repeat(50))
	print("COMBAT TEST COMPLETE")
	print("=" . repeat(50) + "\n")
	
	print("\n=== DWARVEN LINGUISTICS TEST ===")
	
