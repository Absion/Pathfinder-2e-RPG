# pf_player_character.gd
## A player-controlled character built using standard proficiency matrix mathematics.
class_name PFPlayerCharacter
extends PFActor

# --- COMPONENTS ---
var attributes: PFAttributesComponent
var movement: PFMovementComponent
var senses: PFSensesComponent
var sheet: PFProficiencySheet
var inventory: PFInventory
var spellbook: PFSpellbook

# --- LORE & BACKGROUND ---
var description: String
var gender: PFBiographyConstants.Gender = PFBiographyConstants.Gender.UNKNOWN
var size: PFBiographyConstants.Size = PFBiographyConstants.Size.MEDIUM
var birthplace: PFBiographyConstants.Region = PFBiographyConstants.Region.UNKNOWN
var nationality: PFBiographyConstants.Region = PFBiographyConstants.Region.UNKNOWN
var languages: Array[PFBiographyConstants.LanguageType] = []
var ancestry: PFAncestry
var background: PFBackground
var actor_class: PFClass
var deity: PFDeity
var selected_key_ability: StringName = &""
var bonus_language_slots: int = 0
var available_bonus_languages: Array[PFBiographyConstants.LanguageType] = []

var edicts: Array[String] = []
var anathema: Array[String] = []

func _init(p_name: String, p_traits: Array[StringName], p_level: int,
		p_hp: int, p_fort: int, p_ref: int, p_will: int,
		p_str: int, p_dex: int, p_con: int, p_int: int, p_wis: int, p_cha: int,
		p_speed_land: int = 25, p_speed_fly: int = 0, p_speed_swim: int = 0,
		p_speed_climb: int = 0, p_speed_burrow: int = 0,
		p_description: String = "", 
		p_gender: PFBiographyConstants.Gender = PFBiographyConstants.Gender.UNKNOWN, 
		p_birthplace: PFBiographyConstants.Region = PFBiographyConstants.Region.UNKNOWN, 
		p_nationality: PFBiographyConstants.Region = PFBiographyConstants.Region.UNKNOWN,
		p_has_spirit: bool = true):
			
	# Call PFActor initialization
	super._init(p_name, p_traits, p_level, p_hp)
	
	has_spirit = p_has_spirit
	description = p_description
	gender = p_gender
	birthplace = p_birthplace
	nationality = p_nationality
	
	attributes = PFAttributesComponent.new()
	attributes.initialize(p_fort, p_ref, p_will, p_str, p_dex, p_con, p_int, p_wis, p_cha)
	add_child(attributes)
	
	movement = PFMovementComponent.new()
	movement.initialize(p_speed_land, p_speed_fly, p_speed_swim, p_speed_climb, p_speed_burrow)
	add_child(movement)
	
	senses = PFSensesComponent.new()
	senses.initialize()
	add_child(senses)
	
	sheet = PFProficiencySheet.new(p_level)
	inventory = PFInventory.new(self)
	spellbook = PFSpellbook.new(self)

# DATA SETTERS & BACKGROUND
# ---------------------------------------------------------

func set_description(new_description: String) -> void:
	description = new_description

func set_biography(new_gender: PFBiographyConstants.Gender, new_birthplace: PFBiographyConstants.Region, new_nationality: PFBiographyConstants.Region) -> void:
	gender = new_gender
	birthplace = new_birthplace
	nationality = new_nationality
	print("    > %s's biography updated: PFBiographyConstants.Gender [%s], Birthplace [%s], Nationality [%s]." % [
		entity_name, 
		PFBiographyConstants.Gender.keys()[gender], 
		PFBiographyConstants.Region.keys()[birthplace], 
		PFBiographyConstants.Region.keys()[nationality]
	])

func apply_ancestry(new_ancestry: PFAncestry) -> void:
	ancestry = new_ancestry
	
	health.max_hp += ancestry.hp 
	health.current_hp = health.max_hp
	size = ancestry.size
	
