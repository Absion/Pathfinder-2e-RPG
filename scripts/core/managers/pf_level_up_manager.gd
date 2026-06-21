# pf_level_up_manager.gd
## Generates a "blueprint" of pending choices and fixed bonuses when an actor levels up.
class_name PFLevelUpManager
extends RefCounted

## Analyzes an actor's current state and returns a blueprint of what they gain upon reaching the next level.
## It does NOT mutate the actor's state directly.
static func generate_level_up_blueprint(actor: PFPlayerCharacter) -> Dictionary:
	var next_level = actor.level + 1
	var blueprint = {
		"new_level": next_level,
		"hp_gain": 0,
		"feat_slots": [] as Array[StringName], # e.g. ["class", "skill", "ancestry"]
		"skill_increases": 0,
		"ability_boosts": 0, # at level 5, 10, 15, 20
		"granted_features": [] as Array[StringName]
	}
	
	print("--- LEVEL UP GENERATION: Analyzing %s reaching Level %d ---" % [actor.entity_name, next_level])
	
	# 1. HP Calculation (Blueprint only, not applied)
	var class_hp_per_level = 8
	if actor.actor_class:
		class_hp_per_level = actor.actor_class.hp_per_level
		
	var hp_gain = class_hp_per_level + actor.attributes.con_mod
	if hp_gain < 1: hp_gain = 1 # Minimum 1 HP per level
	blueprint["hp_gain"] = hp_gain
	
	# 2. Ability Boosts (Levels 5, 10, 15, 20)
	if next_level == 5 or next_level == 10 or next_level == 15 or next_level == 20:
		blueprint["ability_boosts"] = 4
		
	# 3. Class Progressions
	var db = PFDatabase.get_instance()
	if db and actor.actor_class:
		var class_id = str(actor.actor_class.entity_name).to_lower() 
		var prog_data = db.get_class_progression(class_id, next_level)
		
		if not prog_data.is_empty():
			# Fixed features
			var features_json = str(prog_data.get(&"granted_features", "[]"))
			if features_json != "" and features_json != "[]":
				var feature_list = JSON.parse_string(features_json)
				if feature_list and typeof(feature_list) == TYPE_ARRAY:
					for feature_id in feature_list:
						blueprint["granted_features"].append(StringName(feature_id))
						
			# Feat slots
			var feats_json = str(prog_data.get(&"granted_feat_slots", "[]"))
			if feats_json != "" and feats_json != "[]":
				var feat_slots = JSON.parse_string(feats_json)
				if feat_slots and typeof(feat_slots) == TYPE_ARRAY:
					for slot in feat_slots:
						blueprint["feat_slots"].append(StringName(slot))
						
			# Spells
			var spells_json = str(prog_data.get(&"granted_spells", "{}"))
			if spells_json != "" and spells_json != "{}" and spells_json != "null":
				var spells_data = JSON.parse_string(spells_json)
				if spells_data and typeof(spells_data) == TYPE_DICTIONARY:
					if spells_data.has("spells_learned"):
						blueprint["spells_learned"] = int(spells_data["spells_learned"])
					if spells_data.has("repertoire_slots_added"):
						blueprint["repertoire_slots_added"] = spells_data["repertoire_slots_added"]
					if spells_data.has("signature_spells_gained"):
						blueprint["signature_spells_gained"] = spells_data["signature_spells_gained"]
	# Add standard skill increase every even level
	if next_level % 2 == 0:
		blueprint["skill_increases"] = 1
		
	# Optional: Give rogues/investigators skill increases every level
	if actor.actor_class and (actor.actor_class.entity_name.to_lower() == "rogue" or actor.actor_class.entity_name.to_lower() == "investigator"):
		blueprint["skill_increases"] = 1
		
	return blueprint

static func apply_class_feature(_actor: PFPlayerCharacter, feature_id: StringName) -> void:
	var db = PFDatabase.get_instance()
	var feature_data = db.get_class_feature_data(feature_id)
	if feature_data.is_empty(): return
	
	print("    > Applied Class Feature: %s" % feature_data["name"])
	# Future: We can parse feature_data["granted_rules"] and programmatically apply effects
