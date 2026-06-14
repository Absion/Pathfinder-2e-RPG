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
var size_id: StringName = &"medium"
var birthplace: StringName = &"unknown"
var nationality: StringName = &"unknown"
var ethnicity: StringName = &"unknown"
var languages: Array[StringName] = []
var ancestry: PFAncestry
var heritage: PFHeritage
var background: PFBackground
var actor_class: PFClass
var deity: PFDeity
var selected_key_ability: StringName = &""
var bonus_language_slots: int = 0
var available_bonus_languages: Array[StringName] = []

var edicts: Array[StringName] = []
var anathema: Array[StringName] = []

# --- FEATS & ABILITIES ---
var feats: Array[PFFeat] = []

# --- PROGRESSION ---
var experience_points: int = 0
var pending_level_up_choices: Array[Dictionary] = []

# --- META CURRENCY ---
var hero_points: int = 1

signal experience_gained(current_xp: int, amount: int)
signal leveled_up(new_level: int, pending_choices: Dictionary)
signal hero_points_changed(current: int)

func _init(p_name: String, p_traits: Array[StringName], p_level: int,
		p_hp: int, p_fort: int, p_ref: int, p_will: int,
		p_speed_land: int = 25, p_speed_fly: int = 0, p_speed_swim: int = 0,
		p_speed_climb: int = 0, p_speed_burrow: int = 0,
		p_description: String = "", 
		p_gender: PFBiographyConstants.Gender = PFBiographyConstants.Gender.UNKNOWN, 
		p_birthplace: StringName = &"unknown", 
		p_nationality: StringName = &"unknown",
		p_ethnicity: StringName = &"unknown",
		p_has_spirit: bool = true):
		
	# Call PFActor initialization
	super._init(p_name, p_traits, p_level, p_hp)
	
	has_spirit = p_has_spirit
	description = p_description
	gender = p_gender
	birthplace = p_birthplace
	nationality = p_nationality
	ethnicity = p_ethnicity
	health.max_hp = p_hp
	health.current_hp = p_hp
	
	attributes = PFAttributesComponent.new()
	attributes.initialize(p_fort, p_ref, p_will)
	add_child(attributes)
	
	movement = PFMovementComponent.new()
	movement.initialize(p_speed_land, p_speed_fly, p_speed_swim, p_speed_climb, p_speed_burrow)
	add_child(movement)
	
	senses = PFSensesComponent.new()
	senses.initialize()
	add_child(senses)
	
	sheet = PFProficiencySheet.new()
	inventory = PFInventory.new(self)
	spellbook = PFSpellbook.new(self)

# DATA SETTERS & BACKGROUND
# ---------------------------------------------------------

func set_description(new_description: String) -> void:
	description = new_description

func set_biography(new_gender: PFBiographyConstants.Gender, new_birthplace: StringName, new_nationality: StringName) -> void:
	gender = new_gender
	birthplace = new_birthplace
	nationality = new_nationality
	print("    > %s's biography updated: PFBiographyConstants.Gender [%s], Birthplace [%s], Nationality [%s]." % [
		entity_name, 
		PFBiographyConstants.Gender.keys()[gender], 
		birthplace, 
		nationality
	])

func set_ethnicity(new_ethnicity: StringName) -> bool:
	var db = PFDatabase.get_instance()
	if db:
		var eth_data = db.get_ethnicity_data(new_ethnicity)
		if not eth_data.is_empty():
			var required = eth_data.get("required_traits", [])
			# Check if character has ALL required traits
			for req_trait in required:
				if not traits.has(StringName(req_trait)):
					push_warning("Cannot set ethnicity %s. Missing required trait: %s" % [new_ethnicity, req_trait])
					return false
	
	ethnicity = new_ethnicity
	print("    > %s's ethnicity is now %s." % [entity_name, ethnicity])
	return true

func apply_ancestry(new_ancestry: PFAncestry) -> void:
	ancestry = new_ancestry
	
	health.max_hp += ancestry.hp 
	health.current_hp = health.max_hp
	size_id = ancestry.size_id
	
	# Apply Ability Boosts / Flaws
	if attributes.use_alternate_ancestry_boosts:
		for b in ancestry.alternate_ancestry_boosts:
			if b != &"FREE" and b != &"free":
				attributes.apply_ancestry_boost(b)
			# FREE boosts will be handled by a pending UI queue in the future
	else:
		for b in ancestry.ability_boosts:
			if b != &"FREE" and b != &"free":
				attributes.apply_ancestry_boost(b)
		for f in ancestry.ability_flaws:
			if f != &"FREE" and f != &"free":
				# In Pathfinder, ancestry flaws directly subtract 1 from the stat block conceptually.
				# Our apply_voluntary_flaw can be reused or we can make apply_ancestry_flaw
				attributes.apply_voluntary_flaw(f) 
	
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

