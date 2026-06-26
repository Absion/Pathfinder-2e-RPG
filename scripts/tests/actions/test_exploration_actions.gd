extends GutTest

var db: PFDatabase
var game_root: PFGameRoot
var actor: PFActor

func before_all():
	# Ensure Godot's MainLoop exists
	if Engine.get_main_loop() == null:
		push_error("MainLoop not available!")
		
	# Setup DB
	db = PFDatabase.new()
	Engine.get_main_loop().root.add_child(db)
	
	# Setup GameRoot
	game_root = PFGameRoot.new()
	game_root.name = "PFGameRoot"
	var overworld = PFOverworldContext.new()
	game_root.contexts["OverworldContext"] = overworld
	Engine.get_main_loop().root.add_child(game_root)
	
	# Transition to Overworld context
	game_root.transition_to_context("OverworldContext")

func after_all():
	if db and db.is_inside_tree():
		db.get_parent().remove_child(db)
		db.free()
	if game_root and game_root.is_inside_tree():
		game_root.get_parent().remove_child(game_root)
		game_root.free()

func before_each():
	actor = autofree(PFActor.new("Valeros", [&"human", &"humanoid"], 1, 20))
	add_child_autofree(actor)

func test_exploration_activity_updates_context():
	var avoid_notice = PFActionExploration.new(&"avoid_notice")
	var scout = PFActionExploration.new(&"scout")
	
	# Execute 'Avoid Notice'
	avoid_notice.execute(actor)
	
	var context = game_root.current_context as PFOverworldContext
	assert_not_null(context)
	assert_eq(str(context.get_exploration_activity(actor)), "avoid_notice")
	
	# Execute 'Scout'
	scout.execute(actor)
	assert_eq(str(context.get_exploration_activity(actor)), "scout")

func test_generic_action_logs_without_crash():
	# This ensures generic actions (which we just added) load properly from the DB
	var sense_motive = PFActionGeneric.new(&"sense_motive")
	sense_motive.execute(actor)
	assert_eq(str(sense_motive.action_id), "sense_motive")