# Apply all inherited movement speeds
	movement.speed_land = ancestry.speed
	if ancestry.speed_fly > 0:
		movement.speed_fly = ancestry.speed_fly
	if ancestry.speed_swim > 0:
		movement.speed_swim = ancestry.speed_swim
	if ancestry.speed_climb > 0:
		movement.speed_climb = ancestry.speed_climb
	if ancestry.speed_burrow > 0:
		movement.speed_burrow = ancestry.speed_burrow
		
	senses.vision = ancestry.vision
	
	# NEW: Feed the Ancestry's special granted items straight into the inventory
	for item in ancestry.granted_items:
		inventory.add_item(item)
	
	# NEW: Grant starting wealth!
	if ancestry.starting_gold > 0:
		inventory.add_currency(ancestry.starting_gold)
	
	# NEW: In the future, this is where you would process granted_abilities
	# for ability in ancestry.granted_abilities:
	#     add_ability(ability)
	
	for sense in ancestry.additional_senses:
		senses.grant_sense(sense.type, sense.acuity, sense.range_ft)
	
	for lang in ancestry.known_languages:
		if not languages.has(lang):
			languages.append(lang)
			
	bonus_language_slots = maxi(0, attributes.int_mod)
	
	available_bonus_languages = ancestry.bonus_language_options.duplicate()
	for common_lang in PFLanguage.get_all_common_languages():
		if not available_bonus_languages.has(common_lang) and not languages.has(common_lang):
			available_bonus_languages.append(common_lang)
			
	for t in ancestry.traits:
		if not traits.has(t):
			traits.append(t)
			
	print("    > %s is now a %s!" % [entity_name, ancestry.entity_name])
	
	# Optional debug prints to verify special speeds transferred correctly
	if movement.speed_fly > 0: print("    > Gained Fly Speed: %d ft." % movement.speed_fly)
	if movement.speed_swim > 0: print("    > Gained Swim Speed: %d ft." % movement.speed_swim)
	if movement.speed_climb > 0: print("    > Gained Climb Speed: %d ft." % movement.speed_climb)

func add_bonus_language_option(lang: PFBiographyConstants.LanguageType) -> void:
	if not languages.has(lang) and not available_bonus_languages.has(lang):
		available_bonus_languages.append(lang)
		print("    > %s gained access to select %s!" % [entity_name, PFBiographyConstants.LanguageType.keys()[lang]])

func learn_language(lang: PFBiographyConstants.LanguageType) -> void:
	if not languages.has(lang):
		languages.append(lang)
		print("    > %s learned %s!" % [entity_name, PFBiographyConstants.LanguageType.keys()[lang]])
		
		if available_bonus_languages.has(lang):
			available_bonus_languages.erase(lang)

func apply_background(new_background: PFBackground) -> void:
	background = new_background
	print("%s selected Background: %s" % [entity_name, new_background.entity_name])
	# Ability boosts will be applied by the level up/character creator system

func apply_class(new_class: PFClass) -> void:
	actor_class = new_class
	
	# Automatically adopt any forced edicts/anathemas
	if actor_class.forced_edicts.size() > 0:
		for e in actor_class.forced_edicts:
			if not edicts.has(e): edicts.append(e)
			
	if actor_class.forced_anathema.size() > 0:
		for a in actor_class.forced_anathema:
			if not anathema.has(a): anathema.append(a)
			
	print("%s selected Class: %s" % [entity_name, new_class.entity_name])
	# Stats updates will be handled by the character creator system

func apply_deity(new_deity: PFDeity) -> void:
	deity = new_deity
	print("%s selected Deity: %s" % [entity_name, new_deity.entity_name])

# ---------------------------------------------------------
# THE UNIFIED MATH DELEGATES
# ---------------------------------------------------------

func get_ac() -> int:
	var base_ac = 10
	var armor = inventory.worn_items.filter(func(i): return i is PFArmor).front()
	if not armor: armor = PFArmor.new("Unarmored", [], 0, 0.0, PFEquipmentConstants.ArmorCategory.UNARMORED, PFEquipmentConstants.ArmorGroup.UNARMORED, 0, 99)
	
	var capped_dex = mini(attributes.dex_mod, armor.dex_cap)
	base_ac += capped_dex + armor.ac_bonus + sheet.get_armor_bonus(armor.category)
	if armor.is_broken(): base_ac -= 2 
	return base_ac + get_condition_modifier(&"ac")

