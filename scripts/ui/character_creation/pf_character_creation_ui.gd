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
	opt_heritage.item_selected.connect(_on_heritage_selected)
	opt_heritage.disabled = true
	opt_heritage.mouse_default_cursor_shape = Control.CURSOR_ARROW
	opt_heritage.selected = 0
	
	opt_ethnicity = _add_dropdown("Ethnicity (Ancestry Restricted)")
	opt_ethnicity.add_item("--- Select Ethnicity ---", -1)
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
	
	# Ability Scores Section
	_build_section_header("5. Ability Scores")
	chk_alt_boosts = CheckBox.new()
	chk_alt_boosts.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	chk_alt_boosts.text = "Use Alternate Ancestry Boosts (2 Free)"
	chk_alt_boosts.tooltip_text = "Replaces the ancestry's standard boosts and flaws with two free ability boosts."
	chk_alt_boosts.toggled.connect(_on_alt_boosts_toggled)
	form_layout.add_child(chk_alt_boosts)
	
	ability_container = VBoxContainer.new()
	form_layout.add_child(ability_container)
	
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
	_ancestries = db.get_all_ancestries()
	for i in range(_ancestries.size()):
		opt_ancestry.add_item(_ancestries[i]["name"], i)
		opt_ancestry.set_item_metadata(i+1, _ancestries[i]["id"])
	opt_ancestry.selected = 0
		
	# Populate Backgrounds
	opt_background.add_item("--- Select Background ---", -1)
	_backgrounds = db.get_all_backgrounds()
	for i in range(_backgrounds.size()):
		opt_background.add_item(_backgrounds[i]["name"], i)
		opt_background.set_item_metadata(i+1, _backgrounds[i]["id"])
	opt_background.selected = 0
		
	# Populate Classes
	opt_class.add_item("--- Select Class ---", -1)
	_classes = db.get_all_classes()
	for i in range(_classes.size()):
		opt_class.add_item(_classes[i]["name"], i)
		opt_class.set_item_metadata(i+1, _classes[i]["id"])
	opt_class.selected = 0
		
	# Populate Nationalities and Birthplaces
	opt_nationality.add_item("--- Select Nationality ---", -1)
	opt_birthplace.add_item("--- Select Birthplace ---", -1)
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
		var parsed_data = JSON.parse_string(names_raw)
		if typeof(parsed_data) == TYPE_DICTIONARY:
			var label_map = {
				"male": "Male Names",
				"female": "Female Names",
				"clan": "Family / Clan Names",
				"family": "Family / Clan Names",
				"names": "Sample Names"
			}
			for cat in parsed_data.keys():
				var label = label_map.get(str(cat).to_lower(), str(cat).capitalize() + " Names")
				var names_list: Array = parsed_data[cat]
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
		var parsed_data = JSON.parse_string(s)
		if typeof(parsed_data) == TYPE_ARRAY:
			for item in parsed_data: result.append(str(item).strip_edges())
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
		manager.draft_bio["nationality_id"] = opt_nationality.get_item_metadata(index)
		var item = _regions[index - 1]
		_update_info_panel(item["name"], item.get("description", "No description available."))
	else:
		manager.draft_bio["nationality_id"] = ""
		_update_info_panel("Details", "Hover or select an option to see details.")
	_update_ui_state()
	
func _on_birthplace_selected(index: int):
	if index > 0: 
		manager.draft_bio["birthplace_id"] = opt_birthplace.get_item_metadata(index)
		var item = _regions[index - 1]
		_update_info_panel(item["name"], item.get("description", "No description available."))
	else:
		manager.draft_bio["birthplace_id"] = ""
		_update_info_panel("Details", "Hover or select an option to see details.")
	_update_ui_state()

