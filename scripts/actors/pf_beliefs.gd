# pf_beliefs.gd
class_name PFBeliefs
extends RefCounted

static func get_belief_data(id: StringName) -> Dictionary:
	var db_inst = PFDatabase.get_instance()
	return db_inst.get_belief_data(id) if db_inst else {}

static func is_valid_edict(edict: StringName) -> bool:
	var data = get_belief_data(edict)
	return data.has(&"type") and data["type"] == "edict"

static func is_valid_anathema(anathema: StringName) -> bool:
	var data = get_belief_data(anathema)
	return data.has(&"type") and data["type"] == "anathema"
