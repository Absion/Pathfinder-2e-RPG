extends GutTest

var actor1: PFActor
var actor2: PFActor

func before_each():
	PFContext.init_shared_services()
	actor1 = PFPlayerCharacter.new("Alchemist", [&"humanoid"] as Array[StringName], 1, 15, 10, 10, 10)
	actor2 = PFPlayerCharacter.new("Goblin", [&"humanoid", &"goblin"] as Array[StringName], 1, 15, 10, 10, 10)

func after_each():
	PFContext.cleanup_shared_services()
	if is_instance_valid(actor1): actor1.free()
	if is_instance_valid(actor2): actor2.free()

func test_mutagen_overwrites_mutagen():
	var elixir1 = autofree(PFAlchemicalElixir.new("mutagen_juggernaut", "Juggernaut Mutagen", 1, true))
	elixir1.charges = 1
	var elixir2 = autofree(PFAlchemicalElixir.new("mutagen_quicksilver", "Quicksilver Mutagen", 1, true))
	elixir2.charges = 1
	
	var m1_benefit = PFModifier.new(2, PFMathConstants.ModifierType.ITEM, "mutagen_juggernaut")
	m1_benefit.set_meta(&"target_stat", "fortitude")
	elixir1.mutagen_benefit_modifier = m1_benefit
	
	var m2_benefit = PFModifier.new(2, PFMathConstants.ModifierType.ITEM, "mutagen_quicksilver")
	m2_benefit.set_meta(&"target_stat", "reflex")
	elixir2.mutagen_benefit_modifier = m2_benefit
	
	actor1.inventory.add_item(elixir1)
	actor1.inventory.add_item(elixir2)
	
	# Drink the first mutagen
	assert_true(elixir1.on_consume(actor1), "First mutagen should be consumed successfully.")
	
	# Verify fort modifier is applied
	var has_fort_mod = false
	for mod in actor1.attributes.fort_save.modifiers:
		if mod.source == "mutagen_juggernaut":
			has_fort_mod = true
			break
	assert_true(has_fort_mod, "Juggernaut mutagen should grant a fortitude modifier.")
	
	# Drink the second mutagen — it should replace the first
	assert_true(elixir2.on_consume(actor1), "Second mutagen should be consumed successfully.")
	
	# Verify fort modifier from first mutagen is removed
	var still_has_fort = false
	for mod in actor1.attributes.fort_save.modifiers:
		if mod.source == "mutagen_juggernaut":
			still_has_fort = true
			break
	assert_false(still_has_fort, "Juggernaut mutagen modifier should be removed when a new mutagen is consumed.")
	
	# Verify reflex modifier from second mutagen is applied
	var has_ref_mod = false
	for mod in actor1.attributes.ref_save.modifiers:
		if mod.source == "mutagen_quicksilver":
			has_ref_mod = true
			break
	assert_true(has_ref_mod, "Quicksilver mutagen should grant a reflex modifier.")
