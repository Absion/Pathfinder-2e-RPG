# pf_character_creation_ui.gd
class_name PFCharacterCreationUI
extends CanvasLayer

var manager: PFCharacterCreationManager
var db: PFDatabase

var main_panel: PanelContainer
var hbox: HBoxContainer
var form_layout: VBoxContainer
var info_layout: VBoxContainer
var info_title: Label
var info_desc: RichTextLabel

# UI References
var line_name: LineEdit
var opt_gender: OptionButton
var opt_ancestry: OptionButton
var opt_heritage: OptionButton
var opt_ethnicity: OptionButton
var opt_nationality: OptionButton
var opt_birthplace: OptionButton
var opt_background: OptionButton
var opt_class: OptionButton
var btn_finalize: Button

# Dynamic UI Containers & Elements
var chk_alt_boosts: CheckBox
var ability_container: VBoxContainer
var free_warning_label: Label
var attr_labels: Dictionary = {}
var int_mod: int = 0
var languages_container: VBoxContainer
var skills_container: VBoxContainer

var ancestry_boost_opts: Array[OptionButton] = []
var background_boost_opts: Array[OptionButton] = []
var class_boost_opts: Array[OptionButton] = []
var free_boost_opts: Array[OptionButton] = []
var language_opts: Array[OptionButton] = []
var skill_opts: Array[OptionButton] = []

# Caches
var _ancestries: Array[Dictionary] = []
var _heritages: Array[Dictionary] = []
var _backgrounds: Array[Dictionary] = []
var _classes: Array[Dictionary] = []
var _ethnicities: Array[Dictionary] = []
var _regions: Array[Dictionary] = []

func _init():
	manager = PFCharacterCreationManager.new()
	
func _ready():
	db = PFDatabase.get_instance()
	_build_ui()
	_rebuild_languages()
	_rebuild_skills()
	_populate_dropdowns()
	_rebuild_abilities()
	_rebuild_languages()
	_rebuild_skills()
	_update_ui_state()
	line_name.grab_focus()

func _build_ui():
	var margin_container = MarginContainer.new()
	add_child(margin_container)
	margin_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin_container.add_theme_constant_override("margin_left", 50)
	margin_container.add_theme_constant_override("margin_top", 50)
	margin_container.add_theme_constant_override("margin_right", 50)
	margin_container.add_theme_constant_override("margin_bottom", 50)
	
	main_panel = PanelContainer.new()
	margin_container.add_child(main_panel)
	
	hbox = HBoxContainer.new()
	main_panel.add_child(hbox)
	
	var scroll_container = ScrollContainer.new()
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_stretch_ratio = 1.5
	scroll_container.custom_minimum_size = Vector2(450, 0)
	hbox.add_child(scroll_container)
	
	form_layout = VBoxContainer.new()
	form_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(form_layout)
	
	var title = Label.new()
	title.text = "Pathfinder 2e Character Creator"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	form_layout.add_child(title)
	
	# Info Panel setup
	var info_panel = PanelContainer.new()
	info_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_panel.custom_minimum_size = Vector2(300, 0)
	hbox.add_child(info_panel)
	
	info_layout = VBoxContainer.new()
	info_panel.add_child(info_layout)
	
	info_title = Label.new()
	info_title.text = "Details"
	info_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_layout.add_child(info_title)
	
	info_desc = RichTextLabel.new()
	info_desc.text = "Hover or select an option to see details."
	info_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_desc.bbcode_enabled = true
	info_desc.fit_content = false
	info_layout.add_child(info_desc)
	
	# Bio Section
	_build_section_header("1. Biography")
	line_name = _add_input_field("Character Name *", "e.g. Arthur")
	line_name.text_changed.connect(_on_name_changed)
	
	opt_gender = _add_dropdown("Gender")
	opt_gender.add_item("--- Select Gender ---", PFBiographyConstants.Gender.UNKNOWN)
	opt_gender.set_item_disabled(0, true)
	opt_gender.add_item("Male", PFBiographyConstants.Gender.MALE)
	opt_gender.add_item("Female", PFBiographyConstants.Gender.FEMALE)
	opt_gender.add_item("Non-Binary", PFBiographyConstants.Gender.NON_BINARY)
	opt_gender.item_selected.connect(_on_gender_selected)
	opt_gender.selected = 0
	
	opt_nationality = _add_dropdown("Nationality")
	opt_nationality.item_selected.connect(_on_nationality_selected)
	
	opt_birthplace = _add_dropdown("Birthplace")
	opt_birthplace.item_selected.connect(_on_birthplace_selected)
	
	# Ancestry Section
	_build_section_header("2. Ancestry & Heritage")
	opt_ancestry = _add_dropdown("Ancestry *")
	opt_ancestry.item_selected.connect(_on_ancestry_selected)
	
	opt_heritage = _add_dropdown("Heritage")
	opt_heritage.add_item("--- Select Heritage ---", -1)
	opt_heritage.set_item_disabled(0, true)
	opt_heritage.item_selected.connect(_on_heritage_selected)
	opt_heritage.disabled = true
	opt_heritage.mouse_default_cursor_shape = Control.CURSOR_ARROW
	opt_heritage.selected = 0
	
	opt_ethnicity = _add_dropdown("Ethnicity (Ancestry Restricted)")
	opt_ethnicity.add_item("--- Select Ethnicity ---", -1)
	opt_ethnicity.set_item_disabled(0, true)
	opt_ethnicity.item_selected.connect(_on_ethnicity_selected)
	opt_ethnicity.disabled = true
	opt_ethnicity.mouse_default_cursor_shape = Control.CURSOR_ARROW
	opt_ethnicity.selected = 0
	
	# Background Section
	_build_section_header("3. Background")
	opt_background = _add_dropdown("Background *")
	opt_background.item_selected.connect(_on_background_selected)
	opt_background.disabled = true
	opt_background.mouse_default_cursor_shape = Control.CURSOR_ARROW
	
	# Class Section
	_build_section_header("4. Class")
	opt_class = _add_dropdown("Class *")
	opt_class.item_selected.connect(_on_class_selected)
	opt_class.disabled = true
	opt_class.mouse_default_cursor_shape = Control.CURSOR_ARROW
	
	# Attributes Section (PF2e Remaster)
	_build_section_header("5. Attribute Modifiers")
	chk_alt_boosts = CheckBox.new()
	chk_alt_boosts.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	chk_alt_boosts.text = "Use Alternate Ancestry Boosts (2 Free)"
	chk_alt_boosts.tooltip_text = "Replaces the ancestry's standard boosts and flaws with two free attribute boosts."
	chk_alt_boosts.toggled.connect(_on_alt_boosts_toggled)
	form_layout.add_child(chk_alt_boosts)
	
	ability_container = VBoxContainer.new()
	form_layout.add_child(ability_container)
	
	free_warning_label = Label.new()
	free_warning_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	free_warning_label.visible = false
	form_layout.add_child(free_warning_label)
	
	# Languages Section
	_build_section_header("6. Languages")
	languages_container = VBoxContainer.new()
	form_layout.add_child(languages_container)
	
	# Skills Section
	_build_section_header("7. Skills")
	skills_container = VBoxContainer.new()
	form_layout.add_child(skills_container)
	
	# Finalize
	form_layout.add_spacer(false)
	btn_finalize = Button.new()
	btn_finalize.text = "Finish & Generate Character"
	btn_finalize.disabled = true
	btn_finalize.tooltip_text = "Fill out Biography, Ancestry, Background, and Class to continue."
	btn_finalize.mouse_default_cursor_shape = Control.CURSOR_ARROW
	btn_finalize.pressed.connect(_on_finalize_pressed)
	form_layout.add_child(btn_finalize)

func _build_section_header(text: String):
	var lbl = Label.new()
	lbl.text = "\n" + text
	lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	form_layout.add_child(lbl)

func _add_input_field(label_text: String, placeholder: String = "") -> LineEdit:
	var container = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(200, 0)
	container.add_child(lbl)
	
	var input = LineEdit.new()
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.clear_button_enabled = true
	input.caret_blink = true
	if placeholder != "":
		input.placeholder_text = placeholder
	container.add_child(input)
	
	form_layout.add_child(container)
	return input

func _add_dropdown(label_text: String) -> OptionButton:
	var container = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(200, 0)
	container.add_child(lbl)
	
	var opt = OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	container.add_child(opt)
	
	form_layout.add_child(container)
	return opt