func _on_ancestry_selected(index: int):
	_rebuild_abilities()
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
		opt_heritage.selected = 0
		opt_ethnicity.clear()
		opt_ethnicity.add_item("--- Select Ethnicity ---", -1)
		opt_ethnicity.selected = 0
		_heritages.clear()
		_ethnicities.clear()
		_update_info_panel("Details", "Hover or select an option to see details.")
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
		manager.draft_bio["ethnicity_id"] = opt_ethnicity.get_item_metadata(index)
		var item = _ethnicities[index - 1]
		_update_info_panel(item["name"], item.get("description", "No description available."))
	else:
		manager.draft_bio["ethnicity_id"] = ""
	_update_ui_state()

func _on_background_selected(index: int):
	_rebuild_abilities()
	if index > 0: 
		manager.draft_background_id = opt_background.get_item_metadata(index)
		var item = _backgrounds[index - 1]
		var stats = "Boosts: " + str(item.get("boosts", ""))
		_update_info_panel(item["name"], item.get("description", "No description available."), stats)
	else:
		manager.draft_background_id = ""
		_update_info_panel("Details", "Hover or select an option to see details.")
	_update_ui_state()

func _on_class_selected(index: int):
	_rebuild_abilities()
	_rebuild_skills()
	if index > 0: 
		manager.draft_class_id = opt_class.get_item_metadata(index)
		var item = _classes[index - 1]
		_update_info_panel(item["name"], item.get("description", "No description available."))
	else:
		manager.draft_class_id = ""
		_update_info_panel("Details", "Hover or select an option to see details.")
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
	# Bypassing the 4-free boosts strict check for the simplified MVP
	if manager.draft_name != "" and manager.draft_ancestry_id != "" and manager.draft_background_id != "" and manager.draft_class_id != "":
		btn_finalize.text = "Finish & Generate Character"
		btn_finalize.disabled = false
		btn_finalize.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn_finalize.tooltip_text = ""
	else:
		var missing = PackedStringArray()
		if manager.draft_name == "":
			missing.append("Biography (Name)")
		if manager.draft_ancestry_id == "":
			missing.append("Ancestry")
		if manager.draft_background_id == "":
			missing.append("Background")
		if manager.draft_class_id == "":
			missing.append("Class")

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
	if manager.draft_background_id != "":
		var bg = _get_cached_item(_backgrounds, manager.draft_background_id)
		var b_arr = JSON.parse_string(bg.get("boosts", "[]"))
		if typeof(b_arr) == TYPE_ARRAY:
			for b in b_arr:
				if not "FREE" in b and not "|" in b:
					bg_boosts.append(StringName(b))
	manager.selected_background_boosts = bg_boosts
	
	if manager.draft_class_id != "":
		var c = _get_cached_item(_classes, manager.draft_class_id)
		var b_arr = JSON.parse_string(c.get("key_abilities", "[]"))
		if typeof(b_arr) == TYPE_ARRAY and b_arr.size() > 0:
			var b = b_arr[0]
			if "|" in b:
				if class_boost_opts.size() > 0 and class_boost_opts[0].selected > 0:
					var chosen = class_boost_opts[0].get_item_metadata(class_boost_opts[0].selected)
					# Manager doesn't have class boost property right now, so apply it directly after pc generation
			else:
				# Fixed class boost
				pass
	
	# Pass class boost via a temporary array if it was a choice (for now, manager just handles free boosts)
	
	var free_boosts: Array[StringName] = []
	for opt in free_boost_opts:
		if opt.selected > 0: free_boosts.append(StringName(opt.get_item_metadata(opt.selected)))
	manager.selected_level_1_boosts = free_boosts
	
	var pc = manager.generate_draft_character()
	
	# Apply Class Boost manually since manager doesn't track it
	if manager.draft_class_id != "":
		var c = _get_cached_item(_classes, manager.draft_class_id)
		var b_arr = JSON.parse_string(c.get("key_abilities", "[]"))
		if typeof(b_arr) == TYPE_ARRAY and b_arr.size() > 0:
			var b = b_arr[0]
			if "|" in b:
				if class_boost_opts.size() > 0 and class_boost_opts[0].selected > 0:
					pc.attributes.apply_class_boost(StringName(class_boost_opts[0].get_item_metadata(class_boost_opts[0].selected)))
			else:
				pc.attributes.apply_class_boost(StringName(b))
				
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
	print("  - Final Stats:")
	print("      STR: ", pc.attributes.str_score, " DEX: ", pc.attributes.dex_score, " CON: ", pc.attributes.con_score)
	print("      INT: ", pc.attributes.int_score, " WIS: ", pc.attributes.wis_score, " CHA: ", pc.attributes.cha_score)
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
			var raw = ancestry.get("boosts", "[]")
			var parsed_boosts = JSON.parse_string(raw)
			if typeof(parsed_boosts) == TYPE_ARRAY:
				for b in parsed_boosts:
					if b == "FREE":
						var opt = _create_stat_dropdown(stats)
						hbox.add_child(opt)
						ancestry_boost_opts.append(opt)
					else:
						var lbl = _create_label("+" + str(b))
						hbox.add_child(lbl)
			
			var flaws = JSON.parse_string(ancestry.get("flaws", "[]"))
			if typeof(flaws) == TYPE_ARRAY:
				for f in flaws:
					var lbl = _create_label("-" + str(f))
					lbl.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
					hbox.add_child(lbl)
		
		ability_container.add_child(hbox)
		
	if manager.draft_background_id != "":
		var bg = _get_cached_item(_backgrounds, manager.draft_background_id)
		var hbox = HBoxContainer.new()
		hbox.add_child(_create_label("Background:"))
		
		var raw = bg.get("boosts", "[]")
		var parsed_boosts = JSON.parse_string(raw)
		if typeof(parsed_boosts) == TYPE_ARRAY:
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
					var lbl = _create_label("+" + str(b))
					hbox.add_child(lbl)
					
		ability_container.add_child(hbox)

	if manager.draft_class_id != "":
		var c = _get_cached_item(_classes, manager.draft_class_id)
		var hbox = HBoxContainer.new()
		hbox.add_child(_create_label("Class Key:"))
		
		var raw = c.get("key_abilities", "[]")
		var parsed_boosts = JSON.parse_string(raw)
		if typeof(parsed_boosts) == TYPE_ARRAY and parsed_boosts.size() > 0:
			var b = parsed_boosts[0]
			if "|" in b:
				var choices = b.split("|")
				var opt = _create_stat_dropdown(choices)
				hbox.add_child(opt)
				class_boost_opts.append(opt)
			else:
				var lbl = _create_label("+" + str(b))
				hbox.add_child(lbl)
				
		ability_container.add_child(hbox)

	var hbox_free = HBoxContainer.new()
	hbox_free.add_child(_create_label("Free Boosts:"))
	for i in range(4):
		var opt = _create_stat_dropdown(stats)
		hbox_free.add_child(opt)
		free_boost_opts.append(opt)
	ability_container.add_child(hbox_free)

	var hbox_total = HBoxContainer.new()
	for s in stats:
		var lbl = Label.new()
		lbl.text = str(s) + ": 10 "
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox_total.add_child(lbl)
		attr_labels[s] = lbl
	ability_container.add_child(hbox_total)
	
	for opt in ancestry_boost_opts: opt.item_selected.connect(_on_ability_dropdown_changed)
	for opt in background_boost_opts: opt.item_selected.connect(_on_ability_dropdown_changed)
	for opt in class_boost_opts: opt.item_selected.connect(_on_ability_dropdown_changed)
	for opt in free_boost_opts: opt.item_selected.connect(_on_ability_dropdown_changed)
	
	_calculate_live_attributes()

