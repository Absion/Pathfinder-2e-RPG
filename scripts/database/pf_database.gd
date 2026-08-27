# pf_database.gd
## A stateless singleton that parses sqlite data into GDScript Objects.
class_name PFDatabase
extends Node

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
var _deities_cache: Dictionary = {}

static var _instance_cache: PFDatabase = null

static func get_instance() -> PFDatabase:
	if _instance_cache != null and is_instance_valid(_instance_cache):
		return _instance_cache

	var ml = Engine.get_main_loop()
	if ml:
		if ml.root.has_node("PFDB"):
			_instance_cache = ml.root.get_node("PFDB") as PFDatabase
			return _instance_cache
		elif ml.root.has_node("PFDatabase"):
			_instance_cache = ml.root.get_node("PFDatabase") as PFDatabase
			return _instance_cache
	return null

func _ready():
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

func _ensure_ancestries_columns() -> void:
	if not database:
		return
	var existing_cols: Array[String] = []
	if database.query("PRAGMA table_info(ancestries)"):
		for row in database.query_result:
			if row.has("name"):
				existing_cols.append(String(row["name"]).to_lower())

	var required_cols: Dictionary = {
		"rarity": "INTEGER DEFAULT 0",
		"speed_fly": "INTEGER DEFAULT 0",
		"speed_swim": "INTEGER DEFAULT 0",
		"speed_climb": "INTEGER DEFAULT 0",
		"speed_burrow": "INTEGER DEFAULT 0",
		"alternate_boosts": "TEXT",
		"known_languages": "TEXT",
		"vision": "INTEGER DEFAULT 0",
		"additional_senses": "TEXT",
		"ethnicities": "TEXT",
		"heritages": "TEXT",
		"physical_description": "TEXT",
		"societal_description": "TEXT",
		"common_beliefs": "TEXT",
		"common_edicts": "TEXT",
		"common_anathema": "TEXT",
		"common_names": "TEXT",
		"granted_abilities": "TEXT",
		"starting_gold": "INTEGER DEFAULT 15"
	}

	for col_name in required_cols:
		if not existing_cols.has(col_name):
			database.query("ALTER TABLE ancestries ADD COLUMN " + col_name + " " + required_cols[col_name])

