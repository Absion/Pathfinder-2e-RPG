# pf_sense.gd
class_name PFSense
extends RefCounted

enum Type { 
	VISION, 
	HEARING, 
	SCENT, 
	TREMORSENSE, 
	ECHOLOCATION, 
	LIFESENSE, 
	THOUGHTSENSE, 
	WAVESENSE, 
	MOTIONSENSE,
	APPARITION_SIGHT,
	SPIRITSENSE,
	TOUCH,
	TASTE
}

enum Acuity { 
	PRECISE, 
	IMPRECISE, 
	VAGUE 
}

var type: Type
var acuity: Acuity
var range_ft: int # 0 indicates an unlimited/standard range

func _init(p_type: Type, p_acuity: Acuity, p_range_ft: int = 0):
	type = p_type
	acuity = p_acuity
	range_ft = p_range_ft

func get_sense_string() -> String:
	var type_name = Type.keys()[type].capitalize().replace("_", " ")
	var acuity_name = Acuity.keys()[acuity].capitalize()
	
	if range_ft > 0:
		return "%s (%s) %d ft." % [type_name, acuity_name, range_ft]
	return "%s (%s)" % [type_name, acuity_name]
