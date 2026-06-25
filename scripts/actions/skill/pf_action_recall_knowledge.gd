# pf_action_recall_knowledge.gd
## Allows a character to roll a secret skill check to learn information about a target.
class_name PFActionRecallKnowledge
extends PFAction

const KNOWLEDGE_STATE_UNKNOWN = 0
const KNOWLEDGE_STATE_KNOWN = 1
const KNOWLEDGE_STATE_FALSE = 2

const BESTIARY_FIELDS = [
	"state_name", "state_description", "state_traits", "state_level",
	"state_hp", "state_ac", "state_saves", "state_attributes",
	"state_speeds", "state_senses", "state_immunities", "state_weaknesses",
	"state_resistances", "state_strikes", "state_spells", "state_special_abilities"
]

func _init():
	super._init("Recall Knowledge", [&"secret", &"concentrate"], PFCombatConstants.ActionCost.ONE_ACTION)

func execute(user: PFActor, target: PFActor = null) -> bool:
	if not super.execute(user, target): return false
	
	if not target or not target is PFNpc:
		print("    > [Recall Knowledge] Invalid target. Must be an NPC.")
		return false
		
	var monster_id = target.base_id
	if monster_id == &"":
		print("    > [Recall Knowledge] Target has no base_id, cannot track in Bestiary.")
		return false
		
	var skill_used = _determine_skill_for_target(target)
	if skill_used == &"":
		print("    > [Recall Knowledge] Could not determine a relevant skill for %s." % target.entity_name)
		return false
		
	var modifier = user.get_skill_bonus(skill_used)
	var roll = PFDice.roll(1, 20).total + modifier
	
	var dc = PFGameMath.get_dc_by_level(target.level)
	var _rarity = target.get(&"rarity") if target.get(&"rarity") else &"common"
	match rarity:
		&"uncommon": dc += 2
		&"rare": dc += 5
		&"unique": dc += 10
		
	print("    > [Secret] %s rolls %s to Recall Knowledge on %s." % [user.entity_name, str(skill_used).capitalize(), target.entity_name])
	
	var degree = PFGameMath.get_degree_of_success(roll, dc)
	var db = PFDatabase.get_instance()
	if not db:
		print("    > [Recall Knowledge] Database unavailable!")
		return false
		
	var current_knowledge = db.get_player_knowledge(monster_id)
	
	match degree:
		PFCombatConstants.DegreeOfSuccess.CRITICAL_SUCCESS:
			print("    > [Recall Knowledge: CRIT SUCCESS] You recall significant details about %s!" % target.entity_name)
			_grant_success_knowledge(db, monster_id, current_knowledge, 3)
		PFCombatConstants.DegreeOfSuccess.SUCCESS:
			print("    > [Recall Knowledge: SUCCESS] You recall a useful piece of information about %s." % target.entity_name)
			_grant_success_knowledge(db, monster_id, current_knowledge, 1)
		PFCombatConstants.DegreeOfSuccess.FAILURE:
			print("    > [Recall Knowledge: FAILURE] You can't remember anything useful right now.")
		PFCombatConstants.DegreeOfSuccess.CRITICAL_FAILURE:
			print("    > [Recall Knowledge: CRIT FAILURE] You recall false information!")
			_grant_false_knowledge(db, monster_id, target, current_knowledge)
			
	return true

func _grant_success_knowledge(db: PFDatabase, monster_id: String, current_knowledge: Dictionary, unlock_count: int) -> void:
	var updates = {}
	
	# Clear false data if it exists
	if current_knowledge.get(&"false_data", "{}") != "{}":
		updates["false_data"] = "{}"
		
	# On any success, they always learn the basics if they didn't know them
	var basics = ["state_name", "state_description", "state_traits"]
	for b in basics:
		if current_knowledge.get(b, 0) != KNOWLEDGE_STATE_KNOWN:
			updates[b] = KNOWLEDGE_STATE_KNOWN
			
	# Find unknown fields (excluding basics)
	var unknown_fields = []
	for field in BESTIARY_FIELDS:
		if field in basics: continue
		var state = current_knowledge.get(field, 0)
		if state == KNOWLEDGE_STATE_UNKNOWN or state == KNOWLEDGE_STATE_FALSE:
			unknown_fields.append(field)
			
	# Pick random unknowns
	unknown_fields.shuffle()
	var to_unlock = mini(unlock_count, unknown_fields.size())
	for i in range(to_unlock):
		updates[unknown_fields[i]] = KNOWLEDGE_STATE_KNOWN
		
	if updates.size() > 0:
		db.update_player_knowledge(monster_id, updates)
		print("    > [Bestiary] Unlocked %d new fields for %s." % [updates.size() - (1 if updates.has(&"false_data") else 0), monster_id])
	else:
		print("    > [Bestiary] You already know everything about %s!" % monster_id)