func _parse_stringname_array(val: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	if val == null: return result
	if val is Array:
		for item in val:
			result.append(StringName(str(item).strip_edges()))
		return result
	var s = str(val).strip_edges()
	if s == "" or s == "[]": return result
	
	if s.begins_with("[") and s.contains('"'):
		var parsed = JSON.parse_string(s)
		if parsed is Array:
			for item in parsed:
				result.append(StringName(str(item).strip_edges()))
			return result
			
	if s.to_lower().contains("two free"):
		result.append(&"FREE")
		result.append(&"FREE")
		return result
		
	s = s.trim_prefix("[").trim_suffix("]")
	for part in s.split(","):
		var cleaned = part.strip_edges().trim_prefix('"').trim_suffix('"').trim_prefix("'").trim_suffix("'")
		if cleaned != "":
			var upper = cleaned.to_upper()
			var lower = cleaned.to_lower()
			if upper in ["STR", "DEX", "CON", "INT", "WIS", "CHA", "FREE"]:
				result.append(StringName(upper))
			elif lower in ["strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma", "free"]:
				var m = {"strength": &"STR", "dexterity": &"DEX", "constitution": &"CON", "intelligence": &"INT", "wisdom": &"WIS", "charisma": &"CHA", "free": &"FREE"}
				result.append(m[lower])
			else:
				result.append(StringName(lower))
	return result

func _parse_string_array(val: Variant) -> Array[String]:
	var result: Array[String] = []
	if val == null: return result
	if val is Array:
		for item in val:
			result.append(str(item).strip_edges())
		return result
	var s = str(val).strip_edges()
	if s == "" or s == "[]": return result
	
	if s.begins_with("[") and s.contains('"'):
		var parsed = JSON.parse_string(s)
		if parsed is Array:
			for item in parsed:
				result.append(str(item).strip_edges())
			return result
			
	s = s.trim_prefix("[").trim_suffix("]")
	for part in s.split(","):
		var cleaned = part.strip_edges().trim_prefix('"').trim_suffix('"').trim_prefix("'").trim_suffix("'")
		if cleaned != "":
			result.append(cleaned)
	return result

func _initialize_schema_if_needed():
	# Tables will only be created if they do not exist, and default data will only be inserted if missing.
	
	# Core Data-Driven Mechanics Tables
	database.query("CREATE TABLE IF NOT EXISTS sizes (
		id TEXT PRIMARY KEY,
		name TEXT,
		effective_size INTEGER,
		base_bulk INTEGER,
		description TEXT
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
		false_data TEXT DEFAULT '{}',
		description TEXT
	);")
	
	database.query("CREATE TABLE IF NOT EXISTS traits (
		id TEXT PRIMARY KEY,
		name TEXT,
		mechanic_hook TEXT,
		hook_value INTEGER,
		description TEXT
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
		script_path TEXT,
		description TEXT
	);")
	
	database.query("CREATE TABLE IF NOT EXISTS beliefs (
		id TEXT PRIMARY KEY,
		name TEXT,
		type TEXT,
		mechanic_hook TEXT,
		description TEXT
	);")
	
	database.query("CREATE TABLE IF NOT EXISTS skills (
		id TEXT PRIMARY KEY,
		name TEXT,
		key_ability TEXT,
		is_lore INTEGER,
		description TEXT
	);")
	
	database.query("CREATE TABLE IF NOT EXISTS languages (
		id TEXT PRIMARY KEY,
		name TEXT,
		rarity INTEGER,
		description TEXT
	);")
	
	database.query("CREATE TABLE IF NOT EXISTS regions (
		id TEXT PRIMARY KEY,
		name TEXT,
		description TEXT
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
		advanced_maneuver TEXT,
		description TEXT
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
		description TEXT,
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
		granted_actions TEXT DEFAULT '',
		description TEXT
	);")
	
	# Equipment
	database.query("CREATE TABLE IF NOT EXISTS equipment (
		id TEXT PRIMARY KEY,
		name TEXT,
		level INTEGER,
		price_cp INTEGER,
		bulk INTEGER,
		usage_cooldown TEXT,
		action_script_path TEXT,
		skill_bonus_data TEXT
	);")
	
	# Consumables
	database.query("CREATE TABLE IF NOT EXISTS consumables (
		id TEXT PRIMARY KEY,
		name TEXT,
		level INTEGER,
		price_cp INTEGER,
		bulk INTEGER,
		consumable_type TEXT,
		charges INTEGER,
		spell_id TEXT
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
		valid_hosts TEXT DEFAULT '',
		description TEXT
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
		valid_hosts TEXT DEFAULT '',
		description TEXT
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
		granted_actions TEXT DEFAULT '',
		description TEXT
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
		granted_actions TEXT DEFAULT '',
		description TEXT
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
		stages TEXT,
		description TEXT
	);")
	
	# Ancestries
	database.query("CREATE TABLE IF NOT EXISTS ancestries (
		id TEXT PRIMARY KEY,
		name TEXT,
		traits TEXT,
		rarity INTEGER DEFAULT 0,
		hp INTEGER DEFAULT 8,
		size TEXT DEFAULT 'medium',
		speed INTEGER DEFAULT 25,
		speed_fly INTEGER DEFAULT 0,
		speed_swim INTEGER DEFAULT 0,
		speed_climb INTEGER DEFAULT 0,
		speed_burrow INTEGER DEFAULT 0,
		boosts TEXT,
		flaws TEXT,
		alternate_boosts TEXT,
		known_languages TEXT,
		vision INTEGER DEFAULT 0,
		additional_senses TEXT,
		ethnicities TEXT,
		heritages TEXT,
		description TEXT,
		physical_description TEXT,
		societal_description TEXT,
		common_beliefs TEXT,
		common_edicts TEXT,
		common_anathema TEXT,
		common_names TEXT,
		granted_abilities TEXT,
		starting_gold INTEGER DEFAULT 15
	);")
	_ensure_ancestries_columns()
	
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
		spell_progression INTEGER,
		description TEXT
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
		special_effects TEXT,
		description TEXT,
		UNIQUE(spell_id, action_cost, target)
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
	
	# Deities
	database.query("CREATE TABLE IF NOT EXISTS deities (
		id TEXT PRIMARY KEY,
		name TEXT,
		title TEXT,
		category TEXT,
		edicts TEXT,
		anathema TEXT,
		religious_symbol TEXT,
		sacred_animal TEXT,
		sacred_colors TEXT,
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
		curse_major TEXT,
		description TEXT
	);")
	
	database.query("SELECT COUNT(*) as count FROM deities;")
	# Force seeding for now while dropping tables
	_seed_data()

func _seed_data():
	print("PFDatabase: Seeding default data...")
	# Afflictions
	database.query("""INSERT OR IGNORE INTO afflictions (id, name, saving_throw_stat, dc, max_stage, onset_interval, stage_interval, stages, description) VALUES 
		('giant_centipede_venom', 'Giant Centipede Venom', 'fortitude', 17, 6, 0, 1, 
		'[
			{"stage": 1, "damage": "1d6", "damage_type": "poison"},
			{"stage": 2, "damage": "1d8", "damage_type": "poison", "conditions": [{"id": "enfeebled", "value": 1}]},
			{"stage": 3, "damage": "1d12", "damage_type": "poison", "conditions": [{"id": "enfeebled", "value": 1}]},
			{"stage": 4, "damage": "2d6", "damage_type": "poison", "conditions": [{"id": "enfeebled", "value": 2}]},
			{"stage": 5, "damage": "2d8", "damage_type": "poison", "conditions": [{"id": "enfeebled", "value": 2}]},
			{"stage": 6, "damage": "3d6", "damage_type": "poison", "conditions": [{"id": "enfeebled", "value": 2}]}
		]', 'A toxic venom from a giant centipede that causes muscle spasms and weakness.');""")
	
	print("PFDatabase: Seeding complete.")
	
	# Seed Sizes
	database.query("INSERT OR IGNORE INTO sizes (id, name, effective_size, base_bulk, description) VALUES 
		('tiny', 'Tiny', 0, 10, 'A creature or object smaller than a typical halfling, usually taking up less than a 5-foot square.'),
		('small', 'Small', 1, 30, 'A creature or object about the size of a halfling or goblin.'),
		('medium', 'Medium', 1, 60, 'A creature or object about the size of a human, elf, or dwarf.'),
		('large', 'Large', 2, 120, 'A creature or object about the size of an ogre or horse, typically taking up a 10-by-10-foot space.'),
		('huge', 'Huge', 3, 240, 'A creature or object about the size of a giant, typically taking up a 15-by-15-foot space.'),
		('gargantuan', 'Gargantuan', 4, 480, 'A massive creature or object, taking up a 20-by-20-foot space or larger.');")
		
	# Seed Traits
	database.query("INSERT OR IGNORE INTO traits (id, name, mechanic_hook, hook_value, description) VALUES 
		('agile', 'Agile', 'modifies_map', 4, 'The multiple attack penalty you take with this weapon on the second attack on your turn is -4 instead of -5, and -8 instead of -10 on the third and subsequent attacks.'),
		('finesse', 'Finesse', 'allows_dex_to_hit', 0, 'You can use your Dexterity modifier instead of your Strength modifier on attack rolls using this melee weapon.'),
		('versatile_p', 'Versatile P', 'adds_damage_type', 0, 'This weapon can be used to deal piercing damage instead of its normal damage type.'),
		('versatile p', 'Versatile P', 'adds_damage_type', 0, 'This weapon can be used to deal piercing damage instead of its normal damage type.'),
		('steel', 'Steel', '', 0, 'This object is made of steel.'),
		('two-hand d12', 'Two-Hand d12', '', 0, 'This weapon can be wielded with two hands. Doing so changes its weapon damage die to the indicated value.'),
		('wood', 'Wood', '', 0, 'This object is made of wood.'),
		('improvised', 'Improvised', '', 0, 'This object was not designed to be a weapon. You take a -2 item penalty to attack rolls with it.'),
		('slashing', 'Slashing', '', 0, 'This attack deals slashing damage.'),
		('bludgeoning', 'Bludgeoning', '', 0, 'This attack deals bludgeoning damage.'),
		('piercing', 'Piercing', '', 0, 'This attack deals piercing damage.'),
		('alchemical', 'Alchemical', '', 0, 'This item was created using alchemy.'),
		('bomb', 'Bomb', '', 0, 'An alchemical bomb that is thrown as a ranged weapon.'),
		('consumable', 'Consumable', '', 0, 'An item that is used up once activated.'),
		('splash', 'Splash', '', 0, 'When you use a thrown weapon with the splash trait, you dont add your Strength modifier to the damage roll. If an attack with a splash weapon fails, succeeds, or critically succeeds, all creatures within 5 feet of the target take the listed splash damage.'),
		('fire', 'Fire', '', 0, 'This effect deals fire damage or is created by fire magic.'),
		('cold', 'Cold', '', 0, 'This effect deals cold damage or is created by cold magic.'),
		('acid', 'Acid', '', 0, 'This effect deals acid damage or is created by acid magic.'),
		('electricity', 'Electricity', '', 0, 'This effect deals electricity damage or is created by electricity magic.'),
		('sonic', 'Sonic', '', 0, 'This effect deals sonic damage or is created by sonic magic.'),
		('poison', 'Poison', '', 0, 'This effect deals poison damage, inflicts a poison affliction, or is created by poison magic.'),
		('thrown', 'Thrown', '', 0, 'You can throw this weapon as a ranged attack.'),
		('returning', 'Returning', '', 0, 'A returning weapon flies back to your hand after a Strike.'),
		('elixir', 'Elixir', '', 0, 'An alchemical liquid you drink.'),
		('mutagen', 'Mutagen', '', 0, 'An elixir that temporarily morphs your body, granting a benefit but inflicting a drawback.'),
		('polymorph', 'Polymorph', '', 0, 'An effect that changes the targets shape.'),
		('healing', 'Healing', '', 0, 'A healing effect restores Hit Points or heals damage.'),
		('unarmed', 'Unarmed', '', 0, 'An attack that uses your body rather than a manufactured weapon.'),
		('reach', 'Reach', '', 0, 'This weapon is long and can be used to attack targets up to 10 feet away instead of only adjacent targets.'),
		('nonlethal', 'Nonlethal', '', 0, 'Attacks with this weapon are nonlethal, and are used to knock creatures unconscious instead of killing them.'),
		('backstabber', 'Backstabber', '', 0, 'When you hit an off-guard creature, this weapon deals 1 precision damage.'),
		('sweep', 'Sweep', '', 0, 'This weapon gets a +1 circumstance bonus to attack rolls if you have already attacked a different target this turn.'),
		('backswing', 'Backswing', '', 0, 'You can use the momentum from a missed attack with this weapon to lead into your next attack.'),
		('forceful', 'Forceful', '', 0, 'This weapon becomes more dangerous as you build momentum. Subsequent attacks deal extra damage.'),
		('cobbled', 'Cobbled', '', 0, 'This weapon is cobbled together from disparate parts.'),
		('concussive', 'Concussive', '', 0, 'These weapons smash as much as puncture.'),
		('injection', 'Injection', '', 0, 'This weapon can be filled with an injury poison.'),
		('repeating', 'Repeating', '', 0, 'This weapon has a magazine or similar mechanism that holds ammunition.'),
		('kickback', 'Kickback', '', 0, 'This weapon is exceptionally powerful and recoils heavily.'),
		('brutal', 'Brutal', '', 0, 'Ranged attacks with a brutal weapon use Strength instead of Dexterity for attack rolls.'),
		('free-hand', 'Free-Hand', '', 0, 'You can use the hand holding this weapon to perform other actions.'),
		('manipulate', 'Manipulate', '', 0, 'You must physically manipulate an item or make gestures to use this action.'),
		('move', 'Move', '', 0, 'An action that involves moving from one space to another.'),
		('attack', 'Attack', '', 0, 'An action that harms your opponent and contributes to your multiple attack penalty.'),
		('concentrate', 'Concentrate', '', 0, 'An action that requires a degree of mental focus.'),
		('auditory', 'Auditory', '', 0, 'An action or effect that relies on sound.'),
		('visual', 'Visual', '', 0, 'An action or effect that relies on sight.'),
		('secret', 'Secret', '', 0, 'The GM rolls the check for this action in secret.');")
		

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
	database.query("INSERT OR IGNORE INTO conditions (id, name, modifier_type, target_stat, multiplier, script_path, description) VALUES 
		('clumsy', 'Clumsy', 'status', 'dex_based', -1, '', 'You take a status penalty equal to the clumsy value on Dexterity-based checks and DCs.'),
		('enfeebled', 'Enfeebled', 'status', 'str_based', -1, '', 'You take a status penalty equal to the enfeebled value on Strength-based checks and DCs.'),
		('frightened', 'Frightened', 'status', 'all_checks_and_dcs', -1, '', 'You take a status penalty equal to this value to all your checks and DCs.'),
		('parry', 'Parry', 'circumstance', 'ac', 1, '', 'You gain a +1 circumstance bonus to AC until the start of your next turn.');")
		
	# Seed Beliefs
	database.query("INSERT OR IGNORE INTO beliefs (id, name, type, mechanic_hook, description) VALUES 
		('bring_civilization', 'Bring civilization to the frontiers', 'edict', 'deity_edict', 'Bring the light of civilization to the untamed wilderness.'),
		('earn_wealth', 'Earn wealth through hard work and trade', 'edict', 'deity_edict', 'Acquire wealth and personal prosperity.'),
		('follow_law', 'Follow the rule of law', 'edict', 'deity_edict', 'Strictly adhere to the laws of the land.'),
		('create_art', 'Create art', 'edict', 'deity_edict', 'Create and preserve beautiful art.'),
		('defend_nature', 'Defend nature', 'edict', 'deity_edict', 'Protect the natural world from destruction.'),
		('protect_innocent', 'Protect the innocent', 'edict', 'deity_edict', 'Shield those who cannot shield themselves.'),
		('seek_knowledge', 'Seek knowledge', 'edict', 'deity_edict', 'Uncover hidden truths and ancient lore.'),
		('destroy_undead', 'Destroy undead', 'edict', 'deity_edict', 'Eradicate the undead wherever they are found.'),
		('edict_healing', 'Heal the sick and wounded', 'edict', 'deity_edict', 'destroy the undead, protect your allies, heal the sick and wounded'),
		('edict_redemption', 'Seek and allow redemption', 'edict', 'deity_edict', 'seek and allow redemption'),
		('edict_study', 'Study the cosmos and ancient magical lore', 'edict', 'deity_edict', 'Study the cosmos and ancient magical lore'),
		('edict_time_acceptance', 'Accept the natural flow of time', 'edict', 'deity_edict', 'Accept the natural flow of time'),
		('edict_pattern_recognition', 'Look for patterns in seemingly random events', 'edict', 'deity_edict', 'Look for patterns in seemingly random events'),
		('edict_protect_weak', 'Protect the weak and defenseless', 'edict', 'deity_edict', 'Protect the weak and defenseless'),
		('edict_confront_horrors', 'Confront the horrors that lurk in the dark', 'edict', 'deity_edict', 'Confront the horrors that lurk in the dark'),
		('edict_greet_dawn', 'Greet the dawn', 'edict', 'deity_edict', 'Greet the dawn'),
		('edict_stand_ground', 'Stand your ground when others flee', 'edict', 'deity_edict', 'Stand your ground when others flee'),
		('edict_allow_rot', 'Allow rot and disease to take their natural course', 'edict', 'deity_edict', 'Allow rot and disease to take their natural course'),
		('edict_spread_sickness', 'Spread sickness to humble the arrogant and powerful', 'edict', 'deity_edict', 'Spread sickness to humble the arrogant and powerful'),
		('edict_embrace_decay', 'Embrace the grim beauty of decay', 'edict', 'deity_edict', 'Embrace the grim beauty of decay'),
		('edict_travel_new_road', 'Travel a road you have never walked', 'edict', 'deity_edict', 'Travel a road you have never walked'),
		('edict_trust_chance', 'Trust your fate to chance', 'edict', 'deity_edict', 'Trust your fate to chance'),
		('edict_share_story', 'Share a drink or a story with a stranger', 'edict', 'deity_edict', 'Share a drink or a story with a stranger'),
		('edict_defy_tyrants', 'Defy tyrants and strict schedules', 'edict', 'deity_edict', 'Defy tyrants and strict schedules'),
		('edict_build_structures', 'Build structures meant to outlast you', 'edict', 'deity_edict', 'Build structures meant to outlast you'),
		('edict_fair_trade', 'Engage in fair and prosperous trade', 'edict', 'deity_edict', 'Engage in fair and prosperous trade'),
		('edict_respect_laws', 'Respect the foundational laws of the land', 'edict', 'deity_edict', 'Respect the foundational laws of the land'),
		('edict_invest_civilization', 'Invest in civilization', 'edict', 'deity_edict', 'Invest in civilization'),
		('edict_crush_opposition', 'Crush those who oppose your rule', 'edict', 'deity_edict', 'Crush those who oppose your rule'),
		('edict_inspire_fear', 'Demonstrate absolute power to inspire fear', 'edict', 'deity_edict', 'Demonstrate absolute power to inspire fear'),
		('edict_strike_without_warning', 'Strike without warning like a sudden storm', 'edict', 'deity_edict', 'Strike without warning like a sudden storm'),
		('edict_comfort_grieving', 'Comfort the grieving', 'edict', 'deity_edict', 'Comfort the grieving'),
		('edict_proper_burial', 'Ensure the dead receive proper burial rites', 'edict', 'deity_edict', 'Ensure the dead receive proper burial rites'),
		('edict_embrace_quiet', 'Embrace the quiet and stillness of the dark', 'edict', 'deity_edict', 'Embrace the quiet and stillness of the dark'),
		('edict_trust_intuition', 'Trust your intuition and visions over cold logic', 'edict', 'deity_edict', 'Trust your intuition and visions over cold logic'),
		('edict_create_subconscious_art', 'Create art inspired by the subconscious', 'edict', 'deity_edict', 'Create art inspired by the subconscious'),
		('edict_sleep_beneath_moonlight', 'Sleep beneath the moonlight', 'edict', 'deity_edict', 'Sleep beneath the moonlight'),
		('edict_hunt_survival', 'Hunt for your own survival', 'edict', 'deity_edict', 'Hunt for your own survival'),
		('edict_embrace_primal', 'Embrace your primal emotions and instincts', 'edict', 'deity_edict', 'Embrace your primal emotions and instincts'),
		('edict_allow_wild_reclaim', 'Allow the wild to reclaim the ruins of civilization', 'edict', 'deity_edict', 'Allow the wild to reclaim the ruins of civilization'),
		('edict_speak_truth', 'Speak only the absolute truth', 'edict', 'deity_edict', 'Speak only the absolute truth'),
		('edict_hone_mind_body', 'Continuously hone your mind and body through strict discipline', 'edict', 'deity_edict', 'Continuously hone your mind and body through strict discipline'),
		('edict_judge_by_actions', 'Judge others solely by their actions', 'edict', 'deity_edict', 'Judge others solely by their actions'),
		('edict_keep_secrets', 'Keep secrets entrusted to you', 'edict', 'deity_edict', 'Keep secrets entrusted to you'),
		('edict_seek_forbidden_lore', 'Seek out forbidden or forgotten lore from the depths', 'edict', 'deity_edict', 'Seek out forbidden or forgotten lore from the depths'),
		('edict_embrace_cold_isolation', 'Embrace the cold and isolation of the deep', 'edict', 'deity_edict', 'Embrace the cold and isolation of the deep'),
		('edict_seize_leadership', 'Seize leadership when others falter', 'edict', 'deity_edict', 'Seize leadership when others falter'),
		('edict_improve_station', 'Constantly seek to improve your station and wealth', 'edict', 'deity_edict', 'Constantly seek to improve your station and wealth'),
		('edict_assert_superiority', 'Assert your superiority through undeniable deeds', 'edict', 'deity_edict', 'Assert your superiority through undeniable deeds'),
		('edict_protect_bloodline', 'Protect your bloodline and chosen family at all costs', 'edict', 'deity_edict', 'Protect your bloodline and chosen family at all costs'),
		('edict_honor_ancestors', 'Honor ancestral spirits', 'edict', 'deity_edict', 'Honor ancestral spirits'),
		('edict_endure_pain', 'Endure physical pain to strengthen your resolve or save a loved one', 'edict', 'deity_edict', 'Endure physical pain to strengthen your resolve or save a loved one'),
		('anathema_undead', 'Create undead', 'anathema', 'deity_anathema', 'create undead'),
		('anathema_lies', 'Lie', 'anathema', 'deity_anathema', 'lie'),
		('anathema_mercy', 'Deny mercy', 'anathema', 'deity_anathema', 'deny a repentant creature an opportunity for redemption'),
		('anathema_fail_strike', 'Fail to strike down evil', 'anathema', 'deity_anathema', 'fail to strike down evil'),
		('anathema_destroy_history', 'Destroy historical or magical records', 'anathema', 'deity_anathema', 'Destroy historical or magical records'),
		('anathema_act_blindly', 'Act blindly without contemplating future consequences', 'anathema', 'deity_anathema', 'Act blindly without contemplating future consequences'),
		('anathema_rewrite_past', 'Attempt to magically rewrite your own past', 'anathema', 'deity_anathema', 'Attempt to magically rewrite your own past'),
		('anathema_flee_battle', 'Flee from battle while allies remain in danger', 'anathema', 'deity_anathema', 'Flee from battle while allies remain in danger'),
		('anathema_allow_monsters', 'Allow monsters of the dark to flourish unchecked', 'anathema', 'deity_anathema', 'Allow monsters of the dark to flourish unchecked'),
		('anathema_extinguish_flame', 'Extinguish a flame meant for warmth or safety', 'anathema', 'deity_anathema', 'Extinguish a flame meant for warmth or safety.'),
		('anathema_cure_without_toll', 'Cure an ailment without extracting a heavy toll', 'anathema', 'deity_anathema', 'Cure an ailment without extracting a heavy toll'),
		('anathema_preserve_corpse', 'Preserve a corpse unnaturally', 'anathema', 'deity_anathema', 'Preserve a corpse unnaturally'),
		('anathema_construct_monuments', 'Construct monuments meant to last forever', 'anathema', 'deity_anathema', 'Construct monuments meant to last forever.'),
		('anathema_own_property', 'Own property that ties you to one location', 'anathema', 'deity_anathema', 'Own property that ties you to one location'),
		('anathema_refuse_gamble', 'Refuse a gamble when the stakes are thrilling', 'anathema', 'deity_anathema', 'Refuse a gamble when the stakes are thrilling'),
		('anathema_enforce_laws', 'Enforce rigid laws upon others', 'anathema', 'deity_anathema', 'Enforce rigid laws upon others.'),
		('anathema_destroy_building', 'Destroy a functional building or bridge', 'anathema', 'deity_anathema', 'Destroy a functional building or bridge'),
		('anathema_break_contract', 'Break a binding contract or oath', 'anathema', 'deity_anathema', 'Break a binding contract or oath'),
		('anathema_hoard_wealth', 'Hoard wealth without investing it back into the community', 'anathema', 'deity_anathema', 'Hoard wealth without investing it back into the community.'),
		('anathema_show_mercy', 'Show mercy to a defeated rival', 'anathema', 'deity_anathema', 'Show mercy to a defeated rival'),
		('anathema_allow_insult', 'Allow a public insult to go unpunished', 'anathema', 'deity_anathema', 'Allow a public insult to go unpunished'),
		('anathema_submit_weaker', 'Submit to a weaker authority', 'anathema', 'deity_anathema', 'Submit to a weaker authority.'),
		('anathema_deny_mourning', 'Deny someone their right to mourn', 'anathema', 'deity_anathema', 'Deny someone their right to mourn'),
		('anathema_force_happiness', 'Force false happiness upon the sorrowful', 'anathema', 'deity_anathema', 'Force false happiness upon the sorrowful'),
		('anathema_desecrate_tomb', 'Desecrate a tomb or grave', 'anathema', 'deity_anathema', 'Desecrate a tomb or grave.'),
		('anathema_rely_empirical', 'Rely entirely on empirical evidence to solve a problem', 'anathema', 'deity_anathema', 'Rely entirely on empirical evidence to solve a problem'),
		('anathema_wake_dreamer', 'Wake someone from a profound or prophetic dream', 'anathema', 'deity_anathema', 'Wake someone from a profound or prophetic dream'),
		('anathema_suppress_hallucination', 'Suppress a hallucination', 'anathema', 'deity_anathema', 'Suppress a hallucination.'),
		('anathema_domesticate_predator', 'Domesticate a wild predator', 'anathema', 'deity_anathema', 'Domesticate a wild predator'),
		('anathema_suppress_instincts', 'Suppress your natural instincts for the sake of being civilized', 'anathema', 'deity_anathema', 'Suppress your natural instincts for the sake of being civilized'),
		('anathema_destroy_nature', 'Destroy nature for pure monetary profit', 'anathema', 'deity_anathema', 'Destroy nature for pure monetary profit.'),
		('anathema_tell_lie', 'Tell a lie', 'anathema', 'deity_anathema', 'Tell a lie (even a white lie to spare someone feelings)'),
		('anathema_cloud_judgment', 'Allow emotion to cloud your judgment', 'anathema', 'deity_anathema', 'Allow emotion to cloud your judgment'),
		('anathema_indulge_excess', 'Indulge in bodily excess or gluttony', 'anathema', 'deity_anathema', 'Indulge in bodily excess or gluttony.'),
		('anathema_reveal_truth', 'Reveal a hidden truth to the unworthy', 'anathema', 'deity_anathema', 'Reveal a hidden truth to the unworthy'),
		('anathema_show_fear', 'Show fear of the dark or deep water', 'anathema', 'deity_anathema', 'Show fear of the dark or deep water'),
		('anathema_share_knowledge', 'Share your knowledge without demanding a steep price', 'anathema', 'deity_anathema', 'Share your knowledge without demanding a steep price.'),
		('anathema_accept_subordinate', 'Accept a subordinate role when you have the power to lead', 'anathema', 'deity_anathema', 'Accept a subordinate role when you have the power to lead'),
		('anathema_show_doubt', 'Show public self-doubt', 'anathema', 'deity_anathema', 'Show public self-doubt'),
		('anathema_allow_outmaneuver', 'Allow a rival to outmaneuver you without retaliation', 'anathema', 'deity_anathema', 'Allow a rival to outmaneuver you without retaliation.'),
		('anathema_betray_family', 'Betray a family member', 'anathema', 'deity_anathema', 'Betray a family member'),
		('anathema_refuse_bloodshed', 'Refuse to shed blood when survival demands it', 'anathema', 'deity_anathema', 'Refuse to shed blood when survival demands it'),
		('anathema_forget_ancestors', 'Allow your ancestral line to be forgotten', 'anathema', 'deity_anathema', 'Allow your ancestral line to be forgotten.'),
		('banditry_piracy', 'Engage in banditry or piracy', 'anathema', 'deity_anathema', 'Plunder and steal from others on the roads or high seas.'),
		('steal', 'Steal', 'anathema', 'deity_anathema', 'Take what belongs to others for yourself.'),
		('undermine_court', 'Undermine a law-abiding court', 'anathema', 'deity_anathema', 'Subvert and disrupt legal proceedings or royalty.'),
		('create_undead', 'Create undead', 'anathema', 'deity_anathema', 'Raise the dead to serve your will.'),
		('despoil_nature', 'Despoil nature', 'anathema', 'deity_anathema', 'Corrupt or destroy the natural world.'),
		('harm_innocent', 'Harm the innocent', 'anathema', 'deity_anathema', 'Inflict pain on those who have done no wrong.'),
		('destroy_knowledge', 'Destroy knowledge', 'anathema', 'deity_anathema', 'Burn books and erase history.'),
		('lie', 'Tell a lie', 'anathema', 'deity_anathema', 'Deceive others for your own gain.'),
		('break_promise', 'Break a promise', 'anathema', 'deity_anathema', 'Go back on your given word.');")
		
	# Seed Skills & Lores
	database.query("INSERT OR IGNORE INTO skills (id, name, key_ability, is_lore, description) VALUES 
		('acrobatics', 'Acrobatics', 'DEX', 0, 'Acrobatics measures your ability to perform tasks requiring coordination and grace.'),
		('arcana', 'Arcana', 'INT', 0, 'Arcana measures how much you know about arcane magic and creatures.'),
		('athletics', 'Athletics', 'STR', 0, 'Athletics allows you to perform deeds of physical prowess.'),
		('crafting', 'Crafting', 'INT', 0, 'You can use this skill to create, understand, and repair items.'),
		('deception', 'Deception', 'CHA', 0, 'You can trick and mislead others using disguises, lies, and other forms of subterfuge.'),
		('diplomacy', 'Diplomacy', 'CHA', 0, 'You influence others through negotiation and flattery.'),
		('intimidation', 'Intimidation', 'CHA', 0, 'You bend others to your will using threats.'),
		('medicine', 'Medicine', 'WIS', 0, 'You can patch up wounds and help people recover from diseases and poisons.'),
		('nature', 'Nature', 'WIS', 0, 'You know a great deal about the natural world.'),
		('occultism', 'Occultism', 'INT', 0, 'You know a great deal about ancient mysteries, obscure philosophy, and the supernatural.'),
		('perception', 'Perception', 'WIS', 0, 'Perception measures your ability to notice things.'),
		('performance', 'Performance', 'CHA', 0, 'You are skilled at a form of performance, using it to impress a crowd.'),
		('religion', 'Religion', 'WIS', 0, 'The secrets of deities, dogma, faith, and the realms of divine creatures are open to you.'),
		('society', 'Society', 'INT', 0, 'You understand the people and systems that make civilization run.'),
		('stealth', 'Stealth', 'DEX', 0, 'You are skilled at avoiding detection.'),
		('survival', 'Survival', 'WIS', 0, 'You are adept at living in the wilderness.'),
		('thievery', 'Thievery', 'DEX', 0, 'You are trained in a particular set of skills highly sought after by thieves and scoundrels.'),
		('academia_lore', 'Academia Lore', 'INT', 1, 'Lore about academia and universities.'),
		('accounting_lore', 'Accounting Lore', 'INT', 1, 'Lore about accounting and finances.'),
		('architecture_lore', 'Architecture Lore', 'INT', 1, 'Lore about buildings and engineering.'),
		('art_lore', 'Art Lore', 'INT', 1, 'Lore about art and artists.'),
		('circus_lore', 'Circus Lore', 'INT', 1, 'Lore about circuses and carnivals.'),
		('engineering_lore', 'Engineering Lore', 'INT', 1, 'Lore about engineering and construction.'),
		('farming_lore', 'Farming Lore', 'INT', 1, 'Lore about agriculture.'),
		('fishing_lore', 'Fishing Lore', 'INT', 1, 'Lore about fishing and the sea.'),
		('fortune_telling_lore', 'Fortune-Telling Lore', 'INT', 1, 'Lore about predicting the future.'),
		('games_lore', 'Games Lore', 'INT', 1, 'Lore about games and gambling.'),
		('genealogy_lore', 'Genealogy Lore', 'INT', 1, 'Lore about bloodlines and families.'),
		('gladiatorial_lore', 'Gladiatorial Lore', 'INT', 1, 'Lore about gladiators and arenas.'),
		('guild_lore', 'Guild Lore', 'INT', 1, 'Lore about trade guilds.'),
		('heraldry_lore', 'Heraldry Lore', 'INT', 1, 'Lore about noble houses and their symbols.'),
		('herbalism_lore', 'Herbalism Lore', 'INT', 1, 'Lore about plants and natural remedies.'),
		('hunting_lore', 'Hunting Lore', 'INT', 1, 'Lore about hunting game.'),
		('labor_lore', 'Labor Lore', 'INT', 1, 'Lore about manual labor.'),
		('legal_lore', 'Legal Lore', 'INT', 1, 'Lore about laws and courts.'),
		('library_lore', 'Library Lore', 'INT', 1, 'Lore about libraries and archives.'),
		('mercantile_lore', 'Mercantile Lore', 'INT', 1, 'Lore about trade and commerce.'),
		('midwifery_lore', 'Midwifery Lore', 'INT', 1, 'Lore about childbirth.'),
		('milling_lore', 'Milling Lore', 'INT', 1, 'Lore about grain and mills.'),
		('mining_lore', 'Mining Lore', 'INT', 1, 'Lore about mining and the earth.'),
		('piloting_lore', 'Piloting Lore', 'INT', 1, 'Lore about flying or steering ships.'),
		('sailing_lore', 'Sailing Lore', 'INT', 1, 'Lore about sailing ships.'),
		('scouting_lore', 'Scouting Lore', 'INT', 1, 'Lore about reconnaissance.'),
		('scribing_lore', 'Scribing Lore', 'INT', 1, 'Lore about writing and copying.'),
		('stabling_lore', 'Stabling Lore', 'INT', 1, 'Lore about horses and stables.'),
		('tanning_lore', 'Tanning Lore', 'INT', 1, 'Lore about leatherworking.'),
		('theater_lore', 'Theater Lore', 'INT', 1, 'Lore about plays and acting.'),
		('underworld_lore', 'Underworld Lore', 'INT', 1, 'Lore about the criminal underworld.');")
		

	# Seed Conditions
	database.query("INSERT OR IGNORE INTO conditions (id, name, modifier_type, target_stat, multiplier, script_path, description) VALUES 
		('blinded', 'Blinded', '', '', 0, '', 'You cant see. All normal terrain is difficult terrain to you. You cant detect anything using vision.'),
		('broken', 'Broken', 'status', 'ac', -2, '', 'A broken object cant be used for its normal function, nor does it grant bonuses.'),
		('clumsy', 'Clumsy', 'status', 'dex_based', -1, '', 'You take a status penalty equal to the clumsy value on Dexterity-based checks and DCs.'),
		('concealed', 'Concealed', '', '', 0, '', 'While you are concealed from a creature, such as in thick fog, you are difficult for that creature to see.'),
		('confused', 'Confused', '', '', 0, '', 'You dont have your wits about you, and you attack randomly.'),
		('controlled', 'Controlled', '', '', 0, '', 'Someone else is dictating your actions.'),
		('cover', 'Cover', 'circumstance', 'ac', 2, '', 'You are behind an obstacle that provides a bonus to AC.'),
		('dazzled', 'Dazzled', '', '', 0, '', 'Your eyes are overstimulated. All creatures and objects are concealed from you.'),
		('dead', 'Dead', '', '', 0, '', 'You are dead.'),
		('deafened', 'Deafened', 'status', 'perception_hearing', -2, '', 'You cant hear.'),
		('doomed', 'Doomed', '', '', 0, 'res://scripts/conditions/pf_condition_doomed.gd', 'Your life is slipping away. The maximum dying value at which you die is reduced by your doomed value.'),
		('drained', 'Drained', 'status', 'con_based', -1, '', 'You are depleted of vitality. You take a status penalty to Constitution-based checks and reduce your max HP.'),
		('dying', 'Dying', '', '', 0, 'res://scripts/conditions/pf_condition_dying.gd', 'You are bleeding out or otherwise at deaths door.'),
		('encumbered', 'Encumbered', 'status', 'speed', -10, 'res://scripts/conditions/pf_condition_encumbered.gd', 'You are carrying more weight than you can manage.'),
		('enfeebled', 'Enfeebled', 'status', 'str_based', -1, '', 'You take a status penalty equal to the enfeebled value on Strength-based checks and DCs.'),
		('fascinated', 'Fascinated', 'status', 'perception_and_skill', -2, '', 'You are compelled to focus your attention on something, taking a penalty to Perception and skill checks.'),
		('fatigued', 'Fatigued', 'status', 'ac_and_saves', -1, '', 'You are tired and cant sustain a shield or take the exploration activities you normally could.'),
		('fleeing', 'Fleeing', '', '', 0, '', 'You are forced to run away due to fear or some other compulsion.'),
		('frightened', 'Frightened', 'status', 'all_checks_and_dcs', -1, 'res://scripts/conditions/pf_condition_frightened.gd', 'You take a status penalty equal to this value to all your checks and DCs.'),
		('grabbed', 'Grabbed', '', '', 0, 'res://scripts/conditions/pf_condition_grabbed.gd', 'You are held in place by another creature.'),
		('hidden', 'Hidden', '', '', 0, '', 'While you are hidden from a creature, that creature knows the space you are in but cant see you.'),
		('immobilized', 'Immobilized', '', '', 0, '', 'You cant use any action with the move trait.'),
		('invisible', 'Invisible', '', '', 0, '', 'You cant be seen.'),
		('observed', 'Observed', '', '', 0, '', 'A creature can see you clearly.'),
		('off_guard', 'Off-Guard', 'circumstance', 'ac', -2, '', 'You are distracted or otherwise unable to protect yourself. You take a -2 circumstance penalty to AC.'),
		('paralyzed', 'Paralyzed', '', '', 0, '', 'Your body is frozen in place.'),
		('persistent_damage', 'Persistent Damage', '', '', 0, 'res://scripts/conditions/pf_condition_persistent.gd', 'You take damage at the end of your turns until the condition ends.'),
		('parry', 'Parry', 'circumstance', 'ac', 1, '', 'You gain a +1 circumstance bonus to AC until the start of your next turn.'),
		('raised_shield', 'Raised Shield', 'circumstance', 'ac', 0, '', 'Your shield is raised, granting you its bonus to AC.'),
		('petrified', 'Petrified', '', '', 0, '', 'You have been turned to stone.'),
		('prone', 'Prone', 'circumstance', 'attack', -2, 'res://scripts/conditions/pf_condition_prone.gd', 'You are lying on the ground.'),
		('quickened', 'Quickened', '', '', 0, 'res://scripts/conditions/pf_condition_quickened.gd', 'You gain 1 additional action at the start of your turn.'),
		('restrained', 'Restrained', '', '', 0, 'res://scripts/conditions/pf_condition_grabbed.gd', 'You are tied up or otherwise securely held.'),
		('sickened', 'Sickened', 'status', 'all_checks_and_dcs', -1, '', 'You feel ill. You take a status penalty equal to this value on all checks and DCs.'),
		('slowed', 'Slowed', '', '', 0, 'res://scripts/conditions/pf_condition_slowed.gd', 'You have fewer actions. You lose actions equal to your slowed value.'),
		('stunned', 'Stunned', '', '', 0, 'res://scripts/conditions/pf_condition_stunned.gd', 'You cant act. You lose actions equal to your stunned value.'),
		('stupefied', 'Stupefied', 'status', 'mental_based', -1, '', 'Your mind is clouded. You take a status penalty equal to this value on INT, WIS, and CHA checks.'),
		('unconscious', 'Unconscious', 'status', 'ac_and_saves', -4, 'res://scripts/conditions/pf_condition_unconscious.gd', 'You are asleep or have been knocked out.'),
		('undetected', 'Undetected', '', '', 0, '', 'When you are undetected by a creature, it doesnt know what space you occupy.'),
		('unnoticed', 'Unnoticed', '', '', 0, '', 'A creature has no idea you are even present.'),
		('wounded', 'Wounded', '', '', 0, 'res://scripts/conditions/pf_condition_wounded.gd', 'You have been seriously injured. If you lose all HP and are dying, your dying value increases by your wounded value.');")
		
	database.query("UPDATE conditions SET script_path = 'res://scripts/conditions/pf_condition_encumbered.gd' WHERE id = 'encumbered';")
		
	# Seed Languages
	# Rarity: 0=Common, 1=Uncommon, 2=Rare
	database.query("INSERT OR IGNORE INTO languages (id, name, rarity, description) VALUES 
		('common', 'Common', 0, 'The most widely spoken language in the Inner Sea region.'),
		('dwarven', 'Dwarven', 0, 'The language of dwarves, written in dwarven runes.'),
		('elven', 'Elven', 0, 'The flowing language of elves.'),
		('gnomish', 'Gnomish', 0, 'The excitable language of gnomes.'),
		('goblin', 'Goblin', 0, 'The yapping language of goblins.'),
		('halfling', 'Halfling', 0, 'The language of halflings.'),
		('orcish', 'Orcish', 0, 'The harsh language of orcs.'),
		('sylvan', 'Sylvan', 1, 'The language of fey creatures.'),
		('undercommon', 'Undercommon', 1, 'The trade language of the Darklands.'),
		('draconic', 'Draconic', 1, 'The ancient language of dragons.'),
		('celestial', 'Celestial', 1, 'The language of angels and good outsiders.'),
		('abyssal', 'Abyssal', 1, 'The language of demons.'),
		('infernal', 'Infernal', 1, 'The language of devils.'),
		('druidic', 'Druidic', 2, 'The secret language of druids.');")
		
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

	# Seed Regions
	database.query("INSERT OR IGNORE INTO regions (id, name, description) VALUES 
		('unknown', 'Unknown', 'An unknown region.'),
		('cordoval', 'Grand Duchy of Cordoval', 'A proud Mediterranean civilization of grand aqueducts, sunlit cathedrals, and terraced vineyards.'),
		('torvalla', 'Frost-Marked Concordat of Torvalla', 'A resilient alpine confederation of fjord settlements, runic blacksmiths, and disciplined shield-walls.'),
		('calatara', 'Sun-Gilded League of Calatara', 'A vibrant cosmopolitan coalition of tropical archipelago ports, floating markets, and merchant fleets.'),
		('shahrazar', 'Grand Sultanate of Shahrazar', 'An ancient desert empire of glass domes, oasis bazaars, and alchemical observatories.'),
		('qing_ling', 'Jade Hegemony of Qing-Ling', 'An isolated mountain realm immersed in martial asceticism, celestial divination, and jade artistry.'),
		('caerwen', 'Freeholds of Caerwen', 'Sprawling primeval woodlands governed by agrarian communes and ancient druidic circles.'),
		('mal_kharum', 'Ashen Cradle of Mal-Kharum', 'Scorched volcanic badlands and fractured leylines where hardy prospectors and nomads survive.');")
		
	# Seed Heritages
	# vision_override: -1 (no change), 0 (Normal), 1 (Low-Light), 2 (Darkvision)
	database.query("INSERT OR IGNORE INTO heritages (id, name, traits, rarity, ancestry_id, is_versatile, hp_bonus, size_id, speed_bonus, vision_override, granted_traits, granted_items, granted_abilities, description) VALUES 
		('forge_dwarf', 'Forge Dwarf', '[]', 0, 'dwarf', 0, 0, '', 0, -1, '[\"fire_resistance\"]', '[]', '[]', ''),
		('nephilim', 'Nephilim', '[\"nephilim\", \"planar\"]', 0, '', 1, 0, '', 0, 1, '[\"nephilim\"]', '[]', '[\"nephilim_feat_access\"]', 'Infused with planar cosmic, fiendish, or celestial essence, you gain low-light vision and access to nephilim lineage feats.'),
		('half_elf', 'Half-Elf', '[\"aiuvarin\", \"elf\", \"humanoid\"]', 0, '', 1, 0, '', 0, 1, '[\"elf\"]', '[]', '[\"elf_feat_access\"]', 'Expressing mixed elven heritage alongside any mortal ancestry, you gain pointed ears, low-light vision, the elf trait, and access to elf feats.'),
		('half_orc', 'Half-Orc', '[\"dromaar\", \"orc\", \"humanoid\"]', 0, '', 1, 0, '', 0, 1, '[\"orc\"]', '[]', '[\"orc_feat_access\"]', 'Expressing mixed orcish heritage alongside any mortal ancestry, you gain lower tusks, low-light vision, the orc trait, and access to orc feats.');")
		
	database.query("INSERT OR IGNORE INTO ethnicities (id, name, required_traits, description) VALUES 
		('cordovalen', 'Cordovalen', '[\"human\", \"halfling\", \"catfolk\", \"dogfolk\"]', 'Descendants of the Sovereign Grand Duchy of Cordoval, accustomed to terraced vineyards, grand aqueducts, and strict civic order.'),
		('torvallan', 'Torvallan', '[\"human\", \"dwarf\", \"orc\", \"titanborn\", \"bullfolk\"]', 'Hardy folk of the Frost-Marked Concordat of Torvalla, forged by harsh glacial winters, disciplined shield-walls, and runic crafts.'),
		('calataran', 'Calataran', '[\"human\", \"halfling\", \"catfolk\", \"birdfolk\", \"monkeyfolk\", \"kobold\", \"lizardfolk\"]', 'Cosmopolitan mariners, merchant sailors, and archipelago navigators of the Sun-Gilded League of Calatara.'),
		('shahrazari', 'Shahrazari', '[\"human\", \"gnome\", \"foxfolk\", \"snakefolk\", \"hyenafolk\"]', 'Desert scholars, glass artisans, and alchemical masters tracing lineage to the Grand Sultanate of Shahrazar and its oasis bazaars.'),
		('qing_ling', 'Qing-Ling', '[\"human\", \"elf\", \"monkeyfolk\", \"foxfolk\", \"snakefolk\"]', 'Inhabitants of the isolated Jade Hegemony beyond the Serpent''s Maw, immersed in celestial astrology, martial asceticism, and jade craft.'),
		('caerweni', 'Caerweni', '[\"human\", \"elf\", \"halfling\", \"leshy\", \"horsefolk\", \"dogfolk\", \"frogfolk\"]', 'Woodland agrarian folk of the Freeholds of Caerwen, living in harmony with primeval rainforests and ancient druidic groves.'),
		('mal_kharumi', 'Mal-Kharumi', '[\"human\", \"orc\", \"goblin\", \"hobgoblin\", \"titanborn\", \"shadowman\"]', 'Frontier survivors and prospectors dwelling in the scorched volcanic badlands and ancient monoliths of the Ashen Cradle.'),
		('ashen_nomad', 'Ashen Nomad', '[\"human\", \"orc\", \"shadowman\", \"hyenafolk\"]', 'Wandering wasteland tribes traversing the dust basins where ancient leylines shattered during the Resource Wars.'),
		('fey_tethered', 'Fey-Tethered', '[\"gnome\", \"sprite\", \"kobold\", \"leshy\"]', 'Lineages retaining intense attunement to First World planar conduits and dream-resonating leylines.'),
		('deep_delver', 'Deep Delver', '[\"dwarf\", \"goblin\", \"kobold\", \"ratfolk\"]', 'Subterranean clan-dwellers who have inhabited deep crystalline mines and volcanic caverns for generations.');")
		
	database.query("INSERT OR IGNORE INTO backgrounds (id, name, boosts, flaws, traits, granted_items, granted_abilities, description) VALUES 
		('acolyte', 'Acolyte', '[\"WIS\", \"FREE\"]', '[]', '[]', '[]', '[]', 'You spent your early days in a religious monastery.');")
		
	# Seed Animal Companions
	# Unarmed attacks stored as JSON: [{"name": "Jaws", "damage_dice": 1, "damage_faces": 8, "damage_type": 3, "traits": ["unarmed"]}]
	database.query("INSERT OR IGNORE INTO animal_companions (id, name, size_id, ancestry_hp, speed_land, str_mod, dex_mod, con_mod, int_mod, wis_mod, cha_mod, signature_skill, skills, senses, unarmed_attacks, support_benefit, advanced_maneuver, description) VALUES 
		('bear', 'Bear', 'small', 8, 25, 3, 2, 2, -4, 1, 0, 'athletics', '[\"intimidation\"]', '[1, 2]', '[{\"name\": \"Jaws\", \"damage_dice\": 1, \"damage_faces\": 8, \"damage_type\": 3, \"traits\": [\"unarmed\"]}, {\"name\": \"Claw\", \"damage_dice\": 1, \"damage_faces\": 6, \"damage_type\": 3, \"traits\": [\"agile\", \"unarmed\"]}]', 'Your bear mauls your enemies when you threaten them.', 'Bear Hug', 'A powerful bear that can maul its foes.'),
		('wolf', 'Wolf', 'small', 6, 40, 2, 3, 1, -4, 1, 0, 'survival', '[\"stealth\"]', '[1, 2]', '[{\"name\": \"Jaws\", \"damage_dice\": 1, \"damage_faces\": 8, \"damage_type\": 3, \"traits\": [\"unarmed\"]}]', 'Your wolf tears at your enemies legs.', 'Knockdown', 'A swift wolf that can knock enemies prone.');")
		
	database.query("INSERT OR IGNORE INTO specific_familiars (id, name, required_abilities, granted_abilities, unique_abilities, traits, description) VALUES 
		('faerie_dragon', 'Faerie Dragon', 3, '[\"amphibious\", \"flier\", \"manual_dexterity\", \"speech\", \"telepathy\", \"touch_telepathy\"]', '[\"breath_weapon\"]', '[\"dragon\"]', 'A tiny, colorful dragon that loves pranks.'),
		('imp', 'Imp', 6, '[\"flier\", \"manual_dexterity\", \"speech\", \"touch_telepathy\"]', '[\"invisibility\", \"infernal_temptation\"]', '[\"devil\", \"fiend\"]', 'A small, deceptive fiend often acting as a familiar to malicious masters.');")
		

		
		
	database.query("INSERT OR IGNORE INTO feats (id, name, feat_type, level, traits, prerequisites, granted_rules, description) VALUES 
		('natural_ambition', 'Natural Ambition', 0, 1, '[\"human\"]', '{\"ancestry\": \"human\"}', '{}', 'You gain an extra 1st-level class feat.'),
		('ashen_shadowcaster', 'Ashen Shadowcaster', 0, 1, '[\"human\"]', '{\"ethnicity\": \"ashen_nomad\"}', '{}', 'You harness the planar shadow residue of the shattered leylines.'),
		('acrobat_dedication', 'Acrobat Dedication', 4, 2, '[\"dedication\", \"archetype\", \"acrobat\"]', '{\"min_stats\": {\"dex\": 2}, \"min_proficiency\": {\"acrobatics\": 1}}', '{\"set_proficiency\": {\"acrobatics\": 2}}', 'You become an acrobat.'),
		('dodge_away', 'Dodge Away', 4, 4, '[\"archetype\", \"acrobat\"]', '{\"requires_feat\": \"acrobat_dedication\"}', '{}', 'You dodge incoming attacks.'),
		('acrobat_grace', 'Acrobat Grace', 4, 4, '[\"archetype\", \"acrobat\"]', '{\"requires_feat\": \"acrobat_dedication\"}', '{}', 'You move with extreme grace.'),
		('assassin_dedication', 'Assassin Dedication', 4, 2, '[\"dedication\", \"archetype\", \"assassin\"]', '{}', '{}', 'You become an assassin.'),
		('titan_wrestler', 'Titan Wrestler', 2, 1, '[\"general\", \"skill\"]', '{\"min_proficiency\": {\"athletics\": 1}}', '{}', 'You can grapple larger foes.'),
		('elf_weapon_familiarity', 'Elven Weapon Familiarity', 0, 1, '[\"elf\"]', '{}', '{\"granted_familiarity\": [\"longbow\", \"composite longbow\", \"shortbow\", \"composite shortbow\", \"longsword\", \"rapier\"]}', 'You are trained with elven weapons.');")
		
	database.query("INSERT OR IGNORE INTO class_features (id, name, granted_rules, description) VALUES 
		('wizard_spellcasting', 'Arcane Spellcasting', '{}', 'You cast wizard spells.'),
		('arcane_thesis', 'Arcane Thesis', '{}', 'Your custom arcane research.');")
		
	database.query("INSERT OR IGNORE INTO class_progressions (class_id, level, granted_features, granted_feat_slots, description) VALUES 
		('wizard', 1, '[\"wizard_spellcasting\", \"arcane_thesis\"]', '[\"ancestry\"]', 'Scholars of the arcane arts, wizards study ancient tomes to master powerful spells.'),
		('wizard', 2, '[]', '[\"class\", \"skill\"]', 'Scholars of the arcane arts, wizards study ancient tomes to master powerful spells.');")
	
	database.query("INSERT OR IGNORE INTO weapons (id, name, traits, level, price_cp, material, hardness, max_hp, broken_threshold, grade, bulk, weapon_type, category, group_type, damage_dice, damage_faces, damage_type, range_increment, volley_range, reload_value, hands_required, ammunition_type, description) VALUES 
		('longsword', 'Longsword', 'versatile_p', 1, 100, 3, 5, 20, 10, 1, 1, 0, 1, 4, 1, 8, 3, 0, 0, 0, 1, 0, 'A classic straight-bladed sword favored by knights.'),
		('bayonet_weapon', 'Bayonet Attack', 'agile,finesse', 1, 0, 3, 5, 20, 10, 1, 0, 0, 1, 6, 1, 4, 3, 0, 0, 0, 1, 0, 'A sharp blade attached to a ranged weapon for close combat.'),
		('reinforced_stock_weapon', 'Reinforced Stock Attack', 'finesse,two_hand_d6', 1, 0, 2, 5, 20, 10, 1, 0, 0, 1, 5, 1, 4, 1, 0, 0, 0, 1, 0, 'A heavy stock designed to be used as a club in a pinch.'),
		('shield_boss_weapon', 'Shield Boss Attack', '', 1, 0, 3, 5, 20, 10, 1, 0, 0, 1, 5, 1, 6, 1, 0, 0, 0, 1, 0, 'A heavy metal boss attached to the center of a shield for bashing.'),
		('shield_spikes_weapon', 'Shield Spikes Attack', '', 1, 0, 3, 5, 20, 10, 1, 0, 0, 1, 10, 1, 6, 3, 0, 0, 0, 1, 0, 'Wicked spikes attached to a shield to puncture foes.');")
		
	database.query("INSERT OR IGNORE INTO attachments (id, name, traits, level, price_cp, granted_weapon_id, granted_traits, valid_hosts, description) VALUES 
		('bayonet', 'Bayonet', 'attachment', 1, 230, 'bayonet_weapon', '', 'crossbow,firearm', 'A blade attached to the barrel of a firearm or crossbow.'),
		('reinforced_stock', 'Reinforced Stock', 'attachment', 1, 200, 'reinforced_stock_weapon', '', 'crossbow,firearm', 'A strengthened stock for bludgeoning in melee.'),
		('shield_boss', 'Shield Boss', 'attachment', 1, 20, 'shield_boss_weapon', '', 'shield', 'A rounded metal cap in the center of a shield.'),
		('shield_spikes', 'Shield Spikes', 'attachment', 1, 50, 'shield_spikes_weapon', '', 'shield', 'Sharp spikes covering the face of a shield.'),
		('scope', 'Scope', 'attachment', 1, 500, '', 'deadly_d6', 'crossbow,firearm', 'A telescopic sight for a ranged weapon.');")
		
	database.query("INSERT OR IGNORE INTO adjustments (id, name, traits, level, price_cp, granted_weapon_id, granted_traits, valid_hosts, description) VALUES 
		('shield_augmentation', 'Shield Augmentation', 'adjustment', 1, 0, '', '', 'shield', 'Additional plating for a shield.'),
		('throwing_shield', 'Throwing Shield', 'adjustment', 1, 50, '', 'thrown_20', 'shield', 'A shield designed to be thrown like a chakram.'),
		('counterweight', 'Counterweight', 'adjustment', 1, 20, '', 'agile', 'weapon', 'A weight added to a weapon to improve its balance.'),
		('silencer', 'Silencer', 'adjustment', 1, 100, '', 'covert', 'firearm', 'A device to muffle the sound of a firearm.'),
		('armored_skirt', 'Armored Skirt', 'adjustment', 1, 200, '', '', 'armor', 'Chain or plates attached to the bottom of armor to protect the legs.');")
		
	database.query("INSERT OR IGNORE INTO shields (id, name, traits, level, price_cp, bulk, ac_bonus, speed_penalty, hardness, max_hp, broken_threshold, description) VALUES 
		('buckler', 'Buckler', 'buckler', 1, 10, 1, 1, 0, 3, 12, 6, 'A small shield strapped to the forearm.'),
		('steel_shield', 'Steel Shield', '', 1, 200, 1, 2, 0, 5, 20, 10, 'A sturdy shield made of wood and steel.');")
		
	# Seed Character Creation Data
	database.query("INSERT OR IGNORE INTO ancestries (id, name, traits, rarity, hp, size, speed, speed_fly, speed_swim, speed_climb, speed_burrow, boosts, flaws, alternate_boosts, known_languages, vision, additional_senses, ethnicities, heritages, description, physical_description, societal_description, common_beliefs, common_edicts, common_anathema, common_names, granted_abilities, starting_gold) VALUES 
		('human', 'Human', 'human,humanoid', 0, 8, 'medium', 25, 0, 0, 0, 0, '[\"FREE\", \"FREE\"]', '[]', '[\"FREE\", \"FREE\"]', '[\"common\"]', 0, '[]', '[\"Keleshite\", \"Kellid\", \"Mwangi\", \"Taldan\", \"Tian\", \"Ulfen\", \"Varisian\"]', '[\"Skilled Human\", \"Versatile Human\"]', 'Adaptable and ambitious, humans are defined by their diversity and flexibility across the mortal realm.', 'Human physical features vary wildly.', 'Human societies range from tiny villages to vast empires.', 'Humans worship a wide array of deities.', '[]', '[]', '[\"Alexander\", \"Beatrice\", \"Charles\", \"Diana\"]', '[]', 15);")
		
	database.query("INSERT OR IGNORE INTO backgrounds (id, name, traits, boosts, skills, lores, description) VALUES 
		('farmhand', 'Farmhand', '', '[\"CON|WIS\", \"FREE\"]', 'athletics', 'Farming Lore', 'You grew up working on a farm.');")
		
	# Fighter: 10 HP, STR or DEX key, Expert Perc/Fort/Ref, Trained Will, 3 skills
	# Trained Class DC (2). Expert unarmed/simple/martial, trained advanced. Trained all armor.
	database.query("INSERT OR IGNORE INTO classes (id, name, traits, hp_per_level, key_abilities, perception_rank, class_dc_rank, save_fort, save_ref, save_will, trained_skills_count, weapon_unarmed, weapon_simple, weapon_martial, weapon_advanced, armor_unarmored, armor_light, armor_medium, armor_heavy, forced_edicts, forced_anathema, is_spellcaster, caster_type, spell_tradition, spell_proficiency, spell_progression, description) VALUES 
		('fighter', 'Fighter', '', 10, '[\"STR|DEX\"]', 4, 2, 4, 4, 2, 3, 4, 4, 4, 2, 2, 2, 2, 2, '[]', '[]', 0, 0, 0, 0, 0, 'Masters of martial combat, fighters use their superior training to defeat their foes.');")
		
	database.query("INSERT OR IGNORE INTO classes (id, name, traits, hp_per_level, key_abilities, perception_rank, class_dc_rank, save_fort, save_ref, save_will, trained_skills_count, weapon_unarmed, weapon_simple, weapon_martial, weapon_advanced, armor_unarmored, armor_light, armor_medium, armor_heavy, forced_edicts, forced_anathema, is_spellcaster, caster_type, spell_tradition, spell_proficiency, spell_progression, description) VALUES 
		('wizard', 'Wizard', '', 6, '[\"INT\"]', 2, 2, 2, 2, 4, 2, 2, 2, 0, 0, 2, 0, 0, 0, '[]', '[]', 1, 1, 1, 2, 1, 'Scholars of the arcane arts, wizards study ancient tomes to master powerful spells.');")
		
	# Spells
	var tr_arc_occ = JSON.stringify([PFMagicConstants.MagicTradition.ARCANE, PFMagicConstants.MagicTradition.OCCULT])
	var tr_arc_pri = JSON.stringify([PFMagicConstants.MagicTradition.ARCANE, PFMagicConstants.MagicTradition.PRIMAL])
	
	database.query("INSERT OR IGNORE INTO spell_variants (spell_id, action_cost, spell_range, target, duration, damage_dice, damage_faces, applied_conditions, special_effects, description) VALUES 
		('ignition', 4, 30, '1 creature', '', 2, 4, '[]', '', 'Snap your fingers and conjure a gout of flame.');")
		
	database.query("INSERT OR IGNORE INTO spells (id, name, traits, base_spell_rank, spell_category, traditions, saving_throw, is_attack, damage_type, scaling_rules, scaling_dice, description, script_path) VALUES 
		('illusory_object', 'Illusory Object', 'illusion,visual', 1, 0, '" + tr_arc_occ + "', '', 0, '', 0, 0, 'You create an illusion of an object.', '');")
	
	database.query("INSERT OR IGNORE INTO spells (id, name, traits, base_spell_rank, spell_category, traditions, saving_throw, is_attack, damage_type, scaling_rules, scaling_dice, description, script_path) VALUES 
		('ignition', 'Ignition', 'cantrip,fire', 1, 0, '" + tr_arc_pri + "', '', 1, 'fire', 1, 1, 'You snap your fingers and point, launching a spark that ignites your target.', 'res://scripts/magic/spells/pf_spell_ignition.gd');")
	
	database.query("INSERT OR IGNORE INTO spell_variants (spell_id, action_cost, spell_range, target, duration, damage_dice, damage_faces, applied_conditions, special_effects, description) VALUES 
		('illusory_object', 4, 500, '', '', 0, 0, '[]', '', 'Create a visual illusion of an object.');")
		
	database.query("INSERT OR IGNORE INTO spells (id, name, traits, base_spell_rank, spell_category, traditions, saving_throw, is_attack, damage_type, scaling_rules, scaling_dice, description, script_path) VALUES 
		('creation', 'Creation', 'manipulate', 4, 0, '" + tr_arc_pri + "', '', 0, '', 0, 0, 'You create a temporary object.', '');")
		
	database.query("INSERT OR IGNORE INTO spells (id, name, traits, base_spell_rank, spell_category, traditions, saving_throw, is_attack, damage_type, scaling_rules, scaling_dice, description, script_path) VALUES 
		('fireball', 'Fireball', 'fire,concentrate,manipulate', 3, 0, '" + tr_arc_pri + "', 'Reflex', 0, 'fire', 1, 2, 'A roaring blast of fire appears at a spot you designate, dealing 6d6 fire damage.', '');")
		
	database.query("INSERT OR IGNORE INTO spell_variants (spell_id, action_cost, spell_range, target, duration, damage_dice, damage_faces, applied_conditions, special_effects, description) VALUES 
		('fireball', 2, 500, '20-foot burst', '', 6, 6, '[]', '', 'A roaring explosion of fire.');")
	
	database.query("INSERT OR IGNORE INTO spell_variants (spell_id, action_cost, spell_range, target, duration, damage_dice, damage_faces, applied_conditions, special_effects, description) VALUES 
		('creation', 4, 0, '', '1 hour', 0, 0, '[]', '', 'Form a temporary object out of magical energy.');")
		
	# Deity: The Thirteen
	database.query("INSERT OR IGNORE INTO deities (id, name, title, category, edicts, anathema, religious_symbol, sacred_animal, sacred_colors, divine_attributes, divine_font, divine_sanctification, divine_skill, favored_weapon, domains, alternate_domains, cleric_spells, boon_minor, boon_moderate, boon_major, curse_minor, curse_moderate, curse_major, description) VALUES 
		('aethelis', 'Aethelis', 'The Cosmic Weaver', 'The Thirteen', '[\"edict_study\", \"edict_time_acceptance\", \"edict_pattern_recognition\"]', '[\"anathema_destroy_history\", \"anathema_act_blindly\", \"anathema_rewrite_past\"]', 'Hourglass', 'Owl', '[\"Grey\", \"Blue\"]', '[\"INT\", \"WIS\"]', '[\"harm\", \"heal\"]', 0, 'arcana', 'staff', '[\"fate\", \"magic\", \"star\", \"time\"]', '[\"knowledge\", \"void\"]', '{\"1\": \"sure strike\", \"2\": \"augury\", \"3\": \"haste\"}', 'Once per day, you can roll twice on a check and take the higher result.', 'You can cast haste once per day as a divine innate spell.', 'You can cast time stop once per day as a divine innate spell.', 'Time slows around you. You take a -2 penalty to initiative rolls.', 'You are slowed 1 during the first round of any combat.', 'You age rapidly, taking a permanent -2 penalty to physical attributes.', 'A distant, calculating observer of the tapestry of reality, Aethelis is not prayed to for mercy, but for understanding.'),
		('kaldian', 'Kaldian', 'The Sunlit Warden', 'The Thirteen', '[\"edict_protect_weak\", \"edict_confront_horrors\", \"edict_greet_dawn\", \"edict_stand_ground\"]', '[\"anathema_flee_battle\", \"anathema_allow_monsters\", \"anathema_extinguish_flame\"]', 'Rising Sun', 'Dog', '[\"Red\", \"Gold\"]', '[\"STR\", \"CON\"]', '[\"heal\"]', 4, 'survival', 'bastard sword', '[\"duty\", \"fire\", \"protection\", \"sun\"]', '[\"healing\", \"might\"]', '{\"1\": \"breathe fire\", \"2\": \"floating flame\", \"3\": \"fireball\"}', 'Your weapons shed bright light in a 20-foot radius.', 'You gain fire resistance 5.', 'You can cast sunburst once per day as a divine innate spell.', 'You are blinded by the light for 1 minute when you wake up.', 'You take double damage from cold and darkness effects.', 'You spontaneously combust, taking 10d6 fire damage every day at dawn.', 'A militant guardian deity of the dawn, Kaldian bears the cosmic burns of battling ancient, primordial horrors to keep the mortal realm safe.'),
		('cankros', 'Cankros', 'The Whispering Blight', 'The Thirteen', '[\"edict_allow_rot\", \"edict_spread_sickness\", \"edict_embrace_decay\"]', '[\"anathema_cure_without_toll\", \"anathema_preserve_corpse\", \"anathema_construct_monuments\"]', 'Decomposing Skull', 'Locust', '[\"Green\", \"Black\"]', '[\"CON\", \"WIS\"]', '[\"harm\"]', 5, 'occultism', 'injection spear', '[\"death\", \"decay\", \"plague\", \"swarm\"]', '[\"pain\", \"undeath\"]', '{\"1\": \"enfeeble\", \"3\": \"stinking cloud\", \"5\": \"toxic cloud\"}', 'You gain resistance 2 to poison.', 'Your touch inflicts a debilitating disease.', 'You can cast horrid wilting once per day.', 'Food rots in your presence.', 'You emit a foul stench, taking a -2 penalty to Diplomacy.', 'You become a carrier of a deadly plague, infecting those around you.', 'An ancient, terrifying entity embodying the inevitable rot of the world...'),
		('tavrin', 'Tavrin', 'The Laughing Vagabond', 'The Thirteen', '[\"edict_travel_new_road\", \"edict_trust_chance\", \"edict_share_story\", \"edict_defy_tyrants\"]', '[\"anathema_own_property\", \"anathema_refuse_gamble\", \"anathema_enforce_laws\"]', 'Pair of Ivory Dice', 'Mouse', '[\"Brown\", \"Yellow\"]', '[\"DEX\", \"CHA\"]', '[\"harm\", \"heal\"]', 0, 'diplomacy', 'battle lute', '[\"freedom\", \"indulgence\", \"luck\", \"travel\"]', '[\"confidence\", \"passion\"]', '{\"1\": \"fleet step\", \"2\": \"blur\", \"4\": \"translocate\"}', 'You gain a +10-foot status bonus to your Speed.', 'You can cast dimension door once per day.', 'You can cast teleport once per day.', 'You can never sleep in the same bed twice.', 'You become lost easily, taking a -4 penalty to Survival checks to navigate.', 'You are cursed to wander forever, unable to stay in one place for more than a day.', 'A trickster god of the open road, the rolling dice, and the bottom of a wine glass.'),
		('brada', 'Brada', 'The Iron Architect', 'The Thirteen', '[\"edict_build_structures\", \"edict_fair_trade\", \"edict_respect_laws\", \"edict_invest_civilization\"]', '[\"anathema_destroy_building\", \"anathema_break_contract\", \"anathema_hoard_wealth\"]', 'Golden Abacus', 'Mole', '[\"Silver\", \"Copper\"]', '[\"STR\", \"INT\"]', '[\"harm\", \"heal\"]', 0, 'society', 'warhammer', '[\"cities\", \"creation\", \"earth\", \"wealth\"]', '[\"duty\", \"perfection\"]', '{\"1\": \"mending\", \"3\": \"earthbind\", \"5\": \"wall of stone\"}', 'You can appraise the value of any item perfectly.', 'You gain resistance 5 to physical damage.', 'You can cast earthquake once per day.', 'You must pay a toll to cross any bridge or enter any city.', 'You become obsessed with wealth, unable to part with coins.', 'You turn to stone.', 'The patron of builders, masons, and the relentless flow of coin that binds societies together.'),
		('kragthor', 'Kragthor', 'The Storm-Crowned Tyrant', 'The Thirteen', '[\"edict_crush_opposition\", \"edict_inspire_fear\", \"edict_strike_without_warning\"]', '[\"anathema_show_mercy\", \"anathema_allow_insult\", \"anathema_submit_weaker\"]', 'Raging Storm Cloud', 'Hawk', '[\"Yellow\", \"Green\"]', '[\"STR\", \"CHA\"]', '[\"harm\"]', 2, 'athletics', 'greatpick', '[\"air\", \"destruction\", \"lightning\", \"tyranny\"]', '[\"might\", \"water\"]', '{\"1\": \"thunderstrike\", \"3\": \"lightning bolt\", \"6\": \"chain lightning\"}', 'You can deal 1d6 electricity damage with a touch.', 'You gain electricity resistance 5.', 'You can cast chain lightning once per day.', 'You are constantly shocked by static electricity.', 'You attract lightning strikes during storms.', 'You are deafened permanently by the sound of thunder.', 'A brutal deity of subjugation and the destructive, uncaring power of the hurricane.'),
		('morwenna', 'Morwenna', 'The Veiled Mourner', 'The Thirteen', '[\"edict_comfort_grieving\", \"edict_proper_burial\", \"edict_embrace_quiet\"]', '[\"anathema_deny_mourning\", \"anathema_force_happiness\", \"anathema_desecrate_tomb\"]', 'Burning Incense', 'Raven', '[\"Black\", \"White\"]', '[\"WIS\", \"CHA\"]', '[\"heal\"]', 1, 'religion', 'rope dart', '[\"darkness\", \"repose\", \"sorrow\", \"soul\"]', '[\"cold\", \"healing\"]', '{\"1\": \"sanctuary\", \"2\": \"peaceful rest\", \"9\": \"Seize Soul\"}', 'You can see in darkness.', 'You gain resistance 5 to negative damage.', 'You can cast wail of the banshee once per day.', 'You weep constantly, taking a -1 penalty to Perception.', 'You are surrounded by an aura of gloom, making others unfriendly.', 'You are haunted by the spirits of the dead.', 'A quiet, somber deity who guides souls to the afterlife and comforts those left behind.'),
		('oneris', 'Oneris', 'The Endless Trance', 'The Thirteen', '[\"edict_trust_intuition\", \"edict_create_subconscious_art\", \"edict_sleep_beneath_moonlight\"]', '[\"anathema_rely_empirical\", \"anathema_wake_dreamer\", \"anathema_suppress_hallucination\"]', 'Cloud Obscurred Moon', 'Sloth', '[\"Purple\", \"Cyan\"]', '[\"CHA\", \"WIS\"]', '[\"harm\", \"heal\"]', 0, 'performance', 'fighting fan', '[\"delirium\", \"dreams\", \"moon\", \"nightmares\"]', '[\"darkness\", \"star\"]', '{\"1\": \"sleep\", \"3\": \"dream message\", \"4\": \"nightmare\"}', 'You require only 2 hours of sleep.', 'You can cast dream message once per day.', 'You can cast Phantasmagoria once per day.', 'You suffer from vivid nightmares, becoming fatigued.', 'You have difficulty distinguishing dreams from reality.', 'You fall into a permanent coma.', 'An enigmatic, shifting entity residing deep within the shifting expanse of the Dreamlands.'),
		('vurrok', 'Vurrok', 'The Primal Roar', 'The Thirteen', '[\"edict_hunt_survival\", \"edict_embrace_primal\", \"edict_allow_wild_reclaim\"]', '[\"anathema_domesticate_predator\", \"anathema_suppress_instincts\", \"anathema_destroy_nature\"]', 'Snarling Fanged Mouth', 'Wolf', '[\"Green\", \"Brown\"]', '[\"STR\", \"CON\"]', '[\"harm\", \"heal\"]', 3, 'nature', 'fist', '[\"change\", \"nature\", \"passion\", \"zeal\"]', '[\"earth\", \"might\"]', '{\"1\": \"runic body\", \"2\": \"animal form\", \"6\": \"cursed metamorphosis\"}', 'You gain a +2 circumstance bonus to Survival.', 'You can speak with animals at will.', 'You can cast nature''s reprisal once per day.', 'You must eat raw meat.', 'You lose the ability to speak humanoid languages.', 'You permanently transform into a wild beast.', 'A deity of the untamed wilds, raw emotion, and the endless, brutal cycle of predator and prey.'),
		('severin', 'Severin', 'The Ashen Judge', 'The Thirteen', '[\"edict_speak_truth\", \"edict_hone_mind_body\", \"edict_judge_by_actions\"]', '[\"anathema_tell_lie\", \"anathema_cloud_judgment\", \"anathema_indulge_excess\"]', 'Shining Mirror', 'Fox', '[\"White\", \"Grey\"]', '[\"WIS\", \"DEX\"]', '[\"heal\"]', 1, 'acrobatics', 'bow staff', '[\"dust\", \"introspection\", \"perfection\", \"truth\"]', '[\"duty\", \"fate\"]', '{\"1\": \"command\", \"3\": \"ring of truth\", \"4\": \"discern lies\"}', 'You gain a +2 status bonus against illusions.', 'You can cast zone of truth once per day.', 'You can cast overwhelming presence once per day.', 'You cannot tell a lie, even to save a life.', 'You become rigidly inflexible, taking a -2 penalty to all Charisma checks.', 'You are turned to ash.', 'A severe, uncompromising deity of absolute truth and self-mastery.'),
		('bathyos', 'Bathyos', 'The Abyssal Depth', 'The Thirteen', '[\"edict_keep_secrets\", \"edict_seek_forbidden_lore\", \"edict_embrace_cold_isolation\"]', '[\"anathema_reveal_truth\", \"anathema_show_fear\", \"anathema_share_knowledge\"]', 'Submerged Pair of Eyes', 'Octopus', '[\"Blue\", \"Black\"]', '[\"INT\", \"WIS\"]', '[\"harm\"]', 2, 'deception', 'garrote', '[\"cold\", \"secrecy\", \"void\", \"water\"]', '[\"darkness\", \"delirium\"]', '{\"1\": \"befuddle\", \"5\": \"slither\", \"7\": \"mask of terror\"}', 'You can breathe underwater.', 'You gain cold resistance 5.', 'You can cast polar ray once per day.', 'You are always freezing cold.', 'You suffer from claustrophobia in tight spaces.', 'You are dragged into the abyssal depths by unseen tentacles.', 'An eldritch intelligence dwelling in the crushing, lightless depths of the abyssal oceans.'),
		('stryvan', 'Stryvan', 'The Ambitious Flame', 'The Thirteen', '[\"edict_seize_leadership\", \"edict_improve_station\", \"edict_assert_superiority\"]', '[\"anathema_accept_subordinate\", \"anathema_show_doubt\", \"anathema_allow_outmaneuver\"]', 'Golden Throne', 'Lion', '[\"Gold\", \"Purple\"]', '[\"STR\", \"CHA\"]', '[\"harm\", \"heal\"]', 3, 'intimidation', 'greatsword', '[\"ambition\", \"confidence\", \"knowledge\", \"might\"]', '[\"wealth\", \"zeal\"]', '{\"1\": \"sure strike\", \"2\": \"enlarge\", \"3\": \"heroism\"}', 'You gain a +1 status bonus to Intimidation.', 'You can cast heroism once per day.', 'You can cast divine decree once per day.', 'You become overly arrogant.', 'You refuse to accept help from others.', 'You are stripped of all your titles and wealth.', 'A deity of rising above one''s station through sheer will, intellect, and physical prowess.'),
		('corvyna', 'Corvyna', 'The Crimson Matriarch', 'The Thirteen', '[\"edict_protect_bloodline\", \"edict_honor_ancestors\", \"edict_endure_pain\"]', '[\"anathema_betray_family\", \"anathema_refuse_bloodshed\", \"anathema_forget_ancestors\"]', 'Blood Soaked Flower', 'Bear', '[\"Red\", \"White\"]', '[\"CON\", \"WIS\"]', '[\"harm\", \"heal\"]', 3, 'medicine', 'sickle', '[\"family\", \"healing\", \"pain\", \"undeath\"]', '[\"protection\", \"sorrow\"]', '{\"2\": \"blood vendetta\", \"3\": \"vampiric feast\", \"6\": \"vampiric exsanguination\"}', 'You can stabilize a dying creature with a touch.', 'You can cast blood vendetta once per day.', 'You can cast regenerate once per day.', 'You bleed profusely from minor wounds.', 'You suffer the pain of your ancestors, becoming sickened 1.', 'Your bloodline is cursed to end with you.', 'A deeply polarizing deity representing the inescapable bonds of bloodlines.');")

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

func get_heritage_raw_data(id: String) -> Dictionary:
	if database == null: return {}
	database.query("SELECT * FROM heritages WHERE id = '" + id + "'")
	if database.query_result.size() > 0:
		return database.query_result[0]
	return {}

func get_available_heritages_for_ancestry(ancestry_id: String) -> Array[Dictionary]:
	if database == null: return []
	var result: Array[Dictionary] = []
	var sql = "SELECT * FROM heritages WHERE ancestry_id = '" + ancestry_id + "' OR is_versatile = 1 OR ancestry_id = '' ORDER BY is_versatile ASC, name ASC;"
	if database.query(sql):
		for row in database.query_result:
			result.append(row)
	return result

func get_available_ethnicities_for_traits(actor_traits: Array[StringName]) -> Array[Dictionary]:
	if database == null: return []
	
	database.query("SELECT * FROM ethnicities ORDER BY name ASC;")
	var all_ethnicities = database.query_result
	var valid_ethnicities: Array[Dictionary] = []
	
	var lower_actor_traits: Array[String] = []
	for t in actor_traits:
		lower_actor_traits.append(str(t).strip_edges().to_lower())
	
	for row in all_ethnicities:
		var reqs: Array = []
		var raw_reqs = row.get("required_traits", "")
		if raw_reqs != null and str(raw_reqs) != "":
			var parsed = JSON.parse_string(str(raw_reqs))
			if parsed is Array:
				reqs = parsed
			else:
				var cleaned = str(raw_reqs).trim_prefix("[").trim_suffix("]")
				for p in cleaned.split(","):
					var c = p.strip_edges().trim_prefix('"').trim_suffix('"').trim_prefix("'").trim_suffix("'").to_lower()
					if c != "": reqs.append(c)
					
		var meets_reqs = false
		if reqs.is_empty():
			meets_reqs = true
		else:
			for req in reqs:
				var clean_req = str(req).strip_edges().to_lower()
				if lower_actor_traits.has(clean_req):
					meets_reqs = true
					break
		
		if meets_reqs:
			valid_ethnicities.append({
				"id": StringName(row["id"]),
				"name": row["name"],
				"required_traits": reqs,
				"description": row.get("description", "")
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

func get_all_ancestries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if database.query("SELECT id, name, description, boosts, flaws, alternate_boosts, hp, speed, vision, traits, known_languages, ethnicities, heritages FROM ancestries ORDER BY name ASC"):
		for row in database.query_result:
			result.append(row)
	return result

func get_all_backgrounds() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if database.query("SELECT id, name, description, boosts, flaws, skills, lores FROM backgrounds ORDER BY name ASC"):
		for row in database.query_result:
			result.append(row)
	return result

func get_all_classes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if database.query("SELECT id, name, description, key_abilities, hp_per_level, trained_skills_count, is_spellcaster FROM classes ORDER BY name ASC"):
		for row in database.query_result:
			result.append(row)
	return result

func get_all_ethnicities() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if database.query("SELECT id, name, description FROM ethnicities ORDER BY name ASC"):
		for row in database.query_result:
			result.append(row)
	return result

func get_all_regions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if database.query("SELECT id, name, description FROM regions ORDER BY name ASC"):
		for row in database.query_result:
			result.append(row)
	return result


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
	new_ancestry.id = StringName(id)
	new_ancestry.entity_name = row.get("name", "")
	new_ancestry.description = row.get("description", "")
	new_ancestry.rarity = int(row.get("rarity", 0)) as PFBiographyConstants.Rarity
	new_ancestry.hp = int(row.get("hp", 8))
	new_ancestry.size_id = StringName(row.get("size", "medium"))

	new_ancestry.speed = int(row.get("speed", 25))
	new_ancestry.speed_fly = int(row.get("speed_fly", 0))
	new_ancestry.speed_swim = int(row.get("speed_swim", 0))
	new_ancestry.speed_climb = int(row.get("speed_climb", 0))
	new_ancestry.speed_burrow = int(row.get("speed_burrow", 0))

	new_ancestry.vision = int(row.get("vision", 0)) as PFBiographyConstants.Vision
	new_ancestry.starting_gold = int(row.get("starting_gold", 15))

	new_ancestry.physical_description = row.get("physical_description", "")
	new_ancestry.societal_description = row.get("societal_description", "")
	new_ancestry.common_beliefs = row.get("common_beliefs", "")

	new_ancestry.traits = _parse_stringname_array(row.get("traits", ""))
	new_ancestry.ability_boosts = _parse_stringname_array(row.get("boosts", ""))
	new_ancestry.ability_flaws = _parse_stringname_array(row.get("flaws", ""))

	var alt_boosts = _parse_stringname_array(row.get("alternate_boosts", ""))
	if not alt_boosts.is_empty():
		new_ancestry.alternate_ancestry_boosts = alt_boosts

	new_ancestry.known_languages = _parse_stringname_array(row.get("known_languages", ""))

	new_ancestry.ethnicities = _parse_string_array(row.get("ethnicities", ""))
	new_ancestry.heritages = _parse_string_array(row.get("heritages", ""))

	new_ancestry.common_edicts = _parse_stringname_array(row.get("common_edicts", ""))
	new_ancestry.common_anathema = _parse_stringname_array(row.get("common_anathema", ""))
	new_ancestry.common_names = _parse_string_array(row.get("common_names", ""))

	return new_ancestry

func get_ancestry_raw_data(id: String) -> Dictionary:
	if _ancestries_cache.has(id):
		return _ancestries_cache[id]
	get_ancestry(id)
	return _ancestries_cache.get(id, {})

func get_background_raw_data(id: String) -> Dictionary:
	if _backgrounds_cache.has(id):
		return _backgrounds_cache[id]
	get_background(id)
	return _backgrounds_cache.get(id, {})

func get_class_raw_data(id: String) -> Dictionary:
	database.query("SELECT * FROM classes WHERE id = '" + id + "'")
	if database.query_result.size() > 0:
		return database.query_result[0]
	return {}

func get_ethnicity_raw_data(id: String) -> Dictionary:
	database.query("SELECT * FROM ethnicities WHERE id = '" + id + "'")
	if database.query_result.size() > 0:
		return database.query_result[0]
	return {}

func get_region_raw_data(id: String) -> Dictionary:
	database.query("SELECT * FROM regions WHERE id = '" + id + "'")
	if database.query_result.size() > 0:
		return database.query_result[0]
	return {}

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
	new_deity.title = row["title"]
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
	
	
	var parsed_colors = JSON.parse_string(row["sacred_colors"])
	if parsed_colors: new_deity.sacred_colors.assign(parsed_colors)
	
	
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
		database.query("INSERT OR IGNORE INTO player_knowledge (monster_id) VALUES ('" + monster_id + "');")
		
	var set_statements = []
	for key in updates:
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
	return get_belief_data(StringName(edict_id))

func get_anathema_data(anathema_id: String) -> Dictionary:
	return get_belief_data(StringName(anathema_id))

func get_deity(id: String) -> PFDeity:
	if _deities_cache.has(id):
		return _deities_cache[id]
		
	database.query("SELECT * FROM deities WHERE id = '" + id + "'")
	if database.query_result.size() == 0:
		push_error("PFDatabase: Deity not found -> " + id)
		return null
		
	var row = database.query_result[0]
	var deity = PFDeity.new(row.get("name", ""), [], PFBiographyConstants.Rarity.COMMON)
	deity.id = StringName(id)
	deity.title = row.get("title", "")
	deity.category = row.get("category", "")
	deity.description = row.get("description", "")
	deity.religious_symbol = row.get("religious_symbol", "")
	deity.sacred_animal = row.get("sacred_animal", "")
	deity.favored_weapon = StringName(row.get("favored_weapon", ""))
	deity.divine_skill = StringName(row.get("divine_skill", ""))
	
	# Parse divine sanctification
	var sanct_raw = str(row.get("divine_sanctification", "none")).strip_edges().to_lower()
	if sanct_raw == "1" or sanct_raw == "must choose holy":
		deity.divine_sanctification = PFBiographyConstants.DivineSanctification.MUST_CHOOSE_HOLY
	elif sanct_raw == "2" or sanct_raw == "must choose unholy":
		deity.divine_sanctification = PFBiographyConstants.DivineSanctification.MUST_CHOOSE_UNHOLY
	elif sanct_raw == "3" or sanct_raw == "can choose holy":
		deity.divine_sanctification = PFBiographyConstants.DivineSanctification.CAN_CHOOSE_HOLY
	elif sanct_raw == "4" or sanct_raw == "can choose unholy":
		deity.divine_sanctification = PFBiographyConstants.DivineSanctification.CAN_CHOOSE_UNHOLY
	elif sanct_raw == "5" or sanct_raw == "can choose either" or sanct_raw == "can choose holy or unholy":
		deity.divine_sanctification = PFBiographyConstants.DivineSanctification.CAN_CHOOSE_EITHER
	else:
		deity.divine_sanctification = PFBiographyConstants.DivineSanctification.NONE
		
	deity.edicts = _parse_stringname_array(row.get("edicts", ""))
	deity.anathema = _parse_stringname_array(row.get("anathema", ""))
	deity.domains = _parse_string_array(row.get("domains", ""))
	deity.alternate_domains = _parse_string_array(row.get("alternate_domains", ""))
	deity.sacred_colors = _parse_string_array(row.get("sacred_colors", ""))
	deity.divine_font = _parse_string_array(row.get("divine_font", ""))
	deity.divine_attributes = _parse_stringname_array(row.get("divine_attributes", ""))
	
	var spells_raw = row.get("cleric_spells", "")
	if spells_raw != null and str(spells_raw) != "":
		var json = JSON.new()
		if json.parse(str(spells_raw)) == OK and json.data is Dictionary:
			deity.cleric_spells = json.data
			
	_deities_cache[id] = deity
	return deity

# --- SPELL VARIANTS ---

func get_spell_variant_data(variant_id: int) -> Dictionary:
	if _spell_variants_cache.has(variant_id): return _spell_variants_cache[variant_id]
	database.query("SELECT * FROM spell_variants WHERE id = " + str(variant_id) + ";")
	var result = database.query_result
	if result.is_empty(): return {}
	_spell_variants_cache[variant_id] = result[0]
	return result[0]