func _populate_dropdowns():
	# Populate Ancestries
	opt_ancestry.add_item("--- Select Ancestry ---", -1)
	opt_ancestry.set_item_disabled(0, true)
	_ancestries = db.get_all_ancestries()
	for i in range(_ancestries.size()):
		opt_ancestry.add_item(_ancestries[i]["name"], i)
		opt_ancestry.set_item_metadata(i+1, _ancestries[i]["id"])
	opt_ancestry.selected = 0
		
	# Populate Backgrounds
	opt_background.add_item("--- Select Background ---", -1)
	opt_background.set_item_disabled(0, true)
	_backgrounds = db.get_all_backgrounds()
	for i in range(_backgrounds.size()):
		opt_background.add_item(_backgrounds[i]["name"], i)
		opt_background.set_item_metadata(i+1, _backgrounds[i]["id"])
	opt_background.selected = 0
		
	# Populate Classes
	opt_class.add_item("--- Select Class ---", -1)
	opt_class.set_item_disabled(0, true)
	_classes = db.get_all_classes()
	for i in range(_classes.size()):
		opt_class.add_item(_classes[i]["name"], i)
		opt_class.set_item_metadata(i+1, _classes[i]["id"])
	opt_class.selected = 0
		
	# Populate Nationalities and Birthplaces
	opt_nationality.add_item("--- Select Nationality ---", -1)
	opt_nationality.set_item_disabled(0, true)
	opt_birthplace.add_item("--- Select Birthplace ---", -1)
	opt_birthplace.set_item_disabled(0, true)
	_regions = db.get_all_regions()
	for i in range(_regions.size()):
		opt_nationality.add_item(_regions[i]["name"], i)
		opt_nationality.set_item_metadata(i+1, _regions[i]["id"])
		opt_birthplace.add_item(_regions[i]["name"], i)
		opt_birthplace.set_item_metadata(i+1, _regions[i]["id"])
	opt_nationality.selected = 0
	opt_birthplace.selected = 0

func _update_info_panel(title: String, desc: String, extra_stats: String = ""):
	info_title.text = title
	var full_text = desc
	if extra_stats != "":
		full_text += "\n\n[color=lightblue]" + extra_stats + "[/color]"
	info_desc.text = full_text

func _format_ancestry_info(a_id: String) -> String:
	var raw = db.get_ancestry_raw_data(a_id)
	var ancestry = db.get_ancestry(a_id)
	if ancestry == null:
		return "No details available."
		
	var out: Array[String] = []
	
	# Overview description
	var desc = raw.get("description", "")
	if desc == "":
		desc = raw.get("ancestry_description", "")
	if desc != "":
		out.append(desc)
		out.append("")
		
	# Mechanics summary
	out.append("[b][color=gold]Ancestry Mechanics[/color][/b]")
	out.append("[b]• Hit Points:[/b] %d" % ancestry.hp)
	out.append("[b]• Size:[/b] %s" % str(ancestry.size_id).capitalize())
	
	var speed_str = "%d feet" % ancestry.speed
	if ancestry.speed_fly > 0: speed_str += ", Fly %d ft" % ancestry.speed_fly
	if ancestry.speed_swim > 0: speed_str += ", Swim %d ft" % ancestry.speed_swim
	if ancestry.speed_climb > 0: speed_str += ", Climb %d ft" % ancestry.speed_climb
	if ancestry.speed_burrow > 0: speed_str += ", Burrow %d ft" % ancestry.speed_burrow
	out.append("[b]• Speed:[/b] %s" % speed_str)
	
	var boosts_raw = str(raw.get("boosts", ""))
	if boosts_raw == "":
		var b_list: Array[String] = []
		for b in ancestry.ability_boosts:
			b_list.append(str(b).capitalize())
		boosts_raw = ", ".join(b_list)
	out.append("[b]• Ability Boosts:[/b] [color=lightgreen]%s[/color]" % boosts_raw)
	
	var flaws_raw = str(raw.get("flaws", ""))
	if flaws_raw == "":
		flaws_raw = "None"
	out.append("[b]• Ability Flaw:[/b] [color=coral]%s[/color]" % flaws_raw)
	
	var vision_str = "Normal"
	match ancestry.vision:
		PFBiographyConstants.Vision.LOW_LIGHT: vision_str = "Low-Light Vision"
		PFBiographyConstants.Vision.DARKVISION: vision_str = "Darkvision"
		_: vision_str = "Normal"
	var senses_raw = str(raw.get("additional_senses", "")).strip_edges()
	if senses_raw != "" and senses_raw != "None":
		vision_str += ", " + senses_raw
	out.append("[b]• Senses:[/b] %s" % vision_str)
	
	var langs_raw = str(raw.get("known_languages", ""))
	if langs_raw == "":
		langs_raw = "Common"
	out.append("[b]• Languages:[/b] %s" % langs_raw)
	
	var traits_raw = str(raw.get("traits", "")).trim_prefix("[").trim_suffix("]").replace('"', '')
	out.append("[b]• Traits:[/b] [color=lightblue]%s[/color]" % traits_raw)
	out.append("")
	
	# Lore Details
	var phys_desc = str(raw.get("physical_description", ""))
	if phys_desc != "":
		out.append("[b][color=gold]Physical Description[/color][/b]")
		out.append(phys_desc)
		out.append("")
		
	var soc_desc = str(raw.get("societal_description", ""))
	if soc_desc != "":
		out.append("[b][color=gold]Society & Culture[/color][/b]")
		out.append(soc_desc)
		out.append("")
		
	var beliefs = str(raw.get("common_beliefs", ""))
	if beliefs != "":
		out.append("[b][color=gold]Beliefs & Religion[/color][/b]")
		out.append(beliefs)
		out.append("")
		
	var names_raw = str(raw.get("common_names", ""))
	if names_raw != "":
		out.append("[b][color=gold]Sample Names[/color][/b]")
		var parsed = JSON.parse_string(names_raw)
		if typeof(parsed) == TYPE_DICTIONARY:
			var label_map = {
				"male": "Male Names",
				"female": "Female Names",
				"clan": "Family / Clan Names",
				"family": "Family / Clan Names",
				"names": "Sample Names"
			}
			# ⚡ Bolt: Iterate directly over the dictionary to avoid allocating an Array via .keys()
			for cat in parsed:
				var label = label_map.get(str(cat).to_lower(), str(cat).capitalize() + " Names")
				var names_list: Array = parsed[cat]
				var formatted_list: Array[String] = []
				for n in names_list:
					formatted_list.append(str(n))
				out.append("[b]• %s:[/b] %s" % [label, ", ".join(formatted_list)])
		else:
			out.append(names_raw)
			
	return "\n".join(out)

func _parse_array_field(val: Variant) -> Array[String]:
	var result: Array[String] = []
	if val == null: return result
	if val is Array:
		for item in val: result.append(str(item).strip_edges())
		return result
	var s = str(val).strip_edges()
	if s == "" or s == "[]": return result
	if s.begins_with("[") and s.contains('"'):
		var parsed = JSON.parse_string(s)
		if typeof(parsed) == TYPE_ARRAY:
			for item in parsed: result.append(str(item).strip_edges())
			return result
	s = s.trim_prefix("[").trim_suffix("]")
	for part in s.split(","):
		var cleaned = part.strip_edges().trim_prefix('"').trim_suffix('"').trim_prefix("'").trim_suffix("'")
		if cleaned != "":
			result.append(cleaned)
	return result

func _format_feature_label(feature_id: String) -> String:
	var s = feature_id.strip_edges()
	var words = s.split("_")
	var formatted_words: Array[String] = []
	for w in words:
		if w != "":
			var low = w.to_lower()
			if low in ["1d4", "1d6", "1d8", "1d10", "1d12", "5ft", "15ft", "30ft"]:
				formatted_words.append("(%s)" % w.to_upper())
			elif low == "2":
				formatted_words.append("2")
			else:
				formatted_words.append(w.capitalize())
	return " ".join(formatted_words)

