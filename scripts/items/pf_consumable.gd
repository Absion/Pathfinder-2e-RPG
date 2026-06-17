# pf_consumable.gd
## Represents an item that is consumed upon use (potions, elixirs, scrolls, ammunition).
class_name PFConsumable
extends PFItem

var consumable_type: String
var charges: int
var max_charges: int
var spell_id: String

func _init(p_id: String):
	super._init()
	var db = PFDatabase.get_instance()
	if not db: return
	
	var data = db.query("SELECT * FROM consumables WHERE id = ?", [p_id])
	if data and data.size() > 0:
		var item_data = data[0]
		
		id = p_id
		entity_name = item_data.get("name", "Unknown Consumable")
		level = item_data.get("level", 1)
		base_level = level
		set_price_from_cp(item_data.get("price_cp", 0))
		base_price_cp = price_cp
		bulk_value = item_data.get("bulk", 1)
		base_bulk_value = bulk_value
		
		var raw_traits = item_data.get("traits", "")
		if raw_traits != "":
			var trait_strs = raw_traits.split(",")
			for t in trait_strs:
				add_trait(StringName(t.strip_edges()))
				
		consumable_type = item_data.get("consumable_type", "")
		charges = item_data.get("charges", 1)
		max_charges = item_data.get("max_charges", 1)
		spell_id = item_data.get("spell_id", "")

## Virtual method overridden by specific consumable scripts if needed,
## or parsed generically. Returns true if consumed successfully.
func on_consume(consumer: PFActor) -> bool:
	if charges <= 0:
		print("    > [ERROR] %s is empty!" % entity_name)
		return false
		
	# Base logic for generic healing potions as an example:
	if has_trait(&"healing") and consumable_type == "potion":
		print("    > %s drinks %s." % [consumer.entity_name, entity_name])
		# Actually applying healing requires parsing the exact dice amount,
		# but for now, we just reduce charges.
		
	elif consumable_type == "scroll" and spell_id != "":
		print("    > %s reads %s." % [consumer.entity_name, entity_name])
		# Typically this should trigger a PFActionCastSpell internally.
		
	charges -= 1
	return true
