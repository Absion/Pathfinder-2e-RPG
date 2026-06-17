extends SceneTree

class_name TestBestiary

func get_test_name() -> String:
	return "Bestiary & Recall Knowledge Tracking Tests"

func _init() -> void:
	run_test()
	quit()

func run_test() -> void:
	print("\n--- Running Bestiary Tests ---")
	
	PFContext.init_shared_services()
	var db = PFDatabase.get_instance()
	
	# Clear db for this specific test
	db.query("DELETE FROM player_knowledge;")
	
	var wizard = PFPlayerCharacter.new("Wizard", [&"humanoid"], 5, 0, 0, 0, 0)
	wizard.attributes.int = 18
	wizard.sheet.set_skill_rank(&"arcana", PFMathConstants.ProficiencyRank.EXPERT)
	
	# Dragon, Level 5
	var dragon = PFNpc.new(&"young_red_dragon", "Young Red Dragon", [&"dragon", &"fire"], 5, 
		75, 12, 10, 11, 
		4, 2, 3, 1, 2, 2)
	dragon.monster_stats["weaknesses"] = [{"type": "cold", "value": 5}]
	dragon.monster_stats["immunities"] = [{"type": "fire"}]
	dragon.health.weaknesses = {PFCombatConstants.DamageType.COLD: 5}
	
	var action = PFActionRecallKnowledge.new()
	
	# TEST 1: Initial Crit Failure (Generates fake weakness)
	print("\nTest 1: Recall Knowledge Crit Failure")
	# Force a low roll by overriding math or just manually injecting the failure state to test generation reliably
	var rk_action = PFActionRecallKnowledge.new()
	var current_knowledge = db.get_player_knowledge(dragon.base_id)
	rk_action._grant_false_knowledge(db, dragon.base_id, dragon, current_knowledge)
	
	current_knowledge = db.get_player_knowledge(dragon.base_id)
	assert_true(current_knowledge.get("false_data", "{}") != "{}", "Should have generated false data on crit fail.")
	
	var false_data = JSON.parse_string(current_knowledge["false_data"])
	# We expect one of the fields to have been marked as '2' (FALSE)
	var found_false_state = false
	var false_field = ""
	for k in current_knowledge.keys():
		if str(k).begins_with("state_") and current_knowledge[k] == 2:
			found_false_state = true
			false_field = str(k).replace("state_", "")
			break
			
	assert_true(found_false_state, "A state should be marked as 2 (FALSE).")
	assert_true(false_data.has(false_field), "False data JSON should contain the generated fake field.")
	print("Fake field generated: " + false_field)
	
	# TEST 2: Passive Un-Discovery
	print("\nTest 2: Passive Un-Discovery via Combat")
	# Let's forcefully inject a fake Fire weakness for the test
	db.update_player_knowledge(dragon.base_id, {
		"state_weaknesses": 2,
		"false_data": JSON.stringify({"weaknesses": [{"type": "fire", "value": 5}]})
	})
	
	# Wizard hits dragon with Fire
	dragon.health.apply_damage(10, PFCombatConstants.DamageType.FIRE)
	
	var updated_knowledge = db.get_player_knowledge(dragon.base_id)
	var updated_false_data = JSON.parse_string(updated_knowledge["false_data"])
	
	assert_true(updated_knowledge.get("state_weaknesses", 0) == 0, "Weakness state should revert to 0 after realizing it's fake.")
	assert_false(updated_false_data.has("weaknesses"), "Fake weakness should be removed from false_data.")
	
	# TEST 3: Passive Discovery
	print("\nTest 3: Passive Discovery via Combat")
	# Wizard hits dragon with Cold
	dragon.health.apply_damage(10, PFCombatConstants.DamageType.COLD)
	
	updated_knowledge = db.get_player_knowledge(dragon.base_id)
	assert_true(updated_knowledge.get("state_weaknesses", 0) == 1, "Weakness state should be 1 (KNOWN) after triggering actual weakness.")
	
	# TEST 4: Success clears false data
	print("\nTest 4: Success clears remaining false data")
	db.update_player_knowledge(dragon.base_id, {
		"state_saves": 2,
		"false_data": JSON.stringify({"saves": {"fortitude": 10}})
	})
	rk_action._grant_success_knowledge(db, dragon.base_id, updated_knowledge, 1)
	
	var final_knowledge = db.get_player_knowledge(dragon.base_id)
	assert_true(final_knowledge.get("false_data", "{}") == "{}", "Success should clear all false data.")
	assert_true(final_knowledge.get("state_name", 0) == 1, "Success should guarantee basic info is KNOWN.")
	
	print("\nAll Bestiary Tests Executed Successfully!")

func assert_true(a, msg: String = ""):
	if not a:
		push_error("Assertion failed: Expected true - " + msg)
		quit(1)

func assert_false(a, msg: String = ""):
	if a:
		push_error("Assertion failed: Expected false - " + msg)
		quit(1)