func _format_heritage_info(h_id: String) -> String:
	var raw = db.get_heritage_raw_data(h_id)
	if raw.is_empty():
		return "No details available."
		
	var out: Array[String] = []
	var desc = raw.get("description", "")
	if desc != "":
		out.append(desc)
		out.append("")
		
	out.append("[b][color=gold]Heritage Mechanics[/color][/b]")
	
	var is_versatile = int(raw.get("is_versatile", 0)) == 1
	var anc_id = str(raw.get("ancestry_id", ""))
	if is_versatile:
		out.append("[b]• Type:[/b] [color=lightblue]Versatile Heritage[/color] (Can be chosen by any ancestry)")
	else:
		var anc_display = anc_id.capitalize() if anc_id != "" else "Ancestry"
		out.append("[b]• Type:[/b] %s Heritage" % anc_display)
		
	var rarity = int(raw.get("rarity", 0))
	var rarity_names = ["Common", "Uncommon", "Rare", "Unique"]
	var rarity_str = rarity_names[rarity] if rarity >= 0 and rarity < rarity_names.size() else "Common"
	if rarity > 0:
		out.append("[b]• Rarity:[/b] [color=gold]%s[/color]" % rarity_str)
	else:
		out.append("[b]• Rarity:[/b] %s" % rarity_str)
		
	var hp_b = int(raw.get("hp_bonus", 0))
	if hp_b > 0:
		out.append("[b]• Hit Points:[/b] +%d HP" % hp_b)
		
	var spd_b = int(raw.get("speed_bonus", 0))
	if spd_b > 0:
		out.append("[b]• Speed Bonus:[/b] +%d feet" % spd_b)
		
	# Only display vision if it grants darkvision or low-light vision
	var vis_ovr = int(raw.get("vision_override", 0))
	if is_versatile or vis_ovr > 0:
		if vis_ovr == 1:
			out.append("[b]• Senses:[/b] Grants Low-Light Vision")
		elif vis_ovr == 2:
			out.append("[b]• Senses:[/b] Grants Darkvision")
		
	var g_traits = raw.get("granted_traits", "")
	if g_traits != null and str(g_traits) != "" and str(g_traits) != "[]":
		var parsed = _parse_array_field(g_traits)
		if not parsed.is_empty():
			var clean: Array[String] = []
			for t in parsed: clean.append(t.capitalize())
			out.append("[b]• Granted Traits:[/b] [color=lightblue]%s[/color]" % ", ".join(clean))
			
	var g_abil = raw.get("granted_abilities", "")
	if g_abil != null and str(g_abil) != "" and str(g_abil) != "[]":
		var parsed = _parse_array_field(g_abil)
		if not parsed.is_empty():
			var clean: Array[String] = []
			for a in parsed:
				clean.append(_format_feature_label(a))
			out.append("[b]• Granted Features:[/b] [color=lightgreen]%s[/color]" % ", ".join(clean))
			
	return "\n".join(out)

func _rank_name(rank_val: int) -> String:
	match rank_val:
		PFMathConstants.ProficiencyRank.UNTRAINED: return "Untrained"
		PFMathConstants.ProficiencyRank.TRAINED: return "Trained"
		PFMathConstants.ProficiencyRank.EXPERT: return "Expert"
		PFMathConstants.ProficiencyRank.MASTER: return "Master"
		PFMathConstants.ProficiencyRank.LEGENDARY: return "Legendary"
		_: return "Untrained"

func _format_background_info(bg_id: String) -> String:
	var raw = db.get_background_raw_data(bg_id)
	if raw.is_empty():
		return "No details available."
		
	var out: Array[String] = []
	var desc = raw.get("description", "")
	if desc != "":
		out.append(desc)
		out.append("")
		
	out.append("[b][color=gold]Background Mechanics[/color][/b]")
	
	# Boosts
	var boosts_raw = str(raw.get("boosts", "")).strip_edges()
	if boosts_raw != "":
		var boost_parts = _parse_boost_list(boosts_raw)
		var clean_boosts: Array[String] = []
		for b in boost_parts:
			if b == "FREE":
				clean_boosts.append("One Free Attribute Boost")
			elif "|" in b:
				var split_b = b.split("|")
				var opt_names: Array[String] = []
				for sb in split_b: opt_names.append(_normalize_stat(sb))
				clean_boosts.append(" or ".join(opt_names))
			else:
				clean_boosts.append(_normalize_stat(b))
		out.append("[b]• Attribute Boosts:[/b] [color=lightgreen]%s[/color]" % ", ".join(clean_boosts))
		
	# Skills
	var skills_raw = str(raw.get("skills", "")).strip_edges()
	if skills_raw != "":
		var skill_parts = _parse_skill_names(skills_raw)
		out.append("[b]• Trained Skill:[/b] [color=lightgreen]%s[/color]" % ", ".join(skill_parts))
		
	# Lores
	var lores_raw = str(raw.get("lores", "")).strip_edges()
	if lores_raw != "":
		var lore_parts = _parse_skill_names(lores_raw)
		var clean_lores: Array[String] = []
		for l in lore_parts:
			var l_str = l.replace("_", " ").capitalize()
			if not l_str.to_lower().ends_with("lore"): l_str += " Lore"
			clean_lores.append(l_str)
		out.append("[b]• Trained Lore:[/b] [color=lightblue]%s[/color]" % ", ".join(clean_lores))
		
	# Granted Abilities / Feats
	var feats_raw = str(raw.get("granted_abilities", "")).strip_edges()
	if feats_raw != "" and feats_raw != "[]":
		var feat_parts = _parse_array_field(feats_raw)
		if not feat_parts.is_empty():
			var clean_feats: Array[String] = []
			for f in feat_parts: clean_feats.append(_format_feature_label(f))
			out.append("[b]• Skill Feat:[/b] [color=gold]%s[/color]" % ", ".join(clean_feats))
			
	# Traits
	var traits_raw = str(raw.get("traits", "")).strip_edges().trim_prefix("[").trim_suffix("]").replace('"', '')
	if traits_raw != "":
		out.append("[b]• Traits:[/b] [color=lightblue]%s[/color]" % traits_raw)
		
	return "\n".join(out)

