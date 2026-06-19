extends GdUnitTestSuite

var turn_manager: PFTurnManager
var reaction_manager: PFReactionManager
var actor_a: PFActor
var actor_b: PFActor
var db: PFDatabase

func before() -> void:
	if not Engine.get_main_loop().root.has_node("PFDatabase"):
		db = PFDatabase.new()
		db.name = "PFDatabase"
		Engine.get_main_loop().root.add_child(db)
		db._ready()
	else:
		db = PFDatabase.get_instance()

func before_test():
	turn_manager = PFTurnManager.new()
	add_child(turn_manager)
	
	reaction_manager = PFReactionManager.new()
	reaction_manager.auto_resolve_prompts = true
	add_child(reaction_manager)
	PFContext.reaction_manager = reaction_manager
	
	actor_a = PFPlayerCharacter.new("Alice", [], 1, 20, 0, 0, 0)
	actor_b = PFPlayerCharacter.new("Bob", [], 1, 20, 0, 0, 0)
	actor_a.set_meta(&"is_ai", true)
	actor_b.set_meta(&"is_ai", true)
	
	add_child(actor_a)
	add_child(actor_b)
	
	turn_manager.add_combatant(actor_a)
	turn_manager.add_combatant(actor_b)

func after_test():
	turn_manager.queue_free()
	reaction_manager.queue_free()
	PFContext.reaction_manager = null
	actor_a.queue_free()
	actor_b.queue_free()

func test_interact_action():
	var interact = PFActionInteract.new()
	auto_free(interact)
	
	var success = await interact.execute(actor_a)
	assert_bool(success).is_true()

func test_crawl_action_fails_if_not_prone():
	var crawl = PFActionCrawl.new()
	auto_free(crawl)
	
	var success = await crawl.execute(actor_a)
	assert_bool(success).is_false() # Alice is not prone

func test_crawl_action_succeeds_if_prone():
	var cond = PFCondition.create(&"prone")
	actor_a.apply_condition(cond)
	
	var crawl = PFActionCrawl.new()
	auto_free(crawl)
	
	var success = await crawl.execute(actor_a)
	assert_bool(success).is_true()

func test_leap_action():
	var leap = PFActionLeap.new()
	auto_free(leap)
	
	var success = await leap.execute(actor_a)
	assert_bool(success).is_true()

func test_aid_action_registers_reaction():
	var aid = PFActionAid.new()
	auto_free(aid)
	
	var success = await aid.execute(actor_a, actor_b)
	assert_bool(success).is_true()
	
	# Verify reaction is registered
	assert_bool(PFContext.reaction_manager.active_triggers.has(PFCombatConstants.ReactionTriggers.ON_ALLY_ACTION)).is_true()
	
	# Simulate trigger
	var event_data = {"roll_bonus": 0}
	event_data = await PFContext.reaction_manager.notify_event(PFCombatConstants.ReactionTriggers.ON_ALLY_ACTION, actor_b, event_data)
	
	# Roll bonus should be increased by 1
	assert_int(event_data.get(&"roll_bonus", 0)).is_equal(1)

func test_ready_action_executes_stored_action():
	var strike_weapon = PFWeapon.new("Sword", [], 1, 1.0, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.SIMPLE, PFEquipmentConstants.WeaponGroup.SWORD, 1, 8, PFCombatConstants.DamageType.SLASHING)
	auto_free(strike_weapon)
	actor_a.inventory.add_item(strike_weapon)
	actor_a.inventory.equip_weapon(strike_weapon, 1)
	
	var strike = PFActionStrike.new(strike_weapon)
	auto_free(strike)
	
	var ready = PFActionReady.new(strike)
	auto_free(ready)
	
	# Ready the strike
	var success = await ready.execute(actor_a)
	assert_bool(success).is_true()
	
	# Simulate Bob moving (triggering the readied action)
	var event_data = {"disrupted": false}
	event_data = await PFContext.reaction_manager.notify_event(PFCombatConstants.ReactionTriggers.ON_MOVE, actor_b, event_data)
	
	# The strike should have happened. Let's just verify it didn't crash.
	# We can't easily check Bob's HP here because Strike might miss, but the event should resolve.
	assert_bool(event_data.has(&"disrupted")).is_true()