func apply_heritage(new_heritage: PFHeritage) -> void:
	heritage = new_heritage
	
	health.max_hp += heritage.hp_bonus
	health.current_hp = health.max_hp
	
	if heritage.size_id != &"":
		size_id = heritage.size_id
		
	movement.speed_land += heritage.speed_bonus
	
	if heritage.vision_override != -1: # -1 indicates no change
		senses.vision = heritage.vision_override as PFBiographyConstants.Vision
		
	for t in heritage.granted_traits:
		if not traits.has(t):
			traits.append(t)
			
	# Append any granted abilities to the inventory or action components later
	# for ability in heritage.granted_abilities: ...
	
	print("    > %s inherited %s!" % [entity_name, heritage.entity_name])

func add_bonus_language_option(lang: StringName) -> void:
	if not languages.has(lang) and not available_bonus_languages.has(lang):
		available_bonus_languages.append(lang)
		print("    > %s gained access to select %s!" % [entity_name, lang])

func learn_language(lang: StringName) -> void:
	if not languages.has(lang):
		languages.append(lang)
		print("    > %s learned %s!" % [entity_name, lang])
		
		if available_bonus_languages.has(lang):
			available_bonus_languages.erase(lang)

func apply_background(new_background: PFBackground) -> void:
	background = new_background
	for t in background.traits:
		if not traits.has(t):
			traits.append(t)
	print("    > %s was a %s!" % [entity_name, background.entity_name])

func apply_class(class_id: StringName) -> void:
	var db = PFDatabase.get_instance()
	if not db: return
	
	var c_data = db.get_class_data(class_id)
	if c_data.is_empty(): return
	
	actor_class = PFClass.new(
		str(c_data["name"]),
		c_data["hp_per_level"],
		([] as Array[StringName]), # Key abilities parsed below
		c_data["perception_rank"] as PFMathConstants.ProficiencyRank,
		c_data["class_dc_rank"] as PFMathConstants.ProficiencyRank,
		{
			"fort": c_data["save_fort"] as PFMathConstants.ProficiencyRank,
			"ref": c_data["save_ref"] as PFMathConstants.ProficiencyRank,
			"will": c_data["save_will"] as PFMathConstants.ProficiencyRank
		},
		c_data["trained_skills_count"],
		{}, {}, str(c_data.get("description", "")), ([] as Array[StringName]), ([] as Array[StringName]),
		c_data["is_spellcaster"] == 1,
		c_data["caster_type"] as PFMagicConstants.CasterType,
		c_data["spell_tradition"] as PFMagicConstants.MagicTradition,
		c_data["spell_proficiency"] as PFMathConstants.ProficiencyRank,
		c_data["spell_progression"] as PFMagicConstants.SpellProgression
	)
	
	if c_data["key_abilities"] and c_data["key_abilities"] != "":
		var parsed = JSON.parse_string(c_data["key_abilities"])
		if parsed:
			for k in parsed: actor_class.key_abilities.append(StringName(k))
			
	# Apply HP
	health.max_hp += actor_class.hp_per_level * level
	health.current_hp = health.max_hp
	
	# Apply Proficiencies
	sheet.set_skill_rank(&"perception", actor_class.perception_rank)
	sheet.set_save_rank(&"fort", actor_class.saving_throws["fort"])
	sheet.set_save_rank(&"ref", actor_class.saving_throws["ref"])
	sheet.set_save_rank(&"will", actor_class.saving_throws["will"])
	
	if actor_class.is_spellcaster:
		spellbook = PFSpellbook.new(self)
		spellbook.restore_daily_slots()
		
	print("    > %s is now a Level %d %s! (Max HP: %d)" % [entity_name, level, actor_class.entity_name, health.max_hp])

func apply_deity(new_deity: PFDeity) -> void:
	deity = new_deity
	print("%s selected Deity: %s" % [entity_name, new_deity.entity_name])

func has_feat(feat_id: StringName) -> bool:
	for f in feats:
		if f.id == feat_id:
			return true
	return false

# ---------------------------------------------------------
# THE UNIFIED MATH DELEGATES
# ---------------------------------------------------------