func _format_class_info(class_id: String) -> String:
	var raw = db.get_class_raw_data(class_id)
	var c = db.get_pf_class(class_id)
	if raw.is_empty() and c == null:
		return "No details available."
		
	var out: Array[String] = []
	var desc = raw.get("description", "")
	if desc != "":
		out.append(desc)
		out.append("")
		
	out.append("[b][color=gold]Class Mechanics[/color][/b]")
	
	# HP per level
	var hp = raw.get("hp_per_level", 8)
	out.append("[b]• Hit Points per Level:[/b] %d + Constitution modifier" % hp)
	
	# Key Attribute
	var key_raw = str(raw.get("key_abilities", "")).strip_edges()
	if key_raw != "":
		var keys = _parse_boost_list(key_raw)
		var key_display: Array[String] = []
		for k in keys:
			if "|" in k:
				var sp = k.split("|")
				var opt_k: Array[String] = []
				for p in sp: opt_k.append(_normalize_stat(p))
				key_display.append(" or ".join(opt_k))
			elif k == "FREE":
				key_display.append("Choice of Attribute")
			else:
				key_display.append(_normalize_stat(k))
		out.append("[b]• Key Attribute:[/b] [color=lightgreen]%s[/color]" % ", ".join(key_display))
		
	out.append("")
	out.append("[b][color=gold]Initial Proficiencies[/color][/b]")
	
	# Perception
	var perc_rank = int(raw.get("perception_rank", 1))
	out.append("[b]• Perception:[/b] %s" % _rank_name(perc_rank))
	
	# Saving Throws
	var save_f = int(raw.get("save_fort", 1))
	var save_r = int(raw.get("save_ref", 1))
	var save_w = int(raw.get("save_will", 1))
	out.append("[b]• Saving Throws:[/b] Fortitude [color=lightblue]%s[/color], Reflex [color=lightblue]%s[/color], Will [color=lightblue]%s[/color]" % [
		_rank_name(save_f), _rank_name(save_r), _rank_name(save_w)
	])
	
	# Class DC
	var dc_rank = int(raw.get("class_dc_rank", 1))
	out.append("[b]• Class DC:[/b] %s" % _rank_name(dc_rank))
	
	# Trained Skills Count
	var skills_count = int(raw.get("trained_skills_count", 2))
	out.append("[b]• Trained Skills:[/b] %d + Intelligence modifier" % skills_count)
	
	out.append("")
	out.append("[b][color=gold]Attacks & Defenses[/color][/b]")
	
	# Weapons
	var w_un = int(raw.get("weapon_unarmed", 1))
	var w_si = int(raw.get("weapon_simple", 1))
	var w_ma = int(raw.get("weapon_martial", 0))
	var w_ad = int(raw.get("weapon_advanced", 0))
	var weapons_desc: Array[String] = []
	if w_un > 0: weapons_desc.append("%s in Unarmed" % _rank_name(w_un))
	if w_si > 0: weapons_desc.append("%s in Simple Weapons" % _rank_name(w_si))
	if w_ma > 0: weapons_desc.append("%s in Martial Weapons" % _rank_name(w_ma))
	if w_ad > 0: weapons_desc.append("%s in Advanced Weapons" % _rank_name(w_ad))
	if weapons_desc.is_empty(): weapons_desc.append("Untrained in all weapons")
	out.append("[b]• Weapons:[/b] %s" % ", ".join(weapons_desc))
	
	# Armor
	var a_un = int(raw.get("armor_unarmored", 1))
	var a_li = int(raw.get("armor_light", 0))
	var a_me = int(raw.get("armor_medium", 0))
	var a_he = int(raw.get("armor_heavy", 0))
	var armor_desc: Array[String] = []
	if a_un > 0: armor_desc.append("%s in Unarmored Defense" % _rank_name(a_un))
	if a_li > 0: armor_desc.append("%s in Light Armor" % _rank_name(a_li))
	if a_me > 0: armor_desc.append("%s in Medium Armor" % _rank_name(a_me))
	if a_he > 0: armor_desc.append("%s in Heavy Armor" % _rank_name(a_he))
	if armor_desc.is_empty(): armor_desc.append("Untrained in all armor")
	out.append("[b]• Armor:[/b] %s" % ", ".join(armor_desc))
	
	# Spellcasting
	var is_caster = int(raw.get("is_spellcaster", 0)) == 1
	if is_caster:
		out.append("")
		out.append("[b][color=gold]Spellcasting[/color][/b]")
		var caster_type_val = int(raw.get("caster_type", 0))
		var caster_type_str = "Prepared" if caster_type_val == PFMagicConstants.CasterType.PREPARED else ("Spontaneous" if caster_type_val == PFMagicConstants.CasterType.SPONTANEOUS else "Spellcaster")
		
		var tradition_val = int(raw.get("spell_tradition", 0))
		var tradition_str = "Arcane"
		match tradition_val:
			PFMagicConstants.MagicTradition.ARCANE: tradition_str = "Arcane"
			PFMagicConstants.MagicTradition.DIVINE: tradition_str = "Divine"
			PFMagicConstants.MagicTradition.OCCULT: tradition_str = "Occult"
			PFMagicConstants.MagicTradition.PRIMAL: tradition_str = "Primal"
			_: tradition_str = "Magical"
			
		var spell_rank = int(raw.get("spell_proficiency", 1))
		out.append("[b]• Spell Tradition:[/b] [color=lightblue]%s (%s)[/color]" % [tradition_str, caster_type_str])
		out.append("[b]• Spell Attack & DC:[/b] %s" % _rank_name(spell_rank))
		
	# Forced Edicts / Anathema
	var edicts_raw = str(raw.get("forced_edicts", "")).strip_edges()
	if edicts_raw != "" and edicts_raw != "[]":
		var edicts_arr = _parse_array_field(edicts_raw)
		if not edicts_arr.is_empty():
			out.append("")
			out.append("[b][color=gold]Edicts & Anathema[/color][/b]")
			out.append("[b]• Edicts:[/b] %s" % ", ".join(edicts_arr))
			
	var anathema_raw = str(raw.get("forced_anathema", "")).strip_edges()
	if anathema_raw != "" and anathema_raw != "[]":
		var anathema_arr = _parse_array_field(anathema_raw)
		if not anathema_arr.is_empty():
			out.append("[b]• Anathema:[/b] [color=coral]%s[/color]" % ", ".join(anathema_arr))
			
	return "\n".join(out)

func _format_ethnicity_info(eth_id: String) -> String:
	var raw = db.get_ethnicity_raw_data(eth_id)
	if raw.is_empty():
		return "No details available."
		
	var out: Array[String] = []
	var desc = raw.get("description", "")
	if desc != "":
		out.append(desc)
		out.append("")
		
	out.append("[b][color=gold]Ethnicity Details[/color][/b]")
	
	var traits_raw = str(raw.get("traits", "")).strip_edges().trim_prefix("[").trim_suffix("]").replace('"', '')
	if traits_raw != "":
		out.append("[b]• Associated Traits:[/b] [color=lightblue]%s[/color]" % traits_raw)
		
	var langs_raw = str(raw.get("languages", "")).strip_edges().trim_prefix("[").trim_suffix("]").replace('"', '')
	if langs_raw != "":
		out.append("[b]• Common Languages:[/b] %s" % langs_raw)
		
	var reg = str(raw.get("region_id", "")).strip_edges()
	if reg != "":
		out.append("[b]• Traditional Homeland:[/b] %s" % reg.capitalize())
		
	return "\n".join(out)

func _format_region_info(region_id: String) -> String:
	var raw = db.get_region_raw_data(region_id)
	if raw.is_empty():
		return "No details available."
		
	var out: Array[String] = []
	var desc = raw.get("description", "")
	if desc != "":
		out.append(desc)
		out.append("")
		
	out.append("[b][color=gold]Region Details[/color][/b]")
	
	var traits_raw = str(raw.get("traits", "")).strip_edges().trim_prefix("[").trim_suffix("]").replace('"', '')
	if traits_raw != "":
		out.append("[b]• Regional Traits:[/b] [color=lightblue]%s[/color]" % traits_raw)
		
	var langs_raw = str(raw.get("languages", "")).strip_edges().trim_prefix("[").trim_suffix("]").replace('"', '')
	if langs_raw != "":
		out.append("[b]• Primary Languages:[/b] %s" % langs_raw)
		
	return "\n".join(out)

# --- Signals ---

func _on_name_changed(new_text: String):
	manager.draft_name = new_text
	_update_ui_state()

func _on_gender_selected(index: int):
	if index > 0:
		var val = opt_gender.get_item_id(index)
		manager.draft_bio["gender"] = val
	else:
		manager.draft_bio["gender"] = PFBiographyConstants.Gender.UNKNOWN
	_update_ui_state()

func _on_nationality_selected(index: int):
	if index > 0: 
		var reg_id = opt_nationality.get_item_metadata(index)
		manager.draft_bio["nationality_id"] = reg_id
		var item = _regions[index - 1]
		_update_info_panel(item["name"], _format_region_info(reg_id))
	else:
		manager.draft_bio["nationality_id"] = ""
		_update_info_panel("Details", "Hover or select an option to see details.")
	_update_ui_state()
	
func _on_birthplace_selected(index: int):
	if index > 0: 
		var reg_id = opt_birthplace.get_item_metadata(index)
		manager.draft_bio["birthplace_id"] = reg_id
		var item = _regions[index - 1]
		_update_info_panel(item["name"], _format_region_info(reg_id))
	else:
		manager.draft_bio["birthplace_id"] = ""
		_update_info_panel("Details", "Hover or select an option to see details.")
	_update_ui_state()

func _on_ancestry_selected(index: int):
	if index > 0:
		var a_id = opt_ancestry.get_item_metadata(index)
		manager.draft_ancestry_id = a_id
		var item = _ancestries[index - 1]
		_update_info_panel(item["name"], _format_ancestry_info(a_id))
		
		# Fetch ancestry entity to get traits
		var ancestry = db.get_ancestry(a_id)
		var traits: Array[StringName] = []
		if ancestry:
			traits = ancestry.traits
		
		# 1. Populate Heritages for this Ancestry (+ Versatile Heritages)
		opt_heritage.clear()
		opt_heritage.add_item("--- Select Heritage ---", -1)
		opt_heritage.set_item_disabled(0, true)
		_heritages = db.get_available_heritages_for_ancestry(a_id)
		for i in range(_heritages.size()):
			var h_label = _heritages[i]["name"]
			if _heritages[i].get("is_versatile", 0) == 1:
				h_label += " (Versatile)"
			opt_heritage.add_item(h_label, i)
			opt_heritage.set_item_metadata(i + 1, _heritages[i]["id"])
		opt_heritage.selected = 0
		
		# 2. Populate compatible Ethnicities
		opt_ethnicity.clear()
		opt_ethnicity.add_item("--- Select Ethnicity ---", -1)
		opt_ethnicity.set_item_disabled(0, true)
		_ethnicities = db.get_available_ethnicities_for_traits(traits)
		for i in range(_ethnicities.size()):
			opt_ethnicity.add_item(_ethnicities[i]["name"], i)
			opt_ethnicity.set_item_metadata(i + 1, _ethnicities[i]["id"])
		opt_ethnicity.selected = 0
	else:
		manager.draft_ancestry_id = ""
		manager.draft_heritage_id = ""
		manager.draft_bio["ethnicity_id"] = ""
		opt_heritage.clear()
		opt_heritage.add_item("--- Select Heritage ---", -1)
		opt_heritage.set_item_disabled(0, true)
		opt_heritage.selected = 0
		opt_ethnicity.clear()
		opt_ethnicity.add_item("--- Select Ethnicity ---", -1)
		opt_ethnicity.set_item_disabled(0, true)
		opt_ethnicity.selected = 0
		_heritages.clear()
		_ethnicities.clear()
		_update_info_panel("Details", "Hover or select an option to see details.")
	_rebuild_abilities()
	_rebuild_languages()
	_rebuild_skills()
	_update_ui_state()

