extends GutTest

var reaction_manager: PFReactionManager
var alice: PFActor
var bob: PFActor
var shield: PFShield

func before_each():
	PFContext.init_shared_services()
	reaction_manager = autofree(PFReactionManager.new())
	add_child_autofree(reaction_manager)
	
	alice = autofree(PFActor.new("Alice", [], 1, 20))
	bob = autofree(PFActor.new("Bob", [], 1, 20))
	
	add_child_autofree(alice)
	add_child_autofree(bob)
	
	shield = PFShield.new("Test Shield", 1, 0.0, 2, 5, 20, 10) # AC 2, Hardness 5, HP 20, BT 10
	var raised = PFConditionRaisedShield.new(shield)
	alice.conditions.append(raised)
	
	# Manually simulate what PFContext does
	# Actually raised shield needs reaction_manager on context
	PFContext.reaction_manager = reaction_manager
	raised.on_apply(alice)

func after_each():
	PFContext.cleanup_shared_services()
	PFContext.reaction_manager = null

func test_shield_block_damage_reduction():
	# Alice has shield raised (Hardness 5). Bob hits Alice for 15 piercing damage.
	var event_data = {"damage": 15, "type": PFCombatConstants.DamageType.PIERCING}
	
	# Because Alice is technically NOT an AI by default, it will emit a signal and yield!
	# We want to test the synchronous AI bypass for testing logic.
	alice.set_meta(&"is_ai", true)
	
	# We must await the notify_event
	var new_data = await reaction_manager.notify_event(PFCombatConstants.ReactionTriggers.BEFORE_TAKE_DAMAGE, bob, event_data)
	
	# Damage should be 15 - 5 = 10
	assert_eq(new_data["damage"], 10)
	
	# Shield should have taken 10 damage
	assert_eq(shield.current_hp, 10)
	
	# Alice's reaction should be consumed
	assert_eq(alice.action_economy.reactions_remaining, 0)
