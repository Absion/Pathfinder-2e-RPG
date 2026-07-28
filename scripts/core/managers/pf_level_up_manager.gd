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
	var database = PFDatabase.get_instance()
	if database and actor.actor_class:
		var class_id = str(actor.actor_class.entity_name).to_lower() 
		var prog_data = database.get_class_progression(class_id, next_level)
		
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
			if spells_json != "" and spells_json != "{}" and spells_json != "null" and spells_json != "<null>" and spells_json != "<Variant(null)>":
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
	var database = PFDatabase.get_instance()
	var feature_data = database.get_class_feature_data(feature_id)
	if feature_data.is_empty(): return
	
	print("    > Applied Class Feature: %s" % feature_data["name"])
	# Future: We can parse feature_data["granted_rules"] and programmatically apply effects

static func recalculate_spell_slots(actor: PFPlayerCharacter) -> void:
	if not actor.spellbook: return
	
	# Recalculate Class Receptacle Slots
	if actor.actor_class and actor.actor_class.is_spellcaster:
		var class_id = actor.actor_class.id
		var class_rep: PFSpellcastingReceptacle = null
		for receptacle in actor.spellbook.receptacles:
			if receptacle.source_id == class_id:
				class_rep = receptacle
				break
		
		if class_rep:
			class_rep.spells_per_rank.clear()
			var prog = PFMagicConstants.FULL_CASTER_PROGRESSION if actor.actor_class.spell_progression == PFMagicConstants.SpellProgression.FULL_CASTER else PFMagicConstants.BOUNDED_CASTER_PROGRESSION
			if prog.has(actor.level):
				for rank in prog[actor.level]:
					class_rep.spells_per_rank[rank] = prog[actor.level][rank]

	# Parse feats for archetype magic progression
	var archetype_levels = {}
	for feat in actor.feats:
		if feat.granted_rules.has("grant_archetype_spellcasting"):
			var rule = feat.granted_rules["grant_archetype_spellcasting"]
			var tradition = rule.get("tradition", PFMagicConstants.MagicTradition.NONE)
			var caster_type = rule.get("caster_type", PFMagicConstants.CasterType.NONE)
			var progression_tier = rule.get("progression", "basic")
			var source_id = rule.get("source_id", "archetype_magic")
			var is_bounded = rule.get("bounded", false)
			
			if not archetype_levels.has(source_id):
				archetype_levels[source_id] = {
					"tradition": tradition,
					"caster_type": caster_type,
					"tier": progression_tier,
					"bounded": is_bounded
				}
			else:
				# Upgrade tier
				if progression_tier == "expert" and archetype_levels[source_id]["tier"] == "basic":
					archetype_levels[source_id]["tier"] = "expert"
				elif progression_tier == "master":
					archetype_levels[source_id]["tier"] = "master"
					
	for source_id in archetype_levels:
		var data = archetype_levels[source_id]
		var receptacle: PFSpellcastingReceptacle = null
		for r in actor.spellbook.receptacles:
			if r.source_id == source_id:
				receptacle = r
				break
		if not receptacle:
			receptacle = PFSpellcastingReceptacle.new(source_id, data["tradition"], data["caster_type"])
			actor.spellbook.add_receptacle(receptacle)
			
		# Apply slots
		receptacle.spells_per_rank.clear()
		
		if data.get("bounded", false):
			var table: Dictionary = {}
			if data["tier"] == "master" and PFMagicConstants.ARCHETYPE_BOUNDED_MASTER_PROGRESSION.has(actor.level):
				table = PFMagicConstants.ARCHETYPE_BOUNDED_MASTER_PROGRESSION[actor.level]
			elif (data["tier"] == "expert" or data["tier"] == "master") and PFMagicConstants.ARCHETYPE_BOUNDED_EXPERT_PROGRESSION.has(actor.level):
				table = PFMagicConstants.ARCHETYPE_BOUNDED_EXPERT_PROGRESSION[actor.level]
			elif PFMagicConstants.ARCHETYPE_BOUNDED_BASIC_PROGRESSION.has(actor.level):
				table = PFMagicConstants.ARCHETYPE_BOUNDED_BASIC_PROGRESSION[actor.level]
				
			for rank in table:
				receptacle.spells_per_rank[rank] = table[rank]
		else:
			# 1. Basic Progression
			if PFMagicConstants.ARCHETYPE_BASIC_PROGRESSION.has(actor.level):
				var basic = PFMagicConstants.ARCHETYPE_BASIC_PROGRESSION[actor.level]
				for rank in basic:
					receptacle.spells_per_rank[rank] = receptacle.spells_per_rank.get(rank, 0) + basic[rank]
			
			# 2. Expert Progression
			if (data["tier"] == "expert" or data["tier"] == "master") and PFMagicConstants.ARCHETYPE_EXPERT_PROGRESSION.has(actor.level):
				var expert = PFMagicConstants.ARCHETYPE_EXPERT_PROGRESSION[actor.level]
				for rank in expert:
					receptacle.spells_per_rank[rank] = receptacle.spells_per_rank.get(rank, 0) + expert[rank]
					
			# 3. Master Progression
			if data["tier"] == "master" and PFMagicConstants.ARCHETYPE_MASTER_PROGRESSION.has(actor.level):
				var master = PFMagicConstants.ARCHETYPE_MASTER_PROGRESSION[actor.level]
				for rank in master:
					receptacle.spells_per_rank[rank] = receptacle.spells_per_rank.get(rank, 0) + master[rank]
					
		# 4. Proficiency
		if data["tradition"] != PFMagicConstants.MagicTradition.NONE:
			var target_rank = PFMathConstants.ProficiencyRank.TRAINED
			if data["tier"] == "expert": target_rank = PFMathConstants.ProficiencyRank.EXPERT
			elif data["tier"] == "master": target_rank = PFMathConstants.ProficiencyRank.MASTER
			actor.sheet.set_spell_rank(data["tradition"], target_rank)

