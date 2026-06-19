# pf_language.gd
## Represents a language that an actor can speak or understand.
class_name PFLanguage
extends RefCounted

# The master list of game languages
# Maps languages to their PF2e rarities
static func get_rarity(language: StringName) -> PFBiographyConstants.Rarity:
	var db = PFDatabase.get_instance()
	if db:
		var data = db.get_language_data(language)
		if not data.is_empty():
			return data.get(&"rarity", PFBiographyConstants.Rarity.COMMON) as PFBiographyConstants.Rarity
			
	return PFBiographyConstants.Rarity.COMMON

# Helper for the Character Creator UI to fetch "any other languages to which you have access"
static func get_all_common_languages() -> Array[StringName]:
	var db = PFDatabase.get_instance()
	if db:
		return db.get_all_common_languages()
	return []
