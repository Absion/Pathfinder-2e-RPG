# pf_level_up_manager.gd
## Manages the level-up transaction for an actor.
class_name PFLevelUpManager
extends RefCounted

## Processes a level-up for an actor. Returns a dictionary containing any pending choices (e.g. feat selections, skill increases) that the UI must resolve.
static func level_up(actor: PFPlayerCharacter) -> Dictionary:
	var pending_choices = {
		"feat_slots": [] as Array[StringName], # e.g. ["class", "skill", "ancestry"]
		"skill_increases": 0,
		"ability_boosts": 0 # at level 5, 10, 15, 20
	}
	
	actor.level += 1
	var new_level = actor.level
	
	print("--- LEVEL UP: %s reached Level %d! ---" % [actor.entity_name, new_level])
	
	# 1. HP Calculation
	var class_hp_per_level = 8
	if actor.actor_class:
		class_hp_per_level = actor.actor_class.hp_per_level
		
	var hp_gain = class_hp_per_level + actor.attributes.con_mod
	if hp_gain < 1: hp_gain = 1 # Minimum 1 HP per level
	
	actor.health.max_hp += hp_gain
	actor.health.current_hp = actor.health.max_hp
	print("    > HP increased by %d. New Max HP: %d" % [hp_gain, actor.health.max_hp])
	
	# 2. Ability Boosts (Levels 5, 10, 15, 20)
	if new_level == 5 or new_level == 10 or new_level == 15 or new_level == 20:
		pending_choices["ability_boosts"] += 4
		print("    > Gained 4 Ability Boosts!")
		
	# 3. Class Progressions
	var db = PFDatabase.get_instance()
	if db and actor.actor_class:
		# Extract the base class ID from entity_name, or actor_class should store it
		# For this implementation, we assume the class ID is the lowercase class name
		var class_id = str(actor.actor_class.entity_name).to_lower() 
		var prog_data = db.get_class_progression(class_id, new_level)
		
		if not prog_data.is_empty():
			# Apply fixed features
			var features_json = str(prog_data.get("granted_features", "[]"))
			if features_json != "" and features_json != "[]":
				var feature_list = JSON.parse_string(features_json)
				if feature_list and typeof(feature_list) == TYPE_ARRAY:
					for feature_id in feature_list:
						_apply_class_feature(actor, StringName(feature_id))
						
			# Queue up granted feat slots
			var feats_json = str(prog_data.get("granted_feat_slots", "[]"))
			if feats_json != "" and feats_json != "[]":
				var feat_slots = JSON.parse_string(feats_json)
				if feat_slots and typeof(feat_slots) == TYPE_ARRAY:
					for slot in feat_slots:
						pending_choices["feat_slots"].append(StringName(slot))
						print("    > Gained Feat Slot: %s" % slot)
						
	return pending_choices

static func _apply_class_feature(actor: PFPlayerCharacter, feature_id: StringName) -> void:
	var db = PFDatabase.get_instance()
	var feature_data = db.get_class_feature_data(feature_id)
	if feature_data.is_empty(): return
	
	print("    > Granted Class Feature: %s" % feature_data["name"])
	
	# Future: We can parse feature_data["granted_rules"] and programmatically apply effects
	# e.g. {"set_proficiency": {"spellcasting": 2}}
