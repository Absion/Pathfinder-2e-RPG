# pf_sense.gd
## Represents a specialized sense like Darkvision or Tremorsense.
class_name PFSense
extends RefCounted

var type: PFBiographyConstants.SenseType
var acuity: PFBiographyConstants.SenseAcuity
var range_ft: int # 0 indicates an unlimited/standard range

func _init(p_type: PFBiographyConstants.SenseType, p_acuity: PFBiographyConstants.SenseAcuity, p_range_ft: int = 0):
	type = p_type
	acuity = p_acuity
	range_ft = p_range_ft

func get_sense_string() -> String:
	var type_name = PFBiographyConstants.SenseType.keys()[type].capitalize().replace("_", " ")
	var acuity_name = PFBiographyConstants.SenseAcuity.keys()[acuity].capitalize()
	
	if range_ft > 0:
		return "%s (%s) %d ft." % [type_name, acuity_name, range_ft]
	return "%s (%s)" % [type_name, acuity_name]
