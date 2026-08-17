# pf_alchemical_poison.gd
## Represents an alchemical poison that can be applied to weapons, ingested, or inhaled.
class_name PFAlchemicalPoison
extends PFConsumable

var poison_method: String = "injury" # Can be "injury", "ingested", "inhaled", "contact"
var affliction_id: StringName

func _init(p_id: String, p_name: String, p_level: int, p_method: String, p_affliction: StringName):
	super._init(p_id)
	
	if entity_name == "" or entity_name == "Unknown Consumable":
		entity_name = p_name
		level = p_level
		consumable_type = "poison"
		
	poison_method = p_method
	affliction_id = p_affliction
	
	if not traits.has(&"alchemical"):
		traits.append(&"alchemical")
	if not traits.has(&"consumable"):
		traits.append(&"consumable")
	if not traits.has(&"poison"):
		traits.append(&"poison")

func on_consume(consumer: PFActor) -> bool:
	if charges <= 0:
		print("    > [ERROR] %s is empty!" % entity_name)
		return false
		
	if poison_method == "ingested" or poison_method == "inhaled":
		print("    > %s consumes the poison %s!" % [consumer.entity_name, entity_name])
		_apply_affliction(consumer)
	else:
		print("    > %s cannot be consumed normally. It must be applied to a weapon." % entity_name)
		return false
		
	charges -= 1
	return true

func _apply_affliction(victim: PFActor) -> void:
	if victim and victim.has_method(&"apply_affliction_by_id"):
		victim.apply_affliction_by_id(affliction_id)
