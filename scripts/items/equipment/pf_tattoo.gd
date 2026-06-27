# pf_tattoo.gd
## Represents magical tattoos etched onto the body. Tattoos are permanent 
## but still require the user to invest them to gain their magical benefits.
class_name PFTattoo
extends PFItem

func _init(p_name: String = "Magical Tattoo", p_traits: Array[StringName] = [&"tattoo", &"magical", &"invested"], p_level: int = 1, p_price_gp: float = 0.0):
	super._init(p_name, p_traits, p_level, p_price_gp, PFEquipmentConstants.ItemMaterial.STANDARD, 0, 0, 0, PFEquipmentConstants.MaterialGrade.STANDARD, 0)
	carry_state = PFEquipmentConstants.CarryState.WORN
	requires_investment = true

func apply_tattoo(actor: PFActor) -> void:
	print("    > %s receives a magical tattoo: %s." % [actor.entity_name, entity_name])
	if actor.inventory:
		actor.inventory.worn_items.append(self)
		actor.inventory.invest_item(self)