func get_ac() -> int:
	var base_ac = 10
	var armor = null
	var armor_items = inventory.worn_items.filter(func(i): return i is PFArmor)
	if armor_items.size() > 0:
		armor = armor_items[0]
	if not armor: armor = PFArmor.new("Unarmored", [], 0, 0.0, PFEquipmentConstants.ArmorCategory.UNARMORED, PFEquipmentConstants.ArmorGroup.UNARMORED, 0, 99)
	
	var capped_dex = mini(attributes.dex_mod, armor.dex_cap)
	base_ac += capped_dex + armor.ac_bonus + sheet.get_armor_bonus(armor.category, level)
	if armor.is_broken(): base_ac -= 2 
	return base_ac + get_condition_modifier(&"ac")

func get_strike_bonus(weapon: PFWeapon) -> int:
	var base_bonus = 0
	var stat_mod = attributes.dex_mod if weapon.weapon_type == PFEquipmentConstants.WeaponType.RANGED else attributes.str_mod
	if weapon.has_trait(&"finesse") and attributes.dex_mod > attributes.str_mod:
		stat_mod = attributes.dex_mod
	elif weapon.has_trait(&"brutal"):
		stat_mod = attributes.str_mod
		
	var category_to_use = weapon.category
	if weapon.has_trait(&"unarmed"):
		category_to_use = PFEquipmentConstants.WeaponCategory.UNARMED
		
	base_bonus = stat_mod + sheet.get_weapon_bonus(category_to_use, level)
	base_bonus += weapon.potency_bonus 
	
	if weapon.has_trait(&"kickback") and attributes.str_mod < 2:
		base_bonus -= 2
	
	if weapon.is_broken():
		base_bonus -= 2
	return base_bonus + get_condition_modifier(&"attack")

func get_class_dc() -> int:
	if not actor_class:
		return 10
	
	var rank = actor_class.class_dc_rank
	var prof_bonus = PFProficiency.calculate_bonus(rank, level)
	
	var key_attr = selected_key_ability
	if key_attr == &"" and actor_class.key_abilities.size() > 0:
		key_attr = actor_class.key_abilities[0]
		
	var stat_mod = get_ability_modifier(key_attr)
		
	return 10 + prof_bonus + stat_mod

func get_spell_dc() -> int:
	if not actor_class or not actor_class.is_spellcaster: return 10
	
	var prof_bonus = PFProficiency.calculate_bonus(actor_class.spell_proficiency, level)
	
	var key_attr = selected_key_ability
	if key_attr == &"" and actor_class.key_abilities.size() > 0:
		key_attr = actor_class.key_abilities[0]
		
	var stat_mod = get_ability_modifier(key_attr)
	return 10 + prof_bonus + stat_mod + attributes.status_bonus_to_dc + attributes.item_bonus_to_dc - attributes.circumstance_penalty_to_dc - attributes.status_penalty_to_dc

func get_spell_attack() -> int:
	if not actor_class or not actor_class.is_spellcaster: return 0
	
	var prof_bonus = PFProficiency.calculate_bonus(actor_class.spell_proficiency, level)
	
	var key_attr = selected_key_ability
	if key_attr == &"" and actor_class.key_abilities.size() > 0:
		key_attr = actor_class.key_abilities[0]
		
	var stat_mod = get_ability_modifier(key_attr)
	return prof_bonus + stat_mod + attributes.status_bonus_to_attack + attributes.item_bonus_to_attack - attributes.circumstance_penalty_to_attack - attributes.status_penalty_to_attack

func get_strike_damage_bonus(weapon: PFWeapon) -> int:
	var dmg_bonus = 0
	if weapon.weapon_type == PFEquipmentConstants.WeaponType.MELEE or weapon.can_be_thrown():
		dmg_bonus = attributes.str_mod 
	elif weapon.has_trait(&"propulsive"):
		if attributes.str_mod < 0:
			dmg_bonus = attributes.str_mod
		else:
			dmg_bonus = int(attributes.str_mod / 2.0)
			
	if weapon.has_trait(&"kickback"):
		dmg_bonus += 1
		
	if weapon.has_trait(&"twin"):
		var inv = get("inventory") as PFInventory
		if inv and inv.main_hand_item and inv.off_hand_item:
			var main = inv.main_hand_item as PFWeapon
			var off = inv.off_hand_item as PFWeapon
			if main and off and main.base_name == off.base_name:
				dmg_bonus += weapon.dice_amount # +1 per damage die, not just +1. Wait, let me check the Twin trait... wait, Twin says "+1 circumstance bonus per damage die". Let's do that!
	
	if weapon.is_broken():
		dmg_bonus -= 2
		
	return dmg_bonus

