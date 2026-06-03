# pf_database.gd
extends Node

const DB_PATH = "res://db/pf2e_data.db"
var db

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
		size INTEGER,
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
	
	db.query("INSERT OR IGNORE INTO weapons (id, name, traits, level, price_cp, material, hardness, max_hp, broken_threshold, grade, bulk, weapon_type, category, group_type, damage_dice, damage_faces, damage_type) VALUES 
		('longsword', 'Longsword', 'versatile_p', 1, 100, 3, 5, 20, 10, 1, 1, 0, 1, 4, 1, 8, 3);")
		
	db.query("INSERT OR IGNORE INTO shields (id, name, traits, level, price_cp, bulk, ac_bonus, speed_penalty, hardness, max_hp, broken_threshold) VALUES 
		('buckler', 'Buckler', 'buckler', 1, 10, 1, 1, 0, 3, 12, 6);")
		
	db.query("INSERT OR IGNORE INTO shields (id, name, traits, level, price_cp, bulk, ac_bonus, speed_penalty, hardness, max_hp, broken_threshold) VALUES 
		('steel_shield', 'Steel Shield', '', 1, 200, 1, 2, 0, 5, 20, 10);")
		
	# Seed Character Creation Data
	db.query("INSERT OR IGNORE INTO ancestries (id, name, traits, hp, size, speed, boosts, flaws) VALUES 
		('human', 'Human', 'human,humanoid', 8, 2, 25, 'FREE,FREE', '');")
		
	db.query("INSERT OR IGNORE INTO backgrounds (id, name, traits, boosts, skills, lores, description) VALUES 
		('farmhand', 'Farmhand', '', 'CON,FREE', 'athletics', 'Farming Lore', 'You grew up working on a farm.');")
		
	# Fighter: 10 HP, STR or DEX key, Expert Perc/Fort/Ref, Trained Will, 3 skills
	# Trained Class DC (2). Expert unarmed/simple/martial, trained advanced. Trained all armor.
	db.query("INSERT OR IGNORE INTO classes (id, name, traits, hp_per_level, key_abilities, perception_rank, class_dc_rank, save_fort, save_ref, save_will, trained_skills_count, weapon_unarmed, weapon_simple, weapon_martial, weapon_advanced, armor_unarmored, armor_light, armor_medium, armor_heavy, forced_edicts, forced_anathema, is_spellcaster, caster_type, spell_tradition, spell_proficiency, spell_progression) VALUES 
		('fighter', 'Fighter', '', 10, 'STR,DEX', 4, 2, 4, 4, 2, 3, 4, 4, 4, 2, 2, 2, 2, 2, '[]', '[]', 0, 0, 0, 0, 0);")
		
	# Spells
	var tr_arc_occ = JSON.stringify([PFEntity.MagicTradition.ARCANE, PFEntity.MagicTradition.OCCULT])
	var tr_arc_pri = JSON.stringify([PFEntity.MagicTradition.ARCANE, PFEntity.MagicTradition.PRIMAL])
	
	db.query("INSERT OR IGNORE INTO spells (id, name, traits, base_spell_rank, spell_category, traditions, saving_throw, is_attack, damage_type, scaling_rules, scaling_dice, description) VALUES 
		('illusory_object', 'Illusory Object', 'illusion,visual', 1, 0, '" + tr_arc_occ + "', '', 0, '', 0, 0, 'You create an illusion of an object.');")
	
	db.query("INSERT OR IGNORE INTO spell_variants (spell_id, action_cost, spell_range, target, duration, damage_dice, damage_faces, applied_conditions, special_effects) VALUES 
		('illusory_object', 4, 500, '', '', 0, 0, '[]', '');")
		
	db.query("INSERT OR IGNORE INTO spells (id, name, traits, base_spell_rank, spell_category, traditions, saving_throw, is_attack, damage_type, scaling_rules, scaling_dice, description) VALUES 
		('creation', 'Creation', 'manipulate', 4, 0, '" + tr_arc_pri + "', '', 0, '', 0, 0, 'You create a temporary object.');")
		
	db.query("INSERT OR IGNORE INTO spell_variants (spell_id, action_cost, spell_range, target, duration, damage_dice, damage_faces, applied_conditions, special_effects) VALUES 
		('creation', 4, 0, '', '1 hour', 0, 0, '[]', '');")
		
	# Deity: Abadar
	var abadar_edicts = JSON.stringify(["bring civilization to the frontiers", "earn wealth through hard work and trade", "follow the rule of law"])
	var abadar_anathema = JSON.stringify(["engage in banditry or piracy", "steal", "undermine a law-abiding court"])
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

func get_weapon(id: String) -> PFWeapon:
	db.query("SELECT * FROM weapons WHERE id = '" + id + "'")
	if db.query_result.size() == 0:
		push_error("PFDatabase: Weapon not found -> " + id)
		return null
		
	var row = db.query_result[0]
	var w = PFWeapon.new()
	
	w.entity_name = row["name"]
	w.base_name = row["name"]
	
	var traits_array: Array[StringName] = []
	if row["traits"] != "":
		var split = row["traits"].split(",")
		for t in split:
			traits_array.append(StringName(t.strip_edges()))
	w.traits = traits_array
	
	w.level = row["level"]
	w.base_level = row["level"]
	w.price_cp = row["price_cp"]
	w.base_price_cp = row["price_cp"]
	
	w.item_material = row["material"]
	w.hardness = row["hardness"]
	w.max_hp = row["max_hp"]
	w.current_hp = row["max_hp"]
	w.broken_threshold = row["broken_threshold"]
	w.grade = row["grade"]
	w.bulk_value = row["bulk"]
	w.base_bulk_value = row["bulk"]
	
	w.weapon_type = row["weapon_type"]
	w.category = row["category"]
	w.group = row["group_type"]
	
	w.base_dice_amount = row["damage_dice"]
	w.dice_amount = row["damage_dice"]
	w.die_faces = row["damage_faces"]
	w.base_damage_type = row["damage_type"]
	w.active_damage_type = row["damage_type"]
	
	return w

func get_shield(id: String) -> PFShield:
	db.query("SELECT * FROM shields WHERE id = '" + id + "'")
	if db.query_result.size() == 0:
		push_error("PFDatabase: Shield not found -> " + id)
		return null
		
	var row = db.query_result[0]
	var s = PFShield.new()
	
	s.entity_name = row["name"]
	s.base_name = row["name"]
	
	var traits_array: Array[StringName] = []
	if row["traits"] != "":
		var split = row["traits"].split(",")
		for t in split:
			traits_array.append(StringName(t.strip_edges()))
	s.traits = traits_array
	
	s.level = row["level"]
	s.base_level = row["level"]
	s.price_cp = row["price_cp"]
	s.base_price_cp = row["price_cp"]
	
	s.bulk_value = row["bulk"]
	s.base_bulk_value = row["bulk"]
	
	s.ac_bonus = row["ac_bonus"]
	s.speed_penalty = row["speed_penalty"]
	
	s.base_hardness = row["hardness"]
	s.hardness = row["hardness"]
	s.base_max_hp = row["max_hp"]
	s.max_hp = row["max_hp"]
	s.current_hp = row["max_hp"]
	s.base_broken_threshold = row["broken_threshold"]
	s.broken_threshold = row["broken_threshold"]
	
	return s

func get_ancestry(id: String) -> PFAncestry:
	db.query("SELECT * FROM ancestries WHERE id = '" + id + "'")
	if db.query_result.size() == 0:
		push_error("PFDatabase: Ancestry not found -> " + id)
		return null
		
	var row = db.query_result[0]
	var a = PFAncestry.new()
	a.entity_name = row["name"]
	a.hp = row["hp"]
	a.size = row["size"] as PFEntity.Size
	a.speed = row["speed"]
	
	if row["boosts"] != "":
		for b in row["boosts"].split(","):
			a.ability_boosts.append(StringName(b.strip_edges()))
	if row["flaws"] != "":
		for f in row["flaws"].split(","):
			a.ability_flaws.append(StringName(f.strip_edges()))
			
	return a

func get_background(id: String) -> PFBackground:
	db.query("SELECT * FROM backgrounds WHERE id = '" + id + "'")
	if db.query_result.size() == 0:
		push_error("PFDatabase: Background not found -> " + id)
		return null
		
	var row = db.query_result[0]
	var b = PFBackground.new()
	b.entity_name = row["name"]
	b.background_description = row["description"]
	
	if row["boosts"] != "":
		for x in row["boosts"].split(","):
			b.ability_boosts.append(StringName(x.strip_edges()))
	if row["skills"] != "":
		for x in row["skills"].split(","):
			b.trained_skills.append(StringName(x.strip_edges()))
	if row["lores"] != "":
		for x in row["lores"].split(","):
			b.trained_lores.append(StringName(x.strip_edges()))
			
	return b

func get_pf_class(id: String) -> PFClass:
	db.query("SELECT * FROM classes WHERE id = '" + id + "'")
	if db.query_result.size() == 0:
		push_error("PFDatabase: Class not found -> " + id)
		return null
		
	var row = db.query_result[0]
	var c = PFClass.new()
	c.entity_name = row["name"]
	c.hp_per_level = row["hp_per_level"]
	c.perception_rank = row["perception_rank"] as PFProficiency.Rank
	c.class_dc_rank = row["class_dc_rank"] as PFProficiency.Rank
	c.trained_skills_count = row["trained_skills_count"]
	
	if row["forced_edicts"] and row["forced_edicts"] != "":
		var parsed = JSON.parse_string(row["forced_edicts"])
		if parsed: c.forced_edicts.assign(parsed)
		
	if row["forced_anathema"] and row["forced_anathema"] != "":
		var parsed = JSON.parse_string(row["forced_anathema"])
		if parsed: c.forced_anathema.assign(parsed)
		
	c.is_spellcaster = (row["is_spellcaster"] == 1)
	c.caster_type = row["caster_type"] as PFEntity.CasterType
	c.spell_tradition = row["spell_tradition"] as PFEntity.MagicTradition
	c.spell_proficiency = row["spell_proficiency"] as PFProficiency.Rank
	c.spell_progression = row["spell_progression"] as PFEntity.SpellProgression
	
	if row["key_abilities"] != "":
		for k in row["key_abilities"].split(","):
			c.key_abilities.append(StringName(k.strip_edges()))
			
	c.saving_throws = {
		"fort": row["save_fort"] as PFProficiency.Rank,
		"ref": row["save_ref"] as PFProficiency.Rank,
		"will": row["save_will"] as PFProficiency.Rank
	}
	
	c.weapon_proficiencies = {
		PFWeapon.Category.UNARMED: row["weapon_unarmed"] as PFProficiency.Rank,
		PFWeapon.Category.SIMPLE: row["weapon_simple"] as PFProficiency.Rank,
		PFWeapon.Category.MARTIAL: row["weapon_martial"] as PFProficiency.Rank,
		PFWeapon.Category.ADVANCED: row["weapon_advanced"] as PFProficiency.Rank
	}
	
	c.armor_proficiencies = {
		PFArmor.Category.UNARMORED: row["armor_unarmored"] as PFProficiency.Rank,
		PFArmor.Category.LIGHT: row["armor_light"] as PFProficiency.Rank,
		PFArmor.Category.MEDIUM: row["armor_medium"] as PFProficiency.Rank,
		PFArmor.Category.HEAVY: row["armor_heavy"] as PFProficiency.Rank
	}
	
	return c

func get_pf_spell(id: String) -> PFSpell:
	db.query("SELECT * FROM spells WHERE id = '" + id + "'")
	if db.query_result.size() == 0:
		push_error("PFDatabase: Spell not found -> " + id)
		return null
		
	var row = db.query_result[0]
	var s = PFSpell.new()
	s.entity_name = row["name"]
	s.base_spell_rank = row["base_spell_rank"]
	s.spell_category = row["spell_category"] as PFEntity.SpellCategory
	s.saving_throw = row["saving_throw"]
	s.is_attack = (row["is_attack"] == 1)
	s.damage_type = StringName(row["damage_type"])
	s.scaling_rules = row["scaling_rules"] as PFEntity.ScalingType
	s.scaling_dice = row["scaling_dice"]
	s.description = row["description"]
	
	if row["traits"] != "":
		for t in row["traits"].split(","):
			s.traits.append(StringName(t.strip_edges()))
			
	if row["traditions"] and row["traditions"] != "":
		var parsed_traditions = JSON.parse_string(row["traditions"])
		if parsed_traditions: 
			for tr in parsed_traditions:
				s.traditions.append(tr as PFEntity.MagicTradition)
				
	# Fetch Variants
	db.query("SELECT * FROM spell_variants WHERE spell_id = '" + id + "'")
	for v_row in db.query_result:
		var v = PFSpellVariant.new()
		v.action_cost = v_row["action_cost"] as PFEntity.ActionCost
		v.spell_range = v_row["spell_range"] as PFEntity.Distance
		v.target = v_row["target"]
		v.duration = v_row["duration"]
		v.damage_dice = v_row["damage_dice"]
		v.damage_faces = v_row["damage_faces"]
		v.special_effects = v_row["special_effects"]
		
		if v_row["applied_conditions"] and v_row["applied_conditions"] != "":
			var parsed_conds = JSON.parse_string(v_row["applied_conditions"])
			if parsed_conds:
				for c in parsed_conds:
					v.applied_conditions.append(StringName(c))
					
		s.variants.append(v)
			
	return s

func get_pf_deity(id: String) -> PFDeity:
	db.query("SELECT * FROM deities WHERE id = '" + id + "'")
	if db.query_result.size() == 0:
		push_error("PFDatabase: Deity not found -> " + id)
		return null
		
	var row = db.query_result[0]
	var d = PFDeity.new()
	d.entity_name = row["name"]
	d.category = row["category"]
	d.religious_symbol = row["religious_symbol"]
	d.sacred_animal = row["sacred_animal"]
	d.divine_sanctification = row["divine_sanctification"]
	d.divine_skill = StringName(row["divine_skill"])
	d.favored_weapon = row["favored_weapon"]
	d.boon_minor = row["boon_minor"]
	d.boon_moderate = row["boon_moderate"]
	d.boon_major = row["boon_major"]
	d.curse_minor = row["curse_minor"]
	d.curse_moderate = row["curse_moderate"]
	d.curse_major = row["curse_major"]
	
	# Parse all the JSON Arrays
	var parsed_edicts = JSON.parse_string(row["edicts"])
	if parsed_edicts: d.edicts.assign(parsed_edicts)
	
	var parsed_anathema = JSON.parse_string(row["anathema"])
	if parsed_anathema: d.anathema.assign(parsed_anathema)
	
	var parsed_areas = JSON.parse_string(row["areas_of_concern"])
	if parsed_areas: d.areas_of_concern.assign(parsed_areas)
	
	var parsed_colors = JSON.parse_string(row["sacred_colors"])
	if parsed_colors: d.sacred_colors.assign(parsed_colors)
	
	var parsed_pantheons = JSON.parse_string(row["pantheons"])
	if parsed_pantheons: d.pantheons.assign(parsed_pantheons)
	
	var parsed_attributes = JSON.parse_string(row["divine_attributes"])
	if parsed_attributes: 
		for a in parsed_attributes: d.divine_attributes.append(StringName(a))
		
	var parsed_fonts = JSON.parse_string(row["divine_font"])
	if parsed_fonts: d.divine_font.assign(parsed_fonts)
	
	var parsed_domains = JSON.parse_string(row["domains"])
	if parsed_domains: d.domains.assign(parsed_domains)
	
	var parsed_alt_domains = JSON.parse_string(row["alternate_domains"])
	if parsed_alt_domains: d.alternate_domains.assign(parsed_alt_domains)
	
	var parsed_spells = JSON.parse_string(row["cleric_spells"])
	if parsed_spells: d.cleric_spells = parsed_spells
	
	return d
