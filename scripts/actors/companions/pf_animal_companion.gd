# pf_animal_companion.gd
# Represents a combat-capable animal minion with derived stats scaling from its master.
## Represents an animal companion bound to a player character.
class_name PFAnimalCompanion
extends PFMinion

enum CompanionStage { YOUNG, MATURE, NIMBLE, SAVAGE, INDOMITABLE, SPECIALIZED }

var stage: CompanionStage = CompanionStage.YOUNG
var base_data: Dictionary
var sheet: PFProficiencySheet

# --- INITIALIZATION ---
func _init(p_name: String, p_master: PFActor, db_id: StringName):
	super._init(p_name, p_master, [&"animal"], p_master.level)
	
	var db = PFDatabase.get_instance()
	if db:
		base_data = db.get_animal_companion_data(db_id)
		
		# Animal companions need proficiency tracking like players for their scaling rules
		sheet = PFProficiencySheet.new()
		
		if not base_data.is_empty():
			size_id = StringName(base_data["size_id"])
			calculate_stats()
		else:
			push_error("PFAnimalCompanion: Failed to load data for " + str(db_id))

# --- STATS ---
func set_stage(new_stage: CompanionStage) -> void:
	stage = new_stage
	print("    > %s has grown to stage: %s" % [entity_name, CompanionStage.keys()[stage]])
	calculate_stats()

func update_stats_from_master() -> void:
	level = master.level
	print("    > %s updates stats to match master's level %d." % [entity_name, level])
	calculate_stats()

