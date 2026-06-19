# pf_prerequisite_engine.gd
## A static engine for evaluating prerequisite JSON rules against an actor.
class_name PFPrerequisiteEngine
extends RefCounted

## Evaluates a prerequisite JSON string. Returns true if valid, false otherwise.
## `feat_traits`: The traits of the feat currently being evaluated (needed for dedication lock check).
static func evaluate(prereqs_json: String, actor: PFPlayerCharacter, feat_traits: Array[StringName] = [], ignore_dedication_lock: bool = false) -> bool:
	if prereqs_json == "" or prereqs_json == "{}":
		# Note: We must still check dedication locks even if the feat has no explicit prerequisites!
		return _check_dedication_lock(actor, feat_traits, ignore_dedication_lock)
		
	var reqs = JSON.parse_string(prereqs_json)
	if typeof(reqs) != TYPE_DICTIONARY:
		return _check_dedication_lock(actor, feat_traits, ignore_dedication_lock)
		
	# 1. Level Check
	if reqs.has(&"level"):
		if actor.level < reqs["level"]:
			return false
			
	# 2. Ancestry Check
	if reqs.has(&"ancestry"):
		if not actor.ancestry or str(actor.ancestry.id) != reqs["ancestry"]:
			return false
			
	# 3. Heritage Check
	if reqs.has(&"heritage"):
		if not actor.heritage or str(actor.heritage.id) != reqs["heritage"]:
			return false
			
	# 3b. Ethnicity Check
	if reqs.has(&"ethnicity"):
		if str(actor.ethnicity) != reqs["ethnicity"]:
			return false
			
	# 3c. Class Check
	if reqs.has(&"requires_class"):
		if not actor.actor_class or str(actor.actor_class.entity_name).to_lower() != reqs["requires_class"].to_lower():
			return false
			
	# 4. Specific Feat Requirement Check
	if reqs.has(&"requires_feat"):
		var req_feat = StringName(reqs["requires_feat"])
		if req_feat != &"none" and req_feat != &"":
			if not actor.has_feat(req_feat):
				return false
				
	# 5. Minimum Stats Check
	if reqs.has(&"min_stats"):
		var stats = reqs["min_stats"]
		if typeof(stats) == TYPE_DICTIONARY:
			for stat_name in stats.keys():
				var required_val = stats[stat_name]
				var actual_val = 10
				match stat_name:
					"str": actual_val = actor.attributes.str_mod
					"dex": actual_val = actor.attributes.dex_mod
					"con": actual_val = actor.attributes.con_mod
					"int": actual_val = actor.attributes.int_mod
					"wis": actual_val = actor.attributes.wis_mod
					"cha": actual_val = actor.attributes.cha_mod
				if actual_val < required_val:
					return false
					
	# 6. Minimum Proficiency Check
	if reqs.has(&"min_proficiency"):
		var profs = reqs["min_proficiency"]
		if typeof(profs) == TYPE_DICTIONARY:
			for skill_name in profs.keys():
				var req_rank = profs[skill_name]
				var actual_rank = actor.sheet.get_skill_rank(StringName(skill_name))
				if actual_rank < req_rank:
					return false

	# 7. Region Check (placeholder until Region logic is fully attached to actor)
	if reqs.has(&"region"):
		# Assuming we add region to background or biography later
		pass
		
	# 8. Archetype Dedication Lockout Check
	return _check_dedication_lock(actor, feat_traits, ignore_dedication_lock)

static func _check_dedication_lock(actor: PFPlayerCharacter, feat_traits: Array[StringName], ignore_lock: bool) -> bool:
	if ignore_lock: return true
	if not feat_traits.has(&"dedication"): return true
	
	# The feat being evaluated is a Dedication. Check if the actor already has one that isn't satisfied.
	for feat in actor.feats:
		if feat.traits.has(&"dedication"):
			# Find the archetype grouping trait (e.g., "acrobat" from ["dedication", "archetype", "acrobat"])
			var archetype_trait = &""
			for t in feat.traits:
				if t != &"dedication" and t != &"archetype":
					archetype_trait = t
					break
					
			if archetype_trait != &"":
				# Count how many feats the actor has with this archetype trait
				var count = 0
				for check_feat in actor.feats:
					if check_feat.traits.has(archetype_trait):
						count += 1
				
				# If less than 3 feats belong to this archetype, the dedication is locked!
				if count < 3:
					return false
					
	return true