func get_skill_bonus(skill: StringName) -> int:
	var ability = PFProficiency.get_skill_ability(skill)
	var ability_mod = get_ability_modifier(ability)
	var base_bonus = ability_mod + sheet.get_skill_bonus(skill, level)
		
	return base_bonus + get_condition_modifier(&"skill")

func get_maneuver_bonus(maneuver: StringName, weapon: PFWeapon = null) -> int:
	var base_bonus = get_skill_bonus(&"athletics")
	
	if weapon and weapon.has_trait(maneuver):
		# If the weapon has the maneuver trait, you can use its item bonus.
		var weapon_bonus = weapon.potency_bonus
		
		# Can use Finesse for maneuvers if the weapon has Finesse
		if weapon.has_trait(&"finesse") and attributes.dex_mod > attributes.str_mod:
			# Skill bonus already includes STR. Let's substitute DEX for STR.
			base_bonus = base_bonus - attributes.str_mod + attributes.dex_mod
			
		base_bonus += weapon_bonus
		
	return base_bonus

func get_ability_modifier(ability: StringName) -> int:
	match ability:
		&"STR": return attributes.str_mod
		&"DEX": return attributes.dex_mod
		&"CON": return attributes.con_mod
		&"INT": return attributes.int_mod
		&"WIS": return attributes.wis_mod
		&"CHA": return attributes.cha_mod
		_: return 0

# ---------------------------------------------------------
# SPELLCASTING & CLASS HELPERS
# ---------------------------------------------------------
func get_spellcasting_mod() -> int:
	# Virtual helper for familiars to query spellcasting mod until classes are implemented
	# Returns the highest mental attribute modifier
	return max(attributes.int_mod, max(attributes.wis_mod, attributes.cha_mod))

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

# ---------------------------------------------------------
# PROGRESSION
# ---------------------------------------------------------
func gain_experience(amount: int) -> void:
	if amount <= 0: return
	
	experience_points += amount
	experience_gained.emit(experience_points, amount)
	print("    > %s gained %d XP! (Total: %d/1000)" % [entity_name, amount, experience_points])
	
	while experience_points >= 1000:
		experience_points -= 1000
		var choices = PFLevelUpManager.level_up(self)
		pending_level_up_choices.append(choices)
		leveled_up.emit(level, choices)

# ---------------------------------------------------------
# HERO POINTS
# ---------------------------------------------------------
func gain_hero_point() -> void:
	hero_points = mini(3, hero_points + 1)
	hero_points_changed.emit(hero_points)
	print("    > %s gained a Hero Point! (Total: %d)" % [entity_name, hero_points])

func spend_hero_point() -> bool:
	if hero_points > 0:
		hero_points -= 1
		hero_points_changed.emit(hero_points)
		print("    > %s spent a Hero Point! (Remaining: %d)" % [entity_name, hero_points])
		return true
	print("    > %s has no Hero Points to spend!" % entity_name)
	return false

func heroic_reroll() -> int:
	if spend_hero_point():
		var new_roll = randi_range(1, 20)
		var final_roll = PFGameMath.apply_keeley_hero_point_reroll(new_roll)
		print("    > %s invokes a Heroic Reroll! Raw d20 roll: %d | Final d20 result (Keeley Rule): %d" % [entity_name, new_roll, final_roll])
		return final_roll
	return -1 # Represents failure to reroll

func heroic_recovery() -> bool:
	if hero_points > 0:
		print("    > %s spends ALL their Hero Points (%d) for a Heroic Recovery!" % [entity_name, hero_points])
		hero_points = 0
		hero_points_changed.emit(hero_points)
		
		# Remove dying condition, stabilize at 0 HP (if they aren't already conscious)
		if has_condition("dying"):
			remove_condition("dying")
			print("    > %s loses the Dying condition and stabilizes at 0 HP!" % entity_name)
			
			# Ensure they are at least at 0 HP and unconscious, not dead
			if health.current_hp < 0:
				health.current_hp = 0
			
			if not has_condition("unconscious"):
				apply_condition(PFCondition.create("unconscious", 1))
				
		return true
	print("    > %s has no Hero Points for a Heroic Recovery!" % entity_name)
	return false