func get_strike_bonus(weapon: PFWeapon) -> int:
	var base_bonus = 0
	var stat_mod = attributes.dex_mod if weapon.weapon_type == PFEquipmentConstants.WeaponType.RANGED else attributes.str_mod
	if weapon.has_trait(&"finesse") and attributes.dex_mod > attributes.str_mod:
		stat_mod = attributes.dex_mod
	base_bonus = stat_mod + sheet.get_weapon_bonus(weapon.category)
	base_bonus += weapon.potency_bonus 
	
	if weapon.is_broken():
		base_bonus -= 2
	return base_bonus + get_condition_modifier(&"attack")

func get_class_dc() -> int:
	if not actor_class:
		return 10
	
	var rank = actor_class.class_dc_rank
	var prof_bonus = PFProficiency.calculate_bonus(rank, sheet.level)
	
	var key_attr = selected_key_ability
	if key_attr == &"" and actor_class.key_abilities.size() > 0:
		key_attr = actor_class.key_abilities[0]
		
	var stat_mod = get_ability_modifier(key_attr)
		
	return 10 + prof_bonus + stat_mod

func get_spell_dc() -> int:
	if not actor_class or not actor_class.is_spellcaster: return 10
	
	var prof_bonus = PFProficiency.calculate_bonus(actor_class.spell_proficiency, sheet.level)
	
	var key_attr = selected_key_ability
	if key_attr == &"" and actor_class.key_abilities.size() > 0:
		key_attr = actor_class.key_abilities[0]
		
	var stat_mod = get_ability_modifier(key_attr)
	return 10 + prof_bonus + stat_mod

func get_spell_attack() -> int:
	if not actor_class or not actor_class.is_spellcaster: return 0
	
	var prof_bonus = PFProficiency.calculate_bonus(actor_class.spell_proficiency, sheet.level)
	
	var key_attr = selected_key_ability
	if key_attr == &"" and actor_class.key_abilities.size() > 0:
		key_attr = actor_class.key_abilities[0]
		
	var stat_mod = get_ability_modifier(key_attr)
	return prof_bonus + stat_mod

func get_strike_damage_bonus(weapon: PFWeapon) -> int:
	var dmg_bonus = 0
	if weapon.weapon_type == PFEquipmentConstants.WeaponType.MELEE:
		dmg_bonus = attributes.str_mod 
		
	if weapon.is_broken():
		dmg_bonus -= 2
		
	return dmg_bonus

func get_skill_bonus(skill: StringName) -> int:
	var ability = PFProficiency.get_skill_ability(skill)
	var ability_mod = get_ability_modifier(ability)
	var rank = sheet.skills.get(skill, PFMathConstants.ProficiencyRank.UNTRAINED)
	var base_bonus = ability_mod + PFProficiency.calculate_bonus(rank, sheet.level)
		
	return base_bonus + get_condition_modifier(&"skill")

func get_ability_modifier(ability: StringName) -> int:
	match ability:
		&"STR": return attributes.str_mod
		&"DEX": return attributes.dex_mod
		&"CON": return attributes.con_mod
		&"INT": return attributes.int_mod
		&"WIS": return attributes.wis_mod
		&"CHA": return attributes.cha_mod
		_: return 0

func get_speed_land() -> int:
	var current_speed = movement.speed_land
	
	for item in inventory.worn_items + [inventory.held_main_hand, inventory.held_off_hand]:
		if item != null and "speed_penalty" in item:
			var penalty = item.speed_penalty
			if penalty < 0:
				if item is PFArmor and attributes.str_mod >= item.strength_req:
					penalty = mini(0, penalty + 5)
				current_speed += penalty
		
	current_speed += get_condition_modifier(&"speed")
	return maxi(5, current_speed)

func get_wielded_shield() -> PFShield:
	if inventory.held_off_hand is PFShield:
		return inventory.held_off_hand
	if inventory.held_main_hand is PFShield:
		return inventory.held_main_hand
	return null
