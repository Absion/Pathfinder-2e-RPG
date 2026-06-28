# pf_level_up_service.gd
## A Sandbox Builder for managing a character's pending level up transaction without mutating the character until confirmed.
class_name PFLevelUpService
extends RefCounted

var _actor: PFPlayerCharacter
var _blueprint: Dictionary

var preview_hp: int = 0
var selected_feats: Dictionary = {} # slot_index (int) -> PFFeat
var selected_skills: Array[StringName] = []

func begin_level_up(actor: PFPlayerCharacter, blueprint: Dictionary) -> void:
	_actor = actor
	_blueprint = blueprint
	preview_hp = _actor.health.max_hp + blueprint.get(&"hp_gain", 0)
	selected_feats.clear()
	selected_skills.clear()

func get_preview_stats() -> Dictionary:
	var stats = {
		"hp": preview_hp,
		"level": _blueprint.get(&"new_level", _actor.level)
	}
	return stats

func get_available_feats(slot_type: StringName) -> Array[Dictionary]:
	var database = PFDatabase.get_instance()
	if not database: return []
	
	# Fetch all feats from the database
	database.query("SELECT * FROM feats")
	var all_feats = database.query_result
	var valid_feats: Array[Dictionary] = []
	
	for row in all_feats:
		var type_int = row["feat_type"] as int
		var feat_type_enum = type_int as PFFeat.FeatType
		
		var feat_type_str = _feat_type_to_string(feat_type_enum)
		
		var is_valid_type = (feat_type_str == slot_type) or (slot_type == "bonus")
		# Archetype feats can be taken in Class feat slots
		if slot_type == "class" and feat_type_str == "archetype":
			is_valid_type = true
			
		if not is_valid_type:
			continue
			
		var required_level = row["level"] as int
		if required_level > _blueprint.get(&"new_level", _actor.level):
			continue
			
		# Check prerequisites
		var prereqs_json = row["prerequisites"] as String
		if not _meets_prerequisites(prereqs_json):
			continue
			
		valid_feats.append({
			"id": StringName(row["id"]),
			"name": row["name"],
			"description": row["description"]
		})
		
	return valid_feats

func _feat_type_to_string(type: PFFeat.FeatType) -> StringName:
	match type:
		PFFeat.FeatType.ANCESTRY: return &"ancestry"
		PFFeat.FeatType.CLASS: return &"class"
		PFFeat.FeatType.SKILL: return &"skill"
		PFFeat.FeatType.GENERAL: return &"general"
		PFFeat.FeatType.ARCHETYPE: return &"archetype"
		PFFeat.FeatType.BONUS: return &"bonus"
	return &"unknown"

func _meets_prerequisites(prereqs_json: String) -> bool:
	if prereqs_json == "" or prereqs_json == "{}": return true
	var prereq = JSON.parse_string(prereqs_json)
	if not prereq: return true
	
	if prereq.has(&"ancestry"):
		if not _actor.ancestry or str(_actor.ancestry.id) != prereq["ancestry"]:
			return false
			
	if prereq.has(&"ethnicity"):
		if str(_actor.ethnicity) != prereq["ethnicity"]:
			return false
			
	if prereq.has(&"min_stats"):
		for stat in prereq["min_stats"]:
			var required_val = prereq["min_stats"][stat] as int
			if _actor.get_ability_modifier(StringName(stat).to_upper()) < required_val:
				return false
				
	if prereq.has(&"min_proficiency"):
		for skill in prereq["min_proficiency"]:
			var req_rank = prereq["min_proficiency"][skill] as int
			var current_rank = _actor.sheet.get_skill_rank(StringName(skill)) as int
			# also check if they selected it in this sandbox!
			if selected_skills.has(StringName(skill)):
				current_rank += 1 
			if current_rank < req_rank:
				return false
				
	if prereq.has(&"requires_feat"):
		var feat_id = prereq["requires_feat"]
		var has_feat = false
		for feat in _actor.feats:
			if str(feat.id) == feat_id: has_feat = true
		for s in selected_feats.values():
			if str(s.id) == feat_id: has_feat = true
		if not has_feat: return false
		
	return true

func select_feat(slot_index: int, feat_id: StringName) -> bool:
	if slot_index >= _blueprint.get(&"feat_slots", []).size(): return false
	
	var feat = PFFeat.new(feat_id)
	if feat.entity_name == "Unknown Feat": return false
	
	selected_feats[slot_index] = feat
	
	# If the feat grants HP (e.g. Toughness), update preview
	if feat_id == &"toughness":
		preview_hp += _blueprint.get(&"new_level", _actor.level)
		
	return true

func undo_feat(slot_index: int) -> void:
	if selected_feats.has(slot_index):
		var feat = selected_feats[slot_index]
		if feat.id == &"toughness":
			preview_hp -= _blueprint.get(&"new_level", _actor.level)
		selected_feats.erase(slot_index)

func select_skill(skill_name: StringName) -> bool:
	var max_increases = _blueprint.get(&"skill_increases", 0)
	if selected_skills.size() >= max_increases:
		return false
		
	var current_rank = _actor.sheet.get_skill_rank(skill_name)
	# Pre-validate if they can actually upgrade it based on level limits
	var next_level = _blueprint.get(&"new_level", _actor.level)
	if current_rank == PFMathConstants.ProficiencyRank.TRAINED and next_level < 2: return false
	if current_rank == PFMathConstants.ProficiencyRank.EXPERT and next_level < 7: return false
	if current_rank == PFMathConstants.ProficiencyRank.MASTER and next_level < 15: return false
	if current_rank == PFMathConstants.ProficiencyRank.LEGENDARY: return false
	
	selected_skills.append(skill_name)
	return true

func commit_transaction() -> void:
	_actor.level = _blueprint["new_level"]
	_actor.health.max_hp = preview_hp
	_actor.health.current_hp = preview_hp
	
	var history_entry = {
		"feat_slots": {},
		"skill_increases": selected_skills.duplicate(),
		"granted_features": _blueprint.get(&"granted_features", [])
	}
	
	var slots = _blueprint.get(&"feat_slots", [])
	for i in range(slots.size()):
		var slot_type = slots[i]
		if selected_feats.has(i):
			var feat = selected_feats[i]
			_actor.feats.append(feat)
			history_entry["feat_slots"][slot_type] = str(feat.id)
			
	for skill in selected_skills:
		_actor.sheet.upgrade_skill(skill, _actor.level)
		
	for feature_id in _blueprint.get(&"granted_features", []):
		PFLevelUpManager.apply_class_feature(_actor, feature_id)
		
	if not _actor.get(&"progression_history"):
		_actor.set(&"progression_history", {})
		
	_actor.progression_history[_actor.level] = history_entry
	
	PFLevelUpManager.recalculate_spell_slots(_actor)