func _on_heritage_selected(index: int):
	if index > 0 and index - 1 < _heritages.size():
		var h_id = str(opt_heritage.get_item_metadata(index))
		manager.draft_heritage_id = h_id
		var item = _heritages[index - 1]
		_update_info_panel(item["name"], _format_heritage_info(h_id))
	else:
		manager.draft_heritage_id = ""
		if manager.draft_ancestry_id != "" and opt_ancestry.selected > 0:
			_update_info_panel(_ancestries[opt_ancestry.selected - 1]["name"], _format_ancestry_info(manager.draft_ancestry_id))
		else:
			_update_info_panel("Details", "Hover or select an option to see details.")
	_update_ui_state()

func _on_ethnicity_selected(index: int):
	if index > 0 and index - 1 < _ethnicities.size(): 
		var eth_id = opt_ethnicity.get_item_metadata(index)
		manager.draft_bio["ethnicity_id"] = eth_id
		var item = _ethnicities[index - 1]
		_update_info_panel(item["name"], _format_ethnicity_info(eth_id))
	else:
		manager.draft_bio["ethnicity_id"] = ""
		_update_info_panel("Details", "Hover or select an option to see details.")
	_update_ui_state()

func _on_background_selected(index: int):
	if index > 0: 
		var bg_id = opt_background.get_item_metadata(index)
		manager.draft_background_id = bg_id
		var item = _backgrounds[index - 1]
		_update_info_panel(item["name"], _format_background_info(bg_id))
	else:
		manager.draft_background_id = ""
		_update_info_panel("Details", "Hover or select an option to see details.")
	_rebuild_abilities()
	_rebuild_skills()
	_update_ui_state()

func _on_class_selected(index: int):
	if index > 0: 
		var class_id = opt_class.get_item_metadata(index)
		manager.draft_class_id = class_id
		var item = _classes[index - 1]
		_update_info_panel(item["name"], _format_class_info(class_id))
	else:
		manager.draft_class_id = ""
		_update_info_panel("Details", "Hover or select an option to see details.")
	_rebuild_abilities()
	_rebuild_skills()
	_update_ui_state()

func _update_ui_state():
	# Cascading enable/disable logic based on strict A-B-C-D enforcement
	
	# Background requires Ancestry
	if manager.draft_ancestry_id != "":
		opt_background.disabled = false
		opt_ethnicity.disabled = false
		opt_heritage.disabled = false
		opt_background.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		opt_ethnicity.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		opt_heritage.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		opt_background.tooltip_text = ""
		opt_ethnicity.tooltip_text = ""
		opt_heritage.tooltip_text = ""
	else:
		opt_background.disabled = true
		opt_ethnicity.disabled = true
		opt_heritage.disabled = true
		opt_background.mouse_default_cursor_shape = Control.CURSOR_ARROW
		opt_ethnicity.mouse_default_cursor_shape = Control.CURSOR_ARROW
		opt_heritage.mouse_default_cursor_shape = Control.CURSOR_ARROW

		opt_background.tooltip_text = "Requires Ancestry selection first."
		opt_ethnicity.tooltip_text = "Requires Ancestry selection first."
		opt_heritage.tooltip_text = "Requires Ancestry selection first."

	# Class requires Background
	if manager.draft_background_id != "":
		opt_class.disabled = false
		opt_class.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		opt_class.tooltip_text = ""
	else:
		opt_class.disabled = true
		opt_class.mouse_default_cursor_shape = Control.CURSOR_ARROW
		opt_class.tooltip_text = "Requires Background selection first."
		
	# Finish Button requires everything
	var missing = PackedStringArray()
	if manager.draft_name.strip_edges() == "":
		missing.append("Biography (Name)")
	if manager.draft_ancestry_id == "":
		missing.append("Ancestry")
	if manager.draft_background_id == "":
		missing.append("Background")
	if manager.draft_class_id == "":
		missing.append("Class")

	var free_selected_count = 0
	var free_seen: Array[String] = []
	var has_duplicate_free = false
	for opt in free_boost_opts:
		if opt.selected > 0:
			free_selected_count += 1
			var s = str(opt.get_item_metadata(opt.selected))
			if free_seen.has(s):
				has_duplicate_free = true
			free_seen.append(s)
			
	if free_selected_count < 4:
		missing.append("4 Free Attribute Boosts (%d/4 chosen)" % free_selected_count)
	elif has_duplicate_free:
		missing.append("Unique Free Boosts (Duplicates detected)")

	var trained_skills_target = 0
	if manager.draft_class_id != "":
		var c = _get_cached_item(_classes, manager.draft_class_id)
		trained_skills_target = maxi(0, c.get("trained_skills_count", 0) + int_mod)

	var skills_selected_count = 0
	var skills_seen: Array[String] = []
	var has_duplicate_skill = false
	for opt in skill_opts:
		if opt.selected > 0:
			skills_selected_count += 1
			var s = str(opt.get_item_metadata(opt.selected)).capitalize()
			if skills_seen.has(s):
				has_duplicate_skill = true
			skills_seen.append(s)
			
	if skills_selected_count < trained_skills_target:
		missing.append("Trained Skills (%d/%d chosen)" % [skills_selected_count, trained_skills_target])
	elif has_duplicate_skill:
		missing.append("Unique Trained Skills (Duplicates detected)")

	var bonus_langs_target = maxi(0, int_mod)
	var langs_selected_count = 0
	var langs_seen: Array[String] = []
	var has_duplicate_lang = false
	for opt in language_opts:
		if opt.selected > 0:
			langs_selected_count += 1
			var l = str(opt.get_item_metadata(opt.selected)).capitalize()
			if langs_seen.has(l):
				has_duplicate_lang = true
			langs_seen.append(l)
			
	if langs_selected_count < bonus_langs_target:
		missing.append("Bonus Languages (%d/%d chosen)" % [langs_selected_count, bonus_langs_target])
	elif has_duplicate_lang:
		missing.append("Unique Bonus Languages (Duplicates detected)")

	if missing.is_empty():
		btn_finalize.text = "Finish & Generate Character"
		btn_finalize.disabled = false
		btn_finalize.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn_finalize.tooltip_text = ""
	else:
		btn_finalize.disabled = true
		btn_finalize.mouse_default_cursor_shape = Control.CURSOR_ARROW
		btn_finalize.tooltip_text = "Missing required fields: " + ", ".join(missing) + "."