func calculate_stats() -> void:
	if base_data.is_empty(): return
	
	# Base Ability Modifiers
	var str_mod = base_data["str_mod"]
	var dex_mod = base_data["dex_mod"]
	var con_mod = base_data["con_mod"]
	var int_mod = base_data["int_mod"]
	var wis_mod = base_data["wis_mod"]
	var cha_mod = base_data["cha_mod"]
	
	# Default Proficiencies
	var unarmored_prof = PFMathConstants.ProficiencyRank.TRAINED
	var unarmed_prof = PFMathConstants.ProficiencyRank.TRAINED
	var saving_throw_prof = PFMathConstants.ProficiencyRank.TRAINED
	var perception_prof = PFMathConstants.ProficiencyRank.TRAINED
	var signature_prof = PFMathConstants.ProficiencyRank.TRAINED
	var attack_dice_multiplier = 1
	var attack_damage_bonus = 0
	
	size_id = StringName(base_data["size_id"])
	
	# Stage Overrides
	if stage >= CompanionStage.MATURE:
		str_mod += 1
		dex_mod += 1
		con_mod += 1
		wis_mod += 1
		perception_prof = PFMathConstants.ProficiencyRank.EXPERT
		saving_throw_prof = PFMathConstants.ProficiencyRank.EXPERT
		unarmed_prof = PFMathConstants.ProficiencyRank.EXPERT
		unarmored_prof = PFMathConstants.ProficiencyRank.EXPERT
		signature_prof = PFMathConstants.ProficiencyRank.EXPERT
		attack_dice_multiplier = 2
		
	if stage == CompanionStage.NIMBLE:
		dex_mod += 2
		str_mod += 1
		con_mod += 1
		wis_mod += 1
		unarmored_prof = PFMathConstants.ProficiencyRank.MASTER
		attack_damage_bonus = 1 # Often a generic small bonus
	elif stage == CompanionStage.SAVAGE:
		str_mod += 2
		dex_mod += 1
		con_mod += 1
		wis_mod += 1
		size_id = &"large" # Or whatever the rules say for scaling
		unarmed_prof = PFMathConstants.ProficiencyRank.MASTER
		attack_damage_bonus = 2
	elif stage == CompanionStage.INDOMITABLE or stage == CompanionStage.SPECIALIZED:
		str_mod += 2
		dex_mod += 2
		con_mod += 2
		wis_mod += 2
		size_id = &"large"
		unarmed_prof = PFMathConstants.ProficiencyRank.MASTER
		unarmored_prof = PFMathConstants.ProficiencyRank.MASTER
		attack_dice_multiplier = 3
	
	# Apply Attributes
	attributes.str_mod = str_mod
	attributes.dex_mod = dex_mod
	attributes.con_mod = con_mod
	attributes.int_mod = int_mod
	attributes.wis_mod = wis_mod
	attributes.cha_mod = cha_mod
	
	# Calculate HP: Ancestry HP + ((6 + Con Mod) * Level)
	var ancestry_hp = base_data["ancestry_hp"]
	health.max_hp = ancestry_hp + ((6 + con_mod) * level)
	if health.current_hp == 0 or health.current_hp > health.max_hp:
		health.current_hp = health.max_hp
		
	# Speeds
	movement.speed_land = base_data["speed_land"]
	
	# Apply Proficiencies to Sheet
	sheet.set_skill_rank(&"fortitude", saving_throw_prof)
	sheet.set_skill_rank(&"reflex", saving_throw_prof)
	sheet.set_skill_rank(&"will", saving_throw_prof)
	sheet.set_skill_rank(&"perception", perception_prof)
	sheet.set_armor_rank(PFEquipmentConstants.ArmorCategory.UNARMORED, unarmored_prof)
	sheet.set_weapon_rank(PFEquipmentConstants.WeaponCategory.UNARMED, unarmed_prof)
	
	if base_data["signature_skill"] != "":
		sheet.set_skill_rank(StringName(base_data["signature_skill"]), signature_prof)
		
	# Parse JSON specific fields safely
	if base_data["skills"] and base_data["skills"] != "":
		var parsed_skills = JSON.parse_string(base_data["skills"])
		if parsed_skills:
			for s in parsed_skills:
				if sheet.get_skill_rank(StringName(s)) < PFMathConstants.ProficiencyRank.TRAINED:
					sheet.set_skill_rank(StringName(s), PFMathConstants.ProficiencyRank.TRAINED)

	if base_data["senses"] and base_data["senses"] != "":
		var parsed_senses = JSON.parse_string(base_data["senses"])
		if parsed_senses:
			for sense_int in parsed_senses:
				# Just an example mapping, would need proper PFSense objects later
				if sense_int == PFBiographyConstants.Vision.LOW_LIGHT: senses.vision = PFBiographyConstants.Vision.LOW_LIGHT
				if sense_int == PFBiographyConstants.Vision.DARKVISION: senses.vision = PFBiographyConstants.Vision.DARKVISION
				
	# Apply Unarmed Attacks
	inventory.clear_inventory() # Clear old ones if recalculating
	if base_data["unarmed_attacks"] and base_data["unarmed_attacks"] != "":
		var parsed_attacks = JSON.parse_string(base_data["unarmed_attacks"])
		if parsed_attacks:
			for attack in parsed_attacks:
				var traits_sn: Array[StringName] = []
				if attack.has(&"traits"):
					for t in attack["traits"]: traits_sn.append(StringName(t))
					
				var wpn = PFWeapon.new(
					attack["name"], traits_sn, 1, 0, 
					PFEquipmentConstants.WeaponType.MELEE, 
					PFEquipmentConstants.WeaponCategory.UNARMED, 
					PFEquipmentConstants.WeaponGroup.BRAWLING, 
					attack_dice_multiplier, # Use our multiplier!
					attack["damage_faces"], 
					attack["damage_type"] as PFCombatConstants.DamageType, 
					PFEquipmentConstants.ItemMaterial.STANDARD, 0, 0
				)
				# TODO: Attach the flat attack_damage_bonus dynamically, usually we rely on STR mod but savage/nimble add raw +1/+2 flat
				inventory.add_item(wpn)
				inventory.wield_item(wpn, true) # Auto-wield its own body parts

# --- MINION ACTIONS ---
func support_benefit() -> void:
	if action_economy.actions_remaining > 0:
		action_economy.actions_remaining -= 1
		print("    > %s uses Support Benefit: %s" % [entity_name, base_data.get(&"support_benefit", "None")])
	else:
		print("    > %s has no actions left to Support." % entity_name)

func advanced_maneuver() -> void:
	if stage < CompanionStage.NIMBLE and stage < CompanionStage.SAVAGE:
		print("    > %s is not Nimble or Savage and cannot use an Advanced Maneuver yet." % entity_name)
		return
		
	if action_economy.actions_remaining > 0:
		action_economy.actions_remaining -= 1
		print("    > %s uses Advanced Maneuver: %s" % [entity_name, base_data.get(&"advanced_maneuver", "None")])
	else:
		print("    > %s has no actions left for Advanced Maneuver." % entity_name)
