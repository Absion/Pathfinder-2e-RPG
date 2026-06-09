# pf_feat.gd
## Represents an individual feat selected by an actor
class_name PFFeat
extends PFEntity

enum FeatType {
	ANCESTRY,
	CLASS,
	SKILL,
	GENERAL,
	ARCHETYPE,
	BONUS
}

var feat_type: FeatType
var required_level: int
var prerequisites_json: String
var granted_rules_json: String
var description: String

func _init(p_id: StringName):
	var db = PFDatabase.get_instance()
	var f_data = db.get_feat_data(p_id)
	
	if f_data.is_empty():
		entity_name = "Unknown Feat"
		return
		
	var feat_traits: Array[StringName] = []
	if f_data["traits"] and f_data["traits"] != "":
		var parsed = JSON.parse_string(f_data["traits"])
		if parsed:
			for t in parsed: feat_traits.append(StringName(t))
			
	id = p_id
	entity_name = str(f_data["name"])
	traits = feat_traits
	rarity = PFBiographyConstants.Rarity.COMMON
	
	feat_type = f_data["feat_type"] as FeatType
	required_level = f_data["level"]
	prerequisites_json = str(f_data["prerequisites"])
	granted_rules_json = str(f_data["granted_rules"])
	description = str(f_data["description"])
