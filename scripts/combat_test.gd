# combat_test.gd
extends Node

func _ready():
	randomize() 
	
	var gunslinger = PFActor.new("Gunslinger", [&"humanoid"], 30, 16, 5, 8, 4, 1, 4, 1, 0, 0, 0)
	var skeleton = PFActor.new("Skeleton Guard", [&"undead"], 30, 5, 4, 6, 2, 2, 4, 1, -5, 0, 0)
	
	# Skeleton is heavily resistant to piercing, but weak to bludgeoning!
	skeleton.weaknesses[PFDamage.Type.BLUDGEONING] = 5
	skeleton.resistances[PFDamage.Type.PIERCING] = 5
	
	# Flintlock Pistol: 1d4 Piercing. Has Fatal d8 AND Concussive!
	# We pass deadly=0, fatal=8
	var pistol = PFWeapon.new("Flintlock Pistol", [&"concussive"], 
		PFWeapon.WeaponType.RANGED, PFWeapon.Category.MARTIAL, PFWeapon.Group.FIREARM, 
		1, 4, PFDamage.Type.PIERCING, 0, 8)
		
	# Longsword: 1d8 Slashing. Has Versatile Piercing!
	var longsword = PFWeapon.new("Longsword", [&"versatile_p"], 
		PFWeapon.WeaponType.MELEE, PFWeapon.Category.MARTIAL, PFWeapon.Group.SWORD, 
		1, 8, PFDamage.Type.SLASHING)
		
	print("\n=== TESTING VERSATILE TRAIT ===")
	# Fighter wants to pierce the enemy instead of slash
	longsword.set_versatile_type(PFDamage.Type.PIERCING)
	
	# If they try to switch to Bludgeoning, Godot will throw a red error!
	# longsword.set_versatile_type(PFDamage.Type.BLUDGEONING) 
	
	print("\n=== TESTING GUNSLINGER (CONCUSSIVE & FATAL) ===")
	gunslinger.start_turn()
	
	# The pistol is Piercing, which the skeleton resists.
	# But because it is Concussive, the engine will automatically swap it to Bludgeoning 
	# right before damage is applied, bypassing the resistance AND triggering the weakness!
	var shoot = PFActionStrike.new(pistol)
	gunslinger.use_action(shoot, skeleton)
