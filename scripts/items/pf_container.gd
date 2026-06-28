# pf_container.gd
class_name PFContainer
extends PFItem

var stored_items: Array[PFItem] = []
var bulk_capacity: int = 40 # Total bulk it can hold, e.g. 4 Bulk

func add_item(item: PFItem) -> bool:
	if get_contents_bulk() + item.bulk_value > bulk_capacity:
		print("    > Cannot fit %s into %s!" % [item.entity_name, entity_name])
		return false
		
	stored_items.append(item)
	item.carry_state = PFEquipmentConstants.CarryState.STOWED
	print("    > Stowed %s inside %s." % [item.entity_name, entity_name])
	return true

func remove_item(item: PFItem) -> bool:
	if stored_items.has(item):
		stored_items.erase(item)
		return true
	return false

func get_contents_bulk() -> int:
	var total = 0
	for item in stored_items:
		total += item.bulk_value
	return total

func get_bulk() -> int:
	# Container's own bulk + contents bulk - reduction (min 0 for contents)
	var contents_bulk = maxi(0, get_contents_bulk() - bulk_reduction_value)
	return bulk_value + contents_bulk
