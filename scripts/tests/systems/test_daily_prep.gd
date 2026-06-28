extends GutTest

var prep_manager: PFDailyPrepManager
var time_manager: PFTimeManager
var actor: PFPlayerCharacter

func before_each() -> void:
	PFContext.init_shared_services()
	time_manager = PFTimeManager.new()
	add_child_autofree(time_manager)
	
	prep_manager = PFDailyPrepManager.new()
	add_child_autofree(prep_manager)
	
	actor = PFPlayerCharacter.new("Test Actor", [], 2, 20, 0, 0, 0)
	actor.actor_class = PFClass.new("Wizard", 6, [], PFMathConstants.ProficiencyRank.TRAINED, PFMathConstants.ProficiencyRank.TRAINED, {"fort": 1, "ref": 1, "will": 1}, 2, {}, {}, "", [], [], true, PFMagicConstants.CasterType.PREPARED, PFMagicConstants.MagicTradition.ARCANE, PFMathConstants.ProficiencyRank.TRAINED, PFMagicConstants.SpellProgression.FULL_CASTER)
	add_child_autofree(actor)
	# Add spellbook for testing
	actor.spellbook = PFSpellbook.new(actor)
	actor.spellbook.increase_max_focus_points(2)

func after_each() -> void:
	PFContext.cleanup_shared_services()
	if is_instance_valid(actor):
		actor.free()
	# Gut's add_child_autofree will handle time_manager and prep_manager.

func test_rest_for_night() -> void:
	# Setup damage
	actor.health.current_hp = 5
	actor.health.max_hp = 20
	
	# Setup conditions
	actor.apply_condition(PFCondition.create("doomed", 2))
	actor.apply_condition(PFCondition.create("drained", 2))
	actor.apply_condition(PFCondition.create("fatigued", 1))
	
	actor.spellbook.focus_points = 0
	
	# Emit signal from time manager
	time_manager.rest_for_night()
	
	# Healing should be maxi(1, con_mod) * level = maxi(1, 0) * 2 = 2
	assert_eq(actor.health.current_hp, 7, "Actor should heal 2 HP")
	
	# Condition reductions (1 per standard rest)
	assert_eq(actor.get_condition("doomed").value, 1, "Doomed should reduce by 1")
	assert_eq(actor.get_condition("drained").value, 1, "Drained should reduce by 1")
	assert_false(actor.has_condition("fatigued"), "Fatigued should be removed")
	
	# Focus points restored
	assert_eq(actor.spellbook.focus_points, 2, "Focus points should be fully restored")

func test_long_term_rest() -> void:
	# Setup damage
	actor.health.current_hp = 5
	actor.health.max_hp = 20
	
	# Setup conditions
	actor.apply_condition(PFCondition.create("doomed", 2))
	actor.apply_condition(PFCondition.create("drained", 2))
	actor.apply_condition(PFCondition.create("fatigued", 1))
	
	actor.spellbook.focus_points = 0
	
	# Emit signal from time manager
	time_manager.rest_long_term()
	
	# Healing should be double: 2 * 2 = 4
	assert_eq(actor.health.current_hp, 9, "Actor should heal 4 HP")
	
	# Condition reductions (2 per long term rest)
	assert_false(actor.has_condition("doomed"), "Doomed should be fully removed (reduced by 2)")
	assert_false(actor.has_condition("drained"), "Drained should be fully removed (reduced by 2)")
	assert_false(actor.has_condition("fatigued"), "Fatigued should be removed")

func test_sleeping_in_armor() -> void:
	var armor = PFArmor.new("Half Plate", [], 1, 0.0, PFEquipmentConstants.ArmorCategory.HEAVY, PFEquipmentConstants.ArmorGroup.PLATE, 5, 0, -3, 10, 3)
	actor.inventory.add_item(armor)
	actor.inventory.equip_item(armor)
	
	assert_false(actor.has_condition("fatigued"))
	
	time_manager.rest_for_night()
	
	assert_true(actor.has_condition("fatigued"), "Sleeping in heavy armor should apply fatigued")

func test_sleeping_in_comfort_armor() -> void:
	var armor = PFArmor.new("Explorer's Clothing", [&"comfort"], 1, 0.0, PFEquipmentConstants.ArmorCategory.UNARMORED, PFEquipmentConstants.ArmorGroup.CLOTH, 0, 5, 0, 0, 0)
	actor.inventory.add_item(armor)
	actor.inventory.equip_item(armor)
	
	time_manager.rest_for_night()
	
	assert_false(actor.has_condition("fatigued"), "Comfort trait should prevent fatigue")

func test_explicit_spell_prep() -> void:
	var req = PFSpellcastingReceptacle.new("Wizard Spellbook", PFMagicConstants.MagicTradition.ARCANE, PFMagicConstants.CasterType.PREPARED)
	actor.spellbook.add_receptacle(req)
	req.spells_per_rank[1] = 2
	
	var fireball = PFSpell.new(&"fireball")
	actor.spellbook.learn_spell(fireball)
	
	# Attempt to prepare spell
	var success = prep_manager.prepare_spell(actor, fireball, 1, req)
	assert_true(success, "Spell should be explicitly prepared")
	assert_eq(req.prepared_spells[1][0], fireball, "Fireball should be in slot 1")

func test_staff_prep() -> void:
	var req = PFSpellcastingReceptacle.new("Wizard Spellbook", PFMagicConstants.MagicTradition.ARCANE, PFMagicConstants.CasterType.PREPARED)
	actor.spellbook.add_receptacle(req)
	req.spells_per_rank[2] = 1
	
	var staff = PFStaff.new("Staff of Fire")
	
	# Prepare staff with 2 charges and expend a rank 2 slot
	prep_manager.prepare_staff(actor, staff, 2, 2)
	
	assert_eq(staff.get_current_charges(), 4, "Staff should have base charges + expended rank charges")

func test_craft_temporary_items() -> void:
	# Start at hour 8
	time_manager.current_time_seconds = 8 * PFTimeManager.SECONDS_PER_HOUR
	
	# Add a permanent item
	var dagger = PFItem.new()
	dagger.entity_name = "Dagger"
	actor.inventory.add_item(dagger)
	
	# Craft temporary item (Alchemist Fire)
	prep_manager.craft_temporary_item(actor, &"alchemist_fire_lesser", 2)
	
	assert_eq(actor.inventory.items.size(), 3, "Inventory should have 1 permanent + 2 temporary items")
	var has_temp = false
	for item in actor.inventory.items:
		if item.is_temporary:
			has_temp = true
	assert_true(has_temp, "Should have temporary items")
	
	# Commit daily prep
	var actors: Array[PFActor] = [actor]
	prep_manager.commit_daily_prep(actors)
	
	# Temporary items should be destroyed
	assert_eq(actor.inventory.items.size(), 1, "Inventory should only have 1 permanent item left")
	assert_eq(actor.inventory.items[0], dagger, "Permanent item should remain")
	assert_eq(time_manager.current_time_seconds, 9 * PFTimeManager.SECONDS_PER_HOUR, "Time should advance 1 hour")