func _on_finalize_pressed():
	var a_boosts: Array[StringName] = []
	for opt in ancestry_boost_opts:
		if opt.selected > 0: a_boosts.append(StringName(opt.get_item_metadata(opt.selected)))
	manager.selected_ancestry_free_boosts = a_boosts
	
	var bg_boosts: Array[StringName] = []
	for opt in background_boost_opts:
		if opt.selected > 0: bg_boosts.append(StringName(opt.get_item_metadata(opt.selected)))
	manager.selected_background_boosts = bg_boosts
	
	if class_boost_opts.size() > 0 and class_boost_opts[0].selected > 0:
		manager.selected_class_boost = StringName(class_boost_opts[0].get_item_metadata(class_boost_opts[0].selected))
	else:
		manager.selected_class_boost = &""
	
	var free_boosts: Array[StringName] = []
	for opt in free_boost_opts:
		if opt.selected > 0: free_boosts.append(StringName(opt.get_item_metadata(opt.selected)))
	manager.selected_level_1_boosts = free_boosts
	
	var pc = manager.generate_draft_character()
	
	# Apply Languages
	for opt in language_opts:
		if opt.selected > 0:
			pc.learn_language(StringName(opt.get_item_metadata(opt.selected)))
			
	# Apply Skills
	for opt in skill_opts:
		if opt.selected > 0:
			pc.sheet.set_skill_rank(StringName(opt.get_item_metadata(opt.selected).to_lower()), PFMathConstants.ProficiencyRank.TRAINED)
			
	print("=======================================")
	print("Character Created Successfully: ", pc.entity_name)
	print("  - Ancestry: ", pc.ancestry.entity_name if pc.ancestry else "None")
	print("  - Background: ", pc.background.entity_name if pc.background else "None")
	print("  - Class: ", pc.actor_class.entity_name if pc.actor_class else "None")
	print("  - Final Attribute Modifiers:")
	print("      STR: %+d  DEX: %+d  CON: %+d" % [pc.attributes.str_mod, pc.attributes.dex_mod, pc.attributes.con_mod])
	print("      INT: %+d  WIS: %+d  CHA: %+d" % [pc.attributes.int_mod, pc.attributes.wis_mod, pc.attributes.cha_mod])
	print("  - Known Languages: ", pc.languages)
	print("=======================================")

	btn_finalize.text = "✔ Character Created Successfully!"
	btn_finalize.disabled = true
	btn_finalize.mouse_default_cursor_shape = Control.CURSOR_ARROW
	btn_finalize.tooltip_text = "Character created. You can now use this character in the game."



# --- Dynamic UI Rebuilders ---

func _get_cached_item(cache: Array, id: String) -> Dictionary:
	for item in cache:
		if item["id"] == id:
			return item
	return {}

func _normalize_stat(stat: String) -> String:
	var s = stat.strip_edges().to_upper()
	match s:
		"STRENGTH": return "STR"
		"DEXTERITY": return "DEX"
		"CONSTITUTION": return "CON"
		"INTELLIGENCE": return "INT"
		"WISDOM": return "WIS"
		"CHARISMA": return "CHA"
		_: return s

func _normalize_boost_entry(entry: String) -> String:
	var s = entry.strip_edges().to_upper()
	if "|" in s:
		var parts = s.split("|")
		var norm_parts: Array[String] = []
		for p in parts:
			norm_parts.append(_normalize_stat(p))
		return "|".join(norm_parts)
	return _normalize_stat(s)

func _parse_boost_list(raw_val: Variant) -> Array[String]:
	var result: Array[String] = []
	if raw_val == null:
		return result
	if raw_val is Array:
		for item in raw_val:
			var s = _normalize_boost_entry(str(item))
			if s != "": result.append(s)
		return result
	var s_val = str(raw_val).strip_edges()
	if s_val == "" or s_val == "[]":
		return result
	var parsed = JSON.parse_string(s_val)
	if typeof(parsed) == TYPE_ARRAY:
		for item in parsed:
			var s = _normalize_boost_entry(str(item))
			if s != "": result.append(s)
		return result
	s_val = s_val.trim_prefix("[").trim_suffix("]")
	for part in s_val.split(","):
		var cleaned = _normalize_boost_entry(part.strip_edges().trim_prefix('"').trim_suffix('"').trim_prefix("'").trim_suffix("'"))
		if cleaned != "":
			result.append(cleaned)
	return result

func _parse_skill_names(raw_val: Variant) -> Array[String]:
	var result: Array[String] = []
	if raw_val == null:
		return result
	if raw_val is Array:
		for item in raw_val:
			var s = str(item).strip_edges()
			if s != "": result.append(s.capitalize())
		return result
	var s_val = str(raw_val).strip_edges()
	if s_val == "" or s_val == "[]":
		return result
	var parsed = JSON.parse_string(s_val)
	if typeof(parsed) == TYPE_ARRAY:
		for item in parsed:
			var s = str(item).strip_edges()
			if s != "": result.append(s.capitalize())
		return result
	s_val = s_val.trim_prefix("[").trim_suffix("]")
	for part in s_val.split(","):
		var cleaned = part.strip_edges().trim_prefix('"').trim_suffix('"').trim_prefix("'").trim_suffix("'")
		if cleaned != "":
			result.append(cleaned.capitalize())
	return result

func _create_badge(text: String, color: Color = Color.WHITE) -> Label:
	var lbl = Label.new()
	lbl.text = " " + text + " "
	lbl.add_theme_color_override("font_color", color)
	return lbl

func _on_alt_boosts_toggled(button_pressed: bool):
	manager.use_alternate_ancestry_boosts = button_pressed
	_rebuild_abilities()

func _rebuild_abilities():
	for child in ability_container.get_children():
		child.queue_free()
	
	ancestry_boost_opts.clear()
	background_boost_opts.clear()
	class_boost_opts.clear()
	free_boost_opts.clear()
	
	var stats = ["STR", "DEX", "CON", "INT", "WIS", "CHA"]
	
	# 1. Ancestry Boosts / Flaws
	if manager.draft_ancestry_id != "":
		var ancestry = _get_cached_item(_ancestries, manager.draft_ancestry_id)
		var hbox = HBoxContainer.new()
		hbox.add_child(_create_label("Ancestry:"))
		
		if manager.use_alternate_ancestry_boosts:
			for i in range(2):
				var opt = _create_stat_dropdown(stats)
				hbox.add_child(opt)
				ancestry_boost_opts.append(opt)
		else:
			var parsed_boosts = _parse_boost_list(ancestry.get("boosts"))
			for b in parsed_boosts:
				if b == "FREE":
					var opt = _create_stat_dropdown(stats)
					hbox.add_child(opt)
					ancestry_boost_opts.append(opt)
				else:
					var lbl = _create_badge("+" + b, Color(0.4, 0.9, 0.4))
					hbox.add_child(lbl)
			
			var parsed_flaws = _parse_boost_list(ancestry.get("flaws"))
			for f in parsed_flaws:
				var lbl = _create_badge("-" + f, Color(1.0, 0.4, 0.4))
				hbox.add_child(lbl)
		
		ability_container.add_child(hbox)
		
	# 2. Background Boosts
	if manager.draft_background_id != "":
		var bg = _get_cached_item(_backgrounds, manager.draft_background_id)
		var hbox = HBoxContainer.new()
		hbox.add_child(_create_label("Background:"))
		
		var parsed_boosts = _parse_boost_list(bg.get("boosts"))
		for b in parsed_boosts:
			if b == "FREE":
				var opt = _create_stat_dropdown(stats)
				hbox.add_child(opt)
				background_boost_opts.append(opt)
			elif "|" in b:
				var choices = b.split("|")
				var opt = _create_stat_dropdown(choices)
				hbox.add_child(opt)
				background_boost_opts.append(opt)
			else:
				var lbl = _create_badge("+" + b, Color(0.4, 0.9, 0.4))
				hbox.add_child(lbl)
					
		ability_container.add_child(hbox)

	# 3. Class Key Attribute
	if manager.draft_class_id != "":
		var c = _get_cached_item(_classes, manager.draft_class_id)
		var hbox = HBoxContainer.new()
		hbox.add_child(_create_label("Class Key:"))
		
		var parsed_keys = _parse_boost_list(c.get("key_abilities"))
		for k in parsed_keys:
			if "|" in k:
				var choices = k.split("|")
				var opt = _create_stat_dropdown(choices)
				hbox.add_child(opt)
				class_boost_opts.append(opt)
			elif k == "FREE":
				var opt = _create_stat_dropdown(stats)
				hbox.add_child(opt)
				class_boost_opts.append(opt)
			else:
				var lbl = _create_badge("+" + k, Color(0.4, 0.9, 0.4))
				hbox.add_child(lbl)
				
		ability_container.add_child(hbox)

	# 4. Free Boosts (Step 4: 4 Free Boosts)
	var hbox_free = HBoxContainer.new()
	hbox_free.add_child(_create_label("Free Boosts:"))
	for i in range(4):
		var opt = _create_stat_dropdown(stats)
		hbox_free.add_child(opt)
		free_boost_opts.append(opt)
	ability_container.add_child(hbox_free)

	# 5. Attributes Total Row
	var hbox_total = HBoxContainer.new()
	for s in stats:
		var lbl = Label.new()
		lbl.text = str(s) + ": +0"
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox_total.add_child(lbl)
		attr_labels[s] = lbl
	ability_container.add_child(hbox_total)
	
	for opt in ancestry_boost_opts: opt.item_selected.connect(_on_ability_dropdown_changed)
	for opt in background_boost_opts: opt.item_selected.connect(_on_ability_dropdown_changed)
	for opt in class_boost_opts: opt.item_selected.connect(_on_ability_dropdown_changed)
	for opt in free_boost_opts: opt.item_selected.connect(_on_ability_dropdown_changed)
	
	_refresh_boost_dropdown_states()
	_calculate_live_attributes()

