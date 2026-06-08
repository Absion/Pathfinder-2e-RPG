# pf_spell.gd
## Represents a magical spell that can be cast by an actor.
class_name PFSpell
extends PFEntity

var base_spell_rank: int
var cast_time: String # 1, 2, 3, reaction, free
var range_ft: int
var targets: String
var saving_throw: String
var duration: String
var is_cantrip: bool
var description: String

func _init(p_id: StringName):
	var db = PFDatabase.get_instance()
	var s_data = db.get_spell_data(p_id)
	
	if s_data.is_empty():
		entity_name = "Unknown Spell"
		return
		
	var spell_traits: Array[StringName] = []
	if s_data["traits"] and s_data["traits"] != "":
		var parsed = JSON.parse_string(s_data["traits"])
		if parsed:
			for t in parsed: spell_traits.append(StringName(t))
			
	entity_name = str(s_data["name"])
	traits = spell_traits
	rarity = PFBiographyConstants.Rarity.COMMON
	
	base_spell_rank = s_data["base_spell_rank"]
	cast_time = str(s_data["cast_time"])
	range_ft = s_data["range_ft"]
	targets = str(s_data["targets"])
	saving_throw = str(s_data["saving_throw"])
	duration = str(s_data["duration"])
	is_cantrip = s_data["is_cantrip"] == 1
	description = str(s_data["description"])
