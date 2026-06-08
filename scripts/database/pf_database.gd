# pf_database.gd
## A stateless singleton that parses sqlite data into GDScript Objects.
class_name PFDatabase
extends Node # Force Reparse

const DB_PATH = "res://db/pf2e_data.db"
var db

# In-memory caches to prevent constant disk I/O
var _sizes_cache: Dictionary = {}
var _traits_cache: Dictionary = {}
var _conditions_cache: Dictionary = {}
var _beliefs_cache: Dictionary = {}
var _skills_cache: Dictionary = {}
var _languages_cache: Dictionary = {}
var _regions_cache: Dictionary = {}
var _heritages_cache: Dictionary = {}
var _animal_companions_cache: Dictionary = {}
var _specific_familiars_cache: Dictionary = {}
var _classes_cache: Dictionary = {}
var _spells_cache: Dictionary = {}

static func get_instance() -> PFDatabase:
	var ml = Engine.get_main_loop()
	if ml and ml.root.has_node("PFDatabase"):
		return ml.root.get_node("PFDatabase") as PFDatabase
	return null

func _ready():
	# If godot-sqlite is missing, this will fail safely.
	if not ClassDB.class_exists("SQLite"):
		push_error("Godot SQLite plugin not found or not enabled!")
		return
		
	db = ClassDB.instantiate("SQLite")
	
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("db"):
		dir.make_dir("db")
		
	db.path = DB_PATH
	db.open_db()
	_initialize_schema_if_needed()

