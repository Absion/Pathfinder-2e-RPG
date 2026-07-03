# pf_database.gd
## A stateless singleton that parses sqlite data into GDScript Objects.
class_name PFDatabase
extends Node # Force Reparse

const DB_PATH = "res://db/pf2e_data.db"
var database

# In-memory caches to prevent constant disk I/O
var _sizes_cache: Dictionary = {}
var _traits_cache: Dictionary = {}
var _conditions_cache: Dictionary = {}
var _afflictions_cache: Dictionary = {}
var _actions_cache: Dictionary = {}
var _beliefs_cache: Dictionary = {}
var _skills_cache: Dictionary = {}
var _languages_cache: Dictionary = {}
var _regions_cache: Dictionary = {}
var _heritages_cache: Dictionary = {}
var _animal_companions_cache: Dictionary = {}
var _specific_familiars_cache: Dictionary = {}
var _classes_cache: Dictionary = {}
var _spells_cache: Dictionary = {}
var _feats_cache: Dictionary = {}
var _class_features_cache: Dictionary = {}
var _player_knowledge_cache: Dictionary = {}
var _hazards_cache: Dictionary = {}
var _ethnicities_cache: Dictionary = {}
var _class_progressions_cache: Dictionary = {}
var _weapons_cache: Dictionary = {}
var _attachments_cache: Dictionary = {}
var _adjustments_cache: Dictionary = {}
var _armors_cache: Dictionary = {}
var _shields_cache: Dictionary = {}
var _ancestries_cache: Dictionary = {}
var _backgrounds_cache: Dictionary = {}

var _spell_variants_cache: Dictionary = {}
var _domains_cache: Dictionary = {}
var _edicts_cache: Dictionary = {}
var _anathemas_cache: Dictionary = {}
var _deities_cache: Dictionary = {}

static var _instance: PFDatabase

static func get_instance() -> PFDatabase:
	# Performance: Cache the instance to avoid expensive string-based scene tree traversals
	# (has_node/get_node) during frequent database access.
	if is_instance_valid(_instance):
		return _instance

	var ml = Engine.get_main_loop()
	if ml:
		if ml.root.has_node("PFDB"):
			_instance = ml.root.get_node("PFDB") as PFDatabase
			return _instance
		elif ml.root.has_node("PFDatabase"):
			_instance = ml.root.get_node("PFDatabase") as PFDatabase
			return _instance
	return null

func _ready():
	_instance = self

	# If godot-sqlite is missing, this will fail safely.
	if not ClassDB.class_exists("SQLite"):
		push_error("Godot SQLite plugin not found or not enabled!")
		return
		
	database = ClassDB.instantiate("SQLite")
	
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("database"):
		dir.make_dir("database")
		
	database.path = DB_PATH
	database.open_db()
	_initialize_schema_if_needed()

var query_result: Array = []

func select_with_bindings(query_str: String, bindings: Array) -> Array:
	if database and database.query_with_bindings(query_str, bindings):
		return database.query_result
	return []

func query(query_str: String) -> bool:
	if database and database.query(query_str):
		query_result = database.query_result
		return true
	query_result = []
	return false

func query_with_bindings(query_str: String, bindings: Array) -> bool:
	if database and database.query_with_bindings(query_str, bindings):
		query_result = database.query_result
		return true
	query_result = []
	return false

func _initialize_schema_if_needed():
	# Tables will only be created if they do not exist, and default data will only be inserted if missing.
	
	# Core Data-Driven Mechanics Tables
	database.query("CREATE TABLE IF NOT EXISTS sizes (
		id TEXT PRIMARY KEY,
		name TEXT,
		effective_size INTEGER,
		base_bulk INTEGER
	);")
	
	database.query("CREATE TABLE IF NOT EXISTS player_knowledge (
		monster_id TEXT PRIMARY KEY,
		state_name INTEGER DEFAULT 0,
		state_description INTEGER DEFAULT 0,
		state_traits INTEGER DEFAULT 0,
		state_level INTEGER DEFAULT 0,
		state_hp INTEGER DEFAULT 0,
		state_ac INTEGER DEFAULT 0,
		state_saves INTEGER DEFAULT 0,
		state_attributes INTEGER DEFAULT 0,
		state_speeds INTEGER DEFAULT 0,
		state_senses INTEGER DEFAULT 0,
		state_immunities INTEGER DEFAULT 0,
		state_weaknesses INTEGER DEFAULT 0,
		state_resistances INTEGER DEFAULT 0,
		state_strikes INTEGER DEFAULT 0,
		state_spells INTEGER DEFAULT 0,
		state_special_abilities INTEGER DEFAULT 0,
		false_data TEXT DEFAULT '{}'
	);")
	
	database.query("CREATE TABLE IF NOT EXISTS traits (
		id TEXT PRIMARY KEY,
		name TEXT,
		mechanic_hook TEXT,
		hook_value INTEGER
	);")
	
	
	database.query("CREATE TABLE IF NOT EXISTS actions (
		id TEXT PRIMARY KEY,
		name TEXT,
		cost TEXT,
		traits TEXT,
		requirements TEXT,
		trigger TEXT,
		description TEXT,
		script_path TEXT
	);")

	database.query("CREATE TABLE IF NOT EXISTS hazards (
		id TEXT PRIMARY KEY,
		name TEXT,
		level INTEGER,
		complexity TEXT,
		traits TEXT,
		stealth_dc INTEGER,
		stealth_min_proficiency INTEGER,
		disable_methods TEXT,
		hardness INTEGER,
		hp INTEGER,
		immunities TEXT,
		weaknesses TEXT,
		resistances TEXT,
		abilities TEXT,
		description TEXT
	);")

	database.query("CREATE TABLE IF NOT EXISTS conditions (
		id TEXT PRIMARY KEY,
		name TEXT,
		modifier_type TEXT,
		target_stat TEXT,
		multiplier INTEGER,
		script_path TEXT
	);")
	
	database.query("CREATE TABLE IF NOT EXISTS beliefs (
		id TEXT PRIMARY KEY,
		name TEXT,
		type TEXT,
		mechanic_hook TEXT
	);")
	
	database.query("CREATE TABLE IF NOT EXISTS skills (
		id TEXT PRIMARY KEY,
		name TEXT,
		key_ability TEXT,
		is_lore INTEGER
	);")
	
	database.query("CREATE TABLE IF NOT EXISTS languages (
		id TEXT PRIMARY KEY,
		name TEXT,
		rarity INTEGER
	);")
	
	database.query("CREATE TABLE IF NOT EXISTS regions (
		id TEXT PRIMARY KEY,
		name TEXT
	);")
	
	database.query("CREATE TABLE IF NOT EXISTS heritages (
		id TEXT PRIMARY KEY,
		name TEXT,
		traits TEXT,
		rarity INTEGER,
		ancestry_id TEXT,
		is_versatile INTEGER,
		hp_bonus INTEGER,
		size_id TEXT,
		speed_bonus INTEGER,
		vision_override INTEGER,
		granted_traits TEXT,
		granted_items TEXT,
		granted_abilities TEXT,
		description TEXT
	);")
	
	database.query("CREATE TABLE IF NOT EXISTS ethnicities (
		id TEXT PRIMARY KEY,
		name TEXT,
		required_traits TEXT,
		description TEXT
	);")
	
	database.query("CREATE TABLE IF NOT EXISTS animal_companions (
		id TEXT PRIMARY KEY,
		name TEXT,
		size_id TEXT,
		ancestry_hp INTEGER,
		speed_land INTEGER,
		str_mod INTEGER,
		dex_mod INTEGER,
		con_mod INTEGER,
		int_mod INTEGER,
		wis_mod INTEGER,
		cha_mod INTEGER,
		signature_skill TEXT,
		skills TEXT,
		senses TEXT,
		unarmed_attacks TEXT,
		support_benefit TEXT,
		advanced_maneuver TEXT
	);")
	
	# Specific Familiars
	database.query("CREATE TABLE IF NOT EXISTS specific_familiars (
		id TEXT PRIMARY KEY,
		name TEXT,
		required_abilities INTEGER,
		granted_abilities TEXT,
		unique_abilities TEXT,
		traits TEXT,
		description TEXT
	);")
	
	
	# Feats
	database.query("CREATE TABLE IF NOT EXISTS feats (
		id TEXT PRIMARY KEY,
		name TEXT,
		feat_type INTEGER,
		level INTEGER,
		traits TEXT,
		prerequisites TEXT,
		granted_rules TEXT,
		description TEXT
	);")
	
	# Class Features
	database.query("CREATE TABLE IF NOT EXISTS class_features (
		id TEXT PRIMARY KEY,
		name TEXT,
		granted_rules TEXT,
		description TEXT
	);")
	
	# Class Progressions
	database.query("CREATE TABLE IF NOT EXISTS class_progressions (
		class_id TEXT,
		level INTEGER,
		granted_features TEXT,
		granted_feat_slots TEXT,
		granted_spells TEXT,
		PRIMARY KEY (class_id, level)
	);")
	
	# Weapons
	database.query("CREATE TABLE IF NOT EXISTS weapons (
		id TEXT PRIMARY KEY,
		name TEXT,
		traits TEXT,
		level INTEGER,
		price_cp INTEGER,
		material INTEGER,
		hardness INTEGER,
		max_hp INTEGER,
		broken_threshold INTEGER,
		grade INTEGER,
		bulk INTEGER,
		weapon_type INTEGER,
		category INTEGER,
		group_type INTEGER,
		damage_dice INTEGER,
		damage_faces INTEGER,
		damage_type INTEGER,
		range_increment INTEGER DEFAULT 0,
		volley_range INTEGER DEFAULT 0,
		reload_value INTEGER DEFAULT 0,
		hands_required INTEGER DEFAULT 1,
		ammunition_type INTEGER DEFAULT 0,
		linked_weapon_id TEXT DEFAULT '',
		is_specific_magic INTEGER DEFAULT 0,
		granted_actions TEXT DEFAULT ''
	);")
	
	# Attachments
	database.query("CREATE TABLE IF NOT EXISTS attachments (
		id TEXT PRIMARY KEY,
		name TEXT,
		traits TEXT,
		level INTEGER,
		price_cp INTEGER,
		granted_weapon_id TEXT DEFAULT '',
		granted_traits TEXT DEFAULT '',
		valid_hosts TEXT DEFAULT ''
	);")
	
	# Adjustments
	database.query("CREATE TABLE IF NOT EXISTS adjustments (
		id TEXT PRIMARY KEY,
		name TEXT,
		traits TEXT,
		level INTEGER,
		price_cp INTEGER,
		granted_weapon_id TEXT DEFAULT '',
		granted_traits TEXT DEFAULT '',
		valid_hosts TEXT DEFAULT ''
	);")
	
	# Armors
	database.query("CREATE TABLE IF NOT EXISTS armors (
		id TEXT PRIMARY KEY,
		name TEXT,
		traits TEXT,
		level INTEGER,
		price_cp INTEGER,
		material INTEGER,
		hardness INTEGER,
		max_hp INTEGER,
		broken_threshold INTEGER,
		grade INTEGER,
		bulk INTEGER,
		category INTEGER,
		group_type INTEGER,
		ac_bonus INTEGER,
		dex_cap INTEGER,
		check_penalty INTEGER,
		speed_penalty INTEGER,
		strength_req INTEGER,
		is_specific_magic INTEGER DEFAULT 0,
		granted_actions TEXT DEFAULT ''
	);")
	
	# Shields
	database.query("CREATE TABLE IF NOT EXISTS shields (
		id TEXT PRIMARY KEY,
		name TEXT,
		traits TEXT,
		level INTEGER,
		price_cp INTEGER,
		bulk INTEGER,
		ac_bonus INTEGER,
		speed_penalty INTEGER,
		hardness INTEGER,
		max_hp INTEGER,
		broken_threshold INTEGER,
		is_specific_magic INTEGER DEFAULT 0,
		granted_actions TEXT DEFAULT ''
	);")
	
	# Afflictions
	database.query("CREATE TABLE IF NOT EXISTS afflictions (
		id TEXT PRIMARY KEY,
		name TEXT,
		saving_throw_stat TEXT,
		dc INTEGER,
		max_stage INTEGER,
		onset_interval INTEGER,
		stage_interval INTEGER,
		stages TEXT
	);")
	
	# Ancestries
	database.query("CREATE TABLE IF NOT EXISTS ancestries (
		id TEXT PRIMARY KEY,
		name TEXT,
		traits TEXT,
		hp INTEGER,
		size TEXT,
		speed INTEGER,
		boosts TEXT,
		flaws TEXT
	);")
	
	# Backgrounds
	database.query("CREATE TABLE IF NOT EXISTS backgrounds (
		id TEXT PRIMARY KEY,
		name TEXT,
		traits TEXT,
		boosts TEXT,
		flaws TEXT,
		skills TEXT,
		lores TEXT,
		granted_items TEXT,
		granted_abilities TEXT,
		description TEXT
	);")
	
	# Classes
	database.query("CREATE TABLE IF NOT EXISTS classes (
		id TEXT PRIMARY KEY,
		name TEXT,
		traits TEXT,
		hp_per_level INTEGER,
		key_abilities TEXT,
		perception_rank INTEGER,
		class_dc_rank INTEGER,
		save_fort INTEGER,
		save_ref INTEGER,
		save_will INTEGER,
		trained_skills_count INTEGER,
		weapon_unarmed INTEGER,
		weapon_simple INTEGER,
		weapon_martial INTEGER,
		weapon_advanced INTEGER,
		armor_unarmored INTEGER,
		armor_light INTEGER,
		armor_medium INTEGER,
		armor_heavy INTEGER,
		forced_edicts TEXT,
		forced_anathema TEXT,
		is_spellcaster INTEGER,
		caster_type INTEGER,
		spell_tradition INTEGER,
		spell_proficiency INTEGER,
		spell_progression INTEGER
	);")
	
	# Spells
	database.query("CREATE TABLE IF NOT EXISTS spells (
		id TEXT PRIMARY KEY,
		name TEXT,
		traits TEXT,
		base_spell_rank INTEGER,
		spell_category INTEGER,
		traditions TEXT,
		saving_throw TEXT,
		is_attack INTEGER,
		damage_type TEXT,
		scaling_rules INTEGER,
		scaling_dice INTEGER,
		description TEXT,
		script_path TEXT
	);")
	
	# Spell Variants
	database.query("CREATE TABLE IF NOT EXISTS spell_variants (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		spell_id TEXT,
		action_cost INTEGER,
		spell_range INTEGER,
		target TEXT,
		duration TEXT,
		damage_dice INTEGER,
		damage_faces INTEGER,
		applied_conditions TEXT,
		special_effects TEXT
	);")
	
	# Domains
	database.query("CREATE TABLE IF NOT EXISTS domains (
		id TEXT PRIMARY KEY,
		name TEXT,
		description TEXT,
		domain_spell_id TEXT,
		advanced_domain_spell_id TEXT,
		apocryphal_spell_id TEXT,
		advanced_apocryphal_spell_id TEXT
	);")
	
	# Edicts
	database.query("CREATE TABLE IF NOT EXISTS edicts (
		id TEXT PRIMARY KEY,
		description TEXT
	);")
	
	# Anathemas
	database.query("CREATE TABLE IF NOT EXISTS anathemas (
		id TEXT PRIMARY KEY,
		description TEXT
	);")
	
	# Deities
	database.query("CREATE TABLE IF NOT EXISTS deities (
		id TEXT PRIMARY KEY,
		name TEXT,
		category TEXT,
		edicts TEXT,
		anathema TEXT,
		areas_of_concern TEXT,
		religious_symbol TEXT,
		sacred_animal TEXT,
		sacred_colors TEXT,
		pantheons TEXT,
		divine_attributes TEXT,
		divine_font TEXT,
		divine_sanctification TEXT,
		divine_skill TEXT,
		favored_weapon TEXT,
		domains TEXT,
		alternate_domains TEXT,
		cleric_spells TEXT,
		boon_minor TEXT,
		boon_moderate TEXT,
		boon_major TEXT,
		curse_minor TEXT,
		curse_moderate TEXT,
		curse_major TEXT
	);")
	
	database.query("SELECT COUNT(*) as count FROM deities;")
	# Force seeding for now while dropping tables
	_seed_data()

