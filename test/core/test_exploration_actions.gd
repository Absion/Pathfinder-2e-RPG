extends GdUnitTestSuite

var db: PFDatabase
var game_root: PFGameRoot
var actor: PFActor

func before():
	# Ensure Godot's MainLoop exists
	if Engine.get_main_loop() == null:
		push_error("MainLoop not available!")
		return
		
	# Setup DB
	db = auto_free(PFDatabase.new())
	Engine.get_main_loop().root.add_child(db)
	
	# Setup GameRoot
	game_root = auto_free(PFGameRoot.new())
	game_root.name = "PFGameRoot"
	var overworld = auto_free(PFOverworldContext.new())
	game_root.contexts["OverworldContext"] = overworld
	Engine.get_main_loop().root.add_child(game_root)
	
	# Transition to Overworld context
	game_root.transition_to_context("OverworldContext")

func after():
	if db and db.is_inside_tree():
		db.get_parent().remove_child(db)
	if game_root and game_root.is_inside_tree():
		game_root.get_parent().remove_child(game_root)

func before_test():
	actor = auto_free(PFActor.new("Valeros", [&"human", &"humanoid"], 1, 20))
	Engine.get_main_loop().root.add_child(actor)

func test_exploration_activity_updates_context():
	var avoid_notice = auto_free(PFActionExploration.new(&"avoid_notice"))
	var scout = auto_free(PFActionExploration.new(&"scout"))
	
	# Execute 'Avoid Notice'
	await avoid_notice.execute(actor)
	
	var context = game_root.current_context as PFOverworldContext
	assert_object(context).is_not_null()
	assert_str(str(context.get_exploration_activity(actor))).is_equal("avoid_notice")
	
	# Execute 'Scout'
	await scout.execute(actor)
	assert_str(str(context.get_exploration_activity(actor))).is_equal("scout")

func test_generic_action_logs_without_crash():
	# This ensures generic actions (which we just added) load properly from the DB
	var sense_motive = auto_free(PFActionGeneric.new(&"sense_motive"))
	await sense_motive.execute(actor)
	assert_str(str(sense_motive.action_id)).is_equal("sense_motive")
