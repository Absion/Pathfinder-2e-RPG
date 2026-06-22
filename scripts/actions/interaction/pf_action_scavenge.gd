# pf_action_scavenge.gd
## Allows a character to find and immediately wield an improvised weapon from their environment.
class_name PFActionScavenge
extends PFAction

var environment_tags: Array[StringName]

func _init(p_tags: Array[StringName] = []):
	environment_tags = p_tags
	var initial_traits: Array[StringName] = [&"manipulate", &"interact"]
	super._init("Scavenge Environment", initial_traits, PFCombatConstants.ActionCost.ONE_ACTION, 1)

func execute(user: PFActor, _target: PFActor = null) -> bool:
	var inv = user.get(&"inventory") as PFInventory
	if not inv:
		print("    > [ERROR] %s has no inventory and cannot scavenge!" % user.entity_name)
		return false
		
	var free_hands = 2
	if inv.held_main_hand: free_hands -= 1
	if inv.held_off_hand: free_hands -= 1
	if inv.two_handed_item: free_hands -= 2
	
	if free_hands <= 0:
		print("    > [ERROR] %s needs at least one free hand to scavenge and hold an item!" % user.entity_name)
		return false
		
	var item_name = "Improvised Debris"
	var item_traits: Array[StringName] = []
	var dmg_type = PFCombatConstants.DamageType.BLUDGEONING
	
	# Determine contextual item based on first matching tag
	var found = false
	for tag in environment_tags:
		if found: break
		match tag:
			&"forest", &"swamp", &"jungle":
				item_name = "Sturdy Branch"
				item_traits.append(&"wood")
				found = true
			&"road", &"mountain", &"cave":
				item_name = "Loose Rock"
				item_traits.append(&"stone")
				item_traits.append(&"thrown")
				found = true
			&"tavern", &"city":
				if randf() > 0.5:
					item_name = "Heavy Mug"
					item_traits.append(&"glass")
				else:
					item_name = "Broken Bottle"
					item_traits.append(&"glass")
					dmg_type = PFCombatConstants.DamageType.PIERCING
				found = true
			&"ruins", &"dungeon":
				item_name = "Rusted Pipe"
				item_traits.append(&"metal")
				found = true
				
	var scavenged_item = PFItem.new(item_name, item_traits)
	print("\n>>> %s scavenges the area and finds a %s!" % [user.entity_name, item_name])
	
	# Wield it in the first available hand
	var main_hand = (inv.held_main_hand == null)
	inv.wield_as_improvised(scavenged_item, main_hand, dmg_type)
	
	return true