func _seed_data():
	print("PFDatabase: Seeding default data...")
	# Afflictions
	database.query("""INSERT OR IGNORE INTO afflictions (id, name, saving_throw_stat, dc, max_stage, onset_interval, stage_interval, stages) VALUES 
		('giant_centipede_venom', 'Giant Centipede Venom', 'fortitude', 17, 6, 0, 1, 
		'[
			{"stage": 1, "damage": "1d6", "damage_type": "poison"},
			{"stage": 2, "damage": "1d8", "damage_type": "poison", "conditions": [{"id": "enfeebled", "value": 1}]},
			{"stage": 3, "damage": "1d12", "damage_type": "poison", "conditions": [{"id": "enfeebled", "value": 1}]},
			{"stage": 4, "damage": "2d6", "damage_type": "poison", "conditions": [{"id": "enfeebled", "value": 2}]},
			{"stage": 5, "damage": "2d8", "damage_type": "poison", "conditions": [{"id": "enfeebled", "value": 2}]},
			{"stage": 6, "damage": "3d6", "damage_type": "poison", "conditions": [{"id": "enfeebled", "value": 2}]}
		]')
	;""")
	
	print("PFDatabase: Seeding complete.")
	
	# Seed Sizes
	database.query("INSERT OR IGNORE INTO sizes (id, name, effective_size, base_bulk) VALUES 
		('tiny', 'Tiny', 0, 10),
		('small', 'Small', 1, 30),
		('medium', 'Medium', 1, 60),
		('large', 'Large', 2, 120),
		('huge', 'Huge', 3, 240),
		('gargantuan', 'Gargantuan', 4, 480);")
		
	# Seed Traits
	database.query("INSERT OR IGNORE INTO traits (id, name, mechanic_hook, hook_value) VALUES 
		('agile', 'Agile', 'modifies_map', 4),
		('finesse', 'Finesse', 'allows_dex_to_hit', 0),
		('versatile_p', 'Versatile P', 'adds_damage_type', 0),
		('versatile p', 'Versatile P', 'adds_damage_type', 0),
		('steel', 'Steel', '', 0),
		('two-hand d12', 'Two-Hand d12', '', 0),
		('wood', 'Wood', '', 0),
		('improvised', 'Improvised', '', 0),
		('slashing', 'Slashing', '', 0),
		('bludgeoning', 'Bludgeoning', '', 0),
		('piercing', 'Piercing', '', 0),
		('alchemical', 'Alchemical', '', 0),
		('bomb', 'Bomb', '', 0),
		('consumable', 'Consumable', '', 0),
		('splash', 'Splash', '', 0),
		('fire', 'Fire', '', 0),
		('cold', 'Cold', '', 0),
		('acid', 'Acid', '', 0),
		('electricity', 'Electricity', '', 0),
		('sonic', 'Sonic', '', 0),
		('poison', 'Poison', '', 0),
		('thrown', 'Thrown', '', 0),
		('returning', 'Returning', '', 0),
		('elixir', 'Elixir', '', 0),
		('mutagen', 'Mutagen', '', 0),
		('polymorph', 'Polymorph', '', 0),
		('healing', 'Healing', '', 0),
		('unarmed', 'Unarmed', '', 0),
		('reach', 'Reach', '', 0),
		('nonlethal', 'Nonlethal', '', 0),
		('backstabber', 'Backstabber', '', 0),
		('sweep', 'Sweep', '', 0),
		('backswing', 'Backswing', '', 0),
		('forceful', 'Forceful', '', 0),
		('cobbled', 'Cobbled', '', 0),
		('concussive', 'Concussive', '', 0),
		('injection', 'Injection', '', 0),
		('repeating', 'Repeating', '', 0),
		('kickback', 'Kickback', '', 0),
		('brutal', 'Brutal', '', 0),
		('free-hand', 'Free-Hand', '', 0),
		('manipulate', 'Manipulate', '', 0),
		('move', 'Move', '', 0),
		('attack', 'Attack', '', 0),
		('concentrate', 'Concentrate', '', 0),
		('auditory', 'Auditory', '', 0),
		('visual', 'Visual', '', 0),
		('secret', 'Secret', '', 0);")
		

	# Seed Basic Actions
	database.query("INSERT OR IGNORE INTO actions (id, name, cost, traits, requirements, trigger, description, script_path) VALUES 
		('aid', 'Aid', 'reaction', '[]', '', 'An ally is about to use an action.', 'You try to help your ally with a task.', 'res://scripts/actions/pf_action_generic.gd'),
		('arrest_a_fall', 'Arrest a Fall', 'reaction', '[]', '', 'You fall.', 'You use Acrobatics to slow your fall.', 'res://scripts/actions/pf_action_generic.gd'),
		('avert_gaze', 'Avert Gaze', '1', '[]', '', '', 'You avert your gaze from a danger.', 'res://scripts/actions/pf_action_generic.gd'),
		('avoid_notice', 'Avoid Notice', '1', '[]', '', '', 'You attempt to move stealthily during exploration.', 'res://scripts/actions/pf_action_hide.gd'),
		('burrow', 'Burrow', '1', '[\"move\"]', 'You have a burrow Speed.', '', 'You dig your way through dirt.', 'res://scripts/actions/pf_action_generic.gd'),
		('cast_a_spell', 'Cast a Spell', 'varies', '[]', '', '', 'You cast a spell you have prepared or in your repertoire.', 'res://scripts/actions/pf_action_generic.gd'),
		('crawl', 'Crawl', '1', '[\"move\"]', 'You are prone and your Speed is at least 10 feet.', '', 'You move 5 feet by crawling.', 'res://scripts/actions/pf_action_generic.gd'),
		('defend', 'Defend', '1', '[]', '', '', 'You move at half speed and keep your shield raised.', 'res://scripts/actions/pf_action_exploration.gd'),
		('delay', 'Delay', 'free', '[]', 'Your turn begins and you haven''t acted yet.', '', 'You wait to take your turn.', 'res://scripts/actions/pf_action_delay.gd'),
		('detect_magic', 'Detect Magic', '1', '[\"concentrate\"]', '', '', 'You cast detect magic at regular intervals.', 'res://scripts/actions/pf_action_exploration.gd'),
		('dismiss', 'Dismiss', '1', '[\"concentrate\"]', '', '', 'You end a spell or magic item effect.', 'res://scripts/actions/pf_action_generic.gd'),
		('drop_prone', 'Drop Prone', '1', '[\"move\"]', '', '', 'You fall prone.', 'res://scripts/actions/pf_action_toggle_condition.gd'),
		('escape', 'Escape', '1', '[\"attack\"]', 'You are grabbed, immobilized, or restrained.', '', 'You attempt to escape.', 'res://scripts/actions/pf_action_escape.gd'),
		('fly', 'Fly', '1', '[\"move\"]', 'You have a fly Speed.', '', 'You move through the air.', 'res://scripts/actions/pf_action_fly.gd'),
		('follow_the_expert', 'Follow the Expert', '1', '[\"auditory\", \"concentrate\", \"visual\"]', '', '', 'You gain a bonus to a skill check from an expert ally.', 'res://scripts/actions/pf_action_exploration.gd'),
		('grab_an_edge', 'Grab an Edge', 'reaction', '[\"manipulate\"]', 'You fall or slip.', '', 'You attempt to catch an edge to stop falling.', 'res://scripts/actions/pf_action_generic.gd'),
		('hustle', 'Hustle', '1', '[\"move\"]', '', '', 'You move at double Speed for up to Con x 10 minutes.', 'res://scripts/actions/pf_action_exploration.gd'),
		('interact', 'Interact', '1', '[\"manipulate\"]', '', '', 'You use your hand or hands to manipulate an object or the terrain.', 'res://scripts/actions/pf_action_generic.gd'),
		('investigate', 'Investigate', '1', '[\"concentrate\"]', '', '', 'You use Recall Knowledge to discover clues.', 'res://scripts/actions/pf_action_exploration.gd'),
		('leap', 'Leap', '1', '[\"move\"]', '', '', 'You take a careful, short jump.', 'res://scripts/actions/pf_action_generic.gd'),
		('mount', 'Mount', '1', '[\"move\"]', '', '', 'You get on an allied animal bigger than you.', 'res://scripts/actions/pf_action_generic.gd'),
		('point_out', 'Point Out', '1', '[\"auditory\",\"manipulate\",\"visual\"]', '', '', 'You indicate an unseen creature to your allies.', 'res://scripts/actions/pf_action_point_out.gd'),
		('raise_a_shield', 'Raise a Shield', '1', '[]', '', '', 'You put up a shield to get its bonus to AC.', 'res://scripts/actions/pf_action_raise_shield.gd'),
		('ready', 'Ready', '2', '[\"concentrate\"]', '', '', 'You prepare an action to use as a reaction.', 'res://scripts/actions/pf_action_generic.gd'),
		('release', 'Release', 'free', '[\"manipulate\"]', '', '', 'You release something you are holding.', 'res://scripts/actions/pf_action_generic.gd'),
		('repeat_a_spell', 'Repeat a Spell', '1', '[\"concentrate\"]', '', '', 'You repeatedly cast the same spell.', 'res://scripts/actions/pf_action_exploration.gd'),
		('scout', 'Scout', '1', '[\"concentrate\"]', '', '', 'You scout ahead, granting allies a bonus to initiative.', 'res://scripts/actions/pf_action_exploration.gd'),
		('search', 'Search', '1', '[\"concentrate\"]', '', '', 'You seek for hidden doors and hazards.', 'res://scripts/actions/pf_action_exploration.gd'),
		('seek', 'Seek', '1', '[\"concentrate\",\"secret\"]', '', '', 'You scan an area for unseen creatures or objects.', 'res://scripts/actions/pf_action_seek.gd'),
		('sense_motive', 'Sense Motive', '1', '[\"concentrate\",\"secret\"]', '', '', 'You try to tell whether a creature''s behavior is abnormal.', 'res://scripts/actions/pf_action_sense_motive.gd'),
		('stand', 'Stand', '1', '[\"move\"]', '', '', 'You stand up from prone.', 'res://scripts/actions/pf_action_toggle_condition.gd'),
		('step', 'Step', '1', '[\"move\"]', '', '', 'You carefully move 5 feet.', 'res://scripts/actions/pf_action_step.gd'),
		('stride', 'Stride', '1', '[\"move\"]', '', '', 'You move up to your Speed.', 'res://scripts/actions/pf_action_stride.gd'),
		('strike', 'Strike', '1', '[\"attack\"]', '', '', 'You attack with a weapon or unarmed attack.', 'res://scripts/actions/pf_action_strike.gd'),
		('sustain', 'Sustain', '1', '[\"concentrate\"]', '', '', 'You maintain an effect with a sustained duration.', 'res://scripts/actions/pf_action_generic.gd'),
		('take_cover', 'Take Cover', '1', '[]', '', '', 'You press yourself against a wall or duck behind an obstacle.', 'res://scripts/actions/pf_action_toggle_condition.gd')
	;")

	# Seed Conditions
	database.query("INSERT OR IGNORE INTO conditions (id, name, modifier_type, target_stat, multiplier, script_path) VALUES 
		('clumsy', 'Clumsy', 'status', 'dex_based', -1, ''),
		('enfeebled', 'Enfeebled', 'status', 'str_based', -1, ''),
		('frightened', 'Frightened', 'status', 'all_checks_and_dcs', -1, ''),
		('parry', 'Parry', 'circumstance', 'ac', 1, '');")
		
	# Seed Beliefs
	database.query("INSERT OR IGNORE INTO beliefs (id, name, type, mechanic_hook) VALUES 
		('bring_civilization', 'Bring civilization to the frontiers', 'edict', ''),
		('earn_wealth', 'Earn wealth through hard work and trade', 'edict', ''),
		('follow_law', 'Follow the rule of law', 'edict', ''),
		('create_art', 'Create art', 'edict', ''),
		('defend_nature', 'Defend nature', 'edict', ''),
		('protect_innocent', 'Protect the innocent', 'edict', ''),
		('seek_knowledge', 'Seek knowledge', 'edict', ''),
		('destroy_undead', 'Destroy undead', 'edict', ''),
		
		('banditry_piracy', 'Engage in banditry or piracy', 'anathema', ''),
		('steal', 'Steal', 'anathema', ''),
		('undermine_court', 'Undermine a law-abiding court', 'anathema', ''),
		('create_undead', 'Create undead', 'anathema', ''),
		('despoil_nature', 'Despoil nature', 'anathema', ''),
		('harm_innocent', 'Harm the innocent', 'anathema', ''),
		('destroy_knowledge', 'Destroy knowledge', 'anathema', ''),
		('lie', 'Tell a lie', 'anathema', ''),
		('break_promise', 'Break a promise', 'anathema', '');")
		
	# Seed Skills & Lores
	database.query("INSERT OR IGNORE INTO skills (id, name, key_ability, is_lore) VALUES 
		('acrobatics', 'Acrobatics', 'DEX', 0),
		('arcana', 'Arcana', 'INT', 0),
		('athletics', 'Athletics', 'STR', 0),
		('crafting', 'Crafting', 'INT', 0),
		('deception', 'Deception', 'CHA', 0),
		('diplomacy', 'Diplomacy', 'CHA', 0),
		('intimidation', 'Intimidation', 'CHA', 0),
		('medicine', 'Medicine', 'WIS', 0),
		('nature', 'Nature', 'WIS', 0),
		('occultism', 'Occultism', 'INT', 0),
		('perception', 'Perception', 'WIS', 0),
		('performance', 'Performance', 'CHA', 0),
		('religion', 'Religion', 'WIS', 0),
		('society', 'Society', 'INT', 0),
		('stealth', 'Stealth', 'DEX', 0),
		('survival', 'Survival', 'WIS', 0),
		('thievery', 'Thievery', 'DEX', 0),
		('academia_lore', 'Academia Lore', 'INT', 1),
		('accounting_lore', 'Accounting Lore', 'INT', 1),
		('architecture_lore', 'Architecture Lore', 'INT', 1),
		('art_lore', 'Art Lore', 'INT', 1),
		('circus_lore', 'Circus Lore', 'INT', 1),
		('engineering_lore', 'Engineering Lore', 'INT', 1),
		('farming_lore', 'Farming Lore', 'INT', 1),
		('fishing_lore', 'Fishing Lore', 'INT', 1),
		('fortune_telling_lore', 'Fortune-Telling Lore', 'INT', 1),
		('games_lore', 'Games Lore', 'INT', 1),
		('genealogy_lore', 'Genealogy Lore', 'INT', 1),
		('gladiatorial_lore', 'Gladiatorial Lore', 'INT', 1),
		('guild_lore', 'Guild Lore', 'INT', 1),
		('heraldry_lore', 'Heraldry Lore', 'INT', 1),
		('herbalism_lore', 'Herbalism Lore', 'INT', 1),
		('hunting_lore', 'Hunting Lore', 'INT', 1),
		('labor_lore', 'Labor Lore', 'INT', 1),
		('legal_lore', 'Legal Lore', 'INT', 1),
		('library_lore', 'Library Lore', 'INT', 1),
		('mercantile_lore', 'Mercantile Lore', 'INT', 1),
		('midwifery_lore', 'Midwifery Lore', 'INT', 1),
		('milling_lore', 'Milling Lore', 'INT', 1),
		('mining_lore', 'Mining Lore', 'INT', 1),
		('piloting_lore', 'Piloting Lore', 'INT', 1),
		('sailing_lore', 'Sailing Lore', 'INT', 1),
		('scouting_lore', 'Scouting Lore', 'INT', 1),
		('scribing_lore', 'Scribing Lore', 'INT', 1),
		('stabling_lore', 'Stabling Lore', 'INT', 1),
		('tanning_lore', 'Tanning Lore', 'INT', 1),
		('theater_lore', 'Theater Lore', 'INT', 1),
		('underworld_lore', 'Underworld Lore', 'INT', 1);")
		

	# Seed Conditions
	database.query("INSERT OR IGNORE INTO conditions (id, name, modifier_type, target_stat, multiplier, script_path) VALUES 
		('blinded', 'Blinded', '', '', 0, ''),
		('broken', 'Broken', 'status', 'ac', -2, ''),
		('clumsy', 'Clumsy', 'status', 'dex_based', -1, ''),
		('concealed', 'Concealed', '', '', 0, ''),
		('confused', 'Confused', '', '', 0, ''),
		('controlled', 'Controlled', '', '', 0, ''),
		('cover', 'Cover', 'circumstance', 'ac', 2, ''),
		('dazzled', 'Dazzled', '', '', 0, ''),
		('dead', 'Dead', '', '', 0, ''),
		('deafened', 'Deafened', 'status', 'perception_hearing', -2, ''),
		('doomed', 'Doomed', '', '', 0, 'res://scripts/conditions/pf_condition_doomed.gd'),
		('drained', 'Drained', 'status', 'con_based', -1, ''),
		('dying', 'Dying', '', '', 0, 'res://scripts/conditions/pf_condition_dying.gd'),
		('encumbered', 'Encumbered', 'status', 'speed', -10, 'res://scripts/conditions/pf_condition_encumbered.gd'),
		('enfeebled', 'Enfeebled', 'status', 'str_based', -1, ''),
		('fascinated', 'Fascinated', 'status', 'perception_and_skill', -2, ''),
		('fatigued', 'Fatigued', 'status', 'ac_and_saves', -1, ''),
		('fleeing', 'Fleeing', '', '', 0, ''),
		('frightened', 'Frightened', 'status', 'all_checks_and_dcs', -1, 'res://scripts/conditions/pf_condition_frightened.gd'),
		('grabbed', 'Grabbed', '', '', 0, 'res://scripts/conditions/pf_condition_grabbed.gd'),
		('hidden', 'Hidden', '', '', 0, ''),
		('immobilized', 'Immobilized', '', '', 0, ''),
		('invisible', 'Invisible', '', '', 0, ''),
		('observed', 'Observed', '', '', 0, ''),
		('off_guard', 'Off-Guard', 'circumstance', 'ac', -2, ''),
		('paralyzed', 'Paralyzed', '', '', 0, ''),
		('persistent_damage', 'Persistent Damage', '', '', 0, 'res://scripts/conditions/pf_condition_persistent.gd'),
		('parry', 'Parry', 'circumstance', 'ac', 1, ''),
		('raised_shield', 'Raised Shield', 'circumstance', 'ac', 0, ''),
		('petrified', 'Petrified', '', '', 0, ''),
		('prone', 'Prone', 'circumstance', 'attack', -2, 'res://scripts/conditions/pf_condition_prone.gd'),
		('quickened', 'Quickened', '', '', 0, 'res://scripts/conditions/pf_condition_quickened.gd'),
		('restrained', 'Restrained', '', '', 0, 'res://scripts/conditions/pf_condition_grabbed.gd'),
		('sickened', 'Sickened', 'status', 'all_checks_and_dcs', -1, ''),
		('slowed', 'Slowed', '', '', 0, 'res://scripts/conditions/pf_condition_slowed.gd'),
		('stunned', 'Stunned', '', '', 0, 'res://scripts/conditions/pf_condition_stunned.gd'),
		('stupefied', 'Stupefied', 'status', 'mental_based', -1, ''),
		('unconscious', 'Unconscious', 'status', 'ac_and_saves', -4, 'res://scripts/conditions/pf_condition_unconscious.gd'),
		('undetected', 'Undetected', '', '', 0, ''),
		('unnoticed', 'Unnoticed', '', '', 0, ''),
		('wounded', 'Wounded', '', '', 0, 'res://scripts/conditions/pf_condition_wounded.gd');")
		
	database.query("UPDATE conditions SET script_path = 'res://scripts/conditions/pf_condition_encumbered.gd' WHERE id = 'encumbered';")
		
	# Seed Languages
	# Rarity: 0=Common, 1=Uncommon, 2=Rare
	database.query("INSERT OR IGNORE INTO languages (id, name, rarity) VALUES 
		('common', 'Common', 0),
		('dwarven', 'Dwarven', 0),
		('elven', 'Elven', 0),
		('gnomish', 'Gnomish', 0),
		('goblin', 'Goblin', 0),
		('halfling', 'Halfling', 0),
		('orcish', 'Orcish', 0),
		('sylvan', 'Sylvan', 1),
		('undercommon', 'Undercommon', 1),
		('draconic', 'Draconic', 1),
		('celestial', 'Celestial', 1),
		('abyssal', 'Abyssal', 1),
		('infernal', 'Infernal', 1),
		('druidic', 'Druidic', 2);")
		
	# Seed Domains
	database.query("INSERT OR IGNORE INTO domains (id, name, description, domain_spell_id, advanced_domain_spell_id, apocryphal_spell_id, advanced_apocryphal_spell_id) VALUES 
		('abomination', 'Abomination', 'You seek to instill abhorrence and horror in those around you.', 'lift_natures_caul', 'fearful_feast', '', ''),
		('air', 'Air', 'You can control winds and the weather.', 'pushing_gust', 'disperse_into_air', 'wind_whispers', ''),
		('ambition', 'Ambition', 'You strive to keep up with and outpace the competition.', 'ignite_ambition', 'competitive_edge', 'hollow_heart', ''),
		('change', 'Change', 'You can restructure the physical and metaphysical.', 'adapt_self', 'adaptive_ablation', '', ''),
		('cities', 'Cities', 'You have powers over urban environments and denizens.', 'face_in_the_crowd', 'pulse_of_civilization', '', ''),
		('cold', 'Cold', 'You control ice, snow, and freezing temperatures', 'winter_bolt', 'diamond_dust', '', ''),
		('confidence', 'Confidence', 'You overcome your fear and project pride.', 'veil_of_confidence', 'delusional_pride', 'shaken_confidence', ''),
		('creation', 'Creation', 'You have divine abilities related to crafting and art.', 'creative_splash', 'artistic_flourish', '', ''),
		('darkness', 'Darkness', 'You operate in the darkness and take away the light.', 'cloak_of_shadow', 'darkened_sight', 'isolation', ''),
		('death', 'Death', 'You have the power to end lives and destroy undead.', 'deaths_call', 'eradicate_undeath', 'euphoric_renewal', ''),
		('decay', 'Decay', 'You have the power to spoil and deteriorate matter.', 'withering_grasp', 'fallow_field', '', ''),
		('destruction', 'Destruction', 'You are a conduit for divine devastation.', 'cry_of_destruction', 'destructive_aura', '', ''),
		('disorientation', 'Disorientation', 'You can bewilder and perplex your foes.', 'clouded_focus', 'ephemeral_hazards', '', ''),
		('dragon', 'Dragon', 'You draw on the power of dragons, linnorms, and other powerful reptilian creatures.', 'draconic_barrage', 'roar_of_the_dragon', '', ''),
		('dreams', 'Dreams', 'You have the power to enter and manipulate dreams.', 'sweet_dream', 'dreamers_call', '', ''),
		('dust', 'Dust', 'You have the power to dry and crumble what opposes you.', 'parch', 'dust_storm', '', ''),
		('duty', 'Duty', 'You defend oaths and carry out your divine missions with great dedication.', 'swear_oath', 'dutiful_challenge', '', ''),
		('earth', 'Earth', 'You control soil and stone.', 'hurtling_stone', 'localized_quake', '', ''),
		('family', 'Family', 'You aid and protect your family and community more effectively.', 'soothing_words', 'unity', '', ''),
		('fate', 'Fate', 'You see and understand hidden inevitabilities.', 'read_fate', 'tempt_fate', 'string_of_fate', ''),
		('fire', 'Fire', 'You control flame.', 'fire_ray', 'flame_barrier', 'cinder_gaze', ''),
		('freedom', 'Freedom', 'You liberate yourself and others from shackles and constraints.', 'unimpeded_stride', 'word_of_freedom', '', ''),
		('glyph', 'Glyph', 'You wield power over written words and symbols.', 'redact', 'ghostly_transcription', '', ''),
		('healing', 'Healing', 'Your healing magic is particularly potent.', 'healers_blessing', 'rebuke_death', '', ''),
		('indulgence', 'Indulgence', 'You feast mightily and can shake off the effects of overindulging.', 'overstuff', 'take_its_course', 'frenzied_revelry', ''),
		('introspection', 'Introspection', 'You guide others in examining their lives, emotions, and motivations to ultimately become a truer version of themselvesâ€”a difficult and often painful process.', 'guided_introspection', 'confront_selves', '', ''),
		('knowledge', 'Knowledge', 'You receive divine insights.', 'scholarly_recollection', 'know_the_enemy', 'wordsmith', ''),
		('lightning', 'Lightning', 'You control electricity, thunder, and storms.', 'charged_javelin', 'bottle_the_storm', '', ''),
		('luck', 'Luck', 'Youâ€™re unnaturally lucky and keep out of harmâ€™s way.', 'bit_of_luck', 'lucky_break', '', ''),
		('magic', 'Magic', 'You perform the unexpected and inexplicable.', 'magics_vessel', 'mystic_beacon', '', ''),
		('metal', 'Metal', 'You manipulate flexible mutable metal.', 'serrate', 'repel_metal', '', ''),
		('might', 'Might', 'Your physical power is bolstered by divine strength.', 'athletic_rush', 'enduring_might', 'victory_cry', ''),
		('moon', 'Moon', 'You command powers associated with the moon.', 'moonbeam', 'touch_of_the_moon', '', ''),
		('naga', 'Naga', 'Like many nagas, you believe you understand your place in the Universe, try to help those who donâ€™t, and dissuade those who would serve to fool others into straying from their purpose.', 'chastising_retort', 'show_the_path', '', ''),
		('nature', 'Nature', 'You hold power over animals and plants.', 'vibrant_thorns', 'natures_bounty', '', ''),
		('nightmares', 'Nightmares', 'You fill minds with horror and dread.', 'waking_nightmare', 'shared_nightmare', '', ''),
		('nothingness', 'Nothingness', 'You draw power from emptiness.', 'empty_inside', 'door_to_beyond', '', ''),
		('pain', 'Pain', 'You punish those who displease you with the sharp sting of pain.', 'savor_the_sting', 'retributive_pain', '', ''),
		('passion', 'Passion', 'You evoke passion, whether as love or lust.', 'charming_touch', 'captivating_adoration', '', ''),
		('perfection', 'Perfection', 'You strive to perfect your mind, body, and spirit.', 'perfected_mind', 'perfected_body', '', ''),
		('plague', 'Plague', 'You wield disease and pestilence like a weapon.', 'divine_plagues', 'foul_miasma', '', ''),
		('protection', 'Protection', 'You ward yourself and others.', 'protectors_sacrifice', 'protectors_sphere', '', ''),
		('repose', 'Repose', 'You ease mental burdens.', 'share_burden', 'font_of_serenity', '', ''),
		('secrecy', 'Secrecy', 'You protect secrets and keep them hidden.', 'whispering_quiet', 'safeguard_secret', 'weaponize_secret', ''),
		('sorrow', 'Sorrow', 'You have a powerful and painful connection to melancholy and sadness.', 'lament', 'overflowing_sorrow', '', ''),
		('soul', 'Soul', 'You wield power over the spiritual.', 'eject_soul', 'ectoplasmic_interstice', '', ''),
		('star', 'Star', 'You command the power of the stars.', 'zenith_star', 'asterism', '', ''),
		('sun', 'Sun', 'You harness the power of the sun and other light sources, and punish undead.', 'dazzling_flash', 'vital_luminance', '', ''),
		('swarm', 'Swarm', 'You exert control over masses of creatures.', 'swarmsense', 'swarm_form', '', ''),
		('time', 'Time', 'You reign over the flow of time.', 'delay_consequence', 'stasis', '', ''),
		('toil', 'Toil', 'You work constantly and refuse to let anything stand in your way', 'practice_makes_perfect', 'tireless_worker', '', ''),
		('travel', 'Travel', 'You have power over movement and journeys.', 'agile_feet', 'travelers_transit', 'inevitable_destination', ''),
		('trickery', 'Trickery', 'You deceive others and cause mischief.', 'sudden_shift', 'tricksters_twin', '', ''),
		('truth', 'Truth', 'You pierce lies and discover the truth.', 'word_of_truth', 'glimpse_the_truth', '', ''),
		('tyranny', 'Tyranny', 'You wield power to rule and enslave others.', 'touch_of_obedience', 'commanding_lash', '', ''),
		('undeath', 'Undeath', 'Your magic carries close ties to the undead.', 'touch_of_undeath', 'malignant_sustenance', '', ''),
		('vigil', 'Vigil', 'You watch over those long passed and guard their secrets.', 'object_memory', 'remember_the_lost', '', ''),
		('water', 'Water', 'You control water and bodies of water.', 'tidal_surge', 'downpour', 'purifying_veil', ''),
		('wealth', 'Wealth', 'You hold power over wealth, trade, and treasure.', 'appearance_of_wealth', 'precious_metals', '', ''),
		('wood', 'Wood', 'You command the indomitable power of wood.', 'arms_of_nature', 'wood_walk', '', ''),
		('zeal', 'Zeal', 'Your inner fire increases your combat prowess.', 'weapon_surge', 'zeal_for_battle', '', '');")



	database.query("INSERT OR IGNORE INTO edicts (id, description) VALUES 
		('edict_healing', 'destroy the undead, protect your allies, heal the sick and wounded'),
		('edict_redemption', 'seek and allow redemption');")

	# Seed Anathemas
	database.query("INSERT OR IGNORE INTO anathemas (id, description) VALUES 
		('anathema_undead', 'create undead'),
		('anathema_lies', 'lie'),
		('anathema_mercy', 'deny a repentant creature an opportunity for redemption'),
		('anathema_fail_strike', 'fail to strike down evil');")

	# Seed Deities
	database.query("INSERT OR IGNORE INTO deities (id, name, category, edicts, anathema, areas_of_concern, religious_symbol, sacred_animal, sacred_colors, pantheons, divine_attributes, divine_font, divine_sanctification, divine_skill, favored_weapon, domains, alternate_domains, cleric_spells, boon_minor, boon_moderate, boon_major, curse_minor, curse_moderate, curse_major) VALUES 
		('sarenrae', 'Sarenrae', 'core', '[\"edict_healing\",\"edict_redemption\"]', '[\"anathema_undead\",\"anathema_lies\",\"anathema_mercy\",\"anathema_fail_strike\"]', '[\"healing\",\"honesty\",\"redemption\",\"the sun\"]', 'Ankh', 'Dove', '[\"blue\",\"gold\"]', '[\"The Godclaw\"]', '[\"WIS\",\"CHA\"]', '[\"heal\"]', '1', 'medicine', 'scimitar', '[\"fire\",\"healing\",\"sun\",\"truth\"]', '[]', '{\"1\":\"burning_hands\", \"3\":\"fireball\", \"4\":\"wall_of_fire\"}', '', '', '', '', '', '');")

	# Seed Regions
	database.query("INSERT OR IGNORE INTO regions (id, name) VALUES 
		('unknown', 'Unknown'),
		('linvarre', 'Linvarre'),
		('absalom', 'Absalom'),
		('andoran', 'Andoran'),
		('cheliax', 'Cheliax'),
		('taldor', 'Taldor'),
		('qadira', 'Qadira');")
		
	# Seed Heritages
	# vision_override: -1 (no change), 0 (Normal), 1 (Low-Light), 2 (Darkvision)
	database.query("INSERT OR IGNORE INTO heritages (id, name, traits, rarity, ancestry_id, is_versatile, hp_bonus, size_id, speed_bonus, vision_override, granted_traits, granted_items, granted_abilities, description) VALUES 
		('forge_dwarf', 'Forge Dwarf', '[]', 0, 'dwarf', 0, 0, '', 0, -1, '[\"fire_resistance\"]', '[]', '[]', ''),
		('undine', 'Undine', '[]', 0, '', 1, 0, '', 0, 1, '[\"undine\", \"amphibious\"]', '[]', '[]', 'You are descended from elemental beings of water.'),
		('half_elf', 'Half-Elf', '[]', 0, '', 1, 0, '', 0, 1, '[\"elf\", \"half-elf\"]', '[]', '[]', 'You have both human and elven blood.');")
		
	database.query("INSERT OR IGNORE INTO ethnicities (id, name, required_traits, description) VALUES 
		('nidalese', 'Nidalese', '[\"human\"]', 'Humans from the shadowy nation of Nidal.'),
		('keleshite', 'Keleshite', '[\"human\"]', 'Humans from the vast Padishah Empire of Kelesh.'),
		('mualijae', 'Mualijae', '[\"elf\"]', 'Elves from the Mwangi Expanse.');")
		
	database.query("INSERT OR IGNORE INTO backgrounds (id, name, boosts, flaws, traits, granted_items, granted_abilities, description) VALUES 
		('acolyte', 'Acolyte', '[\"WIS\", \"FREE\"]', '[]', '[]', '[]', '[]', 'You spent your early days in a religious monastery.');")
		
	# Seed Animal Companions
	# Unarmed attacks stored as JSON: [{"name": "Jaws", "damage_dice": 1, "damage_faces": 8, "damage_type": 3, "traits": ["unarmed"]}]
	database.query("INSERT OR IGNORE INTO animal_companions (id, name, size_id, ancestry_hp, speed_land, str_mod, dex_mod, con_mod, int_mod, wis_mod, cha_mod, signature_skill, skills, senses, unarmed_attacks, support_benefit, advanced_maneuver) VALUES 
		('bear', 'Bear', 'small', 8, 25, 3, 2, 2, -4, 1, 0, 'athletics', '[\"intimidation\"]', '[1, 2]', '[{\"name\": \"Jaws\", \"damage_dice\": 1, \"damage_faces\": 8, \"damage_type\": 3, \"traits\": [\"unarmed\"]}, {\"name\": \"Claw\", \"damage_dice\": 1, \"damage_faces\": 6, \"damage_type\": 3, \"traits\": [\"agile\", \"unarmed\"]}]', 'Your bear mauls your enemies when you threaten them.', 'Bear Hug'),
		('wolf', 'Wolf', 'small', 6, 40, 2, 3, 1, -4, 1, 0, 'survival', '[\"stealth\"]', '[1, 2]', '[{\"name\": \"Jaws\", \"damage_dice\": 1, \"damage_faces\": 8, \"damage_type\": 3, \"traits\": [\"unarmed\"]}]', 'Your wolf tears at your enemies legs.', 'Knockdown');")
		
	database.query("INSERT OR IGNORE INTO specific_familiars (id, name, required_abilities, granted_abilities, unique_abilities, traits, description) VALUES 
		('faerie_dragon', 'Faerie Dragon', 3, '[\"amphibious\", \"flier\", \"manual_dexterity\", \"speech\", \"telepathy\", \"touch_telepathy\"]', '[\"breath_weapon\"]', '[\"dragon\"]', 'A tiny, colorful dragon that loves pranks.'),
		('imp', 'Imp', 6, '[\"flier\", \"manual_dexterity\", \"speech\", \"touch_telepathy\"]', '[\"invisibility\", \"infernal_temptation\"]', '[\"devil\", \"fiend\"]', 'A small, deceptive fiend often acting as a familiar to malicious masters.');")
		

		
		
	database.query("INSERT OR IGNORE INTO feats (id, name, feat_type, level, traits, prerequisites, granted_rules, description) VALUES 
		('natural_ambition', 'Natural Ambition', 0, 1, '[\"human\"]', '{\"ancestry\": \"human\"}', '{}', 'You gain an extra 1st-level class feat.'),
		('nidalese_shadowcaster', 'Nidalese Shadowcaster', 0, 1, '[\"human\"]', '{\"ethnicity\": \"nidalese\"}', '{}', 'You harness the shadows of Nidal.'),
		('acrobat_dedication', 'Acrobat Dedication', 4, 2, '[\"dedication\", \"archetype\", \"acrobat\"]', '{\"min_stats\": {\"dex\": 2}, \"min_proficiency\": {\"acrobatics\": 1}}', '{\"set_proficiency\": {\"acrobatics\": 2}}', 'You become an acrobat.'),
		('dodge_away', 'Dodge Away', 4, 4, '[\"archetype\", \"acrobat\"]', '{\"requires_feat\": \"acrobat_dedication\"}', '{}', 'You dodge incoming attacks.'),
		('acrobat_grace', 'Acrobat Grace', 4, 4, '[\"archetype\", \"acrobat\"]', '{\"requires_feat\": \"acrobat_dedication\"}', '{}', 'You move with extreme grace.'),
		('assassin_dedication', 'Assassin Dedication', 4, 2, '[\"dedication\", \"archetype\", \"assassin\"]', '{}', '{}', 'You become an assassin.'),
		('titan_wrestler', 'Titan Wrestler', 2, 1, '[\"general\", \"skill\"]', '{\"min_proficiency\": {\"athletics\": 1}}', '{}', 'You can grapple larger foes.'),
		('elf_weapon_familiarity', 'Elven Weapon Familiarity', 0, 1, '[\"elf\"]', '{}', '{\"granted_familiarity\": [\"longbow\", \"composite longbow\", \"shortbow\", \"composite shortbow\", \"longsword\", \"rapier\"]}', 'You are trained with elven weapons.');")
		
	database.query("INSERT OR IGNORE INTO class_features (id, name, granted_rules, description) VALUES 
		('wizard_spellcasting', 'Arcane Spellcasting', '{}', 'You cast wizard spells.'),
		('arcane_thesis', 'Arcane Thesis', '{}', 'Your custom arcane research.');")
		
	database.query("INSERT OR IGNORE INTO class_progressions (class_id, level, granted_features, granted_feat_slots) VALUES 
		('wizard', 1, '[\"wizard_spellcasting\", \"arcane_thesis\"]', '[\"ancestry\"]'),
		('wizard', 2, '[]', '[\"class\", \"skill\"]');")
	
	database.query("INSERT OR IGNORE INTO weapons (id, name, traits, level, price_cp, material, hardness, max_hp, broken_threshold, grade, bulk, weapon_type, category, group_type, damage_dice, damage_faces, damage_type, range_increment, volley_range, reload_value, hands_required, ammunition_type) VALUES 
		('longsword', 'Longsword', 'versatile_p', 1, 100, 3, 5, 20, 10, 1, 1, 0, 1, 4, 1, 8, 3, 0, 0, 0, 1, 0),
		('bayonet_weapon', 'Bayonet Attack', 'agile,finesse', 1, 0, 3, 5, 20, 10, 1, 0, 0, 1, 6, 1, 4, 3, 0, 0, 0, 1, 0),
		('reinforced_stock_weapon', 'Reinforced Stock Attack', 'finesse,two_hand_d6', 1, 0, 2, 5, 20, 10, 1, 0, 0, 1, 5, 1, 4, 1, 0, 0, 0, 1, 0),
		('shield_boss_weapon', 'Shield Boss Attack', '', 1, 0, 3, 5, 20, 10, 1, 0, 0, 1, 5, 1, 6, 1, 0, 0, 0, 1, 0),
		('shield_spikes_weapon', 'Shield Spikes Attack', '', 1, 0, 3, 5, 20, 10, 1, 0, 0, 1, 10, 1, 6, 3, 0, 0, 0, 1, 0);")
		
	database.query("INSERT OR IGNORE INTO attachments (id, name, traits, level, price_cp, granted_weapon_id, granted_traits, valid_hosts) VALUES 
		('bayonet', 'Bayonet', 'attachment', 1, 230, 'bayonet_weapon', '', 'crossbow,firearm'),
		('reinforced_stock', 'Reinforced Stock', 'attachment', 1, 200, 'reinforced_stock_weapon', '', 'crossbow,firearm'),
		('shield_boss', 'Shield Boss', 'attachment', 1, 20, 'shield_boss_weapon', '', 'shield'),
		('shield_spikes', 'Shield Spikes', 'attachment', 1, 50, 'shield_spikes_weapon', '', 'shield'),
		('scope', 'Scope', 'attachment', 1, 500, '', 'deadly_d6', 'crossbow,firearm');")
		
	database.query("INSERT OR IGNORE INTO adjustments (id, name, traits, level, price_cp, granted_weapon_id, granted_traits, valid_hosts) VALUES 
		('shield_augmentation', 'Shield Augmentation', 'adjustment', 1, 0, '', '', 'shield'),
		('throwing_shield', 'Throwing Shield', 'adjustment', 1, 50, '', 'thrown_20', 'shield'),
		('counterweight', 'Counterweight', 'adjustment', 1, 20, '', 'agile', 'weapon'),
		('silencer', 'Silencer', 'adjustment', 1, 100, '', 'covert', 'firearm'),
		('armored_skirt', 'Armored Skirt', 'adjustment', 1, 200, '', '', 'armor');")
		
	database.query("INSERT OR IGNORE INTO shields (id, name, traits, level, price_cp, bulk, ac_bonus, speed_penalty, hardness, max_hp, broken_threshold) VALUES 
		('buckler', 'Buckler', 'buckler', 1, 10, 1, 1, 0, 3, 12, 6),
		('steel_shield', 'Steel Shield', '', 1, 200, 1, 2, 0, 5, 20, 10);")
		
	# Seed Character Creation Data
	database.query("INSERT OR IGNORE INTO ancestries (id, name, traits, hp, size, speed, boosts, flaws) VALUES 
		('human', 'Human', 'human,humanoid', 8, 'medium', 25, 'FREE,FREE', '');")
		
	database.query("INSERT OR IGNORE INTO backgrounds (id, name, traits, boosts, skills, lores, description) VALUES 
		('farmhand', 'Farmhand', '', 'CON,FREE', 'athletics', 'Farming Lore', 'You grew up working on a farm.');")
		
	# Fighter: 10 HP, STR or DEX key, Expert Perc/Fort/Ref, Trained Will, 3 skills
	# Trained Class DC (2). Expert unarmed/simple/martial, trained advanced. Trained all armor.
	database.query("INSERT OR IGNORE INTO classes (id, name, traits, hp_per_level, key_abilities, perception_rank, class_dc_rank, save_fort, save_ref, save_will, trained_skills_count, weapon_unarmed, weapon_simple, weapon_martial, weapon_advanced, armor_unarmored, armor_light, armor_medium, armor_heavy, forced_edicts, forced_anathema, is_spellcaster, caster_type, spell_tradition, spell_proficiency, spell_progression) VALUES 
		('fighter', 'Fighter', '', 10, 'STR,DEX', 4, 2, 4, 4, 2, 3, 4, 4, 4, 2, 2, 2, 2, 2, '[]', '[]', 0, 0, 0, 0, 0);")
		
	database.query("INSERT OR IGNORE INTO classes (id, name, traits, hp_per_level, key_abilities, perception_rank, class_dc_rank, save_fort, save_ref, save_will, trained_skills_count, weapon_unarmed, weapon_simple, weapon_martial, weapon_advanced, armor_unarmored, armor_light, armor_medium, armor_heavy, forced_edicts, forced_anathema, is_spellcaster, caster_type, spell_tradition, spell_proficiency, spell_progression) VALUES 
		('wizard', 'Wizard', '', 6, '[\"INT\"]', 2, 2, 2, 2, 4, 2, 2, 2, 0, 0, 2, 0, 0, 0, '[]', '[]', 1, 1, 1, 2, 1);")
		
	# Spells
	var tr_arc_occ = JSON.stringify([PFMagicConstants.MagicTradition.ARCANE, PFMagicConstants.MagicTradition.OCCULT])
	var tr_arc_pri = JSON.stringify([PFMagicConstants.MagicTradition.ARCANE, PFMagicConstants.MagicTradition.PRIMAL])
	
	database.query("INSERT OR IGNORE INTO spell_variants (spell_id, action_cost, spell_range, target, duration, damage_dice, damage_faces, applied_conditions, special_effects) VALUES 
		('ignition', 4, 30, '1 creature', '', 2, 4, '[]', '');")
		
	database.query("INSERT OR IGNORE INTO spells (id, name, traits, base_spell_rank, spell_category, traditions, saving_throw, is_attack, damage_type, scaling_rules, scaling_dice, description, script_path) VALUES 
		('illusory_object', 'Illusory Object', 'illusion,visual', 1, 0, '" + tr_arc_occ + "', '', 0, '', 0, 0, 'You create an illusion of an object.', '');")
	
	database.query("INSERT OR IGNORE INTO spells (id, name, traits, base_spell_rank, spell_category, traditions, saving_throw, is_attack, damage_type, scaling_rules, scaling_dice, description, script_path) VALUES 
		('ignition', 'Ignition', 'cantrip,fire', 1, 0, '" + tr_arc_pri + "', '', 1, 'fire', 1, 1, 'You snap your fingers and point, launching a spark that ignites your target.', 'res://scripts/magic/spells/pf_spell_ignition.gd');")
	
	database.query("INSERT OR IGNORE INTO spell_variants (spell_id, action_cost, spell_range, target, duration, damage_dice, damage_faces, applied_conditions, special_effects) VALUES 
		('illusory_object', 4, 500, '', '', 0, 0, '[]', '');")
		
	database.query("INSERT OR IGNORE INTO spells (id, name, traits, base_spell_rank, spell_category, traditions, saving_throw, is_attack, damage_type, scaling_rules, scaling_dice, description, script_path) VALUES 
		('creation', 'Creation', 'manipulate', 4, 0, '" + tr_arc_pri + "', '', 0, '', 0, 0, 'You create a temporary object.', '');")
		
	database.query("INSERT OR IGNORE INTO spells (id, name, traits, base_spell_rank, spell_category, traditions, saving_throw, is_attack, damage_type, scaling_rules, scaling_dice, description, script_path) VALUES 
		('fireball', 'Fireball', 'fire,concentrate,manipulate', 3, 0, '" + tr_arc_pri + "', 'Reflex', 0, 'fire', 1, 2, 'A roaring blast of fire appears at a spot you designate, dealing 6d6 fire damage.', '');")
		
	database.query("INSERT OR IGNORE INTO spell_variants (spell_id, action_cost, spell_range, target, duration, damage_dice, damage_faces, applied_conditions, special_effects) VALUES 
		('fireball', 2, 500, '20-foot burst', '', 6, 6, '[]', '');")
	
	database.query("INSERT OR IGNORE INTO spell_variants (spell_id, action_cost, spell_range, target, duration, damage_dice, damage_faces, applied_conditions, special_effects) VALUES 
		('creation', 4, 0, '', '1 hour', 0, 0, '[]', '');")
		
	# Deity: Abadar
	var abadar_edicts = JSON.stringify(["bring_civilization", "earn_wealth", "follow_law"])
	var abadar_anathema = JSON.stringify(["banditry_piracy", "steal", "undermine_court"])
	var abadar_areas = JSON.stringify(["cities", "law", "merchants", "wealth"])
	var abadar_colors = JSON.stringify(["gold", "silver"])
	var abadar_pantheons = JSON.stringify(["Talons of the Godclaw", "The Deliberate Journey", "The Godclaw", "The Offering Plate", "The Resplendent Court", "Urban Prosperity"])
	var abadar_attributes = JSON.stringify(["CON", "INT"])
	var abadar_fonts = JSON.stringify(["harm", "heal"])
	var abadar_domains = JSON.stringify(["cities", "earth", "travel", "wealth"])
	var abadar_alt_domains = JSON.stringify(["creation", "duty", "metal", "toil"])
	var abadar_spells = JSON.stringify({"1": "illusory_object", "4": "creation"})
	
	database.query("INSERT OR IGNORE INTO deities (id, name, category, edicts, anathema, areas_of_concern, religious_symbol, sacred_animal, sacred_colors, pantheons, divine_attributes, divine_font, divine_sanctification, divine_skill, favored_weapon, domains, alternate_domains, cleric_spells, boon_minor, boon_moderate, boon_major, curse_minor, curse_moderate, curse_major) VALUES " + 
	"('abadar', 'Abadar', 'Gods of the Inner Sea', '" + abadar_edicts + "', '" + abadar_anathema + "', '" + abadar_areas + "', 'golden key', 'monkey', '" + abadar_colors + "', '" + abadar_pantheons + "', '" + abadar_attributes + "', '" + abadar_fonts + "', 'can choose holy or unholy', 'society', 'crossbow', '" + abadar_domains + "', '" + abadar_alt_domains + "', '" + abadar_spells + "', '', '', '', '', '', '');")

# ---------------------------------------------------------
# CACHED DATA-DRIVEN FETCHERS
# ---------------------------------------------------------

func get_size_data(size_id: StringName) -> Dictionary:
	if _sizes_cache.has(size_id): return _sizes_cache[size_id]
	database.query("SELECT * FROM sizes WHERE id = '" + str(size_id) + "'")
	if database.query_result.size() == 0:
		push_error("PFDatabase: Size not found -> " + str(size_id))
		return {}
	_sizes_cache[size_id] = database.query_result[0]
	return _sizes_cache[size_id]

func get_trait_data(trait_id: StringName) -> Dictionary:
	if _traits_cache.has(trait_id): return _traits_cache[trait_id]
	database.query("SELECT * FROM traits WHERE id = '" + str(trait_id) + "'")
	if database.query_result.size() == 0:
		push_error("PFDatabase: Trait not found -> " + str(trait_id))
		return {}
	_traits_cache[trait_id] = database.query_result[0]
	return _traits_cache[trait_id]

func get_condition_data(condition_id: StringName, silent: bool = false) -> Dictionary:
	if _conditions_cache.has(condition_id): return _conditions_cache[condition_id]
	database.query("SELECT * FROM conditions WHERE id = '" + str(condition_id) + "'")
	if database.query_result.size() == 0:
		if not silent:
			push_error("PFDatabase: Condition not found -> " + str(condition_id))
		return {}
	_conditions_cache[condition_id] = database.query_result[0]
	return _conditions_cache[condition_id]

func get_affliction_data(affliction_id: StringName, silent: bool = false) -> Dictionary:
	if _afflictions_cache.has(affliction_id): return _afflictions_cache[affliction_id]
	database.query("SELECT * FROM afflictions WHERE id = '" + str(affliction_id) + "'")
	if database.query_result.size() == 0:
		if not silent:
			push_error("PFDatabase: Affliction not found -> " + str(affliction_id))
		return {}
	_afflictions_cache[affliction_id] = database.query_result[0]
	return _afflictions_cache[affliction_id]

func get_belief_data(belief_id: StringName) -> Dictionary:
	if _beliefs_cache.has(belief_id): return _beliefs_cache[belief_id]
	database.query("SELECT * FROM beliefs WHERE id = '" + str(belief_id) + "'")
	if database.query_result.size() == 0:
		push_error("PFDatabase: Belief not found -> " + str(belief_id))
		return {}
	_beliefs_cache[belief_id] = database.query_result[0]
	return _beliefs_cache[belief_id]

func get_skill_data(skill_id: StringName) -> Dictionary:
	if _skills_cache.has(skill_id): return _skills_cache[skill_id]
	database.query("SELECT * FROM skills WHERE id = '" + str(skill_id) + "'")
	if database.query_result.size() == 0:
		return {}
	_skills_cache[skill_id] = database.query_result[0]
	return _skills_cache[skill_id]

func get_core_skills() -> Array[StringName]:
	database.query("SELECT id FROM skills WHERE is_lore = 0")
	var result: Array[StringName] = []
	for row in database.query_result:
		result.append(StringName(row["id"]))
	return result

func get_language_data(language_id: StringName) -> Dictionary:
	if _languages_cache.has(language_id): return _languages_cache[language_id]
	database.query("SELECT * FROM languages WHERE id = '" + str(language_id) + "'")
	if database.query_result.size() == 0:
		push_error("PFDatabase: Language not found -> " + str(language_id))
		return {}
	_languages_cache[language_id] = database.query_result[0]
	return _languages_cache[language_id]

func get_all_common_languages() -> Array[StringName]:
	database.query("SELECT id FROM languages WHERE rarity = 0")
	var result: Array[StringName] = []
	for row in database.query_result:
		result.append(StringName(row["id"]))
	return result

func get_region_data(region_id: StringName) -> Dictionary:
	if _regions_cache.has(region_id): return _regions_cache[region_id]
	database.query("SELECT * FROM regions WHERE id = '" + str(region_id) + "'")
	if database.query_result.size() == 0:
		return {}
	_regions_cache[region_id] = database.query_result[0]
	return _regions_cache[region_id]

func get_heritage(id: String) -> PFHeritage:
	if _heritages_cache.has(id): return _heritages_cache[id]
	
	database.query("SELECT * FROM heritages WHERE id = '" + id + "'")
	if database.query_result.size() == 0:
		push_error("PFDatabase: Heritage not found -> " + id)
		return null
		
	var row = database.query_result[0]
	var new_heritage = PFHeritage.new()
	new_heritage.entity_name = row["name"]
	new_heritage.ancestry_id = StringName(row["ancestry_id"])
	new_heritage.is_versatile = row["is_versatile"] == 1
	new_heritage.hp_bonus = row["hp_bonus"]
	new_heritage.size_id = StringName(row["size_id"])
	new_heritage.speed_bonus = row["speed_bonus"]
	new_heritage.vision_override = row["vision_override"]
	new_heritage.rarity = row["rarity"]
	
	if row["traits"] and row["traits"] != "":
		var parsed = JSON.parse_string(row["traits"])
		if parsed: 
			for t in parsed: new_heritage.traits.append(StringName(t))
			
	if row["granted_traits"] and row["granted_traits"] != "":
		var parsed = JSON.parse_string(row["granted_traits"])
		if parsed: 
			for t in parsed: new_heritage.granted_traits.append(StringName(t))
			
	_heritages_cache[id] = new_heritage
	return new_heritage

func get_ethnicity_data(ethnicity_id: StringName) -> Dictionary:
	if _ethnicities_cache.has(ethnicity_id): return _ethnicities_cache[ethnicity_id]
	database.query("SELECT * FROM ethnicities WHERE id = '" + String(ethnicity_id) + "';")
	var result = database.query_result
	if result.size() > 0:
		var row = result[0]
		var data = {
			"id": StringName(row["id"]),
			"name": row["name"],
			"required_traits": JSON.parse_string(row["required_traits"]) if row["required_traits"] != "" else [],
			"description": row["description"]
		}
		_ethnicities_cache[ethnicity_id] = data
		return data
	return {}

func get_available_ethnicities_for_traits(actor_traits: Array[StringName]) -> Array[Dictionary]:
	if database == null: return []
	
	database.query("SELECT * FROM ethnicities;")
	var all_ethnicities = database.query_result
	var valid_ethnicities: Array[Dictionary] = []
	
	for row in all_ethnicities:
		var reqs = JSON.parse_string(row["required_traits"]) if row["required_traits"] != "" else []
		var meets_reqs = true
		for req in reqs:
			if not actor_traits.has(StringName(req)):
				meets_reqs = false
				break
		
		if meets_reqs:
			valid_ethnicities.append({
				"id": StringName(row["id"]),
				"name": row["name"],
				"required_traits": reqs,
				"description": row["description"]
			})
			
	return valid_ethnicities

func get_animal_companion_data(id: StringName) -> Dictionary:
	if _animal_companions_cache.has(id): return _animal_companions_cache[id]
	database.query("SELECT * FROM animal_companions WHERE id = '" + String(id) + "'")
	if database.query_result.size() == 0:
		push_error("PFDatabase: Animal Companion not found -> " + String(id))
		return {}
	_animal_companions_cache[id] = database.query_result[0]
	return _animal_companions_cache[id]

func get_specific_familiar(id: StringName) -> Dictionary:
	if _specific_familiars_cache.has(id): return _specific_familiars_cache[id]
	database.query("SELECT * FROM specific_familiars WHERE id = '" + String(id) + "'")
	if database.query_result.size() == 0:
		push_error("PFDatabase: Specific Familiar not found -> " + String(id))
		return {}
	_specific_familiars_cache[id] = database.query_result[0]
	return _specific_familiars_cache[id]

func get_class_data(id: StringName) -> Dictionary:
	if _classes_cache.has(id): return _classes_cache[id]
	database.query("SELECT * FROM classes WHERE id = '" + String(id) + "'")
	if database.query_result.size() == 0:
		push_error("PFDatabase: Class not found -> " + String(id))
		return {}
	_classes_cache[id] = database.query_result[0]
	return _classes_cache[id]

func get_spell_data(id: StringName) -> Dictionary:
	if _spells_cache.has(id): return _spells_cache[id]
	database.query("SELECT * FROM spells WHERE id = '" + String(id) + "'")
	if database.query_result.size() == 0:
		push_error("PFDatabase: Spell not found -> " + String(id))
		return {}
	_spells_cache[id] = database.query_result[0]
	return _spells_cache[id]

func get_feat_data(id: StringName) -> Dictionary:
	if _feats_cache.has(id): return _feats_cache[id]
	database.query("SELECT * FROM feats WHERE id = '" + String(id) + "'")
	if database.query_result.size() == 0:
		push_error("PFDatabase: Feat not found -> " + String(id))
		return {}
	_feats_cache[id] = database.query_result[0]
	return _feats_cache[id]

func get_class_feature_data(id: StringName) -> Dictionary:
	if _class_features_cache.has(id): return _class_features_cache[id]
	database.query("SELECT * FROM class_features WHERE id = '" + String(id) + "'")
	if database.query_result.size() == 0:
		push_error("PFDatabase: Class Feature not found -> " + String(id))
		return {}
	_class_features_cache[id] = database.query_result[0]
	return _class_features_cache[id]

func get_class_progression(class_id: StringName, level: int) -> Dictionary:
	var _key = String(class_id) + "_" + str(level)
	if _class_progressions_cache.has(_key): return _class_progressions_cache[_key]
	database.query("SELECT * FROM class_progressions WHERE class_id = '" + String(class_id) + "' AND level = " + str(level))
	if database.query_result.size() == 0:
		return {}
	_class_progressions_cache[_key] = database.query_result[0]
	return _class_progressions_cache[_key]

func get_weapon(id: String) -> PFWeapon:
	var row: Dictionary
	if _weapons_cache.has(id):
		row = _weapons_cache[id]
	else:
		database.query("SELECT * FROM weapons WHERE id = '" + id + "'")
		if database.query_result.size() == 0:
			push_error("PFDatabase: Weapon not found -> " + id)
			return null
			
		row = database.query_result[0]
		_weapons_cache[id] = row
	var new_weapon = PFWeapon.new()
	
	new_weapon.entity_name = row["name"]
	new_weapon.base_name = row["name"]
	
	var traits_array: Array[StringName] = []
	if row["traits"] != "":
		var split = row["traits"].split(",")
		for t in split:
			traits_array.append(StringName(t.strip_edges()))
	new_weapon.traits = traits_array
	
	new_weapon.level = row["level"]
	new_weapon.base_level = row["level"]
	new_weapon.price_cp = row["price_cp"]
	new_weapon.base_price_cp = row["price_cp"]
	
	new_weapon.item_material = row["material"]
	new_weapon.hardness = row["hardness"]
	new_weapon.max_hp = row["max_hp"]
	new_weapon.current_hp = row["max_hp"]
	new_weapon.broken_threshold = row["broken_threshold"]
	new_weapon.grade = row["grade"]
	new_weapon.bulk_value = row["bulk"]
	new_weapon.base_bulk_value = row["bulk"]
	
	new_weapon.weapon_type = row["weapon_type"]
	new_weapon.category = row["category"]
	new_weapon.group = row["group_type"]
	
	new_weapon.base_dice_amount = row["damage_dice"]
	new_weapon.dice_amount = row["damage_dice"]
	new_weapon.die_faces = row["damage_faces"]
	new_weapon.base_damage_type = row["damage_type"]
	new_weapon.active_damage_type = row["damage_type"]
	
	new_weapon.range_increment = row.get(&"range_increment", 0) if row.has(&"range_increment") else 0
	new_weapon.volley_range = row.get(&"volley_range", 0) if row.has(&"volley_range") else 0
	new_weapon.reload_value = row.get(&"reload_value", 0) if row.has(&"reload_value") else 0
	new_weapon.hands_required = row.get(&"hands_required", 1) if row.has(&"hands_required") else 1
	new_weapon.ammunition_type = row.get(&"ammunition_type", 0) if row.has(&"ammunition_type") else 0
	new_weapon.linked_weapon_id = row.get(&"linked_weapon_id", "") if row.has(&"linked_weapon_id") else ""
	new_weapon.is_specific_magic = row.get(&"is_specific_magic", 0) == 1 if row.has(&"is_specific_magic") else false
	if row.has(&"granted_actions") and row["granted_actions"] != "":
		var actions_split = row["granted_actions"].split(",")
		for a in actions_split:
			new_weapon.granted_actions.append(StringName(a.strip_edges()))
	
	if new_weapon.linked_weapon_id != "":
		database.query("SELECT * FROM weapons WHERE id = '" + new_weapon.linked_weapon_id + "'")
		if database.query_result.size() > 0:
			new_weapon.combination_data = database.query_result[0]
	
	return new_weapon

func get_armor(id: String) -> PFArmor:
	var row: Dictionary
	if _armors_cache.has(id):
		row = _armors_cache[id]
	else:
		database.query("SELECT * FROM armors WHERE id = '" + id + "'")
		if database.query_result.size() == 0:
			push_error("PFDatabase: Armor not found -> " + id)
			return null
			
		row = database.query_result[0]
		_armors_cache[id] = row
	var new_armor = PFArmor.new()
	
	new_armor.entity_name = row["name"]
	new_armor.base_name = row["name"]
	
	var traits_array: Array[StringName] = []
	if row["traits"] != "":
		var split = row["traits"].split(",")
		for t in split:
			traits_array.append(StringName(t.strip_edges()))
	new_armor.traits = traits_array
	
	new_armor.level = row["level"]
	new_armor.base_level = row["level"]
	new_armor.price_cp = row["price_cp"]
	new_armor.base_price_cp = row["price_cp"]
	
	new_armor.item_material = row["material"]
	new_armor.hardness = row["hardness"]
	new_armor.max_hp = row["max_hp"]
	new_armor.current_hp = row["max_hp"]
	new_armor.broken_threshold = row["broken_threshold"]
	new_armor.grade = row["grade"]
	new_armor.bulk_value = row["bulk"]
	new_armor.base_bulk_value = row["bulk"]
	
	new_armor.category = row["category"]
	new_armor.group = row["group_type"]
	new_armor.base_ac_bonus = row["ac_bonus"]
	new_armor.ac_bonus = row["ac_bonus"]
	new_armor.dex_cap = row["dex_cap"]
	new_armor.check_penalty = row["check_penalty"]
	new_armor.speed_penalty = row["speed_penalty"]
	new_armor.strength_req = row["strength_req"]
	
	new_armor.is_specific_magic = row.get(&"is_specific_magic", 0) == 1 if row.has(&"is_specific_magic") else false
	if row.has(&"granted_actions") and row["granted_actions"] != "":
		var actions_split = row["granted_actions"].split(",")
		for a in actions_split:
			new_armor.granted_actions.append(StringName(a.strip_edges()))
	
	return new_armor

func get_shield(id: String) -> PFShield:
	var row: Dictionary
	if _shields_cache.has(id):
		row = _shields_cache[id]
	else:
		database.query("SELECT * FROM shields WHERE id = '" + id + "'")
		if database.query_result.size() == 0:
			push_error("PFDatabase: Shield not found -> " + id)
			return null
			
		row = database.query_result[0]
		_shields_cache[id] = row
	var new_shield = PFShield.new()
	
	new_shield.entity_name = row["name"]
	new_shield.base_name = row["name"]
	
	var traits_array: Array[StringName] = []
	if row["traits"] != "":
		var split = row["traits"].split(",")
		for t in split:
			traits_array.append(StringName(t.strip_edges()))
	new_shield.traits = traits_array
	
	new_shield.level = row["level"]
	new_shield.base_level = row["level"]
	new_shield.price_cp = row["price_cp"]
	new_shield.base_price_cp = row["price_cp"]
	
	new_shield.bulk_value = row["bulk"]
	new_shield.base_bulk_value = row["bulk"]
	
	new_shield.ac_bonus = row["ac_bonus"]
	new_shield.speed_penalty = row["speed_penalty"]
	
	new_shield.base_hardness = row["hardness"]
	new_shield.hardness = row["hardness"]
	new_shield.base_max_hp = row["max_hp"]
	new_shield.max_hp = row["max_hp"]
	new_shield.current_hp = row["max_hp"]
	new_shield.base_broken_threshold = row["broken_threshold"]
	new_shield.broken_threshold = row["broken_threshold"]
	new_shield.is_specific_magic = row.get(&"is_specific_magic", 0) == 1 if row.has(&"is_specific_magic") else false
	if row.has(&"granted_actions") and row["granted_actions"] != "":
		var actions_split = row["granted_actions"].split(",")
		for a in actions_split:
			new_shield.granted_actions.append(StringName(a.strip_edges()))
	
	return new_shield

func get_attachment(id: String) -> PFAttachment:
	var row: Dictionary
	if _attachments_cache.has(id):
		row = _attachments_cache[id]
	else:
		database.query("SELECT * FROM attachments WHERE id = '" + id + "'")
		if database.query_result.size() == 0:
			push_error("PFDatabase: Attachment not found -> " + id)
			return null
			
		row = database.query_result[0]
		_attachments_cache[id] = row
	var new_attach = PFAttachment.new()
	new_attach.entity_name = row["name"]
	new_attach.level = row["level"]
	new_attach.price_cp = row["price_cp"]
	
	if row["traits"] != "":
		var split = row["traits"].split(",")
		for t in split:
			new_attach.traits.append(StringName(t.strip_edges()))
			
	if row["granted_traits"] != "":
		var split = row["granted_traits"].split(",")
		for t in split:
			new_attach.granted_traits.append(StringName(t.strip_edges()))
			
	if row["valid_hosts"] != "":
		var split = row["valid_hosts"].split(",")
		for v in split:
			new_attach.valid_hosts.append(v.strip_edges())
			
	if row["granted_weapon_id"] != "":
		new_attach.granted_weapon = get_weapon(row["granted_weapon_id"])
		
	return new_attach

func get_adjustment(id: String) -> PFAdjustment:
	var row: Dictionary
	if _adjustments_cache.has(id):
		row = _adjustments_cache[id]
	else:
		database.query("SELECT * FROM adjustments WHERE id = '" + id + "'")
		if database.query_result.size() == 0:
			push_error("PFDatabase: Adjustment not found -> " + id)
			return null
			
		row = database.query_result[0]
		_adjustments_cache[id] = row
	var new_adj = PFAdjustment.new()
	new_adj.entity_name = row["name"]
	new_adj.level = row["level"]
	new_adj.price_cp = row["price_cp"]
	
	if row["traits"] != "":
		var split = row["traits"].split(",")
		for t in split:
			new_adj.traits.append(StringName(t.strip_edges()))
			
	if row["granted_traits"] != "":
		var split = row["granted_traits"].split(",")
		for t in split:
			new_adj.granted_traits.append(StringName(t.strip_edges()))
			
	if row["valid_hosts"] != "":
		var split = row["valid_hosts"].split(",")
		for v in split:
			new_adj.valid_hosts.append(v.strip_edges())
			
	return new_adj

func get_ancestry(id: String) -> PFAncestry:
	var row: Dictionary
	if _ancestries_cache.has(id):
		row = _ancestries_cache[id]
	else:
		database.query("SELECT * FROM ancestries WHERE id = '" + id + "'")
		if database.query_result.size() == 0:
			push_error("PFDatabase: Ancestry not found -> " + id)
			return null
			
		row = database.query_result[0]
		_ancestries_cache[id] = row
	var new_ancestry = PFAncestry.new()
	new_ancestry.entity_name = row["name"]
	new_ancestry.hp = row["hp"]
	new_ancestry.size_id = StringName(row["size"])
	new_ancestry.speed = row["speed"]
	
	if row["boosts"] != "":
		for b in row["boosts"].split(","):
			new_ancestry.ability_boosts.append(StringName(b.strip_edges()))
	if row["flaws"] != "":
		for f in row["flaws"].split(","):
			new_ancestry.ability_flaws.append(StringName(f.strip_edges()))
			
	return new_ancestry

func get_background(id: String) -> PFBackground:
	var row: Dictionary
	if _backgrounds_cache.has(id):
		row = _backgrounds_cache[id]
	else:
		database.query("SELECT * FROM backgrounds WHERE id = '" + id + "'")
		if database.query_result.size() == 0:
			push_error("PFDatabase: Background not found -> " + id)
			return null
			
		row = database.query_result[0]
		_backgrounds_cache[id] = row
	var new_background = PFBackground.new()
	new_background.entity_name = row["name"]
	new_background.background_description = row["description"]
	
	if row["boosts"] != "":
		for x in row["boosts"].split(","):
			new_background.ability_boosts.append(StringName(x.strip_edges()))
	if row["skills"] != "":
		for x in row["skills"].split(","):
			new_background.trained_skills.append(StringName(x.strip_edges()))
	if row["lores"] != "":
		for x in row["lores"].split(","):
			new_background.trained_lores.append(StringName(x.strip_edges()))
			
	return new_background

func get_pf_class(id: String) -> PFClass:
	database.query("SELECT * FROM classes WHERE id = '" + id + "'")
	if database.query_result.size() == 0:
		push_error("PFDatabase: Class not found -> " + id)
		return null
		
	var row = database.query_result[0]
	var new_class = PFClass.new()
	new_class.entity_name = row["name"]
	new_class.hp_per_level = row["hp_per_level"]
	new_class.perception_rank = row["perception_rank"] as PFMathConstants.ProficiencyRank
	new_class.class_dc_rank = row["class_dc_rank"] as PFMathConstants.ProficiencyRank
	new_class.trained_skills_count = row["trained_skills_count"]
	
	if row["forced_edicts"] and row["forced_edicts"] != "":
		var parsed = JSON.parse_string(row["forced_edicts"])
		if parsed: 
			for e in parsed: new_class.forced_edicts.append(StringName(e))
		
	if row["forced_anathema"] and row["forced_anathema"] != "":
		var parsed = JSON.parse_string(row["forced_anathema"])
		if parsed: 
			for a in parsed: new_class.forced_anathema.append(StringName(a))
		
	new_class.is_spellcaster = (row["is_spellcaster"] == 1)
	new_class.caster_type = row["caster_type"] as PFMagicConstants.CasterType
	new_class.spell_tradition = row["spell_tradition"] as PFMagicConstants.MagicTradition
	new_class.spell_proficiency = row["spell_proficiency"] as PFMathConstants.ProficiencyRank
	new_class.spell_progression = row["spell_progression"] as PFMagicConstants.SpellProgression
	
	if row["key_abilities"] != "":
		for k in row["key_abilities"].split(","):
			new_class.key_abilities.append(StringName(k.strip_edges()))
			
	new_class.saving_throws = {
		"fort": row["save_fort"] as PFMathConstants.ProficiencyRank,
		"ref": row["save_ref"] as PFMathConstants.ProficiencyRank,
		"will": row["save_will"] as PFMathConstants.ProficiencyRank
	}
	
	new_class.weapon_proficiencies = {
		PFEquipmentConstants.WeaponCategory.UNARMED: row["weapon_unarmed"] as PFMathConstants.ProficiencyRank,
		PFEquipmentConstants.WeaponCategory.SIMPLE: row["weapon_simple"] as PFMathConstants.ProficiencyRank,
		PFEquipmentConstants.WeaponCategory.MARTIAL: row["weapon_martial"] as PFMathConstants.ProficiencyRank,
		PFEquipmentConstants.WeaponCategory.ADVANCED: row["weapon_advanced"] as PFMathConstants.ProficiencyRank
	}
	
	new_class.armor_proficiencies = {
		PFEquipmentConstants.ArmorCategory.UNARMORED: row["armor_unarmored"] as PFMathConstants.ProficiencyRank,
		PFEquipmentConstants.ArmorCategory.LIGHT: row["armor_light"] as PFMathConstants.ProficiencyRank,
		PFEquipmentConstants.ArmorCategory.MEDIUM: row["armor_medium"] as PFMathConstants.ProficiencyRank,
		PFEquipmentConstants.ArmorCategory.HEAVY: row["armor_heavy"] as PFMathConstants.ProficiencyRank
	}
	
	return new_class


func get_pf_deity(id: String) -> PFDeity:
	var row: Dictionary
	if _deities_cache.has(id):
		row = _deities_cache[id]
	else:
		database.query("SELECT * FROM deities WHERE id = '" + id + "'")
		if database.query_result.size() == 0:
			push_error("PFDatabase: Deity not found -> " + id)
			return null
			
		row = database.query_result[0]
		_deities_cache[id] = row
	var new_deity = PFDeity.new()
	new_deity.entity_name = row["name"]
	new_deity.category = row["category"]
	new_deity.religious_symbol = row["religious_symbol"]
	new_deity.sacred_animal = row["sacred_animal"]
	new_deity.divine_sanctification = int(row["divine_sanctification"]) as PFBiographyConstants.DivineSanctification
	new_deity.divine_skill = StringName(row["divine_skill"])
	new_deity.favored_weapon = StringName(row["favored_weapon"])
	new_deity.boon_minor = row["boon_minor"]
	new_deity.boon_moderate = row["boon_moderate"]
	new_deity.boon_major = row["boon_major"]
	new_deity.curse_minor = row["curse_minor"]
	new_deity.curse_moderate = row["curse_moderate"]
	new_deity.curse_major = row["curse_major"]
	
	# Parse all the JSON Arrays
	var parsed_edicts = JSON.parse_string(row["edicts"])
	if parsed_edicts: 
		for e in parsed_edicts: new_deity.edicts.append(StringName(e))
	
	var parsed_anathema = JSON.parse_string(row["anathema"])
	if parsed_anathema: 
		for a in parsed_anathema: new_deity.anathema.append(StringName(a))
	
	var parsed_areas = JSON.parse_string(row["areas_of_concern"])
	if parsed_areas: new_deity.areas_of_concern.assign(parsed_areas)
	
	var parsed_colors = JSON.parse_string(row["sacred_colors"])
	if parsed_colors: new_deity.sacred_colors.assign(parsed_colors)
	
	var parsed_pantheons = JSON.parse_string(row["pantheons"])
	if parsed_pantheons: new_deity.pantheons.assign(parsed_pantheons)
	
	var parsed_attributes = JSON.parse_string(row["divine_attributes"])
	if parsed_attributes: 
		for attribute in parsed_attributes: new_deity.divine_attributes.append(StringName(attribute))
		
	var parsed_fonts = JSON.parse_string(row["divine_font"])
	if parsed_fonts: new_deity.divine_font.assign(parsed_fonts)
	
	var parsed_domains = JSON.parse_string(row["domains"])
	if parsed_domains: new_deity.domains.assign(parsed_domains)
	
	var parsed_alt_domains = JSON.parse_string(row["alternate_domains"])
	if parsed_alt_domains: new_deity.alternate_domains.assign(parsed_alt_domains)
	
	var parsed_spells = JSON.parse_string(row["cleric_spells"])
	if parsed_spells: new_deity.cleric_spells = parsed_spells
	
	return new_deity


func get_action_data(action_id: StringName) -> Dictionary:
	if _actions_cache.has(action_id):
		return _actions_cache[action_id]
	database.query("SELECT * FROM actions WHERE id = '" + str(action_id) + "';")
	var result = database.query_result
	if result.is_empty():
		return {}
	_actions_cache[action_id] = result[0]
	return result[0]

# --- PLAYER KNOWLEDGE (BESTIARY) ---

## Retrieves the current player knowledge state for a given monster base ID.
func get_player_knowledge(monster_id: String) -> Dictionary:
	if _player_knowledge_cache.has(monster_id): return _player_knowledge_cache[monster_id]
	database.query("SELECT * FROM player_knowledge WHERE monster_id = '" + monster_id + "';")
	var result = database.query_result
	if result.is_empty():
		return {}
	_player_knowledge_cache[monster_id] = result[0]
	return result[0]

## Updates specific knowledge fields for a given monster ID.
## Updates is a dictionary of { "state_field": value }
func update_player_knowledge(monster_id: String, updates: Dictionary) -> void:
	if updates.is_empty(): return
	
	# Check if exists
	database.query("SELECT monster_id FROM player_knowledge WHERE monster_id = '" + monster_id + "';")
	var exists = not database.query_result.is_empty()
	
	if not exists:
		database.query("INSERT INTO player_knowledge (monster_id) VALUES ('" + monster_id + "');")
		
	var set_statements = []
	for key in updates.keys():
		var val = updates[key]
		if typeof(val) == TYPE_STRING:
			# Escape single quotes
			val = val.replace("'", "''")
			set_statements.append("%s = '%s'" % [key, val])
		else:
			set_statements.append("%s = %s" % [key, str(val)])
			
	var sql_query = "UPDATE player_knowledge SET " + ", ".join(set_statements) + " WHERE monster_id = '" + monster_id + "';"
	database.query(sql_query)
	_player_knowledge_cache.erase(monster_id)

# --- HAZARDS ---

func get_hazard_data(hazard_id: String) -> Dictionary:
	if _hazards_cache.has(hazard_id): return _hazards_cache[hazard_id]
	database.query("SELECT * FROM hazards WHERE id = '" + hazard_id + "';")
	var result = database.query_result
	if result.is_empty():
		return {}
	_hazards_cache[hazard_id] = result[0]
	return result[0]

# --- DOMAINS & RELIGION ---

func get_domain_data(domain_id: String) -> Dictionary:
	if _domains_cache.has(domain_id): return _domains_cache[domain_id]
	database.query("SELECT * FROM domains WHERE id = '" + domain_id + "';")
	var result = database.query_result
	if result.is_empty(): return {}
	_domains_cache[domain_id] = result[0]
	return result[0]

func get_edict_data(edict_id: String) -> Dictionary:
	if _edicts_cache.has(edict_id): return _edicts_cache[edict_id]
	database.query("SELECT * FROM edicts WHERE id = '" + edict_id + "';")
	var result = database.query_result
	if result.is_empty(): return {}
	_edicts_cache[edict_id] = result[0]
	return result[0]

func get_anathema_data(anathema_id: String) -> Dictionary:
	if _anathemas_cache.has(anathema_id): return _anathemas_cache[anathema_id]
	database.query("SELECT * FROM anathemas WHERE id = '" + anathema_id + "';")
	var result = database.query_result
	if result.is_empty(): return {}
	_anathemas_cache[anathema_id] = result[0]
	return result[0]

# --- SPELL VARIANTS ---

func get_spell_variant_data(variant_id: int) -> Dictionary:
	if _spell_variants_cache.has(variant_id): return _spell_variants_cache[variant_id]
	database.query("SELECT * FROM spell_variants WHERE id = " + str(variant_id) + ";")
	var result = database.query_result
	if result.is_empty(): return {}
	_spell_variants_cache[variant_id] = result[0]
	return result[0]