func _create_label(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.custom_minimum_size = Vector2(100, 0)
	return lbl

func _create_stat_dropdown(options: Array) -> OptionButton:
	var opt = OptionButton.new()
	opt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	opt.add_item("---", 0)
	for i in range(options.size()):
		var stat_name = _normalize_stat(options[i])
		opt.add_item(stat_name, i + 1)
		opt.set_item_metadata(i + 1, stat_name)
	opt.selected = 0
	return opt

func _create_skill_dropdown(options: Array) -> OptionButton:
	var opt = OptionButton.new()
	opt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	opt.add_item("---", 0)
	for i in range(options.size()):
		var skill_name = str(options[i]).capitalize()
		opt.add_item(skill_name, i + 1)
		opt.set_item_metadata(i + 1, skill_name)
	opt.selected = 0
	return opt

func _create_language_dropdown(options: Array) -> OptionButton:
	var opt = OptionButton.new()
	opt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	opt.add_item("---", 0)
	for i in range(options.size()):
		var lang_name = str(options[i]).capitalize()
		opt.add_item(lang_name, i + 1)
		opt.set_item_metadata(i + 1, lang_name)
	opt.selected = 0
	return opt

func _refresh_boost_dropdown_states():
	# --- 1. Ancestry Boosts: Cannot boost an attribute already boosted by Ancestry ---
	if manager.draft_ancestry_id != "":
		var ancestry = _get_cached_item(_ancestries, manager.draft_ancestry_id)
		var fixed_ancestry_boosts: Array[String] = []
		if not manager.use_alternate_ancestry_boosts:
			var b_list = _parse_boost_list(ancestry.get("boosts"))
			for b in b_list:
				if b != "FREE" and not "|" in b:
					fixed_ancestry_boosts.append(b)
					
		for i in range(ancestry_boost_opts.size()):
			var opt = ancestry_boost_opts[i]
			var other_chosen: Array[String] = []
			for j in range(ancestry_boost_opts.size()):
				if i != j and ancestry_boost_opts[j].selected > 0:
					other_chosen.append(str(ancestry_boost_opts[j].get_item_metadata(ancestry_boost_opts[j].selected)))
			
			for idx in range(1, opt.item_count):
				var stat = str(opt.get_item_metadata(idx))
				var should_disable = fixed_ancestry_boosts.has(stat) or other_chosen.has(stat)
				opt.set_item_disabled(idx, should_disable)
				if opt.selected == idx and should_disable:
					opt.selected = 0
	
	# --- 2. Background Boosts: Cannot apply two background boosts to the same attribute ---
	if manager.draft_background_id != "":
		var bg = _get_cached_item(_backgrounds, manager.draft_background_id)
		var fixed_bg_boosts: Array[String] = []
		var b_list = _parse_boost_list(bg.get("boosts"))
		for b in b_list:
			if b != "FREE" and not "|" in b:
				fixed_bg_boosts.append(b)
				
		for i in range(background_boost_opts.size()):
			var opt = background_boost_opts[i]
			var other_chosen: Array[String] = []
			for j in range(background_boost_opts.size()):
				if i != j and background_boost_opts[j].selected > 0:
					other_chosen.append(str(background_boost_opts[j].get_item_metadata(background_boost_opts[j].selected)))
			
			for idx in range(1, opt.item_count):
				var stat = str(opt.get_item_metadata(idx))
				var should_disable = fixed_bg_boosts.has(stat) or other_chosen.has(stat)
				opt.set_item_disabled(idx, should_disable)
				if opt.selected == idx and should_disable:
					opt.selected = 0
					
	# --- 3. Class Key Attribute Choices ---
	if manager.draft_class_id != "":
		for i in range(class_boost_opts.size()):
			var opt = class_boost_opts[i]
			var other_chosen: Array[String] = []
			for j in range(class_boost_opts.size()):
				if i != j and class_boost_opts[j].selected > 0:
					other_chosen.append(str(class_boost_opts[j].get_item_metadata(class_boost_opts[j].selected)))
			for idx in range(1, opt.item_count):
				var stat = str(opt.get_item_metadata(idx))
				var should_disable = other_chosen.has(stat)
				opt.set_item_disabled(idx, should_disable)
				if opt.selected == idx and should_disable:
					opt.selected = 0

	# --- 4. Level 1 Free Boosts: Each of the 4 boosts must apply to a different attribute ---
	for i in range(free_boost_opts.size()):
		var opt = free_boost_opts[i]
		var other_chosen: Array[String] = []
		for j in range(free_boost_opts.size()):
			if i != j and free_boost_opts[j].selected > 0:
				other_chosen.append(str(free_boost_opts[j].get_item_metadata(free_boost_opts[j].selected)))
		
		for idx in range(1, opt.item_count):
			var stat = str(opt.get_item_metadata(idx))
			var should_disable = other_chosen.has(stat)
			opt.set_item_disabled(idx, should_disable)
			if opt.selected == idx and should_disable:
				opt.selected = 0

func _on_ability_dropdown_changed(_idx: int):
	_refresh_boost_dropdown_states()
	_calculate_live_attributes()

func _calculate_live_attributes():
	var mods = {"STR": 0, "DEX": 0, "CON": 0, "INT": 0, "WIS": 0, "CHA": 0}
	
	# 1. Fixed Ancestry Boosts / Flaws
	if manager.draft_ancestry_id != "":
		var ancestry = _get_cached_item(_ancestries, manager.draft_ancestry_id)
		if not manager.use_alternate_ancestry_boosts:
			var b_list = _parse_boost_list(ancestry.get("boosts"))
			for b in b_list:
				if b != "FREE" and not "|" in b and mods.has(b):
					mods[b] += 1
			var f_list = _parse_boost_list(ancestry.get("flaws"))
			for f in f_list:
				if f != "FREE" and mods.has(f):
					mods[f] -= 1
	
	# 2. Ancestry Dropdown Boosts
	for opt in ancestry_boost_opts:
		if opt.selected > 0:
			var stat = opt.get_item_metadata(opt.selected)
			if mods.has(stat):
				mods[stat] += 1
				
	# 3. Fixed Background Boosts
	if manager.draft_background_id != "":
		var bg = _get_cached_item(_backgrounds, manager.draft_background_id)
		var b_list = _parse_boost_list(bg.get("boosts"))
		for b in b_list:
			if b != "FREE" and not "|" in b and mods.has(b):
				mods[b] += 1
				
	# 4. Background Dropdown Boosts
	for opt in background_boost_opts:
		if opt.selected > 0:
			var stat = opt.get_item_metadata(opt.selected)
			if mods.has(stat):
				mods[stat] += 1
				
	# 5. Fixed Class Key Boosts
	if manager.draft_class_id != "":
		var c = _get_cached_item(_classes, manager.draft_class_id)
		var k_list = _parse_boost_list(c.get("key_abilities"))
		for k in k_list:
			if k != "FREE" and not "|" in k and mods.has(k):
				mods[k] += 1
				
	# 6. Class Dropdown Boosts
	for opt in class_boost_opts:
		if opt.selected > 0:
			var stat = opt.get_item_metadata(opt.selected)
			if mods.has(stat):
				mods[stat] += 1
				
	# 7. Level 1 Free Boosts
	for opt in free_boost_opts:
		if opt.selected > 0:
			var stat = opt.get_item_metadata(opt.selected)
			if mods.has(stat):
				mods[stat] += 1
				
	# Update Labels
	for stat in mods:
		if attr_labels.has(stat):
			var val = mods[stat]
			var formatted = ("+" + str(val)) if val >= 0 else str(val)
			attr_labels[stat].text = "%s: %s" % [stat, formatted]
			
	# Check Free Boosts duplicates warning (backup check)
	var free_chosen: Array[String] = []
	var has_duplicate_free = false
	for opt in free_boost_opts:
		if opt.selected > 0:
			var s = str(opt.get_item_metadata(opt.selected))
			if free_chosen.has(s):
				has_duplicate_free = true
			free_chosen.append(s)
	
	if free_warning_label:
		if has_duplicate_free:
			free_warning_label.text = "⚠ Duplicate Free Boosts: Each level 1 free boost must apply to a different attribute."
			free_warning_label.visible = true
		else:
			free_warning_label.text = ""
			free_warning_label.visible = false

	var new_int_mod = mods["INT"]
	if new_int_mod != int_mod:
		int_mod = new_int_mod
		_rebuild_languages()
		_rebuild_skills()
		
	_update_ui_state()

func _rebuild_languages():
	for child in languages_container.get_children():
		child.queue_free()
	language_opts.clear()
	
	var known_langs: Array[String] = []
	# 1. Base Known Languages from Ancestry (+ Common by default)
	if manager.draft_ancestry_id != "":
		var anc = _get_cached_item(_ancestries, manager.draft_ancestry_id)
		var langs_field = anc.get("known_languages")
		if langs_field == null or str(langs_field) == "":
			var raw = db.get_ancestry_raw_data(manager.draft_ancestry_id)
			langs_field = raw.get("known_languages")
		var parsed = _parse_skill_names(langs_field)
		for pl in parsed:
			if not known_langs.has(pl):
				known_langs.append(pl)
				
	if not known_langs.has("Common"):
		known_langs.insert(0, "Common")
		
	var hbox_known = HBoxContainer.new()
	hbox_known.add_child(_create_label("Known Languages:"))
	for kl in known_langs:
		var lbl = _create_badge("[Known] " + kl, Color(0.4, 0.9, 0.4))
		hbox_known.add_child(lbl)
	languages_container.add_child(hbox_known)
	
	# 2. Bonus Languages from INT modifier
	var num_languages = maxi(0, int_mod)
	var lbl_bonus = Label.new()
	if num_languages > 0:
		var int_sign = ("+" + str(int_mod)) if int_mod >= 0 else str(int_mod)
		lbl_bonus.text = "Bonus Languages (%s INT mod = %d):" % [int_sign, num_languages]
	else:
		lbl_bonus.text = "Bonus Languages (0 from +0 INT mod):"
	lbl_bonus.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	languages_container.add_child(lbl_bonus)
	
	if num_languages > 0:
		var all_bonus_langs = [
			"Draconic", "Dwarven", "Elven", "Gnomish", "Goblin", 
			"Halfling", "Orcish", "Fey", "Shadowtongue",
			"Birdfolk", "Bullfolk", "Catfolk", "Dogfolk", "Foxfolk", 
			"Frogfolk", "Horsefolk", "Hyenafolk", "Lizardfolk", 
			"Monkeyfolk", "Ratfolk", "Snakefolk",
			"Cordovalen", "Torvallan", "Calataran", "Shahrazari",
			"Qingling", "Caerwenic", "Kharumic",
			"Pyric", "Thalassic", "Sussuran", "Petran",
			"Empyrean", "Diabolic", "Chthonian", "Necril", "Jotun", "Aklo"
		]
		# Filter out languages already known by base ancestry/character
		var available_langs: Array[String] = []
		for l in all_bonus_langs:
			if not known_langs.has(l):
				available_langs.append(l)
				
		for i in range(num_languages):
			var opt = _create_language_dropdown(available_langs)
			languages_container.add_child(opt)
			language_opts.append(opt)
			opt.item_selected.connect(_on_language_dropdown_changed)
			
	_refresh_language_dropdown_states()

func _refresh_language_dropdown_states():
	var known_langs: Array[String] = []
	if manager.draft_ancestry_id != "":
		var anc = _get_cached_item(_ancestries, manager.draft_ancestry_id)
		var langs_field = anc.get("known_languages")
		if langs_field == null or str(langs_field) == "":
			var raw = db.get_ancestry_raw_data(manager.draft_ancestry_id)
			langs_field = raw.get("known_languages")
		known_langs = _parse_skill_names(langs_field)
	if not known_langs.has("Common"):
		known_langs.append("Common")
		
	for i in range(language_opts.size()):
		var opt = language_opts[i]
		var other_chosen: Array[String] = []
		for j in range(language_opts.size()):
			if i != j and language_opts[j].selected > 0:
				other_chosen.append(str(language_opts[j].get_item_metadata(language_opts[j].selected)).capitalize())
				
		for idx in range(1, opt.item_count):
			var lang_name = str(opt.get_item_metadata(idx)).capitalize()
			var should_disable = known_langs.has(lang_name) or other_chosen.has(lang_name)
			opt.set_item_disabled(idx, should_disable)
			if opt.selected == idx and should_disable:
				opt.selected = 0

func _on_language_dropdown_changed(_idx: int):
	_refresh_language_dropdown_states()
	_update_ui_state()

func _rebuild_skills():
	for child in skills_container.get_children():
		child.queue_free()
	skill_opts.clear()
	
	var bg_skills: Array[String] = []
	var bg_lores: Array[String] = []
	
	# 1. Background Granted Skills & Lores
	if manager.draft_background_id != "":
		var bg = _get_cached_item(_backgrounds, manager.draft_background_id)
		bg_skills = _parse_skill_names(bg.get("skills"))
		bg_lores = _parse_skill_names(bg.get("lores"))
		
		var hbox_bg = HBoxContainer.new()
		hbox_bg.add_child(_create_label("Background:"))
		
		for s in bg_skills:
			var lbl = _create_badge("[Trained] " + s, Color(0.4, 0.9, 0.4))
			hbox_bg.add_child(lbl)
			
		for l in bg_lores:
			var lore_display = l.replace("_", " ").capitalize()
			if not lore_display.to_lower().ends_with("lore"):
				lore_display += " Lore"
			var lbl = _create_badge("[Trained] " + lore_display, Color(0.4, 0.8, 1.0))
			hbox_bg.add_child(lbl)
			
		skills_container.add_child(hbox_bg)

	# 2. Class Trained Skills Choices
	var base_class_skills = 0
	var total_trained_skills = 0
	if manager.draft_class_id != "":
		var c = _get_cached_item(_classes, manager.draft_class_id)
		base_class_skills = c.get("trained_skills_count", 0)
		total_trained_skills = maxi(0, base_class_skills + int_mod)
	
	var lbl_class = Label.new()
	if manager.draft_class_id != "":
		var int_sign = ("+" + str(int_mod)) if int_mod >= 0 else str(int_mod)
		lbl_class.text = "Class Trained Choices (%d base %s INT mod = %d):" % [
			base_class_skills,
			int_sign,
			total_trained_skills
		]
	else:
		lbl_class.text = "Class Trained Choices:"
	lbl_class.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	skills_container.add_child(lbl_class)
	
	if total_trained_skills > 0:
		var available_skills = [
			"Acrobatics", "Arcana", "Athletics", "Crafting", "Deception", 
			"Diplomacy", "Intimidation", "Medicine", "Nature", "Occultism", 
			"Performance", "Religion", "Society", "Stealth", "Survival", "Thievery"
		]
		for i in range(total_trained_skills):
			var opt = _create_skill_dropdown(available_skills)
			skills_container.add_child(opt)
			skill_opts.append(opt)
			opt.item_selected.connect(_on_skill_dropdown_changed)
			
	_refresh_skill_dropdown_states()

func _refresh_skill_dropdown_states():
	var bg_skills: Array[String] = []
	if manager.draft_background_id != "":
		var bg = _get_cached_item(_backgrounds, manager.draft_background_id)
		bg_skills = _parse_skill_names(bg.get("skills"))
	
	for i in range(skill_opts.size()):
		var opt = skill_opts[i]
		var other_chosen: Array[String] = []
		for j in range(skill_opts.size()):
			if i != j and skill_opts[j].selected > 0:
				other_chosen.append(str(skill_opts[j].get_item_metadata(skill_opts[j].selected)).capitalize())
				
		for idx in range(1, opt.item_count):
			var skill_name = str(opt.get_item_metadata(idx)).capitalize()
			var should_disable = bg_skills.has(skill_name) or other_chosen.has(skill_name)
			opt.set_item_disabled(idx, should_disable)
			if opt.selected == idx and should_disable:
				opt.selected = 0

func _on_skill_dropdown_changed(_idx: int):
	_refresh_skill_dropdown_states()
	_update_ui_state()
