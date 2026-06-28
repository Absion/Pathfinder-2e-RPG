extends "res://addons/gut/test.gd"

func test_coda_bards_only():
	var coda = load("res://scripts/items/magic_tools/pf_coda.gd").new()
	var actor = autofree(PFPlayerCharacter.new("Actor", [], 1, 10, 0, 0, 0))
	actor.actor_class = PFClass.new("Fighter")
	
	coda.prepare_coda(actor, 3)
	assert_eq(coda.get_max_charges(), 0, "Non-bard cannot prepare a coda")
	
	actor.actor_class.id = "bard"
	actor.spellbook = PFSpellbook.new(actor)
	coda.prepare_coda(actor, 3)
	assert_eq(coda.get_max_charges(), 3, "Bard can prepare a coda")