func _create_label(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.custom_minimum_size = Vector2(100, 0)
	return lbl

func _create_stat_dropdown(options: Array) -> OptionButton:
	var opt = OptionButton.new()
	opt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	opt.add_item("---", -1)
	opt.set_item_disabled(0, true)
	for i in range(options.size()):
		opt.add_item(options[i], i)
		opt.set_item_metadata(i+1, options[i])
	return opt

func _on_ability_dropdown_changed(_idx: int):
	_calculate_live_attributes()

func _calculate_live_attributes():
	var scores = {"STR": 10, "DEX": 10, "CON": 10, "INT": 10, "WIS": 10, "CHA": 10}
	
	var all_opts = []
	all_opts.append_array(ancestry_boost_opts)
	all_opts.append_array(background_boost_opts)
	all_opts.append_array(class_boost_opts)
	all_opts.append_array(free_boost_opts)
	
	for opt in all_opts:
		if opt.selected > 0:
			var stat = opt.get_item_metadata(opt.selected)
			if scores.has(stat):
				scores[stat] += 2
				
	if manager.draft_ancestry_id != "" and not manager.use_alternate_ancestry_boosts:
		var a = _get_cached_item(_ancestries, manager.draft_ancestry_id)
		var b_arr = JSON.parse_string(a.get("boosts", "[]"))
		if typeof(b_arr) == TYPE_ARRAY:
			for b in b_arr:
				if scores.has(b): scores[b] += 2
		var f_arr = JSON.parse_string(a.get("flaws", "[]"))
		if typeof(f_arr) == TYPE_ARRAY:
			for f in f_arr:
				if scores.has(f): scores[f] -= 2
				
	if manager.draft_background_id != "":
		var bg = _get_cached_item(_backgrounds, manager.draft_background_id)
		var b_arr = JSON.parse_string(bg.get("boosts", "[]"))
		if typeof(b_arr) == TYPE_ARRAY:
			for b in b_arr:
				if scores.has(b): scores[b] += 2
				
	if manager.draft_class_id != "":
		var c = _get_cached_item(_classes, manager.draft_class_id)
		var b_arr = JSON.parse_string(c.get("key_abilities", "[]"))
		if typeof(b_arr) == TYPE_ARRAY and b_arr.size() > 0:
			var b = b_arr[0]
			if scores.has(b): scores[b] += 2
			
	for stat in scores:
		if attr_labels.has(stat):
			attr_labels[stat].text = str(stat) + ": " + str(scores[stat])
			
	var new_int_mod = floor((scores["INT"] - 10) / 2.0)
	if new_int_mod != int_mod:
		int_mod = new_int_mod
		_rebuild_languages()
		_rebuild_skills()

func _rebuild_languages():
	for child in languages_container.get_children():
		child.queue_free()
	language_opts.clear()
	
	var num_languages = maxi(0, int_mod)
	var lbl = Label.new()
	lbl.text = "Bonus Languages: " + str(num_languages)
	languages_container.add_child(lbl)
	
	if num_languages > 0:
		var available_langs = ["Common", "Draconic", "Elven", "Dwarven", "Goblin", "Orcish", "Sylvan", "Undercommon"]
		for i in range(num_languages):
			var opt = _create_stat_dropdown(available_langs)
			languages_container.add_child(opt)
			language_opts.append(opt)

func _rebuild_skills():
	for child in skills_container.get_children():
		child.queue_free()
	skill_opts.clear()
	
	var trained_count = 0
	if manager.draft_class_id != "":
		var c = _get_cached_item(_classes, manager.draft_class_id)
		trained_count = c.get("trained_skills_count", 0) + int_mod
	
	var lbl = Label.new()
	lbl.text = "Trained Skills: " + str(trained_count)
	skills_container.add_child(lbl)
	
	if trained_count > 0:
		var available_skills = ["Acrobatics", "Arcana", "Athletics", "Crafting", "Deception", "Diplomacy", "Intimidation", "Medicine", "Nature", "Occultism", "Performance", "Religion", "Society", "Stealth", "Survival", "Thievery"]
		for i in range(trained_count):
			var opt = _create_stat_dropdown(available_skills)
			skills_container.add_child(opt)
			skill_opts.append(opt)
