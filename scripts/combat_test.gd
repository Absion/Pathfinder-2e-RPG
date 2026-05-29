extends Node

func _ready():
	randomize() 
	
	print("\n=== SANCTIFICATION & HEALING TEST ===")
	
	var paladin = PFActor.new("Champion", [&"humanoid"], 5, false, 60, 10, 10, 10, 4, 2, 2, 0, 0, 0)
	var zombie = PFActor.new("Zombie Brute", [&"undead", &"mindless"], 3, true, 40, 8, 12, 7, 3, 4, 2, -1, 1, 2)
	zombie.monster_stats["ac"] = 15
	
	# The Zombie is Weak to Slashing (5) and Weak to Holy (10)
	zombie.weaknesses[PFDamage.Type.SLASHING] = 5
	zombie.trait_weaknesses[&"holy"] = 10
	
	# The Paladin swings a Holy Greatsword
	var holy_sword = PFWeapon.new("Holy Greatsword", [&"holy"], 
		PFWeapon.WeaponType.MELEE, PFWeapon.Category.MARTIAL, PFWeapon.Group.SWORD, 
		1, 12, PFDamage.Type.SLASHING)
	
	paladin.start_turn()
	var strike = PFActionStrike.new(holy_sword)
	
	# When the Paladin hits, the Zombie is weak to BOTH Slashing and Holy.
	# The engine will correctly apply both weaknesses independently!
	paladin.use_action(strike, zombie)
	
	# Later in the turn, a Cleric casts a 3-action "Heal" spell (Vitality damage) in the area.
	# The Zombie takes Vitality damage because it is undead.
	print("\n-- Cleric casts AoE Heal (Vitality) --")
	zombie.heal(8, PFDamage.Type.VITALITY)
	
	# The Paladin is in the area too, but she is living, so she heals normally!
	paladin.heal(8, PFDamage.Type.VITALITY)
	
	# A Necromancer tries to cast a Void spell on the Paladin.
	# The engine will flip it into damage!
	print("\n-- Necromancer casts Void damage on Paladin --")
	paladin.heal(12, PFDamage.Type.VOID)