func _grant_false_knowledge(db: PFDatabase, monster_id: String, target: PFNpc, current_knowledge: Dictionary) -> void:
	var unknown_fields = []
	for field in BESTIARY_FIELDS:
		# Don't give fake names/descriptions/traits usually, stick to mechanical fields
		if field in ["state_name", "state_description", "state_traits"]: continue
		if current_knowledge.get(field, 0) == KNOWLEDGE_STATE_UNKNOWN:
			unknown_fields.append(field)
			
	if unknown_fields.is_empty():
		return # Cannot generate a lie if they know everything
		
	unknown_fields.shuffle()
	var target_field = unknown_fields[0]
	
	var false_data_str = current_knowledge.get(&"false_data", "{}")
	var false_data = JSON.parse_string(false_data_str) if false_data_str else {}
	
	_generate_false_data_for_field(target, target_field, false_data)
	
	var updates = {
		target_field: KNOWLEDGE_STATE_FALSE,
		"false_data": JSON.stringify(false_data)
	}
	db.update_player_knowledge(monster_id, updates)
	print("    > [Bestiary] Generated false knowledge for %s on field %s." % [monster_id, target_field])

func _generate_false_data_for_field(target: PFNpc, field: String, false_data: Dictionary) -> void:
	match field:
		"state_weaknesses":
			var fake_type = _get_random_unmatched_damage_type(target.get_weaknesses())
			false_data["weaknesses"] = [{"type": fake_type, "value": maxi(2, target.level + 2)}]
		"state_resistances":
			var fake_type = _get_random_unmatched_damage_type(target.get_resistances())
			false_data["resistances"] = [{"type": fake_type, "value": maxi(2, target.level + 2)}]
		"state_immunities":
			var fake_type = _get_random_unmatched_damage_type(target.get_immunities())
			false_data["immunities"] = [{"type": fake_type}]
		"state_saves":
			# Scramble the actual saves
			false_data["saves"] = {
				"fortitude": target.get_save_bonus(&"will") + randi_range(-2, 2),
				"reflex": target.get_save_bonus(&"fortitude") + randi_range(-2, 2),
				"will": target.get_save_bonus(&"reflex") + randi_range(-2, 2)
			}
		"state_hp":
			false_data["hp"] = int(target.health.max_hp * randf_range(1.2, 1.5))
		"state_ac":
			false_data["ac"] = target.get_ac() + randi_range(-4, 4)
		_:
			false_data[field.replace("state_", "")] = "A false assumption."

func _get_random_unmatched_damage_type(actual_list: Array) -> String:
	var keys = PFCombatConstants.DamageType.keys()
	keys.shuffle()
	
	var actual_types = []
	for item in actual_list:
		if typeof(item) == TYPE_DICTIONARY and item.has(&"type"):
			actual_types.append(str(item.type).to_upper())
			
	for k in keys:
		if not actual_types.has(k):
			return str(k).to_lower()
	return "fire" # Fallback

func _determine_skill_for_target(target: PFActor) -> StringName:
	var _traits = target.traits if "traits" in target else []
	var string_traits = []
	for t in traits:
		string_traits.append(str(t).to_lower())
		
	if string_traits.has(&"animal") or string_traits.has(&"fungus") or string_traits.has(&"plant") or string_traits.has(&"fey") or string_traits.has(&"beast"):
		return &"nature"
	if string_traits.has(&"dragon") or string_traits.has(&"elemental") or string_traits.has(&"monitor"):
		return &"arcana"
	if string_traits.has(&"undead") or string_traits.has(&"fiend") or string_traits.has(&"celestial"):
		return &"religion"
	if string_traits.has(&"aberration") or string_traits.has(&"spirit") or string_traits.has(&"ooze"):
		return &"occultism"
	if string_traits.has(&"humanoid"):
		return &"society"
	if string_traits.has(&"construct"):
		return &"crafting"
		
	# Fallback
	return &"society"
