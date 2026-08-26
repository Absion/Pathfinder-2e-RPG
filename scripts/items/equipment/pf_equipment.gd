# pf_equipment.gd
## Represents permanent equipment like Wands, Rings, Boots.
class_name PFEquipment
extends PFItem

var usage_cooldown: String
var action_script_path: String
var skill_bonus_data: Dictionary

# Active modifiers granted by this equipment
var _active_modifiers: Array[PFModifier] = []

func _init(p_id: String):
	super._init()
	var database = PFDatabase.get_instance()
	if not database: return
	
	var data = database.select_with_bindings("SELECT * FROM equipment WHERE id = ?", [p_id])
	if data and data.size() > 0:
		var item_data = data[0]
		
		id = p_id
		entity_name = item_data.get(&"name", "Unknown Equipment")
		level = item_data.get(&"level", 1)
		base_level = level
		price_cp = item_data.get(&"price_cp", 0)
		base_price_cp = price_cp
		bulk_value = item_data.get(&"bulk", 1)
		base_bulk_value = bulk_value
		
		var raw_traits = item_data.get(&"traits", "")
		if raw_traits != "":
			var trait_strs = raw_traits.split(",")
			for t in trait_strs:
				var trait_name = StringName(t.strip_edges())
				if not traits.has(trait_name):
					traits.append(trait_name)
				
		requires_investment = item_data.get(&"requires_investment", 0) == 1
		usage_cooldown = item_data.get(&"usage_cooldown", "")
		action_script_path = item_data.get(&"action_script_path", "")
		
		var raw_skill_data = item_data.get(&"skill_bonus_data", "{}")
		if raw_skill_data and raw_skill_data != "":
			var parsed_data = JSON.parse_string(raw_skill_data)
			if typeof(parsed_data) == TYPE_DICTIONARY:
				skill_bonus_data = parsed_data

func on_equipped(wearer: PFActor) -> void:
	if not "sheet" in wearer or not wearer.sheet: return
	if not "attributes" in wearer or not wearer.attributes: return
	
	for stat_name in skill_bonus_data:
		var bonus = skill_bonus_data[stat_name]
		var modifier = PFModifier.new(bonus, PFMathConstants.ModifierType.ITEM, entity_name)
		
		match stat_name:
			"ac":
				if "ac_modifiers" in wearer.attributes:
					wearer.attributes.ac_modifiers.add_modifier(modifier)
			"attack":
				if "attack_modifiers" in wearer.attributes:
					wearer.attributes.attack_modifiers.add_modifier(modifier)
			"dc":
				if "dc_modifiers" in wearer.attributes:
					wearer.attributes.dc_modifiers.add_modifier(modifier)
			"fort":
				if "fort_save" in wearer.attributes:
					wearer.attributes.fort_save.add_modifier(modifier)
			"ref":
				if "ref_save" in wearer.attributes:
					wearer.attributes.ref_save.add_modifier(modifier)
			"will":
				if "will_save" in wearer.attributes:
					wearer.attributes.will_save.add_modifier(modifier)
			_:
				# Assume it's a skill
				var _short_name = StringName(stat_name)
				# TODO: Implement PFStat tracking for skills so items can add modifiers
				#if wearer.sheet.skill_modifiers.has(short_name):
				#	wearer.sheet.skill_modifiers[short_name].add_modifier(modifier)
					
		_active_modifiers.append(modifier)

func on_unequipped(wearer: PFActor) -> void:
	if not "sheet" in wearer or not wearer.sheet: return
	if not "attributes" in wearer or not wearer.attributes: return
	
	for modifier in _active_modifiers:
		if "ac_modifiers" in wearer.attributes:
			wearer.attributes.ac_modifiers.remove_modifier_by_source(modifier.source)
		if "attack_modifiers" in wearer.attributes:
			wearer.attributes.attack_modifiers.remove_modifier_by_source(modifier.source)
		if "dc_modifiers" in wearer.attributes:
			wearer.attributes.dc_modifiers.remove_modifier_by_source(modifier.source)
		if "fort_save" in wearer.attributes:
			wearer.attributes.fort_save.remove_modifier_by_source(modifier.source)
		if "ref_save" in wearer.attributes:
			wearer.attributes.ref_save.remove_modifier_by_source(modifier.source)
		if "will_save" in wearer.attributes:
			wearer.attributes.will_save.remove_modifier_by_source(modifier.source)
			
		# TODO: Implement PFStat tracking for skills so items can add modifiers
		#for stat in wearer.sheet.skill_modifiers.values():
		#	stat.remove_modifier_by_source(modifier.source)
			
	_active_modifiers.clear()

