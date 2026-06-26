# pf_action_interact.gd
## Allows actors to manipulate their equipment states with action costs.
class_name PFActionInteract
extends PFAction

enum InteractType { DRAW, STOW, RETRIEVE, RELEASE, PICK_UP }

var interact_type: InteractType
var target_item: PFItem
var main_hand: bool

func _init(p_interact_type: InteractType, p_item: PFItem, p_main_hand: bool = true):
	var action_name = "Interact"
	if p_interact_type == InteractType.DRAW: action_name = "Draw"
	elif p_interact_type == InteractType.STOW: action_name = "Stow"
	elif p_interact_type == InteractType.RETRIEVE: action_name = "Retrieve"
	elif p_interact_type == InteractType.RELEASE: action_name = "Release"
	elif p_interact_type == InteractType.PICK_UP: action_name = "Pick Up"
	
	super._init(action_name, [&"manipulate"], PFCombatConstants.ActionCost.ONE_ACTION)
	
	interact_type = p_interact_type
	target_item = p_item
	main_hand = p_main_hand
	
	if interact_type == InteractType.RETRIEVE:
		cost = PFCombatConstants.ActionCost.TWO_ACTIONS
	elif interact_type == InteractType.RELEASE:
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
				
	return true

func execute(user: PFActor, _target: PFActor = null) -> Variant:
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
		InteractType.RELEASE:
			user.inventory.release_item(main_hand)
			
	return true
