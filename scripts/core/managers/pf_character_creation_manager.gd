# pf_character_creation_manager.gd
## A state-machine manager for building a Level 1 character step-by-step.
class_name PFCharacterCreationManager
extends RefCounted

signal draft_updated(character: PFPlayerCharacter)

var draft_name: String = "Unknown Hero"
var draft_ancestry_id: String = ""
var draft_heritage_id: String = ""
var draft_background_id: String = ""
var draft_class_id: String = ""
var draft_bio: Dictionary = {
	"gender": PFBiographyConstants.Gender.NON_BINARY,
	"ethnicity_id": "",
	"nationality_id": "",
	"birthplace_id": ""
}

# Selections for boosts
var selected_ancestry_free_boosts: Array[StringName] = []
var selected_background_boosts: Array[StringName] = []
var selected_level_1_boosts: Array[StringName] = []

# Optional Rules
var use_alternate_ancestry_boosts: bool = false

## Builds a PFPlayerCharacter based on the current draft state and returns it.
func generate_draft_character() -> PFPlayerCharacter:
	# 1. Initialize Blank Slate
	var pc = PFPlayerCharacter.new(draft_name, [], 1, 10, 0, 0, 0)
	pc.attributes.use_alternate_ancestry_boosts = use_alternate_ancestry_boosts
	var db = PFDatabase.get_instance()
	
	# 2. Apply Bio
	pc.gender = draft_bio["gender"]
	if draft_bio["ethnicity_id"] != "":
		pc.ethnicity = draft_bio["ethnicity_id"]
	if draft_bio["nationality_id"] != "":
		pc.nationality = draft_bio["nationality_id"]
	if draft_bio["birthplace_id"] != "":
		pc.birthplace = draft_bio["birthplace_id"]
	
	# 3. Apply Ancestry & Heritage
	if draft_ancestry_id != "":
		var ancestry = db.get_ancestry(draft_ancestry_id)
		if ancestry:
			pc.apply_ancestry(ancestry)
			for b in selected_ancestry_free_boosts:
				pc.attributes.apply_ancestry_boost(b)
				
		if draft_heritage_id != "":
			var heritage = db.get_heritage(draft_heritage_id)
			if heritage:
				pc.apply_heritage(heritage)
				
	# 4. Apply Background
	if draft_background_id != "":
		var background = db.get_background(draft_background_id)
		if background:
			# Base background apply handles lores and skills
			pc.apply_background(background)
			for b in selected_background_boosts:
				pc.attributes.apply_background_boost(b)
				
	# 5. Apply Class
	if draft_class_id != "":
		var c = db.get_pf_class(draft_class_id)
		if c:
			pc.apply_class(c.id)
			# Class boost is automatically handled in PFPlayerCharacter.apply_class() if key_ability is an array and we pick one.
			# But for simplicity, we assume apply_class handles the primary key ability boost for now.
			
	# 6. Apply Level 1 Free Boosts
	for b in selected_level_1_boosts:
		pc.attributes.apply_level_boost(1, b)
		
	draft_updated.emit(pc)
	return pc

## Validates if the current state forms a complete, legal Level 1 Character
func is_valid_character() -> bool:
	if draft_name == "" or draft_ancestry_id == "" or draft_background_id == "" or draft_class_id == "":
		return false
		
	# Check 4 free boosts
	if selected_level_1_boosts.size() != 4:
		return false
		
	return true