func _initialize_schema_if_needed():
	# TEMPORARY: Drop tables to force schema rebuild during prototyping
	db.query("DROP TABLE IF EXISTS classes;")
	db.query("DROP TABLE IF EXISTS spells;")
	db.query("DROP TABLE IF EXISTS spell_variants;")
	db.query("DROP TABLE IF EXISTS deities;")
	db.query("DROP TABLE IF EXISTS sizes;")
	db.query("DROP TABLE IF EXISTS traits;")
	db.query("DROP TABLE IF EXISTS conditions;")
	db.query("DROP TABLE IF EXISTS ancestries;")
	db.query("DROP TABLE IF EXISTS beliefs;")
	db.query("DROP TABLE IF EXISTS skills;")
	db.query("DROP TABLE IF EXISTS languages;")
	db.query("DROP TABLE IF EXISTS regions;")
	db.query("DROP TABLE IF EXISTS heritages;")
	db.query("DROP TABLE IF EXISTS animal_companions;")
	
	# Core Data-Driven Mechanics Tables
	db.query("CREATE TABLE IF NOT EXISTS sizes (
		id TEXT PRIMARY KEY,
		name TEXT,
		effective_size INTEGER,
		base_bulk INTEGER
	);")
	
	db.query("CREATE TABLE IF NOT EXISTS traits (
		id TEXT PRIMARY KEY,
		name TEXT,
		mechanic_hook TEXT,
		hook_value INTEGER
	);")
	
	db.query("CREATE TABLE IF NOT EXISTS conditions (
		id TEXT PRIMARY KEY,
		name TEXT,
		modifier_type TEXT,
		target_stat TEXT,
		multiplier INTEGER,
		script_path TEXT
	);")
	
	db.query("CREATE TABLE IF NOT EXISTS beliefs (
		id TEXT PRIMARY KEY,
		name TEXT,
		type TEXT,
		mechanic_hook TEXT
	);")
	
	db.query("CREATE TABLE IF NOT EXISTS skills (
		id TEXT PRIMARY KEY,
		name TEXT,
		key_ability TEXT,
		is_lore INTEGER
	);")
	
	db.query("CREATE TABLE IF NOT EXISTS languages (
		id TEXT PRIMARY KEY,
		name TEXT,
		rarity INTEGER
	);")
	
	db.query("CREATE TABLE IF NOT EXISTS regions (
		id TEXT PRIMARY KEY,
		name TEXT
	);")
	
	db.query("CREATE TABLE IF NOT EXISTS heritages (
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
		granted_traits TEXT
	);")
	
	db.query("CREATE TABLE IF NOT EXISTS animal_companions (
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
	db.query("CREATE TABLE IF NOT EXISTS specific_familiars (
		id TEXT PRIMARY KEY,
		name TEXT,
		required_abilities INTEGER,
		granted_abilities TEXT,
		unique_abilities TEXT,
		traits TEXT,
		description TEXT
	);")
	
	# Classes
	db.query("CREATE TABLE IF NOT EXISTS classes (
		id TEXT PRIMARY KEY,
		name TEXT,
		hp_per_level INTEGER,
		key_abilities TEXT,
		perception_rank INTEGER,
		class_dc_rank INTEGER,
		fort_rank INTEGER,
		ref_rank INTEGER,
		will_rank INTEGER,
		trained_skills_count INTEGER,
		is_spellcaster INTEGER,
		caster_type INTEGER,
		spell_tradition INTEGER,
		spell_proficiency INTEGER,
		spell_progression INTEGER,
		description TEXT
	);")
	
	# Spells
	db.query("CREATE TABLE IF NOT EXISTS spells (
		id TEXT PRIMARY KEY,
		name TEXT,
		traits TEXT,
		base_spell_rank INTEGER,
		cast_time TEXT,
		range_ft INTEGER,
		targets TEXT,
		saving_throw TEXT,
		duration TEXT,
		is_cantrip INTEGER,
		description TEXT
	);")
	
	# Weapons
	db.query("CREATE TABLE IF NOT EXISTS weapons (
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
		damage_type INTEGER
	);")
	
	# Shields
	db.query("CREATE TABLE IF NOT EXISTS shields (
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
		broken_threshold INTEGER
	);")
	
	# Ancestries
	db.query("CREATE TABLE IF NOT EXISTS ancestries (
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
	db.query("CREATE TABLE IF NOT EXISTS backgrounds (
		id TEXT PRIMARY KEY,
		name TEXT,
		traits TEXT,
		boosts TEXT,
		skills TEXT,
		lores TEXT,
		description TEXT
	);")
	
	# Classes
	db.query("CREATE TABLE IF NOT EXISTS classes (
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
	db.query("CREATE TABLE IF NOT EXISTS spells (
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
		description TEXT
	);")
	
	# Spell Variants
	db.query("CREATE TABLE IF NOT EXISTS spell_variants (
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
	
	# Deities
	db.query("CREATE TABLE IF NOT EXISTS deities (
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
	
	db.query("SELECT COUNT(*) as count FROM deities;")
	# Force seeding for now while dropping tables
	_seed_data()

func _seed_data():
	print("PFDatabase: Seeding default data...")
	
	# Seed Sizes
	db.query("INSERT OR IGNORE INTO sizes (id, name, effective_size, base_bulk) VALUES 
		('tiny', 'Tiny', 0, 10),
		('small', 'Small', 1, 30),
		('medium', 'Medium', 1, 60),
		('large', 'Large', 2, 120),
		('huge', 'Huge', 3, 240),
		('gargantuan', 'Gargantuan', 4, 480);")
		
	# Seed Traits
	db.query("INSERT OR IGNORE INTO traits (id, name, mechanic_hook, hook_value) VALUES 
		('agile', 'Agile', 'modifies_map', 4),
		('finesse', 'Finesse', 'allows_dex_to_hit', 0),
		('versatile_p', 'Versatile P', 'adds_damage_type', 0);")
		
	# Seed Conditions
	db.query("INSERT OR IGNORE INTO conditions (id, name, modifier_type, target_stat, multiplier, script_path) VALUES 
		('clumsy', 'Clumsy', 'status', 'dex_based', -1, ''),
		('enfeebled', 'Enfeebled', 'status', 'str_based', -1, ''),
		('frightened', 'Frightened', 'status', 'all_checks_and_dcs', -1, '');")
		
	# Seed Beliefs
	db.query("INSERT OR IGNORE INTO beliefs (id, name, type, mechanic_hook) VALUES 
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
	db.query("INSERT OR IGNORE INTO skills (id, name, key_ability, is_lore) VALUES 
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
		
	# Seed Languages
	# Rarity: 0=Common, 1=Uncommon, 2=Rare
	db.query("INSERT OR IGNORE INTO languages (id, name, rarity) VALUES 
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
		
	# Seed Regions
	db.query("INSERT OR IGNORE INTO regions (id, name) VALUES 
		('unknown', 'Unknown'),
		('linvarre', 'Linvarre'),
		('absalom', 'Absalom'),
		('andoran', 'Andoran'),
		('cheliax', 'Cheliax'),
		('taldor', 'Taldor'),
		('qadira', 'Qadira');")
		
	# Seed Heritages
	# vision_override: -1 (no change), 0 (Normal), 1 (Low-Light), 2 (Darkvision)
	db.query("INSERT OR IGNORE INTO heritages (id, name, traits, rarity, ancestry_id, is_versatile, hp_bonus, size_id, speed_bonus, vision_override, granted_traits) VALUES 
		('forge_dwarf', 'Forge Dwarf', '[]', 0, 'dwarf', 0, 0, '', 0, -1, '[\"fire_resistance\"]'),
		('half_elf', 'Half-Elf', '[]', 0, '', 1, 0, '', 0, 1, '[\"elf\", \"half-elf\"]');")
		
	# Seed Animal Companions
	# Unarmed attacks stored as JSON: [{"name": "Jaws", "damage_dice": 1, "damage_faces": 8, "damage_type": 3, "traits": ["unarmed"]}]
	db.query("INSERT OR IGNORE INTO animal_companions (id, name, size_id, ancestry_hp, speed_land, str_mod, dex_mod, con_mod, int_mod, wis_mod, cha_mod, signature_skill, skills, senses, unarmed_attacks, support_benefit, advanced_maneuver) VALUES 
		('bear', 'Bear', 'small', 8, 25, 3, 2, 2, -4, 1, 0, 'athletics', '[\"intimidation\"]', '[1, 2]', '[{\"name\": \"Jaws\", \"damage_dice\": 1, \"damage_faces\": 8, \"damage_type\": 3, \"traits\": [\"unarmed\"]}, {\"name\": \"Claw\", \"damage_dice\": 1, \"damage_faces\": 6, \"damage_type\": 3, \"traits\": [\"agile\", \"unarmed\"]}]', 'Your bear mauls your enemies when you threaten them.', 'Bear Hug'),
		('wolf', 'Wolf', 'small', 6, 40, 2, 3, 1, -4, 1, 0, 'survival', '[\"stealth\"]', '[1, 2]', '[{\"name\": \"Jaws\", \"damage_dice\": 1, \"damage_faces\": 8, \"damage_type\": 3, \"traits\": [\"unarmed\"]}]', 'Your wolf tears at your enemies legs.', 'Knockdown');")
		
	db.query("INSERT OR IGNORE INTO specific_familiars (id, name, required_abilities, granted_abilities, unique_abilities, traits, description) VALUES 
		('faerie_dragon', 'Faerie Dragon', 3, '[\"amphibious\", \"flier\", \"manual_dexterity\", \"speech\", \"telepathy\", \"touch_telepathy\"]', '[\"breath_weapon\"]', '[\"dragon\"]', 'A tiny, colorful dragon that loves pranks.'),
		('imp', 'Imp', 6, '[\"flier\", \"manual_dexterity\", \"speech\", \"touch_telepathy\"]', '[\"invisibility\", \"infernal_temptation\"]', '[\"devil\", \"fiend\"]', 'A small, deceptive fiend often acting as a familiar to malicious masters.');")
		
	db.query("INSERT OR IGNORE INTO classes (id, name, hp_per_level, key_abilities, perception_rank, class_dc_rank, fort_rank, ref_rank, will_rank, trained_skills_count, is_spellcaster, caster_type, spell_tradition, spell_proficiency, spell_progression, description) VALUES 
		('wizard', 'Wizard', 6, '[\"INT\"]', 1, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 'Scholars of the arcane mysteries.');")
		
	db.query("INSERT OR IGNORE INTO spells (id, name, traits, base_spell_rank, cast_time, range_ft, targets, saving_throw, duration, is_cantrip, description) VALUES 
		('fireball', 'Fireball', '[\"fire\", \"evocation\"]', 3, '2', 500, '20-foot burst', 'Reflex', '', 0, 'A roaring blast of fire.'),
		('shield', 'Shield', '[\"abjuration\", \"force\"]', 1, '1', 0, 'Self', '', 'Until the start of your next turn', 1, 'A magical shield of force.');")
	
	db.query("INSERT OR IGNORE INTO weapons (id, name, traits, level, price_cp, material, hardness, max_hp, broken_threshold, grade, bulk, weapon_type, category, group_type, damage_dice, damage_faces, damage_type) VALUES 
		('longsword', 'Longsword', 'versatile_p', 1, 100, 3, 5, 20, 10, 1, 1, 0, 1, 4, 1, 8, 3);")
		
	db.query("INSERT OR IGNORE INTO shields (id, name, traits, level, price_cp, bulk, ac_bonus, speed_penalty, hardness, max_hp, broken_threshold) VALUES 
		('buckler', 'Buckler', 'buckler', 1, 10, 1, 1, 0, 3, 12, 6);")
		
	db.query("INSERT OR IGNORE INTO shields (id, name, traits, level, price_cp, bulk, ac_bonus, speed_penalty, hardness, max_hp, broken_threshold) VALUES 
		('steel_shield', 'Steel Shield', '', 1, 200, 1, 2, 0, 5, 20, 10);")
		
	# Seed Character Creation Data
	db.query("INSERT OR IGNORE INTO ancestries (id, name, traits, hp, size, speed, boosts, flaws) VALUES 
		('human', 'Human', 'human,humanoid', 8, 'medium', 25, 'FREE,FREE', '');")
		
	db.query("INSERT OR IGNORE INTO backgrounds (id, name, traits, boosts, skills, lores, description) VALUES 
		('farmhand', 'Farmhand', '', 'CON,FREE', 'athletics', 'Farming Lore', 'You grew up working on a farm.');")
		
	# Fighter: 10 HP, STR or DEX key, Expert Perc/Fort/Ref, Trained Will, 3 skills
	# Trained Class DC (2). Expert unarmed/simple/martial, trained advanced. Trained all armor.
	db.query("INSERT OR IGNORE INTO classes (id, name, traits, hp_per_level, key_abilities, perception_rank, class_dc_rank, save_fort, save_ref, save_will, trained_skills_count, weapon_unarmed, weapon_simple, weapon_martial, weapon_advanced, armor_unarmored, armor_light, armor_medium, armor_heavy, forced_edicts, forced_anathema, is_spellcaster, caster_type, spell_tradition, spell_proficiency, spell_progression) VALUES 
		('fighter', 'Fighter', '', 10, 'STR,DEX', 4, 2, 4, 4, 2, 3, 4, 4, 4, 2, 2, 2, 2, 2, '[]', '[]', 0, 0, 0, 0, 0);")
		
	# Spells
	var tr_arc_occ = JSON.stringify([PFMagicConstants.MagicTradition.ARCANE, PFMagicConstants.MagicTradition.OCCULT])
	var tr_arc_pri = JSON.stringify([PFMagicConstants.MagicTradition.ARCANE, PFMagicConstants.MagicTradition.PRIMAL])
	
	db.query("INSERT OR IGNORE INTO spells (id, name, traits, base_spell_rank, spell_category, traditions, saving_throw, is_attack, damage_type, scaling_rules, scaling_dice, description) VALUES 
		('illusory_object', 'Illusory Object', 'illusion,visual', 1, 0, '" + tr_arc_occ + "', '', 0, '', 0, 0, 'You create an illusion of an object.');")
	
	db.query("INSERT OR IGNORE INTO spell_variants (spell_id, action_cost, spell_range, target, duration, damage_dice, damage_faces, applied_conditions, special_effects) VALUES 
		('illusory_object', 4, 500, '', '', 0, 0, '[]', '');")
		
	db.query("INSERT OR IGNORE INTO spells (id, name, traits, base_spell_rank, spell_category, traditions, saving_throw, is_attack, damage_type, scaling_rules, scaling_dice, description) VALUES 
		('creation', 'Creation', 'manipulate', 4, 0, '" + tr_arc_pri + "', '', 0, '', 0, 0, 'You create a temporary object.');")
		
	db.query("INSERT OR IGNORE INTO spell_variants (spell_id, action_cost, spell_range, target, duration, damage_dice, damage_faces, applied_conditions, special_effects) VALUES 
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
	
	db.query("INSERT OR IGNORE INTO deities (id, name, category, edicts, anathema, areas_of_concern, religious_symbol, sacred_animal, sacred_colors, pantheons, divine_attributes, divine_font, divine_sanctification, divine_skill, favored_weapon, domains, alternate_domains, cleric_spells, boon_minor, boon_moderate, boon_major, curse_minor, curse_moderate, curse_major) VALUES " + 
	"('abadar', 'Abadar', 'Gods of the Inner Sea', '" + abadar_edicts + "', '" + abadar_anathema + "', '" + abadar_areas + "', 'golden key', 'monkey', '" + abadar_colors + "', '" + abadar_pantheons + "', '" + abadar_attributes + "', '" + abadar_fonts + "', 'can choose holy or unholy', 'society', 'crossbow', '" + abadar_domains + "', '" + abadar_alt_domains + "', '" + abadar_spells + "', '', '', '', '', '', '');")

# ---------------------------------------------------------
# CACHED DATA-DRIVEN FETCHERS
# ---------------------------------------------------------

func get_size_data(size_id: StringName) -> Dictionary:
	if _sizes_cache.has(size_id): return _sizes_cache[size_id]
	db.query("SELECT * FROM sizes WHERE id = '" + str(size_id) + "'")
	if db.query_result.size() == 0:
		push_error("PFDatabase: Size not found -> " + str(size_id))
		return {}
	_sizes_cache[size_id] = db.query_result[0]
	return _sizes_cache[size_id]

func get_trait_data(trait_id: StringName) -> Dictionary:
	if _traits_cache.has(trait_id): return _traits_cache[trait_id]
	db.query("SELECT * FROM traits WHERE id = '" + str(trait_id) + "'")
	if db.query_result.size() == 0:
		push_error("PFDatabase: Trait not found -> " + str(trait_id))
		return {}
	_traits_cache[trait_id] = db.query_result[0]
	return _traits_cache[trait_id]

func get_condition_data(condition_id: StringName) -> Dictionary:
	if _conditions_cache.has(condition_id): return _conditions_cache[condition_id]
	db.query("SELECT * FROM conditions WHERE id = '" + str(condition_id) + "'")
	if db.query_result.size() == 0:
		push_error("PFDatabase: Condition not found -> " + str(condition_id))
		return {}
	_conditions_cache[condition_id] = db.query_result[0]
	return _conditions_cache[condition_id]

func get_belief_data(belief_id: StringName) -> Dictionary:
	if _beliefs_cache.has(belief_id): return _beliefs_cache[belief_id]
	db.query("SELECT * FROM beliefs WHERE id = '" + str(belief_id) + "'")
	if db.query_result.size() == 0:
		push_error("PFDatabase: Belief not found -> " + str(belief_id))
		return {}
	_beliefs_cache[belief_id] = db.query_result[0]
	return _beliefs_cache[belief_id]

func get_skill_data(skill_id: StringName) -> Dictionary:
	if _skills_cache.has(skill_id): return _skills_cache[skill_id]
	db.query("SELECT * FROM skills WHERE id = '" + str(skill_id) + "'")
	if db.query_result.size() == 0:
		return {}
	_skills_cache[skill_id] = db.query_result[0]
	return _skills_cache[skill_id]

func get_core_skills() -> Array[StringName]:
	db.query("SELECT id FROM skills WHERE is_lore = 0")
	var result: Array[StringName] = []
	for row in db.query_result:
		result.append(StringName(row["id"]))
	return result

func get_language_data(language_id: StringName) -> Dictionary:
	if _languages_cache.has(language_id): return _languages_cache[language_id]
	db.query("SELECT * FROM languages WHERE id = '" + str(language_id) + "'")
	if db.query_result.size() == 0:
		push_error("PFDatabase: Language not found -> " + str(language_id))
		return {}
	_languages_cache[language_id] = db.query_result[0]
	return _languages_cache[language_id]

func get_all_common_languages() -> Array[StringName]:
	db.query("SELECT id FROM languages WHERE rarity = 0")
	var result: Array[StringName] = []
	for row in db.query_result:
		result.append(StringName(row["id"]))
	return result

func get_region_data(region_id: StringName) -> Dictionary:
	if _regions_cache.has(region_id): return _regions_cache[region_id]
	db.query("SELECT * FROM regions WHERE id = '" + str(region_id) + "'")
	if db.query_result.size() == 0:
		return {}
	_regions_cache[region_id] = db.query_result[0]
	return _regions_cache[region_id]

func get_heritage(id: String) -> PFHeritage:
	if _heritages_cache.has(id): return _heritages_cache[id]
	
	db.query("SELECT * FROM heritages WHERE id = '" + id + "'")
	if db.query_result.size() == 0:
		push_error("PFDatabase: Heritage not found -> " + id)
		return null
		
	var row = db.query_result[0]
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

func get_animal_companion_data(id: StringName) -> Dictionary:
	if _animal_companions_cache.has(id): return _animal_companions_cache[id]
	db.query("SELECT * FROM animal_companions WHERE id = '" + String(id) + "'")
	if db.query_result.size() == 0:
		push_error("PFDatabase: Animal Companion not found -> " + String(id))
		return {}
	_animal_companions_cache[id] = db.query_result[0]
	return _animal_companions_cache[id]

func get_specific_familiar(id: StringName) -> Dictionary:
	if _specific_familiars_cache.has(id): return _specific_familiars_cache[id]
	db.query("SELECT * FROM specific_familiars WHERE id = '" + String(id) + "'")
	if db.query_result.size() == 0:
		push_error("PFDatabase: Specific Familiar not found -> " + String(id))
		return {}
	_specific_familiars_cache[id] = db.query_result[0]
	return _specific_familiars_cache[id]

func get_class_data(id: StringName) -> Dictionary:
	if _classes_cache.has(id): return _classes_cache[id]
	db.query("SELECT * FROM classes WHERE id = '" + String(id) + "'")
	if db.query_result.size() == 0:
		push_error("PFDatabase: Class not found -> " + String(id))
		return {}
	_classes_cache[id] = db.query_result[0]
	return _classes_cache[id]

func get_spell_data(id: StringName) -> Dictionary:
	if _spells_cache.has(id): return _spells_cache[id]
	db.query("SELECT * FROM spells WHERE id = '" + String(id) + "'")
	if db.query_result.size() == 0:
		push_error("PFDatabase: Spell not found -> " + String(id))
		return {}
	_spells_cache[id] = db.query_result[0]
	return _spells_cache[id]

func get_weapon(id: String) -> PFWeapon:
	db.query("SELECT * FROM weapons WHERE id = '" + id + "'")
	if db.query_result.size() == 0:
		push_error("PFDatabase: Weapon not found -> " + id)
		return null
		
	var row = db.query_result[0]
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
	
	return new_weapon

func get_shield(id: String) -> PFShield:
	db.query("SELECT * FROM shields WHERE id = '" + id + "'")
	if db.query_result.size() == 0:
		push_error("PFDatabase: Shield not found -> " + id)
		return null
		
	var row = db.query_result[0]
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
	
	return new_shield

func get_ancestry(id: String) -> PFAncestry:
	db.query("SELECT * FROM ancestries WHERE id = '" + id + "'")
	if db.query_result.size() == 0:
		push_error("PFDatabase: Ancestry not found -> " + id)
		return null
		
	var row = db.query_result[0]
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
	db.query("SELECT * FROM backgrounds WHERE id = '" + id + "'")
	if db.query_result.size() == 0:
		push_error("PFDatabase: Background not found -> " + id)
		return null
		
	var row = db.query_result[0]
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
	db.query("SELECT * FROM classes WHERE id = '" + id + "'")
	if db.query_result.size() == 0:
		push_error("PFDatabase: Class not found -> " + id)
		return null
		
	var row = db.query_result[0]
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
	db.query("SELECT * FROM deities WHERE id = '" + id + "'")
	if db.query_result.size() == 0:
		push_error("PFDatabase: Deity not found -> " + id)
		return null
		
	var row = db.query_result[0]
	var new_deity = PFDeity.new()
	new_deity.entity_name = row["name"]
	new_deity.category = row["category"]
	new_deity.religious_symbol = row["religious_symbol"]
	new_deity.sacred_animal = row["sacred_animal"]
	new_deity.divine_sanctification = row["divine_sanctification"]
	new_deity.divine_skill = StringName(row["divine_skill"])
	new_deity.favored_weapon = row["favored_weapon"]
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
