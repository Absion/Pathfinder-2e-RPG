# pf_augmentation.gd
## Represents physical body modifications, such as grafts, that permanently 
## alter the creature and bypass normal equipment slots.
class_name PFAugmentation
extends PFItem

func _init(p_name: String = "Augmentation", p_traits: Array[StringName] = [&"augmentation", &"magical"], p_level: int = 1, p_price_gp: float = 0.0):
	super._init(p_name, p_traits, p_level, p_price_gp, PFEquipmentConstants.ItemMaterial.STANDARD, 0, 0, 0, PFEquipmentConstants.MaterialGrade.STANDARD, 0)
	carry_state = PFEquipmentConstants.CarryState.WORN
	requires_investment = false # Most permanent grafts don't require daily investment unless specified

func apply_augmentation(actor: PFActor) -> void:
	print("    > %s undergoes a permanent physical augmentation: %s." % [actor.entity_name, entity_name])
	if actor.inventory:
		actor.inventory.worn_items.append(self)
