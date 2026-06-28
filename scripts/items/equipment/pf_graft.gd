# pf_graft.gd
## Represents magical or alchemical body grafts. Grafts are permanent 
## but still require the user to invest them to gain their benefits.
class_name PFGraft
extends PFItem

func _init(p_name: String = "Graft", p_traits: Array[StringName] = [&"graft", &"magical", &"invested"], p_level: int = 1, p_price_gp: float = 0.0):
	super._init(p_name, p_traits, p_level, p_price_gp, PFEquipmentConstants.ItemMaterial.STANDARD, 0, 0, 0, PFEquipmentConstants.MaterialGrade.STANDARD, 0)
	carry_state = PFEquipmentConstants.CarryState.WORN
	requires_investment = true

func apply_graft(actor: PFActor) -> void:
	print("    > %s receives a body graft: %s." % [actor.entity_name, entity_name])
	if actor.inventory:
		actor.inventory.worn_items.append(self)
		actor.inventory.invest_item(self)
