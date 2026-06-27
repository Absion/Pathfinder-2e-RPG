# pf_action_interact.gd
## Allows actors to manipulate their equipment states with action costs.
class_name PFActionInteract
extends PFAction

enum InteractType { 
	DRAW, STOW, RETRIEVE, RELEASE, PICK_UP,
	SWAP, PASS_OFF, TAKE, THROW, DETACH, CHANGE_GRIP_ADD, CHANGE_GRIP_REMOVE
}

var interact_type: InteractType
var target_item: PFItem
var secondary_item: PFItem
var main_hand: bool

func _init(p_interact_type: InteractType, p_item: PFItem, p_main_hand: bool = true, p_secondary_item: PFItem = null):
	var action_name = "Interact"
	match p_interact_type:
		InteractType.DRAW: action_name = "Draw"
		InteractType.STOW: action_name = "Stow"
		InteractType.RETRIEVE: action_name = "Retrieve"
		InteractType.RELEASE: action_name = "Release"
		InteractType.PICK_UP: action_name = "Pick Up"
		InteractType.SWAP: action_name = "Swap"
		InteractType.PASS_OFF: action_name = "Pass Off"
		InteractType.TAKE: action_name = "Take"
		InteractType.THROW: action_name = "Throw"
		InteractType.DETACH: action_name = "Detach Shield"
		InteractType.CHANGE_GRIP_ADD: action_name = "Add Hand to Grip"
		InteractType.CHANGE_GRIP_REMOVE: action_name = "Remove Hand from Grip"
	
	super._init(action_name, [&"manipulate"], PFCombatConstants.ActionCost.ONE_ACTION)
	
	interact_type = p_interact_type
	target_item = p_item
	secondary_item = p_secondary_item
	main_hand = p_main_hand
	
	if interact_type == InteractType.RETRIEVE:
		cost = PFCombatConstants.ActionCost.TWO_ACTIONS
	elif interact_type == InteractType.RELEASE or interact_type == InteractType.CHANGE_GRIP_REMOVE:
		cost = PFCombatConstants.ActionCost.FREE

func is_usable(user: PFActor) -> bool:
	if not user.inventory:
		return false
		
	if target_item == null:
		return false
		
	match interact_type:
		InteractType.DRAW:
			if target_item.carry_state != PFEquipmentConstants.CarryState.WORN:
				print("    > %s must be WORN to Draw it." % target_item.entity_name)
				return false
		InteractType.STOW:
			if target_item.carry_state != PFEquipmentConstants.CarryState.HELD:
				print("    > %s must be HELD to Stow it." % target_item.entity_name)
				return false
		InteractType.RETRIEVE:
			if target_item.carry_state != PFEquipmentConstants.CarryState.STOWED:
				print("    > %s must be STOWED to Retrieve it." % target_item.entity_name)
				return false
		InteractType.RELEASE:
			if target_item.carry_state != PFEquipmentConstants.CarryState.HELD:
				print("    > %s must be HELD to Release it." % target_item.entity_name)
				return false
		InteractType.PICK_UP:
			if target_item.carry_state != PFEquipmentConstants.CarryState.DROPPED:
				print("    > %s must be DROPPED to Pick Up." % target_item.entity_name)
				return false
		InteractType.SWAP:
			if target_item.carry_state != PFEquipmentConstants.CarryState.HELD:
				print("    > %s must be HELD to Stow it." % target_item.entity_name)
				return false
			if secondary_item == null or secondary_item.carry_state != PFEquipmentConstants.CarryState.WORN:
				print("    > Secondary item must be WORN to Draw it for a Swap.")
				return false
		InteractType.PASS_OFF, InteractType.THROW:
			if target_item.carry_state != PFEquipmentConstants.CarryState.HELD:
				print("    > %s must be HELD to pass or throw it." % target_item.entity_name)
				return false
		InteractType.TAKE:
			if target_item.carry_state != PFEquipmentConstants.CarryState.HELD:
				print("    > %s must be HELD by someone else to take it." % target_item.entity_name)
				return false
		InteractType.DETACH:
			if target_item.carry_state != PFEquipmentConstants.CarryState.WORN:
				print("    > %s must be WORN (strapped) to detach it." % target_item.entity_name)
				return false
		InteractType.CHANGE_GRIP_ADD:
			if target_item.carry_state != PFEquipmentConstants.CarryState.HELD:
				print("    > %s must be HELD to change grip." % target_item.entity_name)
				return false
		InteractType.CHANGE_GRIP_REMOVE:
			if target_item.carry_state != PFEquipmentConstants.CarryState.HELD:
				print("    > %s must be HELD to change grip." % target_item.entity_name)
				return false
				
	return true

func execute(user: PFActor, _target: Variant = null) -> Variant:
	if await check_trait_triggers(user):
		return false # Disrupted
		
	print("%s uses %s on %s!" % [user.entity_name, entity_name, target_item.entity_name])
	
	match interact_type:
		InteractType.DRAW, InteractType.RETRIEVE, InteractType.PICK_UP:
			# If it's WORN/STOWED, remove it from worn/stowed internally if we are making it HELD?
			# Hold_item automatically sets HELD state
			user.inventory.hold_item(target_item, main_hand)
			if interact_type == InteractType.DRAW:
				user.inventory.worn_items.erase(target_item)
		InteractType.STOW:
			# Held -> Worn/Stowed
			user.inventory.release_item(main_hand)
			user.inventory.equip_item(target_item) # Puts it in Worn
		InteractType.SWAP:
			user.inventory.release_item(main_hand)
			user.inventory.equip_item(target_item)
			user.inventory.hold_item(secondary_item, main_hand)
			user.inventory.worn_items.erase(secondary_item)
		InteractType.RELEASE:
			user.inventory.release_item(main_hand)
		InteractType.CHANGE_GRIP_REMOVE:
			user.inventory.change_grip(false, target_item)
		InteractType.CHANGE_GRIP_ADD:
			user.inventory.change_grip(true, target_item)
		InteractType.DETACH:
			user.inventory.unequip_item(target_item)
			user.inventory.hold_item(target_item, main_hand)
		InteractType.PASS_OFF:
			if _target != null and _target.inventory:
				user.inventory.pass_item(_target, target_item, main_hand)
		InteractType.TAKE:
			if _target != null and _target.inventory:
				_target.inventory.pass_item(user, target_item, main_hand)
		InteractType.THROW:
			if _target != null:
				var is_ally = (user is PFPlayerCharacter and _target is PFPlayerCharacter) or (user is PFNpc and _target is PFNpc)
				if is_ally: # Throwing to ally
					# Perform DC 15 check
					print("    > %s throws %s to %s!" % [user.entity_name, target_item.entity_name, _target.entity_name])
					var roll = randi_range(1, 20) + user.attributes.dex_mod # Simple Ranged throw check
					if roll >= 15 and _target.inventory:
						print("    > %s catches the %s!" % [_target.entity_name, target_item.entity_name])
						user.inventory.pass_item(_target, target_item, main_hand)
					else:
						print("    > %s fails to catch the %s!" % [_target.entity_name, target_item.entity_name])
						user.inventory.release_item(main_hand)
				else: # Throwing at enemy
					print("    > %s throws %s at %s as an improvised weapon!" % [user.entity_name, target_item.entity_name, _target.entity_name])
					user.inventory.release_item(main_hand)
					if target_item is PFConsumable:
						target_item.current_hp = 0 # Destroy consumable on impact
						print("    > %s shatters on impact!" % target_item.entity_name)
					else:
						print("    > %s drops to the ground in %s's space." % [target_item.entity_name, _target.entity_name])
	return true
